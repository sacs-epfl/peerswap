library(ggplot2)
library(dplyr)

dat <- read.csv("data/success_rate_with_latency.csv")
dat$max_network_delay <- as.factor(dat$max_network_delay)

dat <- dat %>%
  group_by(max_network_delay,swaps_per_sec) %>%
  summarise(
    success_mean = mean(success), fail_mean = mean(fail))

dat$frac <- dat$fail_mean / (dat$success_mean + dat$fail_mean) * 100
dat$throughput <- dat$success_mean / 100
print(dat, n=500)

p <- ggplot(dat, aes(x=swaps_per_sec, y=frac, group=max_network_delay, color=max_network_delay)) +
     geom_line() +
     geom_point(aes(shape=max_network_delay)) +
     theme_bw() +
     xlab("Swaps per Second") +
     ylab("% Swaps Failed") +
     labs(color="Network Delay", shape="Network Delay") +
     theme(legend.position="top", legend.margin=margin(t = 0, unit='cm'))

ggsave("data/success_rate_with_latency.pdf", p, width=4.8, height=2.3)


p <- ggplot(dat, aes(x=swaps_per_sec, y=throughput, group=max_network_delay, color=max_network_delay)) +
     geom_line() +
     geom_point(aes(shape=max_network_delay)) +
     theme_bw() +
     xlab("Edge activations per Second") +
     ylab("Throughput [swaps/s.]") +
     labs(color="Network Delay", shape="Network Delay") +
     theme(legend.position="top", legend.margin=margin(t = 0, unit='cm'))

ggsave("data/throughput_with_latency.pdf", p, width=4.8, height=2.3)
