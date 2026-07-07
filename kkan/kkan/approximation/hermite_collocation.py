"""approximation/hermite_collocation.py — Hermite-Birkhoff kernel collocation.

Ansatz:  s(x) = Σ_j w_j k(x,x_j) + Σ_j Σ_l v_{j,l} ∂_l k(x,x_j) + poly tail

Both k(x,x_j) and ∂_l k(x,x_j) are basis FUNCTIONS OF x (with x_j held
fixed as a parameter) — i.e. ∂_l acts on the free variable x throughout,
never on the fixed centre x_j. This is the standard Hermite-Birkhoff RBF
construction (Wu 1992; Fasshauer 1996).

Consequently, the second-derivative block used to enforce derivative
observations at collocation points,

    H[i,l,j,m] = ∂_l ∂_m [ k(x,x_j) ]  evaluated at x = x_i,

is simply the (l,m) entry of the ordinary x-Hessian of k(x_i, x_j) — with
NO sign flip. (An earlier version of this file incorrectly applied a
center-derivative sign flip appropriate for a different formulation where
the derivative basis is defined via ∂_c instead of ∂_x; that mismatch
between the value-row basis (∂_x, correct) and the derivative-derivative
block (incorrectly using ∂_x∂c = -∂_x∂x) silently corrupted every fit.)

The system is solved via regularised normal equations (Tikhonov on the
kernel/derivative block only, not the polynomial block), which is far
more robust than raw SVD-based lstsq for the kernel+derivative block's
characteristically poor conditioning (condition numbers of 1e7-1e9 are
common even for well-posed small problems — Schaback's "uncertainty
principle": smaller sigma buys smoothness/accuracy at the cost of
conditioning).
"""
from __future__ import annotations
from typing import List, Optional
import numpy as np
import jax, jax.numpy as jnp
from ..kernels.families import get_kernel
from ..kernels.derivatives import (get_derivatives, kernel_grad_matrix,
                                    kernel_laplacian_x, kernel_hessian_x)


def _kernel_matrix(kernel_name, x, c, sigma):
    k = get_kernel(kernel_name)
    diff = x[:, None, :] - c[None, :, :]
    r = np.linalg.norm(diff, axis=-1) / sigma
    return np.asarray(k(jnp.array(r)))


def _laplacian_kernel_matrix(kernel_name, x, c, sigma):
    dk_fn, d2k_fn = get_derivatives(kernel_name)
    fn = lambda xi, cj: kernel_laplacian_x(xi, cj, sigma, dk_fn, d2k_fn)
    L = jax.vmap(jax.vmap(fn, (None, 0)), (0, None))(jnp.array(x), jnp.array(c))
    return np.asarray(L)


def _grad_col_matrix(kernel_name, x, c, sigma):
    """G[i,j,l] = ∂/∂x_l k(x_i, x_j)  (derivative w.r.t. the FREE variable x)."""
    dk_fn, _ = get_derivatives(kernel_name)
    return np.asarray(kernel_grad_matrix(jnp.array(x), jnp.array(c), sigma, dk_fn))


def _hess_x_matrix(kernel_name, x, c, sigma, comp_a, comp_b):
    """H[i,j] = ∂_a ∂_b [k(x,c_j)] evaluated at x=x_i — both derivatives
    act on the free variable x (NOT the fixed centre c_j). No sign flip."""
    dk_fn, d2k_fn = get_derivatives(kernel_name)
    def single(xi, cj):
        return kernel_hessian_x(xi, cj, sigma, dk_fn, d2k_fn)[comp_a, comp_b]
    return np.asarray(jax.vmap(jax.vmap(single, (None, 0)), (0, None))(
        jnp.array(x), jnp.array(c)))


def _poly_basis(x, degree):
    from itertools import product as iprod
    d = x.shape[1]
    indices = [a for a in iprod(range(degree+1), repeat=d) if sum(a) <= degree]
    cols = []
    for alpha in indices:
        c = np.ones(x.shape[0])
        for i, e in enumerate(alpha): c = c*(x[:, i]**e)
        cols.append(c)
    return np.column_stack(cols) if cols else np.zeros((x.shape[0], 1))


def _poly_grad_basis(x, degree, dim):
    from itertools import product as iprod
    d = x.shape[1]
    indices = [a for a in iprod(range(degree+1), repeat=d) if sum(a) <= degree]
    cols = []
    for alpha in indices:
        if alpha[dim] == 0:
            cols.append(np.zeros(x.shape[0]))
        else:
            c = float(alpha[dim])*np.ones(x.shape[0])
            for i, e in enumerate(alpha):
                exp = e-1 if i == dim else e
                c = c*(x[:, i]**exp)
            cols.append(c)
    return np.column_stack(cols) if cols else np.zeros((x.shape[0], 1))


class HermiteKernelInterpolant:
    """Hermite-Birkhoff interpolant fitting u(x_j) and selected ∇u(x_j) components.

    Solved via Tikhonov-regularised normal equations, which is far more
    numerically robust for this system than plain SVD-based least squares
    (see module docstring). Default reg=1e-6 works well for sigma in the
    range [0.05, 0.3] with N up to a few hundred points.
    """
    def __init__(self, kernel_name="matern_25", sigma=0.15,
                 deriv_components: Optional[List[int]] = None,
                 reg=1e-6, poly_degree=1):
        self.kname = kernel_name; self.sigma = sigma
        self.dcomps = deriv_components; self.reg = reg; self.pdeg = poly_degree
        self.centers_ = None; self.w_ = None; self.dw_ = None; self.q_ = None

    def fit(self, x, u, du=None):
        N, d = x.shape; self.centers_ = x.copy()
        components = self.dcomps if self.dcomps is not None else list(range(d))
        n_comp = len(components)
        u = np.asarray(u).ravel()

        K = _kernel_matrix(self.kname, x, x, self.sigma)
        P = _poly_basis(x, self.pdeg); M = P.shape[1]

        if du is None:
            A = np.hstack([K, P])
            AtA = A.T@A; AtA[:N, :N] += self.reg*np.eye(N)
            sol = np.linalg.solve(AtA, A.T@u)
            self.w_ = sol[:N]; self.dw_ = np.zeros((n_comp, N)); self.q_ = sol[N:]
            return self

        # Value-row basis: [K | G_l1 | G_l2 | ... | P]  (all functions of x)
        G_all = _grad_col_matrix(self.kname, x, x, self.sigma)  # (N,N,d)
        G_val = np.concatenate([G_all[:, :, l] for l in components], axis=1)  # (N, n_comp*N)

        # Derivative-row basis for component m: [G_m | H_{m,l1} | ... | dP_m]
        deriv_rows = []
        rhs_deriv = []
        for m in components:
            row = [G_all[:, :, m]]  # d/dx_m of the value-block kernel term
            for l in components:
                row.append(_hess_x_matrix(self.kname, x, x, self.sigma, m, l))
            row.append(_poly_grad_basis(x, self.pdeg, m))
            deriv_rows.append(np.hstack(row))
            rhs_deriv.append(du[:, m])

        top = np.hstack([K, G_val, P])
        mid = np.vstack(deriv_rows)
        A = np.vstack([top, mid])
        rhs = np.concatenate([u] + rhs_deriv)

        n_ker = N + n_comp*N   # kernel + derivative-weight columns (not poly)
        AtA = A.T@A
        AtA[:n_ker, :n_ker] += self.reg*np.eye(n_ker)
        sol = np.linalg.solve(AtA, A.T@rhs)

        self.w_ = sol[:N]
        self.dw_ = sol[N:N+n_comp*N].reshape(n_comp, N)
        self.q_ = sol[N+n_comp*N:]
        self._components = components
        return self

    def predict(self, x_q):
        K = _kernel_matrix(self.kname, x_q, self.centers_, self.sigma)
        P = _poly_basis(x_q, self.pdeg)
        u = K@self.w_ + P@self.q_
        components = getattr(self, "_components",
                              self.dcomps if self.dcomps is not None
                              else list(range(self.centers_.shape[1])))
        G_all = _grad_col_matrix(self.kname, x_q, self.centers_, self.sigma)
        for k_idx, l in enumerate(components):
            u = u + G_all[:, :, l]@self.dw_[k_idx]
        return u

    def predict_gradient(self, x_q):
        """∇s(x) = Σ_j w_j ∇_x k(x,x_j) + Σ_{j,l} v_{j,l} ∇_x ∂_l k(x,x_j) + ∇(poly)."""
        components = getattr(self, "_components",
                              self.dcomps if self.dcomps is not None
                              else list(range(self.centers_.shape[1])))
        G_all = _grad_col_matrix(self.kname, x_q, self.centers_, self.sigma)  # (Nq,N,d)
        d = x_q.shape[1]
        grad = np.einsum("ijk,j->ik", G_all, self.w_)  # kernel-weight contribution
        for k_idx, l in enumerate(components):
            for dim_out in range(d):
                H_ld = _hess_x_matrix(self.kname, x_q, self.centers_, self.sigma, dim_out, l)
                grad[:, dim_out] += H_ld@self.dw_[k_idx]
        for dim_out in range(d):
            dPb = _poly_grad_basis(x_q, self.pdeg, dim_out)
            grad[:, dim_out] += dPb@self.q_
        return grad
