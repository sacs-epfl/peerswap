library(ggplot2)
library(dplyr)

# Example: Generating directory names manually
directories <- c()
for (n in c(2048, 4096, 8192, 16384, 32768)) {
    for (s in 42:46) {
        directory_name <- paste("n_", n, "_k_5_t_5_s_", s, sep = "")
        directories <- c(directories, directory_name)
    }
}

file_paths <- paste0("data/exp3/", directories, "/frequencies.csv")
merged_data <- data.frame()
for (file_path in file_paths) {
    print(file_path)
    if (file.exists(file_path)) {
        dat <- read.csv(file_path)
        merged_data <- rbind(merged_data, dat)
    }
}

merged_data$time_per_run <- as.factor(merged_data$time_per_run)

for (n in c(2048, 4096, 8192, 16384, 32768)) {
    synthetic_data <- read.csv(paste("data/exp3/n_", n, "_k_4_t_4_s_42_synthetic/frequencies.csv", sep=""))
    filtered_data <- merged_data[merged_data$nodes == n,]
    total_ks_distance <- 0
    total_ks_p_value <- 0
    count <- 0
    for (s in 42:46) {
        further_filtered <- filtered_data[filtered_data$seed == s,]
        ks_test_result <- ks.test(further_filtered$freq, synthetic_data$freq)

        # Accumulate KS statistics
        total_ks_distance <- total_ks_distance + ks_test_result$statistic
        total_ks_p_value <- total_ks_p_value + ks_test_result$p.value
        count <- count + 1
    }

    if (count > 0) {
        avg_ks_distance <- total_ks_distance / count
        avg_ks_p_value <- total_ks_p_value / count

        # Print the averaged values
        cat("Average KS Test results for n =", n, "\n")
        cat("Average KS Distance:", avg_ks_distance, "\n")
        cat("Average P-value:", avg_ks_p_value, "\n\n")
    }
}

merged_data$nodes <- as.factor(merged_data$nodes)

p <- ggplot(merged_data, aes(x=freq, group=nodes, color=nodes, linetype=nodes)) +
     stat_ecdf() +
     coord_cartesian(xlim=c(75, 125)) +
     scale_color_discrete(name = "Peers") +
     scale_linetype_discrete(name = "Peers") +
     theme_bw() +
     xlab("Peer Frequency") +
     ylab("ECDF") +
     theme(legend.position="top", legend.margin=margin(t = 0, unit='cm'))

ggsave("data/exp3/nodes_frequencies_different_n_ecdf.pdf", p, width=4.4, height=2.3)
