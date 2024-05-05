library(ggplot2)
library(dplyr)
library(ggpubr)

dat <- read.csv("data/exp7/success_rate_with_latency.csv")
dat$max_network_delay <- as.factor(dat$max_network_delay)

dat <- dat %>%
  group_by(max_network_delay,swaps_per_sec) %>%
  summarise(
    success_mean = mean(success), fail_mean = mean(fail))

dat$frac <- dat$fail_mean / (dat$success_mean + dat$fail_mean) * 100
dat$throughput <- dat$success_mean / 120
dat$max_network_delay <- factor(dat$max_network_delay, levels = c("0-20 ms", "0-50 ms", "0-100 ms", "traces"))
print(dat, n=500)

p <- ggplot(dat, aes(x=swaps_per_sec, y=frac, group=max_network_delay, color=max_network_delay)) +
     geom_line() +
     geom_point(aes(shape=max_network_delay)) +
     theme_bw() +
     xlab("Swaps per Second") +
     ylab("% Swaps Failed") +
     labs(color="Network Delay", shape="Network Delay") +
     theme(legend.position="top", legend.margin=margin(t = 0, unit='cm'))

ggsave("data/exp7/success_rate_with_latency.pdf", p, width=4.8, height=2.3)


p <- ggplot(dat, aes(x=swaps_per_sec, y=throughput, group=max_network_delay, color=max_network_delay)) +
     geom_line() +
     geom_point(aes(shape=max_network_delay)) +
     theme_bw() +
     xlab("Edge activations per Second") +
     ylab("Throughput [swaps/s.]") +
     labs(color="Network Delay", shape="Network Delay") +
     theme(legend.position="top", legend.margin=margin(t = 0, unit='cm'))

ggsave("data/exp7/throughput_with_latency.pdf", p, width=4.8, height=2.3)


dat_swap_time <- read.csv("data/exp7/swap_times.csv")
dat_swap_time$max_network_latency <- factor(dat_swap_time$max_network_latency, levels = c("0-20 ms", "0-50 ms", "0-100 ms", "traces"))

dat_filtered <- dat_swap_time[dat_swap_time$max_network_latency == "traces",]
print(mean(dat_filtered$swap_time))

p2 <- ggplot(dat_swap_time, aes(x=swap_time, group=max_network_latency, color=max_network_latency, linetype=max_network_latency)) +
      stat_ecdf() +
      scale_color_discrete(name = "Network Delay") +
      scale_linetype_discrete(name = "Network Delay") +
      theme_bw() +
      xlim(c(0, 0.8)) +
      xlab("Swap Duration [s.]") +
      ylab("ECDF") +
      theme(legend.position="top", legend.margin=margin(t = 0, unit='cm'))

sp <- ggpubr::ggarrange(p, p2, # list of plots
                  common.legend = T, # COMMON LEGEND
                  legend = "top", # legend position
                  align = "hv", # Align them both, horizontal and vertical
                  nrow = 1)  # number of rows

# If you want to save the combined plot to a file
ggsave("data/exp7/throughput_with_swap_durations.pdf", sp, width = 5, height = 2)