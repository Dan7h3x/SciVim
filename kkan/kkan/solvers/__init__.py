from .variational_solver import (VariationalSolver, XPINNSolver,
    deep_ritz_loss, lspg_loss, RESIDUALS,
    residual_poisson, residual_helmholtz, residual_heat,
    residual_wave, residual_burgers, residual_biharmonic, residual_convection_diffusion,
    residual_allen_cahn, residual_cahn_hilliard, residual_navier_stokes_streamfunction,
    velocity_from_streamfunction)
from .meshless_solver import KansaSolver, GalerkinSolver, RKPMInterpolant, MOLSolver
from .coupled_solver import CahnHilliardSolver, NavierStokesCavitySolver
