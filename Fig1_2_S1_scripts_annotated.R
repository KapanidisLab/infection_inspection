{
  # LOAD LIBRARIES
  {
    library('vegan')
    library('ggplot2')
    library('dplyr')
    library('reshape2')
    library('RVAideMemoire')
    library('Hmisc')
    library('tidyverse')
    library('rstatix')
    library('egg')
    library('ggpubr')
    library('cowplot')
    library('scales')
    library('ggside')
    #library(digest)
  }
  
  # >>> DATA LOADING <<< #
  # Getting the datasets in order
  alldata <- read.csv("DATA_ANON.csv")
  alldata <- alldata %>% filter(classification != "Image processing error")
  dim(alldata)
  alldata$classifier <- factor(alldata$classifier, levels = c("Zooniverse", "DL_Model"))
  
  # >>> SUMMARY STATS OF ENGAGEMENT <<< #
  count <- userdata %>%
    group_by(anon_name) %>%
    summarise(subject_ids = n()) %>%
    arrange(desc(subject_ids))
  
  count <- count %>%
    mutate(Project = "Infection_Inspection")
  
  count$subject_log <- log(count$subject_ids)
  count <- count %>% 
    rename(Classification_per_user = subject_ids)
  names(count)
  dim(count)
  
  write.csv(count, "classification_counts_per_user_ex_training.csv")
  
  # Plotting
  library(gghalves)
  library(ggdist)
  
  ggplot(count, aes(x = Project, y = Classification_per_user)) + 
    ggdist::stat_halfeye(adjust = 0.4,
                         width = 0.3,
                         .width = 0,
                         justification = -0.25,
                         point_colour = NA,
                         fill = "#8c6bb1",
                         alpha = 0.8,
                         size = 10) + 
    geom_boxplot(width = 0.10,
                 outlier.shape = NA) +
    gghalves::geom_half_point(
      side = "l", 
      range_scale = 0.5, 
      alpha = 0.2,
      fill = "#8c6bb1",
      size = 0.5)  +
    scale_y_continuous(trans = 'log10') +
    theme(panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          axis.text.x = element_blank(),
          axis.text = element_text(size = 18),
          axis.title = element_text(size = 20)) +
    labs(y = "Classifications per user", x = "Infection \nInspection")
  
  ggsave('Classifications_per_user_ex_training.png', height = 4.5, width = 3, dpi = 600)
  
}

{
  # Top 20 users
  # Count the occurrences of each user_name
  user_counts <- table(userdata$anon_name)
  
  # Get the top 20 user_names
  top20_user_names <- names(user_counts)[order(user_counts, decreasing = TRUE)][1:20]
  
  # Create a data frame with user_name and count of entries
  top20_table <- data.frame(anon_name = top20_user_names, entries = user_counts[top20_user_names])
  
  # Print the table
  top20_table$anon_name
  
  library(plotly)
  
  # Plotting top 20 users in a table using Plotly
  plot_ly(
    type = "table",
    columnwidth = c(5, 5),
    columnorder = c(0, 1),
    header = list(
      values = c("User", "Classifications"),
      align = c("left", "left"),
      line = list(width = 1, color = "grey"),
      fill = list(color = c("#FFFFFF", "#FFFFFF")),
      font = list(size = 14, color = "#000000"),
      height = 40),
    cells = list(values = rbind(top20_table$anon_name, top20_table$entries.Freq),
                 align = c("left", "left"),
                 line = list(width = 1, color = "grey"),
                 font = list(size = 12, color = "#000000")))
  
  # Plotting classifications per day
  classifications_per_day <- userdata %>%
    dplyr::group_by(day) %>%
    dplyr::summarize(classifications_count = n())
  
  names(classifications_per_day)
  classifications_per_day$day <- as.numeric(classifications_per_day$day)
  
  ggplot(classifications_per_day, aes(x = day, y = classifications_count)) +
    geom_bar(stat = "identity", fill = "#43a2ca", colour = "black") +
    labs(x = "Day", y = "Classifications") +
    theme_minimal() +
    scale_x_continuous(breaks = seq(0, max(classifications_per_day$day), by = 10)) +
    theme(panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),axis.text = element_text(size = 20),
          axis.title = element_text(size = 20)) +
    scale_y_continuous(expand = c(0, 0))
  
  ggsave('classifications_per_day.png', height = 4, width = 6, dpi = 600)
  
  # Plotting the top ten users' engagement over time
  user_counts <- table(userdata$anon_name)
  
  top20 <- subset(userdata, anon_name %in% names(user_counts[user_counts >= 6954]))
  names(top20)
  top20$day <- as.numeric(top20$day)
  
  top20$anon_name <- factor(top20$anon_name , levels = c("User_1008", "User_3060",
                                                         "User_1264", "User_928",
                                                         "User_3682", "User_3208",
                                                         "User_3412", "User_1697",
                                                         "User_1795", "User_4095",
                                                         "User_2014", "User_4240",
                                                         "User_381", "User_3636",
                                                         "User_3309", "User_2862",
                                                         "User_3035", "User_2800",
                                                         "User_3401", "User_1252"))
  
  my_palette <- c('#8dd3c7', '#ffffb3', '#bebada', '#fb8072', '#80b1d3', '#fdb462', '#b3de69', '#fccde5', '#d9d9d9', '#bc80bd',
                  '#ccebc5', '#ffed6f', '#8c6bb1', '#e34a33', '#1f78b4', '#33a02c', '#fdbf6f', '#b15928', '#a6cee3', '#cab2d6')
  
  ggplot(top20, aes(x = day, fill = anon_name)) +
    geom_density(alpha = 0.7) +
    labs(x = "Day", y = "Density") +
    scale_fill_manual(name = "Top 20 users", values = my_palette) +
    scale_x_continuous(breaks = seq(0, max(top20$day), by = 10)) +
    theme(panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          legend.position = c(0.35, 0.70),  # Adjust the values to move the legend within the plot area
          legend.background = element_rect(fill = "transparent", color = NA),
          legend.box.background = element_rect(fill = "transparent", color = NA),
          legend.key = element_rect(fill = "transparent", color = NA),
          legend.text = element_text(size = 16),
          legend.title = element_text(size=18),
          axis.text = element_text(size = 20),
          axis.title = element_text(size = 20)) +
    scale_y_continuous(expand = c(0, 0))+
    guides(fill = guide_legend(ncol = 3)) 
  
  ggsave('top20_users_engagement_over_time.png', height = 5, width = 8, dpi = 600)
  
}

{
  ###>>>-------<<<###
  # Accuracy of users and model aggregated
  ###>>>-------<<<###
  
  # Zooniverse Data
  dataZN <- alldata %>% filter(classifier == "Zooniverse")
  
  # Factorize user_call and classification variables
  dataZN$user_call <- factor(dataZN$user_call, levels = c("Incorrect", "Correct"))
  dataZN$classification <- factor(dataZN$classification, levels = c("Resistant", "Sensitive", "Image processing error"))
  dim(dataZN)
  
  # Convert treatment_concentration to numeric
  dataZN$treatment_concentration <- as.numeric(dataZN$treatment_concentration)
  
  # Grouped by subject_ids for Zooniverse
  dataZNlist <- table(dataZN$subject_ids)
  

  # Aggregated accuracy for Zooniverse
  dataZN_percent <- dataZN %>%
    group_by(classifier, expected_response, user_call) %>%
    summarise(Count = n()) %>%
    mutate(Percentage = ifelse(user_call == "Correct", Count / sum(Count) * 100, 0)) %>%
    mutate(CI = (1.96 * sqrt(((Percentage/100) * (1 - (Percentage/100))) / Count) + (0.5/Count)) * 100) #95CI by Wald Method with continuity correction
    
  # Plotting accuracy for Zooniverse (only "Correct" user_call)
  znpercent_correct <- ggplot(dataZN_percent, aes(expected_response, Percentage)) +
    geom_bar(colour = "black", width = 0.7, stat = "identity", fill = "#43a2ca") +
    geom_errorbar(aes(ymin = Percentage - CI, ymax = Percentage + CI), width = 0.2) +
    geom_text(aes(label = ifelse(Percentage > 5, paste0(sprintf("%.1f", Percentage), "%"), "")),
              vjust = -0.5, size = 5, color = "black") +  # Add text annotations, show only if Percentage > 5
    ylab("Percentage correct") +
    xlab("Expected \nciprofloxacin phenotype") +
    theme_bw() +
    theme(axis.text.x = element_text(size = 16),
          axis.text.y = element_text(size = 20),
          axis.title.x = element_text(size = 17),
          axis.title.y = element_text(size = 20),
          legend.text = element_text(size=20),
          legend.title=element_text(size=20),
          strip.text = element_text(size = 16),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          axis.line = element_line(colour = "black"),
          panel.border = element_rect(colour = "black", fill = NA, linewidth = 1)) +
    facet_wrap(~ classifier, nrow = 1) +
    scale_y_continuous(expand = c(0, 0), limits = c(0, 100)) +  # Set the y-axis limits
    labs(fill = "Call")
  
  znpercent_correct
  
  ggsave('Accuracy_of_expected_phenotype_all_test_data_users.png', height = 5, width = 6, dpi = 300)
  
  # Model Data
  dataModel <- alldata %>% filter(classifier == "DL_Model")
  
  # Factorize user_call and classification variables
  dataModel$user_call <- factor(dataModel$user_call, levels = c("Incorrect", "Correct"))
  dataModel$classification <- factor(dataModel$classification, levels = c("Resistant", "Sensitive", "Image processing error"))
  dim(dataModel)
  
  # Convert treatment_concentration to numeric
  dataModel$treatment_concentration <- as.numeric(dataModel$treatment_concentration)
  
  # Grouped by subject_ids for DL_Model
  dataZNlist <- table(dataModel$subject_ids)
  
  # Aggregated accuracy for DL_Model
  dataModel_percent <- dataModel %>%
    group_by(classifier, expected_response, user_call) %>%
    summarise(Count = n()) %>%
    mutate(Percentage = ifelse(user_call == "Correct", Count / sum(Count) * 100, 0)) %>%
    mutate(CI = (1.96 * sqrt(((Percentage/100) * (1 - (Percentage/100))) / Count) + (0.5/Count)) * 100) #95CI by Wald Method with continuity correction
  
  # Plotting accuracy for Zooniverse (only "Correct" user_call)
  modelpercent <- ggplot(dataModel_percent, aes(expected_response, Percentage)) +
    geom_bar(colour = "black", width = 0.7, stat = "identity", fill = "#43a2ca") +
    geom_errorbar(aes(ymin = Percentage - CI, ymax = Percentage + CI), width = 0.2) +
    geom_text(aes(label = ifelse(Percentage > 5, paste0(sprintf("%.1f", Percentage), "%"), "")),
              vjust = -0.5, size = 5, color = "black") +  # Add text annotations, show only if Percentage > 5
    ylab("Percentage correct") +
    xlab("Expected \nciprofloxacin phenotype") +
    theme_bw() +
    theme(axis.text.x = element_text(size = 16),
          axis.text.y = element_text(size = 20),
          axis.title.x = element_text(size = 17),
          axis.title.y = element_text(size = 20, colour = "white"),
          legend.text = element_text(size=20),
          legend.title=element_text(size=20),
          strip.text = element_text(size = 16),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          axis.line = element_line(colour = "black"),
          panel.border = element_rect(colour = "black", fill = NA, linewidth = 1)) +
    facet_wrap(~ classifier, nrow = 1) +
    scale_y_continuous(expand = c(0, 0), limits = c(0, 100)) +  # Set the y-axis limits
    labs(fill = "Call")
  
  modelpercent
  
  
  
  ggsave('Model_Accuracy_of_expected_phenotype_all_test_data.png', height = 5, width = 6, dpi = 300)
  
  # Arranging plots side by side
  arranged_plot <- ggarrange(znpercent_correct, modelpercent, ncol = 2, common.legend = TRUE, legend = "bottom")
  arranged_plot
  ggsave("Fig2_a.png", plot = arranged_plot, width = 6.6, height = 4, dpi = 300)
  
}

{
  ###>>>-------<<<###
  # Titration accuracy of both users and model 
  ###>>>-------<<<###
  
  # Accuracy for users by strain and concentration
  {
    names(dataZN)
    
    titration_data <- subset(dataZN, anon_strain %in% c("EC1", "EC3"))
    unique(titration_data$treatment_concentration)
    titration_data <- subset(titration_data, treatment_concentration %in% c(0.000, 8.000, 0.500, 0.010, 1.000,
                                                                            4.000, 16.000, 0.001, 2.000, 0.100))
    
    count_data <- titration_data %>%
      group_by(classifier, anon_strain, treatment_concentration, user_call) %>%
      summarise(count = n()) %>%
      pivot_wider(names_from = user_call, values_from = count, values_fill = 0)
    
    count_data <- count_data %>%
      mutate(total = Correct + Incorrect, percentage_correct = Correct * 100 / total) %>%
      mutate(CI = (1.96 * sqrt(((percentage_correct/100) * (1 - (percentage_correct/100))) / total) + (0.5/total))
    
    custom_colors <- c('#80b1d3', '#b35806')
    
    count_data$anon_strain <- factor(count_data$anon_strain, levels = c('EC1', 'EC3'))
    
    custom_labels <- function(x) {
      labels <- c("0", "0.001", "0.01", "0.1", "0.5", "1", "2", "4", "8", "16")
      labels[labels %in% as.character(x)] <- x[labels %in% as.character(x)]
      return(labels)
    }
    
    p <- ggplot(count_data, aes(x = treatment_concentration, y = percentage_correct, group = anon_strain, color = anon_strain)) +
      geom_line(linewidth = 1) + 
      geom_point(size = 4, shape = 16) +  
      geom_errorbar(aes(ymin=percentage_correct-CI, ymax=percentage_correct+CI), width=.2) +
      geom_vline(xintercept = unique(count_data$treatment_concentration), 
                 linetype = "dashed", color = "#bdbdbd", linewidth = 0.2) +  
      labs(x = "Treatment Concentration \n(mg/l)", y = "Percentage of Correct") +
      scale_y_continuous(labels = scales::percent_format(scale = 1),
                         expand = c(0, 0), limits = c(0, 100)) +
      theme_bw() +
      theme(
        axis.text.x = element_text(size = 14, angle = 45, hjust = 1),
        axis.text.y = element_text(size = 14),
        axis.title.x = element_text(size = 18),
        axis.title.y = element_text(size = 20),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.text=element_text(size=18),
        legend.title = element_text(size=18),
        axis.line = element_line(colour = "black"),
        panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),
        strip.text = element_text(size = 16)
      ) +
      theme(legend.position = "bottom") +
      scale_color_manual(values = custom_colors) +
      facet_wrap(~ classifier) +
      guides(color = guide_legend(title = "Strain")) +
      scale_x_log10(breaks = c(0, 0.001, 0.01, 0.1, 0.5, 1, 2, 4, 8, 16), labels = custom_labels)
    
    # Add annotation to each facet
    annotation_data <- data.frame(
      anon_strain = unique(count_data$anon_strain),
      x_coord = c(0.008, 0.5),  # Adjust as needed
      y_coord = rep(10, 2)       # Adjust y-coordinate as needed
    )
    
    p <- p + geom_text(data = annotation_data, aes(x = x_coord, y = y_coord + 5, label = c("EC1 MIC", "EC3 MIC")),
                       size = 4, angle = 0, hjust = 0.5) +
      geom_segment(data = annotation_data, aes(x = x_coord, xend = x_coord,
                                               y = y_coord, yend = y_coord + -5),
                   arrow = arrow(type = "closed", length = unit(3, "mm")), color = "black")
    
    p
    ggsave("Percentage_accuracy_by_strain_and_concentration.png", plot = p, width = 7, height = 8, dpi = 300)
  }
  
  # Accuracy for model by strain and concentration
  {
    titration_data_model <- subset(dataModel, anon_strain %in% c("EC3", "EC1"))
    titration_data_model <- subset(titration_data_model, treatment_concentration %in% c(0.000, 8.000, 0.500, 0.010, 1.000,
                                                                                        4.000, 16.000, 0.001, 2.000, 0.100))
    
    count_data <- titration_data_model %>%
      group_by(classifier, anon_strain, treatment_concentration, user_call) %>%
      summarise(count = n()) %>%
      pivot_wider(names_from = user_call, values_from = count, values_fill = 0)
    
    count_data <- count_data %>%
      mutate(total = Correct + Incorrect, percentage_correct = Correct * 100 / total) %>%
      mutate(CI = (1.96 * sqrt(((percentage_correct/100) * (1 - (percentage_correct/100))) / total) + (0.5/total)) * 100)
    
    custom_colors <- c('#80b1d3', '#b35806')
    
    count_data$anon_strain <- factor(count_data$anon_strain, levels = c('EC1', 'EC3'))
    
    custom_labels <- function(x) {
      labels <- c("0", "0.001", "0.01", "0.1", "0.5", "1", "2", "4", "8", "16")
      labels[labels %in% as.character(x)] <- x[labels %in% as.character(x)]
      return(labels)
    }
    
    M <- ggplot(count_data, aes(x = treatment_concentration, y = percentage_correct, group = anon_strain, color = anon_strain)) +
      geom_line(linewidth = 1) + 
      geom_point(size = 4, shape = 16) +  
      geom_errorbar(aes(ymin=percentage_correct-CI, ymax=percentage_correct+CI), width=.2) +
      geom_vline(xintercept = unique(count_data$treatment_concentration), 
                 linetype = "dashed", color = "#bdbdbd", linewidth = 0.2) +  
      labs(x = "Treatment Concentration \n(mg/l)", y = "Percentage of Correct") +
      scale_y_continuous(labels = scales::percent_format(scale = 1),
                         expand = c(0, 0), limits = c(0, 100)) +
      theme_bw() +
      theme(
        axis.text.x = element_text(size = 14, angle = 45, hjust = 1),
        axis.text.y = element_text(size = 14, colour="white"),
        axis.title.x = element_text(size = 18),
        axis.title.y = element_text(size = 20, colour="white"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.text=element_text(size=18),
        legend.title = element_text(size=18),
        axis.line = element_line(colour = "black"),
        panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),
        strip.text = element_text(size = 16)
      ) +
      theme(legend.position = "bottom") +
      scale_color_manual(values = custom_colors) +
      facet_wrap(~ classifier, labeller = as_labeller(c(DL_Model = "DL Model"))) +
      scale_x_log10(breaks = c(0, 0.001, 0.01, 0.1, 0.5, 1, 2, 4, 8, 16), labels = custom_labels) + 
      guides(color = guide_legend(title = "Strain"))
    
    # Add annotation to each facet
    annotation_data <- data.frame(
      anon_strain = unique(count_data$anon_strain),
      x_coord = c(0.008, 0.5),  # Adjust as needed
      y_coord = rep(10, 2)       # Adjust y-coordinate as needed
    )
    
    M <- M + geom_text(data = annotation_data, aes(x = x_coord, y = y_coord + 5, label = c("EC1 MIC", "EC3 MIC")),
                       size = 4, angle = 0, hjust = 0.5) +
      geom_segment(data = annotation_data, aes(x = x_coord, xend = x_coord,
                                               y = y_coord, yend = y_coord + -5),
                   arrow = arrow(type = "closed", length = unit(3, "mm")), color = "black")
    M
    ggsave("Model_Percentage_accuracy_by_strain_and_concentration.png", plot = M, width = 7, height = 8, dpi = 300)
  }
  
  # Arrange plots side by side
  Fig2B <- ggarrange(p, M, ncol = 2, common.legend = TRUE, legend = "bottom")
  ggsave("Fig2_b.png", plot = Fig2B, width = 8, height = 4.5, dpi = 300)
  
}

{
  ###>>>-------<<<###
  # Classifications versus accuracy
  ###>>>-------<<<###
  
  # Count the occurrences of each user_name
  user_accuracy <- alldata %>%
    count(anon_name) %>%
    rename(classifications = n)
  
  # Calculate the percentage of 'Correct' entries for each user_name
  correct_counts <- alldata %>%
    filter(user_call == "Correct") %>%
    count(anon_name) %>%
    rename(correct_classifications = n)
  
  # Merge the two dataframes based on user_name
  accuracy <- left_join(user_accuracy, correct_counts, by = "anon_name")
  
  # Calculate the percentage
  accuracy <- accuracy %>%
    mutate(percentage = (correct_classifications / classifications) * 100)
  
  # Calculate the logarithm of classifications
  accuracy <- accuracy %>%
    mutate(log_classifications = log10(classifications))
  
  # Define the breaks for classification ranges
  breaks <- seq(0, max(accuracy$classifications, na.rm = TRUE) + 100, by = 100)
  
  # Define custom labels in the desired format
  labels <- sprintf("%s-%s", breaks[-length(breaks)], breaks[-1])
  
  # Group user_name into classification ranges with custom labels
  accuracy$classification_range <- cut(accuracy$classifications, breaks = breaks, include.lowest = TRUE, right = TRUE, labels = labels)
  
  # Sort the dataframe by log_classifications in descending order
  accuracy <- accuracy %>%
    arrange(desc(percentage))
  
  summary_days <- alldata %>%
    group_by(anon_name) %>%
    summarise(num_days = n_distinct(day))
  
  # Merge accuracy with the summary of days
  merged_accuracy <- merge(accuracy, summary_days, by = "anon_name")
  

  # Plotting the first figure (FigS1A)
  ggplot(merged_accuracy, aes(percentage, classification_range, colour = classification_range)) +
    geom_jitter(col = "#fec44f", size = 0.8, fill = "black", alpha = 0.9) +
    geom_boxplot(col = "black", alpha = 0.8) +
    ylab("Accuracy (%)") +
    labs(colour = "") +
    ylab("Intervals of classifications (100's)") +
    xlab("Percentage") +
    coord_flip() +
    theme(panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          axis.text.y = element_text(size = 20),
          axis.text.x = element_text(size = 14),
          axis.title = element_text(size = 20)) +
    scale_fill_brewer(palette = "Dark2") +
    theme(legend.position = "none") +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))
  
  ggsave("FigS1A.png", w = 10, h = 6, dpi = 600)
  
  # Plotting the second figure (FigS1B)
  merged_accuracy <- merged_accuracy %>%
    mutate(num_days_label = ifelse(num_days == 1, "1 day",
                                   ifelse(num_days == 2, "2 days",
                                          ifelse(num_days == 3, "3 days",
                                                 ifelse(num_days == 4, "4 days",
                                                        ifelse(num_days == 5, "5 days",
                                                               paste(num_days, "days", sep = " ")))))))
  
  merged_accuracy$num_days_label <- factor(merged_accuracy$num_days_label, levels = c("1 day", "2 days", "3 days", "4 days", "5 days",
                                                                                      "6 days", "7 days", "8 days", "9 days", "10 days",
                                                                                      "11 days", "12 days", "13 days", "14 days", "15 days",
                                                                                      "16 days", "17 days", "18 days", "19 days", "20 days",
                                                                                      "21 days", "24 days", "26 days", "35 days", "39 days"))
  
  ggplot(merged_accuracy, aes(percentage, num_days_label, colour = num_days_label)) +
    coord_flip() +
    geom_jitter(col = "grey", size = 0.8, fill = "black", alpha = 0.8) +
    geom_boxplot(col = "black", alpha=0.8) +
    ylab("Accuracy (%)") +
    labs(colour = "") +
    ylab("Days active") +
    xlab("Percentage") +
    theme(panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          axis.text = element_text(size = 18),
          axis.title = element_text(size = 20)) +
    scale_fill_brewer(palette = "Dark2") +
    theme(legend.position = "none") +
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1))
  
  ggsave("FigS1B.png", w = 10, h = 6, dpi = 600)
  
  # Save accuracy data to a CSV file
  write.csv(accuracy, "accurate_scores.csv")
  
}
