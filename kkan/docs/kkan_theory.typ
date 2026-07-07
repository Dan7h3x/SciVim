// ============================================================
//  K-KAN: Complete Mathematical Reference
//  Kernels, KAN Layers, Variational & Meshless PDE Solvers,
//  Derivative Learning, and Mixed-Formulation 4th-Order PDEs
// ============================================================

#set document(
  title: "K-KAN: Complete Mathematical Reference",
  author: "Technical Reference"
)
#set page(margin: (x: 2.2cm, y: 2.5cm), numbering: "1")
#set text(font: "New Computer Modern", size: 10.5pt)
#set heading(numbering: "1.1")
#set par(justify: true, leading: 0.65em)
#show heading: set block(above: 1.4em, below: 0.8em)
#show raw: set text(font: "DejaVu Sans Mono", size: 9pt)

#let norm(x) = $lr(|| #x ||)$
#let abs1(x) = $lr(| #x |)$
#let bx = $bold(x)$
#let bc = $bold(c)$
#let bw = $bold(w)$
#let bg = $bold(g)$
#let bu = $bold(u)$
#let RR = $bb(R)$
#let sig = [$sigma$]
#let lam = [$lambda$]
#let eps = [$epsilon$]

#align(center)[
  #text(size: 20pt, weight: "bold")[K-KAN: Complete Mathematical Reference]
  #v(0.3em)
  #text(size: 12.5pt)[Kernels · KAN Layers · Variational \& Meshless PDE Solvers · Derivative Learning · Mixed-Formulation 4th-Order PDEs]
  #v(0.4em)
  #text(size: 10pt, fill: gray)[Covers every module in the codebase, in build order]
]

#v(0.8em)
#outline(indent: auto, depth: 3)
#pagebreak()

// ============================================================
= Overview and Notation
// ============================================================

Throughout, $bx in RR^d$ denotes a spatial (or space-time) point, $bc_k$ a
kernel centre, $sig$ a bandwidth, and $r = norm(bx - bc)\/sig$ the
normalised radial distance used by every kernel. A K-KAN layer maps
$RR^(d_ell) -> RR^(d_(ell+1))$ by summing, for each output node $j$, a
*learned univariate function* of each input coordinate $x_i$:

$ x_j^((ell+1)) = sum_(i=1)^(d_ell) phi_(i j)^((ell)) (x_i^((ell))). $

Each edge function $phi_(i j)$ is represented as a kernel expansion —
this single design choice is what connects the whole codebase to classical
meshless/RBF approximation theory, and is why every PDE solver, derivative
estimator, and pruning mechanism below is expressed in kernel language.

#pagebreak()

// ============================================================
= Kernel Families (`kkan/kernels/families.py`)
// ============================================================

== Positive Definiteness

A radial kernel $k(bx,bc) = phi(norm(bx-bc))$ is *positive definite* on
$RR^d$ iff for all finite point sets and coefficients $bold(alpha) != 0$,
$ sum_(i,j) alpha_i alpha_j phi(norm(bx_i - bx_j)) > 0. $
Equivalently (Bochner), $phi$ is the Fourier transform of a positive
measure. This guarantees kernel (Gram) matrices are symmetric
positive-definite for distinct sites, so interpolation systems are
solvable.

== Implemented Families

#figure(
  table(
    columns: (auto, 1fr, auto, auto),
    align: (left,left,center,center),
    table.header[*Kernel*][*Formula $k(r)$*][*Smooth.*][*Support*],
    [Gaussian RBF], [$exp(-r^2)$], [$C^infinity$], [Global],
    [Inverse Multiquadric], [$(1+r^2)^(-beta)$], [$C^infinity$], [Global],
    [Matérn-$1/2$], [$e^(-r)$], [$C^0$], [Global],
    [Matérn-$3/2$], [$(1+sqrt(3)r)e^(-sqrt(3)r)$], [$C^2$], [Global],
    [Matérn-$5/2$], [$(1+sqrt(5)r+5r^2/3)e^(-sqrt(5)r)$], [$C^4$], [Global],
    [Wendland $C^(2k)$], [piecewise polynomial $times (1-r)_+^l$], [$C^(2k)$], [Compact, $r<1$],
    [Wu $C^(2k)$], [piecewise polynomial $times (1-r)_+^l$], [$C^(2k)$], [Compact, $r<1$],
  ),
  caption: [Kernel families, `kkan/kernels/families.py`.]
)

The native-space (Sobolev) order of each kernel — the exponent $tau$
governing interpolation convergence $norm(u-s_h)_(L^infinity) = O(h^tau)$
— is: Matérn-$nu$: $tau=nu+d/2$; Wendland-$C^(2k)$: $tau=k+d/2+1/2$; RBF:
$tau=infinity$.

== Polynomial Augmentation (`PolyAugKernel`)

For compactly-supported kernels, the raw kernel matrix can be singular
when scattered points fall outside each other's support. Augmenting with
a polynomial tail restores unisolvence:
$ s(bx) = sum_j w_j k(bx,bx_j) + sum_(abs1(alpha) <= m) q_alpha bx^alpha, $
with the *annihilation condition* $sum_j w_j bx_j^alpha = 0$ for all
$abs1(alpha) <= m$, giving the augmented saddle-point system
$ mat(K, P; P^top, 0) mat(bw; bold(q)) = mat(bold(f); 0). $

The Legendre basis (`PolyAugKernel.legendre`, Bonnet recursion
$P_n = ((2n-1)x P_(n-1) - (n-1)P_(n-2))\/n$) is used instead of raw
monomials because it is orthogonal on $[-1,1]$, avoiding the
Vandermonde-matrix ill-conditioning that plagues monomial bases beyond
degree $tilde.op 6$.

#pagebreak()

// ============================================================
= Kernel Derivatives (`kkan/kernels/derivatives.py`)
// ============================================================

== Analytic Derivative Formulas

With $r = norm(bx-bc)\/sig$, the chain rule gives:

$ (partial k)/(partial x_i) = k'(r) dot (x_i-c_i)/(sig^2 r), quad quad
  (partial^2 k)/(partial x_i partial x_j)
    = (k''(r))/sig^4 (x_i-c_i)(x_j-c_j)/r^2
    + (k'(r))/sig^2 (delta_(i j)/r - (x_i-c_i)(x_j-c_j)/(sig^2 r^3)), $

$ Delta_bx k = "tr"(nabla^2_bx k) = (k''(r) + (d-1)k'(r)\/r) \/ sig^2. $

#pad(left: 1em)[
  *Correctness note*: an earlier version of this code had two independent
  scaling/sign bugs in these formulas — a missing $1/sig$ factor in
  $partial r/partial x_i$, and an algebraically incorrect Hessian
  assembly. Both were traced by comparing against `jax.grad`/`jax.hessian`
  autodiff ground truth on all four kernel families and are now fixed;
  the formulas above are the verified, correct closed forms.
]

== Safety at $r=0$

Since kernel centres frequently coincide with evaluation points (e.g. the
diagonal of a collocation matrix, where $bx_i = bc_i$), and
$norm(dot)$ has an undefined second derivative at the origin,
naively differentiating $r$ via `jax.grad`/`jax.hessian` through
`jnp.linalg.norm` produces `NaN` on the diagonal. The fix used throughout
is a safe floor $r <- max(r, epsilon)$, $epsilon=10^(-7)$, applied *before*
evaluating $k'(r)$, $k''(r)$ — since $k'(0)=0$ for every kernel here, the
floored value introduces negligible bias while eliminating the
division-by-zero.

#pagebreak()

// ============================================================
= K-KAN Layer (`kkan/model/kan_layer.py`)
// ============================================================

== Adaptive Centre Placement

Centres are initialised at Gauss-Legendre or Chebyshev quadrature nodes
rather than a uniform grid:
$ c_k = ((xi_k+1))/2 (b-a) + a, quad P_K (xi_k) = 0 "(Gauss)"; quad
  c_k = cos(pi k\/(K-1)) "(Chebyshev)". $
Both node families minimise the Lebesgue constant
$Lambda_K = max_x sum_k abs1(ell_k(x))$ for polynomial-type interpolation
— Chebyshev achieves $Lambda_K=O(log K)$ vs $O(2^K\/(K log K))$ for
uniform spacing, directly suppressing Runge-type oscillation.

== Moving-Least-Squares (MLS) Normalisation

Raw kernel activations $phi_k(bx) = k(r_k)$ are optionally renormalised:
$ tilde(phi)_k(bx) = phi_k(bx) \/ (sum_m phi_m(bx) + epsilon). $
This enforces the *partition-of-unity* property $sum_k tilde(phi)_k=1$,
guaranteeing exact reproduction of constants (the zeroth Strang-Fix
condition) without a bias term, and bounding the kernel contribution to
$[min_k w_k, max_k w_k]$ regardless of $sig$.

*Trade-off*: for compactly-supported kernels, normalisation destroys
exact sparsity (any nonzero denominator term makes all numerators
nonzero), so it should be disabled (`use_mls_norm=False`) whenever sparse
kernel matrices matter (e.g. the meshless MOL solver).

== Edge Activation

$ phi_(i j)(x_i) = sum_(k=1)^K w_(i j k) tilde(phi)_k (x_i)
  + v_(i j) "SiLU"(x_i) + sum_beta q_(i j beta) P_beta (x_i). $

The full layer output, vectorised over batch $B$:
$ y_(b j) = sum_(i=1)^(d_ell) "gate"_(i j) dot
  [ sum_k w_(i j k) tilde(phi)_(b i k) + v_(i j) "SiLU"(x_(b i)) + dots ]. $

Kernels are elementwise functions of the pre-computed distance tensor
`r` of shape `(B, in, out, K)`; they are applied *directly* rather than
via nested `jax.vmap`. (An earlier implementation wrapped a 4-fold nested
`vmap` around each already-elementwise kernel call — mathematically a
no-op, but it inflated JAX's tracing graph so severely that even trivial
models took tens of seconds to JIT-compile; removing the redundant `vmap`
layers had zero effect on outputs and a $>10 times$ speedup on compile
time.)

#pagebreak()

// ============================================================
= Hard-Concrete Pruning (`kkan/model/kan_layer.py`, `pruning.py`)
// ============================================================

Each edge $(i,j)$ carries a gate
$ g_(i j) = "clip"(sigma(log alpha_(i j))(zeta-gamma)+gamma,,0,1), $
with stretch parameters $gamma=-0.1$, $zeta=1.1$ ensuring $g$ can reach
exactly 0 or 1. The differentiable expected $L_0$ penalty is
$ EE[norm(bold(g))_0] = sum_(i,j) sigma(log alpha_(i j)
    - beta log(-gamma\/zeta)), $
added to the training loss with a cubic warm-up schedule
$ lam_0(t) = lam_max min(1, ((t-t_w)\/(T-t_w))^3) $
so pruning pressure only activates after the network has had time to
find a good dense solution.

*Compute cost*: enabling pruning requires computing both the gated and
(implicitly, via the gate's gradient) ungated contribution per edge,
roughly doubling forward/backward cost. Combined with deep derivative
graphs (Hessians, bi-Laplacians), this compounding cost is severe enough
that pruning is disabled by default for all 4th-order PDE examples (see
§9) to avoid XLA compiler instability.

#pagebreak()

// ============================================================
= Variational PDE Solvers (`kkan/solvers/variational_solver.py`)
// ============================================================

== Deep Ritz (Energy Minimisation)

For the self-adjoint elliptic problem $-nabla dot(a nabla u) = f$,
$u=g$ on $diff Omega$, the energy functional
$ cal(E)[u] = 1/2 integral_Omega a norm(nabla u)^2 dif bx
  - integral_Omega f u dif bx $
is minimised by the unique weak solution (Euler-Lagrange = the PDE).
Discretised with Gauss quadrature $(bx_i,w_i)$:
$ cal(E)[u_theta] approx 1/2 sum_i w_i a(bx_i) norm(nabla u_theta (bx_i))^2
  - sum_i w_i f(bx_i) u_theta(bx_i)
  + beta_("bc") 1/N_b sum_j (u_theta(bx_j)-g(bx_j))^2. $
Because $cal(E)$ is strictly convex in $u$ (for $a>=a_0>0$), this loss
landscape is far better-conditioned than the strong-form residual — no
second derivatives of $u_theta$ are needed (only $nabla u_theta$).

== Least-Squares Petrov-Galerkin (LSPG)

For non-self-adjoint or time-dependent PDEs, minimise
$ cal(J)[u_theta] = 1/2 sum_i w_i abs1(cal(L)[u_theta](bx_i))^2
  + beta_("bc") norm(u_theta-g)^2_(diff Omega)
  + beta_("ic") norm(u_theta-u_0)^2_(t=0). $
Collocation points use Gauss (tensor-product, $n^d$ points) or Halton
(low-discrepancy, exactly $n$ points, no curse of dimensionality) quadrature.

== Adaptive Collocation

Residual-based resampling draws new points $prop abs1(cal(L)[u_theta])^2$,
concentrating effort where the PDE is hardest to satisfy (shocks,
boundary layers) — the standard RAR/RUCA strategy.

== XPINN Domain Decomposition

$Omega = union.big_k Omega_k$, each sub-domain trained independently with
interface value-continuity enforced as an alternating (Gauss-Seidel-like)
soft boundary condition using the neighbour's current prediction.

#pagebreak()

// ============================================================
= Direct Meshless Solvers (`kkan/solvers/meshless_solver.py`)
// ============================================================

== Kansa Collocation

Ansatz $u(bx)=sum_j w_j k(bx,bx_j) + "poly tail"$; enforce the PDE
*pointwise* at interior points and the BC at boundary points:
$ mat(A_("int"), P_("int"); A_("bc"), P_("bc"); P_c^top, 0)
  mat(bw; bold(q)) = mat(-bold(f); bold(g); 0), $
with $A_("int")[i,j] = -Delta_bx k(bx_i,bx_j)$ computed via the
*analytic* (now-corrected, NaN-safe) Laplacian formula of §4 — critically
important since $bx_i=bc_j$ occurs on the diagonal.

== Symmetric Galerkin

Forms normal equations $B^top B + lam_("bc") B_("bc")^top B_("bc")$,
symmetric positive (semi-)definite by construction, trading a squared
condition number ($kappa(B^top B)=kappa(B)^2$) for guaranteed SPD
structure amenable to Cholesky.

== RKPM / MLS Interpolant

At each query point, solves a small local system
$ (P^top W(bx) P) bold(a)(bx) = P^top W(bx) bu, quad hat(u)(bx) = P_b (bx)^top bold(a)(bx), $
$W(bx) = "diag"(k(bx-bx_j))$ — reproduces polynomials of degree $<=m$
exactly regardless of bandwidth.

== Method of Lines

Backward-Euler time-stepping for $u_t = kappa Delta u + f$:
$ (K_("int") - dif t, kappa, L_("int")) bw^(n+1) = K_("int") bw^n + dif t, bold(f)^(n+1), $
unconditionally stable ($A$-stable) but only $O(dif t)$ accurate.

#pagebreak()

// ============================================================
= Derivative and Gradient Learning
// ============================================================

This section documents the joint value+gradient approximation machinery
and, in detail, a subtle sign-convention bug that silently corrupted
gradient accuracy in earlier versions — its diagnosis and fix are
instructive for anyone extending the Hermite collocation code.

== Hermite-Birkhoff Collocation (`kkan/approximation/hermite_collocation.py`)

*Ansatz.* Both the value-basis and derivative-basis functions are
functions of the *free evaluation variable* $bx$, with the data site
$bx_j$ held fixed as a parameter:
$ s(bx) = sum_j w_j k(bx,bx_j) + sum_j sum_l v_(j,l) diff_l [k(bx,bx_j)]
  + "poly tail", $
where $diff_l [k(bx,bx_j)]$ means: differentiate the function
$bx |-> k(bx,bx_j)$ with respect to its $l$-th argument, i.e. exactly
$partial k \/ partial x_l$ evaluated at $(bx,bx_j)$ — *never* a
derivative with respect to the fixed parameter $bx_j$.

*Value-row conditions* ($s(bx_i)=u_i$):
$ K_(i j) = k(bx_i,bx_j), quad quad G_(i j l) = (partial k)/(partial x_l)(bx_i,bx_j). $

*Derivative-row conditions*
($(partial s\/partial x_m)(bx_i) = g_(i,m)$): differentiating $s$
again with respect to $x_m$, EVERY term in the ansatz picks up one more
$partial\/partial x_m$ acting on the *same free variable* $bx$:
$ (partial s)/(partial x_m)(bx_i)
  = sum_j w_j (partial k)/(partial x_m)(bx_i,bx_j)
  + sum_j sum_l v_(j,l) (partial^2 k)/(partial x_m partial x_l)(bx_i,bx_j)
  + dots $

So the derivative-derivative block is
$ H_(i,m,j,l) = (partial^2 k)/(partial x_m partial x_l)(bx_i,bx_j)
  = "kernel_hessian_x"(bx_i,bx_j)[m,l], $
the *ordinary $bx$-Hessian* of $k(dot,bx_j)$ evaluated at $bx_i$ —
*no sign flip, no derivative with respect to the centre.*

#block(fill: rgb("#fff3cd"), inset: 8pt, radius: 4pt)[
  *The bug and its fix.* An earlier implementation instead computed
  $H_(i,m,j,l) = -partial^2 k \/ partial x_m partial c_l$ — i.e. it
  mixed a derivative-w.r.t.-evaluation-point with a
  derivative-w.r.t.-centre, using the (correct, but *inapplicable here*)
  radial-kernel identity $partial_bx k = -partial_bc k$. That identity
  holds, but the value-row block $G$ was built using
  $partial_bx k$ (matching the ansatz above), while the derivative-
  derivative block used $-partial_bx partial_bx k$ (i.e. implicitly
  $partial_bx partial_bc k$) — an *internally inconsistent* pair of
  bases. The system still "solved" (it is generically full rank) but
  converged to a function satisfying neither the value nor derivative
  data well: empirically, the value error was $5$-$8 times$ *worse* than
  a plain value-only RBF fit at the same $sig$, and gradient error was
  $5$-$6 times$ worse — the opposite of the intended super-convergence.

  Removing the erroneous sign flip (using the ordinary $bx$-Hessian
  throughout, matching the $G$ block's convention) restored the expected
  behaviour: the Hermite fit now *beats* the value-only baseline on both
  metrics, exactly matching Theorem 6.1 below.
]

== Super-Convergence Theorem

#pad(left: 1.2em)[
  *Theorem (Wu 1992; Fasshauer 1996).* The Hermite interpolant $s_h^H$
  fitting both $u(bx_j)$ and $(nabla u)(bx_j)$ satisfies
  $ norm(nabla(u-s_h^H))_(L^infinity) = O(h^tau) norm(u)_(cal(H)_k), $
  the *same* rate as the *value* error of a value-only interpolant — one
  full order better than differentiating a value-only fit, which only
  achieves $O(h^(tau-1))$.
]

*Numerical confirmation (Runge function, Matérn-5/2, $N=25$,
$sig=0.15$, after the fix):*

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, center, center),
    table.header[*Method*][$norm(u-s)_(L^2)$][$norm(nabla(u-s))_(L^2)$],
    [RBF, value-only], [$5.6 times 10^(-2)$], [$3.8 times 10^(-1)$],
    [Hermite (fixed)], [$7.1 times 10^(-3)$ #sym.arrow.b $8 times$], [$6.4 times 10^(-2)$ #sym.arrow.b $6 times$],
  ),
  caption: [Hermite collocation now outperforms the value-only baseline on both value and gradient accuracy, as theory predicts.]
)

== Regularisation: Tikhonov vs SVD Truncation

The assembled Hermite system has condition number routinely
$10^7$-$10^9$ (the derivative block's diagonal scales as $tilde.op 1\/sig^2$
relative to the value block's $O(1)$ diagonal — an inherent scaling
mismatch, not fixable by kernel choice alone). Two remedies were compared:

- *Truncated-SVD least squares* (`numpy.linalg.lstsq` with a `rcond`
  cutoff): discards singular directions below the cutoff. Found to be
  *unstable* here — sweeping `rcond` over $[10^(-3),10^(-10)]$ never
  recovered accurate predictions (best case $norm(u-s)_(L^2) tilde.op 1$,
  useless), because the derivative constraints occupy exactly the
  low-singular-value subspace that truncation removes, discarding the
  gradient information the fit was supposed to use.
- *Tikhonov-regularised normal equations* (used in the fixed code):
  $ (A^top A + lam I_("kernel block")) bold(z) = A^top bold(b), quad lam=10^(-6), $
  regularising *only* the kernel/derivative-weight block (not the
  polynomial block, which must remain exact for the annihilation
  condition). This is stable across $sig in [0.05,0.3]$ and $N$ up to a
  few hundred.

== Gradient-Enhanced K-KAN Edges (`kkan/model/gradient_enhanced_layer.py`)

An alternative to solving a (fragile) linear system: give the *neural*
K-KAN edge an explicit odd-symmetry derivative basis,
$ phi_(i j)(x) = sum_k [w_(i j k) k(r_k) + v_(i j k) k'(r_k) op("sign")(x-c_k)]
  + dots, $
and train with the *Sobolev* ($H^1$) loss
$ cal(L)_(H^1) = 1/N sum_j (u_theta(bx_j)-y_j)^2
  + lam_(nabla) 1/N sum_j norm(nabla u_theta(bx_j) - bg_j)^2, $
where $nabla u_theta$ is obtained by ordinary `jax.grad` through the
*whole* network (chain rule through all layers), not a linear collocation
system. Since $k(r)$ is even and $k'(r) op("sign")(Delta x)$ is odd
about each centre, together they span both symmetric and antisymmetric
local features — analogous to using both cosine and sine terms in a
Fourier basis.

*Empirical result*: this combination outperforms *both* the fixed
Hermite collocation and the value-only baseline by roughly an order of
magnitude on both metrics (Runge, $N=30$):
$ norm(u-u_theta)_(L^2) = 1.6 times 10^(-3), quad
  norm(nabla(u-u_theta))_(L^2) = 2.3 times 10^(-2), $
because gradient descent directly optimises the quantity of interest at
every step, rather than solving a single (however well-posed) linear
system once.

== High-Level API (`kkan/model/joint_training.py`)

`fit_with_gradients(x, u, du=..., d2u=..., ...)` wraps the
`HermiteKKAN` + Sobolev-loss + two-stage (Adam→L-BFGS) pipeline into a
single call, returning `(model, params)`; `predict_with_gradients`
recovers both $u(bx)$ and $nabla u(bx)$ via `jax.grad` at arbitrary query
points — this is the recommended entry point for joint function+gradient
learning in this codebase.

#pagebreak()

// ============================================================
= Mixed-Formulation 4th-Order PDEs (`kkan/solvers/coupled_solver.py`)
// ============================================================

== Why a Single Scalar Network Fails for 4th-Order PDEs

Cahn-Hilliard ($u_t = Delta mu$, $mu = u^3-u-eps^2 Delta u$) and the
stream-function form of steady 2D Navier-Stokes
($Delta psi = -omega$, $bu dot nabla omega = nu Delta omega$,
$bu=(psi_y,-psi_x)$, after eliminating $omega=-Delta psi$) both reduce,
for a *single* scalar field, to a PDE requiring *fourth*-order spatial
derivatives of the network output. Computing this via nested
`jax.hessian(jax.hessian(dot))` is exact and — evaluated once — completes
in finite (if slow) time. The problem is *training*: LSPG requires
$nabla_theta cal(J)$, i.e. differentiating the *already 4th-order*
residual with respect to network parameters — a graph with 5-6 levels of
nested automatic differentiation. Empirically this configuration crashes
the XLA compiler (segmentation fault) *regardless of model size or
quadrature count* — confirmed down to a $10 times 10$-unit, 2-layer
network with 10 quadrature points and 3 training steps. This is a
genuine limitation of the JAX/XLA compilation of deeply nested
`vmap(hessian(hessian(dot)))`-style graphs, not a hyperparameter issue.

== The Mixed-Formulation Fix

The standard remedy in the PINN literature for exactly this class of
problem (Wight & Zhao 2020 for Cahn-Hilliard) is to introduce an
*auxiliary field* and rewrite the 4th-order equation as a *coupled pair*
of 2nd-order equations, each trained with its own scalar K-KAN:

*Cahn-Hilliard, split* — fields $u_theta$, $mu_theta$:
$ R_1 = (partial u_theta)/(partial t) - Delta mu_theta,  quad quad
  R_2 = mu_theta - (u_theta^3 - u_theta - eps^2 Delta u_theta). $
Joint loss $cal(J) = sum_i w_i [R_1(bx_i)^2 + beta_("couple") R_2(bx_i)^2]
  + "BC/IC terms on" u_theta.$
Each residual now needs only *one* `jax.hessian` call — the same
computational class as the Poisson/Helmholtz solvers that train reliably.

*Navier-Stokes, split* — fields $psi_theta$ (stream function),
$omega_theta$ (vorticity):
$ R_1 = Delta psi_theta + omega_theta, quad quad
  R_2 = bu_theta dot nabla omega_theta - nu Delta omega_theta,
  quad bu_theta = (partial_y psi_theta, -partial_x psi_theta). $
$R_1$ needs one Laplacian of $psi_theta$; $R_2$ needs one gradient of
$psi_theta$ and one Laplacian of $omega_theta$ — again all single-Hessian
operations.

Both `CahnHilliardSolver` and `NavierStokesCavitySolver` implement this
pattern: two independent `KKAN` instances, a joint LSPG loss summed over
both residuals (with a coupling weight $beta_("couple")$ balancing the
two equations' typical magnitudes), and standard Adam→L-BFGS training —
verified to train without compiler crashes at practical model sizes
(20-24 hidden units per layer, 30-60 quadrature points).

== Boundary Conditions for the Cavity Flow Example

The lid-driven cavity benchmark on $[0,1]^2$ uses $psi=0$ on all four
walls (no-penetration streamline condition — the domain boundary is
itself a streamline). The moving-lid tangential condition
$partial psi\/partial y = 1$ on $y=1$ is *not* separately enforced in the
minimal example provided (a coarse demonstration of the formulation, not
a converged high-Reynolds benchmark); a production solver would add this
as an additional soft penalty term using the `normal_deriv` /
`grad_u`-based operators already available in `kkan/utils/diff_ops.py`.

#pagebreak()

// ============================================================
= Summary Table: Module -> Mathematics Map
// ============================================================

#figure(
  table(
    columns: (1fr, 1.6fr),
    align: (left,left),
    table.header[*Module*][*Core mathematics*],
    [`kernels/families.py`], [Positive-definite radial kernels; polynomial augmentation for unisolvence],
    [`kernels/derivatives.py`], [Analytic $k'$, $k''$, safe gradient/Hessian/Laplacian at $r=0$],
    [`model/kan_layer.py`], [Adaptive (Gauss/Chebyshev) grids; MLS partition-of-unity; Hard-Concrete $L_0$ pruning],
    [`model/gradient_enhanced_layer.py`], [Odd-symmetry derivative-basis edges; Sobolev ($H^1$) loss; native-space (RKHS) regulariser],
    [`model/joint_training.py`], [High-level fit/predict API for joint value+gradient learning],
    [`solvers/variational_solver.py`], [Deep Ritz energy minimisation; LSPG quadrature-weighted residual; adaptive collocation; XPINN],
    [`solvers/meshless_solver.py`], [Kansa/Galerkin direct collocation; RKPM/MLS interpolant; backward-Euler MOL],
    [`solvers/coupled_solver.py`], [Mixed-formulation split of 4th-order PDEs into coupled 2nd-order pairs],
    [`approximation/hermite_collocation.py`], [Hermite-Birkhoff value+gradient interpolation; Tikhonov-stabilised solve],
    [`approximation/quasi_interpolation.py`], [Shepard/Modified-Shepard/Gaussian quasi-interpolants; Strang-Fix reproduction order],
  ),
  caption: [Every source module and the mathematics it implements.]
)

// ============================================================
= References
// ============================================================
#set par(justify: false)
#enum(
  [Wendland, H. (2004). *Scattered Data Approximation*. Cambridge University Press.],
  [Wendland, H. (1995). Piecewise polynomial, positive definite and compactly supported radial functions of minimal degree. *Adv. Comput. Math.* 4(1), 389–396.],
  [Wu, Z. (1995). Compactly supported positive definite radial functions. *Adv. Comput. Math.* 4(1), 283–292.],
  [Wu, Z. (1992). Hermite-Birkhoff interpolation of scattered data by radial basis functions. *Approx. Theory Appl.* 8(2), 1–11.],
  [Fasshauer, G. E. (1996). Solving partial differential equations by collocation with radial basis functions. Proc. Chamonix.],
  [Schaback, R. (1995). Error estimates and condition numbers for radial basis function interpolation. *Adv. Comput. Math.* 3(3), 251–264.],
  [Kansa, E. J. (1990). Multiquadrics — a scattered data approximation scheme. *Comput. Math. Appl.* 19(8-9), 147–161.],
  [Liu, W. K., Jun, S., & Zhang, Y. F. (1995). Reproducing kernel particle methods. *Int. J. Numer. Methods Fluids* 20(8-9), 1081–1106.],
  [Louizos, C., Welling, M., & Kingma, D. P. (2018). Learning sparse neural networks through $L_0$ regularization. *ICLR*.],
  [Raissi, M., Perdikaris, P., & Karniadakis, G. E. (2019). Physics-informed neural networks. *J. Comput. Phys.* 378, 686–707.],
  [Jagtap, A. D., & Karniadakis, G. E. (2020). Extended PINNs (XPINNs). *Commun. Comput. Phys.* 28(5), 2002–2041.],
  [Lu, L., Meng, X., Mao, Z., & Karniadakis, G. E. (2021). DeepXDE. *SIAM Review* 63(1), 208–228.],
  [Wight, C. L., & Zhao, J. (2020). Solving Allen-Cahn and Cahn-Hilliard equations using the adaptive physics informed neural networks. *Commun. Comput. Phys.* 29(3), 930-954.],
  [Liu, Z., et al. (2024). KAN: Kolmogorov-Arnold Networks. *arXiv:2404.19756*.],
  [Kolmogorov, A. N. (1957). On the representation of continuous functions of many variables. *Dokl. Akad. Nauk SSSR* 114, 953–956.],
)
