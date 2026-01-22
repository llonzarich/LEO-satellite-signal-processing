# ----------------------------------------------------------------------------------------------------------------
# purpose: this script loads the feature vector and corresponding label of each IQ data file into arrays, X, and y. 
# -----------------------------------------------------------------------------------------------------------------

import pandas as pd # for data processing and file i/o.
import os # for building dynamic paths.


# # define path to the input data (raw IQ files).
# iq_file_path = "lr-data/iq-files.raw" 


# # open the iq file directory.
# data = open(iq_file_path)
# # or: data = pd.read("iq_signals")



# ORRR if i have matlab put features and labels together into a csv file, then...
# define path to the training data (a csv file).
training_data_path = "training_data.csv"

# open the csv file
data = pd.read_csv('training_data.csv')