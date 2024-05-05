library(ggplot2)
library(dplyr)

directories <- c()

# Synthetic
# for (t in c(30, 60, 90, 120)) {
#     for (s in 42:42) {
#         directory_name <- paste("n_1024_k_5_t_", t, "_s_", s, sep = "")
#         directories <- c(directories, directory_name)
#     }
# }

# Realistic
for (t in c(60, 90, 120, 150, 180)) {
    for (s in 42:46) {
        directory_name <- paste("synthetic/n_1024_k_5_t_", t, "_s_", s, sep = "")
        directories <- c(directories, directory_name)
    }
}

file_paths <- paste0("data/exp6/", directories, "/frequencies.csv")
merged_data <- data.frame()
for (file_path in file_paths) {
    print(file_path)
    if (file.exists(file_path)) {
        dat <- read.csv(file_path)
        merged_data <- rbind(merged_data, dat)
    }
}

merged_data$time_per_run <- as.factor(merged_data$time_per_run)

p <- ggplot(merged_data, aes(x=freq,group=time_per_run, color=time_per_run, linetype=time_per_run)) +
     stat_ecdf() +
     coord_cartesian(xlim=c(NA, 200)) +
     scale_color_discrete(name = "Experiment Duration [s.]") +
     scale_linetype_discrete(name = "Experiment Duration [s.]") +
     theme_bw() +
     xlab("Peer Frequency") +
     ylab("ECDF") +
     theme(legend.position="top", legend.margin=margin(t = 0, unit='cm'))

ggsave("data/exp6/nodes_frequencies_different_t_latencies_ecdf.pdf", p, width=4.8, height=2.3)
