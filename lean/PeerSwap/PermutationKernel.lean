import PeerSwap.Graph
import PeerSwap.FiniteMixing

/-!
# A lazy adjacent-transposition kernel

The finite move set consists of the identity and all edge transpositions. Its
uniform random walk is doubly stochastic. More generally, any nonnegative kernel
with positive holding probabilities and positive edge-transposition transitions
has a strictly positive power on a connected graph.
-/

open scoped BigOperators

namespace PeerSwap

variable {V : Type*} [Fintype V] [DecidableEq V]

/-- The identity move provides a holding probability, including for the
one-vertex graph. -/
noncomputable def lazyMoves (G : SimpleGraph V) : Finset (Equiv.Perm V) := by
  classical
  exact insert 1 (Finset.univ.filter fun σ => σ ∈ edgeSwaps G)

@[simp] theorem mem_lazyMoves (G : SimpleGraph V) (σ : Equiv.Perm V) :
    σ ∈ lazyMoves G ↔ σ = 1 ∨ σ ∈ edgeSwaps G := by
  classical
  simp [lazyMoves]

theorem lazyMoves_nonempty (G : SimpleGraph V) : (lazyMoves G).Nonempty :=
  ⟨1, (mem_lazyMoves G 1).2 (Or.inl rfl)⟩

theorem lazyMoves_inv (G : SimpleGraph V) {σ : Equiv.Perm V}
    (hσ : σ ∈ lazyMoves G) : σ⁻¹ = σ := by
  rcases (mem_lazyMoves G σ).1 hσ with rfl | hσ
  · simp
  · exact edgeSwap_inv G hσ

/-- Uniform choice among the edge swaps and one holding move. -/
noncomputable def lazyKernel (G : SimpleGraph V) (σ τ : Equiv.Perm V) : ℝ := by
  classical
  exact ∑ e ∈ lazyMoves G, if σ * e = τ then (1 : ℝ) / (lazyMoves G).card else 0

/-- Every edge exchange and the holding move has probability exactly `1 / M`;
all other one-step transitions have probability zero. -/
theorem lazyKernel_eq (G : SimpleGraph V) (σ τ : Equiv.Perm V) :
    lazyKernel G σ τ =
      if σ⁻¹ * τ ∈ lazyMoves G then (1 : ℝ) / (lazyMoves G).card else 0 := by
  classical
  unfold lazyKernel
  simp only [← eq_inv_mul_iff_mul_eq, Finset.sum_ite_eq']

theorem lazyKernel_move_eq (G : SimpleGraph V) (σ : Equiv.Perm V)
    {e : Equiv.Perm V} (he : e ∈ lazyMoves G) :
    lazyKernel G σ (σ * e) = (1 : ℝ) / (lazyMoves G).card := by
  rw [lazyKernel_eq]
  simp [he]

theorem lazyKernel_nonneg (G : SimpleGraph V) (σ τ : Equiv.Perm V) :
    0 ≤ lazyKernel G σ τ := by
  classical
  apply Finset.sum_nonneg
  intro e _
  split_ifs <;> positivity

theorem lazyKernel_row (G : SimpleGraph V) (σ : Equiv.Perm V) :
    ∑ τ, lazyKernel G σ τ = 1 := by
  classical
  have hc : (0 : ℝ) < (lazyMoves G).card := by
    exact_mod_cast Finset.card_pos.mpr (lazyMoves_nonempty G)
  unfold lazyKernel
  rw [Finset.sum_comm]
  simp only [Finset.sum_ite_eq, Finset.mem_univ, if_true]
  simp [ne_of_gt hc]

theorem lazyKernel_symm (G : SimpleGraph V) (σ τ : Equiv.Perm V) :
    lazyKernel G σ τ = lazyKernel G τ σ := by
  classical
  unfold lazyKernel
  apply Finset.sum_congr rfl
  intro e he
  have hself : e * e = 1 := by
    conv_lhs => lhs; rw [← lazyMoves_inv G he]
    exact inv_mul_cancel e
  have heq : σ * e = τ ↔ τ * e = σ := by
    constructor
    · rintro rfl
      simp [mul_assoc, hself]
    · rintro h
      rw [← h]
      simp [mul_assoc, hself]
  simp only [heq]

theorem lazyKernel_column (G : SimpleGraph V) (τ : Equiv.Perm V) :
    ∑ σ, lazyKernel G σ τ = 1 := by
  simpa only [lazyKernel_symm G] using lazyKernel_row G τ

theorem lazyKernel_move_pos (G : SimpleGraph V) (σ : Equiv.Perm V)
    {e : Equiv.Perm V} (he : e ∈ lazyMoves G) :
    0 < lazyKernel G σ (σ * e) := by
  classical
  have hc : (0 : ℝ) < (lazyMoves G).card := by
    exact_mod_cast Finset.card_pos.mpr (lazyMoves_nonempty G)
  have hterm : (0 : ℝ) <
      (if σ * e = σ * e then (1 : ℝ) / (lazyMoves G).card else 0) := by
    simp [hc]
  unfold lazyKernel
  exact hterm.trans_le (Finset.single_le_sum
    (f := fun g => if σ * g = σ * e then (1 : ℝ) / (lazyMoves G).card else 0)
    (fun g _ => by dsimp only; split_ifs <;> positivity) he)

theorem lazyKernel_diag_pos (G : SimpleGraph V) (σ : Equiv.Perm V) :
    0 < lazyKernel G σ σ := by
  simpa using lazyKernel_move_pos G σ ((mem_lazyMoves G 1).2 (Or.inl rfl))

theorem lazyKernel_edge_pos (G : SimpleGraph V) (σ : Equiv.Perm V)
    {e : Equiv.Perm V} (he : e ∈ edgeSwaps G) :
    0 < lazyKernel G σ (σ * e) :=
  lazyKernel_move_pos G σ ((mem_lazyMoves G e).2 (Or.inr he))

open FiniteMixing

/-- Positivity propagates along every finite word of allowed swaps. -/
theorem power_pos_of_edgeSwap_word (G : SimpleGraph V)
    (K : Equiv.Perm V → Equiv.Perm V → ℝ)
    (hK : ∀ σ τ, 0 ≤ K σ τ)
    (hedge : ∀ σ e, e ∈ edgeSwaps G → 0 < K σ (σ * e))
    (σ : Equiv.Perm V) (l : List (Equiv.Perm V))
    (hl : ∀ e ∈ l, e ∈ edgeSwaps G) :
    0 < power K l.length σ (σ * l.prod) := by
  classical
  induction l using List.reverseRecOn with
  | nil => simp
  | append_singleton l e ih =>
    have hp : 0 < power K l.length σ (σ * l.prod) :=
      ih (fun g hg => hl g (by simp only [List.mem_append]; exact Or.inl hg))
    have he : e ∈ edgeSwaps G := hl e (by simp)
    simp only [List.length_append, List.length_singleton, List.prod_append,
      List.prod_singleton, ← mul_assoc]
    rw [power_succ]
    exact (mul_pos hp (hedge (σ * l.prod) e he)).trans_le
      (Finset.single_le_sum
        (f := fun τ => power K l.length σ τ * K τ (σ * l.prod * e))
        (fun τ _ => mul_nonneg (power_nonneg K hK _ _ _) (hK _ _))
        (Finset.mem_univ (σ * l.prod)))

/-- Positive holding probabilities allow padding a positive path to any longer
length. -/
theorem power_pos_of_le (K : Equiv.Perm V → Equiv.Perm V → ℝ)
    (hK : ∀ σ τ, 0 ≤ K σ τ) (hdiag : ∀ σ, 0 < K σ σ)
    {n m : ℕ} {σ τ : Equiv.Perm V} (hpos : 0 < power K n σ τ)
    (hnm : n ≤ m) : 0 < power K m σ τ := by
  classical
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le hnm
  clear hnm
  induction k with
  | zero => simpa using hpos
  | succ k ih =>
    rw [Nat.add_succ, power_succ]
    exact (mul_pos ih (hdiag τ)).trans_le
      (Finset.single_le_sum
        (f := fun υ => power K (n + k) σ υ * K υ τ)
        (fun υ _ => mul_nonneg (power_nonneg K hK _ _ _) (hK _ _))
        (Finset.mem_univ τ))

/-- Connectivity and positive edge and holding probabilities imply a single
strictly positive transition power. No mixing hypothesis is assumed here. -/
theorem exists_positive_power (G : SimpleGraph V) (hG : G.Connected)
    (K : Equiv.Perm V → Equiv.Perm V → ℝ)
    (hK : ∀ σ τ, 0 ≤ K σ τ) (hdiag : ∀ σ, 0 < K σ σ)
    (hedge : ∀ σ e, e ∈ edgeSwaps G → 0 < K σ (σ * e)) :
    ∃ L : ℕ, 0 < L ∧ ∀ σ τ, 0 < power K L σ τ := by
  classical
  have hreach : ∀ σ τ : Equiv.Perm V, ∃ n : ℕ, 0 < power K n σ τ := by
    intro σ τ
    obtain ⟨l, hl, hprod⟩ := exists_edgeSwap_word G hG (σ⁻¹ * τ)
    have hp := power_pos_of_edgeSwap_word G K hK hedge σ l hl
    rw [hprod, mul_inv_cancel_left] at hp
    exact ⟨l.length, hp⟩
  choose n hn using hreach
  obtain ⟨L, hL⟩ := Finite.exists_le (fun p : Equiv.Perm V × Equiv.Perm V => n p.1 p.2)
  refine ⟨L + 1, Nat.zero_lt_succ L, fun σ τ => ?_⟩
  exact power_pos_of_le K hK hdiag (hn σ τ)
    ((hL (σ, τ)).trans (Nat.le_succ L))

theorem lazyKernel_positive_power (G : SimpleGraph V) (hG : G.Connected) :
    ∃ L : ℕ, 0 < L ∧ ∀ σ τ, 0 < power (lazyKernel G) L σ τ :=
  exists_positive_power G hG (lazyKernel G) (lazyKernel_nonneg G)
    (lazyKernel_diag_pos G) (fun σ _ he => lazyKernel_edge_pos G σ he)

end PeerSwap
