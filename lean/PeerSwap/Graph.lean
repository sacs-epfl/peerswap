import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.GroupTheory.Perm.ClosureSwap
import Mathlib.GroupTheory.Perm.Sign
import Mathlib.Algebra.Group.Submonoid.Membership

/-!
# Graph semantics and reachability for PeerSwap

A permutation records where each original vertex is currently located. An atomic
PeerSwap exchanges the two endpoints of a current edge, together with all their
incident edges. Thus it relabels the graph and preserves its isomorphism class.

For a connected finite graph, transpositions along its original edges generate
every permutation. `exists_edgeSwap_word` gives the finite-word form needed for
irreducibility of the stochastic process.
-/

namespace PeerSwap

variable {V : Type*}

/-- Move each original vertex `v` to `σ v`. -/
def relabel (G : SimpleGraph V) (σ : Equiv.Perm V) : SimpleGraph V :=
  G.map σ.toEmbedding

/-- Relabeling is an isomorphism, so every graph property invariant under
isomorphism is preserved by PeerSwap. -/
def relabelIso (G : SimpleGraph V) (σ : Equiv.Perm V) : G ≃g relabel G σ :=
  SimpleGraph.Iso.map σ G

@[simp] theorem relabel_one (G : SimpleGraph V) : relabel G 1 = G := by
  exact SimpleGraph.map_id G

@[simp] theorem relabel_adj_apply (G : SimpleGraph V) (σ : Equiv.Perm V) (u v : V) :
    (relabel G σ).Adj (σ u) (σ v) ↔ G.Adj u v :=
  SimpleGraph.map_adj_apply

/-- Sequential relabeling composes the two vertex permutations. -/
theorem relabel_relabel (G : SimpleGraph V) (σ τ : Equiv.Perm V) :
    relabel (relabel G σ) τ = relabel G (τ * σ) := by
  change (G.map σ.toEmbedding).map τ.toEmbedding = G.map (τ * σ).toEmbedding
  rw [SimpleGraph.map_map]
  rfl

theorem relabel_connected_iff (G : SimpleGraph V) (σ : Equiv.Perm V) :
    (relabel G σ).Connected ↔ G.Connected :=
  (relabelIso G σ).connected_iff.symm

variable [DecidableEq V]

/-- The graph produced by one atomic exchange of vertex identities. An algorithm
step additionally requires that `u` and `v` be adjacent in the current graph. -/
def atomicSwap (G : SimpleGraph V) (u v : V) : SimpleGraph V :=
  relabel G (Equiv.swap u v)

def atomicSwapIso (G : SimpleGraph V) (u v : V) : G ≃g atomicSwap G u v :=
  relabelIso G (Equiv.swap u v)

@[simp] theorem atomicSwap_involutive (G : SimpleGraph V) (u v : V) :
    atomicSwap (atomicSwap G u v) u v = G := by
  simp [atomicSwap, relabel_relabel]

theorem atomicSwap_connected_iff (G : SimpleGraph V) (u v : V) :
    (atomicSwap G u v).Connected ↔ G.Connected :=
  relabel_connected_iff G (Equiv.swap u v)

omit [DecidableEq V] in
/-- An original edge remains an edge between its current endpoint locations. -/
theorem edge_present_after_relabel (G : SimpleGraph V) (σ : Equiv.Perm V)
    {u v : V} (h : G.Adj u v) : (relabel G σ).Adj (σ u) (σ v) :=
  (relabel_adj_apply G σ u v).2 h

/-- Exchanging a current edge is right multiplication by its original edge
transposition in the permutation state space. -/
theorem atomicSwap_relabel (G : SimpleGraph V) (σ : Equiv.Perm V) (u v : V) :
    atomicSwap (relabel G σ) (σ u) (σ v) = relabel G (σ * Equiv.swap u v) := by
  rw [atomicSwap, relabel_relabel]
  congr 1
  ext x
  exact σ.injective.swap_apply u v x

/-- The allowed generators, indexed by edges of the original graph. -/
def edgeSwaps (G : SimpleGraph V) : Set (Equiv.Perm V) :=
  {σ | ∃ u v, G.Adj u v ∧ σ = Equiv.swap u v}

theorem edgeSwap_mem (G : SimpleGraph V) {u v : V} (h : G.Adj u v) :
    Equiv.swap u v ∈ edgeSwaps G :=
  ⟨u, v, h, rfl⟩

theorem edgeSwap_isSwap (G : SimpleGraph V) {σ : Equiv.Perm V}
    (hσ : σ ∈ edgeSwaps G) : σ.IsSwap := by
  obtain ⟨u, v, huv, rfl⟩ := hσ
  exact ⟨u, v, huv.ne, rfl⟩

theorem edgeSwap_inv (G : SimpleGraph V) {σ : Equiv.Perm V}
    (hσ : σ ∈ edgeSwaps G) : σ⁻¹ = σ := by
  obtain ⟨u, v, _, rfl⟩ := hσ
  exact Equiv.swap_inv u v

/-- A walk expresses the transposition of its endpoints using its edge
transpositions, even when the walk visits vertices more than once. -/
theorem swap_mem_edgeClosure_of_walk (G : SimpleGraph V) {u v : V}
    (p : G.Walk u v) : Equiv.swap u v ∈ Submonoid.closure (edgeSwaps G) := by
  induction p with
  | nil =>
    rw [Equiv.swap_self]
    exact (Submonoid.closure (edgeSwaps G)).one_mem
  | cons huv p ih =>
    exact SubmonoidClass.swap_mem_trans (Submonoid.closure (edgeSwaps G))
      (Submonoid.subset_closure (edgeSwap_mem G huv)) ih

theorem swap_mem_edgeClosure (G : SimpleGraph V) (hG : G.Preconnected) (u v : V) :
    Equiv.swap u v ∈ Submonoid.closure (edgeSwaps G) := by
  obtain ⟨p⟩ := hG u v
  exact swap_mem_edgeClosure_of_walk G p

/-- For a finite connected graph, adjacent vertex transpositions generate the
entire symmetric group. This is stronger than mere reachability of vertices. -/
theorem edgeSwaps_generate [Finite V] (G : SimpleGraph V) (hG : G.Connected) :
    Submonoid.closure (edgeSwaps G) = ⊤ := by
  apply top_unique
  rw [← Equiv.Perm.mclosure_isSwap]
  apply Submonoid.closure_le.2
  intro σ hσ
  obtain ⟨u, v, _, rfl⟩ := hσ
  exact swap_mem_edgeClosure G hG.preconnected u v

/-- Every permutation has a finite word of allowed edge transpositions. -/
theorem exists_edgeSwap_word [Finite V] (G : SimpleGraph V) (hG : G.Connected)
    (σ : Equiv.Perm V) :
    ∃ l : List (Equiv.Perm V), (∀ τ ∈ l, τ ∈ edgeSwaps G) ∧ l.prod = σ := by
  apply Submonoid.exists_list_of_mem_closure
  rw [edgeSwaps_generate G hG]
  trivial

end PeerSwap
