"""solvers/variational_solver.py — Variational PDE solvers using K-KAN."""

from __future__ import annotations
from typing import Callable, Dict, List, Optional, Tuple
import time
import jax, jax.numpy as jnp, numpy as np
import optax

from ..model.kan_layer import KKAN, count_params
from ..utils.training import compute_metrics, build_optimizer, l0_schedule
from ..utils.lbfgs import lbfgs_minimize
from ..utils.diff_ops import (
    laplacian_u,
    div_grad_a_u,
    grad_t,
    u_tt,
    lap_spatial,
    convect,
)
from ..utils.quadrature import gauss_legendre_nd, halton_nd, resample_collocation


# ── PDE residual functions ────────────────────────────────────────────────────


def residual_poisson(params, model, x, f_fn, a_fn=None):
    if a_fn is None:
        return -laplacian_u(model, params, x) - f_fn(x)
    return -div_grad_a_u(model, params, x, a_fn) - f_fn(x)


def residual_helmholtz(params, model, x, f_fn, k=1.0):
    lap = laplacian_u(model, params, x)
    u = model.apply(params, x, deterministic=True)[:, 0]
    return -lap - k**2 * u - f_fn(x)


def residual_heat(params, model, xt, f_fn, kappa=0.1):
    return grad_t(model, params, xt) - kappa * lap_spatial(model, params, xt) - f_fn(xt)


def residual_wave(params, model, xt, f_fn, c=1.0):
    return u_tt(model, params, xt) - c**2 * lap_spatial(model, params, xt) - f_fn(xt)


def residual_burgers(params, model, xt, nu=0.01 / jnp.pi):
    fn = lambda xi: model.apply(params, xi[None], deterministic=True)[0, 0]

    def single(xi):
        g = jax.grad(fn)(xi)
        u = fn(xi)
        uxx = jax.hessian(fn)(xi)[0, 0]
        return g[1] + u * g[0] - nu * uxx

    return jax.vmap(single)(xt)


def residual_biharmonic(params, model, x, f_fn):
    from ..utils.diff_ops import bilaplacian_u

    return bilaplacian_u(model, params, x) - f_fn(x)


def residual_convection_diffusion(params, model, x, f_fn, a, eps=0.01):
    return convect(model, params, x, a) - eps * laplacian_u(model, params, x) - f_fn(x)


def residual_allen_cahn(params, model, xt, eps=0.1, f_fn=None):
    """Allen-Cahn phase-field equation:  u_t = eps^2 Δu - (u^3 - u) + f.

    Scalar reaction-diffusion; models phase separation with a double-well
    potential W(u) = (1-u^2)^2/4, whose derivative W'(u) = u^3-u drives u
    toward the stable phases u=±1.
    """
    u = model.apply(params, xt, deterministic=True)[:, 0]
    ut = grad_t(model, params, xt)
    lap = lap_spatial(model, params, xt)
    f = f_fn(xt) if f_fn is not None else 0.0
    return ut - eps**2 * lap + (u**3 - u) - f


def residual_cahn_hilliard(params, model, xt, eps=0.1, f_fn=None):
    """Cahn-Hilliard equation:  u_t = Δμ,  μ = u^3 - u - eps^2 Δu.

    Fourth-order (in space) conserved phase-field equation. μ is the
    chemical potential; Δμ requires differentiating the model 4 times in
    total (2 for Δu inside μ, 2 more for Δμ) — computed here via nested
    jax.hessian, which is exact but expensive per collocation point.

    WARNING: this single-model 4th-order formulation is provided for
    reference/education only. Differentiating it again w.r.t. model
    parameters (as required for gradient-based training) has been found
    to crash the XLA compiler (segfault) even for tiny models — this is
    a genuine JAX/XLA limitation with deeply nested jax.hessian-of-
    jax.hessian graphs, not a tuning issue. For actual training, use the
    mixed formulation in kkan.solvers.CahnHilliardSolver instead, which
    splits this into two coupled 2nd-order residuals (see coupled_solver.py
    and docs/kkan_theory.pdf, "4th-order PDEs and the mixed-formulation fix").
    """
    d_sp = xt.shape[1] - 1
    fn = lambda xi: model.apply(params, xi[None], deterministic=True)[0, 0]

    def lap_sp(xi):
        H = jax.hessian(fn)(xi)
        return sum(H[i, i] for i in range(d_sp))

    def mu_fn(xi):
        return fn(xi) ** 3 - fn(xi) - eps**2 * lap_sp(xi)

    def lap_mu(xi):
        Hm = jax.hessian(mu_fn)(xi)
        return sum(Hm[i, i] for i in range(d_sp))

    def single(xi):
        t_idx = xt.shape[1] - 1
        ut = jax.grad(fn)(xi)[t_idx]
        f = f_fn(xi[None])[0] if f_fn is not None else 0.0
        return ut - lap_mu(xi) - f

    return jax.vmap(single)(xt)


def residual_navier_stokes_streamfunction(params, model, x, nu=0.01, f_fn=None):
    """Steady 2D incompressible Navier-Stokes, stream-function/vorticity form.

    Velocity from stream function ψ:  u = ∂ψ/∂y,  v = -∂ψ/∂x  (⇒ ∇·(u,v)=0
    automatically). Vorticity  ω = -Δψ. Steady vorticity transport:

        (u,v)·∇ω = ν Δω     ⟺     ψ_y ω_x - ψ_x ω_y = ν Δω

    Substituting ω = -Δψ gives a single scalar 4th-order nonlinear PDE in
    ψ alone — the standard reduction of steady 2D NS to one scalar field,
    exactly matching K-KAN's scalar-output architecture. Requires 4th-order
    derivatives of ψ, evaluated via nested jax.hessian (exact, expensive).

    WARNING: same caveat as residual_cahn_hilliard above — this 4th-order
    single-model formulation is for reference only and crashes the XLA
    compiler when trained directly. Use kkan.solvers.NavierStokesCavitySolver
    (mixed stream-function/vorticity formulation) instead.
    """

    def fn(xi):
        return model.apply(params, xi[None], deterministic=True)[0, 0]

    def omega_fn(xi):
        H = jax.hessian(fn)(xi)
        return -(H[0, 0] + H[1, 1])

    def single(xi):
        g_psi = jax.grad(fn)(xi)  # [psi_x, psi_y]
        g_om = jax.grad(omega_fn)(xi)  # [omega_x, omega_y]
        H_om = jax.hessian(omega_fn)(xi)
        lap_om = H_om[0, 0] + H_om[1, 1]
        u_vel, v_vel = g_psi[1], -g_psi[0]
        adv = u_vel * g_om[0] + v_vel * g_om[1]
        f = f_fn(xi[None])[0] if f_fn is not None else 0.0
        return adv - nu * lap_om - f

    return jax.vmap(single)(x)


def velocity_from_streamfunction(model, params, x):
    """Recover (u,v) velocity field from a fitted stream-function model ψ(x,y).
    u = ∂ψ/∂y,  v = -∂ψ/∂x."""
    fn = lambda xi: model.apply(params, xi[None], deterministic=True)[0, 0]
    g = jax.vmap(jax.grad(fn))(x)  # (N,2) = [psi_x, psi_y]
    return jnp.stack([g[:, 1], -g[:, 0]], axis=-1)


RESIDUALS = {
    "poisson": residual_poisson,
    "variable_poisson": lambda p, m, x, **kw: residual_poisson(
        p, m, x, kw["f_fn"], kw.get("a_fn")
    ),
    "helmholtz": residual_helmholtz,
    "heat": residual_heat,
    "wave": residual_wave,
    "burgers": residual_burgers,
    "biharmonic": residual_biharmonic,
    "convection_diffusion": residual_convection_diffusion,
    "allen_cahn": residual_allen_cahn,
    "cahn_hilliard": residual_cahn_hilliard,
    "navier_stokes_sf": residual_navier_stokes_streamfunction,
}


# ── Deep Ritz energy loss ─────────────────────────────────────────────────────


def deep_ritz_loss(
    params, model, x_quad, w_quad, f_fn, x_bc, u_bc, beta_bc=500.0, a_fn=None
):
    from ..utils.diff_ops import grad_u

    gu = grad_u(model, params, x_quad)
    u_q = model.apply(params, x_quad, deterministic=True)[:, 0]
    if a_fn is not None:
        a = a_fn(x_quad)
        energy = 0.5 * jnp.sum(w_quad * a * jnp.sum(gu**2, axis=-1))
    else:
        energy = 0.5 * jnp.sum(w_quad * jnp.sum(gu**2, axis=-1))
    loading = jnp.sum(w_quad * f_fn(x_quad) * u_q)
    bc_loss = jnp.mean(
        (model.apply(params, x_bc, deterministic=True)[:, 0] - u_bc[:, 0]) ** 2
    )
    return energy - loading + beta_bc * bc_loss


def lspg_loss(
    params,
    model,
    x_quad,
    w_quad,
    residual_fn,
    x_bc,
    u_bc,
    x_ic=None,
    u_ic=None,
    beta_bc=500.0,
    beta_ic=500.0,
    lam0=0.0,
):
    res = residual_fn(params, model)
    loss = 0.5 * jnp.sum(w_quad * res**2)
    loss += beta_bc * jnp.mean(
        (model.apply(params, x_bc, deterministic=True)[:, 0] - u_bc[:, 0]) ** 2
    )
    if x_ic is not None and u_ic is not None:
        loss += beta_ic * jnp.mean(
            (model.apply(params, x_ic, deterministic=True)[:, 0] - u_ic[:, 0]) ** 2
        )
    loss += lam0 * model.l0_loss(params)
    return loss


# ── Unified VariationalSolver ─────────────────────────────────────────────────


class VariationalSolver:
    """Deep Ritz / LSPG solver for K-KAN with optional adaptive resampling."""

    def __init__(
        self,
        pde_type,
        formulation,
        dim,
        model_kwargs,
        pde_kwargs,
        bc_data=None,
        ic_data=None,
        domain=(0.0, 1.0),
        t_end=1.0,
        quadrature="gauss",
        n_quad=8,
        beta_bc=500.0,
        beta_ic=500.0,
        adaptive_resample=False,
        resample_every=500,
        resample_blend=0.4,
        optimizer="adamw",
        num_steps=5000,
        lr=1e-3,
        lam0_max=0.0,
        l0_warmup=2000,
        lbfgs_steps=300,
        log_every=300,
        seed=0,
    ):
        self.pde_type = pde_type
        self.form = formulation
        self.dim = dim
        self.pde_kw = pde_kwargs
        self.bc_data = bc_data
        self.ic_data = ic_data
        self.lo, self.hi = domain
        self.t_end = t_end
        self.beta_bc = beta_bc
        self.beta_ic = beta_ic
        self.adaptive = adaptive_resample
        self.res_every = resample_every
        self.res_blend = resample_blend
        self.opt_name = optimizer
        self.num_steps = num_steps
        self.lr = lr
        self.lam0_max = lam0_max
        self.l0_warmup = l0_warmup
        self.lbfgs_steps = lbfgs_steps
        self.log_every = log_every
        self.seed = seed
        self.model = KKAN(**model_kwargs)
        is_td = pde_type in ("heat", "wave", "burgers", "allen_cahn", "cahn_hilliard")
        self._input_dim = dim + 1 if is_td else dim
        self._build_quadrature(n_quad, quadrature, is_td)
        if bc_data is not None:
            self.x_bc_quad = bc_data[0]
            self.u_bc_quad = bc_data[1]
        else:
            self.x_bc_quad = None
            self.u_bc_quad = None
        sample = self.x_quad[:1]
        self.params = self.model.init(
            jax.random.PRNGKey(seed), sample, deterministic=True
        )
        print(
            f"[VariationalSolver] pde={pde_type} | form={formulation} | "
            f"dim={dim} | params={count_params(self.params)} | "
            f"quad_pts={self.x_quad.shape[0]}"
        )
        self.history = []

    def _build_quadrature(self, n_quad, method, is_td):
        lo, hi = self.lo, self.hi
        d = self._input_dim
        if method == "gauss":
            pts, wts = gauss_legendre_nd(n_quad, d, lo, hi)
        else:
            pts, wts = halton_nd(n_quad, d, lo, hi)  # n_quad = total points
        if is_td:
            pts[:, -1] = pts[:, -1] / (hi - lo) * self.t_end
            wts = wts / (hi - lo) * self.t_end
        self.x_quad = jnp.array(pts)
        self.w_quad = jnp.array(wts)

    def _residual(self, params):
        kw = self.pde_kw
        m = self.model
        x = self.x_quad
        if self.pde_type == "poisson":
            return residual_poisson(params, m, x, kw["f_fn"], kw.get("a_fn"))
        elif self.pde_type == "variable_poisson":
            return residual_poisson(params, m, x, kw["f_fn"], kw["a_fn"])
        elif self.pde_type == "helmholtz":
            return residual_helmholtz(params, m, x, kw["f_fn"], kw.get("k", 1.0))
        elif self.pde_type == "heat":
            return residual_heat(
                params,
                m,
                x,
                kw.get("f_fn", lambda z: jnp.zeros(z.shape[0])),
                kw.get("kappa", 0.1),
            )
        elif self.pde_type == "wave":
            return residual_wave(
                params,
                m,
                x,
                kw.get("f_fn", lambda z: jnp.zeros(z.shape[0])),
                kw.get("c", 1.0),
            )
        elif self.pde_type == "burgers":
            return residual_burgers(params, m, x, kw.get("nu", 0.01 / jnp.pi))
        elif self.pde_type == "biharmonic":
            return residual_biharmonic(params, m, x, kw["f_fn"])
        elif self.pde_type == "convection_diffusion":
            return residual_convection_diffusion(
                params, m, x, kw["f_fn"], kw["a"], kw.get("eps", 0.01)
            )
        elif self.pde_type == "allen_cahn":
            return residual_allen_cahn(params, m, x, kw.get("eps", 0.1), kw.get("f_fn"))
        elif self.pde_type == "cahn_hilliard":
            return residual_cahn_hilliard(
                params, m, x, kw.get("eps", 0.1), kw.get("f_fn")
            )
        elif self.pde_type == "navier_stokes_sf":
            return residual_navier_stokes_streamfunction(
                params, m, x, kw.get("nu", 0.01), kw.get("f_fn")
            )
        raise ValueError(f"Unknown pde_type: {self.pde_type}")

    def _loss(self, params, lam0=0.0):
        x_ic = getattr(self, "x_ic_quad", None)
        u_ic = getattr(self, "u_ic_quad", None)
        if self.form == "deep_ritz":
            return deep_ritz_loss(
                params,
                self.model,
                self.x_quad,
                self.w_quad,
                self.pde_kw["f_fn"],
                self.x_bc_quad,
                self.u_bc_quad,
                self.beta_bc,
                self.pde_kw.get("a_fn"),
            )
        return lspg_loss(
            params,
            self.model,
            self.x_quad,
            self.w_quad,
            lambda p, m: self._residual(p),
            self.x_bc_quad,
            self.u_bc_quad,
            x_ic,
            u_ic,
            self.beta_bc,
            self.beta_ic,
            lam0,
        )

    def _resample(self, params, step):
        res = np.asarray(self._residual(params))
        new_pts = resample_collocation(
            np.asarray(self.x_quad),
            np.abs(res),
            n_new=int(self.res_blend * self.x_quad.shape[0]),
            lo=self.lo,
            hi=self.hi,
            blend=self.res_blend,
            seed=step,
        )
        self.x_quad = jnp.array(new_pts)
        vol = (self.hi - self.lo) ** self._input_dim
        self.w_quad = jnp.full(new_pts.shape[0], vol / new_pts.shape[0])

    def train(self):
        if self.ic_data is not None:
            self.x_ic_quad = self.ic_data[0]
            self.u_ic_quad = self.ic_data[1]
        opt = build_optimizer(self.opt_name, self.lr, self.num_steps, max_grad_norm=1.0)
        opt_state = opt.init(self.params)
        params = self.params

        @jax.jit
        def step_fn(params, opt_state, lam0):
            loss, grads = jax.value_and_grad(lambda p: self._loss(p, lam0))(params)
            updates, new_opt = opt.update(grads, opt_state, params)
            return optax.apply_updates(params, updates), new_opt, loss

        t0 = time.time()
        for i in range(self.num_steps):
            lam0 = jnp.float32(
                l0_schedule(i, self.l0_warmup, self.num_steps, self.lam0_max)
            )
            params, opt_state, loss = step_fn(params, opt_state, lam0)
            self.history.append(float(loss))
            if self.adaptive and i > 0 and i % self.res_every == 0:
                self._resample(params, i)
            if i % self.log_every == 0 or i == self.num_steps - 1:
                print(
                    f"  [{self.form}] step {i:5d}  loss={loss:.4e}  λ0={float(lam0):.2e}"
                )

        print("  --- L-BFGS refinement ---")
        params, final = lbfgs_minimize(
            lambda p: self._loss(p, 0.0), params, maxiter=self.lbfgs_steps, tol=1e-12
        )
        print(f"  Time: {time.time() - t0:.1f}s")
        self.params = params
        return params

    def predict(self, x):
        return self.model.apply(self.params, x, deterministic=True)

    def evaluate(self, x, u_true):
        return compute_metrics(u_true, self.predict(x))


# ── XPINN domain decomposition ────────────────────────────────────────────────


class XPINNSolver:
    """Domain-decomposition PINN: alternating training on sub-intervals."""

    def __init__(
        self,
        n_subdomains,
        overlap=0.05,
        sub_model_kwargs=None,
        pde_type="poisson",
        pde_kwargs=None,
        domain=(0.0, 1.0),
        num_steps=4000,
        lr=1e-3,
        lbfgs_steps=300,
        seed=0,
    ):
        self.n_sub = n_subdomains
        self.lo, self.hi = domain
        self.pde_type = pde_type
        self.pde_kw = pde_kwargs or {}
        width = (self.hi - self.lo) / n_subdomains
        self.solvers = []
        for k in range(n_subdomains):
            sub_lo = self.lo + k * width - (0 if k == 0 else overlap)
            sub_hi = (
                self.lo + (k + 1) * width + (0 if k == n_subdomains - 1 else overlap)
            )
            kwargs = dict(sub_model_kwargs) if sub_model_kwargs else {}
            kwargs.setdefault("layer_dims", [1, 16, 16, 1])
            self.solvers.append(
                VariationalSolver(
                    pde_type=pde_type,
                    formulation="lspg",
                    dim=1,
                    model_kwargs=kwargs,
                    pde_kwargs=pde_kwargs or {},
                    domain=(sub_lo, sub_hi),
                    num_steps=num_steps,
                    lr=lr,
                    lbfgs_steps=lbfgs_steps,
                    seed=seed + k,
                )
            )
        self._ifc = [
            jnp.array([[self.lo + (k + 1) * width]]) for k in range(n_subdomains - 1)
        ]

    def train(self):
        for epoch in range(5):
            print(f"\n=== XPINN epoch {epoch} ===")
            for k, s in enumerate(self.solvers):
                pts, vals = [], []
                if k > 0 and len(self._ifc) >= k:
                    xi = self._ifc[k - 1]
                    pts.append(np.asarray(xi))
                    vals.append(np.asarray(self.solvers[k - 1].predict(xi)))
                if k < self.n_sub - 1 and len(self._ifc) > k:
                    xi = self._ifc[k]
                    pts.append(np.asarray(xi))
                    vals.append(np.asarray(self.solvers[k + 1].predict(xi)))
                if pts:
                    s.bc_data = (jnp.array(np.vstack(pts)), jnp.array(np.vstack(vals)))
                    s.x_bc_quad = s.bc_data[0]
                    s.u_bc_quad = s.bc_data[1]
                s.train()

    def predict(self, x):
        x_np = np.asarray(x)
        w = (self.hi - self.lo) / self.n_sub
        preds = np.zeros(x_np.shape[0])
        for k, s in enumerate(self.solvers):
            mask = (x_np[:, 0] >= self.lo + k * w) & (
                x_np[:, 0] <= self.lo + (k + 1) * w
            )
            if mask.any():
                preds[mask] = np.asarray(s.predict(jnp.array(x_np[mask])))[:, 0]
        return jnp.array(preds[:, None])
