#--------------------------------------------------------------------------------------------------------------------------
# purpose: this script contains settings that can be modified -- file paths and DL hyperparamters.
#--------------------------------------------------------------------------------------------------------------------------

import os # to build dynamic paths.


# define the path to the input dataset
# define the base path to derive the path to the spectrogram images folder and bounding box annotations folder.
# base_path = "bbox-data"
# spec_path = os.path.sep.join([base_path, "spectrograms"]) # path to spectrogram images (.png files).
# annotated_spec_path = os.path.sep.join([base_path, "annotated-spectrograms"]) # path to bounding box annotations (in .xml files.
spec_path = "bbox-data/spectrograms" # path to spectrogram images (.png files).
annotations_path = "bbox-data/spectrogram-annotations.csv"


# # define path to the base output directory
# base_output = "output"
# model_path = os.path.sep.join([base_output, "detector.h5"]) # path to the tensorflow-serialized output model.
# plot_path = os.path.sep.join([base_output, "plot.png"]) # path to the output training history plot with accuracy and loss curves.
# test_filenames = os.path.sep.join([base_output, "test_images.txt"]) # path to text file of image filenames that we've selected for our testing set.


# initialize DL hyperparameters
learning_rate = 1e-4
num_epochs = 25
batch_size = 32
num_classes = 2
classes = ["signal", "no-signal"]


# define the path to the output directory
model_output_path = "output/detector.h5"

