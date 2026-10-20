import PeerSwap.Convergence
import PeerSwap.UniformProduct

/-!
# The neighbor-sampling service

Choose, independently of the current placement, a uniform ordered injection
into each vertex's neighborhood; read the choice at the querying peer's current
vertex. This realizes uniform sampling without replacement from that neighborhood.
-/

open scoped BigOperators
open Filter Topology

namespace PeerSwap

variable {V : Type*} [Fintype V] [DecidableEq V]

/-- All possible ordered neighbor-slot choices at all vertices. -/
abbrev SlotSystem (G : SimpleGraph V) (b : ℕ) :=
  (v : V) → (Fin b ↪ G.neighborSet v)

omit [DecidableEq V] in
/-- The degree condition ensures that neighbor-slot choices exist. -/
theorem slotSystem_nonempty (G : SimpleGraph V) [DecidableRel G.Adj] (b : ℕ)
    (hb : ∀ v, b ≤ G.degree v) : Nonempty (SlotSystem G b) := by
  classical
  have h : ∀ v, Nonempty (Fin b ↪ G.neighborSet v) := by
    intro v
    apply Function.Embedding.nonempty_of_card_le
    simpa only [Fintype.card_fin, G.card_neighborSet_eq_degree] using hb v
  exact ⟨fun v => Classical.choice (h v)⟩

/-- Forget that each selected position is a neighbor. -/
def neighborSlots (G : SimpleGraph V) {b : ℕ} (r : SlotSystem G b)
    (v : V) : Fin b ↪ V :=
  (r v).trans (Function.Embedding.subtype _)

omit [Fintype V] [DecidableEq V] in
theorem neighborSlots_adj (G : SimpleGraph V) {b : ℕ} (r : SlotSystem G b)
    (v : V) (j : Fin b) : G.Adj v (neighborSlots G r v j) :=
  (r v j).property

omit [Fintype V] [DecidableEq V] in
theorem neighborSlots_ne (G : SimpleGraph V) {b : ℕ} (r : SlotSystem G b)
    (v : V) (j : Fin b) : neighborSlots G r v j ≠ v :=
  (neighborSlots_adj G r v j).ne'

/-- Uniform slot systems induce a uniform ordered choice at every vertex,
including when vertex degrees differ. -/
theorem neighborChoice_uniform (G : SimpleGraph V) [DecidableRel G.Adj]
    (b : ℕ) (hb : ∀ v, b ≤ G.degree v) (v : V)
    (a : Fin b ↪ G.neighborSet v) :
    (∑ r : SlotSystem G b,
      if r v = a then (1 : ℝ) / Fintype.card (SlotSystem G b) else 0) =
      1 / (Fintype.card (Fin b ↪ G.neighborSet v) : ℝ) := by
  classical
  letI : ∀ v, Nonempty (Fin b ↪ G.neighborSet v) := fun v =>
    Function.Embedding.nonempty_of_card_le
      (by simpa only [Fintype.card_fin, G.card_neighborSet_eq_degree] using hb v)
  exact uniform_product_coordinate (A := fun v => Fin b ↪ G.neighborSet v) v a

omit [Fintype V] [DecidableEq V] in
/-- Every returned identifier is a neighbor in the current relabeled graph. -/
theorem read_neighbor (G : SimpleGraph V) {b : ℕ} (r : SlotSystem G b)
    (i : V) (σ : Equiv.Perm V) (j : Fin b) :
    (relabel G σ).Adj i
      (Sampling.read i (neighborSlots G r) (neighborSlots_ne G r) σ j).val := by
  have h := edge_present_after_relabel G σ (neighborSlots_adj G r (σ.symm i) j)
  simpa only [Equiv.apply_symm_apply, Sampling.read] using h

/-- The ideal PeerSwap peer-sampling law for ordered samples of size `b`. -/
noncomputable def neighborSampleLaw (G : SimpleGraph V) [DecidableRel G.Adj] (α : ℝ)
    (μ : Equiv.Perm V → ℝ) (i : V) (b : ℕ) (t : ℝ)
    (a : Sampling.Sample (J := Fin b) i) : ℝ := by
  classical
  exact sampleLaw G α μ i
    (fun _ : SlotSystem G b => 1 / (Fintype.card (SlotSystem G b) : ℝ))
    (neighborSlots G) (neighborSlots_ne G) t a

/-- Main theorem: samples converge to the uniform distribution on ordered
`b`-tuples of other peers, on any finite connected simple graph. -/
theorem neighborSampleLaw_converges (G : SimpleGraph V) [DecidableRel G.Adj]
    (hG : G.Connected) (α : ℝ) (hα : 0 < α)
    (μ : Equiv.Perm V → ℝ) (hμ : ∀ σ, 0 ≤ μ σ) (hmass : ∑ σ, μ σ = 1)
    (i : V) (b : ℕ) (hb : ∀ v, b ≤ G.degree v)
    (a : Sampling.Sample (J := Fin b) i) :
    Tendsto (fun t => neighborSampleLaw G α μ i b t a) atTop
      (𝓝 (1 / (Fintype.card (Sampling.Sample (J := Fin b) i) : ℝ))) := by
  classical
  letI := slotSystem_nonempty G b hb
  have hw : (∑ _ : SlotSystem G b,
      (1 : ℝ) / (Fintype.card (SlotSystem G b) : ℝ)) = 1 := Sampling.uniform_sum
  unfold neighborSampleLaw
  exact sampleLaw_converges (J := Fin b) (R := SlotSystem G b)
    G hG α hα μ hμ hmass i
    (fun _ => (1 : ℝ) / (Fintype.card (SlotSystem G b) : ℝ)) hw
    (neighborSlots G) (neighborSlots_ne G) a

/-- Main total variation formulation of convergence. -/
theorem neighborSampleLaw_totalVariation (G : SimpleGraph V) [DecidableRel G.Adj]
    (hG : G.Connected) (α : ℝ) (hα : 0 < α)
    (μ : Equiv.Perm V → ℝ) (hμ : ∀ σ, 0 ≤ μ σ) (hmass : ∑ σ, μ σ = 1)
    (i : V) (b : ℕ) (hb : ∀ v, b ≤ G.degree v) :
    Tendsto (fun t => (∑ a, |neighborSampleLaw G α μ i b t a -
      1 / (Fintype.card (Sampling.Sample (J := Fin b) i) : ℝ)|) / 2)
      atTop (𝓝 0) := by
  classical
  exact Sampling.totalVariation_tendsto _ _ _
    (neighborSampleLaw_converges G hG α hα μ hμ hmass i b hb)

end PeerSwap
