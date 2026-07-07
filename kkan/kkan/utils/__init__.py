from .training import (compute_metrics, build_optimizer, mse_loss, total_loss,
                        train_optax, train_lbfgs, train_two_stage, EMAState, l0_schedule)
from .lbfgs import lbfgs_minimize
from .data import (TARGETS_1D, TARGETS_2D, TARGETS_3D, make_1d, make_2d, make_3d)
from .quadrature import (gauss_legendre_1d, gauss_legendre_nd, halton_nd,
                          resample_collocation, boundary_quad_2d)
from .diff_ops import (grad_u, laplacian_u, bilaplacian_u, div_grad_a_u,
                        grad_t, u_tt, lap_spatial, convect, normal_deriv)
from .visualization import (plot_training, plot_1d, plot_2d, plot_pde_1d, plot_pde_2d,
                              plot_gate_heatmap, plot_kernels, plot_mol_spacetime)
