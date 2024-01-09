import os
import random
from collections import defaultdict

N = 50
K = 4
T = 1
RUNS = 50000000

freqs = defaultdict(lambda: 0)
for run in range(RUNS):
    if run % 1000000 == 0:
        print("Generated %d neighbourhoods..." % run)

    nbh = tuple(sorted(random.sample(range(0, N - 1), K)))
    freqs[nbh] += 1

# Write away the frequencies
with open(os.path.join("data", "n_%d_k_%d_t_%g" % (N, K, T), "nbh_frequencies_synthetic.csv"), "w") as out_file:
    out_file.write("algorithm,nodes,k,time_per_run,nbh,freq\n")
    for nbh, freq in freqs.items():
        nbh_str = "-".join(["%d" % peer for peer in nbh])
        out_file.write("synthetic,%d,%d,%g,%s,%d\n" % (N, K, T, nbh_str, freq))
