"""experiments/exp_approx.py — Function approximation 1D/2D/3D with adaptive grids & pruning.

Run:
    python main.py approx --dim 1 --target runge --kernel matern_25_poly2
    python main.py approx --dim 2 --target franke --kernel rbf_poly2 --prune
    python main.py approx --dim 3 --target gaussian_3d --kernel matern_25 --no-prune
"""
import sys, os; sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import jax, jax.numpy as jnp
from kkan.model import KKAN, count_params, pruning_report
from kkan.utils import (make_1d, make_2d, make_3d, TARGETS_1D, TARGETS_2D, TARGETS_3D,
                          train_two_stage, train_optax, compute_metrics,
                          plot_1d, plot_2d, plot_training, plot_gate_heatmap)


def run_1d(target="runge", kernel="matern_25_poly2", layer_dims=(1,16,16,1),
           num_grids=12, steps=4000, lr=2e-3, prune=True, grid_type="gauss",
           lbfgs_steps=300):
    print(f"\n=== 1D approximation | target={target} | kernel={kernel} ===")
    fn = TARGETS_1D[target]
    (x_tr,y_tr),(x_te,y_te) = make_1d(fn, n_train=600, n_test=400)
    model = KKAN(layer_dims=list(layer_dims), kernel_name=kernel, num_grids=num_grids,
                 grid_type=grid_type, use_mls_norm=True, use_pruning=prune,
                 trainable_centers=True, trainable_sigma=True)
    params = model.init(jax.random.PRNGKey(0), x_tr[:1], deterministic=True)
    print(f"  Parameters: {count_params(params)}")
    params, history = train_two_stage(model, params, x_tr, y_tr, adam_steps=steps,
                                       lr=lr, lam0_max=5e-4 if prune else 0.0,
                                       lbfgs_steps=lbfgs_steps)
    y_pred = model.apply(params, x_te, deterministic=True)
    m = compute_metrics(y_te, y_pred)
    print("  Metrics:", {k:f"{v:.3e}" for k,v in m.items()})
    if prune: print(pruning_report(params, list(layer_dims)))
    plot_1d(x_te, y_te, y_pred, title=f"1D {target} / {kernel}")
    plot_training([history],[kernel])
    if prune: plot_gate_heatmap(params, list(layer_dims))
    return m, params


def run_2d(target="franke", kernel="rbf_poly2", layer_dims=(2,20,20,1),
           num_grids=10, steps=5000, lr=2e-3, prune=True, grid_type="chebyshev",
           lbfgs_steps=300):
    print(f"\n=== 2D approximation | target={target} | kernel={kernel} ===")
    fn = TARGETS_2D[target]
    (x_tr,y_tr),(x_te,y_te),(xx,yy) = make_2d(fn, n_train=2000)
    model = KKAN(layer_dims=list(layer_dims), kernel_name=kernel, num_grids=num_grids,
                 grid_type=grid_type, use_mls_norm=True, use_pruning=prune,
                 trainable_centers=True, trainable_sigma=True)
    params = model.init(jax.random.PRNGKey(0), x_tr[:1], deterministic=True)
    print(f"  Parameters: {count_params(params)}")
    params, history = train_two_stage(model, params, x_tr, y_tr, adam_steps=steps,
                                       lr=lr, lam0_max=5e-4 if prune else 0.0,
                                       lbfgs_steps=lbfgs_steps)
    y_pred = model.apply(params, x_te, deterministic=True)
    m = compute_metrics(y_te, y_pred)
    print("  Metrics:", {k:f"{v:.3e}" for k,v in m.items()})
    if prune: print(pruning_report(params, list(layer_dims)))
    plot_2d(y_te, y_pred, xx, yy, title=f"2D {target} / {kernel}")
    if prune: plot_gate_heatmap(params, list(layer_dims))
    return m, params


def run_3d(target="gaussian_3d", kernel="matern_25", layer_dims=(3,24,16,1),
           num_grids=8, steps=5000, lr=2e-3, prune=False):
    print(f"\n=== 3D approximation | target={target} | kernel={kernel} ===")
    fn = TARGETS_3D[target]
    (x_tr,y_tr),(x_te,y_te) = make_3d(fn, n_train=6000, n_test=2000)
    model = KKAN(layer_dims=list(layer_dims), kernel_name=kernel, num_grids=num_grids,
                 grid_type="gauss", use_mls_norm=True, use_pruning=prune,
                 trainable_centers=True, trainable_sigma=True)
    params = model.init(jax.random.PRNGKey(0), x_tr[:1], deterministic=True)
    print(f"  Parameters: {count_params(params)}")
    params, history = train_optax(model, params, x_tr, y_tr, "adamw",
                                  num_steps=steps, lr=lr, batch_size=512)
    y_pred = model.apply(params, x_te, deterministic=True)
    m = compute_metrics(y_te, y_pred)
    print("  Metrics:", {k:f"{v:.3e}" for k,v in m.items()})
    plot_training([history],[f"{kernel} (3D)"])
    return m, params


def run(args):
    if args.dim==1:
        run_1d(target=args.target, kernel=args.kernel, steps=args.steps, lr=args.lr,
              prune=args.prune, lbfgs_steps=args.lbfgs_steps)
    elif args.dim==2:
        run_2d(target=args.target, kernel=args.kernel, steps=args.steps, lr=args.lr,
              prune=args.prune, lbfgs_steps=args.lbfgs_steps)
    else:
        run_3d(target=args.target, kernel=args.kernel, steps=args.steps, lr=args.lr,
              prune=args.prune)


def add_args(parser):
    parser.add_argument("--dim", type=int, default=2, choices=[1,2,3])
    parser.add_argument("--target", default=None)
    parser.add_argument("--kernel", default="matern_25_poly2")
    parser.add_argument("--steps", type=int, default=4000)
    parser.add_argument("--lr", type=float, default=2e-3)
    parser.add_argument("--lbfgs-steps", type=int, default=300,
                        help="L-BFGS iterations (reduce for fast smoke tests)")
    parser.add_argument("--prune", action="store_true", default=True)
    parser.add_argument("--no-prune", dest="prune", action="store_false")


if __name__ == "__main__":
    import argparse; p=argparse.ArgumentParser(); add_args(p); a=p.parse_args()
    if a.target is None: a.target={1:"runge",2:"franke",3:"gaussian_3d"}[a.dim]
    run(a)
