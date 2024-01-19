library(ggplot2)
library(dplyr)

dat_t4 <- read.csv("data/exp5/ks_results.csv")
dat_t4$t <- 4
dat_t4$spectral_gap <- (1 - (dat_t4$lambda/4))
# filtered_dat <- dat_t4[dat_t4$seed==343170,]
# print(mean(filtered_dat$distance))

dat_t6 <- read.csv("data/exp5/ks_results_t_6.csv")
dat_t6$t <- 6
dat_t6$spectral_gap <- (1 - (dat_t6$lambda/4))
filtered_dat <- dat_t6[dat_t6$pvalue <= 0.05,]
print(nrow(filtered_dat))

dat <- rbind(dat_t4, dat_t6)
dat$t <-as.factor(dat$t)

dat <- dat[dat$distance <= 0.0075,]
dat <- dat %>% mutate(t = paste("t = ", t, sep=""))

p <- ggplot(data = dat, aes(x = spectral_gap, y=distance, group=spectral_gap)) +
     geom_boxplot() +
     theme_bw() +
     xlab(expression("Spectral Gap (" * lambda * ")")) +
     ylab("KS-test Distance") +
     facet_wrap(~t)

ggsave("data/exp5/ks_distances_boxplot.pdf", p, width=7, height=2.3)


# # T = 6
# dat <- read.csv("data/exp5/ks_results_t_6.csv")
# dat <- dat[dat$distance <= 0.0075,]
# dat$spectral_gap <- (1 - (dat$lambda/4))
# print(dat)
#
# p <- ggplot(data = dat, aes(x = spectral_gap, y=distance, group=lambda)) +
#      geom_boxplot() +
#      theme_bw() +
#      xlab(expression("Spectral Gap (" * lambda * ")")) +
#      ylab("KS Distance")
#
# ggsave("data/exp5/ks_distances_t_6_boxplot.pdf", p, width=5, height=2.3)
