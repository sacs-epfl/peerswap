from typing import Dict


CLOCK_FIRE = "clock_fire"
LOCK_REQUEST = "lock_request"
LOCK_RESPONSE = "lock_response"
UNLOCK = "unlock"
SWAP = "swap"
SWAP_FAIL = "swap_fail"
REPLACE = "replace"
STOP_CLOCKS = "stop_clocks"
STOP = "stop"


class Event:
    COUNTER = 0

    def __init__(self, time: float, type: str, data: Dict = None):
        self.time: float = time
        self.index = Event.COUNTER
        self.type: str = type
        self.data: Dict = data or {}

        Event.COUNTER += 1

    def __str__(self):
        return "Event(%f, %s, %s)" % (self.time, self.type, self.data)
