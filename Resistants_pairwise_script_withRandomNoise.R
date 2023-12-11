library(dplyr)
library(tidyr)
library(ggplot2)
library(reshape2)
library(ggpubr)
library(forcats)

data <- read.csv("resistant_shap_withRandomNoise.csv", header = TRUE)
data$prediction <- as.factor(data$prediction)
data$feature <- as.factor(data$feature)
data$contribution <- abs(data$contribution)
names(data)

data_long <- melt(data, id.vars = c("X", "feature", "prediction"), measure.vars = c("contribution"))
data_long$feature <- as.factor(data_long$feature)
data_long$prediction <- as.factor(data_long$prediction)
levels(data_long$prediction) <- c("Sensitive","Resistant")
levels(data_long$feature) <- c("# of DNA Regions",
                               "Membrane Form Factor",
                               "Membrane Major Axis Length",
                               "Nucleoid Area Fraction",
                               "DNA Mean Integrated Intensity",
                               "DNA Mean Standard Deviation of Intensity",
                               "DNA Standard Deviation of Integrated Intensity",
                               "Random Noise")



colnames(data_long) <- c("Image_Num", "Feature", "Prediction", "Variable", "Contribution")
medians <- aggregate(Contribution ~ Feature, data = data_long, FUN= "median" )

head(data_long)

bxp <- ggboxplot(data_long, x = "Feature", y = "Contribution",
               color = "Prediction",
               add = "jitter") +
  scale_color_manual(values = c("#000080", "#2e8b57"),)+
  theme(panel.border = element_rect(colour="black", fill=NA, linewidth = 1),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank())+
  theme(legend.position = "bottom")

bxp + geom_pwc(
  aes(group = Prediction), tip.length = 0,
  method = "t_test", label = "{p.format}",
  p.adjust.method = "bonferroni", p.adjust.by = "panel",
  hide.ns = FALSE) + coord_flip() +
  labs(y ="Absolute Value of Feature Contribution", x = "Feature")


ggsave("SHAP_Resistants_abs.png",w=10,h=6,dpi=600)

bxp4 <- ggboxplot(data_long,
               x = "Feature",
               y = "Contribution",
               color="black",
               lwd = 1.05,
               fill = "#2e8b57",
               scales = "free", 
               alpha=0.6, 
               notch=TRUE, 
               short.panel.labs = TRUE,
               outlier.shape = 19) +
  theme(panel.border = element_rect(colour="black", fill=NA, linewidth = 1),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank())+
  theme(legend.position = "right",
        legend.title = element_blank(),
        legend.text = element_text(size=14))+
  coord_flip()
bxp4
ggsave("SHAP_Resistants_OVERALL_Features_abs_wRandomNoise_np.png",w=10,h=6,dpi=600)


