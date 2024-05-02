import argparse


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--nodes", type=int, default=100)
    parser.add_argument("--runs-per-process", type=int, default=1000)
    parser.add_argument("--time-per-run", type=float, default=7)
    parser.add_argument("--poisson-rate", type=float, default=1.0)
    parser.add_argument("--max-network-latency", type=float, default=0.01)
    parser.add_argument("--k", type=int, default=7)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--cpus", type=int, default=None)
    parser.add_argument('--profile', action='store_true')
    parser.add_argument('--track-all-nodes', action='store_true')
    parser.add_argument('--latencies-file', type=str, default=None)
    parser.add_argument('--log-level', type=str, default="ERROR")

    return parser.parse_args()
