"""model/pruning.py — Structured pruning utilities for K-KAN."""
import numpy as np
import jax.numpy as jnp
import flax.linen as nn
import copy


def l0_schedule(step, warmup, total, lam_max=1e-3):
    if step < warmup: return 0.0
    return lam_max * min(1.0, (step-warmup)**3/max((total-warmup)**3, 1))


def get_gate_matrix(params, layer_idx):
    lp = params["params"].get(f"layer_{layer_idx}", {})
    gp = lp.get("gates", None)
    if gp is None: return None
    return 1.0/(1.0+np.exp(-np.asarray(gp["log_alpha"])))


def get_edge_importance(params, layer_idx):
    lp = params["params"].get(f"layer_{layer_idx}", {})
    w  = np.asarray(lp.get("w_kern", np.array([])))
    if w.size == 0: return None
    mag = np.linalg.norm(w, axis=-1)/np.sqrt(w.shape[-1])
    gate = get_gate_matrix(params, layer_idx)
    return gate * mag if gate is not None else mag


def prune_edges(params, layer_dims, threshold=0.5):
    params = copy.deepcopy(params)
    masks = {}
    for l in range(len(layer_dims)-1):
        key = f"layer_{l}"
        lp  = params["params"][key]
        gate = get_gate_matrix(params, l)
        if gate is None:
            masks[key] = np.ones((layer_dims[l], layer_dims[l+1]), dtype=bool)
            continue
        mask = gate >= threshold
        masks[key] = mask
        for wkey in ["w_kern", "w_base", "w_poly"]:
            if wkey not in lp: continue
            arr = np.asarray(lp[wkey])
            if wkey == "w_kern":   arr[~mask, :] = 0.0
            elif wkey == "w_base": arr[~mask]    = 0.0
            elif wkey == "w_poly": arr[~mask, :] = 0.0
            lp[wkey] = jnp.array(arr)
    return params, masks


def node_activity(params, layer_dims, threshold=0.5):
    L = len(layer_dims)
    active = {l: np.ones(layer_dims[l], dtype=bool) for l in range(L)}
    for l in range(L-1):
        mask = get_gate_matrix(params, l)
        if mask is None: continue
        hard = mask >= threshold
        active[l]   = active[l]   & hard.any(axis=1)
        active[l+1] = active[l+1] & hard.any(axis=0)
    active[0] = np.ones(layer_dims[0], dtype=bool)
    active[L-1] = np.ones(layer_dims[L-1], dtype=bool)
    return active


def effective_layer_dims(params, layer_dims, threshold=0.5):
    activity = node_activity(params, layer_dims, threshold)
    return [int(activity[l].sum()) for l in range(len(layer_dims))]


def pruning_report(params, layer_dims, threshold=0.5):
    lines = ["="*60, "K-KAN Pruning Report", "="*60]
    total_e, active_e = 0, 0
    for l in range(len(layer_dims)-1):
        imp  = get_edge_importance(params, l)
        gate = get_gate_matrix(params, l)
        n_edges = layer_dims[l]*layer_dims[l+1]
        total_e += n_edges
        n_active = int((gate >= threshold).sum()) if gate is not None else n_edges
        active_e += n_active
        lines.append(f"  Layer {l} ({layer_dims[l]}->{layer_dims[l+1]}): "
                     f"{n_active}/{n_edges} edges active ({100*n_active/n_edges:.1f}%)")
        if imp is not None:
            lines.append(f"    importance: min={imp.min():.3f}  mean={imp.mean():.3f}  max={imp.max():.3f}")
    eff = effective_layer_dims(params, layer_dims, threshold)
    lines += ["-"*60,
              f"Total sparsity: {100*(1-active_e/max(total_e,1)):.1f}%",
              f"Effective architecture: {eff}", "="*60]
    return "\n".join(lines)
