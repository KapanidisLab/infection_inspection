library(dplyr)
library(tidyr)
library(ggplot2)
library(reshape2)
library(ggpubr)

data <- read.csv("incorrects_SHAP_pred_df.csv", header = TRUE)
data$prediction <- as.factor(data$prediction)
data$feature <- as.factor(data$feature)
names(data)

data_long <- melt(data, id.vars = c("X", "feature", "prediction"), measure.vars = c("contribution"))
data_long$feature <- as.factor(data_long$feature)
data_long$prediction <- as.factor(data_long$preditcion)
levels(data_long$prediction) <- c("Correct","Incorrect")
levels(data_long$feature) <- c("# of DNA Regions",
                               "Membrane Form Factor",
                               "Membrane Major Axis Length",
                               "Nucleoid Area Fraction",
                               "DNA Mean Integrated Intensity",
                               "DNA Mean Standard Deviation of Intensity",
                               "DNA Standard Deviation of Integrated Intensity")

colnames(data_long) <- c("Image_Num", "Feature", "Prediction", "Variable", "Contribution")

head(data_long)

bxp <- ggboxplot(data_long, x = "Feature", y = "Contribution",
               color = "Prediction",
               add = "jitter") +
  scale_color_manual(values = c("#2F5597","#e6550d"))+
  theme(panel.border = element_rect(colour="black", fill=NA, linewidth = 1),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank())+
  theme(legend.position = "bottom")

bxp + geom_pwc(
  aes(group = Prediction), tip.length = 0,
  method = "t_test", label = "{p.adj.signif}",
  p.adjust.method = "bonferroni", p.adjust.by = "panel",
  hide.ns = TRUE) + coord_flip()


ggsave("SHAP_Incorrects.png",w=10,h=6,dpi=600)




#########
#just did this to do between the features too
bxp2 <- ggboxplot(data_long, x = "Feature", y = "Contribution") +
  theme(panel.border = element_rect(colour="black", fill=NA, linewidth = 1),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank())+
  theme(legend.position = "bottom") + facet_wrap(~ Prediction, ncol = 1)

bxp2 + geom_pwc(
  aes(group = Feature), tip.length = 0,
  method = "t_test", label = "{p.adj.signif}", bracket.group.by = "x.var",
  show.legend = TRUE,
  hide.ns = FALSE) + coord_flip() #only the significant comparisons are showing

ggsave("SHAP_Incorrects_Features.png",w=10,h=6,dpi=600)
