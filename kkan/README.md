# K-KAN: Kernel Kolmogorov-Arnold Networks

A modular library combining:
- **Multiple kernel families**: RBF, Inverse Multiquadric, Matérn (ν=0.5/1.5/2.5),
  Wendland (C0-C6, compact support), Wu (C2/C4, compact support), polynomial-augmented variants.
- **Adaptive, prunable K-KAN layers**: Gauss-Legendre/Chebyshev quadrature-node grids,
  Moving-Least-Squares (MLS) partition-of-unity normalisation, Hard-Concrete L0 edge pruning.
- **Variational PDE solvers**: Deep Ritz energy minimisation, Least-Squares Petrov-Galerkin
  (LSPG) with Gauss/Halton quadrature, adaptive residual-based collocation resampling,
  XPINN domain decomposition.
- **Direct meshless PDE solvers** (no gradient descent): Kansa unsymmetric collocation,
  symmetric Galerkin normal-equations collocation, RKPM/MLS interpolant, implicit
  backward-Euler Method of Lines.
- **Derivative/gradient approximation**: Hermite-Birkhoff collocation (fits u AND ∇u
  simultaneously for super-convergent gradients), quasi-interpolation (Shepard, Modified
  Shepard, Gaussian), Sobolev-norm (H¹) training loss, gradient-enhanced KAN edges with
  derivative basis functions, native-space (RKHS) regularisation.

## Installation

```bash
pip install jax jaxlib flax optax scipy numpy matplotlib
```

## Quick start

```bash
# Kernel families
python main.py kernels --list
python main.py kernels --plot-profiles
python main.py kernels --compare-2d --target oscillatory

# Function approximation (1D/2D/3D)
python main.py approx --dim 1 --target runge   --kernel matern_25_poly2
python main.py approx --dim 2 --target franke  --kernel rbf_poly2 --prune
python main.py approx --dim 3 --target gaussian_3d --kernel matern_25 --no-prune

# Variational / PINN-family PDE solvers
python main.py pinn --pde poisson          --formulation deep_ritz --dim 2
python main.py pinn --pde variable_poisson --formulation lspg --dim 1 --adaptive
python main.py pinn --pde burgers          --formulation lspg
python main.py pinn --pde helmholtz        --formulation lspg --dim 2
python main.py pinn --pde poisson          --formulation lspg --dim 1 --xpinn

# Direct meshless solvers
python main.py meshless --method kansa    --dim 1
python main.py meshless --method galerkin --dim 2
python main.py meshless --method rkpm
python main.py meshless --method mol
python main.py meshless --method all

# Derivative / gradient approximation
python main.py derivatives --exp runge1d
python main.py derivatives --exp gradfield2d
python main.py derivatives --exp convergence
python main.py derivatives --exp rkhs-reg
python main.py derivatives --exp all
```

All commands accept `--lbfgs-steps` (and `pinn`/`approx` accept `--steps`/`--lr`) to scale
runtime up or down. Reasonable smoke-test values: `--steps 50 --lbfgs-steps 20`.
Production-quality runs: defaults (`--steps 4000-8000`, `--lbfgs-steps 300-500`).

## Project layout

```
kkan/
├── main.py                          CLI entrypoint
├── kkan/                            library package
│   ├── kernels/{families,derivatives}.py
│   ├── model/{kan_layer,gradient_enhanced_layer,pruning}.py
│   ├── solvers/{variational_solver,meshless_solver}.py
│   ├── approximation/{hermite_collocation,quasi_interpolation}.py
│   └── utils/{data,training,lbfgs,quadrature,diff_ops,visualization}.py
├── experiments/                     one file per feature area
│   ├── exp_kernels.py
│   ├── exp_approx.py
│   ├── exp_pinn_variational.py
│   ├── exp_meshless.py
│   └── exp_derivatives.py
└── docs/                            mathematical reference (Typst source)
```

## Notes on numerical stability

- L-BFGS refinement uses a scipy-driven optimiser (`kkan/utils/lbfgs.py`) wrapping a
  single jitted JAX `value_and_grad`, rather than `jaxopt.LBFGS`. This avoids a known
  pathology where jaxopt traces its entire optimisation loop (including line search)
  through `lax.while_loop`, which becomes catastrophically slow to compile when the loss
  involves nested second derivatives (PDE Laplacian residuals).
- All kernel derivative formulas (`kkan/kernels/derivatives.py`) are verified against
  `jax.grad`/`jax.hessian` autodiff ground truth and are safe (NaN-free) at `r=0`, which
  always occurs on the diagonal of meshless collocation matrices since data points
  double as kernel centres.
- Compactly-supported kernels (Wendland, Wu) can become severely ill-conditioned when the
  bandwidth `sigma` is small relative to the inter-point spacing — this shows up as
  negative R² in the `meshless` experiments and is expected numerical behaviour, not a bug.

## What's new in this update

- **Fixed gradient/derivative learning**: the Hermite-Birkhoff collocation
  system had a sign-convention bug in its derivative-derivative block that
  silently corrupted gradient predictions (they were 5-6x *worse* than a
  plain value-only fit). Now fixed and verified: Hermite collocation beats
  the value-only baseline by 6-8x on both value and gradient error, matching
  theory. See `docs/kkan_theory.pdf` §7 for the full diagnosis.
- **New high-level API**: `kkan.model.fit_with_gradients(x, u, du=...)` and
  `predict_with_gradients(model, params, x_query)` — the recommended entry
  point for joint function+gradient learning (best empirical results:
  gradient-enhanced KAN edges + Sobolev loss).
- **Three new LSPG PDE examples**:
  - `python main.py pinn --pde allen_cahn` — phase-field reaction-diffusion
  - `python main.py pinn --pde cahn_hilliard` — mixed-formulation (two
    coupled 2nd-order fields, avoiding a 4th-order single-model XLA crash)
  - `python main.py pinn --pde navier_stokes` — steady 2D lid-driven cavity
    via mixed stream-function/vorticity formulation
- **`docs/kkan_theory.pdf`**: complete mathematical reference covering every
  module — kernels, KAN layers, MLS normalisation, pruning, variational and
  meshless PDE solvers, derivative learning (including the bug/fix above),
  and the mixed-formulation approach for 4th-order PDEs.
