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
# import keras
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Input, Dense, LSTM, Conv1D, TimeDistributed, MaxPooling1D, Flatten, Dropout, GlobalMaxPooling1D
from tensorflow.keras import optimizers
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping
from tensorflow.keras.optimizers import Adam 
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






# function to convert 'data' (a struct) --> 'data' (a dictionary)
def struct_to_dict(data_struct):
    if isinstance(data_struct, np.ndarray) and data_struct.size == 1:
        data_struct = data_struct.item()
    
    if not hasattr(data_struct, 'dtype') or data_struct is None:
        raise ValueError("Input is not a MATLAB struct")
    
    result = {}
    for field_name in data_struct.dtype.names:
        result[field_name] = data_struct[field_name].item()
    return result

    

# function to unpack the contents of data (a dictionary)
def unpack_data(mat_data):
    X = np.array([x[0] for x in mat_data['X'][0]]).astype(np.float32)
    y = np.array([y[0] for y in mat_data['y'][0]]).astype(np.float32)
    files = np.array([f[0] for f in mat_data['files']])
    
    return X, y, files




mat_struct_key = [k for k in data.keys() if not k.startswith('__')][0]
print("Using struct key:", mat_struct_key)



# (btw) levels: data --> cnn_input --> train_set, val_set, test_set --> X, y, and files for each of these sets 


# access train, val, test sets directly
train_set_struct = data['train_set']
val_set_struct = data['val_set']
test_set_struct = data['test_set']


# # define structs from 'data'
# cnn_input_struct = data['cnn_input']


# # unwrap if it's a 0-d array
# if isinstance(cnn_input_struct, np.ndarray) and cnn_input_struct.size == 1:
#     cnn_input_struct = cnn_input_struct.item()


# # convert 'cnn_input_struct' to a dictionary so we can unpack its contents (train_set, val_set, and test_set)
# cnn_input_dict = struct_to_dict(cnn_input_struct)


# # define set structs from 'cnn_input_dict'
# train_set_struct = cnn_input_dict['train_set']
# val_set_struct = cnn_input_dict['val_set']
# test_set_struct = cnn_input_dict['test_set']


# convert set structs to dictionaries, so we can unpack its contents (X, y, and filenames).
train_set = struct_to_dict(train_set_struct)
val_set = struct_to_dict(val_set_struct)
test_set = struct_to_dict(test_set_struct)


# # load train, val, and test sets
# train_set = data["train_set"]
# val_set = data["val_set"]
# test_set = data["test_set"]


# unpack sets
X_train, y_train, train_files = unpack_data(train_set)
X_val, y_val, val_files = unpack_data(val_set)
X_test, y_test, test_files = unpack_data(test_set)
print(f"number of files in training set: {X_train.shape}, {y_train.shape}")
print(f"number of files in val set: {X_val.shape}, {y_val.shape}")
print(f"number of files in test set: {X_test.shape}, {y_test.shape}")


# save test set for evaluation in evaluate.py
with open("test_set.pkl", "wb") as f:
    pickle.dump((X_test, y_test, test_files), f)


# compute class weights
classes = np.unique(y_train)
class_weights = class_weight.compute_class_weight(class_weight='balanced', classes=classes, y=y_train) 
print("class weights for training set: ", class_weights)


# convert class weights into a dictionary
class_weights = {i : class_weights[i] for i, label in enumerate(sorted(np.unique(y_train)))}


# define parameters for model
num_files = X_train.shape[0]
num_windows = X_train.shape[1]
num_samples_per_window = X_train.shape[2]
num_channels = X_train.shape[3]


inputs = Input(shape=(num_windows, num_samples_per_window, num_channels))
print("shape of input: ", inputs.shape)


# instantiate a keras-model object (that is ready to be trained).
model = CNN_LSTM_Classifier(num_windows=num_windows, num_samples_per_window=num_samples, num_channels=num_channels)


# display the shape of each layer in the cnn-lstm-lr model.
model.summary()


# define training parameters.
num_epochs = 20
batch_size = 16


# let model know how to save the best model.
checkpoint = ModelCheckpoint(filepath=working_folder + "model.h5", monitor='val_loss', save_best_only=True, save_weights_only=False, mode='min', verbose=1)


# train the model and document its performance over each epoch.
history = model.fit(X_train, y_train, validation_data=(X_val, y_val), epochs=num_epochs, batch_size=batch_size, callbacks=[checkpoint], class_weight=class_weights)


# visualize the training process
plt.plot(history.history['loss'])
plt.plot(history.history['val_loss'])
plt.title('Model Loss Over Epochs')
plt.ylabel('Loss')
plt.xlabel('Epoch')
plt.legend(['Train', 'Validation'], loc='upper left')
plt.show() # TODO: comment/uncomment before running script.
# plt.savefig(working_folder + "train_plot.png") # TODO: comment/uncomment before running script.








# # function to convert cell arrays to tensors
# def cell_to_tensor(cell_array):
#     return np.array([x[0] for x in cell_array[0]]).astype(np.float32)


# # load train, val, and test sets
# train_set = data["train_set"]
# val_set = data["val_set"]
# test_set = data["test_set"]

# X_train = cell_to_tensor(train_set["X"])
# y_train = cell_to_tensor(train_set["y"])

# X_val = cell_to_tensor(val_set["X"])
# y_val = cell_to_tensor(val_set["y"])

# X_test = cell_to_tensor(test_set["X"])
# y_test = cell_to_tensor(test_set["y"])

# train_loader = DataLoader(TensorDataset(X_train, y_train), batch_size=32, shuffle=True)
# val_loader = DataLoader(TensorDataset(X_val, y_val), batch_size=32, shuffle=False)
# test_loader = DataLoader(TensorDataset(X_test, y_test), batch_size=32, shuffle=False)




# # define input parameters and compute the training and val set splits.
# num_windows, num_samples, num_channels, X_train, y_train, training_files, X_val, y_val, val_files = prepare_data()


# # compute class weights
# classes = np.unique(y_train)
# class_weights = class_weight.compute_class_weight(class_weight='balanced', classes=classes, y=y_train) 
# print("class weights for training set: ", class_weights)


# # convert class weights into a dictionary
# class_weights = {i : class_weights[i] for i, label in enumerate(sorted(np.unique(y_train)))}

# # define input shape.
# inputs = Input(shape=(num_windows, num_samples, num_channels))
# # print("shape of input: ", inputs.shape)


# # instantiate a keras-model object (that is ready to be trained).
# model = CNN_LSTM_Classifier(num_windows=num_windows, num_samples_per_window=num_samples, num_channels=num_channels)


# # display the shape of each layer in the cnn-lstm-lr model.
# model.summary()


# # define training parameters.
# num_epochs = 20
# batch_size = 16


# # let model know how to save the best model.
# checkpoint = ModelCheckpoint(filepath=working_folder + "model.h5", monitor='val_loss', save_best_only=True, save_weights_only=False, mode='min', verbose=1)


# # train the model and document its performance over each epoch.
# history = model.fit(X_train, y_train, validation_data=(X_val, y_val), epochs=num_epochs, batch_size=batch_size, callbacks=[checkpoint], class_weight=class_weights)


# # visualize the training process
# plt.plot(history.history['loss'])
# plt.plot(history.history['val_loss'])
# plt.title('Model Loss Over Epochs')
# plt.ylabel('Loss')
# plt.xlabel('Epoch')
# plt.legend(['Train', 'Validation'], loc='upper left')
# plt.show() # TODO: comment/uncomment before running script.
# # plt.savefig(working_folder + "train_plot.png") # TODO: comment/uncomment before running script.
