# ----------------------------------------------------------------------------------------------------------------
# purpose: this script is used to train the CNN-LSTM-LR model.
#
# training data: - a 4D tensor of shape (num_files, num_windows, num_samples_per_window, num_channels) (where channels = 2 for the I and Q).
#                - a labels vector of shape (num_files, 1) with binary elements (0 = no-pattern, 1 = pattern).
#
# output: a trained model that can predict whether there is a signal present (1) or no signal present (0) based on an input raw IQ data file.  
# 
# note: - layers: CNN extract features from each defined window and outputs 1 feature vector per window. CNN passes this sequence of CNN features to the LSTM.
#                 LSTM layer learns temporal patterns across windows.
#                 FC + Sigmoid activation layers: maps LSTM output to a single logit for binary classification prediction.
#       - input shape 'None' means that any number of __ are allowed.
#       - my 4D tensor shape matches exactly what a 1D TimeDistributed CNN-LSTM using Keras wants
#       - I'm using a Functional Model as opposed to Sequential
#       - the first element in the 4D tensor (num_files) DOES NOT contain actual file names, it is just there for giving a numeric input dimension.
# -----------------------------------------------------------------------------------------------------------------


# note: Im using TimeDistributed, so the shape going into the CNN per time step and per window is (num_samples_per_window, num_channels), then the CNN will extract features and give the LSTM something of shape (num_windows, cnn_feature_dim)
# i want to keep the windows of each file together


# import libraries and helper files.
import random
import numpy as np
from sklearn.model_selection import GroupShuffleSplit, train_test_split # use sklearn to split data into training and testing sets. 
from sklearn.metrics import accuracy_score
from load_data import data, file_names # script that opened the directory with the data on the csv file.
import matplotlib.pyplot as plt
from matplotlib import pyplot
from sklearn.preprocessing import StandardScaler
import joblib
import pickle
import os
from sklearn.utils import class_weight


# data was loaded in load_data.py.
OVERFITTING_TEST = 1 # to test for overfitting
working_folder = "/home/wairimu/training_data_adjusted_window/"


# set random seed to ensure fair comparison of models as I tune parameters.
np.random.seed(42)
    

# function to split the data into train, val, and testing sets.
def prepare_data():
    # # veronica's calling...
    # features = data['combined_cnn_input'].astype(np.float32)
    # labels = data['combined_labels_vector'].flatten().astype(np.float32)
    # files = file_names['combined_file_list']
    # files = np.array(files).flatten()
    # print("file: ", files)


    # lydia's calling...
    features = data['combined_cnn_input'].astype(np.float32)
    labels = data['combined_labels_vector'].flatten().astype(np.float32)
    files = file_names['combined_file_list']
    files = np.array(files).flatten()
    # print("file: ", files)


    # define input parameters.
    num_files = None 
    num_windows = features.shape[1]
    num_samples = features.shape[2]
    num_channels = features.shape[3]
    print("number of files: ", features.shape[0])
    print("number of windows per file: ", num_windows)
    print("number of samples per window: ", num_samples)
    print("number of channels per sample (the IQ channels): ", num_channels)


    all_indices = np.arange(features.shape[0])


    # split indices for training + val and testing sets.
    train_val_idx, test_idx = train_test_split(all_indices, test_size=.3, train_size=.7, shuffle=True, stratify=labels, random_state=42)
    # print("training and validation indices: ", train_val_idx)
    # print("testing_idx indices: ", test_idx)
    

    # split indices for training and val sets 
    train_idx, val_idx = train_test_split(train_val_idx, test_size=.2, train_size=.7, shuffle=True, stratify=labels[train_val_idx], random_state=42)
    # print("training indices: ", train_idx)
    # print("val indices: ", val_idx)


    # use indices to make training, validation, and testing sets. 
    X_train = features[train_idx] # grab all features from the 'train_idx' (aka, from the file X, and file Y and ...)
    y_train = labels[train_idx]
    training_files = files[train_idx]
    # print("training files: ", training_files)
    print("training labels: ", y_train)


    # ------- FOR RUNNING INTERFERENCE WITH SEEN DATA ---------------
    # define number of files for each class
    num_files_per_class = 20

    # get indices of each class in the training set
    class_0_idx = np.where(y_train == 0)[0]
    class_1_idx = np.where(y_train == 1)[0]

    # choose 20 indices from each class at random
    class_0_chosen_idx = np.random.choice(class_0_idx, num_files_per_class, replace=False)
    class_1_chosen_idx = np.random.choice(class_1_idx, num_files_per_class, replace=False)

    chosen_idx = np.concatenate([class_0_chosen_idx, class_1_chosen_idx])
    np.random.shuffle(chosen_idx)

    # get the appropriate training data
    X_seen_data = X_train[chosen_idx]
    y_seen_data = y_train[chosen_idx]
    files_seen_data = training_files[chosen_idx]

    # save the testing data to be used in evaluate.py
    with open(working_folder + "train_set_for_testing_overfitting.pkl", "wb") as f:
        pickle.dump((X_seen_data, y_seen_data, files_seen_data), f)
    return
# -------------------------------------------------------------------    

prepare_data()