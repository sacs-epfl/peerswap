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


G = nx.random_regular_graph(k, n, seed=42)

# Compute T
l = compute_spectral_expansion(G)
print("Spectral expansion: %f" % l)
T = log(n / epsilon, 2) / (k * l)
print("T: %f" % T)
