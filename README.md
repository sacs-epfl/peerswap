# PeerSwap: A Peer-Sampler with Randomness Guarantees

This repository contains the source code associated with our paper "PeerSwap: A Peer-Sampler with Randomness Guarantees", accepted at [SRDS'24](https://srds-conference.org).
PeerSwap is a peer-sampling protocol with provable randomness guarantees.

### Running PeerSwap

First install the required Python dependencies:

```
pip install -r requirements.txt
```

The simulator can be executed in two modes.
In basic mode, we first generate a k-regular graph using `networkx`, and then schedule peer swaps according to the Poisson clock on each edge.
While executing the swaps, we keep track of the neighbourhood distributions of a single, random peer or all peers if the `--track-all-nodes` option is provided when starting the program.
Basic mode can easily be enabled by passing the `--basic` flag but does not support network delays or clock desynchronization between peers since it assumes swaps are executed instantly.
For example, you can use the following command.

```
python3 main.py --cpus 1 --runs-per-process 100 --nodes 1024 --time-per-run 7 --k 7 --basic
```

The above command will run 100 experiments sequentially and each experiment will run PeerSwap for 7 seconds using a 7-regular graph with 1024 nodes.
Your output should look something like this:

```
Will start experiments on 1 CPUs...
Experiment took 7.301254 s., swaps done: 2509524
Processes done - combining results
```

At the end of the experiment we combine the individual results of all runs.
If you don't pass the `--cpus` option, PeerSwap will use all available CPUs minus two on the system.
Default argument values can be found in `peerswap/args.py`.

By default however, we execute the full PeerSwap protocol where peers exchange a sequence of messages to perform a single swap.
This mode is much slower than basic mode but it enables the evaluation of PeerSwap in the presence of network delays.
For example, see the following command.

```
python3 main.py --cpus 1 --poisson-rate 0.1 --max-network-latency 0 --runs-per-process 100 
```

Your output should look something like this:

```
Will start experiments on 1 CPUs...
Experiment took 6.155684 s., swaps done: 24603, failed swaps: 0
Processes done - combining results
```

### Custom network latencies

In default mode, PeerSwap will generate pairwise latencies uniformly between 0 ms and a maximum latency specified by the `--max-network-latency` option (in seconds).
One can also specify a latency matrix as a CSV file with the `--latencies-file` option.
For example, to specify the latencies for a three-node network, your CSV file can look like as follows (note that the latencies are provided in milliseconds):

```
0,183.6055,90.8835
183.029,0,44.826
90.7965,44.793,0
```

If there are more nodes in the experiment than rows/values in the latency matrix, PeerSwap will automatically assign nodes to latency values in a round-robin fashion.

### Reference

If you use our work, please cite us using the following citation:

```
@inproceedings{guerraoui2024peerswap,
  title={PeerSwap: A Peer-Sampler with Randomness Guarantees},
  author={Guerraoui, Rachid and Kermarrec, Anne-Marie and Kucherenko, Anastasiia and Pinot, Rafael and de Vos, Martijn},
  booktitle={Proceedings of the 43rd International Symposium on Reliable Distributed Systems (SRDS 2024)},
  year={2024}
}
```