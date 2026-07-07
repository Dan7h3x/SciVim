"""K-KAN: Kernel Kolmogorov-Arnold Networks v3.0"""
__version__ = "3.0.0"
from .model import KKAN, HermiteKKAN, count_params
from .kernels import get_kernel, KERNEL_REGISTRY
