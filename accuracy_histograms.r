library(dplyr)
library(tidyr)
library(ggplot2)
library(reshape2)
library(ggpubr)

data <- read.csv("AVERAGE_SCORES.csv", header = TRUE)

# Adding column based on other column:
data <- data %>%
  mutate(Resistant = case_when(
    is.na(data$Resistant.Accuracies) ~ "Sensitive",
    !is.na(data$Resistant.Accuracies) ~ "Resistant"
  ))

data$Phenotype <- as.factor(data$Resistant)

# Merge columns ignoring NAs
data$Accuracies <- coalesce(data$Resistant.Accuracies, data$Sensitive.Accuracies)

p <- ggplot(data, aes(x=Accuracies)) +
  theme(panel.border = element_rect(colour="black", fill=NA, linewidth = 1),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank())+
  theme(legend.position = "right") + 
  facet_wrap(data$Phenotype) +
  geom_histogram(binwidth=0.05, colour="black", fill="lightgray") +
  theme(strip.text.x = element_text(size = 16))
p

ggsave("Accuracy_Histograms.png",w=10,h=6,dpi=600)

# How many are >= 0.5?
# Count the number of rows where Accuracies >= 0.5
countGreater <- data %>%
  filter(Accuracies >= 0.5) %>%
  summarise(count = n())

# Count the number of rows where Accuracies < 0.5
countLesser <- data %>%
  filter(Accuracies < 0.5) %>%
  summarise(count = n())

# Count most accurate >=0.94
countMost <- data %>%
  filter(Accuracies >= 0.94) %>%
  summarise(count = n())
