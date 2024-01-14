library(ggplot2)
library(dplyr)

# Example: Generating directory names manually
directories <- c("n_4096_k_5_t_1_s_42", "n_4096_k_5_t_1.5_s_42", "n_4096_k_5_t_2_s_42", "n_4096_k_5_t_3_s_42", "n_4096_k_5_t_4_s_42")
file_paths <- paste0("data/exp2/", directories, "/frequencies.csv")
merged_data <- data.frame()
for (file_path in file_paths) {
    print(file_path)
    if (file.exists(file_path)) {
        dat <- read.csv(file_path)
        merged_data <- rbind(merged_data, dat)
    }
}

merged_data$time_per_run <- as.factor(merged_data$time_per_run)

p <- ggplot(merged_data, aes(x=freq,group=time_per_run, color=time_per_run)) +
     stat_ecdf() +
     coord_cartesian(xlim=c(NA, 200)) +
     theme_bw() +
     xlab("Frequency") +
     ylab("ECDF") +
     theme(legend.position=c(0.8, 0.3), legend.box.background = element_rect(colour = "black"))

ggsave("data/nbh_frequencies_different_t_ecdf_nodes.pdf", p, width=5, height=3)
