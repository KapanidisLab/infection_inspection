library(dplyr)
library(tidyr)
library(ggplot2)
library(reshape2)
library(ggpubr)

data <- read.csv("FEATURE_DF.csv", header = TRUE)
data$Incorrect <- as.factor(data$Incorrect)
levels(data$Incorrect) <- c("Correct","Incorrect")
data$Resistant <- as.factor(data$Resistant)
levels(data$Resistant) <- c("Sensitive","Resistant")
data$strain <- as.factor(data$strain)
data$MIC <- as.factor(data$MIC)

data <- data %>% 
  rename(
    Number.of.DNA.Regions = Image_Count_Nucleoid,
    Membrane.Form.Factor = Mean_Membrane_AreaShape_FormFactor,
    Membrane.Major.Axis.Length = Mean_Membrane_AreaShape_MajorAxisLength,
    DNA.Mean.Integrated.Intensity = Mean_Nucleoid_Intensity_IntegratedIntensity_DAPI,
    DNA.Standard.Deviation.of.Integrated.Intensity = StDev_Nucleoid_Intensity_IntegratedIntensity_DAPI,
    DNA.Mean.Standard.Deviation.of.Intensity = Mean_Nucleoid_Intensity_StdIntensity_DAPI,
    Nucleoid.Area.Fraction = Nucleoid_AreaFraction
  )

data <- data[, -c(1:3)] # delete columns 5 through 7
data <- data[, -c(7:8)] # delete columns 5 through 7
data <- data[, -c(13)] # delete columns 5 through 7

data_long <- melt(data, id.vars = c("Our_ID", 
                                    "strain", 
                                    "MIC", 
                                    "Incorrect", 
                                    "Resistant", 
                                    "Target"), 
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

data_long <- na.omit(data_long) 

# fill = "Target",
bxp <- ggboxplot(data_long, 
                 y = "value", 
                 color="black",
                 palette = c("#2e8b57", "#81d5a6", "#4660bf", "#000080"),
                 fill = "Target",
                 scales = "free", alpha=0.6, notch=TRUE, short.panel.labs = TRUE) +
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
ggsave("Features_Comparison_WithoutPValues_ForTable_Flipped.png",w=7,h=10,dpi=600)

