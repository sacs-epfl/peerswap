# Lean formalization of PeerSwap convergence

This project proves qualitative convergence of the idealized, atomic PeerSwap
process on every finite connected simple undirected graph. It includes the
one-vertex case. The proofs use Lean 4.24.0 and a pinned mathlib revision; they
contain no `sorry`, `admit`, or user-declared axioms.

The main result is `PeerSwap.peerswap_converges` in `PeerSwap/Theorem.lean`.
Starting from the identity placement, for every peer, every edge-clock rate
`α > 0`, and every sample size `b` with `b ≤ degree(v)` at every vertex,
ordered neighbor samples converge in total variation to the uniform law on
`b` distinct other peers as real time tends to infinity.
`PeerSwap.peerswap_sample_probability` gives each ordered sample's limiting
probability as `1 / (n - 1).descFactorial b`.

The more general `PeerSwap.neighborSampleLaw_totalVariation` allows any initial
probability law, and `PeerSwap.placementLaw_totalVariation` gives convergence
of the full placement.

The state is a permutation `σ : Equiv.Perm V` mapping original graph positions
to current peer labels. An edge swap replaces `σ` by `σ * Equiv.swap u v`.
The observed network is the relabeled graph `relabel G σ`.

## Build

With [elan](https://github.com/leanprover/elan) installed and `lake` on `PATH`,
run from this directory:

```sh
lake update
lake exe cache get
lake build
```

`lean-toolchain`, `lakefile.toml`, and `lake-manifest.json` pin the Lean compiler
and dependency revisions. The cache command downloads precompiled mathlib
artifacts; Lean still checks the project proofs during the build. The library
entry point `PeerSwap.lean` prints the axioms used by the main theorems.

To inspect the main theorem independently after building:

```sh
lake env lean PeerSwap.lean
```

## The proof

- `PeerSwap/Graph.lean` defines atomic graph swaps, proves that relabeling
  preserves graph isomorphism, and proves that edge transpositions of a finite
  connected graph generate every permutation. The theorem
  `exists_edgeSwap_word` provides an explicit finite-word reachability statement.
- `PeerSwap/PermutationKernel.lean` constructs a discrete transition kernel by
  choosing uniformly from the identity and all distinct edge transpositions.
  It proves nonnegativity, row and column sums equal to one, positive holding
  probabilities, and positivity of a fixed power on connected graphs.
- `PeerSwap/FiniteMixing.lean` proves a finite-state Doeblin contraction theorem
  directly. A common lower bound `ε > 0` on all entries gives contraction
  factor `1 - card(S) * ε` in the sum of absolute differences. Positivity of
  one power suffices for convergence at every discrete step, including the
  steps between block endpoints.
- `PeerSwap/Poisson.lean` defines the continuous-time law as the Poisson mixture
  of the discrete laws. It proves mass preservation, nonnegativity, and that
  Poisson averaging preserves the limit of any bounded sequence. Its
  `poisson_average_rate_tendsto` theorem handles all real times tending to
  infinity and every strictly positive rate. `poissonAverage_zero` proves that
  the initial law is preserved exactly at time zero.
- `PeerSwap/Sampling.lean` reads distinct ordered peer labels from slots other
  than the querying peer's position. Uniform placements give exactly the
  uniform distribution on ordered samples excluding the query. Finite
  observations preserve convergence, and pointwise convergence of finite
  probability vectors implies convergence in total variation.
- `PeerSwap/Convergence.lean` assembles these results for PeerSwap, including
  arbitrary finite random mixtures of ordered slot choices.
- `PeerSwap/UniformProduct.lean` proves that a uniform finite dependent product
  has uniform coordinate marginals. `PeerSwap/NeighborSampling.lean` applies
  this to all ordered neighbor-slot systems, defines the actual randomized
  neighbor sampler, and proves its pointwise and total variation convergence
  under the degree condition.
- `PeerSwap/SampleLawProperties.lean` verifies nonnegativity and total mass one
  for the randomized sample law. `PeerSwap/Generator.lean` proves that the
  uniformization matrix `α * M * (K - I)` has rate `α` for each edge swap,
  zero for other off-diagonal transitions, and the correct diagonal rate.
- `PeerSwap/NeighborSampleLawProperties.lean` specializes probability-law
  validation to the neighbor sampler. `PeerSwap/Theorem.lean` starts from the
  identity placement and states the main theorem `peerswap_converges`.

The uniform limiting law on full placements is `1 / card(Equiv.Perm V)`.
For an ordered sample of size `b`, the limiting law is
`1 / card(Fin b ↪ {v : V // v ≠ i})`, equivalently
`(n - b - 1)! / (n - 1)!` when `b ≤ n - 1`.

No regularity assumption is needed for convergence. A common sample size `b`
requires a choice of `b` distinct neighbors at every vertex; in particular,
`b ≤ minimum degree` suffices. The sample excludes its querying peer.

## Continuous-time model and clock rates

Let `M` be the number of moves: one identity move and one move for each
undirected edge. Poissonization uses mean `α * M * t`. Each genuine edge is
therefore selected at rate `α`; the additional identity events do not change
the state. This is the uniformization model of the paper's independent
rate-`α` edge clocks. The Lean development defines the transition laws through
this Poisson mixture. It does not construct independent clock sample paths or
formally prove a coupling to the distributed implementation.

The rate appears multiplied by elapsed time inside the Poisson mean. Thus a
larger `α` speeds up the process, and a physical mixing time scales as `1/α`.
The holding move is essential to the discrete proof: the raw edge-swap jump
chain alternates permutation parity, whereas the continuous-time process
converges.

## Scope and correspondence to the manuscript

The result concerns the no-failure, instantaneous atomic-swap model used in the
paper's convergence analysis. It does not verify concurrent message handlers,
network delays, shared pseudorandom generators, or the delay adaptation. In
particular, the message pseudocode as printed needs special treatment of the
two swapping endpoints: simply storing the other endpoint's full neighbor list
can introduce the receiver's own identifier. The formal atomic semantics
exchanges vertex labels and all incident edges simultaneously.

The development proves convergence and an abstract geometric bound from a
positive finite block. It does not formalize the manuscript's polylogarithmic
mixing-time estimate or the external interchange-process mixing theorems used
to obtain that estimate.

The manuscript paths below refer to the companion `peerswap-paper` repository.
Three manuscript details are corrected in the formal model:

1. In `SRDS_submission/Sections/5_Mixing_time.tex`, the definition
   `T := α * T_Y(ε)` and the final bound's factor `α` have the rate scaling
   reversed. For rate-`α` clocks, use `T_Y(ε) / α` and put `α` in the
   denominator of the corresponding time bound. The mean inter-ring time is
   `1/α`, rather than `α`.
2. In the `MainBijection` lemma in
   `SRDS_submission/Sections/4_Convergence.tex`, the historical edge at ring
   `t_m` must be mapped using the permutation immediately before that ring,
   `σ_(t_(m-1))⁻¹`, rather than the final `σ_t⁻¹`.
3. The absolute spectral gap in
   `SRDS_submission/Sections/system_model.tex` vanishes for connected
   bipartite graphs, including hypercubes. A nontrivial continuous-time
   spectral estimate uses `1 - λ₂` instead. The qualitative Lean theorem
   assumes only connectedness and does not use a spectral gap.

The ordered-sample target also consistently excludes the querying peer; the
system-model paragraph's `Uniform((U)_b)` should read
`Uniform((U \\ {u_i})_b)`.
