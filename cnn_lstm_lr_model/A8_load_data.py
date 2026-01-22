# ----------------------------------------------------------------------------------------------------------------
# purpose: this script loads in the .mat file with the .raw iq file and its corresponding label.
#
# note: train_data, val_data, and test_data are shape ('cnn_input'=a 4D feature tensor, 'window_labels___'=a 2D array with window-level labels, '___files'=a 2D array with filenames) 
#
# each data variable has shape
# -----------------------------------------------------------------------------------------------------------------

import pandas as pd # for data processing and file i/o.
# import mat73 # for building dynamic paths. # TODO: comment/uncomment before running script.
from scipy.io import loadmat # for loading .mat data.


# define path to the .mat file.
# train_data_path = "add your path" # TODO: comment/uncomment before running script.
# val_data_path = "add your path" # TODO: comment/uncomment before running script.
# test_data_path = "add your path" # TODO: comment/uncomment before running script.
train_data_path = "10_cnn_input_data_train.mat" # TODO: comment/uncomment before running script.
val_data_path = "10_cnn_input_data_val.mat" # TODO: comment/uncomment before running script.
test_data_path = "10_cnn_input_data_test.mat" # TODO: comment/uncomment before running script.


# load the features and labels from .mat file.
# train_data = mat73.loadmat(train_data_path) # TODO: comment/uncomment before running script.
# val_data_path = mat73.loadmat(val_data_path) # TODO: comment/uncomment before running script.
# test_data_path = mat73.loadmat(test_data_path) # TODO: comment/uncomment before running script.
train_data = loadmat(train_data_path) # TODO: comment/uncomment before running script.
val_data = loadmat(val_data_path) # TODO: comment/uncomment before running script.
test_data = loadmat(test_data_path) # TODO: comment/uncomment before running script.
