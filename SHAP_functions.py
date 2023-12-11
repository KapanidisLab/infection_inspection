from matplotlib import pyplot as plt
import numpy as np
import shap
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import RepeatedKFold, cross_val_score
from sklearn.ensemble import RandomForestClassifier
from xgboost import XGBClassifier
from shapash import SmartExplainer
#import os
#import shutil
# import cv2
import pandas as pd
import seaborn as sns

FEATURES_LIST = ['# Nucleoids', 
                 'Membrane Form Factor', 
                 'Membrane MajorAxisLength', 
                 'Nucleoid Mean Integrated Intensity', 
                 'Nucleoid StD Integrated Intensity', 
                 'Nucleoid Mean Std Intensity',
                 'Nucleoid Area Fraction']

def tree_model_shap(X_train, X_test, Y_train, Y_test, features_list=FEATURES_LIST):
    # Define the model
    scaler = StandardScaler()
    tree_model = XGBClassifier(n_estimators=1000,
                               max_depth = 7,
                               eta = 0.1,
                               subsample = 0.7,
                               colsample_bytree = 0.7,)
    # Scale the input feature arrays
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.fit_transform(X_test)
    # Define the model evaluation method
    cv = RepeatedKFold(n_splits=10, n_repeats=3, random_state=1)
    # Evaluate the model
    scores = cross_val_score(tree_model, X_train_scaled, Y_train, 
                             scoring='neg_mean_absolute_error',
                             cv=cv,
                             n_jobs=1)
    # Force scores to be positive
    scores = np.absolute(scores)
    print('Mean MAE: %.3f (%.3f)' % (scores.mean(), scores.std()) )

    # SHAP Implementation
    shap.initjs()
    # Fit model
    treeModel = tree_model.fit(X_train_scaled, Y_train)
    # Explain model prediction with SHAP
    explainer = shap.KernelExplainer(treeModel.predict_proba, X_train_scaled, link="logit")
    shap_contrib = explainer.shap_values(X_test_scaled, nsamples=100)

    # Plot force for single image
    f_singleImage = f = shap.force_plot(explainer.expected_value[0], shap_contrib[0][0,:], X_test_scaled[0,:], link="logit", feature_names=features_list, text_rotation=30, show=False)
    shap.save_html("SHAP_ForcePlot_single.htm",f_singleImage)
    # Plot of all images
    f_allImages = shap.force_plot(explainer.expected_value[0], shap_contrib[0], X_test_scaled, link="logit", feature_names=features_list, show=False)
    shap.save_html("SHAP_ForcePlot_all.htm",f_allImages)


    # SHAPASH EXplianer

    # Declare SmartExplainer > the mandatory parameter is Model
    xpl = SmartExplainer(model=treeModel)
    # Compile Dataset, the one mandatory parameter is the X_test
    # Y_target allows comparison of True vs Predicted Values
    # xpl.compile(x=X_test_scaled, y_target=Y_test)
    xpl.compile(x=X_test_scaled)
    shap_summary = xpl.to_pandas()

    return treeModel, explainer, shap_contrib, shap_summary

def tree_model_shap_NEW(X_train, X_test, Y_train, Y_test, features_list=FEATURES_LIST):
    # Define the model
    scaler = StandardScaler()

    rf = RandomForestClassifier(n_estimators=100,
                                min_samples_leaf=3)
    
        # Scale the input feature arrays
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.fit_transform(X_test)

    rf.fit(X_train_scaled, Y_train)

    # Define the model evaluation method
    cv = RepeatedKFold(n_splits=10, n_repeats=3, random_state=1)
    # Evaluate the model
    scores = cross_val_score(rf, X_train_scaled, Y_train, 
                             scoring='neg_mean_absolute_error',
                             cv=cv,
                             n_jobs=1)
    # Force scores to be positive
    scores = np.absolute(scores)
    np.savetxt('scores.txt', scores)
    print('Mean MAE: %.3f (%.3f)' % (scores.mean(), scores.std()) )

    Y_Pred_df = pd.DataFrame(rf.predict(X_test_scaled), columns=['pred'])
    
    X_test_scaled_df = pd.DataFrame(data=X_test_scaled,
                                    columns=features_list)

    # SHAP Implementation
    shap.initjs()

    # Explain model prediction with SHAP
    explainer = shap.KernelExplainer(rf.predict_proba, X_test_scaled_df)
    shap_contrib = explainer.shap_values(X_test_scaled_df)

    shap.summary_plot(shap_contrib[1], X_test_scaled_df.astype("float"))

    # # Plot force for single image
    # f_singleImage = f = shap.force_plot(explainer.expected_value[0], shap_contrib[0][0,:], X_test_scaled[0,:], link="logit", feature_names=features_list, text_rotation=30, show=False)
    # shap.save_html("SHAP_ForcePlot_single.htm",f_singleImage)
    # # Plot of all images
    # f_allImages = shap.force_plot(explainer.expected_value[0], shap_contrib[0], X_test_scaled, link="logit", feature_names=features_list, show=False)
    # shap.save_html("SHAP_ForcePlot_all.htm",f_allImages)

    # SHAPASH EXplianer

    # Declare SmartExplainer > the mandatory parameter is Model
    xpl = SmartExplainer(model=rf)
    # Compile Dataset, the one mandatory parater is the X_test
    # Y_target allows comparison of True vs Predicted Values
    # xpl.compile(x=X_test_scaled, y_target=Y_test)
    xpl.compile(contributions=shap_contrib, x=X_test_scaled_df, y_pred=Y_Pred_df)
    shap_summary = xpl.to_pandas()

    return rf, explainer, shap_contrib, shap_summary, scores

def plot_shap_summary(shap_summary):
    contrib_1 = shap_summary[['pred','feature_1', 'contribution_1']].rename(columns={'pred':'prediction','feature_1': 'feature', 'contribution_1': 'contribution'})
    contrib_2 = shap_summary[['pred','feature_2', 'contribution_2']].rename(columns={'pred':'prediction','feature_2': 'feature', 'contribution_2': 'contribution'})
    contrib_3 = shap_summary[['pred','feature_3', 'contribution_3']].rename(columns={'pred':'prediction','feature_3': 'feature', 'contribution_3': 'contribution'})
    contrib_4 = shap_summary[['pred','feature_4', 'contribution_4']].rename(columns={'pred':'prediction','feature_4': 'feature', 'contribution_4': 'contribution'})
    contrib_5 = shap_summary[['pred','feature_5', 'contribution_5']].rename(columns={'pred':'prediction','feature_5': 'feature', 'contribution_5': 'contribution'})
    contrib_6 = shap_summary[['pred','feature_6', 'contribution_6']].rename(columns={'pred':'prediction','feature_6': 'feature', 'contribution_6': 'contribution'})
    contrib_7 = shap_summary[['pred','feature_7', 'contribution_7']].rename(columns={'pred':'prediction','feature_7': 'feature', 'contribution_7': 'contribution'})

    pred_df = pd.concat([contrib_1, contrib_2, contrib_3, contrib_4, contrib_5, contrib_6, contrib_7], axis=0)

    # Violin plot
    violin = sns.violinplot(data=pred_df, x='feature',y='contribution', hue='prediction', split=True)

    # Strip Plot
    stripplot = sns.stripplot(data=pred_df, x='feature',y='contribution', hue='prediction', dodge=True, alpha=0.5, size=1)

    # Cat Plot
    cat = sns.catplot(data=pred_df, x="feature", y="contribution", col="prediction", size=1)
    plt.legend(title='Feature Contributions', loc='upper left', labels=['Sensitive', 'Resistant'])
    plt.show(cat)

    # Bar Plot
    pred_df['contribution'] = pred_df['contribution'].abs()
    bar = sns.barplot(data=pred_df, x='feature',y='contribution', hue='prediction', errorbar='se')
    bar.set_xticklabels(bar.get_xticklabels(), rotation=90)
    #plt.legend(labels=['Sensitive', 'Resistant'])
    plt.show(bar)

    # Point Plot
    point = sns.pointplot(data=pred_df, x="feature", y="contribution", hue="prediction", errorbar='se')
    point.set_xticklabels(point.get_xticklabels(), rotation=90)

    return violin, stripplot, cat, bar, point