"""utils/lbfgs.py — L-BFGS via scipy, calling a jitted JAX value_and_grad.

Why not jaxopt.LBFGS?
  jaxopt traces its entire loop (including line-search) as lax.while_loop.
  When the loss involves nested Hessians (PDE Laplacian residuals), this
  triggers third-order-derivative graph expansion that takes hours to compile.
  Driving scipy's L-BFGS-B with a singly-jitted JAX value_and_grad avoids
  this entirely: JAX compiles once, scipy drives the iteration in Python.
"""
import time, numpy as np
import jax, jax.numpy as jnp
from scipy.optimize import minimize


def _flat(params):
    leaves, td = jax.tree_util.tree_flatten(params)
    shapes = [np.asarray(l).shape for l in leaves]
    sizes  = [int(np.prod(s)) if s else 1 for s in shapes]
    x0 = np.concatenate([np.asarray(l).ravel() for l in leaves]).astype(np.float64)
    return x0, td, shapes, sizes


def _unflat(x, td, shapes, sizes):
    parts, idx = [], 0
    for s, sz in zip(shapes, sizes):
        parts.append(jnp.array(x[idx:idx+sz], dtype=jnp.float32).reshape(s))
        idx += sz
    return jax.tree_util.tree_unflatten(td, parts)


def lbfgs_minimize(loss_fn, params, maxiter=300, tol=1e-11, verbose=True):
    """Minimise loss_fn(params) via scipy L-BFGS-B + jitted JAX gradients."""
    x0, td, shapes, sizes = _flat(params)
    vg = jax.jit(jax.value_and_grad(loss_fn))

    def obj(x):
        p = _unflat(x, td, shapes, sizes)
        v, g = vg(p)
        gf = np.concatenate([np.asarray(gl).ravel()
                              for gl in jax.tree_util.tree_leaves(g)])
        return float(v), gf.astype(np.float64)

    t0 = time.time()
    res = minimize(obj, x0, jac=True, method="L-BFGS-B",
                   options=dict(maxiter=maxiter, ftol=tol, gtol=tol))
    if verbose:
        print(f"  [L-BFGS] iters={res.nit}  loss={res.fun:.4e}  time={time.time()-t0:.1f}s")
    return _unflat(res.x, td, shapes, sizes), float(res.fun)
