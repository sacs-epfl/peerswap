import PeerSwap.PermutationKernel

/-!
# The exact PeerSwap generator

Uniformization with event rate `α * M`, where `M` counts the edge moves and one
identity move, gives rate `α` to every edge transposition. The identity event
changes no state. The resulting generator is therefore exactly the continuous
time adjacent-transposition generator.
-/

open scoped BigOperators Classical

namespace PeerSwap

variable {V : Type*} [Fintype V] [DecidableEq V]

/-- The infinitesimal generator represented by the lazy uniformization. -/
noncomputable def uniformizedGenerator (G : SimpleGraph V) (α : ℝ)
    (σ τ : Equiv.Perm V) : ℝ := by
  classical
  exact α * (lazyMoves G).card *
    (lazyKernel G σ τ - if σ = τ then 1 else 0)

theorem lazyMoves_card_ne_zero (G : SimpleGraph V) :
    ((lazyMoves G).card : ℝ) ≠ 0 := by
  exact_mod_cast ne_of_gt (Finset.card_pos.mpr (lazyMoves_nonempty G))

/-- Uniformized event rate times an individual move's probability is exactly
the prescribed edge-clock rate. -/
theorem uniformized_move_rate (G : SimpleGraph V) (α : ℝ) (σ : Equiv.Perm V)
    {e : Equiv.Perm V} (he : e ∈ lazyMoves G) :
    (α * (lazyMoves G).card) * lazyKernel G σ (σ * e) = α := by
  rw [lazyKernel_move_eq G σ he]
  field_simp [lazyMoves_card_ne_zero G]

theorem uniformized_edge_rate (G : SimpleGraph V) (α : ℝ) (σ : Equiv.Perm V)
    {e : Equiv.Perm V} (he : e ∈ edgeSwaps G) :
    (α * (lazyMoves G).card) * lazyKernel G σ (σ * e) = α :=
  uniformized_move_rate G α σ ((mem_lazyMoves G e).2 (Or.inr he))

/-- Every off-diagonal rate is `α` for an allowed edge swap and zero otherwise. -/
theorem uniformizedGenerator_offdiag (G : SimpleGraph V) (α : ℝ)
    {σ τ : Equiv.Perm V} (hne : σ ≠ τ) :
    uniformizedGenerator G α σ τ =
      if σ⁻¹ * τ ∈ edgeSwaps G then α else 0 := by
  classical
  have hne' : σ⁻¹ * τ ≠ 1 := by
    intro h
    apply hne
    have : τ = σ := by
      calc
        τ = σ * (σ⁻¹ * τ) := by simp
        _ = σ := by rw [h, mul_one]
    exact this.symm
  unfold uniformizedGenerator
  rw [if_neg hne, sub_zero, lazyKernel_eq]
  simp only [mem_lazyMoves, hne', false_or]
  split_ifs
  · field_simp [lazyMoves_card_ne_zero G]
  · simp

/-- The diagonal rate is minus the total rate of all nonidentity moves. -/
theorem uniformizedGenerator_diag (G : SimpleGraph V) (α : ℝ)
    (σ : Equiv.Perm V) :
    uniformizedGenerator G α σ σ = -α * ((lazyMoves G).card - 1) := by
  classical
  have hk : lazyKernel G σ σ = (1 : ℝ) / (lazyMoves G).card := by
    simpa using lazyKernel_move_eq G σ ((mem_lazyMoves G 1).2 (Or.inl rfl))
  unfold uniformizedGenerator
  rw [if_pos rfl, hk]
  field_simp [lazyMoves_card_ne_zero G]
  ring

theorem uniformizedGenerator_row_sum (G : SimpleGraph V) (α : ℝ)
    (σ : Equiv.Perm V) : ∑ τ, uniformizedGenerator G α σ τ = 0 := by
  classical
  unfold uniformizedGenerator
  rw [← Finset.mul_sum, Finset.sum_sub_distrib, lazyKernel_row]
  simp

theorem uniformizedGenerator_symm (G : SimpleGraph V) (α : ℝ)
    (σ τ : Equiv.Perm V) :
    uniformizedGenerator G α σ τ = uniformizedGenerator G α τ σ := by
  classical
  unfold uniformizedGenerator
  rw [lazyKernel_symm G σ τ]
  simp only [eq_comm]

end PeerSwap
