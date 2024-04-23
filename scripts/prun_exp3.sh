#!/bin/bash

# Maximum number of concurrent jobs
nodes=(1024 2048 4096 8192 16384)
k=5
max_jobs=16
cpus=60
runs_per_proc=(342 683 1366 2731 5462)

# Array to hold all the commands
declare -a commands

# Populate the commands array
for ((s=43; s <= 46; s++ ))
do
    for i in "${!nodes[@]}"
    do
        n=${nodes[$i]}
        rpp=${runs_per_proc[$i]}
        commands+=("prun -t 12:00:00 -np 1 -o data/out_${s}_${t}.log bash run.sh $n $k $k $cpus $rpp $s")
    done
done

# Function to check and run the next command if a slot is available
run_next_command() {
    if [[ ${#commands[@]} -gt 0 ]]; then
        # Fetch the first command
        local cmd="${commands[0]}"

        # Remove the first command from the array
        commands=("${commands[@]:1}")
        echo "Running command: {$cmd}"

        # Run the command in the background
        eval "$cmd" &
    fi
}

# Main loop to manage job execution
while [[ ${#commands[@]} -gt 0 || $(jobs -r | wc -l) -gt 0 ]]; do
    # Fill up the job slots to the maximum
    while [[ $(jobs -r | wc -l) -lt $max_jobs && ${#commands[@]} -gt 0 ]]; do
        run_next_command
    done

    # Wait for any job to finish if the max number of jobs are running
    if [[ $(jobs -r | wc -l) -eq $max_jobs ]]; then
        wait -n
    fi
done

# Wait for any remaining background jobs to complete
wait