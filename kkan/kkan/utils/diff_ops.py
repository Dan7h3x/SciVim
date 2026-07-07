"""utils/diff_ops.py — PDE differential operators via JAX automatic differentiation."""
import jax, jax.numpy as jnp


def _scalar(model, params):
    def fn(xi): return model.apply(params, xi[None], deterministic=True)[0,0]
    return fn


def grad_u(model, params, x):
    """∇u(x). Shape: (batch, d)."""
    return jax.vmap(jax.grad(_scalar(model, params)))(x)


def laplacian_u(model, params, x):
    """Δu = tr(∇²u). Shape: (batch,)."""
    fn = _scalar(model, params)
    return jax.vmap(lambda xi: jnp.trace(jax.hessian(fn)(xi)))(x)


def bilaplacian_u(model, params, x):
    """Δ²u. Shape: (batch,)."""
    fn = _scalar(model, params)
    lap = lambda xi: jnp.trace(jax.hessian(fn)(xi))
    return jax.vmap(lambda xi: jnp.trace(jax.hessian(lap)(xi)))(x)


def div_grad_a_u(model, params, x, a_fn):
    """∇·(a∇u) = ∇a·∇u + a·Δu."""
    fn = _scalar(model, params)
    def single(xi):
        gu  = jax.grad(fn)(xi)
        a   = a_fn(xi[None])[0]
        ga  = jax.grad(lambda z: a_fn(z[None])[0])(xi)
        lap = jnp.trace(jax.hessian(fn)(xi))
        return jnp.dot(ga, gu) + a*lap
    return jax.vmap(single)(x)


def grad_t(model, params, xt):
    """∂u/∂t, last coord = time. Shape: (batch,)."""
    fn = _scalar(model, params)
    t_idx = xt.shape[1]-1
    return jax.vmap(lambda xi: jax.grad(fn)(xi)[t_idx])(xt)


def u_tt(model, params, xt):
    """∂²u/∂t². Shape: (batch,)."""
    fn = _scalar(model, params)
    t_idx = xt.shape[1]-1
    def utt(xi):
        return jax.grad(lambda z: jax.grad(fn)(z)[t_idx])(xi)[t_idx]
    return jax.vmap(utt)(xt)


def lap_spatial(model, params, xt):
    """Δ_x u where xt=[x1…x_{d-1},t]. Shape: (batch,)."""
    fn = _scalar(model, params)
    d_sp = xt.shape[1]-1
    return jax.vmap(lambda xi: sum(jax.hessian(fn)(xi)[i,i] for i in range(d_sp)))(xt)


def convect(model, params, x, a):
    """a·∇u. Shape: (batch,)."""
    fn = _scalar(model, params)
    return jax.vmap(lambda xi: jnp.dot(a, jax.grad(fn)(xi)))(x)


def normal_deriv(model, params, x, n):
    """∂u/∂n = ∇u·n. Shape: (batch,)."""
    gu = jax.vmap(jax.grad(_scalar(model, params)))(x)
    return jnp.sum(gu*(n if n.ndim>1 else n[None,:]), axis=-1)
