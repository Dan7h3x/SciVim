#!/usr/bin/env python3
"""
K-KAN: Kernel Kolmogorov-Arnold Networks — unified experiment launcher.

Commands:
    kernels      Kernel family visualization & comparison
    approx       Function approximation (1D/2D/3D) with adaptive grids & pruning
    pinn         Variational PDE solvers (Deep Ritz, LSPG, adaptive, XPINN)
    meshless     Direct meshless PDE solvers (Kansa, Galerkin, RKPM, MOL)
    derivatives  Derivative/gradient approximation (Hermite, quasi-interp, Sobolev)

Examples:
    python main.py kernels --list
    python main.py kernels --plot-profiles
    python main.py kernels --compare-2d --target oscillatory

    python main.py approx --dim 1 --target runge   --kernel matern_25_poly2
    python main.py approx --dim 2 --target franke  --kernel rbf_poly2 --prune
    python main.py approx --dim 3 --target gaussian_3d --kernel matern_25 --no-prune

    python main.py pinn --pde poisson          --formulation deep_ritz --dim 2
    python main.py pinn --pde variable_poisson  --formulation lspg --dim 1 --adaptive
    python main.py pinn --pde burgers           --formulation lspg
    python main.py pinn --pde helmholtz         --formulation lspg --dim 2
    python main.py pinn --pde poisson           --formulation lspg --dim 1 --xpinn

    python main.py meshless --method kansa    --dim 1
    python main.py meshless --method galerkin --dim 2
    python main.py meshless --method rkpm
    python main.py meshless --method mol
    python main.py meshless --method all

    python main.py derivatives --exp runge1d
    python main.py derivatives --exp gradfield2d
    python main.py derivatives --exp convergence
    python main.py derivatives --exp rkhs-reg
    python main.py derivatives --exp all

See docs/kkan_theory.pdf for the full mathematical reference.
"""

import argparse, sys, os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from experiments import (
    exp_kernels,
    exp_approx,
    exp_pinn_variational,
    exp_meshless,
    exp_derivatives,
)

COMMANDS = {
    "kernels": exp_kernels,
    "approx": exp_approx,
    "pinn": exp_pinn_variational,
    "meshless": exp_meshless,
    "derivatives": exp_derivatives,
}


def build_parser():
    parser = argparse.ArgumentParser(
        prog="main.py",
        description="K-KAN: Kernel Kolmogorov-Arnold Networks — experiment launcher",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = parser.add_subparsers(dest="command", required=True)
    for name, module in COMMANDS.items():
        doc = module.__doc__.strip().split("\n")[0] if module.__doc__ else ""
        s = sub.add_parser(
            name,
            help=doc,
            formatter_class=argparse.RawDescriptionHelpFormatter,
            description=module.__doc__,
        )
        module.add_args(s)
    return parser


def main():
    args = build_parser().parse_args()
    module = COMMANDS[args.command]
    if args.command == "approx" and getattr(args, "target", None) is None:
        args.target = {1: "runge", 2: "franke", 3: "gaussian_3d"}[args.dim]
    module.run(args)


if __name__ == "__main__":
    main()
