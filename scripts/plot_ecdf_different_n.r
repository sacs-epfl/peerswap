library(ggplot2)
library(dplyr)

# Example: Generating directory names manually
directories <- c("n_1024_k_5_t_5_s_42", "n_2048_k_5_t_5_s_42", "n_4096_k_5_t_5_s_42", "n_8192_k_5_t_5_s_42")
file_paths <- paste0("data/", directories, "/frequencies.csv")
merged_data <- data.frame()
for (file_path in file_paths) {
    print(file_path)
    if (file.exists(file_path)) {
        dat <- read.csv(file_path)
        merged_data <- rbind(merged_data, dat)
    }
}

merged_data$nodes <- as.factor(merged_data$nodes)

p <- ggplot(merged_data, aes(x=freq, group=nodes, color=nodes)) +
     stat_ecdf() +
     coord_cartesian(xlim=c(50, 150)) +
     theme_bw() +
     xlab("Frequency") +
     ylab("ECDF") +
     theme(legend.position=c(0.8, 0.3), legend.box.background = element_rect(colour = "black"))

ggsave("data/nbh_frequencies_different_n_ecdf.pdf", p, width=5, height=3)
