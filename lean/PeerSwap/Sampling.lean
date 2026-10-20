import Mathlib.GroupTheory.Perm.Finite
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Logic.Equiv.Fintype
import Mathlib.Tactic

/-!
# Ordered samples from a random placement

A placement maps vertices to peer labels. `slots` chooses distinct vertices other
than the querying peer's position. Uniform placements give uniform ordered samples.
-/

open scoped BigOperators
open Filter Topology

namespace PeerSwap.Sampling

variable {V J : Type*} [Fintype V] [Fintype J] [DecidableEq V]

/-- Any two embeddings into a finite type differ by a permutation. -/
theorem exists_perm_between (f g : J ↪ V) :
    ∃ e : Equiv.Perm V, ∀ j, e (f j) = g j := by
  classical
  let e : Set.range f ≃ Set.range g :=
    (Equiv.ofInjective f f.injective).symm.trans (Equiv.ofInjective g g.injective)
  refine ⟨e.extendSubtype, fun j => ?_⟩
  rw [Equiv.extendSubtype_apply_of_mem e (f j) ⟨j, rfl⟩]
  change ((Equiv.ofInjective g g.injective)
    ((Equiv.ofInjective f f.injective).symm
      ((Equiv.ofInjective f f.injective) j))).val = g j
  simp

/-- Ordered samples without repetitions or the querying peer. -/
abbrev Sample (i : V) := J ↪ {v : V // v ≠ i}

/-- Read peer identifiers from an ordered selection of vertex positions. -/
def read (i : V) (slots : V → (J ↪ V))
    (hne : ∀ v j, slots v j ≠ v) (σ : Equiv.Perm V) : Sample (J := J) i where
  toFun j := ⟨σ (slots (σ.symm i) j), by
    intro h
    have := congrArg σ.symm h
    simp only [Equiv.symm_apply_apply] at this
    exact hne (σ.symm i) j this⟩
  inj' := by
    intro a b h
    exact (slots (σ.symm i)).injective (σ.injective (congrArg Subtype.val h))

noncomputable def fixQuery (i : V) (e : Equiv.Perm {v : V // v ≠ i}) : Equiv.Perm V :=
  e.extendDomain (Equiv.refl _)

omit [Fintype V] in
@[simp] theorem fixQuery_self (i : V) (e : Equiv.Perm {v : V // v ≠ i}) :
    fixQuery i e i = i := by
  classical
  exact Equiv.Perm.extendDomain_apply_not_subtype _ _ (by simp)

omit [Fintype V] in
@[simp] theorem fixQuery_other (i : V) (e : Equiv.Perm {v : V // v ≠ i})
    (v : {v : V // v ≠ i}) : fixQuery i e v = e v := by
  classical
  exact Equiv.Perm.extendDomain_apply_image _ _ v

omit [Fintype V] [Fintype J] in
/-- Relabeling peers other than the query relabels the observed sample. -/
theorem read_relabel (i : V) (slots : V → (J ↪ V))
    (hne : ∀ v j, slots v j ≠ v) (σ : Equiv.Perm V)
    (e : Equiv.Perm {v : V // v ≠ i}) :
    read i slots hne (σ.trans (fixQuery i e)) =
      (read i slots hne σ).trans e.toEmbedding := by
  classical
  apply Function.Embedding.ext
  intro j
  apply Subtype.ext
  change fixQuery i e (σ (slots (σ.symm ((fixQuery i e).symm i)) j)) =
    (e (read i slots hne σ j)).val
  have hfix : (fixQuery i e).symm i = i :=
    (fixQuery i e).symm_apply_eq.mpr (fixQuery_self i e).symm
  rw [hfix]
  exact fixQuery_other i e (read i slots hne σ j)

/-- Push a finite probability vector through an observation. -/
noncomputable def push {A B : Type*} [Fintype A] [DecidableEq B]
    (f : A → B) (μ : A → ℝ) (b : B) : ℝ :=
  ∑ a, if f a = b then μ a else 0

theorem uniform_sum {A : Type*} [Fintype A] [Nonempty A] :
    ∑ _ : A, (1 / (Fintype.card A : ℝ)) = 1 := by
  simp [Fintype.card_ne_zero]

/-- Uniform placements assign equal probability to every sample. -/
theorem uniform_read_equal (i : V) (slots : V → (J ↪ V))
    (hne : ∀ v j, slots v j ≠ v) (a b : Sample (J := J) i) :
    push (read i slots hne) (fun _ => 1 / (Fintype.card (Equiv.Perm V) : ℝ)) a =
    push (read i slots hne) (fun _ => 1 / (Fintype.card (Equiv.Perm V) : ℝ)) b := by
  classical
  obtain ⟨e, he⟩ := exists_perm_between a b
  let T : Equiv.Perm (Equiv.Perm V) :=
    { toFun := fun σ => σ.trans (fixQuery i e)
      invFun := fun σ => σ.trans (fixQuery i e).symm
      left_inv := by intro σ; ext v; simp
      right_inv := by intro σ; ext v; simp }
  unfold push
  symm
  rw [← Equiv.sum_comp T]
  apply Finset.sum_congr rfl
  intro σ _
  have hab : read i slots hne (T σ) = b ↔ read i slots hne σ = a := by
    rw [show T σ = σ.trans (fixQuery i e) from rfl, read_relabel]
    constructor
    · intro h
      apply Function.Embedding.ext
      intro j
      apply e.injective
      exact (congrArg (fun f : Sample (J := J) i => f j) h).trans (he j).symm
    · intro h
      rw [h]
      apply Function.Embedding.ext
      intro j
      exact he j
  simp only [hab]

theorem push_sum {A B : Type*} [Fintype A] [Fintype B] [DecidableEq B]
    (f : A → B) (μ : A → ℝ) : ∑ b, push f μ b = ∑ a, μ a := by
  classical
  unfold push
  rw [Finset.sum_comm]
  simp

/-- Uniform placements yield uniform ordered samples excluding self. -/
theorem uniform_read (i : V) (slots : V → (J ↪ V))
    (hne : ∀ v j, slots v j ≠ v) (a : Sample (J := J) i) :
    push (read i slots hne) (fun _ => 1 / (Fintype.card (Equiv.Perm V) : ℝ)) a =
      1 / (Fintype.card (Sample (J := J) i) : ℝ) := by
  classical
  have hsum := push_sum (read i slots hne)
    (fun _ => 1 / (Fintype.card (Equiv.Perm V) : ℝ))
  rw [uniform_sum] at hsum
  have heq : (∑ b : Sample (J := J) i,
      push (read i slots hne) (fun _ => 1 / (Fintype.card (Equiv.Perm V) : ℝ)) b) =
      (Fintype.card (Sample (J := J) i) : ℝ) *
      push (read i slots hne) (fun _ => 1 / (Fintype.card (Equiv.Perm V) : ℝ)) a := by
    calc
      _ = ∑ _ : Sample (J := J) i,
          push (read i slots hne) (fun _ => 1 / (Fintype.card (Equiv.Perm V) : ℝ)) a :=
        Finset.sum_congr rfl (fun b _ => uniform_read_equal i slots hne b a)
      _ = _ := by simp
  rw [heq] at hsum
  have hc : (Fintype.card (Sample (J := J) i) : ℝ) ≠ 0 := by
    intro h; rw [h, zero_mul] at hsum; norm_num at hsum
  apply (eq_div_iff hc).2
  nlinarith [hsum]

/-- Convergence transfers to any finite observation. -/
theorem push_tendsto {A B T : Type*} [Fintype A] [DecidableEq B]
    (f : A → B) (μ : T → A → ℝ) (π : A → ℝ) (l : Filter T)
    (h : ∀ a, Tendsto (fun t => μ t a) l (𝓝 (π a))) (b : B) :
    Tendsto (fun t => push f (μ t) b) l (𝓝 (push f π b)) := by
  classical
  unfold push
  apply tendsto_finset_sum
  intro a _
  by_cases ha : f a = b
  · simpa [ha] using h a
  · simp only [ha, ↓reduceIte]; exact tendsto_const_nhds

/-- On a finite state space pointwise convergence implies total variation convergence. -/
theorem totalVariation_tendsto {A T : Type*} [Fintype A]
    (μ : T → A → ℝ) (π : A → ℝ) (l : Filter T)
    (h : ∀ a, Tendsto (fun t => μ t a) l (𝓝 (π a))) :
    Tendsto (fun t => (∑ a, |μ t a - π a|) / 2) l (𝓝 0) := by
  have hs : Tendsto (fun t => ∑ a, |μ t a - π a|) l (𝓝 (∑ _ : A, (0 : ℝ))) := by
    apply tendsto_finset_sum
    intro a _
    simpa using ((h a).sub (tendsto_const_nhds (x := π a))).abs
  simpa using hs.div_const 2

end PeerSwap.Sampling
