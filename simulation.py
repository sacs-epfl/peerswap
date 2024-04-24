import bisect
import heapq
import random
from collections import defaultdict
from typing import List, Tuple, Dict

import numpy as np
from networkx import random_regular_graph

from event import Event, CLOCK_FIRE, LOCK_REQUEST, LOCK_RESPONSE, SWAP, REPLACE, UNLOCK, SWAP_FAIL
from peer import Peer


class Simulation:

    def __init__(self, args, G = None):
        self.args = args
        self.current_time: float = 0
        self.peers: List[Peer] = []
        self.events: List[Tuple[float, int, Event]] = []
        self.swaps: int = 0
        self.failed_swaps: int = 0
        self.edge_to_clocks: Dict[Tuple[int, int], int] = {}
        self.clock_to_peers: Dict[int, Tuple[int, int]] = {}
        self.latencies = {}

        heapq.heapify(self.events)

        self.G = G or random_regular_graph(self.args.k, self.args.nodes, seed=self.args.seed)

        # Create peers
        for peer_ind in range(self.args.nodes):
            nbs = set(self.G.neighbors(peer_ind))
            peer = Peer(peer_ind, nbs)
            self.peers.append(peer)

        # Generate latencies
        for from_peer_ind in range(self.args.nodes):
            for to_peer_ind in range(self.args.nodes):
                if from_peer_ind == to_peer_ind:
                    self.latencies[(from_peer_ind, to_peer_ind)] = 0
                else:
                    self.latencies[(from_peer_ind, to_peer_ind)] = random.random() * 0.1  # Between 0 and 100 ms

        # Statistics
        self.nb_frequencies: List[int] = [0] * self.args.nodes
        self.node_to_track: int = 0

        np.random.seed()  # Make sure our runs are random

    def get_latency(self, from_peer: int, to_peer: int) -> float:
        return 0.001 #self.latencies[(from_peer, to_peer)]

    def generate_inter_arrival_times(self):
        return np.random.exponential(scale=1 / self.args.poisson_rate)

    def schedule(self, event: Event):
        assert event.time >= self.current_time, "Cannot schedule event %s in the past!" % event
        bisect.insort(self.events, (event.time, event.index, event))

    def get_neighbour_of_tracked_nodes(self):
        if not self.args.track_all_nodes:
            return {0: tuple(sorted(list(self.peers[0].nbs)))}
        else:
            res = {}
            for peer_ind in range(self.args.nodes):
                res[peer_ind] = tuple(sorted(list(self.peers[peer_ind].nbs)))
            return res

    def sanity_check(self):
        """
        Check if our current graph is k-regular
        """
        peer_freqs: Dict[int, int] = defaultdict(lambda: 0)
        for peer in self.peers:
            # print("NBS of peer %d: %s" % (peer.index, peer.nbs))
            assert len(peer.nbs) == self.args.k, "Peer %s has %d nbs (%s)" % (peer.index, len(peer.nbs), peer.nbs)
            for nb in peer.nbs:
                peer_freqs[nb] += 1

        # Check how many times each peer appears in
        assert all([freq == self.args.k for freq in peer_freqs.values()]), "Peer frequencies uneven: %s" % peer_freqs

        # Check if all the clocks are consistent
        for clock_ind, clock_peers in self.clock_to_peers.items():
            assert len(clock_peers) == 2
            p1_ind, p2_ind = clock_peers[0], clock_peers[1]
            assert p1_ind in self.peers[p2_ind].nbs, "<CLOCK INC> Peer %d not nb of %d" % (p1_ind, p2_ind)
            assert p2_ind in self.peers[p1_ind].nbs, "<CLOCK INC> Peer %d not nb of %d" % (p2_ind, p1_ind)
            assert clock_peers in self.edge_to_clocks, "Edge %s does not have a clock?!" % str(clock_peers)

    def process_event(self, event: Event):
        print(event)
        if event.type == CLOCK_FIRE:
            # self.sanity_check()
            self.handle_clock_fire(event)
        elif event.type == LOCK_REQUEST:
            self.handle_lock_request(event)
        elif event.type == LOCK_RESPONSE:
            self.handle_lock_response(event)
        elif event.type == SWAP:
            self.handle_swap(event)
        elif event.type == SWAP_FAIL:
            self.handle_swap_fail(event)
        elif event.type == REPLACE:
            self.handle_replace(event)
        elif event.type == UNLOCK:
            self.handle_unlock(event)
        else:
            raise RuntimeError("Unknown event %s" % event.type)

    def handle_clock_fire(self, event: Event):
        # Lock yourself and send out a lock request
        clock_ind: int = event.data["clock"]
        peer_tup: Tuple[int, int] = self.clock_to_peers[clock_ind]
        print("Will start swap: %s" % str(peer_tup))

        num_locked = 0
        for peer in self.peers:
            if peer.is_locked():
                num_locked += 1
        print(num_locked)

        for peer_ind in peer_tup:
            peer: Peer = self.peers[peer_ind]
            if peer.is_locked():
                print("Peer %d already locked, swap failed :(" % peer_ind)

                other_peer_ind: int = peer_tup[0] if peer_tup[0] != peer_ind else peer_tup[1]
                data = {"from": peer.index, "to": other_peer_ind}
                swap_fail_event = Event(self.current_time + self.get_latency(peer.index, other_peer_ind), SWAP_FAIL, data)
                self.schedule(swap_fail_event)

                self.failed_swaps += 1
                continue

            # Peer is not locked - lock it and send out lock requests
            peer.ongoing_swap = peer_tup
            peer.other_ready_for_swap = False
            peer.ready_for_swap = False
            peer.other_nbs = False
            peer.lock(peer_tup)
            peer.lock_responses_received = 0
            for nb_peer_ind in peer.nbs:
                if nb_peer_ind in peer_tup:
                    continue

                data = {"from": peer_ind, "to": nb_peer_ind, "edge": peer.ongoing_swap}
                lock_request_event: Event = Event(self.current_time + self.get_latency(peer_ind, nb_peer_ind), LOCK_REQUEST, data)
                self.schedule(lock_request_event)
                peer.lock_responses_sent.append(nb_peer_ind)

        # Schedule new edge activation
        delay = self.generate_inter_arrival_times()
        event = Event(self.current_time + delay, CLOCK_FIRE, event.data)
        self.schedule(event)

    def handle_lock_request(self, event: Event):
        from_peer_ind: int = event.data["from"]
        to_peer_ind: int = event.data["to"]
        me: Peer = self.peers[to_peer_ind]
        if me.is_locked() and from_peer_ind not in me.locked_by:
            # Bummer, we have to politely refuse the lock
            data = {"from": to_peer_ind, "to": from_peer_ind, "success": False}
            lock_response_event: Event = Event(self.current_time + self.get_latency(to_peer_ind, from_peer_ind), LOCK_RESPONSE, data)
            self.schedule(lock_response_event)
            return

        # Otherwise, lock and let the sender peer know
        me.lock(event.data["edge"])
        data = {"from": to_peer_ind, "to": from_peer_ind, "success": True}
        lock_response_event: Event = Event(self.current_time + self.get_latency(to_peer_ind, from_peer_ind), LOCK_RESPONSE, data)
        self.schedule(lock_response_event)

    def handle_lock_response(self, event: Event):
        from_peer_ind: int = event.data["from"]
        to_peer_ind: int = event.data["to"]
        me: Peer = self.peers[to_peer_ind]

        if not me.in_swap():  # It could be that a lock response is received after another peer already responded negatively
            return

        if not event.data["success"]:
            # Oh no, one peer couldn't lock! Abort everything
            print("Received negative lock response from %d (I'm %d)" % (from_peer_ind, to_peer_ind))
            print("Abort everything: %s" % me.lock_responses_sent)

            for nb_peer_ind in me.lock_responses_sent:
                data = {"from": me.index, "to": nb_peer_ind}
                unlock_event: Event = Event(self.current_time + self.get_latency(me.index, nb_peer_ind), UNLOCK, data)
                self.schedule(unlock_event)

            data = {"from": to_peer_ind, "to": me.get_edge_nb()}
            swap_fail_event = Event(self.current_time + self.get_latency(me.index, me.get_edge_nb()), SWAP_FAIL, data)
            self.schedule(swap_fail_event)

            me.unlock()
            me.reset_from_swap()

            return

        # Otherwise, proceed with the swap by letting the other party know about our readyness
        me.lock_responses_received += 1
        if me.lock_responses_received == len(me.lock_responses_sent):
            # print("All neighbours locked - we can proceed with the swap!")
            me.ready_for_swap = True

            # Send the swap message to the other end of the activated edge
            edge_nb_ind: int = me.get_edge_nb()
            data = {"from": to_peer_ind, "to": edge_nb_ind, "nbs": {nb for nb in me.nbs if nb not in me.ongoing_swap}}
            swap_event = Event(self.current_time + self.get_latency(to_peer_ind, edge_nb_ind), SWAP, data)
            self.schedule(swap_event)

            if me.ready_for_swap and me.other_ready_for_swap:
                self.do_swap(me)

    def handle_swap(self, event: Event):
        # We received a swap message.
        to_peer_ind: int = event.data["to"]
        me: Peer = self.peers[to_peer_ind]
        me.other_ready_for_swap = True
        me.other_nbs = event.data["nbs"]

        if me.ready_for_swap and me.other_ready_for_swap:
            self.do_swap(me)

    def handle_swap_fail(self, event: Event):
        to_peer_ind: int = event.data["to"]
        me: Peer = self.peers[to_peer_ind]
        for nb_peer_ind in me.lock_responses_sent:
            data = {"from": me.index, "to": nb_peer_ind}
            unlock_event: Event = Event(self.current_time + self.get_latency(me.index, nb_peer_ind), UNLOCK, data)
            self.schedule(unlock_event)
        me.unlock()
        me.reset_from_swap()

    def do_swap(self, me: Peer):
        # Send replace messages to the neighbors
        for nb_peer_ind in me.nbs:
            if nb_peer_ind in me.ongoing_swap:
                continue

            data = {"from": me.index, "to": nb_peer_ind, "replace": me.get_edge_nb()}
            replace_event: Event = Event(self.current_time + self.get_latency(me.index, nb_peer_ind), REPLACE, data)
            self.schedule(replace_event)

        # Finally, replace your neighbors
        me.nbs = me.other_nbs
        me.nbs.add(me.get_edge_nb())
        me.unlock()
        me.reset_from_swap()
        self.swaps += 1

    def handle_replace(self, event: Event):
        from_peer_ind: int = event.data["from"]
        to_peer_ind: int = event.data["to"]
        replace_ind: int = event.data["replace"]
        me: Peer = self.peers[to_peer_ind]

        if from_peer_ind in me.nbs and event.data["replace"] in me.nbs:
            pass
        else:
            edge: Tuple[int, int] = tuple(sorted([from_peer_ind, to_peer_ind]))
            assert edge in self.edge_to_clocks, "Edge %s does not exist in clock table" % str(edge)
            clock_ind: int = self.edge_to_clocks.pop(edge)
            new_edge: Tuple[int, int] = tuple(sorted([to_peer_ind, replace_ind]))
            self.edge_to_clocks[new_edge] = clock_ind
            self.clock_to_peers[clock_ind] = new_edge

            me.nbs.remove(from_peer_ind)
            me.nbs.add(event.data["replace"])
        me.unlock()

    def handle_unlock(self, event: Event):
        to_peer_ind: int = event.data["to"]
        me: Peer = self.peers[to_peer_ind]
        me.unlock()

    def run(self):
        # Create the initial events in the queue, for each edge
        for ind, edge in enumerate(self.G.edges):
            sorted_edge: Tuple[int, int] = tuple(sorted(list(edge)))
            self.clock_to_peers[ind] = sorted_edge
            self.edge_to_clocks[sorted_edge] = ind

            delay = self.generate_inter_arrival_times()
            event = Event(delay, CLOCK_FIRE, {"clock": ind})
            self.schedule(event)

        while self.events:
            _, _, event = self.events.pop(0)
            assert event.time >= self.current_time, "New event %s cannot be executed in the past! (current time: %d)" % (str(event), self.current_time)
            self.current_time = event.time
            if self.current_time >= self.args.time_per_run:
                break
            self.process_event(event)

        self.swaps /= 2  # We count every swap twice...
        print("Failed swaps: %d" % self.failed_swaps)
