library(ggplot2)
library(dplyr)

# Example: Generating directory names manually
directories <- c()
for (n in c(1024, 2048, 4096, 8192, 16382)) {
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

merged_data$nodes <- as.factor(merged_data$nodes)

p <- ggplot(merged_data, aes(x=freq, group=nodes, color=nodes, linetype=nodes)) +
     stat_ecdf() +
     coord_cartesian(xlim=c(75, 125)) +
     scale_color_discrete(name = "Peers") +
     scale_linetype_discrete(name = "Peers") +
     theme_bw() +
     xlab("Peer Frequency") +
     ylab("ECDF") +
     theme(legend.position=c(0.82, 0.4), legend.box.background = element_rect(colour = "black"))

ggsave("data/exp3/nodes_frequencies_different_n_ecdf.pdf", p, width=4, height=2.5)
