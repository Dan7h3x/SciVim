"""experiments/exp_pinn_variational.py — Variational PDE solvers.

Run:
    python main.py pinn --pde poisson --formulation deep_ritz --dim 2
    python main.py pinn --pde variable_poisson --formulation lspg --dim 1 --adaptive
    python main.py pinn --pde burgers --formulation lspg
    python main.py pinn --pde helmholtz --formulation lspg --dim 2
    python main.py pinn --pde poisson --formulation lspg --dim 1 --xpinn
"""

import sys, os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import numpy as np
import jax, jax.numpy as jnp
from kkan.solvers import VariationalSolver, XPINNSolver
from kkan.utils import (
    compute_metrics,
    boundary_quad_2d,
    plot_pde_1d,
    plot_pde_2d,
    plot_training,
)


def poisson_2d_deep_ritz(steps=6000, lr=1e-3, lbfgs_steps=300):
    print("\n=== Deep Ritz: Poisson 2D ===")
    u_ex = lambda xy: jnp.sin(jnp.pi * xy[:, 0]) * jnp.sin(jnp.pi * xy[:, 1])
    f_fn = lambda xy: 2 * jnp.pi**2 * u_ex(xy)
    x_bc, _ = boundary_quad_2d(30, 0.0, 1.0)
    x_bc = jnp.array(x_bc)
    u_bc = u_ex(x_bc)[:, None]
    solver = VariationalSolver(
        pde_type="poisson",
        formulation="deep_ritz",
        dim=2,
        model_kwargs=dict(
            layer_dims=[2, 24, 1],
            kernel_name="matern_25_poly2",
            num_grids=20,
            grid_type="gauss",
            use_mls_norm=True,
            use_pruning=False,
            trainable_centers=True,
            trainable_sigma=True,
        ),
        pde_kwargs=dict(f_fn=f_fn),
        bc_data=(x_bc, u_bc),
        domain=(0.0, 1.0),
        quadrature="gauss",
        n_quad=10,
        beta_bc=1000.0,
        adaptive_resample=False,
        optimizer="adamw",
        num_steps=steps,
        lr=lr,
        lam0_max=5e-4,
        l0_warmup=2000,
        lbfgs_steps=lbfgs_steps,
    )
    solver.train()
    t = jnp.linspace(0, 1, 50)
    xx, yy = jnp.meshgrid(t, t)
    x_te = jnp.stack([xx.ravel(), yy.ravel()], axis=-1)
    u_pred = solver.predict(x_te)
    u_true = u_ex(x_te)[:, None]
    m = compute_metrics(u_true, u_pred)
    print("  Metrics:", {k: f"{v:.3e}" for k, v in m.items()})
    plot_pde_2d(
        np.asarray(xx),
        np.asarray(yy),
        np.asarray(u_pred),
        np.asarray(u_true),
        "Deep Ritz: Poisson 2D",
    )
    return m


def variable_poisson_1d_lspg(steps=5000, lr=1e-3, adaptive=True, lbfgs_steps=300):
    print("\n=== LSPG + Adaptive: Variable-coeff Poisson 1D ===")

    def a_fn(x):
        return 1.0 + 0.5 * jnp.sin(jnp.pi * x[:, 0])

    def f_fn(x):
        return -(
            0.5 * jnp.pi**2 * jnp.cos(jnp.pi * x[:, 0]) ** 2
            - jnp.pi**2 * jnp.sin(jnp.pi * x[:, 0])
            - 0.5 * jnp.pi**2 * jnp.sin(jnp.pi * x[:, 0]) ** 2
        )

    def u_ex(x):
        return jnp.sin(jnp.pi * x[:, 0])

    x_bc = jnp.array([[0.0], [1.0]])
    u_bc = u_ex(x_bc)[:, None]
    solver = VariationalSolver(
        pde_type="variable_poisson",
        formulation="lspg",
        dim=1,
        model_kwargs=dict(
            layer_dims=[1, 20, 1],
            kernel_name="matern_25",
            num_grids=20,
            grid_type="gauss",
            use_mls_norm=True,
            use_pruning=False,
            trainable_centers=True,
            trainable_sigma=True,
        ),
        pde_kwargs=dict(f_fn=f_fn, a_fn=a_fn),
        bc_data=(x_bc, u_bc),
        domain=(0.0, 1.0),
        quadrature="gauss",
        n_quad=40,
        beta_bc=1000.0,
        adaptive_resample=adaptive,
        resample_every=500,
        optimizer="adamw",
        num_steps=steps,
        lr=lr,
        lam0_max=1e-3,
        lbfgs_steps=lbfgs_steps,
    )
    solver.train()
    x_te = jnp.linspace(0, 1, 300)[:, None]
    u_pred = solver.predict(x_te)
    u_true = u_ex(x_te)[:, None]
    m = compute_metrics(u_true, u_pred)
    print("  Metrics:", {k: f"{v:.3e}" for k, v in m.items()})
    plot_pde_1d(x_te, u_pred, u_true, "LSPG Variable-coeff Poisson 1D")
    return m


def burgers_1d_lspg(steps=8000, lr=8e-4, lbfgs_steps=300):
    print("\n=== LSPG: Burgers 1D+t ===")
    nu = 0.01 / jnp.pi
    key = jax.random.PRNGKey(0)
    x_ic = jax.random.uniform(key, (300, 1), minval=-1.0, maxval=1.0)
    t_ic = jnp.zeros((300, 1))
    xt_ic = jnp.concatenate([x_ic, t_ic], axis=1)
    u_ic = -jnp.sin(jnp.pi * x_ic)
    t_bc = jax.random.uniform(jax.random.PRNGKey(1), (200, 1))
    x_bc = jnp.concatenate(
        [
            jnp.concatenate([-jnp.ones((200, 1)), t_bc], axis=1),
            jnp.concatenate([jnp.ones((200, 1)), t_bc], axis=1),
        ],
        axis=0,
    )
    u_bc = jnp.zeros((400, 1))
    solver = VariationalSolver(
        pde_type="burgers",
        formulation="lspg",
        dim=1,  # spatial dim=1; solver adds time -> input dim 2
        model_kwargs=dict(
            layer_dims=[2, 32, 1],
            kernel_name="matern_25",
            num_grids=12,
            grid_type="gauss",
            use_mls_norm=True,
            use_pruning=True,
            trainable_centers=True,
            trainable_sigma=True,
        ),
        pde_kwargs=dict(nu=nu),
        bc_data=(x_bc, u_bc),
        ic_data=(xt_ic, u_ic),
        domain=(-1.0, 1.0),
        t_end=1.0,
        quadrature="halton",
        n_quad=50,
        beta_bc=200.0,
        beta_ic=200.0,
        adaptive_resample=True,
        resample_every=600,
        optimizer="adamw",
        num_steps=steps,
        lr=lr,
        lam0_max=2e-4,
        lbfgs_steps=lbfgs_steps,
    )
    solver.train()
    plot_training([solver.history], ["Burgers LSPG"])
    return solver


def helmholtz_2d_lspg(steps=6000, lr=2e-3, k_wave=1.0, lbfgs_steps=300):
    print("\n=== LSPG: Helmholtz 2D ===")
    u_ex = lambda xy: jnp.sin(jnp.pi * xy[:, 0]) * jnp.sin(jnp.pi * xy[:, 1])
    f_fn = lambda xy: (2 * jnp.pi**2 - k_wave**2) * u_ex(xy)
    x_bc, _ = boundary_quad_2d(30, 0.0, 1.0)
    x_bc = jnp.array(x_bc)
    u_bc = u_ex(x_bc)[:, None]
    solver = VariationalSolver(
        pde_type="helmholtz",
        formulation="lspg",
        dim=2,
        model_kwargs=dict(
            layer_dims=[2, 24, 1],
            kernel_name="matern_25",
            num_grids=19,
            grid_type="gauss",
            use_mls_norm=True,
            use_pruning=False,
            trainable_centers=True,
            trainable_sigma=True,
        ),
        pde_kwargs=dict(f_fn=f_fn, k=k_wave),
        bc_data=(x_bc, u_bc),
        domain=(0.0, 1.0),
        quadrature="gauss",
        n_quad=10,
        beta_bc=500.0,
        adaptive_resample=False,
        optimizer="adamw",
        num_steps=steps,
        lr=lr,
        lam0_max=1e-4,
        lbfgs_steps=lbfgs_steps,
    )
    solver.train()
    t = jnp.linspace(0, 1, 50)
    xx, yy = jnp.meshgrid(t, t)
    x_te = jnp.stack([xx.ravel(), yy.ravel()], axis=-1)
    u_pred = solver.predict(x_te)
    u_true = u_ex(x_te)[:, None]
    m = compute_metrics(u_true, u_pred)
    print("  Metrics:", {k: f"{v:.3e}" for k, v in m.items()})
    plot_pde_2d(
        np.asarray(xx),
        np.asarray(yy),
        np.asarray(u_pred),
        np.asarray(u_true),
        "LSPG Helmholtz 2D",
    )
    return m


def poisson_1d_xpinn(n_sub=3, steps=2000, lr=1e-3, lbfgs_steps=300):
    print(f"\n=== XPINN: Poisson 1D ({n_sub} sub-domains) ===")
    u_ex = lambda x: jnp.sin(jnp.pi * x[:, 0])
    f_fn = lambda x: jnp.pi**2 * jnp.sin(jnp.pi * x[:, 0])
    solver = XPINNSolver(
        n_subdomains=n_sub,
        sub_model_kwargs=dict(
            layer_dims=[1, 12, 12, 1],
            kernel_name="matern_25",
            num_grids=10,
            use_pruning=False,
            use_mls_norm=True,
        ),
        pde_type="poisson",
        pde_kwargs=dict(f_fn=f_fn),
        domain=(0.0, 1.0),
        num_steps=steps,
        lr=lr,
        lbfgs_steps=lbfgs_steps,
    )
    solver.solvers[0].bc_data = (jnp.array([[0.0]]), jnp.array([[0.0]]))
    solver.solvers[0].x_bc_quad = solver.solvers[0].bc_data[0]
    solver.solvers[0].u_bc_quad = solver.solvers[0].bc_data[1]
    solver.solvers[-1].bc_data = (jnp.array([[1.0]]), jnp.array([[0.0]]))
    solver.solvers[-1].x_bc_quad = solver.solvers[-1].bc_data[0]
    solver.solvers[-1].u_bc_quad = solver.solvers[-1].bc_data[1]
    solver.train()
    x_te = jnp.linspace(0, 1, 300)[:, None]
    u_pred = solver.predict(x_te)
    u_true = u_ex(x_te)[:, None]
    m = compute_metrics(u_true, u_pred)
    print("  Metrics:", {k: f"{v:.3e}" for k, v in m.items()})
    plot_pde_1d(x_te, u_pred, u_true, "XPINN Poisson 1D")
    return m


def run(args):
    if args.xpinn:
        poisson_1d_xpinn(
            n_sub=args.n_subdomains,
            steps=args.steps,
            lr=args.lr,
            lbfgs_steps=args.lbfgs_steps,
        )
        return
    if args.pde == "poisson" and args.formulation == "deep_ritz":
        poisson_2d_deep_ritz(steps=args.steps, lr=args.lr, lbfgs_steps=args.lbfgs_steps)
    elif args.pde == "variable_poisson":
        variable_poisson_1d_lspg(
            steps=args.steps,
            lr=args.lr,
            adaptive=args.adaptive,
            lbfgs_steps=args.lbfgs_steps,
        )
    elif args.pde == "burgers":
        burgers_1d_lspg(steps=args.steps, lr=args.lr, lbfgs_steps=args.lbfgs_steps)
    elif args.pde == "helmholtz":
        helmholtz_2d_lspg(steps=args.steps, lr=args.lr, lbfgs_steps=args.lbfgs_steps)
    elif args.pde == "allen_cahn":
        allen_cahn_1d_lspg(
            steps=args.steps, lr=args.lr, lbfgs_steps=args.lbfgs_steps, eps=args.eps
        )
    elif args.pde == "cahn_hilliard":
        cahn_hilliard_1d_lspg(
            steps=args.steps, lr=args.lr, lbfgs_steps=args.lbfgs_steps, eps=args.eps
        )
    elif args.pde == "navier_stokes":
        navier_stokes_cavity_lspg(
            steps=args.steps, lr=args.lr, lbfgs_steps=args.lbfgs_steps, nu=args.nu
        )
    elif args.pde == "poisson" and args.formulation == "lspg":
        if args.dim == 1:
            u_ex = lambda x: jnp.sin(jnp.pi * x[:, 0])
            f_fn = lambda x: jnp.pi**2 * jnp.sin(jnp.pi * x[:, 0])
            x_bc = jnp.array([[0.0], [1.0]])
            u_bc = u_ex(x_bc)[:, None]
            solver = VariationalSolver(
                pde_type="poisson",
                formulation="lspg",
                dim=1,
                model_kwargs=dict(
                    layer_dims=[1, 16, 16, 1],
                    kernel_name="matern_25",
                    num_grids=10,
                    use_mls_norm=True,
                    use_pruning=False,
                ),
                pde_kwargs=dict(f_fn=f_fn),
                bc_data=(x_bc, u_bc),
                domain=(0.0, 1.0),
                quadrature="gauss",
                n_quad=20,
                beta_bc=500.0,
                optimizer="adamw",
                num_steps=args.steps,
                lr=args.lr,
                lbfgs_steps=args.lbfgs_steps,
            )
            solver.train()
            x_te = jnp.linspace(0, 1, 300)[:, None]
            u_pred = solver.predict(x_te)
            u_true = u_ex(x_te)[:, None]
            m = compute_metrics(u_true, u_pred)
            print("  Metrics:", {k: f"{v:.3e}" for k, v in m.items()})
            plot_pde_1d(x_te, u_pred, u_true, "LSPG Poisson 1D")
        else:
            poisson_2d_deep_ritz(
                steps=args.steps, lr=args.lr, lbfgs_steps=args.lbfgs_steps
            )
    else:
        raise ValueError(f"Unsupported: pde={args.pde} formulation={args.formulation}")


def add_args(parser):
    parser.add_argument(
        "--pde",
        default="poisson",
        choices=[
            "poisson",
            "variable_poisson",
            "burgers",
            "helmholtz",
            "allen_cahn",
            "cahn_hilliard",
            "navier_stokes",
        ],
    )
    parser.add_argument("--formulation", default="lspg", choices=["deep_ritz", "lspg"])
    parser.add_argument("--dim", type=int, default=2, choices=[1, 2])
    parser.add_argument("--steps", type=int, default=5000)
    parser.add_argument("--lr", type=float, default=1e-3)
    parser.add_argument("--lbfgs-steps", type=int, default=300)
    parser.add_argument("--adaptive", action="store_true")
    parser.add_argument("--xpinn", action="store_true")
    parser.add_argument("--n-subdomains", type=int, default=3)
    parser.add_argument(
        "--eps",
        type=float,
        default=0.1,
        help="Interface width parameter (Allen-Cahn / Cahn-Hilliard)",
    )
    parser.add_argument(
        "--nu", type=float, default=0.05, help="Kinematic viscosity (Navier-Stokes)"
    )


if __name__ == "__main__":
    import argparse

    p = argparse.ArgumentParser()
    add_args(p)
    run(p.parse_args())


# ── Allen-Cahn phase-field equation ───────────────────────────────────────────


def allen_cahn_1d_lspg(steps=6000, lr=1e-3, lbfgs_steps=300, eps=0.1):
    """Allen-Cahn: u_t = eps^2 u_xx - (u^3-u), u(x,0)=x^2 cos(pi x), periodic-ish BC via u(-1,t)=u(1,t)=-1."""
    print(f"\n=== LSPG: Allen-Cahn 1D+t (eps={eps}) ===")
    key = jax.random.PRNGKey(0)
    x_ic = jax.random.uniform(key, (300, 1), minval=-1.0, maxval=1.0)
    t_ic = jnp.zeros((300, 1))
    xt_ic = jnp.concatenate([x_ic, t_ic], axis=1)
    u_ic = x_ic[:, 0:1] ** 2 * jnp.cos(jnp.pi * x_ic)

    t_bc = jax.random.uniform(jax.random.PRNGKey(1), (200, 1))
    x_bc = jnp.concatenate(
        [
            jnp.concatenate([-jnp.ones((200, 1)), t_bc], axis=1),
            jnp.concatenate([jnp.ones((200, 1)), t_bc], axis=1),
        ],
        axis=0,
    )
    u_bc = -jnp.ones((400, 1))

    solver = VariationalSolver(
        pde_type="allen_cahn",
        formulation="lspg",
        dim=1,
        model_kwargs=dict(
            layer_dims=[2, 32, 32, 1],
            kernel_name="matern_25_poly1",
            num_grids=14,
            grid_type="gauss",
            use_mls_norm=True,
            use_pruning=True,
            trainable_centers=True,
            trainable_sigma=True,
        ),
        pde_kwargs=dict(eps=eps),
        bc_data=(x_bc, u_bc),
        ic_data=(xt_ic, u_ic),
        domain=(-1.0, 1.0),
        t_end=1.0,
        quadrature="halton",
        n_quad=80,
        beta_bc=200.0,
        beta_ic=200.0,
        adaptive_resample=True,
        resample_every=800,
        optimizer="adamw",
        num_steps=steps,
        lr=lr,
        lam0_max=2e-4,
        lbfgs_steps=lbfgs_steps,
    )
    solver.train()

    t_slices = [0.0, 0.3, 0.6, 1.0]
    x_plot = jnp.linspace(-1, 1, 200)[:, None]
    fig_data = []
    for tv in t_slices:
        xt_plot = jnp.concatenate([x_plot, jnp.full_like(x_plot, tv)], axis=1)
        fig_data.append(np.asarray(solver.predict(xt_plot))[:, 0])
    import matplotlib.pyplot as plt

    plt.figure(figsize=(8, 4))
    for tv, u in zip(t_slices, fig_data):
        plt.plot(np.asarray(x_plot)[:, 0], u, label=f"t={tv}")
    plt.xlabel("x")
    plt.ylabel("u")
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.title(f"Allen-Cahn 1D+t solution (LSPG, eps={eps})")
    plt.tight_layout()
    plt.show()
    plot_training([solver.history], ["Allen-Cahn LSPG"])
    return solver


# ── Cahn-Hilliard equation ────────────────────────────────────────────────────


def cahn_hilliard_1d_lspg(steps=4000, lr=1e-3, lbfgs_steps=200, eps=0.1):
    """Cahn-Hilliard via the mixed formulation:
        u_t = Delta(mu),  mu = u^3 - u - eps^2 Delta(u)
    Two coupled scalar K-KAN models (see kkan.solvers.CahnHilliardSolver).
    Avoids the 4th-order single-model formulation, which triggers an XLA
    compiler crash when differentiated through for training (see docs).
    """
    print(f"\n=== LSPG (mixed): Cahn-Hilliard 1D+t (eps={eps}) ===")
    from kkan.solvers import CahnHilliardSolver

    key = jax.random.PRNGKey(2)
    x_ic = jax.random.uniform(key, (250, 1), minval=-1.0, maxval=1.0)
    t_ic = jnp.zeros((250, 1))
    xt_ic = jnp.concatenate([x_ic, t_ic], axis=1)
    u_ic = 0.1 * jnp.sin(jnp.pi * x_ic)
    t_bc = jax.random.uniform(jax.random.PRNGKey(3), (150, 1))
    x_bc = jnp.concatenate(
        [
            jnp.concatenate([-jnp.ones((150, 1)), t_bc], axis=1),
            jnp.concatenate([jnp.ones((150, 1)), t_bc], axis=1),
        ],
        axis=0,
    )
    u_bc = jnp.zeros((300, 1))

    solver = CahnHilliardSolver(
        model_kwargs_u=dict(
            layer_dims=[2, 24, 24, 1],
            kernel_name="matern_25_poly2",
            num_grids=12,
            use_pruning=False,
            use_mls_norm=True,
            trainable_centers=True,
            trainable_sigma=True,
        ),
        model_kwargs_mu=dict(
            layer_dims=[2, 24, 24, 1],
            kernel_name="matern_25_poly2",
            num_grids=12,
            use_pruning=False,
            use_mls_norm=True,
            trainable_centers=True,
            trainable_sigma=True,
        ),
        eps=eps,
        bc_data=(x_bc, u_bc),
        ic_data=(xt_ic, u_ic),
        domain=(-1.0, 1.0),
        t_end=0.5,
        n_quad=60,
        beta_bc=300.0,
        beta_ic=300.0,
        beta_couple=50.0,
        optimizer="adamw",
        num_steps=steps,
        lr=lr,
        lbfgs_steps=lbfgs_steps,
    )
    solver.train()

    t_slices = [0.0, 0.15, 0.3, 0.5]
    x_plot = jnp.linspace(-1, 1, 200)[:, None]
    import matplotlib.pyplot as plt

    plt.figure(figsize=(8, 4))
    for tv in t_slices:
        xt_plot = jnp.concatenate([x_plot, jnp.full_like(x_plot, tv)], axis=1)
        u_p = np.asarray(solver.predict_u(xt_plot))[:, 0]
        plt.plot(np.asarray(x_plot)[:, 0], u_p, label=f"t={tv}")
    plt.xlabel("x")
    plt.ylabel("u")
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.title(f"Cahn-Hilliard 1D+t solution (mixed LSPG, eps={eps})")
    plt.tight_layout()
    plt.show()
    plot_training([solver.history], ["Cahn-Hilliard mixed LSPG"])
    return solver


# ── Navier-Stokes (stream-function/vorticity), lid-driven cavity ────────────


def navier_stokes_cavity_lspg(steps=4000, lr=1e-3, lbfgs_steps=200, nu=0.05):
    """Steady 2D lid-driven cavity via the mixed stream-function/vorticity
    formulation:  Delta(psi) = -omega,  u.grad(omega) = nu*Delta(omega).
    Two coupled scalar K-KAN models (see kkan.solvers.NavierStokesCavitySolver).
    Domain [0,1]^2, psi=0 on all walls (no-penetration streamline BC).
    """
    print(f"\n=== LSPG (mixed): Navier-Stokes lid-driven cavity (nu={nu}) ===")
    from kkan.solvers import NavierStokesCavitySolver

    n_bc = 60
    t = jnp.linspace(0, 1, n_bc)
    bottom = jnp.stack([t, jnp.zeros_like(t)], axis=1)
    top = jnp.stack([t, jnp.ones_like(t)], axis=1)
    left = jnp.stack([jnp.zeros_like(t), t], axis=1)
    right = jnp.stack([jnp.ones_like(t), t], axis=1)
    x_bc_psi = jnp.concatenate([bottom, top, left, right], axis=0)
    u_bc_psi = jnp.zeros((x_bc_psi.shape[0], 1))

    solver = NavierStokesCavitySolver(
        model_kwargs_psi=dict(
            layer_dims=[2, 20, 1],
            kernel_name="matern_25",
            num_grids=20,
            use_pruning=False,
            use_mls_norm=False,
            trainable_centers=True,
            trainable_sigma=True,
        ),
        model_kwargs_omega=dict(
            layer_dims=[2, 20, 1],
            kernel_name="matern_25",
            num_grids=20,
            use_pruning=False,
            use_mls_norm=False,
            trainable_centers=True,
            trainable_sigma=True,
        ),
        nu=nu,
        bc_data_psi=(x_bc_psi, u_bc_psi),
        domain=(0.0, 1.0),
        n_quad=11,
        beta_bc=2000.0,
        beta_couple=10.0,
        optimizer="adamw",
        num_steps=steps,
        lr=lr,
        lbfgs_steps=lbfgs_steps,
    )
    solver.train()

    n = 30
    t2 = jnp.linspace(0, 1, n)
    xx, yy = jnp.meshgrid(t2, t2)
    x_te = jnp.stack([xx.ravel(), yy.ravel()], axis=-1)
    psi_pred = np.asarray(solver.predict_psi(x_te))[:, 0].reshape(xx.shape)
    vel = np.asarray(solver.predict_velocity(x_te))

    import matplotlib.pyplot as plt

    fig, axes = plt.subplots(1, 2, figsize=(12, 5))
    im = axes[0].contourf(
        np.asarray(xx), np.asarray(yy), psi_pred, levels=25, cmap="RdBu_r"
    )
    axes[0].set_title("Stream function psi")
    plt.colorbar(im, ax=axes[0])
    step = 2
    axes[1].quiver(
        np.asarray(xx)[::step, ::step],
        np.asarray(yy)[::step, ::step],
        vel[:, 0].reshape(xx.shape)[::step, ::step],
        vel[:, 1].reshape(xx.shape)[::step, ::step],
    )
    axes[1].set_title("Velocity field (u,v)")
    plt.suptitle(f"Navier-Stokes cavity (mixed LSPG, nu={nu})")
    plt.tight_layout()
    plt.show()
    plot_training([solver.history], ["Navier-Stokes mixed LSPG"])
    return solver
