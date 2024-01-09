import networkx as nx
import numpy as np

# Create a k-regular graph, for example a 3-regular graph
k = 3
n = 128  # number of nodes
G = nx.random_regular_graph(k, n, seed=42)

# Compute the adjacency matrix of the graph
A = nx.adjacency_matrix(G).toarray()

# Compute the eigenvalues of the adjacency matrix
eigenvalues = np.linalg.eigvals(A)

eigenvalues = sorted(eigenvalues, key=abs, reverse=True)

# Remove the largest, absolute eigenvalue
eigenvalues = eigenvalues[1:]
lambda_max = abs(eigenvalues[0])

print("Eigenvalues of the adjacency matrix:", eigenvalues)
print("Spectral expansion (lambda):", lambda_max)
