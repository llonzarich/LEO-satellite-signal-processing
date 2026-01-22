#--------------------------------------------------------------------------------------------------------------------------
# purpose: this script trains the bounding box model.
# output: a trained bounding box model that can be used to generate/predict 1 bounding box x-,y-pixel coordinates for an image.
#--------------------------------------------------------------------------------------------------------------------------


# import necessary packages
import tensorflow as tf
from tensorflow import keras
from imagesearch import config # paths and hyperparameters defined in the imagesearch directory. 
from tensorflow.keras import layers # added for medium tutorial.
from tensorflow.keras.layers import Rescaling
# from tensorflow.keras.applications import VGG16 # CNN architecture to serve as the base network for fine tuning.
from tensorflow.keras.layers import Flatten
from tensorflow.keras.layers import Dense
from tensorflow.keras.layers import Input
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.preprocessing.image import img_to_array
from tensorflow.keras.preprocessing.image import load_img
from sklearn.model_selection import train_test_split # for slicing our network into training and testing sets.
import matplotlib.pyplot as plt
import numpy as np # python's standard numerical processing library
import cv2 # openCV
import os
import time


# note: if you have all the packages and versions in the requirements.txt file installed, you can run this file up to this line!


# load the contents of the csv spectrogram annotations file.
# note: each row in the csv file is organized as... 'filename' (i.e. image_0001.png), 'width', 'height', 'class_label' (i.e. signal), 'xmin' (an int), 'ymin' (an int), 'xmax' (an int), 'ymax' (an int).
print("Loading csv spectrogram annotations dataset...")
annotations_path = 'bbox-data/spectrogram-annotations.csv' # the path to the csv spectrogram annotations file. 
rows = open(annotations_path).read().strip().split("\n") # read content of csv file into a string, removes trailing or leading whitespaces, splits string separate elements in a list, each on a 'row'.


# initialize lists for image-annotation pairs.
images = [] # to hold our images data arrays.
targets = [] # to hold our target bounding box coordinates.
# filenames = [] # to hold the filenames associated with our images. 
labels = [] # added 6/8. i need to populate this. If the current row has a signal (aka, if it's in the csv file), then append a 1, otherwise, append a 0.


rows = rows[1:] # skip the header row.


# iterate through each row in the csv spectrogram annotations file to populate the lists with image-annotations pairs.
for row in rows: 
    
    # load the spectrogram annotations of the current row into a labeled comma-separate list of strings.
    row = row.split(",") # split the row into a comma-separated list of strings.
    (filename, width, height, class_label, startX, startY, endX, endY) = row # unpack the list into 8 variables.
    
    # load a spectrogram image with OpenCV.
    image_path = os.path.sep.join([config.spec_path, filename]) # form the path to the input image. telling machine to "look in the folder (specified by the 'spec_path' variable) and pull the spectrogram image that is named 'filename'". Uses 'filename' from the csv file (of the row we're working with on this current iteration) to load the corresponding image file.
    image = cv2.imread(image_path) # load the image into memory using OpenCV.
    (h, w) = image.shape[:2] # grab the image dimensions.

    # scale the bounding box coordinates to the range [0,1].
    startX = float(startX) / w
    startY = float(startY) / h
    endX = float(endX) / w
    endY = float(endY) / h

    # load spectrogram image and preprocess it. (overwrite previous OpenCV loaded image).
    image = load_img(image_path, target_size=(224,224)) # ensure image is 224x224 pixels for training
    image = img_to_array(image) # convert the image to array format.

    # update 'images', 'targets', and 'filenames' lists. The preprocessed image and normalized bounding box annotations become a pair.
    images.append(image)
    targets.append((startX, startY, endX, endY))
    # filenames.append(filename)
    labels.append(1) # added 6/8. 
    # or if spectrogram has no signal just do train_targets = np.zeros(shape=(num_specs,224,224,4))?


# convert 'images' and 'targets' lists to numpy arrays
images = np.array(images, dtype = "float32") / 255.0
targets = np.array(targets, dtype = "float32")
labels = np.array(labels, dtype = "float32")


print("testing at line 76")


# split the data (images and targets) into training and testing sets (90% of the data for training and 10% for testing)
# split = train_test_split(images, targets, filenames, test_size=0.10, random_state=42) # splitting the images array, targets array, and filename array into training and testing sets. 
split = train_test_split(images, targets, labels, test_size=0.10, random_state=42) #add 6/8.

# unpack the data split.
(train_images, val_images) = split[:2] 
(train_targets, val_targets) = split[2:4]
# (train_filenames, test_filenames) = split[4:]
(train_labels, val_labels) = split[4:] # add 6/8.


# print("Saving testing filenames...")
# f = open(config.test_filenames, "w")
# f.write("\n".join(testing_filenames))
# f.close()


# input layer
input_shape = (224, 224, 3) # 3 is the most commonly used kernel size.
input_layer = tf.keras.layers.Input(input_shape)


# base layers
base_layers = Rescaling(1./255, name='bl_1')(input_layer) # normalizes pixel values from [0,255] --> [0,1].
base_layers = layers.Conv2D(16, 3, padding='same', activation='relu', name='bl_2')(base_layers) # use 16 filters (sized 3x3) to extract features.
base_layers = layers.MaxPooling2D(name='bl_3')(base_layers) # reducing spatial dimensions.
base_layers = layers.Conv2D(32, 3, padding='same', activation='relu', name='bl_4')(base_layers) # use 32 filters (sized 3x3) to extract (more complex) features.
base_layers = layers.MaxPooling2D(name='bl_5')(base_layers) # reducing spatial dimensions. 
base_layers = layers.Conv2D(64, 3, padding='same', activation='relu', name='bl_6')(base_layers) # use 64 filters (sized 3x3) to extract (even more complex) features. 
base_layers = layers.MaxPooling2D(name='bl_7')(base_layers) # reducing spatial dimensions. 
base_layers = layers.Flatten(name='bl_8')(base_layers) # converts 3D feature maps --> 1D vector to feed into fully connected layers.


# (1) classifier branch -- to predict which class the image belongs to ("signal" or "no signal")
# output is a single sigmoid neuron.
# note: I need to add spectrograms with no signal into my training data. 
classifier_branch = layers.Dense(128, activation='relu', name='cb_1')(base_layers) # takes in the flattened feature map (a 1D vector) and passes it thru a fully connected layer with 128 neurons and using ReLU activation. 
# classifier_branch = layers.Dense(config.num_classes, name='cb_head')(classifier_branch) # outputs the class scores using. This layer is sized to the number of classes (2)
classification_branch = layers.Dense(1, activation='sigmoid', name='cb_head')(classifier_branch)

# (2) localizer branch -- to predict WHERE the object is located in the image.
# note: more Dense layers to reduce dimensionality 
# note: the input is the same flattened feature map (a 1D vector)
# output is 4 normalized coordiantes
locator_branch = layers.Dense(128, activation='relu', name='lb_1')(base_layers) 
locator_branch = layers.Dense(64, activation='relu', name='lb_2')(locator_branch)
locator_branch = layers.Dense(32, activation='relu', name='lb_3')(locator_branch)
locator_branch = layers.Dense(4, activation='sigmoid', name='lb_head')(locator_branch) # 4 outputs with sigmoid activation (to normalize the outputs to [0,1])


# create the model class 
# pass in the input layer and the outputs of our 2 output branches -- to get our 2 outputs (class -- "signal" or "no-signal" -- and location).
# model = tf.keras.Model(input_layer, outputs=[classifier_branch, locator_branch])
model = tf.keras.Model(input_layer, outputs=[classification_branch, locator_branch]) #add 6/8


# compiling the model 
# create dictionary to define the different loss functions for the two branches
# losses = {"cb_head":tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True), 
#           "lb_head":tf.keras.losses.MSE} 
losses = {"cb_head":tf.keras.losses.binary_crossentropy, #add 6/8
          "lb_head":tf.keras.losses.MSE}
# optimizer = Adam(lr=config.learning_rate)
# model.compile(loss=losses, optimizer=optimizer, metrics=['accuracy']) # use Adam as the optimizer.
# model.compile(loss=losses, optimizer='Adam', metrics=['accuracy', 'accuracy']) # use Adam as the optimizer.
# model.compile(loss=losses, optimizer='Adam', metrics=['accuracy', 'accuracy'])
model.compile(loss=losses, optimizer=keras.optimizers.Adam(learning_rate=config.learning_rate), metrics=['accuracy', 'accuracy'])
print(model.summary())
# print("HELLLLOOOO")


# create dictionaries to feed the model my two outputs during training.
train_targets_dict = { # tells keras what target goes to what output
    # "cb_head": train_filenames, # the first node of the cb is assigned to the first element in the array 'train_filenames'. this needs to be integers
    "cb_head": train_labels, # teh first node of the cb is assigned to. no. output for classifing.
    "lb_head": train_targets # the first node of the lb is assigned the first element in the array 'train_targets'. (bounding box coordinates). no. output for bbox coordinates
}
val_targets_dict = {
    # "cb_head": test_filenames, 
    "cb_head": val_labels,
    "lb_head": val_targets
}


# # i added: to put list into array. but i dont think this works
# trainTargets = np.array(list(train_targets_dict.values()), dtype="float32")

# testing stuff
# print("train_iamges shape:", train_images.shape)
# print("train_images dtype: ", train_images.dtype)
# print("trainTargets shape: ", train_targets_dict.shape)
# print("trainTargets dtype: ", train_targets_dict.dtype)
# print("Example target: ", train_targets_dict[0])
# print("shape of train_targets_dict['cb_head']:", train_targets_dict['cb_head'])
# print("shape of train_targets_dict['lb_head']: ", train_targets_dict['lb_head'])


# train the network for bounding box regression.
# .fit keeps track of training and validation metrics at each epoch. the trianing data and validation data is used to train the model via .fit()
# history = model.fit(train_images, train_targets_dict, validation_data=(test_images, test_targets), batch_size=4, epochs=config.num_epochs, shuffle=True, verbose=1)
# when you train a model with multiple outputs in keras, you need to tell .fit() which labels go with whcih outputs
# format of .fit(): modle.fit(x=inputs, y=targets, ...)
# train_images is input data, train_targets_dict is target data
initial_time = time.time() # to keep track of training time. 
history = model.fit(train_images, train_targets_dict, validation_data=(val_images, val_targets_dict), batch_size=4, epochs=config.num_epochs, shuffle=True, verbose=1)
final_time = time.time() # to keep track of training time
eta = (final_time - initial_time)
time_unit = 'seconds'
print("time taken to train model: ", eta, "seconds")


model.save("output/detector.h5")

# print(history.history.keys())
# plt.plot(history.history['loss'], label='Training loss')
# plt.plot(history.history['val_loss'], label='Validation loss')
# plt.title('total model loss')
# plt.xlabel('epoch')
# plt.ylabel('loss')
# plt.legend()
# plt.show()
# # prediction = model.predict(train_images, train_targets_dict, validation_data=(test_images, test_targets_dict))
# # plt.plot(history.history[iou])
# # plt.title('loss graph')
# # plt.xlabel('epoch')
# # plt.ylabel('loss')

# # for i in range(10):
# #     print('prediction:',prediction[i])
# #     print('ground truth:',labels[i])
# # score = model.evaluate(train_targets, labels, batch_size=128)

# for layer in model.layers:
#     if layer.name.startswith('bl_'):
#         layer.trainable = False
        
# for layer in model.layers:
#     if layer.name.startswith('lb_'):
#         layer.trainable = False


