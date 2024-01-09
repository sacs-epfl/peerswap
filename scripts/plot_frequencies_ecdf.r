library(ggplot2)
library(dplyr)

# Frequencies per node
dat <- read.csv("data/n_1000_k_7_t_7/frequencies.csv")
synthetic_file_path <- "data/n_1000_k_7_t_7/frequencies_synthetic.csv"
if (file.exists(synthetic_file_path)) {
  dat_synthetic <- read.csv(synthetic_file_path)
  dat <- rbind(dat, dat_synthetic)
}
dat <- dat[dat$freq > 0,]
dat <- dat %>% mutate(group = paste(algorithm, " (n=", nodes, ",k=", k, ")", sep=""))

p <- ggplot(dat, aes(x=freq, group=group, color=group, linetype=group)) +
     stat_ecdf() +
     theme_bw() +
     xlab("Node Frequency") +
     ylab("ECDF") +
     theme(legend.position=c(0.75, 0.3), legend.box.background = element_rect(colour = "black"))

ggsave("data/node_frequencies_ecdf.pdf", p, width=5, height=3)

# Frequencies per node
dat <- read.csv("data/n_50_k_4_t_1/nbh_frequencies.csv")
synthetic_file_path <- "data/n_50_k_4_t_1/nbh_frequencies_synthetic.csv"
if (file.exists(synthetic_file_path)) {
  dat_synthetic <- read.csv(synthetic_file_path)
  dat <- rbind(dat, dat_synthetic)
}

p <- ggplot(dat, aes(x=freq,group=algorithm, color=algorithm, linetype=algorithm)) +
     stat_ecdf() +
     theme_bw() +
     xlab("Frequency") +
     ylab("ECDF") +
     theme(legend.position=c(0.8, 0.3), legend.box.background = element_rect(colour = "black"))

ggsave("data/nbh_frequencies_ecdf.pdf", p, width=5, height=3)
