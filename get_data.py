
import numpy as np
import pandas as pd

DF_PATH = r'DF.csv'
THRESHOLD = 0.5
IMAGE_ERROR_THRESHOLD = 0.5
CORRECT_THRESHOLD = 0.94

COLUMNS = ['Image_Count_Nucleoid',
           'Mean_Membrane_AreaShape_FormFactor',
           'Mean_Membrane_AreaShape_MajorAxisLength',
           'Mean_Nucleoid_Intensity_IntegratedIntensity_DAPI',
           'StDev_Nucleoid_Intensity_IntegratedIntensity_DAPI',
           'Mean_Nucleoid_Intensity_StdIntensity_DAPI',
           'Nucleoid_AreaFraction']

def get_ID_lists(df_path, threshold=THRESHOLD, image_error_threshold=IMAGE_ERROR_THRESHOLD, correct_threshold=CORRECT_THRESHOLD):
    '''
    For a given .csv path and threshold = (average match score)
    Return four lists of Our_IDs: correct resistant, 
    incorrect resistant, correct sensitive, incorrect sensitive
    '''

    # Read the csv as a Pandas DataFrame and extract the necessary columns
    df = pd.read_csv(df_path)
    df = df[['Our_ID','dataset','strain', 'MIC','treatment_concentration','classifier','user_call','expected_response']]

    test_df = df[df.dataset == 'Test']
    test_df = df[df.classifier == 'Zooniverse']

    #concentrations in mg/L
    # We should not use concentration 0 because it will appear resistant
    #    Feature analysis will be done with the 20X EUCAST concentration
    '''Remove rows where CIP_Concentration does not equal '[20]'''

    '''For each value in ['Our_ID'] find the number of times it has 'Classification' == Image processing error'''
    test_df['Image processing error'] = np.where(test_df['user_call'] == 'Image processing error', 1, 0)
    '''For each value in Our_ID find the average value of Image processing error'''
    avg_ImageProcessingError = test_df.groupby('Our_ID')['Image processing error'].mean()
    imageProcessingErrors = avg_ImageProcessingError[avg_ImageProcessingError > image_error_threshold]
    print(len(imageProcessingErrors))
    '''Remove rows where Our_ID is in imageProcessingErrors'''
    test_df = test_df[~test_df.Our_ID.isin(imageProcessingErrors.index)]
    test_df['Match_score'] = np.where(test_df['user_call'] == 'Correct', 1, 0)

    '''Split test_df into Cip_phenotype == 'Resistant' and Cip_phenotype == 'Sensitive' '''
    test_df_resistant = test_df[test_df.expected_response == 'Resistant']
    test_df_sensitive = test_df[test_df.expected_response == 'Sensitive']
    '''For each value in ['Our_ID'] find the average value of 'Match_score', plot as boxplot'''
    avg_scores_resistant = test_df_resistant.groupby('Our_ID')['Match_score'].mean()
    avg_scores_sensitive = test_df_sensitive.groupby('Our_ID')['Match_score'].mean()
    ''' Plot boxplots of avg_scores_resistant and avg_scores_sensitive'''
    avg_scores_df = pd.DataFrame(
        {'Resistant Accuracies': avg_scores_resistant, 
        'Sensitive Accuracies': avg_scores_sensitive})
    #avg_scores_df.plot.box()

    ''' Find the Our_IDs in test_df_resistant and test_df_sensitive that have a mean accuracy below the threshold '''
    incorrect_resistant = avg_scores_resistant[avg_scores_resistant < threshold]
    incorrect_sensitive = avg_scores_sensitive[avg_scores_sensitive < threshold]

    ''' Select the columns in test_df_sensitive that match the incorrect_sensitive Our_IDs '''
    incorrect_sensitive_df = test_df_sensitive[test_df_sensitive.Our_ID.isin(incorrect_sensitive.index)]
    correct_sensitive_df = test_df_sensitive[~test_df_sensitive.Our_ID.isin(incorrect_sensitive.index)]

    ''' Select the columns in test_df_resistant that match the incorrect_resistant Our_IDs '''
    incorrect_resistant_df = test_df_resistant[test_df_resistant.Our_ID.isin(incorrect_resistant.index)]
    correct_resistant_df = test_df_resistant[~test_df_resistant.Our_ID.isin(incorrect_resistant.index)]

    # Make lists with unique values of Our_ID in each of the four dataframes
    incorrect_sensitive_list = incorrect_sensitive_df.Our_ID.unique().tolist()
    correct_sensitive_list = correct_sensitive_df.Our_ID.unique().tolist()
    incorrect_resistant_list = incorrect_resistant_df.Our_ID.unique().tolist()
    correct_resistant_list = correct_resistant_df.Our_ID.unique().tolist()

    # Find the most correct Our_IDs
    most_correct_sensitive = avg_scores_sensitive[avg_scores_sensitive > correct_threshold]
    most_correct_resistant = avg_scores_resistant[avg_scores_resistant > correct_threshold]

    most_correct_sensitive_df = test_df_sensitive[test_df_sensitive.Our_ID.isin(most_correct_sensitive.index)]
    most_correct_resistant_df = test_df_resistant[test_df_resistant.Our_ID.isin(most_correct_resistant.index)]

    most_correct_sensitive_list = most_correct_sensitive_df.Our_ID.unique().tolist()
    most_correct_resistant_list = most_correct_resistant_df.Our_ID.unique().tolist()

     # Make lists with unique values of Our_ID where CIP_Concentration is 0.5 mg/L or 16 mg/L
    resistant_05_list = test_df_resistant[test_df_resistant.treatment_concentration == 0.5].Our_ID.unique().tolist()
    resistant_16_list = test_df_resistant[test_df_resistant.treatment_concentration == 16].Our_ID.unique().tolist()

    return incorrect_sensitive_list, correct_sensitive_list, incorrect_resistant_list, correct_resistant_list, most_correct_sensitive_list, most_correct_resistant_list, resistant_05_list, resistant_16_list

def get_strains(df_path):
    df = pd.read_csv(df_path)
    strains_df = df[['Our_ID','strain','MIC']]
    strains_df = strains_df.drop_duplicates(subset=['Our_ID'])
    return strains_df

def build_feature_df(feature_path, strains_df):
    '''
    From CSVs of features, build dataframes for membrane and nucleoid features
    '''

    # Read the csv as a Pandas DataFrame and extract the necessary columns
    feature_df = pd.read_csv(feature_path)
    # Make a new column 'Our_ID' that is the Image_FileName_RGB without the .png
    feature_df['Our_ID'] = feature_df['Image_FileName_RGB'].str[:-4]
    # Merge the feature_df with the strains_df
    feature_df = pd.merge(feature_df, strains_df, on='Our_ID', how='left')

    return feature_df

def make_labelled_feature_dfs(correct_sensitive_list, incorrect_sensitive_list, correct_resistant_list, incorrect_resistant_list, most_correct_sensitive_list, most_correct_resistant_list, df):
    '''
    For a given list of Our_IDs and a dataframe of features, add a column 'Resistant' to the 
    dataframe with a value 1 if df['Our_ID'] is in the list, else 0

    df['Target']: {0: correct_sensitive, 1: incorrect_sensitive, 2: correct_resistant, 3: incorrect_resistant}
    '''

    df_new = df[df['Our_ID'].isin(incorrect_sensitive_list + correct_sensitive_list + incorrect_resistant_list + correct_resistant_list)].copy()
    df_new['Incorrect'] = np.where(df_new['Our_ID'].isin(incorrect_sensitive_list + incorrect_resistant_list), 1, 0)
    df_new['Resistant'] = np.where(df_new['Our_ID'].isin(incorrect_resistant_list + correct_resistant_list), 1, 0)
    df_new['Most Correct'] = np.where(df_new['Our_ID'].isin(most_correct_resistant_list + most_correct_sensitive_list), 1, 0)
    df_new['Nucleoid_AreaFraction'] = pd.to_numeric(df_new['Nucleoid_AreaFraction'], errors='coerce')
    '''
    Create a new column in df_new called "Target" equal to 0 if df_new['Our_ID'] is in correct_sensitive_list, or 1 if df_new['Our_ID'] is in
    incorrect_sensitive_list, or 2 if df_new['Our_ID'] is in correct_resistant_list, or 3 if df_new['Our_ID'] is in incorrect_resistant_list
    '''
    df_new['Target'] = np.where(df_new['Our_ID'].isin(correct_sensitive_list), "Correct Sensitive", 0)
    df_new['Target'] = np.where(df_new['Our_ID'].isin(incorrect_sensitive_list), "Incorrect Sensitive", df_new['Target'])
    df_new['Target'] = np.where(df_new['Our_ID'].isin(correct_resistant_list), "Correct Resistant", df_new['Target'])
    df_new['Target'] = np.where(df_new['Our_ID'].isin(incorrect_resistant_list), "Incorrect Resistant", df_new['Target'])

    return df_new

def add_titrations_columns(resistant_05_list, resistant_16_list, df):
    df_new = df.copy()
    # Add a column Titration to the DataFrame
    df_new['Titration'] = np.where(df_new['Our_ID'].isin(resistant_05_list), "0.5 mg/L", "0")
    df_new['Titration'] = np.where(df_new['Our_ID'].isin(resistant_16_list), "16 mg/L", df_new['Titration'])

    return df_new
        
def get_arrays(df, columns=COLUMNS):
    '''
    From the full labelled dataframes, return an array X of shape (n_samples, n_features)
    and an array Y of shape (n_samples,) of "Resistant" class labels
    '''

    '''
    The sensitive and resistant dfs have (:,28) columns with labels:

    ['ImageNumber', 'Image_FileName_RGB', 'Image_Count_Membrane', 'Image_Count_Nucleoid', 
    'Image_Threshold_FinalThreshold_Membrane', 'Mean_Membrane_AreaShape_Area', 
    'Mean_Membrane_AreaShape_Compactness', 'Mean_Membrane_AreaShape_ConvexArea', 
    'Mean_Membrane_AreaShape_Eccentricity', 'Mean_Membrane_AreaShape_Eccentricity.1', 
    'Mean_Membrane_AreaShape_FormFactor', 'Mean_Membrane_AreaShape_MajorAxisLength', 
    'Mean_Membrane_AreaShape_MaxFeretDiameter', 'Mean_Membrane_AreaShape_MinFeretDiameter', 
    'Mean_Membrane_AreaShape_MinorAxisLength', 'Mean_Membrane_Intensity_IntegratedIntensityEdge_NileRed', 
    'Mean_Membrane_Intensity_IntegratedIntensity_NileRed', 
    'Mean_Membrane_Intensity_MeanIntensityEdge_NileRed', 
    'Mean_Nucleoid_Intensity_IntegratedIntensityEdge_DAPI', 
    'StDev_Nucleoid_Intensity_IntegratedIntensityEdge_DAPI', 
    'Mean_Nucleoid_Intensity_IntegratedIntensity_DAPI', 
    'StDev_Nucleoid_Intensity_IntegratedIntensity_DAPI', 
    'Mean_Nucleoid_Intensity_MeanIntensityEdge_DAPI', 
    'StDev_Nucleoid_Intensity_MeanIntensityEdge_DAPI', 
    'Mean_Nucleoid_Intensity_StdIntensity_DAPI', 'StDev_Nucleoid_Intensity_StdIntensity_DAPI', 
    'Our_ID', 'Incorrect']'''

    #features_list = list(sensitive_df.columns.values)[3:25]

    # The features are found in the 4th - 26th columns
    X = df.loc[:,columns].to_numpy()
    Y_Incorrects = df.iloc[:,14].to_numpy()
    Y_Resistant = df.iloc[:,15].to_numpy()
    Y_MostCorrect = df.iloc[:,16].to_numpy()
    Y_Targets = df.iloc[:,17].to_numpy()
    Y_MIC = df.iloc[:,13].to_numpy()
    Y_Titrations = df.iloc[:,16].to_numpy()

    # Count the number of nans in X
    if np.isnan(X).sum() > 0:
        nans_array = np.argwhere(np.isnan(X))
        # Remove the rows in X and Y that are in np.unique(nans_array[:,0])
        X = np.delete(X, np.unique(nans_array[:,0]), axis=0)
        Y_Incorrects = np.delete(Y_Incorrects, np.unique(nans_array[:,0]), axis=0)
        Y_Resistant = np.delete(Y_Resistant, np.unique(nans_array[:,0]), axis=0)
        Y_MostCorrect = np.delete(Y_MostCorrect, np.unique(nans_array[:,0]), axis=0)
        Y_Targets = np.delete(Y_Targets, np.unique(nans_array[:,0]), axis=0)
        Y_MIC = np.delete(Y_MIC, np.unique(nans_array[:,0]), axis=0)
        print('X contains nans, rows with nans deleted')
        print(np.isnan(X).sum())
        print(np.unique(nans_array[:,0]))

    return X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC
