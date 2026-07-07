"""experiments/exp_kernels.py — Kernel family visualization and comparison.

Run:
    python main.py kernels --list
    python main.py kernels --plot-profiles
    python main.py kernels --compare-2d --target oscillatory --steps 500
"""

import sys, os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import jax, jax.numpy as jnp
from kkan.kernels import get_kernel, KERNEL_REGISTRY
from kkan.model import KKAN, count_params
from kkan.utils import (
    make_2d,
    TARGETS_2D,
    train_optax,
    compute_metrics,
    plot_kernels,
    plot_training,
)


def list_registry():
    print("Available kernels:")
    for name in sorted(KERNEL_REGISTRY):
        k = get_kernel(name)
        print(f"  {name:24s}  {k!r}")


def plot_profiles(names=None):
    if names is None:
        names = [
            "rbf",
            "imq",
            "matern_05",
            "matern_15",
            "matern_25",
            "wendland_c0",
            "wendland_c2",
            "wendland_c4",
            "wu_c2",
        ]
    print(f"Plotting {len(names)} kernel profiles...")
    plot_kernels(names)


def compare_2d(
    target="oscillatory",
    steps=3000,
    kernels=(
        "rbf",
        "matern_25",
        "wendland_c4",
        "wu_c2",
        "rbf_poly2",
        "matern_25_poly2",
    ),
):
    print(f"\n=== Kernel comparison on 2D '{target}' ===")
    fn = TARGETS_2D[target]
    (x_tr, y_tr), (x_te, y_te), _ = make_2d(fn, n_train=2000)
    histories, labels, results = [], [], {}
    for kname in kernels:
        model = KKAN(
            layer_dims=[2, 16, 16, 1],
            kernel_name=kname,
            num_grids=10,
            use_pruning=False,
            use_mls_norm=True,
        )
        params = model.init(jax.random.PRNGKey(0), x_tr[:1], deterministic=True)
        params, h = train_optax(
            model,
            params,
            x_tr,
            y_tr,
            "adamw",
            num_steps=steps,
            lr=3e-3,
            log_every=max(steps // 4, 1),
        )
        y_pred = model.apply(params, x_te, deterministic=True)
        m = compute_metrics(y_te, y_pred)
        results[kname] = m
        histories.append(h)
        labels.append(kname)
        print(f"  {kname:24s}  RMSE={m['RMSE']:.3e}  R2={m['R2']:.4f}")
    plot_training(histories, labels, f"Kernel comparison — 2D {target}")
    return results


def run(args):
    if args.list:
        list_registry()
    if args.plot_profiles:
        plot_profiles()
    if args.compare_2d:
        compare_2d(target=args.target, steps=args.steps)


def add_args(parser):
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--plot-profiles", action="store_true")
    parser.add_argument("--compare-2d", action="store_true")
    parser.add_argument(
        "--target",
        default="oscillatory",
        choices=["gaussian_mix", "oscillatory", "franke", "peaks"],
    )
    parser.add_argument("--steps", type=int, default=3000)


if __name__ == "__main__":
    import argparse

    p = argparse.ArgumentParser()
    add_args(p)
    run(p.parse_args())
