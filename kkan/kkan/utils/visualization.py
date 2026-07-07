"""utils/visualization.py — All plotting functions."""

import numpy as np
import matplotlib

# matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import cm


def plot_training(histories, labels, title="Training", save=None):
    fig, ax = plt.subplots(figsize=(9, 4))
    for h, lb in zip(histories, labels):
        ax.semilogy(h, label=lb)
    ax.set_xlabel("step")
    ax.set_ylabel("loss")
    ax.set_title(title)
    ax.legend()
    ax.grid(True, which="both", alpha=0.3)
    plt.tight_layout()
    if save:
        plt.savefig(save, dpi=150)
    plt.show()


def plot_1d(x, y_true, y_pred, title="", save=None):
    x = np.asarray(x).ravel()
    idx = np.argsort(x)
    fig, axes = plt.subplots(1, 2, figsize=(12, 4))
    axes[0].plot(x[idx], np.asarray(y_true).ravel()[idx], "b-", lw=2, label="target")
    axes[0].plot(x[idx], np.asarray(y_pred).ravel()[idx], "r--", lw=2, label="K-KAN")
    axes[0].legend()
    axes[0].grid(True, alpha=0.3)
    axes[0].set_title(title)
    axes[1].semilogy(
        x[idx], np.abs(np.asarray(y_pred).ravel() - np.asarray(y_true).ravel())[idx]
    )
    axes[1].set_title("|error|")
    axes[1].grid(True, alpha=0.3)
    plt.tight_layout()
    if save:
        plt.savefig(save, dpi=150)
    plt.show()


def plot_2d(y_true, y_pred, xx, yy, title="", save=None):
    Zt = np.asarray(y_true).reshape(xx.shape)
    Zp = np.asarray(y_pred).reshape(xx.shape)
    fig = plt.figure(figsize=(16, 4))
    for i, (Z, lb) in enumerate([(Zt, "Target"), (Zp, "K-KAN")]):
        ax = fig.add_subplot(1, 3, i + 1, projection="3d")
        ax.plot_surface(xx, yy, Z, cmap=cm.viridis, alpha=0.9)
        ax.set_title(lb)
    ax3 = fig.add_subplot(1, 3, 3)
    im = ax3.imshow(
        np.abs(Zp - Zt),
        origin="lower",
        extent=[xx.min(), xx.max(), yy.min(), yy.max()],
        cmap="inferno",
    )
    plt.colorbar(im, ax=ax3)
    ax3.set_title("|error|")
    plt.suptitle(title)
    plt.tight_layout()
    if save:
        plt.savefig(save, dpi=150)
    plt.show()


def plot_pde_1d(x, u_pred, u_true=None, title="PDE solution", save=None):
    x_np = np.asarray(x).ravel()
    idx = np.argsort(x_np)
    ncols = 2 if u_true is not None else 1
    fig, axes = plt.subplots(1, ncols, figsize=(6 * ncols, 4))
    if ncols == 1:
        axes = [axes]
    axes[0].plot(x_np[idx], np.asarray(u_pred).ravel()[idx], "r-", lw=2, label="K-KAN")
    if u_true is not None:
        axes[0].plot(
            x_np[idx], np.asarray(u_true).ravel()[idx], "b--", lw=2, label="exact"
        )
    axes[0].legend()
    axes[0].grid(True, alpha=0.3)
    axes[0].set_title(title)
    if u_true is not None:
        axes[1].semilogy(
            x_np[idx],
            np.abs(np.asarray(u_pred).ravel() - np.asarray(u_true).ravel())[idx],
        )
        axes[1].set_title("|error|")
        axes[1].grid(True, alpha=0.3)
    plt.tight_layout()
    if save:
        plt.savefig(save, dpi=150)
    plt.show()


def plot_pde_2d(xx, yy, u_pred, u_true=None, title="PDE", save=None):
    Up = np.asarray(u_pred).reshape(xx.shape)
    fig = plt.figure(figsize=(15, 4))
    ax1 = fig.add_subplot(1, 3 if u_true is not None else 1, 1, projection="3d")
    ax1.plot_surface(xx, yy, Up, cmap=cm.plasma, alpha=0.9)
    ax1.set_title("K-KAN")
    if u_true is not None:
        Ut = np.asarray(u_true).reshape(xx.shape)
        ax2 = fig.add_subplot(1, 3, 2, projection="3d")
        ax2.plot_surface(xx, yy, Ut, cmap=cm.plasma, alpha=0.9)
        ax2.set_title("Exact")
        ax3 = fig.add_subplot(1, 3, 3)
        im = ax3.imshow(
            np.abs(Up - Ut),
            origin="lower",
            extent=[xx.min(), xx.max(), yy.min(), yy.max()],
            cmap="inferno",
        )
        plt.colorbar(im, ax=ax3)
        ax3.set_title("|error|")
    plt.suptitle(title)
    plt.tight_layout()
    if save:
        plt.savefig(save, dpi=150)
    plt.show()


def plot_gate_heatmap(params, layer_dims, threshold=0.5, save=None):
    n = len(layer_dims) - 1
    fig, axes = plt.subplots(1, n, figsize=(4 * n, 3))
    if n == 1:
        axes = [axes]
    for l, ax in enumerate(axes):
        lp = params["params"].get(f"layer_{l}", {})
        gp = lp.get("gates", None)
        if gp is None:
            ax.text(0.5, 0.5, "no gates", ha="center")
            continue
        gate = 1 / (1 + np.exp(-np.asarray(gp["log_alpha"])))
        im = ax.imshow(gate, vmin=0, vmax=1, cmap="RdYlGn", aspect="auto")
        ax.set_title(f"Layer {l}: {(gate >= threshold).sum()}/{gate.size} active")
        plt.colorbar(im, ax=ax, fraction=0.046)
    plt.suptitle("Edge gate probabilities")
    plt.tight_layout()
    if save:
        plt.savefig(save, dpi=150)
    plt.show()


def plot_kernels(names, r_max=1.5, n=400, save=None):
    import jax.numpy as jnp
    from ..kernels.families import get_kernel

    r = np.linspace(-r_max, r_max, n)
    fig, ax = plt.subplots(figsize=(9, 4))
    for name in names:
        k = get_kernel(name)
        ax.plot(r, np.asarray(k(jnp.array(r))), lw=2, label=name)
    ax.axhline(0, color="k", lw=0.5)
    ax.set_xlabel("r")
    ax.set_ylabel("k(r)")
    ax.set_title("Kernel profiles")
    ax.legend()
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    if save:
        plt.savefig(save, dpi=150)
    plt.show()


def plot_mol_spacetime(times, U, x_int, exact_fn=None, save=None):
    fig, axes = plt.subplots(
        1, 2 if exact_fn else 1, figsize=(12 if exact_fn else 6, 4)
    )
    if not exact_fn:
        axes = [axes]
    im1 = axes[0].imshow(
        U.T,
        origin="lower",
        aspect="auto",
        extent=[times[0], times[-1], x_int.min(), x_int.max()],
        cmap="viridis",
    )
    axes[0].set_xlabel("t")
    axes[0].set_ylabel("x")
    axes[0].set_title("MOL solution")
    plt.colorbar(im1, ax=axes[0])
    if exact_fn:
        U_ex = np.array([exact_fn(x_int, t) for t in times]).T
        im2 = axes[1].imshow(
            np.abs(U.T - U_ex),
            origin="lower",
            aspect="auto",
            extent=[times[0], times[-1], x_int.min(), x_int.max()],
            cmap="inferno",
        )
        axes[1].set_xlabel("t")
        axes[1].set_title("|error|")
        plt.colorbar(im2, ax=axes[1])
    plt.tight_layout()
    if save:
        plt.savefig(save, dpi=150)
    plt.show()
