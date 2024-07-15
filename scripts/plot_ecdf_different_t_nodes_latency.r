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

for (t in c(60, 90, 120, 150, 180)) {
    for (s in 42:46) {
        directory_name <- paste("n_1024_k_5_t_", t, "_s_", s, "_l_0.02", sep = "")
        directories <- c(directories, directory_name)
        directory_name <- paste("n_1024_k_5_t_", t, "_s_", s, "_l_0.05", sep = "")
        directories <- c(directories, directory_name)
        directory_name <- paste("n_1024_k_5_t_", t, "_s_", s, "_l_0.1", sep = "")
        directories <- c(directories, directory_name)
        directory_name <- paste("n_1024_k_5_t_", t, "_s_", s, "_l_traces", sep = "")
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
merged_data$max_network_delay <- factor(merged_data$max_network_delay, levels = c("0-20 ms", "0-50 ms", "0-100 ms", "traces"))

sp <- ggplot(merged_data, aes(x=freq,group=time_per_run, color=time_per_run, linetype=time_per_run)) +
      stat_ecdf() +
      coord_cartesian(xlim=c(NA, 200)) +
      scale_color_discrete(name = "Experiment Duration [s.]") +
      scale_linetype_discrete(name = "Experiment Duration [s.]") +
      theme_bw() +
      xlab("Peer Frequency") +
      ylab("ECDF") +
      theme(legend.position="top", legend.margin=margin(t = 0, unit='cm')) +
      facet_wrap( ~ max_network_delay, nrow=1)



# filtered_dat <- merged_data[merged_data$max_network_delay == "traces",]

# p1 <- ggplot(filtered_dat, aes(x=freq,group=time_per_run, color=time_per_run, linetype=time_per_run)) +
#       stat_ecdf() +
#       coord_cartesian(xlim=c(NA, 200)) +
#       scale_color_discrete(name = "Experiment Duration [s.]") +
#       scale_linetype_discrete(name = "Experiment Duration [s.]") +
#       theme_bw() +
#       xlab("Peer Frequency") +
#       ylab("ECDF") +
#       theme(legend.position="top", legend.margin=margin(t = 0, unit='cm'))
#
# filtered_dat <- merged_data[merged_data$max_network_delay == "0-20 ms",]
# p2 <- ggplot(filtered_dat, aes(x=freq,group=time_per_run, color=time_per_run, linetype=time_per_run)) +
#       stat_ecdf() +
#       coord_cartesian(xlim=c(NA, 200)) +
#       scale_color_discrete(name = "Experiment Duration [s.]") +
#       scale_linetype_discrete(name = "Experiment Duration [s.]") +
#       theme_bw() +
#       xlab("Peer Frequency") +
#       ylab("ECDF") +
#       theme(legend.position="top", legend.margin=margin(t = 0, unit='cm'))
#
# filtered_dat <- merged_data[merged_data$max_network_delay == "0-50 ms",]
# p3 <- ggplot(filtered_dat, aes(x=freq,group=time_per_run, color=time_per_run, linetype=time_per_run)) +
#       stat_ecdf() +
#       coord_cartesian(xlim=c(NA, 200)) +
#       scale_color_discrete(name = "Experiment Duration [s.]") +
#       scale_linetype_discrete(name = "Experiment Duration [s.]") +
#       theme_bw() +
#       xlab("Peer Frequency") +
#       ylab("ECDF") +
#       theme(legend.position="top", legend.margin=margin(t = 0, unit='cm'))
#
# filtered_dat <- merged_data[merged_data$max_network_delay == "0-100 ms",]
# p4 <- ggplot(filtered_dat, aes(x=freq,group=time_per_run, color=time_per_run, linetype=time_per_run)) +
#       stat_ecdf() +
#       coord_cartesian(xlim=c(NA, 200)) +
#       scale_color_discrete(name = "Experiment Duration [s.]") +
#       scale_linetype_discrete(name = "Experiment Duration [s.]") +
#       theme_bw() +
#       xlab("Peer Frequency") +
#       ylab("ECDF") +
#       theme(legend.position="top", legend.margin=margin(t = 0, unit='cm'))
#
# sp <- ggpubr::ggarrange(p2, p3, p4, p1, # list of plots
#                   common.legend = T, # COMMON LEGEND
#                   legend = "top", # legend position
#                   align = "hv", # Align them both, horizontal and vertical
#                   nrow = 1)  # number of rows

ggsave("data/exp6/nodes_frequencies_different_t_latencies_ecdf.pdf", sp, width=10, height=2.3)
