library(ggplot2)
library(dplyr)

directories <- c()
for (t in c(1, 1.5, 2, 3, 4)) {
    for (s in 42:46) {
        directory_name <- paste("n_4096_k_5_t_", t, "_s_", s, sep = "")
        directories <- c(directories, directory_name)
    }
}

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

p <- ggplot(merged_data, aes(x=freq,group=time_per_run, color=time_per_run, linetype=time_per_run)) +
     stat_ecdf() +
     coord_cartesian(xlim=c(NA, 200)) +
     scale_color_discrete(name = "Runtime [s.]") +
     scale_linetype_discrete(name = "Runtime [s.]") +
     theme_bw() +
     xlab("Peer Frequency") +
     ylab("ECDF") +
     theme(legend.position=c(0.82, 0.43), legend.box.background = element_rect(colour = "black"))

ggsave("data/exp2/nodes_frequencies_different_t_ecdf.pdf", p, width=4, height=2.5)
