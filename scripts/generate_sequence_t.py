"""
Generate a sequence of T when increasing the number of nodes.
"""
from math import log

import networkx as nx

from compute_spectral_expansion import compute_spectral_expansion

epsilon = 1 / 100

with open("../data/sequence_t.csv", "w") as out_file:
    out_file.write("nodes,k,seed,T\n")
    for k in [3, 4, 5]:
        print("k = %d" % k)
        for nodes in [32, 64, 128, 256, 512, 1024, 2048]:
            print("Computing for %d nodes..." % nodes)
            for ind in range(5):
                G = nx.random_regular_graph(k, nodes, seed=42 + ind)
                l = compute_spectral_expansion(G)
                T = log(nodes / epsilon, 2) / (k * l)
                out_file.write("%d,%d,%d,%f\n" % (nodes, k, 42 + ind, T))
