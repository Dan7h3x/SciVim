"""approximation/quasi_interpolation.py — Shepard, Modified Shepard, RBF+Grad interpolants."""
from __future__ import annotations
from typing import Optional
import numpy as np
import jax, jax.numpy as jnp
from ..kernels.families import get_kernel
from ..kernels.derivatives import get_derivatives, kernel_grad_matrix
from .hermite_collocation import _kernel_matrix, _poly_basis, _poly_grad_basis


class ShepardQuasiInterpolant:
    """Shepard's method: Q[u](x) = Σ u_j φ_j(x) / Σ φ_k(x).  O(h) convergence."""
    def __init__(self, kernel_name="wendland_c4", sigma=0.2):
        self.kname=kernel_name; self.sigma=sigma
        self.x_=None; self.u_=None

    def fit(self, x, u):
        self.x_=x.copy(); self.u_=u.ravel().copy(); return self

    def predict(self, xq):
        k = get_kernel(self.kname)
        diff = xq[:,None,:]-self.x_[None,:,:]
        r    = np.linalg.norm(diff,axis=-1)/self.sigma
        phi  = np.asarray(k(jnp.array(r)))   # (N_q, N_d)
        w    = phi/(phi.sum(axis=1,keepdims=True)+1e-14)
        return w@self.u_


class ModifiedShepardInterpolant:
    """Modified Shepard with local linear Taylor expansion.  O(h²) convergence."""
    def __init__(self, kernel_name="wendland_c4", sigma=0.2, estimate_grads=True):
        self.kname=kernel_name; self.sigma=sigma; self.est=estimate_grads
        self.x_=None; self.u_=None; self.du_=None

    def fit(self, x, u, du=None):
        self.x_=x.copy(); self.u_=u.ravel().copy()
        if du is not None:
            self.du_=du.copy()
        elif self.est:
            self.du_=self._estimate_grads(x, u.ravel())
        else:
            self.du_=np.zeros_like(x)
        return self

    def _estimate_grads(self, x, u):
        N,d = x.shape; k_fn = get_kernel(self.kname); grads=np.zeros((N,d))
        for j in range(N):
            diff_j = x-x[j]
            r_j = np.linalg.norm(diff_j,axis=-1)/self.sigma
            w_j = np.asarray(k_fn(jnp.array(r_j))); w_j[j]=0.0
            du_j = u-u[j]
            lhs = (diff_j*w_j[:,None]).T@diff_j+1e-10*np.eye(d)
            rhs = (diff_j*w_j[:,None]).T@du_j
            grads[j]=np.linalg.solve(lhs,rhs)
        return grads

    def predict(self, xq):
        k_fn = get_kernel(self.kname)
        diff = xq[:,None,:]-self.x_[None,:,:]
        r    = np.linalg.norm(diff,axis=-1)/self.sigma
        phi  = np.asarray(k_fn(jnp.array(r)))
        dot  = np.einsum("qjd,jd->qj",diff,self.du_)
        T    = self.u_[None,:]+dot
        w    = phi/(phi.sum(axis=1,keepdims=True)+1e-14)
        return (w*T).sum(axis=1)


class RBFInterpolantWithGrad:
    """Standard RBF interpolant with analytic gradient evaluation."""
    def __init__(self, kernel_name="matern_25", sigma=0.1, poly_degree=1, reg=1e-10):
        self.kname=kernel_name; self.sigma=sigma; self.pdeg=poly_degree; self.reg=reg
        self.x_=None; self.w_=None; self.q_=None; self._indices=None

    def fit(self, x, u):
        N,d = x.shape; self.x_=x.copy()
        K = _kernel_matrix(self.kname,x,x,self.sigma)
        from itertools import product as iprod
        indices=[a for a in iprod(range(self.pdeg+1),repeat=d) if sum(a)<=self.pdeg]
        self._indices=indices
        P=_poly_basis(x,self.pdeg); M=P.shape[1]
        A=np.block([[K,P],[P.T,np.zeros((M,M))]])
        A[:N,:N]+=self.reg*np.eye(N)
        from scipy.linalg import lstsq
        sol=lstsq(A,np.concatenate([u.ravel(),np.zeros(M)]))[0]
        self.w_=sol[:N]; self.q_=sol[N:]; return self

    def predict(self, xq):
        K=_kernel_matrix(self.kname,xq,self.x_,self.sigma)
        P=_poly_basis(xq,self.pdeg)
        return K@self.w_+P@self.q_

    def predict_gradient(self, xq):
        dk_fn,_ = get_derivatives(self.kname)
        G=np.asarray(kernel_grad_matrix(jnp.array(xq),jnp.array(self.x_),self.sigma,dk_fn))
        grad_kern=np.einsum("ijk,j->ik",G,self.w_)
        # polynomial tail gradient
        d=xq.shape[1]; grad_poly=np.zeros((xq.shape[0],d))
        for ci,alpha in enumerate(self._indices):
            q=self.q_[ci]
            for dim in range(d):
                if alpha[dim]==0: continue
                val=q*float(alpha[dim])*np.ones(xq.shape[0])
                for i,e in enumerate(alpha):
                    exp=e-1 if i==dim else e
                    val=val*(xq[:,i]**exp)
                grad_poly[:,dim]+=val
        return grad_kern+grad_poly


class GaussianQuasiInterpolant:
    """Corrected Gaussian quasi-interpolant of order m. O(h^{m+1}) in L²."""
    def __init__(self, h=0.1, poly_order=2):
        self.h=h; self.m=poly_order; self.x_=None; self.u_=None

    def fit(self, x, u): self.x_=x.copy(); self.u_=u.ravel().copy(); return self

    def _psi(self, y):
        r2=np.sum(y**2,axis=-1) if y.ndim>1 else y**2
        phi=np.exp(-r2)
        if self.m>=2 and (y.ndim==1 or y.shape[1]==1):
            yy=y.ravel()
            phi_c=phi*(1.0-0.5*yy**2)
            norm=np.trapz(phi_c,yy) if len(yy)>1 else 1.0
            return phi_c/(norm+1e-14)
        return phi/np.sqrt(np.pi)

    def predict(self, xq):
        h=self.h; d=xq.shape[1]; out=np.zeros(xq.shape[0])
        for q_idx in range(xq.shape[0]):
            y=(xq[q_idx]-self.x_)/h
            psi=self._psi(y)
            out[q_idx]=np.sum(self.u_*psi)
        return out*(h**d)
