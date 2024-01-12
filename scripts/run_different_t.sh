#!/bin/bash

CPUS=60
N=64
K=4
T_values=(1 2 3 4)
RUNS_PER_PROCESS=992775

for T in "${T_values[@]}"
do
  echo "Running with T=$T"
  python3 main.py --runs-per-process $RUNS_PER_PROCESS --nodes $N --k $K --time-per-run $T --cpus $CPUS
done