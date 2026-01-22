# ----------------------------------------------------------------------------------------------------------------
# purpose: this script loads in the .mat file with the .raw iq file's "features" and corresponding "labels".
# 
# note: the .mat file that we load in with this script has __ files, each containing 12 sequences / time steps, each time step has 10 features
# -----------------------------------------------------------------------------------------------------------------

import pandas as pd # for data processing and file i/o.
import os # for building dynamic paths.
from scipy.io import loadmat # for loading .mat data.


# define path to the .mat file.
lstm_data_path = "lstm_data_7.mat"


# load the features and labels from .mat file.
data = loadmat(lstm_data_path)


# df_pos = df[df['label'] == 1]
# df_neg = df[df['label'] == 0]
# print("mean difference between pos and neg classes")
# print(df_pos.mean(numeric_only=True) - df_neg.mean(numeric_only=True))

print(data.keys())

# labels = data['labels'].squeeze() # a 1D array 'labels' contains the data from the 'Labels' column of the .mat file (0 or 1)
# print(labels)