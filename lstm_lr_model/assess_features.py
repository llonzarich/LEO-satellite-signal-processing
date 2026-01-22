# ------------------------------------------------------------------------------------------------------------------------
# purpose: this script will be used to assess the importance of my features are in the model training.
# 
# interpreting the plot...x-axis: - feature index / the number of features.
#                                 - example: index 0 = band 0 of chunk0, index 13 = neo feature 4 of chunk0, index 14 = band 0 of chunk1, etc.
#                         y-axis: importance scale.
#                         RandomForestClassifier finds patterns across all training samples, which is why we only see 168 indices. 
#
# note: - each file has 12 x 14 number of features = 168 features.
# ------------------------------------------------------------------------------------------------------------------------

# import libraries and helper files.
import torch 
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from train import Classifier
import pickle
import os


# load the training sets from the train-test-split that was performed in train.py.
with open("train_set.pkl", "rb") as f:
    X_train, y_train = pickle.load(f)


# # convert X_train and y_train into tensors
# X_test_tensor = torch.tensor(X_train, dtype=torch.float32)
# y_test_tensor = torch.tensor(y_train, dtype=torch.float32)


# collapse the time dimension so each sequence is a flat vector.
X_train_rf = X_train.reshape(X_train.shape[0], -1)  # shape: (num_samples, 12*10 = 120)
X_train_df = pd.DataFrame(X_train_rf, columns = [f"f{t}_{f}" for t in range(51) for f in range(14)])


# Fit a Random Forest and check feature importances
rf_model = RandomForestClassifier(n_estimators=100, random_state=42)
rf_model.fit(X_train_df, y_train)


# new stuff:
neo_feature_indices_10 = []
neo_feature_indices_11 = []
neo_feature_indices_12 = []
neo_feature_indices_13 = []

for t in range(12):
    neo_feature_indices_10.append(t * 14 + 10)
    neo_feature_indices_11.append(t * 14 + 11)
    neo_feature_indices_12.append(t * 14 + 12)
    neo_feature_indices_13.append(t * 14 + 13)



# initialize an array to store the indices of NEO features.
neo_feature_indices = []


# # note: each file has 48 NEO features (because each file has 12 chunks/time steps and each chunk has 4 features).
# # iterate through each file's 12 chunks and "grab" the indices of the NEO features
# for t in range(51):

#     # NEO features are at index positions 10, 11, 12, and 13
#     for i in range(10, 14):  
#         idx = t * 14 + i
#         neo_feature_indices.append(idx)


importances = rf_model.feature_importances_


# plot feature importances
sorted_indices = np.argsort(importances)[::-1]
sorted_importances = importances[sorted_indices]
# plt.figure(figsize=(20, 12))
plt.bar(range(len(sorted_importances)), sorted_importances, color='gray', alpha=0.6, label='Average Bandpowers')


neo_feature_names = {10: "NEO Feature: Mean", 11:"NEO Feature: Standard Deviation", 12:"NEO Feature: Max", 13:"NEO Feature: Peak Count"}


for neo_idx in [10, 11, 12, 13]:
    idx_list = [t * 14 + neo_idx for t in range(51)]
    neo_sorted = [np.where(sorted_indices == i)[0][0] for i in idx_list]
    plt.bar(neo_sorted, [sorted_importances[i] for i in neo_sorted], label=neo_feature_names[neo_idx])



# neo_sorted = [np.where(sorted_indices == i)[0][0] for i in neo_feature_indices]
# plt.bar(range(len(sorted_importances)), sorted_importances, color='gray', alpha=0.6, label='Average Bandpowers')
# for idx in [neo_feature_indices_10, neo_feature_indices_11, neo_feature_indices_12, neo_feature_indices_13]:
#     neo_sorted = [np.where(sorted_indices == i)[0][0] for i in idx]
#     plt.bar(neo_sorted, [sorted_importances[i] for i in neo_sorted], label=f'NEO feature {idx[0] % 14}')  # or name the feature explicitly



# plt.bar(neo_sorted, [sorted_importances[i] for i in neo_sorted], color='orange', label='NEO Features')

plt.xlabel("Features (Sorted By Importance)")
plt.ylabel("Importance")
plt.title("Feature Importance During Model Training")
plt.grid(True)
plt.legend()
plt.tight_layout()

# plt.figure(figsize=(12, 6))
# plt.bar(range(len(importances)), importances[sorted_indices])
# plt.bar(neo_feature_indices, [importances[i] for i in neo_feature_indices], color='orange')
# plt.xlabel("Sorted Feature Index")
# plt.ylabel("Importance")
# plt.title("Sorted Feature Importances (Bandpowers, NEOs)")
# plt.grid(True)
# plt.legend()



# plt.figure(figsize=(12, 6))
# plt.bar(range(len(importances)), importances)
# plt.bar(neo_feature_indices, [importances[i] for i in neo_feature_indices], color='orange')
# plt.xlabel("Flattened Feature Index")
# plt.ylabel("Importance")
# plt.title("Feature Importances (Bandpowers, NEOs)")
# plt.grid(True)
# plt.legend()


# save figure
folder_name = "feature importance plots"
file_path = os.path.join(folder_name, "feature_importance_100.png")
plt.savefig(file_path)
plt.close()