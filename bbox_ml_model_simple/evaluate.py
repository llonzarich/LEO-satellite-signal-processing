# --------------------------------------------------------------------------------
# this script will...
# - use the trained model on unbiased test images to predict presence of a signal AND bbox coordinates 
# - compare to true labels to measure performance of trained model (i.e. IoU, accuracy)
# note: we need ground truth labels (i.e. classes and true bounding boxes coordinates).
# --------------------------------------------------------------------------------


import tensorflow as tf
from tensorflow.keras.models import load_model
from imagesearch import config
# from PIL import Image, ImageDraw # to draw and manipulate images
from tensorflow.keras.preprocessing.image import img_to_array
from tensorflow.keras.preprocessing.image import load_img
# from tensorflow.keras.models import load_model
# import numpy as np
# import mimetypes
# import argparse
# import imutils
import cv2
import os
# from tensorflow.keras.preprocessing.image import load_img, img_to_array
from Model import SignalDetection # a class which has data loading and model building
from PIL import Image, ImageDraw # to visualize bounding boxes
import numpy as np

