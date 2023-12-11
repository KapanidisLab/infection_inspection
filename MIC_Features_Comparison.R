###LOAD LIBRaries
{
  library('vegan')
  library('ggplot2')
  library('dplyr')
  library('reshape2')
  library('Hmisc')
  library('tidyverse')
  library('rstatix')
  library('egg')
  library('ggpubr')
  library('cowplot')
  library('scales')
  library('ggfortify')
  library('ggside')
  library('cluster')
}

###>>>-------<<<###
#getting the datasets in order
###>>>-------<<<###
userdata <- read.csv("DATASET.csv", header = TRUE)
userdata <- userdata %>% filter(dataset == "Test")
names(userdata)
columns_to_keep <- c("Our_ID",
                     "strain",
                     "MIC",
                     "treatment_concentration",
                     "classification",
                     "dataset",
                     "expected_response")
alldata <- userdata %>%
  select(all_of(columns_to_keep))
dim(alldata)
alldata<-alldata %>% filter(classification != "Image processing error")
alldata<-group_by(alldata, Our_ID) %>% slice(1)

featuresdata <- read.csv("FEATURES_DF.csv", header = TRUE)

mergeddata <- merge(alldata,featuresdata,by = "Our_ID",all=F)

mergeddata$treatment_concentration <- as.factor(mergeddata$treatment_concentration)
mergeddata$strain <- as.factor(mergeddata$strain)
mergeddata$MIC <- as.factor(mergeddata$MIC)

### Remove irrelevant columns
data <- mergeddata[, -c(1)] # delete columns 5 through 7
data <- data[, -c(4:9)] # delete columns 5 through 7
data <- data[, -c(10:11)] # delete columns 5 through

data <- na.omit(data)
rm(alldata)
rm(userdata)
rm(featuresdata)
rm(mergeddata)
titrationdata <- subset(data, MIC == 0.5)

# I separate the data into two separate dataframes. One for metadata and one for features
# The row order will remain the same so they can be rejoined later
meta <- titrationdata[,1:3]
features <- titrationdata[,4:10]
features$Nucleoid_AreaFraction <- as.numeric(features$Nucleoid_AreaFraction)

pca_res <- prcomp(features,
                  scale = TRUE)

ap_whole <- autoplot(pca_res, 
                     data=titrationdata, 
                     colour='treatment_concentration',
                     size = 1,
                     scale = 0,
                     alpha = 0.5)
ap_whole

pcaplot <- ggplot(pca_res, aes(PC1,PC2))+
  stat_density_2d(aes(alpha=..level.., 
                      fill=titrationdata$treatment_concentration), 
                  bins=2, 
                  geom="polygon",
                  colour="black")+
  scale_fill_brewer(palette="Spectral", direction=-1)+
  theme_bw()+
  scale_y_reverse()+
  scale_x_reverse()+
  labs(fill = "treatment concentration (mg/L)") +
  guides(alpha=F)
pcaplot
ggsave("PCA_TITRATION_CLUSTERS_Coloured_Reversed.png",w=10,h=6,dpi=600)
