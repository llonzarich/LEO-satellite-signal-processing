# -----------------------------------------------------------------------------------------------------
# this script will...
# - use the trained model on unbiased test images to predict the presence of the signal AND bounding box coordinates
# - plot bounding boxes on the spectrogram image. 
# note: we don't need test labels to run this script.
# plan: (1) resize image in test images folder to match the files used as training inputs
#       (2) normalize pixels to (0,1)
#       (3) predict bounding box (first 4 values) and class (rest)
#       (4) scale bounding box coordinates back to original image size
#       (5) draw box and label on image
#       (6) save final visual output to inference_images.
# -----------------------------------------------------------------------------------------------------


# import packages
import tensorflow as tf
from tensorflow.keras.models import load_model
from imagesearch import config
from PIL import Image, ImageDraw # to draw and manipulate images
from tensorflow.keras.preprocessing.image import img_to_array
from tensorflow.keras.preprocessing.image import load_img
import numpy as np
import cv2
import os


# paths. # put in config.py file.
model_path = "output/detector.h5" # path to our saved model (with best weights).
test_spec_images_path = "bbox-data/testing-spectrograms" # path to testing images.
output_dir = "output/inference_images" # path to output images with predicted bounding boxes on them.
input_size = (224,224)


# load the model (with the best weights) from the 'output/detector.h5' folder
model = tf.keras.models.load_model(model_path)


for image in os.listdir(test_spec_images_path):
    image_path = os.path.join(test_spec_images_path, image) # "grab" the image in the file. 


    pil_image = load_img(image_path, target_size=input_size) # convert image from string to PIL image so we can draw on it.
    image_array = img_to_array(pil_image) / 255.0 # need to put image info as a NumPy array format so we can run the model on it
    image_batch = np.expand_dims(image_array, axis=0) # group images into batches in a NumPy array. must use batch because keras model expects inputs in batches.

    # predict class_prob and (a probabiliy that there is a signal/object in the image) and bbox coordinates (4 integers).
    class_prob, bbox_coordinates = model.predict(image_batch) # output 4 values.

    # unpack output (batch-->single image)
    class_prob = class_prob[0]
    bbox_coordinates = bbox_coordinates[0]
    class_index = np.argmax(class_prob)

    img = Image.open(image_path).convert("RGB")
    W, H = img.size # find the original size of the spectrogram png images.

    # scale bbox coordinates back to original image size
    xmin = int(bbox_coordinates[0] * W)
    ymin = int(bbox_coordinates[1] * H)
    xmax = int(bbox_coordinates[2] * W)
    ymax = int(bbox_coordinates[3] * H)

    # Draw rectangle & class label - https://github.com/AndrzejBandurski/Bounding_Box_Regression_TF/blob/master/Evaluation.py
    draw = ImageDraw.Draw(img)
    draw.rectangle([(xmin, ymin), (xmax, ymax)], outline="red", width=2)
    draw.text((xmin, max(ymin - 10,0)), f"Class {class_index}", fill="red")

    # save result
    os.makedirs(output_dir, exist_ok=True) # make output_dir if it doesn't exist
    save_path = os.path.join(output_dir, image)
    img.save(save_path)
    # image.save('inference_images/image_{}.png'.format(i + 1), 'png')
    print(f"Saved {save_path}")