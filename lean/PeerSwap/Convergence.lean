import PeerSwap.PermutationKernel
import PeerSwap.Poisson
import PeerSwap.Sampling

/-!
# Convergence of ideal, atomic PeerSwap

The state is a permutation from fixed graph vertices to peer identifiers.
Uniformization chooses uniformly among the edge transpositions and one identity
move, at rate `α * (|E| + 1)`. Each genuine edge therefore rings at rate `α`.
The identity events do not change the state. Negative times are clamped to zero;
all limit statements concern `t → +∞`.
-/

open scoped BigOperators
open Filter Topology

namespace PeerSwap

variable {V : Type*} [Fintype V] [DecidableEq V]

/-- Uniform probability on placements of all peer labels. -/
noncomputable def uniformPlacement (_σ : Equiv.Perm V) : ℝ :=
  1 / (Fintype.card (Equiv.Perm V) : ℝ)

theorem uniformPlacement_sum : ∑ σ : Equiv.Perm V, uniformPlacement σ = 1 :=
  Sampling.uniform_sum

theorem uniformPlacement_stationary (G : SimpleGraph V) :
    FiniteMixing.step (lazyKernel G) uniformPlacement = uniformPlacement := by
  funext τ
  simp only [FiniteMixing.step, uniformPlacement, ← Finset.mul_sum,
    lazyKernel_column, mul_one]

/-- The lazy edge-swap chain converges from every initial probability law. -/
theorem discrete_converges (G : SimpleGraph V) (hG : G.Connected)
    (μ : Equiv.Perm V → ℝ) (hmass : ∑ σ, μ σ = 1) :
    ∀ σ, Tendsto (fun n => FiniteMixing.evolve (lazyKernel G) μ n σ)
      atTop (𝓝 (uniformPlacement σ)) := by
  obtain ⟨L, hL, hpos⟩ := lazyKernel_positive_power G hG
  apply FiniteMixing.converges_of_positive_power (lazyKernel G) μ uniformPlacement
    L hL (lazyKernel_row G) (lazyKernel_nonneg G) hpos
  · rw [hmass, uniformPlacement_sum]
  · exact uniformPlacement_stationary G

/-- Continuous-time placement law, with each edge's clock having rate `α`. -/
noncomputable def placementLaw (G : SimpleGraph V) (α : ℝ)
    (μ : Equiv.Perm V → ℝ) (t : ℝ) (σ : Equiv.Perm V) : ℝ :=
  poissonAverage (Real.toNNReal (α * (lazyMoves G).card * t))
    (fun n => FiniteMixing.evolve (lazyKernel G) μ n σ)

/-- The continuous-time law starts from the prescribed initial distribution. -/
theorem placementLaw_zero (G : SimpleGraph V) (α : ℝ)
    (μ : Equiv.Perm V → ℝ) : placementLaw G α μ 0 = μ := by
  funext σ
  simp only [placementLaw, mul_zero, Real.toNNReal_zero, poissonAverage_zero,
    FiniteMixing.evolve]

/-- Multiplying the edge rate by `α` is exactly the time change `t ↦ α*t`. -/
theorem placementLaw_rate_scaling (G : SimpleGraph V) (α : ℝ)
    (μ : Equiv.Perm V → ℝ) (t : ℝ) :
    placementLaw G α μ t = placementLaw G 1 μ (α * t) := by
  have h : α * (lazyMoves G).card * t = 1 * (lazyMoves G).card * (α * t) := by ring
  unfold placementLaw
  rw [h]

theorem placementLaw_nonneg (G : SimpleGraph V) (α : ℝ)
    (μ : Equiv.Perm V → ℝ) (hμ : ∀ σ, 0 ≤ μ σ) (t : ℝ) (σ : Equiv.Perm V) :
    0 ≤ placementLaw G α μ t σ :=
  poissonAverage_nonneg
    (fun n => FiniteMixing.evolve_nonneg _ _ (lazyKernel_nonneg G) hμ n σ) _

theorem placementLaw_sum (G : SimpleGraph V) (α : ℝ)
    (μ : Equiv.Perm V → ℝ) (hμ : ∀ σ, 0 ≤ μ σ)
    (hmass : ∑ σ, μ σ = 1) (t : ℝ) : ∑ σ, placementLaw G α μ t σ = 1 := by
  apply poissonLaw_sum
    (fun n => FiniteMixing.evolve_nonneg _ _ (lazyKernel_nonneg G) hμ n)
  intro n
  rw [FiniteMixing.sum_evolve _ _ (lazyKernel_row G), hmass]

/-- Full continuous-time convergence, for every finite connected graph and
every strictly positive edge-clock rate. -/
theorem placementLaw_converges (G : SimpleGraph V) (hG : G.Connected)
    (α : ℝ) (hα : 0 < α) (μ : Equiv.Perm V → ℝ)
    (hμ : ∀ σ, 0 ≤ μ σ) (hmass : ∑ σ, μ σ = 1) (σ : Equiv.Perm V) :
    Tendsto (fun t => placementLaw G α μ t σ) atTop (𝓝 (uniformPlacement σ)) := by
  have hbound : ∀ n, |FiniteMixing.evolve (lazyKernel G) μ n σ| ≤ 1 := by
    intro n
    rw [abs_of_nonneg (FiniteMixing.evolve_nonneg _ _ (lazyKernel_nonneg G) hμ n σ)]
    exact finite_probability_le_one
      (FiniteMixing.evolve_nonneg _ _ (lazyKernel_nonneg G) hμ n)
      (by rw [FiniteMixing.sum_evolve _ _ (lazyKernel_row G), hmass]) σ
  apply poisson_average_rate_tendsto hbound (discrete_converges G hG μ hmass σ)
  exact mul_pos hα (by exact_mod_cast Finset.card_pos.mpr (lazyMoves_nonempty G))

/-- In particular, placements converge in total variation. -/
theorem placementLaw_totalVariation (G : SimpleGraph V) (hG : G.Connected)
    (α : ℝ) (hα : 0 < α) (μ : Equiv.Perm V → ℝ)
    (hμ : ∀ σ, 0 ≤ μ σ) (hmass : ∑ σ, μ σ = 1) :
    Tendsto (fun t => (∑ σ, |placementLaw G α μ t σ - uniformPlacement σ|) / 2)
      atTop (𝓝 0) :=
  Sampling.totalVariation_tendsto _ _ _ (placementLaw_converges G hG α hα μ hμ hmass)

/-- Deterministic ordered vertex slots already give uniform samples in the limit. -/
theorem orderedSample_converges {J : Type*} [Fintype J]
    (G : SimpleGraph V) (hG : G.Connected) (α : ℝ) (hα : 0 < α)
    (μ : Equiv.Perm V → ℝ) (hμ : ∀ σ, 0 ≤ μ σ) (hmass : ∑ σ, μ σ = 1)
    (i : V) (slots : V → (J ↪ V)) (hne : ∀ v j, slots v j ≠ v)
    (a : Sampling.Sample (J := J) i) :
    Tendsto (fun t => Sampling.push (Sampling.read i slots hne) (placementLaw G α μ t) a)
      atTop (𝓝 (1 / (Fintype.card (Sampling.Sample (J := J) i) : ℝ))) := by
  classical
  have h := Sampling.push_tendsto (Sampling.read i slots hne) (placementLaw G α μ)
    uniformPlacement atTop (placementLaw_converges G hG α hα μ hμ hmass) a
  rwa [show Sampling.push (Sampling.read i slots hne) uniformPlacement a =
    1 / (Fintype.card (Sampling.Sample (J := J) i) : ℝ) from
    Sampling.uniform_read i slots hne a] at h

/-- A finite random choice of ordered slots, independent of the placement. -/
noncomputable def sampleLaw {J R : Type*} [Fintype J] [Fintype R]
    (G : SimpleGraph V) (α : ℝ) (μ : Equiv.Perm V → ℝ)
    (i : V) (w : R → ℝ) (slots : R → V → (J ↪ V))
    (hne : ∀ r v j, slots r v j ≠ v) (t : ℝ) (a : Sampling.Sample (J := J) i) : ℝ := by
  classical
  exact ∑ r, w r * Sampling.push (Sampling.read i (slots r) (hne r))
    (placementLaw G α μ t) a

/-- Randomly choosing slots preserves uniform convergence, including uniform
sampling without replacement from the querying peer's neighbors. -/
theorem sampleLaw_converges {J R : Type*} [Fintype J] [Fintype R]
    (G : SimpleGraph V) (hG : G.Connected) (α : ℝ) (hα : 0 < α)
    (μ : Equiv.Perm V → ℝ) (hμ : ∀ σ, 0 ≤ μ σ) (hmass : ∑ σ, μ σ = 1)
    (i : V) (w : R → ℝ) (hw : ∑ r, w r = 1) (slots : R → V → (J ↪ V))
    (hne : ∀ r v j, slots r v j ≠ v) (a : Sampling.Sample (J := J) i) :
    Tendsto (fun t => sampleLaw G α μ i w slots hne t a) atTop
      (𝓝 (1 / (Fintype.card (Sampling.Sample (J := J) i) : ℝ))) := by
  classical
  have h := tendsto_finset_sum Finset.univ (fun r _ =>
    (orderedSample_converges G hG α hα μ hμ hmass i (slots r) (hne r) a).const_mul (w r))
  simpa only [sampleLaw, ← Finset.sum_mul, hw, one_mul] using h

/-- The complete peer-sampling law converges in total variation. -/
theorem sampleLaw_totalVariation {J R : Type*} [Fintype J] [Fintype R]
    (G : SimpleGraph V) (hG : G.Connected) (α : ℝ) (hα : 0 < α)
    (μ : Equiv.Perm V → ℝ) (hμ : ∀ σ, 0 ≤ μ σ) (hmass : ∑ σ, μ σ = 1)
    (i : V) (w : R → ℝ) (hw : ∑ r, w r = 1) (slots : R → V → (J ↪ V))
    (hne : ∀ r v j, slots r v j ≠ v) :
    Tendsto (fun t => (∑ a, |sampleLaw G α μ i w slots hne t a -
      1 / (Fintype.card (Sampling.Sample (J := J) i) : ℝ)|) / 2) atTop (𝓝 0) := by
  classical
  exact Sampling.totalVariation_tendsto _ _ _
    (sampleLaw_converges G hG α hα μ hμ hmass i w hw slots hne)

end PeerSwap
