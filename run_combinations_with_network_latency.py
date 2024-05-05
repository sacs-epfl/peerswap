import logging
import os

from args import get_args
from simulation import Simulation

if __name__ == "__main__":
    args = get_args()
    args.time_per_run = 120
    args.nodes = 1024
    args.k = 5
    logging.basicConfig(level=getattr(logging, args.log_level))

    with open(os.path.join("data", "success_rate_with_latency.csv"), "w") as out_file:
        out_file.write("max_network_delay,swaps_per_sec,success,fail\n")
        for max_network_latency in ["20", "50", "100", "realistic"]:
            for swaps_per_sec in [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]:
                for run in range(5):
                    if max_network_latency == "realistic":
                        args.latencies_file = "data/latencies.txt"
                        args.max_network_latency = 0
                        print("Running with realistic traces and swaps/sec %d (run %d)" % (swaps_per_sec, run + 1))
                    else:
                        max_network_latency_in_ms = int(max_network_latency)
                        print("Running with max latency %d ms and swaps/sec %d (run %d)" % (max_network_latency_in_ms, swaps_per_sec, run + 1))
                        args.max_network_latency = max_network_latency_in_ms / 1000
                        args.latencies_file = None

                    edges: int = int((args.k * args.nodes) / 2)
                    poisson_rate = 1 / (edges / swaps_per_sec)
                    args.poisson_rate = poisson_rate

                    while True:
                        try:
                            simulation = Simulation(args)
                            simulation.run()
                            break
                        except:
                            print("Whoops - failed, trying that again")

                    group = "traces" if max_network_latency == "realistic" else "0-%d ms" % max_network_latency_in_ms
                    out_file.write("%s,%d,%d,%d\n" % (group, swaps_per_sec, simulation.swaps, simulation.failed_swaps))
