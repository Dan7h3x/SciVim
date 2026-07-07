"""solvers/meshless_solver.py — Direct meshless PDE solvers (no gradient descent)."""
from __future__ import annotations
from typing import Callable, Tuple
import numpy as np
import jax, jax.numpy as jnp
from scipy.linalg import solve, lstsq as sp_lstsq

from ..kernels.families import get_kernel
from ..kernels.derivatives import (get_derivatives, kernel_laplacian_x,
                                    kernel_grad_x)
from ..utils.training import compute_metrics


# ── Matrix builders ───────────────────────────────────────────────────────────

def _K(kname, x, c, sigma):
    """Kernel matrix K[i,j] = k(||x_i-c_j||/sigma). Elementwise — no vmap."""
    k = get_kernel(kname)
    r = np.linalg.norm(x[:,None,:]-c[None,:,:], axis=-1)/sigma
    return np.asarray(k(jnp.array(r)))


def _L(kname, x, c, sigma):
    """Laplacian matrix L[i,j] = Δ_x k(x_i,c_j). Safe at r=0 (analytic)."""
    dk_fn, d2k_fn = get_derivatives(kname)
    fn = lambda xi, cj: kernel_laplacian_x(xi, cj, sigma, dk_fn, d2k_fn)
    return np.asarray(jax.vmap(jax.vmap(fn,(None,0)),(0,None))(
        jnp.array(x), jnp.array(c)))


def _poly_basis(x, degree):
    from itertools import product as iprod
    d = x.shape[1]
    indices = [a for a in iprod(range(degree+1),repeat=d) if sum(a)<=degree]
    cols = []
    for alpha in indices:
        c = np.ones(x.shape[0])
        for i,e in enumerate(alpha): c = c*(x[:,i]**e)
        cols.append(c)
    return np.column_stack(cols) if cols else np.zeros((x.shape[0],1))


def _poly_lap(x, degree):
    from itertools import product as iprod
    d = x.shape[1]
    indices = [a for a in iprod(range(degree+1),repeat=d) if sum(a)<=degree]
    cols = []
    for alpha in indices:
        lap_col = np.zeros(x.shape[0])
        for dim_i,exp in enumerate(alpha):
            if exp >= 2:
                coeff = exp*(exp-1)
                term = np.ones(x.shape[0])
                for dim_j,e2 in enumerate(alpha):
                    ne = e2-2 if dim_j==dim_i else e2
                    if ne < 0: term = np.zeros(x.shape[0]); break
                    term = term*(x[:,dim_j]**ne)
                lap_col += coeff*term
        cols.append(lap_col)
    return np.column_stack(cols) if cols else np.zeros((x.shape[0],1))


# ── Kansa's method ────────────────────────────────────────────────────────────

class KansaSolver:
    """Unsymmetric collocation for -Δu = f with polynomial augmentation."""
    def __init__(self, kernel_name="matern_25", sigma=0.1, poly_degree=1, reg=1e-10):
        self.kname=kernel_name; self.sigma=sigma; self.pdeg=poly_degree; self.reg=reg
        self.ctrs_=None; self.weights_=None; self.poly_w_=None

    def fit(self, x_int, x_bc, f_int, g_bc, operator="neg_laplacian"):
        c = np.vstack([x_int, x_bc]); self.ctrs_=c; N=c.shape[0]
        A_int = -_L(self.kname,x_int,c,self.sigma) if operator=="neg_laplacian" \
                else _K(self.kname,x_int,c,self.sigma)
        A_bc  = _K(self.kname, x_bc, c, self.sigma)
        P_int = _poly_lap(x_int,self.pdeg) if operator=="neg_laplacian" \
                else _poly_basis(x_int,self.pdeg)
        P_bc  = _poly_basis(x_bc,  self.pdeg)
        P_c   = _poly_basis(c,     self.pdeg); M=P_c.shape[1]
        A = np.vstack([np.hstack([A_int,P_int]),
                        np.hstack([A_bc, P_bc]),
                        np.hstack([P_c.T, np.zeros((M,M))])])
        rhs = np.concatenate([f_int, g_bc, np.zeros(M)])
        ATA = A.T@A + self.reg*np.eye(N+M)
        sol = solve(ATA, A.T@rhs, assume_a="sym")
        self.weights_=sol[:N]; self.poly_w_=sol[N:]; return self

    def predict(self, x):
        K=_K(self.kname,x,self.ctrs_,self.sigma)
        P=_poly_basis(x,self.pdeg)
        return K@self.weights_+P@self.poly_w_

    def evaluate(self, x, u_true):
        return compute_metrics(u_true.ravel(), self.predict(x))


# ── Symmetric Galerkin ────────────────────────────────────────────────────────

class GalerkinSolver:
    """Symmetric normal-equations collocation. SPD system — more stable than Kansa."""
    def __init__(self, kernel_name="rbf", sigma=0.1, lam_bc=1e4, reg=1e-10, poly_degree=1):
        self.kname=kernel_name; self.sigma=sigma; self.lam_bc=lam_bc
        self.reg=reg; self.pdeg=poly_degree
        self.ctrs_=None; self.weights_=None; self.poly_w_=None

    def fit(self, x_int, x_bc, f_int, g_bc, operator="neg_laplacian"):
        c = np.vstack([x_int, x_bc]); self.ctrs_=c; N=c.shape[0]
        A_int = -_L(self.kname,x_int,c,self.sigma) if operator=="neg_laplacian" \
                else _K(self.kname,x_int,c,self.sigma)
        A_bc  = _K(self.kname, x_bc, c, self.sigma)
        P_int = _poly_lap(x_int,self.pdeg) if operator=="neg_laplacian" \
                else _poly_basis(x_int,self.pdeg)
        P_bc  = _poly_basis(x_bc, self.pdeg); M=_poly_basis(c,self.pdeg).shape[1]
        B_int = np.hstack([A_int,P_int]); B_bc = np.hstack([A_bc,P_bc])
        Mat = B_int.T@B_int + self.lam_bc*B_bc.T@B_bc + self.reg*np.eye(N+M)
        rhs = B_int.T@f_int + self.lam_bc*B_bc.T@g_bc
        sol = solve(Mat, rhs, assume_a="sym")
        self.weights_=sol[:N]; self.poly_w_=sol[N:]; return self

    def predict(self, x):
        return _K(self.kname,x,self.ctrs_,self.sigma)@self.weights_ + \
               _poly_basis(x,self.pdeg)@self.poly_w_

    def evaluate(self, x, u_true):
        return compute_metrics(u_true.ravel(), self.predict(x))


# ── RKPM interpolant ──────────────────────────────────────────────────────────

class RKPMInterpolant:
    """Moving-least-squares / RKPM interpolant with polynomial reproduction."""
    def __init__(self, kernel_name="wendland_c4", sigma=0.2, poly_degree=1):
        self.kname=kernel_name; self.sigma=sigma; self.pdeg=poly_degree
        self.ctrs_=None; self.vals_=None

    def fit(self, x, u):
        self.ctrs_=x.copy(); self.vals_=u.ravel().copy(); return self

    def predict(self, xq):
        K  = _K(self.kname,xq,self.ctrs_,self.sigma)
        P  = _poly_basis(self.ctrs_,self.pdeg)
        Pb = _poly_basis(xq,self.pdeg); M=P.shape[1]
        preds = np.zeros(xq.shape[0])
        for i in range(xq.shape[0]):
            w_i = K[i]; W = np.diag(w_i)
            lhs = P.T@W@P + 1e-12*np.eye(M)
            rhs = P.T@(w_i*self.vals_)
            a_i = np.linalg.solve(lhs, rhs)
            preds[i] = Pb[i]@a_i
        return preds

    def evaluate(self, x, u_true):
        return compute_metrics(u_true.ravel(), self.predict(x))


# ── Method of Lines ───────────────────────────────────────────────────────────

class MOLSolver:
    """Implicit backward-Euler method of lines for u_t = κΔu + f. Unconditionally stable."""
    def __init__(self, kernel_name="rbf", sigma=0.05, kappa=0.1, poly_degree=1, reg=1e-9):
        self.kname=kernel_name; self.sigma=sigma; self.kappa=kappa
        self.pdeg=poly_degree; self.reg=reg

    def solve(self, x_int, x_bc, u0_fn, g_bc_fn, f_fn, T=1.0, dt=0.01, store_every=1):
        c = np.vstack([x_int, x_bc]); N=c.shape[0]; Ni=x_int.shape[0]
        K_int=_K(self.kname,x_int,c,self.sigma)
        K_bc =_K(self.kname,x_bc, c,self.sigma)
        L_int=_L(self.kname,x_int,c,self.sigma)
        P_int=_poly_basis(x_int,self.pdeg); P_bc=_poly_basis(x_bc,self.pdeg)
        Pc=_poly_basis(c,self.pdeg); Mp=Pc.shape[1]
        B0=np.vstack([np.hstack([K_int,P_int]),np.hstack([K_bc,P_bc])])
        b0=np.concatenate([u0_fn(x_int),u0_fn(x_bc)])
        M0=B0.T@B0+self.reg*np.eye(N+Mp)
        sol0=solve(M0,B0.T@b0,assume_a="sym")
        w=sol0[:N]; qp=sol0[N:]
        n_steps=int(T/dt); times=[0.0]; U=[K_int@w+P_int@qp]
        for step in range(n_steps):
            t_new=(step+1)*dt
            rhs_int=K_int@w+P_int@qp+dt*f_fn(x_int,t_new)
            A_int_s=K_int-dt*self.kappa*L_int
            rhs_bc=g_bc_fn(x_bc,t_new)
            B=np.vstack([np.hstack([A_int_s,P_int]),np.hstack([K_bc,P_bc])])
            rhs=np.concatenate([rhs_int,rhs_bc])
            M=B.T@B+self.reg*np.eye(N+Mp)
            sol=solve(M,B.T@rhs,assume_a="sym")
            w=sol[:N]; qp=sol[N:]
            if step%store_every==0 or step==n_steps-1:
                times.append(t_new); U.append(K_int@w+P_int@qp)
        return np.array(times), np.array(U)
