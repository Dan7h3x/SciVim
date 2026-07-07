"""experiments/exp_derivatives.py — Derivative/gradient approximation.

Run:
    python main.py derivatives --exp runge1d
    python main.py derivatives --exp gradfield2d
    python main.py derivatives --exp convergence
    python main.py derivatives --exp rkhs-reg
    python main.py derivatives --exp all
"""

import sys, os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import numpy as np
import jax, jax.numpy as jnp
import optax

from kkan.approximation import RBFInterpolantWithGrad, ModifiedShepardInterpolant
from kkan.approximation.hermite_collocation import HermiteKernelInterpolant
from kkan.model import HermiteKKAN, sobolev_loss, native_space_regulariser
from kkan.utils import train_lbfgs


def runge_1d(x_arr):
    x = x_arr[:, 0]
    return 1.0 / (1.0 + 25.0 * x**2), (-50.0 * x / (1.0 + 25.0 * x**2) ** 2)[:, None]


def gaussian_2d(x_arr):
    x, y = x_arr[:, 0], x_arr[:, 1]
    u = np.exp(-5.0 * (x**2 + y**2))
    return u, np.column_stack([-10.0 * x * u, -10.0 * y * u])


def oscillatory_1d(x_arr):
    x = x_arr[:, 0]
    return np.sin(6 * np.pi * x), (6 * np.pi * np.cos(6 * np.pi * x))[:, None]


def metrics_u_du(u_true, du_true, u_pred, du_pred):
    err_u = np.abs(u_pred - u_true)
    err_du = (
        np.linalg.norm(du_pred - du_true, axis=-1)
        if du_true.ndim > 1
        else np.abs(du_pred.ravel() - du_true.ravel())
    )
    return dict(
        u_Linf=float(err_u.max()),
        u_L2=float(np.sqrt(np.mean(err_u**2))),
        du_Linf=float(err_du.max()),
        du_L2=float(np.sqrt(np.mean(err_du**2))),
    )


def exp_runge1d(N_train=30, N_test=500, sobolev_steps=2000):
    print("\n" + "=" * 65)
    print("Runge 1D: u(x) and du/dx approximation - method comparison")
    print("=" * 65)
    rng = np.random.RandomState(0)
    x_tr = rng.uniform(-1, 1, (N_train, 1))
    x_te = np.linspace(-1, 1, N_test)[:, None]
    u_tr, du_tr = runge_1d(x_tr)
    u_te, du_te = runge_1d(x_te)
    print(
        f"\n{'Method':32s} {'u_Linf':>10s} {'u_L2':>10s} {'du_Linf':>10s} {'du_L2':>10s}"
    )
    print("-" * 75)

    for kname, sigma in [("matern_25", 0.15), ("rbf", 0.12), ("wendland_c4", 0.2)]:
        interp = RBFInterpolantWithGrad(kernel_name=kname, sigma=sigma, poly_degree=2)
        interp.fit(x_tr, u_tr)
        u_p, du_p = interp.predict(x_te), interp.predict_gradient(x_te)
        m = metrics_u_du(u_te, du_te, u_p, du_p)
        print(
            f"  RBF({kname:15s})              "
            f"{m['u_Linf']:10.3e} {m['u_L2']:10.3e} {m['du_Linf']:10.3e} {m['du_L2']:10.3e}"
        )

    for kname, sigma in [("matern_25", 0.915), ("rbf", 0.30)]:
        herp = HermiteKernelInterpolant(
            kernel_name=kname,
            sigma=sigma,
            poly_degree=5,
            deriv_components=[0],
            reg=1e-13,
        )
        herp.fit(x_tr, u_tr, du_tr)
        u_p, du_p = herp.predict(x_te), herp.predict_gradient(x_te)
        m = metrics_u_du(u_te, du_te, u_p, du_p)
        print(
            f"  Hermite({kname:15s})           "
            f"{m['u_Linf']:10.3e} {m['u_L2']:10.3e} {m['du_Linf']:10.3e} {m['du_L2']:10.3e}"
        )

    msh = ModifiedShepardInterpolant(
        kernel_name="matern_25", sigma=0.925, estimate_grads=True
    )
    msh.fit(x_tr, u_tr, du_tr)
    u_p = msh.predict(x_te)
    eps = 1e-8
    x_p = x_te.copy()
    x_m = x_te.copy()
    x_p[:, 0] += eps
    x_m[:, 0] -= eps
    du_p = (msh.predict(x_p) - msh.predict(x_m)) / (2 * eps)
    m = metrics_u_du(u_te, du_te, u_p, du_p[:, None])
    print(
        f"  ModifiedShepard                     "
        f"{m['u_Linf']:10.3e} {m['u_L2']:10.3e} {m['du_Linf']:10.3e} {m['du_L2']:10.3e}"
    )

    model = HermiteKKAN(
        layer_dims=[1, 36, 1],
        kernel_name="matern_25",
        num_grids=18,
        use_deriv_basis=True,
        trainable_centers=True,
        trainable_sigma=True,
    )
    x_j, u_j, du_j = jnp.array(x_tr), jnp.array(u_tr[:, None]), jnp.array(du_tr)
    params = model.init(jax.random.PRNGKey(0), x_j[:1], deterministic=True)
    opt = optax.adamw(optax.cosine_decay_schedule(2e-3, sobolev_steps))
    opt_state = opt.init(params)

    @jax.jit
    def step(params, opt_state):
        loss, grads = jax.value_and_grad(
            lambda p: sobolev_loss(
                p, model, x_j, u_j, du_target=du_j, lambda_grad=5.0, deterministic=False
            )
        )(params)
        updates, new_opt = opt.update(grads, opt_state, params)
        return optax.apply_updates(params, updates), new_opt, loss

    for i in range(sobolev_steps):
        params, opt_state, loss = step(params, opt_state)
        if i % max(sobolev_steps // 5, 1) == 0:
            print(f"    [HermiteKKAN+Sobolev] step {i} loss={float(loss):.4e}")

    params, _ = train_lbfgs(model, params, x_j, u_j, num_steps=100)

    def u_fn(xi):
        return model.apply(params, xi[None], deterministic=True)[0, 0]

    u_p = np.asarray(model.apply(params, jnp.array(x_te), deterministic=True))
    du_p = np.asarray(jax.vmap(jax.grad(u_fn))(jnp.array(x_te)))
    m = metrics_u_du(u_te, du_te, u_p, du_p)
    print(
        f"  HermiteKKAN+Sobolev                 "
        f"{m['u_Linf']:10.3e} {m['u_L2']:10.3e} {m['du_Linf']:10.3e} {m['du_L2']:10.3e}"
    )
    return m


def exp_gradfield2d(N_train=80):
    print("\n" + "=" * 65)
    print("2D Gaussian: gradient field recovery")
    print("=" * 65)
    rng = np.random.RandomState(1)
    x_tr = rng.uniform(-1, 1, (N_train, 2))
    t = np.linspace(-1, 1, 30)
    xx, yy = np.meshgrid(t, t)
    x_te = np.column_stack([xx.ravel(), yy.ravel()])
    u_tr, du_tr = gaussian_2d(x_tr)
    u_te, du_te = gaussian_2d(x_te)
    print(f"\n{'Method':30s} {'u_Linf':>10s} {'du_Linf':>10s} {'du_L2':>10s}")
    print("-" * 55)
    for kname, sigma in [("rbf", 0.25), ("matern_25", 0.22), ("wendland_c4", 0.3)]:
        interp = RBFInterpolantWithGrad(kernel_name=kname, sigma=sigma, poly_degree=1)
        interp.fit(x_tr, u_tr)
        u_p, du_p = interp.predict(x_te), interp.predict_gradient(x_te)
        m = metrics_u_du(u_te, du_te, u_p, du_p)
        print(
            f"  RBF-val({kname:12s})       "
            f"{m['u_Linf']:10.3e} {m['du_Linf']:10.3e} {m['du_L2']:10.3e}"
        )
        herp = HermiteKernelInterpolant(
            kernel_name=kname,
            sigma=sigma,
            deriv_components=[0, 1],
            poly_degree=1,
            reg=1e-6,
        )
        herp.fit(x_tr, u_tr, du_tr)
        u_p2, du_p2 = herp.predict(x_te), herp.predict_gradient(x_te)
        m2 = metrics_u_du(u_te, du_te, u_p2, du_p2)
        print(
            f"  Hermite({kname:15s})      "
            f"{m2['u_Linf']:10.3e} {m2['du_Linf']:10.3e} {m2['du_L2']:10.3e}"
        )
    return {}


def exp_convergence(Ns=(20, 40, 80)):
    print("\n" + "=" * 65)
    print("Convergence rates: RBF (value-only) vs Hermite (value+gradient)")
    print("=" * 65)
    x_te = np.linspace(-1, 1, 1000)[:, None]
    u_te, du_te = runge_1d(x_te)
    print(
        f"\n{'N':>5s}  {'RBF u_L2':>12s}  {'RBF du_L2':>12s}  "
        f"{'Hermite u_L2':>14s}  {'Hermite du_L2':>14s}"
    )
    print("-" * 65)
    rbf_u, rbf_du, herm_u, herm_du, Ns_v = [], [], [], [], []
    for N in Ns:
        rng = np.random.RandomState(42)
        x_tr = rng.uniform(-1, 1, (N, 1))
        u_tr, du_tr = runge_1d(x_tr)
        sigma = max(2.5 / N, 0.05)
        try:
            interp = RBFInterpolantWithGrad("matern_25", sigma=sigma, poly_degree=2)
            interp.fit(x_tr, u_tr)
            u_p, du_p = interp.predict(x_te), interp.predict_gradient(x_te)
            m = metrics_u_du(u_te, du_te, u_p, du_p)
            rbf_u.append(m["u_L2"])
            rbf_du.append(m["du_L2"])
            herp = HermiteKernelInterpolant(
                "matern_25", sigma=sigma, deriv_components=[0], poly_degree=1, reg=1e-6
            )
            herp.fit(x_tr, u_tr, du_tr)
            u_h, du_h = herp.predict(x_te), herp.predict_gradient(x_te)
            mh = metrics_u_du(u_te, du_te, u_h, du_h)
            herm_u.append(mh["u_L2"])
            herm_du.append(mh["du_L2"])
            Ns_v.append(N)
            print(
                f"{N:5d}  {m['u_L2']:12.3e}  {m['du_L2']:12.3e}  "
                f"{mh['u_L2']:14.3e}  {mh['du_L2']:14.3e}"
            )
        except Exception as e:
            print(f"{N:5d}  SKIPPED ({e})")
    if len(Ns_v) > 1:
        h = np.array([2.0 / N for N in Ns_v])
        rate = lambda y: np.polyfit(np.log(h), np.log(np.array(y) + 1e-30), 1)[0]
        print(
            f"\nEmpirical rates: RBF u->{rate(rbf_u):.2f} du->{rate(rbf_du):.2f}  "
            f"Hermite u->{rate(herm_u):.2f} du->{rate(herm_du):.2f}"
        )
        print("Theory (Matern-5/2,d=1): u->2.5, du->1.5(RBF)/2.5(Hermite)")
    return dict(rbf_u=rbf_u, rbf_du=rbf_du, herm_u=herm_u, herm_du=herm_du)


def exp_rkhs_regularisation(steps=2000):
    print("\n" + "=" * 65)
    print("Native-space (RKHS) regularisation in Hermite-KAN")
    print("=" * 65)
    rng = np.random.RandomState(7)
    x_tr = rng.uniform(-1, 1, (60, 1))
    u_tr, du_tr = oscillatory_1d(x_tr)
    x_te = np.linspace(-1, 1, 400)[:, None]
    u_te, du_te = oscillatory_1d(x_te)
    x_j, u_j, du_j = jnp.array(x_tr), jnp.array(u_tr[:, None]), jnp.array(du_tr)
    results = {}
    for lam in [0.0, 1e-4, 1e-3, 1e-2]:
        model = HermiteKKAN(
            layer_dims=[1, 16, 1],
            kernel_name="matern_25",
            num_grids=10,
            use_deriv_basis=True,
            trainable_centers=True,
            trainable_sigma=True,
        )
        params = model.init(jax.random.PRNGKey(0), x_j[:1], deterministic=True)
        opt = optax.chain(
            optax.clip_by_global_norm(1.0),
            optax.adam(optax.cosine_decay_schedule(1e-2, steps)),
        )
        opt_state = opt.init(params)

        @jax.jit
        def step(params, opt_state):
            def loss_fn(p):
                L = sobolev_loss(
                    p,
                    model,
                    x_j,
                    u_j,
                    du_target=du_j,
                    lambda_grad=5.0,
                    deterministic=False,
                )
                if lam > 0:
                    L = L + lam * native_space_regulariser(p, layer_idx=0)
                return L

            l, g = jax.value_and_grad(loss_fn)(params)
            u2, s = opt.update(g, opt_state, params)
            return optax.apply_updates(params, u2), s, l

        for _ in range(steps):
            params, opt_state, _ = step(params, opt_state)
        u_p = np.asarray(model.apply(params, jnp.array(x_te), deterministic=True))
        u_fn = lambda xi: model.apply(params, xi[None], deterministic=True)[0, 0]
        du_p = np.asarray(jax.vmap(jax.grad(u_fn))(jnp.array(x_te)))
        m = metrics_u_du(u_te, du_te, u_p, du_p)
        results[lam] = m
        print(
            f"  lambda_RKHS={lam:.0e}:  u_L2={m['u_L2']:.3e}  "
            f"du_Linf={m['du_Linf']:.3e}  du_L2={m['du_L2']:.3e}"
        )
    return results


def run(args):
    if args.exp in ("runge1d", "all"):
        exp_runge1d(sobolev_steps=args.sobolev_steps)
    if args.exp in ("gradfield2d", "all"):
        exp_gradfield2d()
    if args.exp in ("convergence", "all"):
        exp_convergence()
    if args.exp in ("rkhs-reg", "all"):
        exp_rkhs_regularisation(steps=args.sobolev_steps)


def add_args(parser):
    parser.add_argument(
        "--exp",
        default="runge1d",
        choices=["runge1d", "gradfield2d", "convergence", "rkhs-reg", "all"],
    )
    parser.add_argument("--sobolev-steps", type=int, default=2000)


if __name__ == "__main__":
    import argparse

    p = argparse.ArgumentParser()
    add_args(p)
    run(p.parse_args())
