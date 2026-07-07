"""model/joint_training.py — High-level API for joint function+gradient learning.

This wraps the best-performing combination found for simultaneous u(x) and
∇u(x) approximation: HermiteKKAN (kernel + derivative-basis edges) trained
with the Sobolev (H^1) loss via two-stage Adam→L-BFGS optimisation.

Empirically (see docs/kkan_theory.pdf, "Derivative Learning" section) this
combination outperforms both value-only RBF differentiation and direct
Hermite-Birkhoff collocation, because:
  1. The derivative-basis edges (k'(r)·sign(Δx)) give the model an explicit
     odd-symmetry component that pure kernel sums (even functions) cannot
     represent, raising the effective approximation order.
  2. The Sobolev loss directly penalises gradient error at every training
     step, rather than relying on a linear system whose conditioning
     degrades rapidly with the number of derivative constraints.
  3. Trainable centres/bandwidths let the model relocate representational
     capacity to high-curvature regions, unlike fixed-centre collocation.
"""

from __future__ import annotations
from typing import Optional, Sequence, Tuple
import time
import jax, jax.numpy as jnp, numpy as np, optax

from .gradient_enhanced_layer import HermiteKKAN, sobolev_loss, native_space_regulariser
from ..utils.lbfgs import lbfgs_minimize


def fit_with_gradients(
    x: jnp.ndarray,
    u: jnp.ndarray,
    du: Optional[jnp.ndarray] = None,
    d2u: Optional[jnp.ndarray] = None,
    layer_dims: Optional[Sequence[int]] = None,
    kernel_name: str = "matern_25",
    num_grids: int = 14,
    lambda_grad: float = 5.0,
    lambda_hess: float = 0.1,
    lambda_rkhs: float = 0.0,
    adam_steps: int = 3000,
    lbfgs_steps: int = 300,
    lr: float = 2e-3,
    seed: int = 0,
    verbose: bool = True,
) -> Tuple["HermiteKKAN", dict]:
    """
    Fit a K-KAN to simultaneously approximate u(x) and (optionally) ∇u(x),
    ∇²u(x), using the Sobolev-loss + derivative-basis-edge combination.

    Args:
        x:  (N, d) training points
        u:  (N,) or (N,1) function values
        du: (N, d) gradient values (optional — if given, trains jointly)
        d2u: (N, d, d) Hessian values (optional, expensive)
        layer_dims: KAN architecture; defaults to [d, 16, 16, 1]
        lambda_grad: weight on the gradient term of the Sobolev loss
        lambda_rkhs: weight on the native-space (RKHS) smoothness penalty

    Returns:
        (model, params) — call model.apply(params, x_query, deterministic=True)
        for values, or jax.grad on a scalar wrapper for gradients (see
        predict_with_gradients below for a convenience wrapper).
    """
    x = jnp.asarray(x, dtype=jnp.float32)
    u = jnp.asarray(u, dtype=jnp.float32).reshape(-1, 1)
    du_t = jnp.asarray(du, dtype=jnp.float32) if du is not None else None
    d2u_t = jnp.asarray(d2u, dtype=jnp.float32) if d2u is not None else None

    d = x.shape[1]
    if layer_dims is None:
        layer_dims = [d, 16, 16, 1]

    model = HermiteKKAN(
        layer_dims=list(layer_dims),
        kernel_name=kernel_name,
        num_grids=num_grids,
        use_deriv_basis=(du is not None),
        trainable_centers=True,
        trainable_sigma=True,
    )
    params = model.init(jax.random.PRNGKey(seed), x[:1], deterministic=True)

    def loss_fn(p, deterministic):
        L = sobolev_loss(
            p,
            model,
            x,
            u,
            du_target=du_t,
            d2u_target=d2u_t,
            lambda_grad=lambda_grad,
            lambda_hess=lambda_hess,
            deterministic=deterministic,
        )
        if lambda_rkhs > 0:
            L = L + lambda_rkhs * native_space_regulariser(p, layer_idx=0)
        return L

    opt = optax.chain(
        optax.clip_by_global_norm(1.0),
        optax.adamw(optax.cosine_decay_schedule(lr, adam_steps)),
    )
    opt_state = opt.init(params)

    @jax.jit
    def step(params, opt_state):
        loss, grads = jax.value_and_grad(lambda p: loss_fn(p, False))(params)
        updates, new_opt = opt.update(grads, opt_state, params)
        return optax.apply_updates(params, updates), new_opt, loss

    t0 = time.time()
    for i in range(adam_steps):
        params, opt_state, loss = step(params, opt_state)
        if verbose and (i % max(adam_steps // 5, 1) == 0 or i == adam_steps - 1):
            print(f"  [fit_with_gradients] step {i:5d}  loss={float(loss):.4e}")

    if lbfgs_steps > 0:
        params, final = lbfgs_minimize(
            lambda p: loss_fn(p, True),
            params,
            maxiter=lbfgs_steps,
            tol=1e-12,
            verbose=verbose,
        )
    if verbose:
        print(f"  Total time: {time.time() - t0:.1f}s")

    return model, params


def predict_with_gradients(model, params, x_query: jnp.ndarray):
    """
    Evaluate both u(x) and ∇u(x) at query points using automatic
    differentiation of the fitted model (exact, not finite-difference).

    Returns:
        u_pred:  (N,) function values
        du_pred: (N, d) gradient values
    """
    x_query = jnp.asarray(x_query, dtype=jnp.float32)
    u_fn = lambda xi: model.apply(params, xi[None], deterministic=True)[0, 0]
    u_pred = jax.vmap(u_fn)(x_query)
    du_pred = jax.vmap(jax.grad(u_fn))(x_query)
    return np.asarray(u_pred), np.asarray(du_pred)
