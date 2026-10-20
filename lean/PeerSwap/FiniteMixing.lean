import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Topology.MetricSpace.Pseudo.Lemmas
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Tactic

/-!
# A finite-state Doeblin convergence theorem

A row-stochastic matrix with a common strictly positive lower bound contracts
zero-mass signed measures in the `ℓ¹` distance. Consequently its iterates converge
to every stationary probability vector. The proof includes the geometric error
bound, rather than assuming an abstract ergodicity or convergence result.
-/

open scoped BigOperators
open Filter Topology

namespace PeerSwap.FiniteMixing

variable {ι : Type*} [Fintype ι]

/-- One step of a finite transition kernel, acting on row probability vectors. -/
noncomputable def step (K : ι → ι → ℝ) (μ : ι → ℝ) (y : ι) : ℝ :=
  ∑ x, μ x * K x y

/-- The distribution after `n` steps. -/
noncomputable def evolve (K : ι → ι → ℝ) (μ : ι → ℝ) : ℕ → ι → ℝ
  | 0 => μ
  | n + 1 => step K (evolve K μ n)

/-- The `n`-step transition kernel. -/
noncomputable def power (K : ι → ι → ℝ) (n : ℕ) (x y : ι) : ℝ := by
  classical
  exact evolve K (fun z => if z = x then 1 else 0) n y

@[simp] lemma power_zero [DecidableEq ι] (K : ι → ι → ℝ) (x y : ι) :
    power K 0 x y = (if y = x then 1 else 0) := by
  classical
  simp [power, evolve]

@[simp] lemma power_succ (K : ι → ι → ℝ) (n : ℕ) (x y : ι) :
    power K (n + 1) x y = ∑ z, power K n x z * K z y := rfl

lemma evolve_add (K : ι → ι → ℝ) (μ : ι → ℝ) (m n : ℕ) :
    evolve K μ (m + n) = evolve K (evolve K μ m) n := by
  induction n with
  | zero => rfl
  | succ n ih =>
    change step K (evolve K μ (m + n)) = step K (evolve K (evolve K μ m) n)
    rw [ih]

lemma evolve_stationary (K : ι → ι → ℝ) (π : ι → ℝ)
    (hstationary : step K π = π) (n : ℕ) : evolve K π n = π := by
  induction n with
  | zero => rfl
  | succ n ih => simp only [evolve, ih, hstationary]

/-- Matrix powers represent the iterated action on every initial vector. -/
lemma evolve_eq_step_power (K : ι → ι → ℝ) (μ : ι → ℝ) (n : ℕ) :
    evolve K μ n = step (power K n) μ := by
  classical
  induction n with
  | zero => funext y; simp [evolve, step]
  | succ n ih =>
    funext y
    change step K (evolve K μ n) y = step (power K (n + 1)) μ y
    rw [ih]
    simp only [step, power_succ, Finset.sum_mul, Finset.mul_sum]
    rw [Finset.sum_comm]
    apply Finset.sum_congr rfl
    intro x _
    apply Finset.sum_congr rfl
    intro z _
    ring

lemma power_add (K : ι → ι → ℝ) (m n : ℕ) (x y : ι) :
    power K (m + n) x y = ∑ z, power K m x z * power K n z y := by
  classical
  change evolve K (fun z => if z = x then 1 else 0) (m + n) y = _
  rw [evolve_add, evolve_eq_step_power]
  rfl

lemma evolve_nonneg (K : ι → ι → ℝ) (μ : ι → ℝ)
    (hK : ∀ x y, 0 ≤ K x y) (hμ : ∀ x, 0 ≤ μ x) (n : ℕ) :
    ∀ x, 0 ≤ evolve K μ n x := by
  induction n with
  | zero => exact hμ
  | succ n ih =>
    intro y
    exact Finset.sum_nonneg fun x _ => mul_nonneg (ih x) (hK x y)

lemma power_nonneg (K : ι → ι → ℝ) (hK : ∀ x y, 0 ≤ K x y)
    (n : ℕ) (x y : ι) : 0 ≤ power K n x y := by
  classical
  exact evolve_nonneg K _ hK (fun z => by split_ifs <;> norm_num) n y

/-- Unnormalized total variation (`ℓ¹`) distance on finite vectors. -/
noncomputable def l1 (μ ν : ι → ℝ) : ℝ := ∑ x, |μ x - ν x|

lemma l1_nonneg (μ ν : ι → ℝ) : 0 ≤ l1 μ ν :=
  Finset.sum_nonneg fun _ _ => abs_nonneg _

lemma abs_sub_le_l1 (μ ν : ι → ℝ) (x : ι) : |μ x - ν x| ≤ l1 μ ν := by
  classical
  exact Finset.single_le_sum (fun y _ => abs_nonneg (μ y - ν y)) (Finset.mem_univ x)

/-- A finite randomized observation channel, possibly with a different output
state space. Deterministic projections are included as point-mass channels. -/
noncomputable def observe {κ : Type*} [Fintype κ]
    (O : ι → κ → ℝ) (μ : ι → ℝ) (y : κ) : ℝ := ∑ x, μ x * O x y

/-- Randomized observations cannot increase total variation distance. No
assumption on the masses of the input signed vectors is necessary. -/
theorem l1_observe_le {κ : Type*} [Fintype κ]
    (O : ι → κ → ℝ) (μ ν : ι → ℝ)
    (hO : ∀ x y, 0 ≤ O x y) (hrow : ∀ x, ∑ y, O x y = 1) :
    l1 (observe O μ) (observe O ν) ≤ l1 μ ν := by
  classical
  calc
    l1 (observe O μ) (observe O ν)
        = ∑ y, |∑ x, (μ x - ν x) * O x y| := by
          simp only [l1, observe, sub_mul, Finset.sum_sub_distrib]
    _ ≤ ∑ y, ∑ x, |μ x - ν x| * O x y := by
      apply Finset.sum_le_sum
      intro y _
      calc
        |∑ x, (μ x - ν x) * O x y| ≤ ∑ x, |(μ x - ν x) * O x y| :=
          Finset.abs_sum_le_sum_abs _ _
        _ = ∑ x, |μ x - ν x| * O x y := by
          simp only [abs_mul, abs_of_nonneg (hO _ _)]
    _ = l1 μ ν := by
      rw [Finset.sum_comm]
      simp_rw [← Finset.mul_sum, hrow, mul_one]
      rfl

lemma sum_step (K : ι → ι → ℝ) (μ : ι → ℝ)
    (hrow : ∀ x, ∑ y, K x y = 1) :
    ∑ y, step K μ y = ∑ x, μ x := by
  classical
  simp only [step]
  rw [Finset.sum_comm]
  simp_rw [← Finset.mul_sum, hrow, mul_one]

lemma sum_evolve (K : ι → ι → ℝ) (μ : ι → ℝ)
    (hrow : ∀ x, ∑ y, K x y = 1) (n : ℕ) :
    ∑ x, evolve K μ n x = ∑ x, μ x := by
  induction n with
  | zero => rfl
  | succ n ih => simpa only [evolve, sum_step K _ hrow] using ih

lemma evolve_le_one (K : ι → ι → ℝ) (μ : ι → ℝ)
    (hrow : ∀ x, ∑ y, K x y = 1) (hK : ∀ x y, 0 ≤ K x y)
    (hμ : ∀ x, 0 ≤ μ x) (hμsum : ∑ x, μ x = 1) (n : ℕ) (x : ι) :
    evolve K μ n x ≤ 1 := by
  classical
  calc
    evolve K μ n x ≤ ∑ y, evolve K μ n y :=
      Finset.single_le_sum (fun y _ => evolve_nonneg K μ hK hμ n y) (Finset.mem_univ x)
    _ = 1 := by rw [sum_evolve K μ hrow n, hμsum]

lemma power_le_one (K : ι → ι → ℝ)
    (hrow : ∀ x, ∑ y, K x y = 1) (hK : ∀ x y, 0 ≤ K x y)
    (n : ℕ) (x y : ι) : power K n x y ≤ 1 := by
  classical
  exact evolve_le_one K _ hrow hK (fun z => by split_ifs <;> norm_num)
    (by simp) n y

lemma power_row_sum (K : ι → ι → ℝ)
    (hrow : ∀ x, ∑ y, K x y = 1) (n : ℕ) (x : ι) :
    ∑ y, power K n x y = 1 := by
  classical
  change ∑ y, evolve K (fun z => if z = x then 1 else 0) n y = 1
  rw [sum_evolve K _ hrow n]
  simp

lemma centered_step (K : ι → ι → ℝ) (μ ν : ι → ℝ) (ε : ℝ)
    (hmass : ∑ x, μ x = ∑ x, ν x) (y : ι) :
    step K μ y - step K ν y = ∑ x, (μ x - ν x) * (K x y - ε) := by
  have hzero : ∑ x, (μ x - ν x) = 0 := by
    rw [Finset.sum_sub_distrib, hmass, sub_self]
  calc
    step K μ y - step K ν y = ∑ x, (μ x - ν x) * K x y := by
      simp only [step, sub_mul, Finset.sum_sub_distrib]
    _ = ∑ x, (μ x - ν x) * (K x y - ε) := by
      simp only [mul_sub, Finset.sum_sub_distrib, ← Finset.sum_mul, hzero,
        zero_mul, sub_zero]

/-- Doeblin's contraction bound for two vectors having the same total mass. -/
theorem l1_step_le (K : ι → ι → ℝ) (μ ν : ι → ℝ) (ε : ℝ)
    (hrow : ∀ x, ∑ y, K x y = 1)
    (hminor : ∀ x y, ε ≤ K x y)
    (hmass : ∑ x, μ x = ∑ x, ν x) :
    l1 (step K μ) (step K ν) ≤
      (1 - (Fintype.card ι : ℝ) * ε) * l1 μ ν := by
  classical
  calc
    l1 (step K μ) (step K ν)
        = ∑ y, |∑ x, (μ x - ν x) * (K x y - ε)| := by
            simp only [l1, centered_step K μ ν ε hmass]
    _ ≤ ∑ y, ∑ x, |μ x - ν x| * (K x y - ε) := by
      apply Finset.sum_le_sum
      intro y _
      calc
        |∑ x, (μ x - ν x) * (K x y - ε)|
            ≤ ∑ x, |(μ x - ν x) * (K x y - ε)| :=
              Finset.abs_sum_le_sum_abs _ _
        _ = ∑ x, |μ x - ν x| * (K x y - ε) := by
          apply Finset.sum_congr rfl
          intro x _
          rw [abs_mul, abs_of_nonneg (sub_nonneg.mpr (hminor x y))]
    _ = ∑ x, |μ x - ν x| * (1 - (Fintype.card ι : ℝ) * ε) := by
      rw [Finset.sum_comm]
      apply Finset.sum_congr rfl
      intro x _
      rw [← Finset.mul_sum, Finset.sum_sub_distrib, hrow]
      simp
    _ = (1 - (Fintype.card ι : ℝ) * ε) * l1 μ ν := by
      rw [← Finset.sum_mul, l1, mul_comm]

lemma minorization_factor_nonneg [Nonempty ι] (K : ι → ι → ℝ) (ε : ℝ)
    (hrow : ∀ x, ∑ y, K x y = 1) (hminor : ∀ x y, ε ≤ K x y) :
    0 ≤ 1 - (Fintype.card ι : ℝ) * ε := by
  classical
  obtain ⟨x⟩ := ‹Nonempty ι›
  have h := Finset.sum_le_sum (s := Finset.univ) (fun y _ => hminor x y)
  simpa only [Finset.sum_const, Finset.card_univ, nsmul_eq_mul, hrow x] using
    sub_nonneg.mpr h

lemma minorization_factor_lt_one [Nonempty ι] (ε : ℝ) (hε : 0 < ε) :
    1 - (Fintype.card ι : ℝ) * ε < 1 := by
  have hc : (0 : ℝ) < Fintype.card ι := by exact_mod_cast Fintype.card_pos
  linarith [mul_pos hc hε]

/-- The explicit geometric mixing bound for a stationary vector. -/
theorem l1_evolve_le [Nonempty ι] (K : ι → ι → ℝ) (μ π : ι → ℝ) (ε : ℝ)
    (hrow : ∀ x, ∑ y, K x y = 1)
    (hminor : ∀ x y, ε ≤ K x y)
    (hmass : ∑ x, μ x = ∑ x, π x)
    (hstationary : step K π = π) (n : ℕ) :
    l1 (evolve K μ n) π ≤
      (1 - (Fintype.card ι : ℝ) * ε) ^ n * l1 μ π := by
  have hq := minorization_factor_nonneg K ε hrow hminor
  induction n with
  | zero => simp [evolve]
  | succ n ih =>
    have hm : ∑ x, evolve K μ n x = ∑ x, π x := by
      rw [sum_evolve K μ hrow n, hmass]
    calc
      l1 (evolve K μ (n + 1)) π
          = l1 (step K (evolve K μ n)) (step K π) := by rw [evolve, hstationary]
      _ ≤ (1 - (Fintype.card ι : ℝ) * ε) * l1 (evolve K μ n) π :=
        l1_step_le K _ π ε hrow hminor hm
      _ ≤ (1 - (Fintype.card ι : ℝ) * ε) *
          ((1 - (Fintype.card ι : ℝ) * ε) ^ n * l1 μ π) :=
        mul_le_mul_of_nonneg_left ih hq
      _ = (1 - (Fintype.card ι : ℝ) * ε) ^ (n + 1) * l1 μ π := by ring

/-- A strictly positive minorization implies convergence to any stationary vector
of the same mass. In particular this applies to probability distributions. -/
theorem converges_of_minorization [Nonempty ι] (K : ι → ι → ℝ)
    (μ π : ι → ℝ) (ε : ℝ)
    (hrow : ∀ x, ∑ y, K x y = 1)
    (hminor : ∀ x y, ε ≤ K x y) (hε : 0 < ε)
    (hmass : ∑ x, μ x = ∑ x, π x)
    (hstationary : step K π = π) :
    ∀ y, Tendsto (fun n => evolve K μ n y) atTop (𝓝 (π y)) := by
  have hq₀ := minorization_factor_nonneg K ε hrow hminor
  have hq₁ := minorization_factor_lt_one (ι := ι) ε hε
  have hgeom : Tendsto
      (fun n : ℕ => (1 - (Fintype.card ι : ℝ) * ε) ^ n * l1 μ π)
      atTop (𝓝 0) := by
    simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one hq₀ hq₁).mul_const (l1 μ π)
  intro y
  apply tendsto_iff_dist_tendsto_zero.mpr
  refine squeeze_zero (fun _ => dist_nonneg) (fun n => ?_) hgeom
  rw [Real.dist_eq]
  exact (abs_sub_le_l1 _ _ y).trans
    (l1_evolve_le K μ π ε hrow hminor hmass hstationary n)

lemma evolve_block (K B : ι → ι → ℝ) (L : ℕ)
    (hblock : ∀ μ, evolve K μ L = step B μ) (μ : ι → ℝ) (n : ℕ) :
    evolve K μ (L * n) = evolve B μ n := by
  induction n with
  | zero => simp [evolve]
  | succ n ih =>
    rw [Nat.mul_succ, evolve_add, hblock, ih]
    rfl

/-- A positive minorization of one fixed-length block suffices: remaining steps
are nonexpansive, giving a bound at every discrete time, not just block times. -/
theorem l1_evolve_le_block [Nonempty ι] (K B : ι → ι → ℝ)
    (μ π : ι → ℝ) (L : ℕ) (ε : ℝ)
    (hrow : ∀ x, ∑ y, K x y = 1) (hK : ∀ x y, 0 ≤ K x y)
    (hBrow : ∀ x, ∑ y, B x y = 1) (hminor : ∀ x y, ε ≤ B x y)
    (hblock : ∀ μ, evolve K μ L = step B μ)
    (hmass : ∑ x, μ x = ∑ x, π x)
    (hstationary : step K π = π) (n : ℕ) :
    l1 (evolve K μ n) π ≤
      (1 - (Fintype.card ι : ℝ) * ε) ^ (n / L) * l1 μ π := by
  have hBstat : step B π = π := by
    rw [← hblock π, evolve_stationary K π hstationary]
  have hmass' : ∑ x, evolve K μ (L * (n / L)) x = ∑ x, π x := by
    rw [sum_evolve K μ hrow, hmass]
  calc
    l1 (evolve K μ n) π
        = l1 (evolve K (evolve K μ (L * (n / L))) (n % L)) π := by
            rw [← evolve_add, Nat.div_add_mod]
    _ ≤ l1 (evolve K μ (L * (n / L))) π := by
      simpa using l1_evolve_le K _ π 0 hrow hK hmass' hstationary (n % L)
    _ = l1 (evolve B μ (n / L)) π := by rw [evolve_block K B L hblock]
    _ ≤ (1 - (Fintype.card ι : ℝ) * ε) ^ (n / L) * l1 μ π :=
      l1_evolve_le B μ π ε hBrow hminor hmass hBstat (n / L)

/-- Doeblin convergence from a positive fixed-length block. -/
theorem converges_of_block [Nonempty ι] (K B : ι → ι → ℝ)
    (μ π : ι → ℝ) (L : ℕ) (ε : ℝ)
    (hL : 0 < L) (hε : 0 < ε)
    (hrow : ∀ x, ∑ y, K x y = 1) (hK : ∀ x y, 0 ≤ K x y)
    (hBrow : ∀ x, ∑ y, B x y = 1) (hminor : ∀ x y, ε ≤ B x y)
    (hblock : ∀ μ, evolve K μ L = step B μ)
    (hmass : ∑ x, μ x = ∑ x, π x) (hstationary : step K π = π) :
    ∀ y, Tendsto (fun n => evolve K μ n y) atTop (𝓝 (π y)) := by
  have hq₀ := minorization_factor_nonneg B ε hBrow hminor
  have hq₁ := minorization_factor_lt_one (ι := ι) ε hε
  have hdiv : Tendsto (fun n : ℕ => n / L) atTop atTop := by
    refine tendsto_atTop.2 fun b => ?_
    exact eventually_atTop.2 ⟨b * L, fun n hn => (Nat.le_div_iff_mul_le hL).2 hn⟩
  have hgeom : Tendsto
      (fun n : ℕ => (1 - (Fintype.card ι : ℝ) * ε) ^ (n / L) * l1 μ π)
      atTop (𝓝 0) := by
    simpa using ((tendsto_pow_atTop_nhds_zero_of_lt_one hq₀ hq₁).comp hdiv).mul_const (l1 μ π)
  intro y
  apply tendsto_iff_dist_tendsto_zero.mpr
  refine squeeze_zero (fun _ => dist_nonneg) (fun n => ?_) hgeom
  rw [Real.dist_eq]
  exact (abs_sub_le_l1 _ _ y).trans
    (l1_evolve_le_block K B μ π L ε hrow hK hBrow hminor hblock hmass hstationary n)

/-- On a finite state space, strict positivity of a power gives its own uniform
minorization. This is the primitive finite-chain convergence criterion. -/
theorem converges_of_positive_power [Nonempty ι] (K : ι → ι → ℝ)
    (μ π : ι → ℝ) (L : ℕ) (hL : 0 < L)
    (hrow : ∀ x, ∑ y, K x y = 1) (hK : ∀ x y, 0 ≤ K x y)
    (hpositive : ∀ x y, 0 < power K L x y)
    (hmass : ∑ x, μ x = ∑ x, π x) (hstationary : step K π = π) :
    ∀ y, Tendsto (fun n => evolve K μ n y) atTop (𝓝 (π y)) := by
  classical
  obtain ⟨z, hz, hmin⟩ := Finset.exists_min_image Finset.univ
    (fun p : ι × ι => power K L p.1 p.2) Finset.univ_nonempty
  exact converges_of_block K (power K L) μ π L (power K L z.1 z.2) hL
    (hpositive z.1 z.2) hrow hK (power_row_sum K hrow L)
    (fun x y => hmin (x, y) (Finset.mem_univ _))
    (fun μ => evolve_eq_step_power K μ L) hmass hstationary

end PeerSwap.FiniteMixing
