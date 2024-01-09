from functools import total_ordering
from typing import NamedTuple


@total_ordering
class Event(NamedTuple):
    time: float
    from_vertex: int
    to_vertex: int
