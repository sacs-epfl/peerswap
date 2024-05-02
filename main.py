import csv
import logging
import multiprocessing
import os
import shutil
import time
from collections import defaultdict
from multiprocessing import Process
from typing import List, Dict, Tuple

import yappi
from networkx import random_regular_graph

from args import get_args
from simulation import Simulation


def run(process_index: int, args, data_dir):
    if args.profile:
        yappi.start(builtins=True)

    logging.basicConfig(level=getattr(logging, args.log_level))

    total_swaps: int = 0
    failed_swaps: int = 0
    nb_frequencies: Dict[int, List[int]] = {}
    nbh_frequencies: Dict[int, Dict[Tuple[int], int]] = {}
    peer_locked_time: Dict[int, float] = {}
    for node in range(args.nodes):
        peer_locked_time[node] = 0

    if args.track_all_nodes:
        for node in range(args.nodes):
            nb_frequencies[node] = [0] * args.nodes
            nbh_frequencies[node] = defaultdict(lambda: 0)
    else:
        nb_frequencies = {0: [0] * args.nodes}
        nbh_frequencies = {0: defaultdict(lambda: 0)}

    start_time = time.time()
    G = random_regular_graph(args.k, args.nodes, seed=args.seed)
    for run_index in range(args.runs_per_process):
        if run_index % 100000 == 0:
            logging.info("Process %d completed %d runs..." % (process_index, run_index))

        while True:
            try:
                simulation = Simulation(args, G)
                simulation.run()
                total_swaps += simulation.swaps
                failed_swaps += simulation.failed_swaps
                break
            except Exception as exc:
                logging.exception(exc)
                print("Whoops - failed, trying that again")

        nbhs = simulation.get_neighbour_of_tracked_nodes()
        for node, nbh in nbhs.items():
            for nb in nbh:
                nb_frequencies[node][nb] += 1
            nbh_frequencies[node][nbh] += 1

        for node in range(args.nodes):
            peer_locked_time[node] += simulation.peers[node].total_time_locked

    print("Experiment took %f s., swaps done: %d, failed swaps: %d" % (time.time() - start_time, total_swaps, failed_swaps))

    if args.profile:
        yappi.stop()
        yappi_stats = yappi.get_func_stats()
        yappi_stats.sort("tsub")
        yappi_stats.save(os.path.join(data_dir, "yappi_%d.stats" % process_index), type='callgrind')

    # Write away the results
    with open(os.path.join(data_dir, "frequencies_%d.csv" % process_index), "w") as out_file:
        out_file.write("tracked_node,node,freq\n")
        for tracked_node, nbhs in nb_frequencies.items():
            for node_id, freq in enumerate(nbhs):
                out_file.write("%d,%d,%d\n" % (tracked_node, node_id, freq))

    with open(os.path.join(data_dir, "nbh_frequencies_%d.csv" % process_index), "w") as out_file:
        out_file.write("tracked_node,neighbourhood,freq\n")
        for tracked_node, nbhs in nbh_frequencies.items():
            for neighbourhood, freq in nbhs.items():
                nbh_str = "-".join(["%d" % nb for nb in neighbourhood])
                out_file.write("%d,%s,%d\n" % (tracked_node,nbh_str, freq))

    with open(os.path.join(data_dir, "peer_time_locked_%d.csv" % process_index), "w") as out_file:
        out_file.write("node,avg_time_locked\n")
        for node in range(args.nodes):
            out_file.write("%d,%g\n" % (node, peer_locked_time[node] / args.runs_per_process))


if __name__ == "__main__":
    args = get_args()

    # How many CPUs do we have?
    cpus_to_use = args.cpus or multiprocessing.cpu_count() - 2  # Don't be greedy and use all the CPUs :)

    print("Will start experiments on %d CPUs..." % cpus_to_use)

    data_dir = os.path.join("data", "n_%d_k_%d_t_%g_s_%d" % (args.nodes, args.k, args.time_per_run, args.seed))
    if os.path.exists(data_dir):
        shutil.rmtree(data_dir)
    os.makedirs(data_dir, exist_ok=True)

    processes = []
    for process_index in range(cpus_to_use):
        p = Process(target=run, args=(process_index, args, data_dir))
        p.start()
        processes.append(p)

    for p in processes:
        p.join()

    print("Processes done - combining results")

    # Merge node frequencies
    merged_frequencies: Dict[int, List[int]] = {}
    input_files = [os.path.join(data_dir, "frequencies_%d.csv" % process_index) for process_index in range(cpus_to_use)]
    for input_file in input_files:
        with open(input_file, "r") as in_file:
            reader = csv.reader(in_file)
            next(reader)  # Skip the header
            for row in reader:
                tracked_node, node_id, freq = int(row[0]), int(row[1]), int(row[2])
                if tracked_node not in merged_frequencies:
                    merged_frequencies[tracked_node] = [0] * args.nodes
                merged_frequencies[tracked_node][node_id] += freq
        os.remove(input_file)

    output_file_name = os.path.join(data_dir, "frequencies.csv")
    with open(output_file_name, "w") as out_file:
        out_file.write("algorithm,nodes,k,time_per_run,seed,tracked_node,node,freq\n")
        for tracked_node, freqs in merged_frequencies.items():
            for node_ind, freq in enumerate(freqs):
                out_file.write("swiftpeer,%d,%d,%g,%d,%d,%d,%d\n" % (args.nodes, args.k, args.time_per_run, args.seed, tracked_node, node_ind, freq))

    # Merge neighbourhoods
    merged_nbh_frequencies: Dict[int, Dict[Tuple[int], int]] = {}
    input_files = [os.path.join(data_dir, "nbh_frequencies_%d.csv" % process_index) for process_index in range(cpus_to_use)]
    for input_file in input_files:
        with open(input_file, "r") as in_file:
            reader = csv.reader(in_file)
            next(reader)  # Skip the header
            for row in reader:
                tracked_node, nbh, freq = int(row[0]), row[1], int(row[2])
                if tracked_node not in merged_nbh_frequencies:
                    merged_nbh_frequencies[tracked_node] = defaultdict(lambda: 0)

                nbh = tuple([int(part) for part in nbh.split("-")])
                merged_nbh_frequencies[tracked_node][nbh] += freq
        os.remove(input_file)

    output_file_name = os.path.join(data_dir, "nbh_frequencies.csv")
    with open(output_file_name, "w") as out_file:
        out_file.write("algorithm,nodes,k,time_per_run,seed,tracked_node,nbh,freq\n")
        for tracked_node, nbhs in merged_nbh_frequencies.items():
            for nbh, freq in nbhs.items():
                nbh_str = "-".join(["%d" % nb for nb in nbh])
                out_file.write("swiftpeer,%d,%d,%g,%d,%d,%s,%d\n" % (args.nodes, args.k, args.time_per_run, args.seed, tracked_node, nbh_str, freq))

    # Merge peer lock time
    merged_lock_times: Dict[int, float] = {}
    for node in range(args.nodes):
        merged_lock_times[node] = 0

    input_files = [os.path.join(data_dir, "peer_time_locked_%d.csv" % process_index) for process_index in range(cpus_to_use)]
    for input_file in input_files:
        with open(input_file, "r") as in_file:
            reader = csv.reader(in_file)
            next(reader)  # Skip the header
            for row in reader:
                node_id, time_locked = int(row[0]), float(row[1])
                merged_lock_times[node_id] += time_locked
        os.remove(input_file)

    for node in range(args.nodes):
        merged_lock_times[node] /= cpus_to_use

    output_file_name = os.path.join(data_dir, "peer_time_locked.csv")
    with open(output_file_name, "w") as out_file:
        out_file.write("algorithm,nodes,k,time_per_run,seed,node,avg_time_locked\n")
        for node, time_locked in merged_lock_times.items():
            out_file.write("swiftpeer,%d,%d,%g,%d,%d,%g\n" % (args.nodes, args.k, args.time_per_run, args.seed, node, time_locked))
