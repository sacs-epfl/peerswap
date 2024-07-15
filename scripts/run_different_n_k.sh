#!/bin/bash

CPUS=50

# Arrays for N, K, and runs-per-process
N_values=(8 16 32 64)
K_values=(3 4 5 5)
runs_per_process_values=(70 2730 339822 14057694) # Corresponding runs-per-process values

# Loop through the indices of the arrays
for i in "${!N_values[@]}"
do
    N=${N_values[$i]}
    K=${K_values[$i]}
    RPP=${runs_per_process_values[$i]}  # Get the runs-per-process value for the current combination

    echo "Running with N=$N, K=$K, runs-per-process=$RPP"
    python3 main.py --runs-per-process $RPP --nodes $N --k $K --time-per-run $K --cpus $CPUS
done