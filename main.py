# -*- coding: utf-8 -*-
"""
Created on Wed Feb 15 15:39:58 2023

@author: farrara
"""

from get_data import get_ID_lists, get_strains, build_feature_df, make_labelled_feature_dfs, add_titrations_columns, get_arrays
from PCA_functions import Principal_Component_Analysis, Principal_Component_Analysis_Most_Correct
from SHAP_functions import tree_model_shap_NEW, plot_shap_summary
import numpy as np
from sklearn.model_selection import train_test_split

DF_PATH = r'DF.csv'
THRESHOLD = 0.5
IMAGE_ERROR_THRESHOLD = 0.5
CORRECT_THRESHOLD = 0.94

FEATURE_PATH = 'PATH.CSV'
# fileNamesPath = r'H:\zooniverse_file_names.csv'

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
    df = add_titrations_columns(resistant_05_list, resistant_16_list, df)
    X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC = get_arrays(df)

    # Add a column of random noise to X
    X_noise = np.random.normal(size=(X.shape[0], 1))
    X = np.hstack((X, X_noise))
    FEATURES_LIST.append("Random Noise")

    # Train-Test Splits
    X_train, X_test, Y_train, Y_test = train_test_split(X, Y_Resistant, random_state=0)
    

    # PCA with Scaling
    Principal_Component_Analysis(X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC, style="Highlight Corrects")
    Principal_Component_Analysis(X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC, style="Highlight Incorrects")
    Principal_Component_Analysis_Most_Correct(X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC, style="Highlight Most Correct")

    '''Tree Model with SHAP Explanations'''
    # For sensitive
    model_corrects, explainer_corrects, shap_values_corrects, shap_summary, scores = tree_model_shap_NEW(X_train, X_test, Y_train, Y_test, FEATURES_LIST)
    shap_summary.to_csv('shap_summary_withRandomNoise.csv')
    violin, stripplot, cat, bar, point = plot_shap_summary(shap_summary)