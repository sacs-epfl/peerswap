import Mathlib.Data.Fintype.BigOperators
import Mathlib.Logic.Equiv.Prod
import Mathlib.Tactic

/-!
# Uniform marginal of a finite product

A uniformly chosen system of ordered neighbor slots is uniform at every fixed
vertex. This holds for dependent products, including irregular graphs whose
vertices have different numbers of admissible local slot choices.
-/

open scoped BigOperators

namespace PeerSwap

/-- The marginal of the uniform law on a finite dependent product is uniform
on each factor. -/
theorem uniform_product_coordinate {V : Type*} [Fintype V] [DecidableEq V]
    {A : V → Type*} [∀ v, Fintype (A v)] [∀ v, DecidableEq (A v)]
    [∀ v, Nonempty (A v)]
    (i : V) (a : A i) :
    (∑ r : ∀ v, A v,
      if r i = a then (1 : ℝ) / Fintype.card (∀ v, A v) else 0) =
      1 / (Fintype.card (A i) : ℝ) := by
  classical
  let E := Equiv.piSplitAt i A
  have hc : Fintype.card (∀ v, A v) =
      Fintype.card (A i) * Fintype.card (∀ v : {v : V // v ≠ i}, A v) := by
    exact (Fintype.card_congr E).trans (Fintype.card_prod _ _)
  have hprod : (∏ j : {v : V // v ≠ i}, (Fintype.card (A j) : ℝ)) ≠ 0 := by
    apply Finset.prod_ne_zero_iff.mpr
    intro j _
    exact_mod_cast (Fintype.card_ne_zero : Fintype.card (A j) ≠ 0)
  rw [← Equiv.sum_comp E.symm, Fintype.sum_prod_type]
  simp [E, Equiv.piSplitAt, hc, hprod]

end PeerSwap
