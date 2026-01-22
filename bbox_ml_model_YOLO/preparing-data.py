# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# purpose: this script....
#  - splits the images into training and validation folders.
# - converts the csv file (with bbox annotations) into YOLO formatted .txt files (one txt file per images, each line in the .txt file has an object's bbox annotations...so if the image has 4 objects, the .txt file has 4 lines).
# - splits the txt file annotations into training and validation folders.
# 
# output: a training-and-testing folder setup, ready for YOLO
# |-- yolo-data/ (dataset root)
#     |-- images/
#         |-- train/
#         |-- val/
#         |-- test/ (png files)
#     |-- labels/
#         |-- train/
#         |-- val/
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

import os
import random
import shutil
import pandas as pd
from sklearn.model_selection import train_test_split


# spectrograms images folder splitting:
# |-- yolo-data/
#     |-- images/
#         |-- train/
#         |-- val/
input_dir = "bbox-data/spectrograms"
output_dir = "yolo-data"

all_images = [image for image in os.listdir(input_dir) if image.endswith(('.png'))]
train_images, val_images = train_test_split(all_images, test_size=0.2, random_state=42)

# create folders for training and validation image data.
os.makedirs(os.path.join(output_dir, 'images/train'), exist_ok=True)
os.makedirs(os.path.join(output_dir, 'images/val'), exist_ok=True)

# move training images and testing images to folders -- like how YOLO likes it.
for image in train_images:
    shutil.copy(os.path.join(input_dir, image), os.path.join(output_dir, 'images/train', image))
for image in val_images:
    shutil.copy(os.path.join(input_dir, image), os.path.join(output_dir, 'images/val', image))






# spectrogram annotations folder splitting:
# |-- yolo-data/
#     |-- labels/
#         |-- train/
#         |-- val/
# split csv file to match image train and validation folder splits.
# each image (png file) should have ONE corresponding annotation (txt file)...spectrogram001.png --> spectrogram001.txt with with the YOLO formatted annotations of each of its object on a separate line.
# YOLO formated .txt file rules...
# - one row per object bounding box.
# - each row must contain: <class_id (signal=0)> <x_center> <y_center> <width> <height>
# - bbox coordinates must be normalized to [0,1] (to do this, divide the pixedl values of x_center and width by the image's total width, and divide y_center and height by the image's total height).
# - class indeces are zero-indexed (i.e., the first class=0, second class=1,etc).

# paths. add to config.py file.
annotations_csv_file = "bbox-data/spectrogram_annotations.csv"
txt_output_dir = "lots-of-txt-files"
final_output_dir = "yolo-data"


# ----- create txt files (1 for each image) from csv file ---------
df = pd.read_csv(annotations_csv_file)

# make the txt_output_dir folder if it isn't already made.
os.makedirs(txt_output_dir, exist_ok=True) 

# loop through annotations in csv file to convert original bbox coordinates (xmin, ymin, xmax, ymax) to YOLO format (class_id,xcenter,ycenter,width,height).
for _, row in df.iterrows():
    
    # extract annotations from the row
    filename = row['filename']
    class_label = row['class_label'] # "signal" must be converted to 0.
    image_width = row['width']
    image_height = row['height']

    # convert "signal" --> 0
    if class_label == "signal":
        class_id = 0 # use class_id from now on (YOLO formatting thing)
    else:
        continue # we won't deal with more than 1 class.
    
    # convert og bbox coordinates (xmin,ymin,xmax,ymax) --> YOLO style (x_center, y_center)
    xmin, ymin, xmax, ymax = row['xmin'], row['ymin'], row['xmax'], row['ymax']
    x_center = ((xmin + xmax)/2) / image_width
    y_center = ((ymin + ymax)/2) / image_height 
    bbox_width = (xmax - xmin) / image_width
    bbox_height = (ymax - ymin) / image_height

    # create a .txt file for the current image
    label_filename = os.path.splitext(filename)[0] + ".txt" # split "spectrogram001.png" into ["spectrogram001", ".png"]. the [0] grabs "spectrogram001"
    label_path = os.path.join(txt_output_dir, label_filename) # lots-of-txt-files/spectrogram001.txt

    # append the annotation to the .txt file
    with open(label_path, 'a') as f:
        f.write(f"{class_id} {x_center:.6f} {y_center:.6f} {bbox_width:.6f} {bbox_height:.6f}\n")


# --------- split txt files into train and validation folders ---------
all_annotations = [annotation for annotation in os.listdir(txt_output_dir) if annotation.endswith(('.txt'))]
train_annotations, val_annotations = train_test_split(all_annotations, test_size=0.2, random_state=42)

# create folders for training and validation annotation data.
os.makedirs(os.path.join(final_output_dir, 'labels/train'), exist_ok=True)
os.makedirs(os.path.join(final_output_dir, 'labels/val'), exist_ok=True)

# move training annotations and val annotations to folders -- like how YOLO likes it
for annotation in train_annotations:
    shutil.copy(os.path.join(txt_output_dir, annotation), os.path.join(final_output_dir, 'labels/train', annotation))
for annotation in val_annotations:
    shutil.copy(os.path.join(txt_output_dir, annotation), os.path.join(final_output_dir, 'labels/val', annotation))


