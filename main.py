# -*- coding: utf-8 -*-
"""
Created on Wed Feb 15 15:39:58 2023

@author: farrara
"""

from get_data import get_ID_lists, get_strains, build_feature_df, make_labelled_feature_dfs, add_titrations_columns, get_arrays
from PCA_functions import Principal_Component_Analysis, Principal_Component_Analysis_Most_Correct
#from SHAP_functions import tree_model_shap_NEW, plot_shap_summary
import numpy as np
import pandas as pd
#from sklearn.model_selection import train_test_split

DF_PATH = r'DATA_ANON.csv'
#MODEL_PATH = r'DL_model_on_zooniverse.csv'
THRESHOLD = 0.5
IMAGE_ERROR_THRESHOLD = 0.5
CORRECT_THRESHOLD = 0.94

FEATURE_PATH = r'FEATURES_DF_COMPARISON.csv'

FEATURES_LIST = ['# Nucleoids', 
                 'Membrane Form Factor', 
                 'Membrane MajorAxisLength', 
                 'Nucleoid Mean Integrated Intensity', 
                 'Nucleoid StD Integrated Intensity', 
                 'Nucleoid Mean Std Intensity',
                 'Nucleoid Area Fraction']
COLUMNS = ['Image_Count_Nucleoid',
           'Mean_Membrane_AreaShape_FormFactor',
           'Mean_Membrane_AreaShape_MajorAxisLength',
           'Mean_Nucleoid_Intensity_IntegratedIntensity_DAPI',
           'StDev_Nucleoid_Intensity_IntegratedIntensity_DAPI',
           'Mean_Nucleoid_Intensity_StdIntensity_DAPI',
           'Nucleoid_AreaFraction']

if __name__ == '__main__':
    
    incorrect_sensitive_list, correct_sensitive_list, incorrect_resistant_list, correct_resistant_list, most_correct_sensitive_list, most_correct_resistant_list, resistant_05_list, resistant_16_list = get_ID_lists(DF_PATH, THRESHOLD)
    strains_df = get_strains(DF_PATH)
    feature_df = build_feature_df(FEATURE_PATH, strains_df)
    df = make_labelled_feature_dfs(correct_sensitive_list, incorrect_sensitive_list, correct_resistant_list, incorrect_resistant_list, most_correct_sensitive_list, most_correct_resistant_list, feature_df)
    #df = add_titrations_columns(resistant_05_list, resistant_16_list, df)
    model_df = pd.read_csv(MODEL_PATH)
    ml_info = model_df[['Our_ID', 'expected_phenotype', 'ml_pred_label']]
    merged_df = pd.merge(ml_info, feature_df, on='Our_ID', how='inner')
    X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC, Y_ModelTargets, Y_Disagree = get_arrays(merged_df)

    # For SHAP analysis, not PCA: Add a column of random noise to X
    X_noise = np.random.normal(size=(X.shape[0], 1))
    X = np.hstack((X, X_noise))
    FEATURES_LIST.append("Random Noise")

    # Train-Test Splits
    X_train, X_test, Y_train, Y_test = train_test_split(X, Y_Resistant, random_state=0)

    # PCA with Scaling
    Principal_Component_Analysis(X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC, Y_ModelTargets, Y_Disagree, style="Highlight Corrects")
    Principal_Component_Analysis(X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC, Y_ModelTargets, Y_Disagree, style="Highlight Incorrects")
    Principal_Component_Analysis_Most_Correct(X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC, style="Highlight Most Correct")
    Principal_Component_Analysis(X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC, Y_ModelTargets, Y_Disagree, style="Model Corrects")
    Principal_Component_Analysis(X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC, Y_ModelTargets, Y_Disagree, style="Model Incorrects")
    Principal_Component_Analysis(X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC, Y_ModelTargets, Y_Disagree, style="Disagree")

    '''Tree Model with SHAP Explanations'''
    # For sensitive
    model_corrects, explainer_corrects, shap_values_corrects, shap_summary, scores = tree_model_shap_NEW(X_train, X_test, Y_train, Y_test, FEATURES_LIST)
    shap_summary.to_csv('shap_summary_withRandomNoise.csv')
    violin, stripplot, cat, bar, point = plot_shap_summary(shap_summary)
