library(dplyr)
library(tidyr)
library(ggplot2)
library(reshape2)
library(ggpubr)

data <- read.csv('FEATURES_DF_COMPARISON.csv', header=TRUE)

data_long <- melt(data, id.vars = c("Our_ID", 
                                    "MIC", 
                                    "Incorrect", 
                                    "Resistant", 
                                    "Target",
                                    "model_call",
                                    "model_target",
                                    "agreement"), 
                  measure.vars = c("Number.of.DNA.Regions", 
                                   "Membrane.Form.Factor", 
                                   "Membrane.Major.Axis.Length", 
                                   "DNA.Mean.Integrated.Intensity", 
                                   "DNA.Standard.Deviation.of.Integrated.Intensity", 
                                   "DNA.Mean.Standard.Deviation.of.Intensity", 
                                   "Nucleoid.Area.Fraction"))

levels(data_long$variable) <- c("# of DNA Regions",
                               "Membrane Form Factor",
                               "Membrane Major Axis Length",
                               "DNA Mean Integrated Intensity",
                               "DNA Standard Deviation of Integrated Intensity",
                               "DNA Mean Standard Deviation of Intensity",
                               "Nucleoid Area Fraction")
data_long$Target <- factor(data_long$Target, 
                              levels = c("Correct Resistant", 
                              "Incorrect Resistant", 
                              "Incorrect Sensitive", 
                              "Correct Sensitive"),
                           ordered=TRUE)

data_long$model_target <- factor(data_long$model_target, 
                           levels = c("Correct Resistant", 
                                      "Incorrect Resistant", 
                                      "Incorrect Sensitive", 
                                      "Correct Sensitive"),
                           ordered=TRUE)

data_long <- na.omit(data_long)

###>>>-------<<<###
# Feature analysis for users
###>>>-------<<<###

# fill = "Target",
bxp <- ggboxplot(data_long, 
                 y = "value", 
                 color="black",
                 palette = c("#2e8b57", "#81d5a6", "#4660bf", "#000080"),
                 fill = "Target",
                 scales = "free", alpha=0.6, notch=TRUE, short.panel.labs = TRUE) +
  #geom_pwc(aes(group = Target), tip.length = 0, method = "t_test", label = "{p.adj.format}", p.adjust.method = "bonferroni", p.adjust.by = "panel", hide.ns = FALSE) + 
  theme(panel.border = element_rect(colour="black", fill=NA, linewidth = 1),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank())+
  theme(legend.position = "right",
        legend.title = element_blank(),
        legend.text = element_text(size=14)) +
  theme(axis.title.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        axis.title.y=element_blank())

bxp <- bxp + facet_wrap(vars(variable),
                 nrow=7,
                 scales = "free")
bxp <- bxp + theme(strip.text.x = element_blank(),
               axis.text.y = element_blank()) + coord_flip()
bxp
ggsave("Features_Comparison_WithoutPValues_ForTable_Flipped.png",w=7,h=10,dpi=300)




###>>>-------<<<###
# Feature analysis for model
###>>>-------<<<###

# fill = "Target",
bxp_m <- ggboxplot(data_long, 
                 y = "value", 
                 color="black",
                 palette = c("#2e8b57", "#81d5a6", "#4660bf", "#000080"),
                 fill = "model_target",
                 scales = "free", alpha=0.6, notch=TRUE, short.panel.labs = TRUE) +
  #geom_pwc(aes(group = model_target), tip.length = 0, method = "t_test", label = "{p.adj.format}", p.adjust.method = "bonferroni", p.adjust.by = "panel", hide.ns = FALSE) + 
  theme(panel.border = element_rect(colour="black", fill=NA, linewidth = 1),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank())+
  theme(legend.position = "right",
        legend.title = element_blank(),
        legend.text = element_text(size=14)) +
  theme(axis.title.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        axis.title.y=element_blank())

bxp_m <- bxp_m + facet_wrap(vars(variable),
                        nrow=7,
                        scales = "free")
bxp_m <- bxp_m + theme(strip.text.x = element_blank(),
                   axis.text.y = element_blank()) + coord_flip()

bxp_m
ggsave("Features_Comparison_WithoutPValues_ForTable_Flipped_Model.png",w=7,h=10,dpi=300)



###>>>-------<<<###
# Combined analysis
###>>>-------<<<####

# Compare model vs user calls
p <- ggplot(data_long, aes(x = agreement, y = value, color = agreement)) +
  geom_boxplot() +
  stat_pwc(aes(group = agreement), method = "t_test", label = "p.adj", p.adjust.method = "bonferroni", hide.ns = FALSE) +
  facet_wrap(~ variable + Resistant, scales = "free", nrow=2) +
  theme(panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank()) +
  theme(legend.position = "right",
        legend.title = element_blank(),
        legend.text = element_text(size = 14)) +
  theme(axis.title.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.title.y = element_blank())

# Display the plot
print(p)

# Compare sensitive vs resistant
p <- ggplot(data_long, aes(x = Resistant, y = value, color = Resistant)) +
  geom_boxplot() +
  stat_pwc(aes(group = Resistant), method = "t_test", label = "{p.adj.format}{p.adj.signif}", p.adjust.method = "bonferroni", hide.ns = FALSE, label.size=3) +
  facet_wrap(~ variable + agreement, scales = "free", ncol=2) +
  theme(panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank()) +
  theme(legend.position = "right",
        legend.title = element_blank(),
        legend.text = element_text(size = 12)) +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_text(size = 8),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.title.y = element_blank(),
        strip.text = element_text(size = 10)) +
  coord_flip()

# Display the plot
print(p)

ggsave('Variables_by_ModelUserAgreement.png', height = 26, width = 18, units="cm", dpi = 300)
