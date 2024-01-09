"""
This script computes the total number of unique neighbourhoods, given a total network size and in/out-degree.
"""
import math

N = 50
K = 4

nbs = math.comb(N - 1, K)
print("Neighbourhoods (N = %d, K = %d): %d" % (N, K, nbs))
