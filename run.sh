#!/bin/bash

source ~/venv3/bin/activate
python3 main.py --nodes $1 --k $2 --time-per-run $3 --cpus $4 --runs-per-process $5 --seed $6 --poisson-rate $7 --max-network-latency $8