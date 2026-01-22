# ----------------------------------------------------------------------------------------------------------------
# purpose: this script loads in the .mat file with the .raw iq file and its corresponding label.
# -----------------------------------------------------------------------------------------------------------------

import scipy.io as sio
import pandas as pd # for data processing and file i/o.
# import os
# import mat73 # for building dynamic paths.
from scipy.io import loadmat # for loading .mat data.


# define path to the .mat file.
# cnn_data_path = "/home/wairimu/training_data_stricter_classification_method/cnn_input_data.mat"
# file_names_path = "/home/wairimu/training_data_stricter_classification_method/file_names.mat"
# cnn_data_path = "/home/wairimu/training_files/cnn_input_data.mat"
# file_names_path = "/home/wairimu/training_files/file_names.mat"
cnn_data_path = "2_cnn_input_data.mat"
file_names_path = "2_file_list.mat"


# load the features and labels from .mat file.
# data = mat73.loadmat(cnn_data_path)
# file_names = mat73.loadmat(file_names_path)
data = sio.loadmat(cnn_data_path)
file_names = sio.loadmat(file_names_path)