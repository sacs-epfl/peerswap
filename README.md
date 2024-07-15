# PeerSwap: A Peer-Sampler with Randomness Guarantees

This repository contains the source code associated with our paper "PeerSwap: A Peer-Sampler with Randomness Guarantees".
PeerSwap is a peer-sampling protocol with provable randomness guarantees.

```
python3 main.py --cpus 1 --poisson-rate 0.1 --max-network-latency 0 --runs-per-process 100 
```

Your output should look something like:

```
Will start experiments on 1 CPUs...
Experiment took 6.155684 s., swaps done: 24603, failed swaps: 0
Processes done - combining results
```