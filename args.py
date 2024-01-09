import argparse


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--nodes", type=int, default=100)
    parser.add_argument("--runs-per-process", type=int, default=1000)
    parser.add_argument("--time-per-run", type=int, default=7)
    parser.add_argument("--poisson-rate", type=int, default=1.0)
    parser.add_argument("--k", type=int, default=7)
    parser.add_argument("--cpus", type=int, default=None)
    parser.add_argument('--profile', action=argparse.BooleanOptionalAction)

    return parser.parse_args()
