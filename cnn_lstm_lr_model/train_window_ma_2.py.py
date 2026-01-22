import pandas as pd # for data processing and file i/o.
import mat73 # for building dynamic paths. # TODO: comment/uncomment before running script.
import numpy as np

# import libraries and helper files.
import random
# import keras
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Input, Dense, LSTM, Conv1D, Conv2D, TimeDistributed, MaxPooling1D, Flatten, Dropout, GlobalMaxPooling1D
from tensorflow.keras import optimizers
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping
from tensorflow.keras.optimizers import Adam 
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
working_folder = "/home/wairimu/training_data_corrected_windowing/" # TODO: comment/uncomment before running script.


# set random seed to ensure fair comparison of models as I tune parameters.
np.random.seed(42)


# define path to the .mat file.
#
data_path = "/home/wairimu/training_data_corrected_windowing/window_tensor_concat.mat" # TODO: comment/uncomment before running script.
labels_path = "/home/wairimu/training_data_corrected_windowing/labels_concat.mat" # TODO: comment/uncomment before running script.


# define CNN-LSTM_Classifier class (using Keras).
class CNN_LSTM_Classifier():

    # function to initialize an instance of a CNN_LSTM_Classifier object (the model).
    # changed lstm_units from 64-->128, and CNN filters from 32-->64 and 64-->128
    def __init__(self, num_windows, num_samples_per_window, num_channels=2, lstm_units=64, dropout=0.2, lr=0.001):
        
        # define model parameters.
        self.num_windows = num_windows
        self.num_samples_per_window = num_samples_per_window
        self.num_channels = num_channels
        self.lstm_units = lstm_units
        self.dropout = dropout
        self.lr = lr

        # create model.
        self.model = self._build_model()
        
        # compile model (configure it for training).
        self._compile_model()


    # function to build the model architecture -- define the layers and their connection flow here.
    def _build_model(self):
        
        # define input shape = (num_windows, num_samples_per_window, num_channels)
        # inputs = Input(shape=(None, self.num_windows, self.num_samples_per_window, self.num_channels))
        # inputs = Input(shape=(None, self.num_windows, self.num_samples_per_window))
        inputs = Input(shape=( None,  self.num_windows, self.num_samples_per_window))

        print("input defined in build_model: ", inputs)

        # use a CNN and max pooling on each window with keras' 'TimeDistributed'.
        x = TimeDistributed(Conv1D(filters=32, kernel_size=3, activation='relu', padding='same'))(inputs)
        x = TimeDistributed(MaxPooling1D(pool_size=2))(x)
        x = TimeDistributed(Conv1D(filters=64, kernel_size=3, activation='relu', padding='same'))(x)
        x = TimeDistributed(MaxPooling1D(pool_size=2))(x)
        # x = TimeDistributed(Flatten())(x)

        # replace Flatten with GlobalMaxPooling1D?...
        # input shape: (batch_size aka num_files, num_windows, num_samples_per_window, num_channels)
        # output shape: (batch_size, num_windows, num_channels)...this 3D input is what the LSTM accepts.
        x = TimeDistributed(GlobalMaxPooling1D(data_format='channels_last', keepdims=False))(x)
        # data_format='channels_last' means input is 3D tensor with shape (batch_size, steps, features aka channels)
        # keepdims=False means the output is a 2D tensor with shape (batch_size, channels aka features), but since I use TimeDistributed, I keep the num_windows dimension, so the actual output shape is (batch_size, num_windows, channels aka features)
        

        # use an LSTM over the sequence of windows.
        x = LSTM(self.lstm_units)(x)
        x = Dropout(self.dropout)(x)

        # use FC and sigmoid activation for the final binary classification.
        outputs = Dense(1, activation='sigmoid')(x)

        # create a Functional Model object which has the above architecture. Inputs --> outputs connects all layers and components.
        model = Model(inputs=inputs, outputs=outputs)
        
        return model

    

    # function to compile the model (aka, configure/prepare it for training) -- define compiling parameters here (aka, how loss will be computed, how model updates weights (adam), and how performance is measured (accuracy)).
    def _compile_model(self):
        
        # define the optimizer to be adam and the lr to be 'lr'.
        # btw: keras' built in adam optimizer has default lr=0.001...I define my own optimzer here so I can customize the lr used by adam.
        optimizer = Adam(learning_rate=self.lr)
        
        # compile the model.
        self.model.compile(optimizer=optimizer, loss='binary_crossentropy', metrics=['accuracy'])


    # function to display the summary (i.e., layer, corresponding shape) of each layer in the model.
    def summary(self):
        self.model.summary()


    # function to actually train the model.
    def fit(self, *args, **kwargs):
        return self.model.fit(*args, **kwargs)
    
    
    def predict(self, *args, **kwargs):
        return self.model.predict(*args, **kwargs)

    
def prepare_data(data_path, labels_path):
    # load the features and labels from .mat file.
    # data = mat73.loadmat(cnn_data_path_approach_7) # TODO: comment/uncomment before running script.
    # file_names = mat73.loadmat(file_names_path_approach_7) # TODO: comment/uncomment before running script.
    data = mat73.loadmat(data_path) # TODO: comment/uncomment before running script.
    labels = mat73.loadmat(labels_path) # TODO: comment/uncomment before running script.

    print(data.keys())
    print(labels.keys())

    data = data["window_tensor_concat"]
    labels = labels["labels_concat"]

    # cnn_input = np.expand_dims(data, axis = -1)
    # cnn_input = data[:, :, np.newaxis]
    # cnn_input = data[np.newaxis, :, :]

    cnn_input = data


    print("cnn input shape: ", cnn_input.shape)


    num_windows = cnn_input.shape[0]
    num_samples = cnn_input.shape[1]
    # num_channels = cnn_input.shape[2]
    num_channels = 0

    print(num_windows, num_samples)

    all_indices = np.arange(num_windows)
    train_val_idx, test_idx = train_test_split(all_indices, test_size=.3, train_size=.7, shuffle=True, stratify=labels, random_state=42)

    train_idx, val_idx = train_test_split(train_val_idx, test_size=.2, train_size=.7, shuffle=True, stratify=labels[train_val_idx], random_state=42)

    X_train = cnn_input[train_idx] # grab all features from the 'train_idx' (aka, from the file X, and file Y and ...)
    y_train = labels[train_idx]
    print("train data shape: ", X_train.shape)
    print("train labels shape: ", y_train.shape)

    X_val = cnn_input[val_idx]
    y_val = labels[val_idx]
    print("val data shape: ", X_val.shape)
    print("val labels shape: ", y_val.shape)

    X_test = cnn_input[test_idx]
    y_test = labels[test_idx]
    print("test data shape: ", X_test.shape)
    print("test labels shape: ", y_test.shape)

    # save the X_test and y_test to be used for interference in evaluate.py.
    with open(working_folder + "test_set.pkl", "wb") as f: # TODO: comment/uncomment before running script.
    # with open("test_set.pkl", "wb") as f: # TODO: comment/uncomment before running script.
        pickle.dump((X_test, y_test), f)
    
    
    return num_windows, num_samples, num_channels, X_train, y_train, X_val, y_val



# define input parameters and compute the training and val set splits.
num_windows, num_samples, num_channels, X_train, y_train, X_val, y_val = prepare_data(data_path=data_path, labels_path=labels_path)


# compute class weights
classes = np.unique(y_train)
class_weights = class_weight.compute_class_weight(class_weight='balanced', classes=classes, y=y_train) 
print("class weights for training set: ", class_weights)


# convert class weights into a dictionary
class_weights = {i : class_weights[i] for i, label in \
                 enumerate(sorted(np.unique(y_train)))\
                }
                        
                                  
# # define input shape.
# inputs = Input(shape=(num_windows, num_samples, num_channels))
# # print("shape of input: ", inputs.shape)


# instantiate a keras-model object (that is ready to be trained).
model = CNN_LSTM_Classifier(num_windows=num_windows, num_samples_per_window=num_samples, num_channels=num_channels)
print("INSTANTIATED MODEL")

# display the shape of each layer in the cnn-lstm-lr model.
model.summary()


# define training parameters.
num_epochs = 20
batch_size = 16


# let model know how to save the best model.
checkpoint = ModelCheckpoint(filepath=working_folder + "model.h5", monitor='val_loss', save_best_only=True, save_weights_only=False, mode='min', verbose=1) # TODO: comment/uncomment before running script.
# checkpoint = ModelCheckpoint("model.h5", monitor='val_loss', save_best_only=True, save_weights_only=False, mode='min', verbose=1) # TODO: comment/uncomment before running script.

print("ABOUT TO FIT MODEL")
# train the model and document its performance over each epoch.
history = model.fit(X_train, y_train, validation_data=(X_val, y_val), epochs=num_epochs, batch_size=batch_size, callbacks=[checkpoint], class_weight=class_weights)


# visualize the training process
plt.plot(history.history['loss'])
plt.plot(history.history['val_loss'])
plt.title('Model Loss Over Epochs')
plt.ylabel('Loss')
plt.xlabel('Epoch')
plt.legend(['Train', 'Validation'], loc='upper left')
# plt.show() # TODO: comment/uncomment before running script.
plt.savefig(working_folder + "train_plot.png") # TODO: comment/uncomment before running script.



