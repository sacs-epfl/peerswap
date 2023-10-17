import heapq
import os
import time
from typing import List, Dict

import numpy as np
from networkx import random_regular_graph

from event import Event


class Simulation:

    POISSON_RATE = 1.0       # The rate at which edges are "activated" for a swap
    EXPERIMENT_TIME = 14400  # The duration of the experiment, in seconds
    NODES = 100              # The total number of nodes in the experiment
    K = 4                    # The degree of the k-regular graph
    SEED = 42                # Experiment seed
    NODE_TO_TRACK = 0        # The node we are tracking throughout the experiment

    def __init__(self):
        self.current_time: float = 0
        self.events: List[Event] = []
        self.swaps: int = 0
        self.nb_frequencies: List[int] = [0] * self.NODES
        heapq.heapify(self.events)

        self.vertex_to_node_map: Dict[int, int] = {}
        self.node_to_vertex_map: Dict[int, int] = {}
        for i in range(self.NODES):
            self.vertex_to_node_map[i] = i
            self.node_to_vertex_map[i] = i

        # Create the topology
        self.G = random_regular_graph(self.K, self.NODES, self.SEED)

    def generate_inter_arrival_times(self):
        return np.random.exponential(scale=1 / self.POISSON_RATE)

    def schedule(self, event: Event):
        heapq.heappush(self.events, event)

    def register_neighbours_of_tracked_node(self):
        for nb_vertex in self.G.neighbors(self.node_to_vertex_map[self.NODE_TO_TRACK]):
            nb_peer = self.vertex_to_node_map[nb_vertex]
            self.nb_frequencies[nb_peer] += 1

    def process_event(self, event: Event):
        #print("[t=%.2f] Activating edge (%d - %d)" % (self.current_time, event.from_vertex, event.to_vertex))

        # Swap nodes
        node_at_from_edge: int = self.vertex_to_node_map[event.from_vertex]
        node_at_to_edge: int = self.vertex_to_node_map[event.to_vertex]
        self.vertex_to_node_map[event.from_vertex] = node_at_to_edge
        self.vertex_to_node_map[event.to_vertex] = node_at_from_edge
        self.node_to_vertex_map[node_at_from_edge] = event.to_vertex
        self.node_to_vertex_map[node_at_to_edge] = event.from_vertex
        if node_at_from_edge == self.NODE_TO_TRACK or node_at_to_edge == self.NODE_TO_TRACK:
            self.register_neighbours_of_tracked_node()
        self.swaps += 1

        # Schedule new edge activation
        delay = self.generate_inter_arrival_times()
        event = Event(self.current_time + delay, event.from_vertex, event.to_vertex)
        self.schedule(event)

    def run(self):
        # Create the initial events in the queue, for each edge
        for edge in self.G.edges:
            delay = self.generate_inter_arrival_times()
            event = Event(delay, *edge)
            self.schedule(event)

        self.register_neighbours_of_tracked_node()

        start_time = time.time()
        while self.events:
            event = heapq.heappop(self.events)
            self.current_time = event.time
            if self.current_time >= self.EXPERIMENT_TIME:
                break
            self.process_event(event)

        print("Experiment took %f s., swaps done: %d" % (time.time() - start_time, self.swaps))

        # Write away the results
        if not os.path.exists("data"):
            os.mkdir("data")

        with open(os.path.join("data", "frequencies.csv"), "w") as out_file:
            out_file.write("node,freq\n")
            for node_id, freq in enumerate(sorted(self.nb_frequencies)):
                if node_id == self.NODE_TO_TRACK:
                    continue
                out_file.write("%d,%d\n" % (node_id, freq))
