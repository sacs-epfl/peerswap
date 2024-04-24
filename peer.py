from typing import Set, Optional, List, Tuple


class Peer:

    def __init__(self, index: int, nbs: Set[int]):
        self.index = index
        self.nbs: Set[int] = nbs
        self.locked_by: Optional[Tuple[int, int]] = None

        self.ongoing_swap: Optional[Tuple[int, int]] = None
        self.other_nbs: Optional[Set[int]] = None
        self.ready_for_swap: bool = False
        self.other_ready_for_swap: bool = False
        self.lock_responses_sent: int = 0
        self.lock_responses_received: int = 0

    def is_locked(self) -> bool:
        return self.locked_by is not None

    def lock(self, locked_by: Tuple[int, int]):
        self.locked_by = locked_by

    def unlock(self):
        self.locked_by = None

    def reset_from_swap(self):
        self.ongoing_swap = None
        self.other_nbs = None
        self.ready_for_swap = False
        self.other_ready_for_swap = False
        self.lock_responses_sent = 0
        self.lock_responses_received = 0

    def get_edge_nb(self) -> Optional[int]:
        if not self.ongoing_swap:
            return None

        return self.ongoing_swap[0] if self.ongoing_swap[0] != self.index else self.ongoing_swap[1]
