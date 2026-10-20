import PeerSwap.Convergence

/-!
# Probability-law validation for randomized PeerSwap observations

The convergence theorem also holds for signed slot weights of mass one. For
actual randomized samplers, the additional nonnegativity assumption below
establishes that every finite-time observation is a probability distribution.
-/

open scoped BigOperators

namespace PeerSwap

variable {V : Type*} [Fintype V] [DecidableEq V]

lemma Sampling.push_nonneg {A B : Type*} [Fintype A] [DecidableEq B]
    (f : A → B) (μ : A → ℝ) (hμ : ∀ a, 0 ≤ μ a) (b : B) :
    0 ≤ Sampling.push f μ b := by
  unfold Sampling.push
  exact Finset.sum_nonneg fun a _ => by split_ifs <;> simp_all

/-- Nonnegative slot weights and an initial probability law give a nonnegative
sample law at every time. -/
theorem sampleLaw_nonneg {J R : Type*} [Fintype J] [Fintype R]
    (G : SimpleGraph V) (α : ℝ) (μ : Equiv.Perm V → ℝ)
    (hμ : ∀ σ, 0 ≤ μ σ) (i : V) (w : R → ℝ) (hw : ∀ r, 0 ≤ w r)
    (slots : R → V → (J ↪ V)) (hne : ∀ r v j, slots r v j ≠ v)
    (t : ℝ) (a : Sampling.Sample (J := J) i) :
    0 ≤ sampleLaw G α μ i w slots hne t a := by
  classical
  exact Finset.sum_nonneg fun r _ => mul_nonneg (hw r)
    (Sampling.push_nonneg _ _ (placementLaw_nonneg G α μ hμ t) a)

/-- Randomized observation preserves total probability mass. -/
theorem sampleLaw_sum {J R : Type*} [Fintype J] [Fintype R]
    (G : SimpleGraph V) (α : ℝ) (μ : Equiv.Perm V → ℝ)
    (hμ : ∀ σ, 0 ≤ μ σ) (hmass : ∑ σ, μ σ = 1)
    (i : V) (w : R → ℝ) (hw : ∑ r, w r = 1)
    (slots : R → V → (J ↪ V)) (hne : ∀ r v j, slots r v j ≠ v) (t : ℝ) :
    ∑ a, sampleLaw G α μ i w slots hne t a = 1 := by
  classical
  unfold sampleLaw
  rw [Finset.sum_comm]
  simp_rw [← Finset.mul_sum, Sampling.push_sum, placementLaw_sum G α μ hμ hmass t,
    mul_one]
  exact hw

/-- Each finite-time sample probability lies in the closed unit interval. -/
theorem sampleLaw_mem_Icc {J R : Type*} [Fintype J] [Fintype R]
    (G : SimpleGraph V) (α : ℝ) (μ : Equiv.Perm V → ℝ)
    (hμ : ∀ σ, 0 ≤ μ σ) (hmass : ∑ σ, μ σ = 1)
    (i : V) (w : R → ℝ) (hw : ∀ r, 0 ≤ w r) (hwsum : ∑ r, w r = 1)
    (slots : R → V → (J ↪ V)) (hne : ∀ r v j, slots r v j ≠ v)
    (t : ℝ) (a : Sampling.Sample (J := J) i) :
    sampleLaw G α μ i w slots hne t a ∈ Set.Icc (0 : ℝ) 1 := by
  refine ⟨sampleLaw_nonneg G α μ hμ i w hw slots hne t a, ?_⟩
  exact finite_probability_le_one
    (sampleLaw_nonneg G α μ hμ i w hw slots hne t)
    (sampleLaw_sum G α μ hμ hmass i w hwsum slots hne t) a

end PeerSwap
