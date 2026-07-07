"""kkan/kernels/derivatives.py — Analytic first/second derivatives of each kernel.

All functions verified against jax.grad/jax.hessian ground truth.
Critically: uses jnp.maximum(r, eps) to avoid NaN at r=0 (diagonal of
collocation matrices), where jnp.linalg.norm has undefined 2nd derivatives.
"""
import jax, jax.numpy as jnp
import numpy as np

_EPS = 1e-7   # safe floor for r to avoid 1/0


# ── Scalar k'(r) and k''(r) ──────────────────────────────────────────────────

def rbf_dk(r):    return -2.0*r*jnp.exp(-r**2)
def rbf_d2k(r):   return (-2.0+4.0*r**2)*jnp.exp(-r**2)

def m05_dk(r):    return -jnp.exp(-jnp.abs(r))
def m05_d2k(r):   return jnp.exp(-jnp.abs(r))

def m15_dk(r):    s=jnp.sqrt(3.0)*r; return -3.0*r*jnp.exp(-s)
def m15_d2k(r):   s=jnp.sqrt(3.0)*r; return 3.0*(s-1.0)*jnp.exp(-s)

def m25_dk(r):    s=jnp.sqrt(5.0)*r; return -(5.0/3.0)*r*(1.0+s)*jnp.exp(-s)
def m25_d2k(r):   s=jnp.sqrt(5.0)*r; return (5.0/3.0)*(s**2-s-1.0)*jnp.exp(-s)

def wc4_dk(r):
    r=jnp.abs(r); t=jnp.maximum(1.0-r,0.0); l=4.0
    p=(35*r**2+18*r+3)/3; dp=(70*r+18)/3
    return t**(l+1)*(-6*p+t*dp)/(1.0)   # chain: sign handled by t

def wc4_d2k(r):
    r=jnp.abs(r); t=jnp.maximum(1.0-r,0.0); l=4.0
    p=(35*r**2+18*r+3)/3; dp=(70*r+18)/3; d2p=70.0/3.0
    return (-5*t**(l)*(-6*p+t*dp)+t**(l+1)*(-7*dp+t*d2p))

DERIVATIVE_REGISTRY = {
    "rbf":        (rbf_dk,  rbf_d2k),
    "matern_05":  (m05_dk,  m05_d2k),
    "matern_15":  (m15_dk,  m15_d2k),
    "matern_25":  (m25_dk,  m25_d2k),
    "wendland_c4":(wc4_dk,  wc4_d2k),
}

def get_derivatives(kernel_name: str):
    base = kernel_name.split("_poly")[0]
    if base in DERIVATIVE_REGISTRY:
        return DERIVATIVE_REGISTRY[base]
    # JAX-AD fallback for unknown kernels
    from .families import get_kernel
    k = get_kernel(base)
    return jax.grad(k), jax.grad(jax.grad(k))


# ── Spatial gradient  ∂k/∂x_i ────────────────────────────────────────────────

def kernel_grad_x(x, c, sigma, dk_fn):
    """∇_x k(||x-c||/σ).  Shape: (d,).  Safe at x==c."""
    diff = x - c
    r    = jnp.maximum(jnp.linalg.norm(diff)/sigma, _EPS)
    dk   = dk_fn(r)
    # ∂r/∂x_i = (x_i-c_i) / (σ² r)
    return dk * diff / (sigma**2 * r)


# ── Full Hessian  ∂²k/∂x_i∂x_j ──────────────────────────────────────────────

def kernel_hessian_x(x, c, sigma, dk_fn, d2k_fn):
    """∇²_x k(||x-c||/σ).  Shape: (d,d).  Safe at x==c (no NaN)."""
    diff  = x - c
    r     = jnp.maximum(jnp.linalg.norm(diff)/sigma, _EPS)
    r2    = r**2
    d     = diff.shape[0]
    dk    = dk_fn(r)
    d2k   = d2k_fn(r)
    outer = jnp.outer(diff, diff)
    # H_ij = k''(r)/σ⁴ * Δx_i Δx_j/r²  +  k'(r)/σ² * (δ_ij/r − Δx_i Δx_j/(σ²r³))
    term1 = d2k * outer / (sigma**4 * r2)
    term2 = dk  / (sigma**2) * (jnp.eye(d)/r - outer/(sigma**2 * r2 * r))
    return term1 + term2


# ── Laplacian  Δk (trace of Hessian) ─────────────────────────────────────────

def kernel_laplacian_x(x, c, sigma, dk_fn, d2k_fn):
    """Δ_x k(||x-c||/σ) = (k''(r) + (d-1)k'(r)/r) / σ².  Safe at x==c."""
    diff = x - c
    r    = jnp.maximum(jnp.linalg.norm(diff)/sigma, _EPS)
    d    = diff.shape[0]
    return (d2k_fn(r) + (d-1)*dk_fn(r)/r) / sigma**2


# ── Batched matrix builders ───────────────────────────────────────────────────

def kernel_grad_matrix(x, c, sigma, dk_fn):
    """G[i,j,:] = ∇_x k(||x_i-c_j||/σ).  Shape (N,M,d)."""
    fn = lambda xi, cj: kernel_grad_x(xi, cj, sigma, dk_fn)
    return jax.vmap(jax.vmap(fn, (None,0)), (0,None))(x, c)

def kernel_lap_matrix(x, c, sigma, dk_fn, d2k_fn):
    """L[i,j] = Δ_x k(||x_i-c_j||/σ).  Shape (N,M)."""
    fn = lambda xi, cj: kernel_laplacian_x(xi, cj, sigma, dk_fn, d2k_fn)
    return jax.vmap(jax.vmap(fn, (None,0)), (0,None))(x, c)
