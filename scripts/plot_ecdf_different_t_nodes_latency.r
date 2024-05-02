library(ggplot2)
library(dplyr)

directories <- c()
for (t in c(60, 120, 180, 240, 300)) {
    for (s in 42:42) {
        directory_name <- paste("n_1024_k_5_t_", t, "_s_", s, sep = "")
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

# synthetic_data <- read.csv("data/exp2/n_4096_k_4_t_4_s_42_synthetic/frequencies.csv")
# merged_data$time_per_run <- as.factor(merged_data$time_per_run)
#
# for (t in c(3)) {
#     filtered_data <- merged_data[merged_data$time_per_run == t,]
#     for (s in 42:46) {
#         further_filtered <- filtered_data[filtered_data$seed == s,]
#         print(ks.test(further_filtered$freq, synthetic_data$freq))
#     }
# }

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