#!/bin/bash

CPUS=50
N=50
K=4
T_values=(1 2 4)

for T in "${T_values[@]}"
do
  echo "Running with T=$T"
  python3 main.py --runs-per-process 423752 --nodes $N --k $K --time-per-run $T --cpus $CPUS
done