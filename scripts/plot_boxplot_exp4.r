library(ggplot2)

print("Loading main data")
dat <- read.csv("data/exp4/n_64_k_4_t_4_s_42/nbh_frequencies.csv")
dat$tracked_node <- as.integer((0:(nrow(dat) - 1)) / 595665)  # Due to a bug...

print("Loading synthetic data")
synthetic_data <- read.csv("data/exp4/n_64_k_4_t_4_s_42_synthetic/nbh_frequencies.csv")

ks_distances <- numeric()

for (n in c(0:63)) {
    print(n)
    filtered_data <- dat[dat$tracked_node == n,]
    ks_test_result <- ks.test(filtered_data$freq, synthetic_data$freq)
    print(ks_test_result)
    ks_distances <- c(ks_distances, ks_test_result$statistic)
}

# Plotting the distribution of KS test distances using ggplot2
p <- ggplot(data = data.frame(distance = ks_distances), aes(x = distance)) +
     geom_boxplot() +
     xlab("KS Test Distance") +
     ylab("Frequency") +
     ggtitle("Boxplot of KS Test Distances")

ggsave("data/exp4/ks_distances_boxplot.pdf", p, width=4, height=2.5)
