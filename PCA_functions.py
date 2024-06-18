from matplotlib import pyplot as plt
import numpy as np
import seaborn as sns
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from matplotlib.colors import to_rgba
import pandas as pd

FEATURES_LIST = ['# Nucleoids', 
                 'Membrane Form Factor', 
                 'Membrane MajorAxisLength', 
                 'Nucleoid Mean Integrated Intensity', 
                 'Nucleoid StD Integrated Intensity', 
                 'Nucleoid Mean Std Intensity',
                 'Nucleoid Area Fraction']

def Principal_Component_Analysis(X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC, Y_ModelTargets, Y_Disagree, style, features_list=FEATURES_LIST):
    # Data Preprocessing
    # StandardScaler will transform to mean = 0 and variance = 1
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    # Fit transform PCA with correct number of components

    pca = PCA(n_components=2)

    principalComponents = pca.fit_transform(X_scaled)

    pca_df = pd.DataFrame(data=principalComponents,
                          columns=['PC1', 'PC2'])
    #target_names = {0: 'Correct_Sensitive', 1: 'Incorrect_Sensitive', 2: 'Correct_Resistant', 3: 'Incorrect_Resistant'}
    pca_df['Targets'] = Y_Targets
    pca_df['Incorrects'] = Y_Incorrects # 1 if incorrect
    pca_df['Resistant'] = Y_Resistant # 1 if resistant
    pca_df['Most Correct'] = pd.Categorical.from_codes(Y_MostCorrect, ['Others', 'Most Correct'])
    pca_df['MIC'] = pd.Categorical(Y_MIC.astype('str'))
    pca_df['Model Targets'] = Y_ModelTargets
    #pca_df['Most Correct'] = Y_MostCorrect # 1 if most correct
    #pca_df['Targets'] = pca_df['Targets'].map(target_names)
    pca_df['Disagree'] = pd.Categorical.from_codes(Y_Disagree, ['Agree', 'Disagree'])
    
    print('Explained variation per principal component: {}'.format(pca.explained_variance_ratio_))


    PC1 = pca.fit_transform(X_scaled)[:,0]
    PC2 = pca.fit_transform(X_scaled)[:,1]
    ldngs = pca.components_
    scalePC1 = 1.0/(PC1.max() - PC1.min())
    scalePC2 = 1.0/(PC2.max() - PC2.min())
    features = features_list
    
    print(ldngs)
    print(features)

    plt.figure(figsize=(9,9))

    for i, feature in enumerate(features_list):
        plt.arrow(0, 0, ldngs[0,i],
                  ldngs[1,i])
    if style=="Highlight Corrects":
        color_dict = {'Correct Sensitive': to_rgba('navy', 0.9),
                    'Incorrect Sensitive': to_rgba('navy', 0.3),
                    'Correct Resistant': to_rgba('darkred', 0.9),
                    'Incorrect Resistant': to_rgba('darkred', 0.3)}
        HUE = "Targets"
    elif style=="Highlight Incorrects":
        color_dict = {'Correct Sensitive': to_rgba('navy', 0.3),
                    'Incorrect Sensitive': to_rgba('navy', 0.9),
                    'Correct Resistant': to_rgba('darkred', 0.3),
                    'Incorrect Resistant': to_rgba('darkred', 0.9)}
        HUE = "Targets"
    elif style=="Highlight Most Correct":
        color_dict = {'Most Correct': to_rgba('navy', 0.9),
                      'Others': to_rgba('navy', 0.3),}
        HUE = "Most Correct"
    elif style=="Colour MIC":
        color_dict = {'0.008': to_rgba('red', 0.7),
                    '0.03': to_rgba('orange', 0.7),
                    '72.0': to_rgba('blue', 0.7),
                    '108.0': to_rgba('purple', 0.7)}
        HUE = "MIC"
    elif style=="Model":
        color_dict = {'Sensitive': to_rgba('navy', 0.9),
                    'Resistant': to_rgba('darkred', 0.9)}
        HUE = "Model"
    elif style=="Model Corrects":
        color_dict = {'Correct Sensitive': to_rgba('navy', 0.9),
                    'Incorrect Sensitive': to_rgba('navy', 0.3),
                    'Correct Resistant': to_rgba('darkred', 0.9),
                    'Incorrect Resistant': to_rgba('darkred', 0.3)}
        HUE = "Model Targets"
    elif style=="Model Incorrects":
        color_dict = {'Correct Sensitive': to_rgba('navy', 0.3),
                    'Incorrect Sensitive': to_rgba('navy', 0.9),
                    'Correct Resistant': to_rgba('darkred', 0.3),
                    'Incorrect Resistant': to_rgba('darkred', 0.9)}
        HUE = "Model Targets"
        
    elif style=="Disagree":
        color_dict = {'Disagree': to_rgba('navy', 0.9),
                    'Agree': to_rgba('darkred', 0.3)}
        HUE = "Disagree"
        
    ax = sns.scatterplot(
        x=PC1*scalePC1, y=PC2*scalePC2,
        #style="Targets",
        hue=HUE,
        #palette=sns.color_palette("colorblind", 4),
        palette=color_dict,
        #style="Resistant",
        data=pca_df,
        legend="full"
    )
    ax.legend().set_title('')
    sns.move_legend(ax, "lower right")
    sns.rugplot(data=pca_df, x=PC1*scalePC1, y=PC2*scalePC2, hue=HUE, palette=color_dict, legend=False)

    plt.xlabel('PC1', fontsize=22)
    plt.ylabel('PC2', fontsize=22)
    for i, feature in enumerate(features_list):
        plt.arrow(0, 0, ldngs[0,i], ldngs[1,i])
    sns.move_legend(ax, "lower right")
    plt.gca().set_aspect('equal', adjustable='box')
    
    plt.xticks(fontsize=14)
    plt.yticks(fontsize=14)
    ax.legend(fontsize=14)
        
    max_range = max(abs(PC1*scalePC1).max(), abs(PC2*scalePC2).max())
    plt.xlim(-max_range, max_range)
    plt.ylim(-max_range, max_range)
    plt.rcParams['figure.dpi'] = 300

 
def PCA_HeatMap(X, features_list=FEATURES_LIST):
    # StandardScaler will transform to mean = 0 and variance = 1
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    pcamodel = PCA(n_components=2)
    pcamodel.fit(X_scaled)

    # Effects of variables on each component
    fig, ax = plt.subplots(figsize=(14,9))
    ax = sns.heatmap(pcamodel.components_,
                     cmap='YlGnBu',
                     yticklabels=[ "PC"+str(x) for x in range(1,pcamodel.n_components_+1)],
                     xticklabels=list(features_list),
                     cbar_kws={"orientation": "vertical"})
    ax.set_aspect("equal")

def plot3DPCA(X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_Titrations, style, features_list=FEATURES_LIST):
    scaler = StandardScaler()
    scaler.fit(X)
    X_scaled = scaler.transform(X)

    pca=PCA(n_components=3)
    pca.fit(X_scaled)
    X_pca = pca.transform(X_scaled)

    pca_df = pd.DataFrame(data=X_pca,
                          columns=['PC1', 'PC2', 'PC3'])
    pca_df['Targets'] = Y_Targets
    pca_df['Incorrects'] = Y_Incorrects # 1 if incorrect
    pca_df['Resistant'] = Y_Resistant # 1 if resistant
    pca_df['Most Correct'] = pd.Categorical.from_codes(Y_MostCorrect, ['Others', 'Most Correct'])
    pca_df['Titrations'] = Y_Titrations
    ex_variance = np.var(X_pca, axis=0)
    ex_variance_ratio = ex_variance/np.sum(ex_variance)
    ex_variance_ratio

    Xax = X_pca[:,0]
    Yax = X_pca[:,1]
    Zax = X_pca[:,2]

    if style=="Highlight Corrects":
        color_dict = {'Correct Sensitive': to_rgba('navy', 0.7),
                    'Incorrect Sensitive': to_rgba('navy', 0.1),
                    'Correct Resistant': to_rgba('darkgreen', 0.7),
                    'Incorrect Resistant': to_rgba('darkgreen', 0.1)}
        HUE = "Targets"
        Y = Y_Incorrects
    elif style=="Highlight Incorrects":
        color_dict = {'Correct Sensitive': to_rgba('navy', 0.1),
                    'Incorrect Sensitive': to_rgba('navy', 0.7),
                    'Correct Resistant': to_rgba('darkgreen', 0.1),
                    'Incorrect Resistant': to_rgba('darkgreen', 0.7)}
        HUE = "Targets"
        Y = Y_Incorrects
    elif style=="Highlight Most Correct":
        color_dict = {'Most Correct': to_rgba('navy', 0.7),
                      'Others': to_rgba('navy', 0.1),}
        HUE = "Most Correct"
        Y = Y_MostCorrect
    elif style=="Titrations":
        color_dict = {'0.5 mg/L': to_rgba('navy', 0.5),
                    '16 mg/L': to_rgba('seagreen', 0.5)}
        HUE = "Titrations"
    
    fig = plt.figure(figsize=(10,10))
    ax = fig.add_subplot(111, projection='3d')

    ax.scatter(X[:,1], X[:,2], X[:,3], c=Y)
    plt.show()


def Principal_Component_Analysis_Most_Correct(X, Y_Incorrects, Y_Resistant, Y_MostCorrect, Y_Targets, Y_MIC, style, features_list=FEATURES_LIST):
    # Data Preprocessing
    # StandardScaler will transform to mean = 0 and variance = 1
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    # Fit transform PCA with correct number of components

    pca = PCA(n_components=2)

    principalComponents = pca.fit_transform(X_scaled)

    pca_df = pd.DataFrame(data=principalComponents,
                          columns=['PC1', 'PC2'])
    #target_names = {0: 'Correct_Sensitive', 1: 'Incorrect_Sensitive', 2: 'Correct_Resistant', 3: 'Incorrect_Resistant'}
    pca_df['Targets'] = Y_Targets
    pca_df['Incorrects'] = Y_Incorrects # 1 if incorrect
    pca_df['Resistant'] = Y_Resistant # 1 if resistant
    pca_df['Most Correct'] = pd.Categorical.from_codes(Y_MostCorrect, ['Others', 'Most Correct'])
    pca_df['MIC'] = pd.Categorical(Y_MIC.astype('str'))
    #pca_df['Most Correct'] = Y_MostCorrect # 1 if most correct
    #pca_df['Targets'] = pca_df['Targets'].map(target_names)
    
    print('Explained variation per principal component: {}'.format(pca.explained_variance_ratio_))

    # Make a new column in pca_df with four categories based on "Most Corrects" and "Resistant"
    # 1. Correct Sensitive
    # 2. Incorrect Sensitive
    # 3. Correct Resistant
    # 4. Incorrect Resistant
    pca_df['Most Correct Targets'] = np.where((pca_df['Most Correct'] == 'Most Correct') & (pca_df['Resistant'] == 0), 'Sensitive Most Correct', '0')
    pca_df['Most Correct Targets'] = np.where((pca_df['Most Correct'] == 'Most Correct') & (pca_df['Resistant'] == 1), 'Resistant Most Correct', pca_df['Most Correct Targets'])
    pca_df['Most Correct Targets'] = np.where((pca_df['Most Correct'] == 'Others') & (pca_df['Resistant'] == 0), 'Sensitive Others', pca_df['Most Correct Targets'])
    pca_df['Most Correct Targets'] = np.where((pca_df['Most Correct'] == 'Others') & (pca_df['Resistant'] == 1), 'Resistant Others', pca_df['Most Correct Targets'])


    PC1 = pca.fit_transform(X_scaled)[:,0]
    PC2 = pca.fit_transform(X_scaled)[:,1]
    ldngs = pca.components_
    scalePC1 = 1.0/(PC1.max() - PC1.min())
    scalePC2 = 1.0/(PC2.max() - PC2.min())
    features = features_list

    plt.figure(figsize=(9,9))

    if style=="Highlight Most Correct":

        color_dict = {'Sensitive Most Correct': to_rgba('navy', 0.9),
                    'Sensitive Others': to_rgba('navy', 0.3),
                    'Resistant Most Correct': to_rgba('darkred', 0.9),
                    'Resistant Others': to_rgba('darkred', 0.3)}
        HUE = "Most Correct Targets"
        
    ax = sns.scatterplot(
        x=PC1*scalePC1, y=PC2*scalePC2,
        #style="Targets",
        hue=HUE,
        #palette=sns.color_palette("colorblind", 4),
        palette=color_dict,
        #style="Resistant",
        data=pca_df,
        legend="full"
    )
    ax.legend().set_title('')
    sns.move_legend(ax, "lower right")
    sns.rugplot(data=pca_df, x=PC1*scalePC1, y=PC2*scalePC2, hue=HUE, palette=color_dict, legend=False)

    plt.xlabel('PC1', fontsize=22)
    plt.ylabel('PC2', fontsize=22)
    for i, feature in enumerate(features_list):
        plt.arrow(0, 0, ldngs[0,i], ldngs[1,i])
    sns.move_legend(ax, "lower right")
    plt.gca().set_aspect('equal', adjustable='box')
    
    plt.xticks(fontsize=14)
    plt.yticks(fontsize=14)
    ax.legend(fontsize=14)
        
    max_range = max(abs(PC1*scalePC1).max(), abs(PC2*scalePC2).max())
    plt.xlim(-max_range, max_range)
    plt.ylim(-max_range, max_range)
    plt.rcParams['figure.dpi'] = 300
