library(ggplot2)
library(dplyr)

dat <- read.csv("../data/frequencies.csv")

p <- ggplot(dat, aes(x=node, y=freq)) +
     geom_line() +
     theme_bw() +
     xlab("Node") +
     ylab("Frequency") +
     ylim(0, max(dat$freq))

ggsave("../data/frequencies.pdf", p, width=5, height=3)
