"""solvers/coupled_solver.py — Two-field (mixed formulation) LSPG solver.

Rationale
---------
Fourth-order PDEs (Cahn-Hilliard, biharmonic Navier-Stokes) require
differentiating a single scalar network 4 times via nested jax.hessian.
Backpropagating through THIS (to get parameter gradients for training)
adds yet more AD levels — empirically this triggers XLA compiler crashes
(stack overflow / segfault) even for tiny models, independent of model
width or quadrature size (see docs/kkan_theory.pdf, "4th-order PDEs and
the mixed-formulation fix").

The standard remedy (used throughout the PINN literature for exactly
this class of equations, e.g. Wight & Zhao 2020 for Cahn-Hilliard) is
the MIXED FORMULATION: introduce an auxiliary field and rewrite the
4th-order PDE as a coupled PAIR of 2nd-order PDEs, each requiring only
jax.hessian ONCE. Two independent scalar K-KAN models (one per field)
are trained jointly by summing their residual losses.

Cahn-Hilliard, split:
    u_t = Δμ                              (field u, needs Δμ only)
    μ = u^3 - u - eps^2 Δu                 (field μ, needs Δu only)

Navier-Stokes (stream-function/vorticity), split:
    Δψ = -ω                                (field ψ, needs Δψ only)
    u·∇ω = ν Δω,  u=(ψ_y,-ψ_x)            (field ω, needs Δω + ∇ψ only)

Each sub-residual now uses at most ONE jax.hessian call — the same cost
class as the Poisson/Helmholtz solvers that train reliably.
"""
from __future__ import annotations
from typing import Callable, Dict, Optional, Tuple
import time
import jax, jax.numpy as jnp, numpy as np
import optax

from ..model.kan_layer import KKAN, count_params
from ..utils.training import compute_metrics, build_optimizer
from ..utils.lbfgs import lbfgs_minimize
from ..utils.quadrature import gauss_legendre_nd, halton_nd


def _scalar(model, params):
    def fn(xi): return model.apply(params, xi[None], deterministic=True)[0, 0]
    return fn


class CahnHilliardSolver:
    """
    Mixed-formulation LSPG solver for the Cahn-Hilliard equation:
        u_t = Δμ,   μ = u^3 - u - eps^2 Δu

    Two independent scalar K-KAN models (u-field, mu-field) are trained
    jointly. Each residual needs only ONE Laplacian (jax.hessian once),
    avoiding the 4th-order AD-through-AD instability of the single-model
    formulation.
    """
    def __init__(self, model_kwargs_u=None, model_kwargs_mu=None,
                 eps=0.1, bc_data=None, ic_data=None,
                 domain=(-1.0, 1.0), t_end=1.0, n_quad=30,
                 beta_bc=200.0, beta_ic=200.0, beta_couple=50.0,
                 optimizer="adamw", num_steps=4000, lr=1e-3,
                 lbfgs_steps=200, log_every=300, seed=0):
        self.eps = eps
        self.lo, self.hi = domain; self.t_end = t_end
        self.bc_data = bc_data; self.ic_data = ic_data
        self.beta_bc = beta_bc; self.beta_ic = beta_ic; self.beta_couple = beta_couple
        self.opt_name = optimizer; self.num_steps = num_steps; self.lr = lr
        self.lbfgs_steps = lbfgs_steps; self.log_every = log_every

        mk_u  = model_kwargs_u  or dict(layer_dims=[2, 16, 16, 1], kernel_name="matern_25_poly1",
                                        num_grids=10, use_pruning=False, use_mls_norm=True)
        mk_mu = model_kwargs_mu or dict(layer_dims=[2, 16, 16, 1], kernel_name="matern_25_poly1",
                                        num_grids=10, use_pruning=False, use_mls_norm=True)
        self.model_u  = KKAN(**mk_u)
        self.model_mu = KKAN(**mk_mu)

        pts, wts = halton_nd(n_quad, 2, self.lo, self.hi)
        pts[:, -1] = pts[:, -1] / (self.hi - self.lo) * t_end
        wts = wts / (self.hi - self.lo) * t_end
        self.x_quad = jnp.array(pts); self.w_quad = jnp.array(wts)

        key = jax.random.PRNGKey(seed)
        k1, k2 = jax.random.split(key)
        self.params_u  = self.model_u.init(k1, self.x_quad[:1], deterministic=True)
        self.params_mu = self.model_mu.init(k2, self.x_quad[:1], deterministic=True)
        print(f"[CahnHilliardSolver] params_u={count_params(self.params_u)}  "
              f"params_mu={count_params(self.params_mu)}  quad_pts={self.x_quad.shape[0]}")
        self.history = []

    def _residuals(self, pu, pmu):
        """R1 = u_t - Δμ ;  R2 = μ - (u^3 - u - eps^2 Δu)."""
        d_sp = 1  # spatial dim (1D + time)
        fn_u  = _scalar(self.model_u, pu)
        fn_mu = _scalar(self.model_mu, pmu)

        def lap_sp(fn, xi):
            H = jax.hessian(fn)(xi)
            return sum(H[i, i] for i in range(d_sp))

        def single(xi):
            t_idx = xi.shape[0] - 1
            u  = fn_u(xi)
            ut = jax.grad(fn_u)(xi)[t_idx]
            lap_mu = lap_sp(fn_mu, xi)
            r1 = ut - lap_mu

            mu  = fn_mu(xi)
            lap_u = lap_sp(fn_u, xi)
            r2 = mu - (u**3 - u - self.eps**2*lap_u)
            return r1, r2

        r1, r2 = jax.vmap(single)(self.x_quad)
        return r1, r2

    def _loss(self, pu, pmu):
        r1, r2 = self._residuals(pu, pmu)
        loss = 0.5*jnp.sum(self.w_quad*r1**2) + self.beta_couple*0.5*jnp.sum(self.w_quad*r2**2)
        if self.bc_data is not None:
            x_bc, u_bc = self.bc_data
            loss += self.beta_bc*jnp.mean((self.model_u.apply(pu, x_bc, deterministic=True)[:,0]-u_bc[:,0])**2)
        if self.ic_data is not None:
            x_ic, u_ic = self.ic_data
            loss += self.beta_ic*jnp.mean((self.model_u.apply(pu, x_ic, deterministic=True)[:,0]-u_ic[:,0])**2)
        return loss

    def train(self):
        opt = build_optimizer(self.opt_name, self.lr, self.num_steps, max_grad_norm=1.0)
        pu, pmu = self.params_u, self.params_mu
        params = {"u": pu, "mu": pmu}
        opt_state = opt.init(params)

        @jax.jit
        def step(params, opt_state):
            loss, grads = jax.value_and_grad(
                lambda p: self._loss(p["u"], p["mu"]))(params)
            updates, new_opt = opt.update(grads, opt_state, params)
            return optax.apply_updates(params, updates), new_opt, loss

        t0 = time.time()
        for i in range(self.num_steps):
            params, opt_state, loss = step(params, opt_state)
            self.history.append(float(loss))
            if i % self.log_every == 0 or i == self.num_steps-1:
                print(f"  [cahn-hilliard mixed] step {i:5d}  loss={loss:.4e}")

        if self.lbfgs_steps > 0:
            print("  --- L-BFGS refinement ---")
            params, final = lbfgs_minimize(lambda p: self._loss(p["u"], p["mu"]), params,
                                           maxiter=self.lbfgs_steps, tol=1e-12)
            print(f"  Time: {time.time()-t0:.1f}s")

        self.params_u, self.params_mu = params["u"], params["mu"]
        return self.params_u, self.params_mu

    def predict_u(self, x):
        return self.model_u.apply(self.params_u, x, deterministic=True)

    def predict_mu(self, x):
        return self.model_mu.apply(self.params_mu, x, deterministic=True)


class NavierStokesCavitySolver:
    """
    Mixed-formulation LSPG solver for steady 2D lid-driven cavity flow:
        Δψ = -ω                          (field psi)
        u·∇ω = ν Δω,  u=(ψ_y,-ψ_x)      (field omega)

    Two coupled scalar K-KAN models, each residual needing at most one
    jax.hessian call (rather than the 4th-order single-field formulation).
    """
    def __init__(self, model_kwargs_psi=None, model_kwargs_omega=None,
                 nu=0.05, bc_data_psi=None, lid_velocity=1.0,
                 domain=(0.0, 1.0), n_quad=8,
                 beta_bc=1000.0, beta_couple=10.0,
                 optimizer="adamw", num_steps=4000, lr=1e-3,
                 lbfgs_steps=200, log_every=300, seed=0):
        self.nu = nu; self.lo, self.hi = domain
        self.bc_data_psi = bc_data_psi; self.lid_velocity = lid_velocity
        self.beta_bc = beta_bc; self.beta_couple = beta_couple
        self.opt_name = optimizer; self.num_steps = num_steps; self.lr = lr
        self.lbfgs_steps = lbfgs_steps; self.log_every = log_every

        mk_psi = model_kwargs_psi or dict(layer_dims=[2, 16, 16, 1], kernel_name="matern_25_poly1",
                                          num_grids=8, use_pruning=False, use_mls_norm=True)
        mk_om  = model_kwargs_omega or dict(layer_dims=[2, 16, 16, 1], kernel_name="matern_25_poly1",
                                            num_grids=8, use_pruning=False, use_mls_norm=True)
        self.model_psi = KKAN(**mk_psi)
        self.model_om  = KKAN(**mk_om)

        pts, wts = gauss_legendre_nd(n_quad, 2, self.lo, self.hi)
        self.x_quad = jnp.array(pts); self.w_quad = jnp.array(wts)

        key = jax.random.PRNGKey(seed); k1, k2 = jax.random.split(key)
        self.params_psi = self.model_psi.init(k1, self.x_quad[:1], deterministic=True)
        self.params_om  = self.model_om.init(k2, self.x_quad[:1], deterministic=True)
        print(f"[NavierStokesCavitySolver] params_psi={count_params(self.params_psi)}  "
              f"params_omega={count_params(self.params_om)}  quad_pts={self.x_quad.shape[0]}")
        self.history = []

    def _residuals(self, ppsi, pom):
        """R1 = Δψ + ω ;  R2 = u·∇ω − ν Δω,  u=(ψ_y,−ψ_x)."""
        fn_psi = _scalar(self.model_psi, ppsi)
        fn_om  = _scalar(self.model_om, pom)

        def single(xi):
            H_psi = jax.hessian(fn_psi)(xi)
            lap_psi = H_psi[0,0] + H_psi[1,1]
            om = fn_om(xi)
            r1 = lap_psi + om

            g_psi = jax.grad(fn_psi)(xi)
            g_om  = jax.grad(fn_om)(xi)
            H_om  = jax.hessian(fn_om)(xi)
            lap_om = H_om[0,0] + H_om[1,1]
            u_vel, v_vel = g_psi[1], -g_psi[0]
            adv = u_vel*g_om[0] + v_vel*g_om[1]
            r2 = adv - self.nu*lap_om
            return r1, r2

        r1, r2 = jax.vmap(single)(self.x_quad)
        return r1, r2

    def _loss(self, ppsi, pom):
        r1, r2 = self._residuals(ppsi, pom)
        loss = self.beta_couple*0.5*jnp.sum(self.w_quad*r1**2) + 0.5*jnp.sum(self.w_quad*r2**2)
        if self.bc_data_psi is not None:
            x_bc, u_bc = self.bc_data_psi
            loss += self.beta_bc*jnp.mean(
                (self.model_psi.apply(ppsi, x_bc, deterministic=True)[:,0]-u_bc[:,0])**2)
        return loss

    def train(self):
        opt = build_optimizer(self.opt_name, self.lr, self.num_steps, max_grad_norm=1.0)
        params = {"psi": self.params_psi, "om": self.params_om}
        opt_state = opt.init(params)

        @jax.jit
        def step(params, opt_state):
            loss, grads = jax.value_and_grad(
                lambda p: self._loss(p["psi"], p["om"]))(params)
            updates, new_opt = opt.update(grads, opt_state, params)
            return optax.apply_updates(params, updates), new_opt, loss

        t0 = time.time()
        for i in range(self.num_steps):
            params, opt_state, loss = step(params, opt_state)
            self.history.append(float(loss))
            if i % self.log_every == 0 or i == self.num_steps-1:
                print(f"  [navier-stokes mixed] step {i:5d}  loss={loss:.4e}")

        if self.lbfgs_steps > 0:
            print("  --- L-BFGS refinement ---")
            params, final = lbfgs_minimize(lambda p: self._loss(p["psi"], p["om"]), params,
                                           maxiter=self.lbfgs_steps, tol=1e-12)
            print(f"  Time: {time.time()-t0:.1f}s")

        self.params_psi, self.params_om = params["psi"], params["om"]
        return self.params_psi, self.params_om

    def predict_psi(self, x):
        return self.model_psi.apply(self.params_psi, x, deterministic=True)

    def predict_velocity(self, x):
        fn = _scalar(self.model_psi, self.params_psi)
        g = jax.vmap(jax.grad(fn))(x)
        return jnp.stack([g[:,1], -g[:,0]], axis=-1)
