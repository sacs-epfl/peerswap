import bisect
import heapq
import logging
import random
import statistics
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
        self.latencies: Dict[Tuple[int, int], float] = {}
        self.node_to_latency: List[int] = []
        self.num_sites: int = 0
        self.logger = logging.getLogger(self.__class__.__name__)

        self.locked_for_count: Dict[Tuple[int, int], int] = {}
        self.swap_started: Dict[Tuple[int, int], float] = {}
        self.swap_durations: List[float] = []

        heapq.heapify(self.events)

        self.G = G or random_regular_graph(self.args.k, self.args.nodes, seed=self.args.seed)

        # Create peers
        for peer_ind in range(self.args.nodes):
            nbs = set(self.G.neighbors(peer_ind))
            peer = Peer(peer_ind, nbs)
            self.peers.append(peer)

        if self.args.latencies_file:
            self.read_latencies()
            self.node_to_latency = list(range(self.args.nodes))
            r = random.Random(args.seed)
            r.shuffle(self.node_to_latency)
        else:
            # Generate latencies
            self.logger.info("Generating random latencies")
            for from_peer_ind in range(self.args.nodes):
                for to_peer_ind in range(self.args.nodes):
                    if from_peer_ind == to_peer_ind:
                        self.latencies[(from_peer_ind, to_peer_ind)] = 0
                    else:
                        self.latencies[(from_peer_ind, to_peer_ind)] = random.random() * self.args.max_network_latency

        # Statistics
        self.nb_frequencies: List[int] = [0] * self.args.nodes
        self.node_to_track: int = 0

        np.random.seed()  # Make sure our runs are random

    def add_to_lock_count(self, swap: Tuple[int, int]):
        if swap not in self.locked_for_count:
            self.locked_for_count[swap] = 0
        self.locked_for_count[swap] += 1

    def remove_from_lock_count(self, swap: Tuple[int, int], success: bool):
        self.locked_for_count[swap] -= 1
        if self.args.track_swap_times and self.locked_for_count[swap] == 0 and success:
            # The swap is done - record its duration
            swap_time: float = self.current_time - self.swap_started[swap]
            self.swap_durations.append(swap_time)
            self.locked_for_count.pop(swap)

    def read_latencies(self):
        """
        If specified in the settings, add latencies between the endpoints.
        """
        with open(self.args.latencies_file) as latencies_file:
            for from_node_ind, line in enumerate(latencies_file.readlines()):
                line_latencies: List[float] = [float(l) for l in line.strip().split(",")]
                self.num_sites = len(line_latencies)
                for to_node_ind, latency in enumerate(line_latencies):
                    norm_latency: float = max(latency / 1000, 0)
                    self.latencies[(from_node_ind, to_node_ind)] = norm_latency

        avg_latency: float = statistics.mean(self.latencies.values())
        max_latency: float = max(self.latencies.values())
        self.logger.info("Read latency matrix with %d sites! Avg latency: %f, max: %f" % (self.num_sites, avg_latency, max_latency))

    def get_latency(self, from_peer: int, to_peer: int) -> float:
        if self.args.latencies_file:
            from_peer_site: int = self.node_to_latency[from_peer] % self.num_sites
            to_peer_site: int = self.node_to_latency[to_peer] % self.num_sites
            return self.latencies[(from_peer_site, to_peer_site)]
        return self.latencies[(from_peer, to_peer)]

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
        self.logger.debug("Handling event: %s" % event)
        if event.type == CLOCK_FIRE:
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
        self.logger.debug("Starting swap: %s", str(peer_tup))

        # Check if one of the peers is working on a previous clock fire of the same edge - if so, ignore
        swap_is_ongoing: bool = False
        for peer in self.peers:
            if peer.locked_for_swap == peer_tup:
                swap_is_ongoing = True
                self.failed_swaps += 2
                self.logger.info("Ignoring swap %s because it's already going on", str(peer_tup))
                break

        # Check if both peers are available for the swap - if not, ignore it
        both_available = not self.peers[peer_tup[0]].is_locked() and not self.peers[peer_tup[1]].is_locked()

        if not swap_is_ongoing and both_available:
            self.swap_started[peer_tup] = self.current_time
            for peer_ind in peer_tup:
                peer: Peer = self.peers[peer_ind]
                peer.ongoing_swap = peer_tup
                peer.other_ready_for_swap = False
                peer.ready_for_swap = False
                peer.other_nbs = False
                peer.lock(peer_tup, event.time)
                self.add_to_lock_count(peer_tup)
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

    def get_num_locked_peers(self) -> int:
        locked: int = 0
        for peer in self.peers:
            if peer.is_locked():
                locked += 1
        return locked

    def handle_lock_request(self, event: Event):
        from_peer_ind: int = event.data["from"]
        to_peer_ind: int = event.data["to"]
        edge: Tuple[int, int] = event.data["edge"]
        swap_nb: int = edge[0] if edge[0] != from_peer_ind else edge[1]
        me: Peer = self.peers[to_peer_ind]
        self.logger.debug("Peer %d received LOCK_REQUEST from %d for swap %s", me.index,
                          from_peer_ind, str(edge))

        if from_peer_ind not in me.nbs:
            # Looks like the sending peer is not a neighbour, which might happen if there is an inconsistency in the
            # graph. Just make the swap fail to give the network time to reconcile.
            self.logger.debug("Peer %d will not lock for swap %s because %d is not a nb", me.index, str(event.data["edge"]), from_peer_ind)
            data = {"from": to_peer_ind, "to": from_peer_ind, "success": False, "swap": event.data["edge"], "adjacent": False}
            lock_response_event: Event = Event(self.current_time + self.get_latency(to_peer_ind, from_peer_ind), LOCK_RESPONSE, data)
            self.schedule(lock_response_event)
            return

        if from_peer_ind in me.nbs and swap_nb in me.nbs:
            # Looks like nothing changes for us
            self.logger.debug("Peer %d will not lock for swap %s because of adjacency", me.index, str(event.data["edge"]))
            data = {"from": to_peer_ind, "to": from_peer_ind, "success": False, "swap": event.data["edge"], "adjacent": True}
            lock_response_event: Event = Event(self.current_time + self.get_latency(to_peer_ind, from_peer_ind), LOCK_RESPONSE, data)
            self.schedule(lock_response_event)
            return

        if me.is_locked():
            # Bummer, we have to politely refuse the lock
            self.logger.debug("Peer %d will not lock - already locked for swap %s", me.index, str(me.locked_for_swap))
            data = {"from": to_peer_ind, "to": from_peer_ind, "success": False, "swap": event.data["edge"], "adjacent": False}
            lock_response_event: Event = Event(self.current_time + self.get_latency(to_peer_ind, from_peer_ind), LOCK_RESPONSE, data)
            self.schedule(lock_response_event)
            return

        # Otherwise, lock and let the sender peer know
        self.logger.debug("Peer %d will lock for swap %s", me.index, str(event.data["edge"]))
        me.lock(event.data["edge"], event.time)
        self.add_to_lock_count(event.data["edge"])
        data = {"from": to_peer_ind, "to": from_peer_ind, "success": True, "swap": event.data["edge"], "adjacent": False}
        lock_response_event: Event = Event(self.current_time + self.get_latency(to_peer_ind, from_peer_ind), LOCK_RESPONSE, data)
        self.schedule(lock_response_event)

    def handle_lock_response(self, event: Event):
        from_peer_ind: int = event.data["from"]
        to_peer_ind: int = event.data["to"]
        me: Peer = self.peers[to_peer_ind]
        self.logger.debug("Peer %d received LOCK_RESPONSE from %d for swap %s", me.index, from_peer_ind, str(event.data["swap"]))

        if me.ongoing_swap != event.data["swap"]:
            # It could be that a lock response is received after another peer already responded negatively
            self.logger.warning("Peer %d received LOCK_RESPONSE for failed swap %s", me.index, str(event.data["swap"]))
            return

        if not event.data["success"]:
            if event.data["adjacent"]:
                me.adjacent_nbs.add(from_peer_ind)
            else:
                # Oh no, one peer couldn't lock! Abort everything
                for nb_peer_ind in me.lock_responses_sent:
                    data = {"from": me.index, "to": nb_peer_ind, "swap": me.ongoing_swap}
                    unlock_event: Event = Event(self.current_time + self.get_latency(me.index, nb_peer_ind), UNLOCK, data)
                    self.schedule(unlock_event)

                data = {"from": to_peer_ind, "to": me.get_edge_nb(), "swap": me.ongoing_swap}
                swap_fail_event = Event(self.current_time + self.get_latency(me.index, me.get_edge_nb()), SWAP_FAIL, data)
                self.schedule(swap_fail_event)

                me.unlock(event.time)
                self.remove_from_lock_count(event.data["swap"], False)
                me.reset_from_swap()

                return

        # Otherwise, proceed with the swap by letting the other party know about our readyness
        me.lock_responses_received += 1
        if me.lock_responses_received == len(me.lock_responses_sent):
            me.ready_for_swap = True

            # Send the swap message to the other end of the activated edge
            edge_nb_ind: int = me.get_edge_nb()
            data = {"from": to_peer_ind, "to": edge_nb_ind, "swap": me.ongoing_swap,
                    "nbs": {nb for nb in me.nbs if nb not in me.ongoing_swap}}
            swap_event = Event(self.current_time + self.get_latency(to_peer_ind, edge_nb_ind), SWAP, data)
            self.schedule(swap_event)

            if me.other_ready_for_swap:
                self.do_swap(me)

    def handle_swap(self, event: Event):
        # We received a swap message.
        from_peer_ind: int = event.data["from"]
        to_peer_ind: int = event.data["to"]
        me: Peer = self.peers[to_peer_ind]
        swap: Tuple[int, int] = event.data["swap"]
        me.other_ready_for_swap = True
        me.other_nbs = event.data["nbs"]
        self.logger.debug("Peer %d received SWAP from %d", me.index, from_peer_ind)

        if me.ongoing_swap == swap and me.ready_for_swap:
            self.do_swap(me)

    def handle_swap_fail(self, event: Event):
        from_peer_ind: int = event.data["from"]
        to_peer_ind: int = event.data["to"]
        swap: int = event.data["swap"]
        me: Peer = self.peers[to_peer_ind]
        self.logger.debug("Peer %d received SWAP_FAIL from %d for swap %s", me.index, from_peer_ind, str(swap))
        for nb_peer_ind in me.lock_responses_sent:
            data = {"from": me.index, "to": nb_peer_ind, "swap": swap}
            unlock_event: Event = Event(self.current_time + self.get_latency(me.index, nb_peer_ind), UNLOCK, data)
            self.schedule(unlock_event)

        if me.locked_for_swap == event.data["swap"]:
            me.unlock(event.time)
            self.remove_from_lock_count(event.data["swap"], False)
            me.reset_from_swap()

        self.failed_swaps += 1

    def do_swap(self, me: Peer):
        # Send replace messages to the neighbors
        recipients: List[int] = [nb_peer_ind for nb_peer_ind in me.nbs if nb_peer_ind not in me.ongoing_swap and nb_peer_ind not in me.adjacent_nbs]
        self.logger.debug("Peer %d sending REPLACE to %s", me.index, recipients)
        for nb_peer_ind in recipients:
            data = {"from": me.index, "to": nb_peer_ind, "replace": me.get_edge_nb(), "swap": me.ongoing_swap}
            replace_event: Event = Event(self.current_time + self.get_latency(me.index, nb_peer_ind), REPLACE, data)
            self.schedule(replace_event)

        # Finally, replace your neighbors
        me.nbs = me.other_nbs
        me.nbs.add(me.get_edge_nb())
        me.unlock(self.current_time)
        self.remove_from_lock_count(me.ongoing_swap, True)
        me.reset_from_swap()
        self.swaps += 1

    def handle_replace(self, event: Event):
        from_peer_ind: int = event.data["from"]
        to_peer_ind: int = event.data["to"]
        replace_ind: int = event.data["replace"]
        swap: Tuple[int, int] = event.data["swap"]
        me: Peer = self.peers[to_peer_ind]
        self.logger.debug("Peer %d received REPLACE from %d for swap %s (replace: %d)",
                          me.index, from_peer_ind, swap, replace_ind)

        if not me.is_locked():
            assert False, "Not locked!"

        if me.locked_for_swap != swap:
            assert False, "Received replace for wrong swap: %s vs %s" % (str(me.locked_for_swap), swap)

        success: bool = False
        if from_peer_ind in me.nbs and event.data["replace"] in me.nbs:
            pass
        else:
            edge: Tuple[int, int] = tuple(sorted([from_peer_ind, to_peer_ind]))
            assert edge in self.edge_to_clocks, "Edge %s does not exist in clock table" % str(edge)
            clock_ind: int = self.edge_to_clocks.pop(edge)
            new_edge: Tuple[int, int] = tuple(sorted([to_peer_ind, replace_ind]))
            self.edge_to_clocks[new_edge] = clock_ind
            self.clock_to_peers[clock_ind] = new_edge
            success = True

            me.nbs.remove(from_peer_ind)
            me.nbs.add(event.data["replace"])
        me.unlock(event.time)
        self.remove_from_lock_count(event.data["swap"], success)

    def handle_unlock(self, event: Event):
        from_peer_ind: int = event.data["from"]
        to_peer_ind: int = event.data["to"]
        me: Peer = self.peers[to_peer_ind]
        swap: Tuple[int, int] = event.data["swap"]
        self.logger.debug("Peer %d received UNLOCK from %d for swap %s", me.index, from_peer_ind, str(swap))

        if me.locked_for_swap == swap:
            me.unlock(event.time)
            self.remove_from_lock_count(swap, False)
        else:
            self.logger.warning("Peer %d not unlocking as it's in another swap %s", me.index, me.locked_for_swap)

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

        self.swaps /= 2
        self.failed_swaps /= 2
