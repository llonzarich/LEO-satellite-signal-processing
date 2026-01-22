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
import tensorflow as tf
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Input, Layer, Dense, LSTM, Conv1D, TimeDistributed, MaxPooling1D, Flatten, Dropout, GlobalMaxPooling1D
from tensorflow.keras import optimizers
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping, ReduceLROnPlateau
from tensorflow.keras.optimizers import Adam 
import numpy as np
from sklearn.model_selection import GroupShuffleSplit, train_test_split # use sklearn to split data into training and testing sets. 
from sklearn.metrics import accuracy_score
from A8_load_data import train_data, val_data # script that opened the directory with the data on the csv file.
import matplotlib.pyplot as plt
from matplotlib import pyplot
from sklearn.preprocessing import StandardScaler
import joblib
import pickle
import os
from sklearn.utils import class_weight
from sklearn.utils.class_weight import compute_class_weight


# data was loaded in load_data.py.
OVERFITTING_TEST = 0 # to test for overfitting TODO: comment/uncomment before running script.
working_folder = "/home/wairimu/training_data_adjusted_window/" # TODO: comment/uncomment before running script.


# set random seed to ensure fair comparison of models as I tune parameters.
np.random.seed(42)


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
        inputs = Input(shape=(self.num_windows, self.num_samples_per_window, self.num_channels))

        # use a CNN and max pooling on each window with keras' 'TimeDistributed'.
        x = TimeDistributed(Conv1D(filters=32, kernel_size=3, activation='relu', padding='same'))(inputs)
        x = TimeDistributed(MaxPooling1D(pool_size=2))(x)
        x = TimeDistributed(Conv1D(filters=64, kernel_size=3, activation='relu', padding='same'))(x)
        x = TimeDistributed(MaxPooling1D(pool_size=2))(x)
        # x = TimeDistributed(Flatten())(x)

        # replace Flatten with GlobalMaxPooling1D?...
        # input shape: (batch_size aka num_files, num_windows, num_samples_per_window, num_channels)
        # output shape: (batch_size, num_windows, num_channels)...this 3D input is what the LSTM accepts.
        # x = TimeDistributed(GlobalMaxPooling1D(data_format='channels_last', keepdims=False))(x)
        x = TimeDistributed(GlobalMaxPooling1D())(x)
        # data_format='channels_last' means input is 3D tensor with shape (batch_size, steps, features aka channels)
        # keepdims=False means the output is a 2D tensor with shape (batch_size, channels aka features), but since I use TimeDistributed, I keep the num_windows dimension, so the actual output shape is (batch_size, num_windows, channels aka features)
        

        # use an LSTM over the sequence of windows.
        x = LSTM(self.lstm_units, return_sequences=True)(x) 

        # attention over windows
        # x = Attention()(x)

        x = Dropout(self.dropout)(x)

        # use FC and sigmoid activation for the final binary classification.
        outputs = TimeDistributed(Dense(1, activation='sigmoid'))(x) # probability per window

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
    



# # define attention layer class
# class Attention(Layer):
#     def __init__(self):
#         super(Attention, self).__init__()
    
#     def call(self, inputs):
#         score = Dense(1, activation="tanh")(inputs)
#         weights = tf.nn.softmax(score, axis=1)
#         context = inputs * weights 
#         return context

    


# unpack data from train and val set splits (unpacking for test set is in evaluate.py)
X_train = train_data['cnn_input_train'] # shape (num_files, num_windows=59, num_samples_per_window=4800, num_channels=2)
y_train = train_data['window_labels_train'] # shape (num_files, num_windows=59) (each of the 59 is a binary entry for the window label: 0  or 1)
training_files = train_data['train_files'] # shape (1, num_files (filled with filenames))
training_files = training_files.flatten() # flatten so 1 * num_files = num_files
print("shape of X_train: ", X_train.shape)
print("shape of y_train: ", y_train.shape)
print("number of training files (derived from the training_files element of the data variable): ", len(training_files))

X_val = val_data['cnn_input_val'] # shape (num_files, num_windows=59, num_samples_per_window=4800, num_channels=2)
y_val = val_data['window_labels_val'] # shape (num_files, num_windows=59)
val_files = val_data['val_files'] # shape (1, num_files (filled with filenames))
val_files = val_files.flatten() # flatten so 1 * num_files = num_files
print("shape of X_val: ", X_val.shape)
print("shape of y_val: ", y_val.shape)
print("number of val files (derived from the training_files element of the data variable): ", len(val_files))


# define input parameters for model
num_files_train = X_train.shape[0]
num_files_val = X_val.shape[0]
num_windows = X_train.shape[1]
num_samples = X_train.shape[2]
num_channels = X_train.shape[3]
print("number of files for training set (derived from first entry in the 4D cnn_input feature tensor): ", num_files_train)
print("number of files for val set (derived from first entry in the 4D cnn_input feature tensor): ", num_files_val)
print("number of windows per file: ", num_windows)
print("number of samples per window: ", num_samples)
print("number of channels per sample: ", num_channels)


# reshape X for LSTM input -- (num_files * num_windows, num_samples * num_channels)
# X_train = X_train.reshape(-1, num_samples * num_channels)
# X_val = X_val.reshape(-1, num_samples * num_channels)
# X_train = X_train.reshape(num_files_train, num_windows, num_samples * num_channels)
# X_val = X_val.reshape(num_files_val, num_windows, num_samples * num_channels)
# print("reshaped shape of X_train: ", X_train.shape)
# print("reshaped shape of X_val: ", X_val.shape)


# reshape y for LSTM input -- (num_files, num_windows) --> (num_files, num_windows, 1 or 2 if num_classes)
y_train = y_train[..., np.newaxis] 
y_val = y_val[..., np.newaxis]

print("new shape of y_train: ", y_train.shape)
print("new shape of y_val: ", y_val.shape)


# flatten window-level labels from 2D array to 1D vector ONLY for determining class weights (sklearn wants 1D arrays)
y_train_flattened = y_train.flatten()


# # compute class weights
# classes = np.unique(y_train_flattened)
# cw = class_weight.compute_class_weight(class_weight='balanced', classes=classes, y=y_train_flattened)


# # convert class weights into a dictionary
# class_weights = {i: cw[i] for i in range(len(classes))}
# print("class weights for training set: ", class_weights)


# # compute sample weights
# # flatten to compute weights
# y_flat = y_train.reshape(-1)  # (Ntr*W,)
# classes = np.unique(y_flat)
# class_w = compute_class_weight(class_weight='balanced', classes=classes, y=y_flat)
# class_w_dict = {int(c): float(w) for c, w in zip(classes, class_w)}
# print("class weights (per label):", class_w_dict)

# sample_weight_train = np.where(y_train.squeeze(-1) == 1, class_w_dict[1], class_w_dict[0]).astype(np.float32)
# sample_weight_val   = np.where(y_val.squeeze(-1)   == 1, class_w_dict[1], class_w_dict[0]).astype(np.float32)
# # Keras expects (batch, timesteps) for temporal outputs
# assert sample_weight_train.shape == (num_files_train, num_windows)
# assert sample_weight_val.shape   == (num_files_val,   num_windows)


# define input shape.
inputs = Input(shape=(num_windows, num_samples, num_channels))
# print("shape of input: ", inputs.shape)


# instantiate a keras-model object (that is ready to be trained).
model = CNN_LSTM_Classifier(num_windows=num_windows, num_samples_per_window=num_samples, num_channels=num_channels)


# display the shape of each layer in the cnn-lstm-lr model.
model.summary()


# define training parameters.
num_epochs = 20 # TODO: change to at least 50 or 60.
# batch_size = 16
batch_size = 8


# let model know how to save the best model.
# checkpoint = ModelCheckpoint(filepath=working_folder + "model.h5", monitor='val_loss', save_best_only=True, save_weights_only=False, mode='min', verbose=1) # TODO: comment/uncomment before running script.
# checkpoint = ModelCheckpoint("model.h5", monitor='val_loss', save_best_only=True, save_weights_only=False, mode='min', verbose=1) # TODO: comment/uncomment before running script.
checkpoint = ModelCheckpoint("model.h5", monitor='val_loss', save_best_only=True, mode='min', verbose=1) # TODO: comment/uncomment before running script.
reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=2, min_lr=1e-6, verbose=1)


# train the model and document its performance over each epoch.
# history = model.fit(X_train, y_train, validation_data=(X_val, y_val), epochs=num_epochs, batch_size=batch_size, callbacks=[checkpoint])
# history = model.fit(X_train, y_train, validation_data=(X_val, y_val, sample_weight_val), sample_weight=sample_weight_train, epochs=num_epochs, batch_size=batch_size, callbacks=[checkpoint, reduce_lr], verbose=1)
history = model.fit(X_train, y_train, validation_data=(X_val, y_val), epochs=num_epochs, batch_size=batch_size, callbacks=[checkpoint, reduce_lr], verbose=1)



# visualize the training process
plt.plot(history.history['loss'])
plt.plot(history.history['val_loss'])
plt.title('Model Loss Over Epochs')
plt.ylabel('Loss')
plt.xlabel('Epoch')
plt.legend(['Train', 'Validation'], loc='upper left')
plt.show() # TODO: comment/uncomment before running script.
# plt.savefig(working_folder + "train_plot.png") # TODO: comment/uncomment before running script.
