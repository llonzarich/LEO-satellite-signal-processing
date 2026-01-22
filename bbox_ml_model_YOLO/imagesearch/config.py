#--------------------------------------------------------------------------------------------------------------------------
# purpose: this script holds settings that can be modified.
#--------------------------------------------------------------------------------------------------------------------------


import os # to build dynamic paths.


# define the path to the input dataset
# define the base path to derive the path to the spectrogram images folder and bounding box annotations folder.
base_path = "bbox-data"
spec_path = os.path.sep.join([base_path, "spectrograms"]) # path to spectrogram images (.png files).
# annotated_spec_path = os.path.sep.join([base_path, "annotated-spectrograms"]) # path to bounding box annotations (in .xml files.






# # USE IF I CREATE .csv (training_data.csv and validation_data.csv) FILES WITH ALL THE INFORMATION FROM EACH ANNOTATED SPECTROGRAM .xml FILE. 
# training_csv_file = 'bbox-data/annotated-spectrograms/training_data.csv'
# training_image_dir = 'bbox-data/spectrograms/training-spectrograms'

# training_image_records = pd.read_csv(training_csv_file) # grab the .csv file with spectrogram annotations.
# train_image_path = os.path.join(os.getcwd(), training_image_dir) # grab the .png files with the spectrograms.

# train_images = [] # to hold all our images.
# train_targets = [] # to hold all predictions and bounding box coordinates.
# train_labels = [] # to hold the filenames associated with the actual image

# for index, row in training_image_records.iterrows(): # iterate through each row in the .csv file. 
    
#     (filename, width, height, class_name, xmin, ymin, xmax, ymax) = row # define what we are looking for in the row. 
    
#     train_image_fullpath = os.path.join(train_image_path, filename)
#     train_img = keras.preprocessing.image.load_img(train_image_fullpath, target_size=(height, width))
#     train_img_arr = keras.preprocessing.image.img_to_array(train_img) # .png spectrogram image --> array.
    
#     xmin = round(xmin/ width, 2)
#     ymin = round(ymin/ height, 2)
#     xmax = round(xmax/ width, 2)
#     ymax = round(ymax/ height, 2)


# val_csv_file = 'bbox-data/annotated-spectrograms/val_data.csv'
# val_image_dir = 'bbox-data/spectrograms/val-spectrograms'

# val_image_records = pd.read_csv(val_csv_file)
# val_image_path = os.path.join(os.getcwd(), val_image_dir)

# val_images = [] # to hold all of our images.
# val_targets = [] # to hold our predictions and bounding box coordinates.
# val_labels = [] # to hold the filenames associated with the actual image. 

# for index, row in val_image_records.iterrows():
    
#     (filename, width, height, class_name, xmin, ymin, xmax, ymax) = row
    
#     val_image_fullpath = os.path.join(val_image_path, filename)
#     val_img = keras.preprocessing.image.load_img(val_image_fullpath, target_size=(height, width))
#     val_img_arr = keras.preprocessing.image.img_to_array(val_img)
    
#     xmin = round(xmin/ width, 2)
#     ymin = round(ymin/ height, 2)
#     xmax = round(xmax/ width, 2)
#     ymax = round(ymax/ height, 2)


# # convert lists to numpy arrays
# train_images = np.array(train_images)
# train_target = np.array(train_targets)
# train_labels = np.array(train_labels)

# val_images = np.array(val_images)
# val_targets = np.array(val_targets)
# val_labels = np.aray(val_labels)







# define path to the base output directory
base_output = "output"
model_path = os.path.sep.join([base_output, "detector.h5"]) # path to the tensorflow-serialized output model.
plot_path = os.path.sep.join([base_output, "plot.png"]) # path to the output training history plot with accuracy and loss curves.
test_filenames = os.path.sep.join([base_output, "test_images.txt"]) # path to text file of image filenames that we've selected for our testing set.


# initialize DL hyperparameters
learning_rate = 1e-4
num_epochs = 25
batch_size = 32
num_classes = 2
classes = ["signal", "no-signal"]





