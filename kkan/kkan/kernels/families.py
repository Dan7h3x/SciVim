"""kkan/kernels/families.py — Kernel families: RBF, IMQ, Matérn, Wendland, Wu, PolyAug."""
import jax.numpy as jnp
from abc import ABC, abstractmethod


class Kernel(ABC):
    name: str = "base"
    @abstractmethod
    def __call__(self, r): ...
    def native_space_order(self, d): return float("inf")


class RBFKernel(Kernel):
    name = "rbf"
    def __call__(self, r): return jnp.exp(-(r**2))


class InverseMultiquadricKernel(Kernel):
    name = "imq"
    def __init__(self, beta=1.5): self.beta = beta
    def __call__(self, r): return (1.0 + r**2)**(-self.beta)
    def native_space_order(self, d): return self.beta + d/2


class MaternKernel(Kernel):
    name = "matern"
    def __init__(self, nu=2.5):
        assert nu in (0.5, 1.5, 2.5)
        self.nu = nu
    def __call__(self, r):
        r = jnp.abs(r)
        if self.nu == 0.5:
            return jnp.exp(-r)
        elif self.nu == 1.5:
            s = jnp.sqrt(3.0)*r
            return (1.0+s)*jnp.exp(-s)
        else:
            s = jnp.sqrt(5.0)*r
            return (1.0+s+(5.0/3.0)*r**2)*jnp.exp(-s)
    def native_space_order(self, d): return self.nu + d/2


class WendlandKernel(Kernel):
    name = "wendland"
    def __init__(self, d=1, k=2):
        assert 0 <= k <= 3
        self.d, self.k, self.l = d, k, d//2+k+1
    def __call__(self, r):
        r = jnp.abs(r); l = float(self.l); t = jnp.maximum(1.0-r, 0.0)
        if self.k == 0: return t**l
        elif self.k == 1: return t**(l+1)*((l+1)*r+1.0)
        elif self.k == 2:
            poly = ((l**2+4*l+3)*r**2+(3*l+6)*r+3.0)/3.0
            return t**(l+2)*poly
        else:
            a = l**3+9*l**2+23*l+15
            poly = (a/15.0*r**3+(6*l**2+36*l+45)/15.0*r**2+(l+3)*r+1.0)
            return t**(l+3)*poly


class WuKernel(Kernel):
    name = "wu"
    def __init__(self, d=1, k=1):
        assert k in (1, 2)
        self.d, self.k, self.l = d, k, d//2+k+1
    def __call__(self, r):
        r = jnp.abs(r); l = float(self.l); t = jnp.maximum(1.0-r, 0.0)
        if self.k == 1:
            poly = ((l**2+4*l+3)*r**2+(3*l+6)*r+3.0)/3.0
            return t**(l+1)*poly
        else:
            poly = ((l**4+6*l**3+11*l**2+6*l)/3.0*r**4
                    +(4*l**3+24*l**2+44*l+24)/3.0*r**3
                    +(2*l**2+8*l+6)*r**2+(l+2)*r*4.0/3.0+1.0)
            return t**(l+3)*poly


class PolyAugKernel(Kernel):
    name = "poly_aug"
    def __init__(self, base, degree=2):
        self.base = base; self.degree = degree
    def __call__(self, r): return self.base(r)
    def legendre(self, x):
        polys = [jnp.ones_like(x), x] if self.degree >= 1 else [jnp.ones_like(x)]
        for n in range(2, self.degree+1):
            pn = ((2*n-1)*x*polys[-1]-(n-1)*polys[-2])/n
            polys.append(pn)
        return jnp.stack(polys[:self.degree+1], axis=-1)
    def n_poly(self): return self.degree+1


def get_kernel(name: str, **kw):
    poly_deg = None; base_name = name
    for m in range(1, 6):
        if name.endswith(f"_poly{m}"):
            base_name = name[:-len(f"_poly{m}")]; poly_deg = m; break
    d = kw.pop("d", 1)
    table = {
        "rbf":         RBFKernel,
        "imq":         lambda: InverseMultiquadricKernel(**kw),
        "matern_05":   lambda: MaternKernel(0.5),
        "matern_15":   lambda: MaternKernel(1.5),
        "matern_25":   lambda: MaternKernel(2.5),
        "wendland_c0": lambda: WendlandKernel(d,0),
        "wendland_c2": lambda: WendlandKernel(d,1),
        "wendland_c4": lambda: WendlandKernel(d,2),
        "wendland_c6": lambda: WendlandKernel(d,3),
        "wu_c2":       lambda: WuKernel(d,1),
        "wu_c4":       lambda: WuKernel(d,2),
    }
    if base_name not in table:
        raise KeyError(f"Unknown kernel '{base_name}'. Available: {list(table)}")
    k = table[base_name]()
    return PolyAugKernel(k, poly_deg) if poly_deg else k

KERNEL_REGISTRY = list({
    "rbf","imq","matern_05","matern_15","matern_25",
    "wendland_c0","wendland_c2","wendland_c4","wendland_c6",
    "wu_c2","wu_c4",
    "rbf_poly1","rbf_poly2","rbf_poly3",
    "matern_25_poly1","matern_25_poly2","wendland_c4_poly2",
})
