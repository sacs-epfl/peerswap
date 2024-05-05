library(ggplot2)
library(dplyr)

dat <- read.csv("data/exp7/swap_times.csv")

p <- ggplot(dat, aes(x=swap_time, group=max_network_latency, color=max_network_latency, linetype=max_network_latency)) +
     stat_ecdf() +
     scale_color_discrete(name = "Network Delay") +
     scale_linetype_discrete(name = "Network Delay") +
     theme_bw() +
     xlab("Swap Duration [s.]") +
     ylab("ECDF") +
     theme(legend.position="top", legend.margin=margin(t = 0, unit='cm'))

ggsave("data/exp7/swap_times_ecdf.pdf", p, width=5.1, height=2.3)
