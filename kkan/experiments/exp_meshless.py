"""experiments/exp_meshless.py — Direct meshless PDE solvers (Kansa, Galerkin, RKPM, MOL).

Run:
    python main.py meshless --method kansa --dim 1
    python main.py meshless --method galerkin --dim 2
    python main.py meshless --method rkpm
    python main.py meshless --method mol
    python main.py meshless --method all
"""
import sys, os; sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import numpy as np
from kkan.solvers import KansaSolver, GalerkinSolver, RKPMInterpolant, MOLSolver
from kkan.utils import compute_metrics, plot_pde_1d, plot_pde_2d, plot_mol_spacetime


def poisson_1d_meshless():
    print("\n=== Direct Meshless: Poisson 1D — Kansa vs Galerkin ===")
    N=120; x_int=np.linspace(0.01,0.99,N).reshape(-1,1); x_bc=np.array([[0.0],[1.0]])
    f_int=(np.pi**2*np.sin(np.pi*x_int)).ravel(); g_bc=np.zeros(2)
    x_te=np.linspace(0,1,400).reshape(-1,1); u_ex=np.sin(np.pi*x_te).ravel()
    print(f"\n  {'Method':20s} {'Kernel':18s} {'RMSE':>10s} {'R2':>10s}")
    for SolCls,mname in [(KansaSolver,"Kansa"),(GalerkinSolver,"Galerkin")]:
        for kname in ["rbf","matern_25","wendland_c4","wu_c2"]:
            try:
                sol=SolCls(kernel_name=kname,sigma=0.04,poly_degree=1)
                sol.fit(x_int,x_bc,f_int,g_bc)
                m=sol.evaluate(x_te,u_ex)
                print(f"  {mname:20s} {kname:18s} {m['RMSE']:>10.3e} {m['R2']:>10.5f}")
            except Exception as e:
                print(f"  {mname:20s} {kname:18s} FAILED: {e}")
    best=KansaSolver(kernel_name="matern_25",sigma=0.04,poly_degree=1)
    best.fit(x_int,x_bc,f_int,g_bc)
    plot_pde_1d(x_te,best.predict(x_te),u_ex,"Kansa: Poisson 1D (Matérn-2.5)")
    return best


def poisson_2d_meshless():
    print("\n=== Direct Meshless: Poisson 2D — Galerkin ===")
    N=20; x1d=np.linspace(0.02,0.98,N); XX,YY=np.meshgrid(x1d,x1d)
    x_int=np.stack([XX.ravel(),YY.ravel()],axis=-1)
    t_bc=np.linspace(0,1,50)
    x_bc=np.vstack([np.stack([t_bc,np.zeros_like(t_bc)],1),np.stack([t_bc,np.ones_like(t_bc)],1),
                     np.stack([np.zeros_like(t_bc),t_bc],1),np.stack([np.ones_like(t_bc),t_bc],1)])
    f_int=2*np.pi**2*np.sin(np.pi*x_int[:,0])*np.sin(np.pi*x_int[:,1])
    g_bc=np.zeros(x_bc.shape[0])
    solver=GalerkinSolver(kernel_name="rbf",sigma=0.15,lam_bc=1e4,poly_degree=1)
    solver.fit(x_int,x_bc,f_int,g_bc)
    n=40; t=np.linspace(0,1,n); xx,yy=np.meshgrid(t,t)
    x_te=np.stack([xx.ravel(),yy.ravel()],axis=-1)
    u_true=np.sin(np.pi*x_te[:,0])*np.sin(np.pi*x_te[:,1])
    u_pred=solver.predict(x_te)
    m=compute_metrics(u_true,u_pred)
    print("  Metrics:", {k:f"{v:.3e}" for k,v in m.items()})
    plot_pde_2d(xx,yy,u_pred,u_true,"Galerkin: Poisson 2D")
    return solver


def rkpm_demo():
    print("\n=== RKPM Interpolant — polynomial reproduction demo ===")
    x_int=np.linspace(0.01,0.99,60).reshape(-1,1)
    u_data=np.sin(np.pi*x_int).ravel()
    x_te=np.linspace(0,1,400).reshape(-1,1); u_ex=np.sin(np.pi*x_te).ravel()
    rkpm=RKPMInterpolant(kernel_name="wendland_c4",sigma=0.12,poly_degree=1)
    rkpm.fit(x_int,u_data)
    u_rkpm=rkpm.predict(x_te)
    m=compute_metrics(u_ex,u_rkpm)
    print("  Metrics:", {k:f"{v:.3e}" for k,v in m.items()})
    plot_pde_1d(x_te,u_rkpm,u_ex,"RKPM interpolant (Wendland-C4, degree 1)")
    return rkpm


def heat_1d_mol():
    print("\n=== MOL: Heat 1D+t (implicit backward Euler) ===")
    kappa=0.01; x_int=np.linspace(0.02,0.98,80).reshape(-1,1); x_bc=np.array([[0.0],[1.0]])
    u0_fn=lambda x: np.sin(np.pi*x[:,0])
    g_fn=lambda x,t: np.zeros(x.shape[0]); f_fn=lambda x,t: np.zeros(x.shape[0])
    exact=lambda x,t: np.sin(np.pi*x[:,0])*np.exp(-kappa*np.pi**2*t)
    solver=MOLSolver(kernel_name="rbf",sigma=0.04,kappa=kappa,poly_degree=1,reg=1e-9)
    times,U=solver.solve(x_int,x_bc,u0_fn,g_fn,f_fn,T=1.0,dt=0.01)
    u_final_ex=exact(x_int,times[-1])
    m=compute_metrics(u_final_ex,U[-1])
    print("  T=1 metrics:", {k:f"{v:.3e}" for k,v in m.items()})
    plot_mol_spacetime(times,U,x_int[:,0],exact_fn=lambda xc,t:exact(xc.reshape(-1,1),t))
    return solver


def run(args):
    if args.method in ("kansa","all"):
        poisson_1d_meshless()
    if args.method in ("galerkin","all"):
        if args.dim==1 and args.method!="all":
            poisson_1d_meshless()
        else:
            poisson_2d_meshless()
    if args.method in ("rkpm","all"): rkpm_demo()
    if args.method in ("mol","all"): heat_1d_mol()


def add_args(parser):
    parser.add_argument("--method", default="kansa",
                        choices=["kansa","galerkin","rkpm","mol","all"])
    parser.add_argument("--dim", type=int, default=1, choices=[1,2])


if __name__ == "__main__":
    import argparse; p=argparse.ArgumentParser(); add_args(p); run(p.parse_args())
