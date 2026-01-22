# --------------------------------------------------------------------------------
# purpose: - this script evaluates the trained model on unseen testing data. 
#          - compute the accuracy, F1 score, and confusion matrix
# --------------------------------------------------------------------------------

# import libraries
# import torch 
from tensorflow.keras.models import load_model
import pickle
import numpy as np
from matplotlib import pyplot 
import matplotlib.pyplot as plt
from sklearn.metrics import confusion_matrix, classification_report
import seaborn as sns

import pandas as pd # for data processing and file i/o.
import mat73 # for building dynamic paths. # TODO: comment/uncomment before running script.
import numpy as np
import os

model_folder = "/home/wairimu/training_data_corrected_windowing/" 
test_data_folder = "/home/wairimu/training_data_corrected_windowing/test_files/ch1_community_forge/target_testing"

# load model
model = load_model(model_folder + "model.h5") # TODO: comment/uncomment before running script.
class_names = ["no-pattern", "pattern"]

directory = os.fsencode(test_data_folder)

fnames = []
predictions = []
for file in os.listdir(directory):
    filename = os.fsdecode(file)
    if filename.endswith(".mat"): 
        part_filename = filename 
        filename = os.path.join(test_data_folder, filename)
        print("filename: ", filename)
        fnames.append(filename)
        data = mat73.loadmat(filename) 
        data = data["segmented_test_signal"]

        # cnn_input = np.expand_dims(data, axis = -1)
        cnn_input = data[:, :, np.newaxis]
        print("shape of cnn input: ", cnn_input.shape)
        prediction = model.predict(cnn_input)
        prediction = (prediction > 0.5).astype("int32")
        print("prediction: ", prediction)
        pred_contains_1 = np.any(prediction == 1)
        print("Contains 1: ", pred_contains_1)
        predictions.append(pred_contains_1)

        num_signals = cnn_input.shape[0]
        for  i  in range(num_signals):
            signal = cnn_input[i, :]
            print("plotting shape: ",  signal.shape)
            print(signal.flatten())
            plt.plot(signal.flatten())
            plt.title(f"Prediction: {pred_contains_1}")
            plt.xlabel("Time")
            plt.ylabel("Amplitude")
            plt.savefig(test_data_folder + "prediction_"+part_filename+"_"+str(i)+".png")
            plt.clf() 
df = pd.DataFrame(np.array([fnames, predictions]),
                   columns=['filename', 'predicted_label'])
df.to_csv(test_data_folder+'test_results.csv', index=False)