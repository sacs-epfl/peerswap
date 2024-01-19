library(ggplot2)
library(dplyr)

directories <- c()
for (t in 1:4) {
    for (s in 42:46) {
        directory_name <- paste("n_64_k_4_t_", t, "_s_", s, sep = "")
        directories <- c(directories, directory_name)
    }
}

file_paths <- paste0("data/exp1/", directories, "/nbh_frequencies.csv")
merged_data <- data.frame()
for (file_path in file_paths) {
    print(file_path)
    if (file.exists(file_path)) {
        dat <- read.csv(file_path)
        merged_data <- rbind(merged_data, dat)
    }
}

merged_data$time_per_run <- as.factor(merged_data$time_per_run)

# load synthetic data
directories <- c()
for (s in 42:46) {
    directory_name <- paste("n_64_k_4_t_1_s_", s, "_synthetic", sep = "")
    directories <- c(directories, directory_name)
}

file_paths <- paste0("data/exp1/", directories, "/nbh_frequencies.csv")
synthetic_data <- data.frame()
for (file_path in file_paths) {
    print(file_path)
    if (file.exists(file_path)) {
        dat <- read.csv(file_path)
        synthetic_data <- rbind(synthetic_data, dat)
    }
}

print("SD of synthetic data")
print(sd(synthetic_data$freq))
for (t in 3:4) {
    filtered_data <- merged_data[merged_data$t == t,]
    for (s in 42:46) {
        further_filtered <- filtered_data[filtered_data$seed == s,]
        print(ks.test(further_filtered$freq, synthetic_data$freq))
    }
}

p <- ggplot(merged_data, aes(x=freq, group=time_per_run, color=time_per_run, linetype=time_per_run)) +
     stat_ecdf() +
     coord_cartesian(xlim=c(NA, 200)) +
     scale_color_discrete(name = "Experiment Duration [s.]") +
     scale_linetype_discrete(name = "Experiment Duration [s.]") +
     theme_bw() +
     xlab("Neighborhood Frequency") +
     ylab("ECDF") +
     theme(legend.position="top", legend.margin=margin(t = 0, unit='cm'))

ggsave("data/exp1/nbh_frequencies_different_t_ecdf.pdf", p, width=4.5, height=2.3)
