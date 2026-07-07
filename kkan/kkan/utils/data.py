"""utils/data.py — Dataset factories 1D/2D/3D."""
import jax, jax.numpy as jnp

TARGETS_1D = {
    "sine":    lambda x: jnp.sin(4*jnp.pi*x[...,0]),
    "runge":   lambda x: 1.0/(1.0+25.0*x[...,0]**2),
    "abs":     lambda x: jnp.abs(x[...,0]),
    "bessel":  lambda x: jnp.sin(10*x[...,0])*jnp.exp(-jnp.abs(x[...,0])),
}
TARGETS_2D = {
    "gaussian_mix": lambda xy: (
        jnp.exp(-((xy[...,0]-0.3)**2+(xy[...,1]-0.3)**2)/0.05)
        -0.7*jnp.exp(-((xy[...,0]+0.4)**2+(xy[...,1]+0.2)**2)/0.08)),
    "oscillatory": lambda xy: (
        jnp.sin(3*jnp.pi*xy[...,0])*jnp.cos(2*jnp.pi*xy[...,1])
        +0.3*xy[...,0]*xy[...,1]),
    "franke": lambda xy: (
        0.75*jnp.exp(-((9*xy[...,0]-2)**2+(9*xy[...,1]-2)**2)/4)
        +0.75*jnp.exp(-(9*xy[...,0]+1)**2/49-(9*xy[...,1]+1)/10)
        +0.5*jnp.exp(-((9*xy[...,0]-7)**2+(9*xy[...,1]-3)**2)/4)
        -0.2*jnp.exp(-(9*xy[...,0]-4)**2-(9*xy[...,1]-7)**2)),
    "peaks": lambda xy: (
        3*(1-3*xy[...,0])**2*jnp.exp(-(3*xy[...,0])**2-(3*xy[...,1]+1)**2)
        -10*(3*xy[...,0]/5-(3*xy[...,0])**3-(3*xy[...,1])**5)
        *jnp.exp(-(3*xy[...,0])**2-(3*xy[...,1])**2)
        -(1/3)*jnp.exp(-(3*xy[...,0]+1)**2-(3*xy[...,1])**2))/8,
}
TARGETS_3D = {
    "sphere_wave": lambda xyz: jnp.sin(
        jnp.pi*jnp.sqrt(xyz[...,0]**2+xyz[...,1]**2+xyz[...,2]**2+1e-8)),
    "gaussian_3d": lambda xyz: jnp.exp(
        -(xyz[...,0]**2+xyz[...,1]**2+xyz[...,2]**2)/0.25),
}

def make_1d(fn, n_train=800, n_test=500, seed=0, domain=(-1.,1.)):
    lo,hi=domain
    x_tr=jax.random.uniform(jax.random.PRNGKey(seed),(n_train,1),minval=lo,maxval=hi)
    x_te=jnp.linspace(lo,hi,n_test)[:,None]
    return (x_tr,fn(x_tr)[:,None]),(x_te,fn(x_te)[:,None])

def make_2d(fn, n_train=3000, n_test_grid=64, seed=0, domain=(-1.,1.)):
    lo,hi=domain
    x_tr=jax.random.uniform(jax.random.PRNGKey(seed),(n_train,2),minval=lo,maxval=hi)
    t=jnp.linspace(lo,hi,n_test_grid); xx,yy=jnp.meshgrid(t,t)
    x_te=jnp.stack([xx.ravel(),yy.ravel()],axis=-1)
    return (x_tr,fn(x_tr)[:,None]),(x_te,fn(x_te)[:,None]),(xx,yy)

def make_3d(fn, n_train=8000, n_test=2000, seed=0, domain=(-1.,1.)):
    lo,hi=domain
    x_tr=jax.random.uniform(jax.random.PRNGKey(seed),(n_train,3),minval=lo,maxval=hi)
    x_te=jax.random.uniform(jax.random.PRNGKey(seed+1),(n_test,3),minval=lo,maxval=hi)
    return (x_tr,fn(x_tr)[:,None]),(x_te,fn(x_te)[:,None])
