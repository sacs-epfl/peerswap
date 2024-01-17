from math import log

import networkx as nx
import numpy as np

# Create a k-regular graph, for example a 3-regular graph
k = 4
n = 64  # number of nodes
epsilon = 1 / 100


def compute_spectral_expansion(G):
    # Compute the adjacency matrix of the graph
    A = nx.adjacency_matrix(G).toarray()

    # Compute the eigenvalues of the adjacency matrix
    eigenvalues = np.linalg.eigvals(A)

    eigenvalues = sorted(eigenvalues, key=abs, reverse=True)

    # Remove the largest, absolute eigenvalue
    eigenvalues = eigenvalues[1:]
    lambda_max = abs(eigenvalues[0])
    return lambda_max

expansions = []
for seed in range(1, 1000000):
    G = nx.random_regular_graph(k, n, seed=seed)

    if seed % 10000 == 0:
        print("Computed %d seeds..." % seed)

    # Compute T
    l = compute_spectral_expansion(G)
    expansions.append((l, seed))
    #print("Spectral expansion: %f" % l)
    # T = log(n / epsilon, 2) / (k * l)
    # print("T: %f" % T)

samples = 100
expansions = sorted(expansions)
step = (len(expansions) - 1) / (samples - 1)
selected_expansions = [expansions[int(i * step)] for i in range(samples)]
with open("spectral_expansion_graphs.csv", "w") as out_file:
    out_file.write("seed,lambda\n")
    for l, seed in selected_expansions:
        out_file.write("%d,%f\n" % (seed, l))
