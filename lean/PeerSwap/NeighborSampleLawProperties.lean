import PeerSwap.NeighborSampling
import PeerSwap.SampleLawProperties
import Mathlib.Data.Fintype.CardEmbedding

/-!
# Validation of the concrete neighbor-sampling law

The minimum-degree condition makes the finite space of neighbor-slot choices
nonempty. Its uniform weights therefore have mass one, and the resulting law
is a probability distribution at every time.
-/

open scoped BigOperators

namespace PeerSwap

variable {V : Type*} [Fintype V] [DecidableEq V]

/-- Every finite-time neighbor-sampling probability is nonnegative. -/
theorem neighborSampleLaw_nonneg (G : SimpleGraph V) [DecidableRel G.Adj] (α : ℝ)
    (μ : Equiv.Perm V → ℝ) (hμ : ∀ σ, 0 ≤ μ σ) (i : V) (b : ℕ)
    (t : ℝ) (a : Sampling.Sample (J := Fin b) i) :
    0 ≤ neighborSampleLaw G α μ i b t a := by
  classical
  unfold neighborSampleLaw
  exact sampleLaw_nonneg (J := Fin b) (R := SlotSystem G b) G α μ hμ i
    (fun _ : SlotSystem G b => (1 : ℝ) / Fintype.card (SlotSystem G b))
    (fun _ => by positivity) (neighborSlots G) (neighborSlots_ne G) t a

/-- The concrete service assigns total probability one to its possible samples. -/
theorem neighborSampleLaw_sum (G : SimpleGraph V) [DecidableRel G.Adj]
    (α : ℝ) (μ : Equiv.Perm V → ℝ) (hμ : ∀ σ, 0 ≤ μ σ)
    (hmass : ∑ σ, μ σ = 1) (i : V) (b : ℕ) (hb : ∀ v, b ≤ G.degree v)
    (t : ℝ) : ∑ a, neighborSampleLaw G α μ i b t a = 1 := by
  classical
  unfold neighborSampleLaw
  letI := slotSystem_nonempty G b hb
  have hw : (∑ _ : SlotSystem G b,
      (1 : ℝ) / Fintype.card (SlotSystem G b)) = 1 := Sampling.uniform_sum
  exact sampleLaw_sum (J := Fin b) (R := SlotSystem G b) G α μ hμ hmass i
    (fun _ : SlotSystem G b => (1 : ℝ) / Fintype.card (SlotSystem G b)) hw
    (neighborSlots G) (neighborSlots_ne G) t

/-- In particular, each probability of the concrete service belongs to `[0,1]`. -/
theorem neighborSampleLaw_mem_Icc (G : SimpleGraph V) [DecidableRel G.Adj]
    (α : ℝ) (μ : Equiv.Perm V → ℝ) (hμ : ∀ σ, 0 ≤ μ σ)
    (hmass : ∑ σ, μ σ = 1) (i : V) (b : ℕ) (hb : ∀ v, b ≤ G.degree v)
    (t : ℝ) (a : Sampling.Sample (J := Fin b) i) :
    neighborSampleLaw G α μ i b t a ∈ Set.Icc (0 : ℝ) 1 := by
  refine ⟨neighborSampleLaw_nonneg G α μ hμ i b t a, ?_⟩
  exact finite_probability_le_one (neighborSampleLaw_nonneg G α μ hμ i b t)
    (neighborSampleLaw_sum G α μ hμ hmass i b hb t) a

/-- Ordered samples without repetitions and without the query have the expected
falling-factorial cardinality. -/
theorem sample_card_descFactorial (i : V) (b : ℕ) :
    Fintype.card (Sampling.Sample (J := Fin b) i) =
      (Fintype.card V - 1).descFactorial b := by
  classical
  simp [Sampling.Sample]

end PeerSwap
