"""utils/training.py — Losses, metrics, optimisers, training loops."""
import time
from typing import Callable, Dict, List, Optional, Tuple
import jax, jax.numpy as jnp, numpy as np, optax
from .lbfgs import lbfgs_minimize


def compute_metrics(y_true, y_pred):
    y_t=np.asarray(y_true).ravel(); y_p=np.asarray(y_pred).ravel()
    err=y_p-y_t; mse=float(np.mean(err**2))
    ss_r=float(np.sum(err**2)); ss_t=float(np.sum((y_t-y_t.mean())**2)+1e-14)
    return dict(MSE=mse, RMSE=float(np.sqrt(mse)), MAE=float(np.mean(np.abs(err))),
                MaxErr=float(np.max(np.abs(err))), R2=1.0-ss_r/ss_t)


def mse_loss(params, model, x, y, deterministic=True):
    return jnp.mean((model.apply(params, x, deterministic=deterministic)-y)**2)


def total_loss(params, model, x, y, lam0=0.0, extra_fn=None, deterministic=True):
    loss = mse_loss(params, model, x, y, deterministic)
    if extra_fn is not None: loss = loss + extra_fn(params, model)
    return loss


def build_optimizer(name, lr, num_steps, weight_decay=1e-5, max_grad_norm=1.0):
    sched = optax.cosine_decay_schedule(lr, num_steps)
    clip  = optax.clip_by_global_norm(max_grad_norm)
    opts  = {"adam":  optax.adam(sched),
             "adamw": optax.adamw(sched, weight_decay=weight_decay),
             "radam": optax.radam(sched),
             "lion":  optax.lion(sched, weight_decay=weight_decay),
             "rprop": optax.rprop(lr),
             "sgd":   optax.sgd(sched, momentum=0.9, nesterov=True)}
    return optax.chain(clip, opts[name.lower()])


def l0_schedule(step, warmup, total, lam_max=1e-3):
    if step < warmup: return 0.0
    return lam_max * min(1.0, (step-warmup)**3/max((total-warmup)**3, 1))


def train_optax(model, params, x, y, optimizer_name="adamw", num_steps=5000,
                lr=1e-2, batch_size=None, weight_decay=1e-5, max_grad_norm=1.0,
                lam0_max=0.0, l0_warmup=1000, log_every=250, seed=1,
                extra_loss_fn=None):
    opt = build_optimizer(optimizer_name, lr, num_steps, weight_decay, max_grad_norm)
    opt_state = opt.init(params)

    @jax.jit
    def step(params, opt_state, xb, yb, lam0):
        def loss_fn(p):
            l = total_loss(p, model, xb, yb, lam0=lam0, deterministic=False)
            return l
        loss, grads = jax.value_and_grad(loss_fn)(params)
        updates, new_opt = opt.update(grads, opt_state, params)
        return optax.apply_updates(params, updates), new_opt, loss

    history, key = [], jax.random.PRNGKey(seed)
    N = x.shape[0]; t0 = time.time()
    for i in range(num_steps):
        lam0 = jnp.float32(l0_schedule(i, l0_warmup, num_steps, lam0_max))
        if batch_size and batch_size < N:
            key, sub = jax.random.split(key)
            idx = jax.random.randint(sub, (batch_size,), 0, N)
            xb, yb = x[idx], y[idx]
        else:
            xb, yb = x, y
        params, opt_state, loss = step(params, opt_state, xb, yb, lam0)
        history.append(float(loss))
        if i % log_every == 0 or i == num_steps-1:
            print(f"  [{optimizer_name}] step {i:5d}  loss={loss:.4e}  λ_0={float(lam0):.2e}")
    print(f"  Time: {time.time()-t0:.1f}s")
    return params, history


def train_lbfgs(model, params, x, y, num_steps=300, tol=1e-11, extra_loss_fn=None):
    def loss_fn(p): return total_loss(p, model, x, y, lam0=0.0, deterministic=True)
    new_params, final = lbfgs_minimize(loss_fn, params, maxiter=num_steps, tol=tol)
    return new_params, [final]*num_steps


def train_two_stage(model, params, x, y, adam_steps=4000, lbfgs_steps=300,
                    lr=1e-2, lam0_max=0.0, extra_loss_fn=None):
    print("--- Stage 1: AdamW ---")
    params, h1 = train_optax(model, params, x, y, "adamw",
                              num_steps=adam_steps, lr=lr, lam0_max=lam0_max)
    print("--- Stage 2: L-BFGS ---")
    params, h2 = train_lbfgs(model, params, x, y, num_steps=lbfgs_steps)
    return params, h1+h2


class EMAState:
    def __init__(self, params, decay=0.999): self.params=params; self.decay=decay
    def update(self, p):
        ema = jax.tree_util.tree_map(lambda e,n: self.decay*e+(1-self.decay)*n, self.params, p)
        return EMAState(ema, self.decay)
