library(ggplot2)
library(dplyr)

dat <- read.csv("data/sequence_t.csv")
dat$nodes <- as.factor(dat$nodes)
dat$k <- as.factor(dat$k)

dat <- dat %>%
  group_by(nodes,k) %>%
  summarise(
    T_mean = mean(T), T_sd = sd(T))

print(dat)

p <- ggplot(dat, aes(x=nodes,y=T_mean,group=k, color=k)) +
     geom_point() +
     geom_line() +
     theme_bw() +
     xlab("Network size") +
     ylab("T") +
     theme(legend.position=c(0.75, 0.6), legend.box.background = element_rect(colour = "black"), , legend.direction="horizontal")

ggsave("data/sequence_t.pdf", p, width=5, height=3)