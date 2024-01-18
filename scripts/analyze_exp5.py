import csv

import networkx as nx
import numpy as np
from scipy.stats import kstest


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


SEEDS = [451221, 96032]
N = 64
K = 4
synthetic_freqs = []
ks_results_file = "../data/exp5/ks_results.csv"
with open(ks_results_file, "w") as out_file:
    out_file.write("seed,lambda,tracked_node,distance,pvalue\n")


# Load synthetic data
print("Loading synthetic data")
with open("../data/exp4/n_64_k_4_t_4_s_42_synthetic/nbh_frequencies.csv") as in_file:
    reader = csv.reader(in_file)
    next(reader)
    for row in reader:
        synthetic_freqs.append(int(row[-1]))

freqs = []
for seed in SEEDS:
    G = nx.random_regular_graph(K, N, seed=seed)
    l = compute_spectral_expansion(G)
    print("Considering seed %d (lambda: %f)" % (seed, l))
    with open("../data/exp5/n_64_k_4_t_4_s_%s/nbh_frequencies.csv" % seed) as in_file:
        rows_read = 0
        reader = csv.reader(in_file)
        next(reader)  # Skip the header
        node_evaluated = 0
        for row in reader:
            if rows_read % 100000 == 0:
                print("Read %d rows..." % rows_read)

            tracked_node = int(row[5])
            if tracked_node != node_evaluated:
                node_evaluated = tracked_node
                kstest_results = kstest(synthetic_freqs, freqs)
                freqs = []
                with open(ks_results_file, "a") as results_file:
                    results_file.write("%d,%f,%d,%f,%f\n" % (seed, l, tracked_node, kstest_results.statistic, kstest_results.pvalue))

            freq = int(row[-1])
            freqs.append(freq)
            rows_read += 1
