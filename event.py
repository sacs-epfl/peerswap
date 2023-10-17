from functools import total_ordering
from typing import NamedTuple


@total_ordering
class Event(NamedTuple):
    time: float
    from_vertex: int
    to_vertex: int

    def __lt__(self, other: 'Event') -> bool:
        # Compare primarily by time, then by client_id and action for tiebreakers.
        # This logic can be adjusted based on the intended ordering.
        return self.time < other.time
