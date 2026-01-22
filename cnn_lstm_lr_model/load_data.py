# ----------------------------------------------------------------------------------------------------------------
# purpose: this script loads in the .mat file with the .raw iq file and its corresponding label.
# -----------------------------------------------------------------------------------------------------------------

import pandas as pd # for data processing and file i/o.
# import mat73 # for building dynamic paths. # TODO: comment/uncomment before running script.
from scipy.io import loadmat # for loading .mat data.


# define path to the .mat file.
# cnn_data_path = "/home/wairimu/training_data_stricter_classification_method/cnn_input_data.mat"
# file_names_path = "/home/wairimu/training_data_stricter_classification_method/file_names.mat"
# cnn_data_path = "/home/wairimu/training_files/cnn_input_data.mat"
# file_names_path = "/home/wairimu/training_files/file_names.mat"
# cnn_data_path = "/home/wairimu/training_data_moving_avg_signal_power/cnn_input_data.mat" # TODO: comment/uncomment before running script.
# file_names_path = "/home/wairimu/training_data_moving_avg_signal_power/file_names.mat" # TODO: comment/uncomment before running script.
# cnn_data_path_approach_7 = "/home/wairimu/training_files_approach_7/cnn_input_data.mat" # TODO: comment/uncomment before running script.
# file_names_path_approach_7 = "/home/wairimu/training_files_approach_7/file_names.mat" # TODO: comment/uncomment before running script.
cnn_data_path = "7_cnn_input_data.mat"
file_names_path = "7_file_list.mat"


# load the features and labels from .mat file.
# data = mat73.loadmat(cnn_data_path_approach_7) # TODO: comment/uncomment before running script.
# file_names = mat73.loadmat(file_names_path_approach_7) # TODO: comment/uncomment before running script.
data = loadmat(cnn_data_path) # TODO: comment/uncomment before running script.
file_names = loadmat(file_names_path) # TODO: comment/uncomment before running script.