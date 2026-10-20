import PeerSwap.NeighborSampleLawProperties
import PeerSwap.Generator

/-!
# PeerSwap convergence from the initial graph

`peerswap_converges` is the main result. Starting from the identity placement,
the distribution of ordered neighbor samples tends in total variation to the
uniform distribution on distinct peers other than the querying peer.
-/

open scoped BigOperators
open Filter Topology

namespace PeerSwap

variable {V : Type*} [Fintype V] [DecidableEq V]

/-- At time zero, each peer occupies its original vertex. -/
noncomputable def initialPlacement (σ : Equiv.Perm V) : ℝ := by
  classical
  exact if σ = 1 then 1 else 0

theorem initialPlacement_nonneg (σ : Equiv.Perm V) : 0 ≤ initialPlacement σ := by
  classical
  unfold initialPlacement
  split_ifs <;> norm_num

theorem initialPlacement_sum : ∑ σ : Equiv.Perm V, initialPlacement σ = 1 := by
  classical
  simp [initialPlacement]

/-- Convergence of ideal atomic PeerSwap, with rate-`α` clocks, from its given
initial graph. No regularity or spectral-gap hypothesis is required. -/
theorem peerswap_converges (G : SimpleGraph V) [DecidableRel G.Adj]
    (hG : G.Connected) (α : ℝ) (hα : 0 < α)
    (i : V) (b : ℕ) (hb : ∀ v, b ≤ G.degree v) :
    Tendsto
      (fun t : ℝ =>
        (∑ a : Sampling.Sample (J := Fin b) i,
          |neighborSampleLaw G α initialPlacement i b t a -
            1 / (Fintype.card (Sampling.Sample (J := Fin b) i) : ℝ)|) / 2)
      atTop (𝓝 0) :=
  neighborSampleLaw_totalVariation G hG α hα initialPlacement
    initialPlacement_nonneg initialPlacement_sum i b hb

/-- Every particular ordered sample has the claimed uniform limiting mass. -/
theorem peerswap_sample_probability (G : SimpleGraph V) [DecidableRel G.Adj]
    (hG : G.Connected) (α : ℝ) (hα : 0 < α)
    (i : V) (b : ℕ) (hb : ∀ v, b ≤ G.degree v)
    (a : Sampling.Sample (J := Fin b) i) :
    Tendsto (fun t : ℝ => neighborSampleLaw G α initialPlacement i b t a)
      atTop (𝓝 (1 / ((Fintype.card V - 1).descFactorial b : ℝ))) := by
  have h := neighborSampleLaw_converges G hG α hα initialPlacement
    initialPlacement_nonneg initialPlacement_sum i b hb a
  rwa [sample_card_descFactorial] at h

end PeerSwap
