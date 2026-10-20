import Mathlib.Probability.Distributions.Poisson
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Topology.Instances.NNReal.Lemmas
import Mathlib.Analysis.Normed.Group.InfiniteSum
import Mathlib.Tactic

/-!
# Poissonization

Poissonization turns a discrete sequence of laws into a continuous-time law.
The main theorem below proves convergence for every real time, rather than
only for a discrete skeleton. It uses only boundedness and convergence of the
discrete sequence.
-/

open Filter Topology
open scoped NNReal

namespace PeerSwap

/-- The real-valued Poisson average of a scalar sequence. -/
noncomputable def poissonAverage (r : ℝ≥0) (a : ℕ → ℝ) : ℝ :=
  ∑' n, ProbabilityTheory.poissonPMFReal r n * a n

/-- At zero elapsed time the Poisson count is zero, so the initial value is
preserved exactly. No boundedness hypothesis is needed. -/
theorem poissonAverage_zero (a : ℕ → ℝ) : poissonAverage 0 a = a 0 := by
  unfold poissonAverage
  rw [tsum_eq_single 0]
  · simp [ProbabilityTheory.poissonPMFReal]
  · intro n hn
    simp [ProbabilityTheory.poissonPMFReal, zero_pow hn]

/-- The probability of any fixed count tends to zero as the mean diverges. -/
theorem poisson_weight_tendsto_zero (n : ℕ) :
    Tendsto (fun r : ℝ≥0 => ProbabilityTheory.poissonPMFReal r n) atTop (𝓝 0) := by
  have hcoe : Tendsto (fun r : ℝ≥0 => (r : ℝ)) atTop atTop :=
    NNReal.tendsto_coe_atTop.mpr tendsto_id
  have h := (Real.tendsto_pow_mul_exp_neg_atTop_nhds_zero n).comp hcoe
  simpa only [ProbabilityTheory.poissonPMFReal, mul_comm, zero_div] using
    h.div_const (Nat.factorial n : ℝ)

/-- A bounded sequence is integrable against every Poisson law. -/
theorem summable_poisson_mul {a : ℕ → ℝ} {B : ℝ}
    (hB : ∀ n, |a n| ≤ B) (r : ℝ≥0) :
    Summable (fun n => ProbabilityTheory.poissonPMFReal r n * a n) := by
  apply Summable.of_norm_bounded
    ((ProbabilityTheory.poissonPMFRealSum r).summable.mul_right B)
  intro n
  rw [Real.norm_eq_abs, abs_mul,
    abs_of_nonneg ProbabilityTheory.poissonPMFReal_nonneg]
  exact mul_le_mul_of_nonneg_left (hB n) ProbabilityTheory.poissonPMFReal_nonneg

/-- Subtracting a constant commutes with the Poisson average. -/
theorem poissonAverage_sub {a : ℕ → ℝ} {B : ℝ}
    (hB : ∀ n, |a n| ≤ B) (r : ℝ≥0) (l : ℝ) :
    poissonAverage r a - l =
      ∑' n, ProbabilityTheory.poissonPMFReal r n * (a n - l) := by
  have hc : (∑' n, ProbabilityTheory.poissonPMFReal r n * l) = l := by
    simpa using ((ProbabilityTheory.poissonPMFRealSum r).mul_right l).tsum_eq
  unfold poissonAverage
  calc
    _ = (∑' n, ProbabilityTheory.poissonPMFReal r n * a n) -
        (∑' n, ProbabilityTheory.poissonPMFReal r n * l) := by rw [hc]
    _ = ∑' n, (ProbabilityTheory.poissonPMFReal r n * a n -
        ProbabilityTheory.poissonPMFReal r n * l) :=
      ((summable_poisson_mul hB r).tsum_sub
        ((ProbabilityTheory.poissonPMFRealSum r).summable.mul_right l)).symm
    _ = _ := tsum_congr (fun n => by ring)

/-- Poissonization preserves the limit of a bounded sequence.

The Poisson count escapes every finite prefix as its mean tends to infinity.
Thus a fixed finite prefix contributes zero in the limit, and the remaining
terms are uniformly close to the limit of the original sequence.
-/
theorem poisson_average_tendsto {a : ℕ → ℝ} {B l : ℝ}
    (hB : ∀ n, |a n| ≤ B) (ha : Tendsto a atTop (𝓝 l)) :
    Tendsto (fun r : ℝ≥0 => poissonAverage r a) atTop (𝓝 l) := by
  apply Metric.tendsto_atTop.mpr
  intro ε hε
  obtain ⟨N, hN⟩ := Metric.tendsto_atTop.mp ha (ε / 2) (by positivity)
  have hhead : Tendsto
      (fun r : ℝ≥0 => ∑ n ∈ Finset.range N,
        ProbabilityTheory.poissonPMFReal r n * |a n - l|) atTop (𝓝 0) := by
    simpa using tendsto_finset_sum (Finset.range N)
      (fun n _ => (poisson_weight_tendsto_zero n).mul_const |a n - l|)
  obtain ⟨R, hR⟩ := Metric.tendsto_atTop.mp hhead (ε / 2) (by positivity)
  refine ⟨R, ?_⟩
  intro r hr
  have hw := (ProbabilityTheory.poissonPMFRealSum r).summable
  have hwt : Summable (fun n => ProbabilityTheory.poissonPMFReal r (n + N)) :=
    (summable_nat_add_iff N).mpr hw
  have htail_mass : (∑' n, ProbabilityTheory.poissonPMFReal r (n + N)) ≤ 1 := by
    have hsum := hw.sum_add_tsum_nat_add N
    rw [(ProbabilityTheory.poissonPMFRealSum r).tsum_eq] at hsum
    have hnonneg : 0 ≤ ∑ n ∈ Finset.range N, ProbabilityTheory.poissonPMFReal r n :=
      Finset.sum_nonneg (fun _ _ => ProbabilityTheory.poissonPMFReal_nonneg)
    linarith
  have htail : |∑' n, ProbabilityTheory.poissonPMFReal r (n + N) *
      (a (n + N) - l)| ≤ ε / 2 := by
    have hnorm : ∀ n, ‖ProbabilityTheory.poissonPMFReal r (n + N) *
        (a (n + N) - l)‖ ≤ ProbabilityTheory.poissonPMFReal r (n + N) * (ε / 2) := by
      intro n
      rw [Real.norm_eq_abs, abs_mul,
        abs_of_nonneg ProbabilityTheory.poissonPMFReal_nonneg]
      exact mul_le_mul_of_nonneg_left
        (le_of_lt (by simpa [Real.dist_eq] using hN (n + N) (Nat.le_add_left N n)))
        ProbabilityTheory.poissonPMFReal_nonneg
    have hbound := tsum_of_norm_bounded (hwt.hasSum.mul_right (ε / 2)) hnorm
    rw [Real.norm_eq_abs] at hbound
    exact hbound.trans (by nlinarith [htail_mass])
  have hsub : Summable (fun n => ProbabilityTheory.poissonPMFReal r n * (a n - l)) :=
    summable_poisson_mul (B := B + |l|)
      (fun n => (abs_sub (a n) l).trans (add_le_add_right (hB n) |l|)) r
  have hfinite : |∑ n ∈ Finset.range N,
        ProbabilityTheory.poissonPMFReal r n * (a n - l)| ≤
      ∑ n ∈ Finset.range N, ProbabilityTheory.poissonPMFReal r n * |a n - l| := by
    simpa only [abs_mul, abs_of_nonneg ProbabilityTheory.poissonPMFReal_nonneg] using
      (Finset.abs_sum_le_sum_abs (s := Finset.range N)
        (f := fun n => ProbabilityTheory.poissonPMFReal r n * (a n - l)))
  have hhead_lt : (∑ n ∈ Finset.range N,
      ProbabilityTheory.poissonPMFReal r n * |a n - l|) < ε / 2 := by
    have hh := hR r hr
    rw [Real.dist_eq, sub_zero] at hh
    exact lt_of_le_of_lt (le_abs_self _) hh
  rw [Real.dist_eq, poissonAverage_sub hB r l,
    ← hsub.sum_add_tsum_nat_add N]
  calc
    _ ≤ |∑ n ∈ Finset.range N, ProbabilityTheory.poissonPMFReal r n * (a n - l)| +
        |∑' n, ProbabilityTheory.poissonPMFReal r (n + N) * (a (n + N) - l)| :=
      abs_add_le _ _
    _ ≤ (∑ n ∈ Finset.range N, ProbabilityTheory.poissonPMFReal r n * |a n - l|) +
        ε / 2 := add_le_add hfinite htail
    _ < ε := by linarith

/-- Every strictly positive physical rate gives convergence as real time tends
  to infinity. The mean count is `rate * t`, so increasing the clock rate
  speeds up the process. -/
theorem poisson_average_rate_tendsto {a : ℕ → ℝ} {B l : ℝ}
    (hB : ∀ n, |a n| ≤ B) (ha : Tendsto a atTop (𝓝 l))
    (rate : ℝ) (hrate : 0 < rate) :
    Tendsto (fun t : ℝ => poissonAverage (Real.toNNReal (rate * t)) a)
      atTop (𝓝 l) := by
  exact (poisson_average_tendsto hB ha).comp
    (tendsto_real_toNNReal_atTop.comp (tendsto_id.const_mul_atTop hrate))

/-- Nonnegative sequences have nonnegative Poisson averages. -/
theorem poissonAverage_nonneg {a : ℕ → ℝ} (ha : ∀ n, 0 ≤ a n) (r : ℝ≥0) :
    0 ≤ poissonAverage r a := by
  exact tsum_nonneg (fun n => mul_nonneg ProbabilityTheory.poissonPMFReal_nonneg (ha n))

/-- Constants are fixed by Poisson averaging. -/
theorem poissonAverage_const (r : ℝ≥0) (c : ℝ) :
    poissonAverage r (fun _ => c) = c := by
  exact by simpa [poissonAverage] using
    ((ProbabilityTheory.poissonPMFRealSum r).mul_right c).tsum_eq

/-- A Poisson average of numbers in `[0, 1]` is also in `[0, 1]`. -/
theorem poissonAverage_mem_Icc {a : ℕ → ℝ}
    (ha : ∀ n, a n ∈ Set.Icc (0 : ℝ) 1) (r : ℝ≥0) :
    poissonAverage r a ∈ Set.Icc (0 : ℝ) 1 := by
  refine ⟨poissonAverage_nonneg (fun n => (ha n).1) r, ?_⟩
  have hsum := summable_poisson_mul (a := a)
    (B := 1) (fun n => by simpa [abs_of_nonneg (ha n).1] using (ha n).2) r
  have hle := hsum.tsum_le_tsum
    (fun n => mul_le_of_le_one_right ProbabilityTheory.poissonPMFReal_nonneg (ha n).2)
    (ProbabilityTheory.poissonPMFRealSum r).summable
  simpa [poissonAverage, (ProbabilityTheory.poissonPMFRealSum r).tsum_eq] using hle

/-- A coordinate of a finite probability distribution is at most one. -/
theorem finite_probability_le_one {S : Type*} [Fintype S]
    {p : S → ℝ} (hpos : ∀ x, 0 ≤ p x) (hmass : ∑ x, p x = 1) (x : S) :
    p x ≤ 1 := by
  classical
  calc
    p x ≤ ∑ y, p y := Finset.single_le_sum (fun y _ => hpos y) (Finset.mem_univ x)
    _ = 1 := hmass

/-- Poisson averaging a sequence of finite probability laws preserves mass. -/
theorem poissonLaw_sum {S : Type*} [Fintype S] {p : ℕ → S → ℝ}
    (hpos : ∀ n x, 0 ≤ p n x) (hmass : ∀ n, ∑ x, p n x = 1) (r : ℝ≥0) :
    ∑ x, poissonAverage r (fun n => p n x) = 1 := by
  have hbound : ∀ x n, |p n x| ≤ 1 := by
    intro x n
    rw [abs_of_nonneg (hpos n x)]
    exact finite_probability_le_one (hpos n) (hmass n) x
  have hswap := Summable.tsum_finsetSum (s := Finset.univ)
    (f := fun x n => ProbabilityTheory.poissonPMFReal r n * p n x)
    (fun x _ => summable_poisson_mul (hbound x) r)
  unfold poissonAverage
  rw [← hswap]
  simp_rw [← Finset.mul_sum, hmass, mul_one]
  exact (ProbabilityTheory.poissonPMFRealSum r).tsum_eq

/-- At a positive time, every positive-probability finite-step event has positive
probability under Poissonization. -/
theorem poissonAverage_pos_of {a : ℕ → ℝ} {B : ℝ}
    (hB : ∀ n, |a n| ≤ B) (ha : ∀ n, 0 ≤ a n)
    (r : ℝ≥0) (hr : 0 < r) (n : ℕ) (hn : 0 < a n) :
    0 < poissonAverage r a := by
  have hterm : 0 < ProbabilityTheory.poissonPMFReal r n * a n :=
    mul_pos (ProbabilityTheory.poissonPMFReal_pos hr) hn
  exact hterm.trans_le ((summable_poisson_mul hB r).le_tsum n
    (fun j _ => mul_nonneg ProbabilityTheory.poissonPMFReal_nonneg (ha j)))

end PeerSwap
