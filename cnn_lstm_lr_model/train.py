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
import tensorflow as tf
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Input, Layer, Dense, LSTM, Conv1D, TimeDistributed, MaxPooling1D, Flatten, Dropout, GlobalMaxPooling1D
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
working_folder = "/home/wairimu/training_files_approach_7/" # TODO: comment/uncomment before running script.


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
        x = LSTM(self.lstm_units, return_sequences=True)(x)

        # attention layer
        x = Attention()(x)
        
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
    


# define attention layer class
class Attention(Layer):
    def __init__(self):
        super(Attention, self).__init__()
    
    def call(self, inputs):
        score = Dense(1, activation="tanh")(inputs)
        weights = tf.nn.softmax(score, axis=1)
        context = tf.reduce_sum(inputs * weights, axis=1) # ==> reduce to scalar across window dimension
        return context

    
    

# function to split the data into train, val, and testing sets.
def prepare_data():
    # # veronica's calling...
    # features = data['combined_cnn_input'].astype(np.float32) # TODO: comment/uncomment before running script.
    # labels = data['combined_labels_vector'].flatten().astype(np.float32) # TODO: comment/uncomment before running script.
    # files = file_names['combined_file_list'] # TODO: comment/uncomment before running script.
    # files = np.array(files).flatten() # TODO: comment/uncomment before running script.


    # lydia's calling...
    features = data['cnn_input'].astype(np.float32) # TODO: comment/uncomment before running script.
    labels = data['labels_vector'].flatten().astype(np.float32) # TODO: comment/uncomment before running script.
    files = file_names['file_list'] # TODO: comment/uncomment before running script.
    files = np.array(files).flatten() # TODO: comment/uncomment before running script.
    
    
    # print("all files: ", files)


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

    X_val = features[val_idx]
    y_val = labels[val_idx]
    val_files = files[val_idx]
    # print("val files: ", val_files)
    # print("val labels: ", y_val)

    X_test = features[test_idx]
    y_test = labels[test_idx]
    testing_files = files[test_idx]
    # print("test files: ", testing_files)
    # print("test labels: ", y_test)


    # ------- FOR RUNNING INTERFERENCE WITH SEEN DATA ---------------
    # define number of files for each class
    if OVERFITTING_TEST == 1:
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
        # with open(working_folder + "train_set_for_eval.pkl", "wb") as f: # TODO: comment/uncomment before running script.
        with open("train_set_for_eval.pkl", "wb") as f: # TODO: comment/uncomment before running script.
            pickle.dump((X_seen_data, y_seen_data, files_seen_data), f)
        return
    # -------------------------------------------------------------------    


    # save the X_test and y_test to be used for interference in evaluate.py.
    # with open(working_folder + "test_set.pkl", "wb") as f: # TODO: comment/uncomment before running script.
    with open("test_set.pkl", "wb") as f: # TODO: comment/uncomment before running script.
        pickle.dump((X_test, y_test, testing_files), f)
    
    
    return num_windows, num_samples, num_channels, X_train, y_train, training_files, X_val, y_val, val_files



# define input parameters and compute the training and val set splits.
num_windows, num_samples, num_channels, X_train, y_train, training_files, X_val, y_val, val_files = prepare_data()


# compute class weights
classes = np.unique(y_train)
class_weights = class_weight.compute_class_weight(class_weight='balanced', classes=classes, y=y_train) 
print("class weights for training set: ", class_weights)


# convert class weights into a dictionary
class_weights = {i : class_weights[i] for i, label in enumerate(sorted(np.unique(y_train)))}

# define input shape.
inputs = Input(shape=(num_windows, num_samples, num_channels))
# print("shape of input: ", inputs.shape)


# instantiate a keras-model object (that is ready to be trained).
model = CNN_LSTM_Classifier(num_windows=num_windows, num_samples_per_window=num_samples, num_channels=num_channels)


# display the shape of each layer in the cnn-lstm-lr model.
model.summary()


# define training parameters.
num_epochs = 20
batch_size = 16


# let model know how to save the best model.
# checkpoint = ModelCheckpoint(filepath=working_folder + "model.h5", monitor='val_loss', save_best_only=True, save_weights_only=False, mode='min', verbose=1) # TODO: comment/uncomment before running script.
checkpoint = ModelCheckpoint("model.h5", monitor='val_loss', save_best_only=True, save_weights_only=False, mode='min', verbose=1) # TODO: comment/uncomment before running script.


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













    # def __init__(self):
    #     super().__init__()
    #     self.layer1 = nn.Sequential(
    #         nn.Conv1d(n_features, 64, kernel_size=3), 
    #         nn.ReLU(), 
    #         nn.Dropout(0.2),
    #         nn.MaxPool1d(10))
    #     self.layer2 = nn.Flattern()
    #     self.layer3 = nn.Sequential(
    #         nn.Linear(768, 100),
    #         nn.ReLU())
    #     self.layer4 = nn.Sequential(
    #         nn.Linear(100, 6), 
    #         nn.Softmax())
        

    # def forward(self, x):
    #     out = self.layer1(x)
    #     out = self.layer2(out)
    #     out = self.layer3(out)
    #     out = self.layer4(out)
    #     return out


    






# model_m = Sequential()
# model_m.add(Reshape((TIME_PERIODS, num_sensors), input_shape=(input_shape,)))
# model_m.add(Conv1D(100, 10, activation='relu', input_shape=(TIME_PERIODS, num_sensors)))
# model_m.add(Conv1D(100, 10, activation='relu'))
# model_m.add(MaxPooling1D(3))
# model_m.add(Conv1D(160, 10, activation='relu'))
# model_m.add(Conv1D(160, 10, activation='relu'))
# model_m.add(GlobalAveragePooling1D())
# model_m.add(Dropout(0.5))
# model_m.add(Dense(num_classes, activation='softmax'))
# print(model_m.summary())



# another script:
# # Build the model

# # The model architecture type is sequential hence that is used
# model = Sequential()

# # We are using 4 convolution layers for feature extraction
# model.add(Conv1D(filters=512, kernel_size=32, padding='same', kernel_initializer='normal', activation='relu', input_shape=(256, 2)))
# model.add(Conv1D(filters=512, kernel_size=32, padding='same', kernel_initializer='normal', activation='relu'))
# model.add(Dropout(0.2)) # This is the dropout layer. It's main function is to inactivate 20% of neurons in order to prevent overfitting
# model.add(Conv1D(filters=256, kernel_size=32, padding='same', kernel_initializer='normal', activation='relu'))
# model.add(Dropout(0.2))
# model.add(Conv1D(filters=256, kernel_size=32, padding='same', kernel_initializer='normal', activation='relu'))
# model.add(MaxPool1D(pool_size=128)) # We use MaxPooling with a filter size of 128. This also contributes to generalization
# model.add(Dropout(0.2))

# # The prevous step gices an output of multi dimentional data, which cannot be fead directly into the feed forward neural network. Hence, the model is flattened
# model.add(Flatten())
# # One hidden layer of 128 neurons have been used in order to have better classification results
# model.add(Dense(units=128, kernel_initializer='normal', activation='relu'))
# model.add(Dropout(0.5))
# # The final neuron HAS to be 1 in number and cannot be more than that. This is because this is a binary classification problem and only 1 neuron is enough to denote the class '1' or '0'
# model.add(Dense(units=1, activation='sigmoid'))

# # Print the summary of the model
# model.summary()




# def init_model():
#     model = Sequential()
#     model.add(TimeDistributed(Conv1D(filters=8, kernel_size=2, activation='relu', padding='same'), batch_input_shape=(None, None, 4, 18)))
#     model.add(TimeDistributed(MaxPooling1D(pool_size=2)))
#     model.add(TimeDistributed(Flatten()))
#     model.add(LSTM(16))
#     model.add(Dense(9, activation='softmax'))
    
#     adam = optimizers.Adam(lr=0.001, beta_1=0.9, beta_2=0.999, epsilon=None, decay=0.0)

#     model.compile(optimizer=adam,
#                   loss='categorical_crossentropy',
#                   metrics=['accuracy'])
#     return model



# def init_model(self):
#         model = Sequential()

#         model.add(TimeDistributed(Conv1D(filters=32, kernel_size=3, activation='relu'))(inputs))
#         model.add(TimeDistributed(MaxPooling1D(pool_size=2))(x))
#         model.add(TimeDistributed(Conv1D(filters=64, kernel_size=3, activation='relu'))(x))
#         model.add(TimeDistributed(MaxPooling1D(pool_size=2))(x))

#         model.add(TimeDistributed(Flatten())(x))

#         model.add(TimeDistributed(LSTM(64, activation='tanh'))(x))

#         model.add(Dense(1, activation='sigmoid')(x))


#     def forward(self, x)
