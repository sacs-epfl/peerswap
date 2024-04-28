from typing import Set, Optional, List, Tuple


class Peer:

    def __init__(self, index: int, nbs: Set[int]):
        self.index = index
        self.nbs: Set[int] = nbs
        self.locked_for_swap: Optional[Tuple[int, int]] = None

        self.ongoing_swap: Optional[Tuple[int, int]] = None
        self.other_nbs: Optional[Set[int]] = None
        self.adjacent_nbs: Set[int] = set()
        self.ready_for_swap: bool = False
        self.other_ready_for_swap: bool = False
        self.lock_responses_sent: List[int] = []
        self.lock_responses_received: int = 0

    def is_locked(self) -> bool:
        return self.locked_for_swap is not None

    def in_swap(self) -> bool:
        return self.ongoing_swap is not None

    def lock(self, edge: Tuple[int, int]):
        self.locked_for_swap = edge

    def unlock(self):
        self.locked_for_swap = None

    def reset_from_swap(self):
        self.ongoing_swap = None
        self.other_nbs = None
        self.ready_for_swap = False
        self.other_ready_for_swap = False
        self.lock_responses_sent = []
        self.lock_responses_received = 0
        self.adjacent_nbs = set()

    def get_edge_nb(self) -> Optional[int]:
        if not self.ongoing_swap:
            return None

        return self.ongoing_swap[0] if self.ongoing_swap[0] != self.index else self.ongoing_swap[1]
