"""model/gradient_enhanced_layer.py — Hermite-augmented KAN + Sobolev loss."""
from __future__ import annotations
from typing import Optional, Sequence
import jax, jax.numpy as jnp
import flax.linen as nn
import numpy as np
from ..kernels.families import get_kernel, PolyAugKernel
from ..kernels.derivatives import get_derivatives
from .kan_layer import _gauss_legendre_nodes


def sobolev_loss(params, model, x, u_target, du_target=None,
                 d2u_target=None, lambda_grad=1.0, lambda_hess=0.1,
                 deterministic=True):
    """H^k Sobolev loss: MSE on u + lambda_grad*MSE on grad u."""
    u_pred = model.apply(params, x, deterministic=deterministic)
    loss = jnp.mean((u_pred - u_target)**2)
    if du_target is not None:
        def u_sc(xi): return model.apply(params, xi[None], deterministic=True)[0,0]
        du_pred = jax.vmap(jax.grad(u_sc))(x)
        loss = loss + lambda_grad*jnp.mean((du_pred - du_target)**2)
    if d2u_target is not None:
        def u_sc(xi): return model.apply(params, xi[None], deterministic=True)[0,0]
        d2u_pred = jax.vmap(jax.hessian(u_sc))(x)
        loss = loss + lambda_hess*jnp.mean((d2u_pred - d2u_target)**2)
    return loss


def native_space_regulariser(params, layer_idx=0):
    """RKHS norm penalty: w^T K w for each edge's kernel weights."""
    lp = params["params"].get(f"layer_{layer_idx}", {})
    w  = lp.get("w_kern", None)
    if w is None: return jnp.array(0.0)
    w = jnp.array(w); c = lp.get("centers", None)
    if c is None: return jnp.array(0.0)
    c = jnp.array(c); log_s = lp.get("log_sigma", jnp.log(jnp.array(0.1)))
    sigma = jnp.exp(log_s)
    in_f, out_f, K_n = w.shape; total = jnp.array(0.0)
    for i in range(in_f):
        for j in range(out_f):
            w_ij = w[i,j,:]; c_ij = c[i,j,:]
            diff = c_ij[:,None]-c_ij[None,:]
            r = jnp.abs(diff)/(sigma if sigma.ndim==0 else sigma[i,j])
            Gram = jnp.exp(-(r**2))
            total = total + w_ij@Gram@w_ij
    return total


class HermiteKANLayer(nn.Module):
    in_features: int; out_features: int; num_grids: int=12
    grid_min: float=-1.5; grid_max: float=1.5; kernel_name: str="matern_25"
    use_deriv_basis: bool=True; use_base: bool=True
    trainable_centers: bool=True; trainable_sigma: bool=True

    def setup(self):
        kern = get_kernel(self.kernel_name)
        self._is_poly = isinstance(kern, PolyAugKernel)
        self._kern = kern
        try:
            dk_fn, _ = get_derivatives(self.kernel_name)
            self._dk_fn = jax.jit(dk_fn)
        except Exception:
            self._dk_fn = None
        init_c = _gauss_legendre_nodes(self.num_grids, self.grid_min, self.grid_max)
        if self.trainable_centers:
            self.centers = self.param("centers",
                lambda k,s: jnp.broadcast_to(init_c,s).copy(),
                (self.in_features, self.out_features, self.num_grids))
        else:
            self.centers = init_c
        init_sigma = (self.grid_max-self.grid_min)/max(self.num_grids-1,1)
        if self.trainable_sigma:
            self.log_sigma = self.param("log_sigma",
                lambda k,s: jnp.full(s, jnp.log(init_sigma)),
                (self.in_features, self.out_features))
        else:
            self.log_sigma = jnp.log(jnp.array(init_sigma))
        self.w_kern = self.param("w_kern", nn.initializers.normal(0.1),
                                  (self.in_features, self.out_features, self.num_grids))
        if self.use_deriv_basis:
            self.w_deriv = self.param("w_deriv", nn.initializers.zeros,
                                       (self.in_features, self.out_features, self.num_grids))
        if self.use_base:
            self.w_base = self.param("w_base", nn.initializers.xavier_uniform(),
                                      (self.in_features, self.out_features))
        if self._is_poly:
            self.w_poly = self.param("w_poly", nn.initializers.zeros,
                (self.in_features, self.out_features, self._kern.n_poly()))

    def _kern_and_deriv(self, x):
        if self.trainable_centers:
            diff = x[:,:,None,None] - self.centers[None,:,:,:]
            sig  = jnp.exp(self.log_sigma)[None,:,:,None]
        else:
            diff = (x[:,:,None]-self.centers[None,None,:])[:,:,None,:]
            sig  = jnp.exp(self.log_sigma)
        r   = jnp.abs(diff)/(sig+1e-8)
        sgn = jnp.sign(diff)
        kern_fn = self._kern if not self._is_poly else self._kern.base
        phi = kern_fn(r)   # elementwise — no nested vmap
        if self.use_deriv_basis:
            if self._dk_fn is not None:
                dphi = self._dk_fn(r)*sgn
            else:
                # Fallback: flatten, AD, reshape
                shape = r.shape
                dphi = jax.vmap(jax.grad(kern_fn))(r.reshape(-1)).reshape(shape)*sgn
        else:
            dphi = jnp.zeros_like(phi)
        return phi, dphi

    def __call__(self, x, deterministic=True):
        phi, dphi = self._kern_and_deriv(x)
        if phi.shape[2]==1:
            kern_c = jnp.einsum("bik,iok->bio", phi[:,:,0,:], self.w_kern)
            if self.use_deriv_basis:
                kern_c = kern_c + jnp.einsum("bik,iok->bio", dphi[:,:,0,:], self.w_deriv)
        else:
            kern_c = jnp.einsum("biok,iok->bio", phi, self.w_kern)
            if self.use_deriv_basis:
                kern_c = kern_c + jnp.einsum("biok,iok->bio", dphi, self.w_deriv)
        if self.use_base:
            kern_c = kern_c + nn.silu(x)[:,:,None]*self.w_base[None,:,:]
        if self._is_poly:
            pf = jax.vmap(self._kern.legendre)(x)
            kern_c = kern_c + jnp.einsum("bip,iop->bio", pf, self.w_poly)
        return jnp.sum(kern_c, axis=1)


class HermiteKKAN(nn.Module):
    layer_dims: Sequence[int]; kernel_name: str="matern_25"; num_grids: int=12
    grid_min: float=-1.5; grid_max: float=1.5
    use_deriv_basis: bool=True; use_base: bool=True
    trainable_centers: bool=True; trainable_sigma: bool=True

    @nn.compact
    def __call__(self, x, deterministic=True):
        for i in range(len(self.layer_dims)-1):
            x = HermiteKANLayer(
                in_features=self.layer_dims[i], out_features=self.layer_dims[i+1],
                num_grids=self.num_grids, grid_min=self.grid_min, grid_max=self.grid_max,
                kernel_name=self.kernel_name, use_deriv_basis=self.use_deriv_basis,
                use_base=self.use_base, trainable_centers=self.trainable_centers,
                trainable_sigma=self.trainable_sigma, name=f"layer_{i}"
            )(x, deterministic=deterministic)
        return x
