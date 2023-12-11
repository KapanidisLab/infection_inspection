# infection_inspection
Python and R scripts for data analysis of https://www.zooniverse.org/projects/conor-feehily/infection-inspection

## R scripts
Fig1_2_S1_scripts_annotated.R : accuracy and participation analysis
Features_Measurements_Comparison.R : box plot of feature measurements
MIC_Features_Comparsion.R : PCA of features with density plot by treatment concentration
Resistants_SHAP_pairwise_script.R : plots SHAP values of resistant features
Resistants_pairwise_script_withRandomNoise.R : adds random noise element to SHAP analysis
Incorrects_SHAP_pairwise_Script.R : like above, but with incorrect images (correct < 50% of users)
accuracy_histograms.R : histogram of all images by accuracy

## Python code for PCA
main.py : loads dataframes for classifications and features from CellProfiler
get_data.py : gets features and labels
SHAP_functions.py : SHAP analysis of models
PCA_functions.py : plots variations of PCA by incorrects, corrects, and most corrects
