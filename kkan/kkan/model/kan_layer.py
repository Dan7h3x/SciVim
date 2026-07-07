"""model/kan_layer.py — K-KAN layer with Gauss/Chebyshev grids, MLS normalisation, L0 pruning."""
from __future__ import annotations
from typing import Sequence
import numpy as np
import jax, jax.numpy as jnp
import flax.linen as nn
from ..kernels.families import get_kernel, PolyAugKernel


def _gauss_legendre_nodes(K, lo, hi):
    nodes, _ = np.polynomial.legendre.leggauss(K)
    return jnp.array(((nodes+1)/2*(hi-lo)+lo).astype(np.float32))

def _chebyshev_nodes(K, lo, hi):
    k = np.arange(K, dtype=np.float32)
    nodes = np.cos(np.pi*k/max(K-1,1))
    return jnp.array(((nodes+1)/2*(hi-lo)+lo))


class ConcreteGate(nn.Module):
    shape: tuple
    beta: float = 0.66
    zeta: float = 1.1
    gamma: float = -0.1

    def setup(self):
        init = float(np.log(0.7/0.3))
        self.log_alpha = self.param("log_alpha",
                                    lambda k, s: jnp.full(s, init), self.shape)

    def __call__(self, deterministic=False):
        return jnp.clip(
            nn.sigmoid(self.log_alpha)*(self.zeta-self.gamma)+self.gamma, 0.0, 1.0)

    def expected_l0(self):
        return jnp.sum(nn.sigmoid(
            self.log_alpha - self.beta*jnp.log(-self.gamma/self.zeta)))


class KKANLayer(nn.Module):
    in_features: int
    out_features: int
    num_grids: int = 12
    grid_min: float = -1.5
    grid_max: float = 1.5
    kernel_name: str = "matern_25"
    grid_type: str = "gauss"
    use_base: bool = True
    trainable_centers: bool = True
    trainable_sigma: bool = True
    use_mls_norm: bool = True
    use_pruning: bool = True

    def setup(self):
        kern = get_kernel(self.kernel_name)
        self._is_poly = isinstance(kern, PolyAugKernel)
        self._kern = kern
        if self.grid_type == "gauss":
            init_c = _gauss_legendre_nodes(self.num_grids, self.grid_min, self.grid_max)
        elif self.grid_type == "chebyshev":
            init_c = _chebyshev_nodes(self.num_grids, self.grid_min, self.grid_max)
        else:
            init_c = jnp.linspace(self.grid_min, self.grid_max, self.num_grids)
        if self.trainable_centers:
            self.centers = self.param("centers",
                lambda k, s: jnp.broadcast_to(init_c, s).copy(),
                (self.in_features, self.out_features, self.num_grids))
        else:
            self.centers = init_c
        init_sigma = (self.grid_max-self.grid_min)/max(self.num_grids-1, 1)
        if self.trainable_sigma:
            self.log_sigma = self.param("log_sigma",
                lambda k, s: jnp.full(s, jnp.log(init_sigma)),
                (self.in_features, self.out_features))
        else:
            self.log_sigma = jnp.log(jnp.array(init_sigma))
        self.w_kern = self.param("w_kern", nn.initializers.normal(0.1),
                                  (self.in_features, self.out_features, self.num_grids))
        if self.use_base:
            self.w_base = self.param("w_base", nn.initializers.xavier_uniform(),
                                      (self.in_features, self.out_features))
        if self._is_poly:
            self.w_poly = self.param("w_poly", nn.initializers.zeros,
                (self.in_features, self.out_features, self._kern.n_poly()))
        if self.use_pruning:
            self.gates = ConcreteGate(shape=(self.in_features, self.out_features))

    def _phi(self, x):
        # x: (B, in)
        if self.trainable_centers:
            diff = x[:, :, None, None] - self.centers[None, :, :, :]  # (B,in,out,K)
            sig  = jnp.exp(self.log_sigma)[None, :, :, None]
        else:
            diff = (x[:, :, None] - self.centers[None, None, :])[:, :, None, :]
            sig  = jnp.exp(self.log_sigma)
        r = jnp.abs(diff) / (sig + 1e-8)
        kern_fn = self._kern if not self._is_poly else self._kern.base
        phi = kern_fn(r)   # elementwise broadcast — no nested vmap needed
        if self.use_mls_norm:
            phi = phi / (jnp.sum(phi, axis=-1, keepdims=True) + 1e-8)
        return phi

    def __call__(self, x, deterministic=True):
        phi = self._phi(x)  # (B, in, out, K)
        # edge-wise contribution: (B, in, out)
        if phi.shape[2] == 1:
            kern_c = jnp.einsum("bik,iok->bio", phi[:, :, 0, :], self.w_kern)
        else:
            kern_c = jnp.einsum("biok,iok->bio", phi, self.w_kern)
        if self.use_base:
            kern_c = kern_c + nn.silu(x)[:, :, None] * self.w_base[None, :, :]
        if self._is_poly:
            pf = jax.vmap(self._kern.legendre)(x)  # (B, in, P)
            kern_c = kern_c + jnp.einsum("bip,iop->bio", pf, self.w_poly)
        if self.use_pruning:
            g = self.gates(deterministic=deterministic)  # (in, out)
            y = jnp.sum(kern_c * g[None, :, :], axis=1)
        else:
            y = jnp.sum(kern_c, axis=1)
        return y


class KKAN(nn.Module):
    layer_dims: Sequence[int]
    kernel_name: str = "matern_25"
    num_grids: int = 12
    grid_min: float = -1.5
    grid_max: float = 1.5
    grid_type: str = "gauss"
    use_base: bool = True
    trainable_centers: bool = True
    trainable_sigma: bool = True
    use_mls_norm: bool = True
    use_pruning: bool = True

    @nn.compact
    def __call__(self, x, deterministic=True):
        for i in range(len(self.layer_dims)-1):
            x = KKANLayer(
                in_features=self.layer_dims[i],
                out_features=self.layer_dims[i+1],
                num_grids=self.num_grids,
                grid_min=self.grid_min, grid_max=self.grid_max,
                kernel_name=self.kernel_name, grid_type=self.grid_type,
                use_base=self.use_base, trainable_centers=self.trainable_centers,
                trainable_sigma=self.trainable_sigma,
                use_mls_norm=self.use_mls_norm, use_pruning=self.use_pruning,
                name=f"layer_{i}")(x, deterministic=deterministic)
        return x

    def l0_loss(self, params):
        total = jnp.array(0.0)
        for i in range(len(self.layer_dims)-1):
            lp = params["params"].get(f"layer_{i}", {})
            gp = lp.get("gates", None)
            if gp is not None:
                total += jnp.sum(nn.sigmoid(
                    gp["log_alpha"] - 0.66*jnp.log(0.1/1.1)))
        return total


def count_params(params):
    def _flat(d, prefix=""):
        out = {}
        for k, v in d.items():
            key = f"{prefix}/{k}" if prefix else k
            if isinstance(v, dict):
                out.update(_flat(v, key))
            else:
                out[key] = v
        return out
    return sum(np.asarray(v).size for v in _flat(params["params"]).values())
