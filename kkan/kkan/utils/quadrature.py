"""utils/quadrature.py — Numerical integration rules for weak-form PDE losses."""
import numpy as np
import jax.numpy as jnp


def gauss_legendre_1d(n, a=0.0, b=1.0):
    nodes, weights = np.polynomial.legendre.leggauss(n)
    nodes   = 0.5*(b-a)*nodes + 0.5*(a+b)
    weights = 0.5*(b-a)*weights
    return nodes, weights


def gauss_legendre_nd(n, d, lo=0.0, hi=1.0):
    """Tensor-product Gauss-Legendre: n^d total points."""
    nodes_1d, w_1d = gauss_legendre_1d(n, lo, hi)
    grids = np.meshgrid(*([nodes_1d]*d), indexing="ij")
    pts   = np.stack([g.ravel() for g in grids], axis=-1)
    ws    = np.meshgrid(*([w_1d]*d), indexing="ij")
    wts   = np.ones(n**d)
    for w in ws: wts *= w.ravel()
    return pts, wts


_PRIMES = [2,3,5,7,11,13,17,19,23,29]

def halton_nd(n, d, lo=0.0, hi=1.0):
    """Halton low-discrepancy sequence: n total points (not tensor-product)."""
    assert d <= len(_PRIMES), f"Max dim {len(_PRIMES)}"
    def _halton(n, base):
        out = np.zeros(n)
        for i in range(1, n+1):
            f, r, k = 1.0, 0.0, i
            while k > 0:
                f /= base; r += f*(k%base); k //= base
            out[i-1] = r
        return out
    cols = [_halton(n, _PRIMES[i]) for i in range(d)]
    pts  = np.stack(cols, axis=-1)*(hi-lo)+lo
    wts  = np.full(n, (hi-lo)**d/n)
    return pts, wts


def resample_collocation(x_current, residuals, n_new, lo=0.0, hi=1.0,
                         blend=0.5, seed=0):
    """Residual-based adaptive collocation resampling (RAR)."""
    rng = np.random.RandomState(seed)
    N, d = x_current.shape
    n_keep = int((1-blend)*N)
    order  = np.argsort(np.abs(residuals))
    kept   = x_current[order[:n_keep]]
    res_sq = residuals**2
    prob   = res_sq/(res_sq.sum()+1e-14)
    idx    = rng.choice(N, size=n_new*10, p=prob)
    props  = x_current[idx]
    noise  = rng.uniform(-0.05*(hi-lo), 0.05*(hi-lo), props.shape)
    new_pts= np.clip(props+noise, lo, hi)[:n_new]
    return np.vstack([kept, new_pts])


def boundary_quad_2d(n, lo=0.0, hi=1.0):
    t, w = gauss_legendre_1d(n, lo, hi)
    lo_a, hi_a = np.full_like(t,lo), np.full_like(t,hi)
    sides = [np.stack([t,lo_a],1), np.stack([t,hi_a],1),
             np.stack([lo_a,t],1), np.stack([hi_a,t],1)]
    return np.vstack(sides), np.tile(w,4)
