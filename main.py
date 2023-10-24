import csv
import multiprocessing
import os
import time
from multiprocessing import Process
from typing import List

from args import get_args
from simulation import Simulation


def run(process_index: int, args):
    total_swaps: int = 0
    nb_frequencies: List[int] = [0] * args.nodes
    start_time = time.time()
    for run_index in range(args.runs_per_process):
        simulation = Simulation(args)
        simulation.run()
        total_swaps += simulation.swaps

        for node_ind in range(args.nodes):
            nb_frequencies[node_ind] += simulation.nb_frequencies[node_ind]

    print("Experiment took %f s., swaps done: %d" % (time.time() - start_time, total_swaps))

    # Write away the results
    if not os.path.exists("data"):
        os.mkdir("data")

    with open(os.path.join("data", "frequencies_%d.csv" % process_index), "w") as out_file:
        out_file.write("node,freq\n")
        for node_id, freq in enumerate(nb_frequencies):
            out_file.write("%d,%d\n" % (node_id, freq))


if __name__ == "__main__":
    args = get_args()

    # How many CPUs do we have?
    num_cpus = multiprocessing.cpu_count()
    cpus_to_use = num_cpus - 1  # Don't be greedy and use all the CPUs :)

    print("Will start experiments on %d CPUs..." % cpus_to_use)

    processes = []
    for process_index in range(cpus_to_use):
        p = Process(target=run, args=(process_index, args))
        p.start()
        processes.append(p)

    for p in processes:
        p.join()

    print("Processes done - combining results")
    merged_frequencies: List[int] = [0] * args.nodes
    input_files = [os.path.join("data", "frequencies_%d.csv" % process_index) for process_index in range(cpus_to_use)]
    for input_file in input_files:
        with open(input_file, "r") as in_file:
            reader = csv.reader(in_file)
            next(reader)  # Skip the header
            for row in reader:
                node_id, freq = int(row[0]), int(row[1])
                merged_frequencies[node_id] += freq

    output_file_name = os.path.join("data", "frequencies.csv")
    with open(output_file_name, "w") as out_file:
        out_file.write("node,freq\n")
        for node_ind, freq in enumerate(merged_frequencies):
            out_file.write("%d,%d\n" % (node_ind, freq))
