#!/bin/bash

# Maximum number of concurrent jobs
max_jobs=16

# Array to hold all the commands
declare -a commands

# Populate the commands array
for ((s=42; s <= 62; s++ ))
do
    for ((t=1; t <= 4; t++ ))
    do
        # Add command to the array
        commands+=("prun -t 24:00:00 -np 1 -o out.log bash run.sh 64 4 $t 60 992775 $s")
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