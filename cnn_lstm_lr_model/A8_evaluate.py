# --------------------------------------------------------------------------------
# purpose: - this script evaluates the trained model on unseen testing data. 
#          - compute the accuracy, F1 score, and confusion matrix
# --------------------------------------------------------------------------------

# import libraries
from tensorflow.keras.models import load_model
import pickle
import numpy as np
from matplotlib import pyplot 
import matplotlib.pyplot as plt
from sklearn.metrics import confusion_matrix, classification_report
import seaborn as sns
from A8_load_data import test_data


# working_folder = "/home/wairimu/training_data_adjusted_window/"


# unpack data from test set 
X_test = test_data['cnn_input_test']
y_test = test_data['window_labels_test']
y_test = y_test[..., np.newaxis]
testing_files = test_data['test_files']
testing_files = testing_files.flatten()
print("shape of X_test: ", X_test.shape)
print("shape of y_test: ", y_test.shape)
print("number of testing files: ", len(testing_files))


# define input parameters for model
num_files_test = X_test.shape[0]
num_windows = X_test.shape[1]
num_samples = X_test.shape[2]
num_channels = X_test.shape[3]
print("number of files for testing set: ", num_files_test)
print("number of windows per file: ", num_windows)
print("number of samples per window: ", num_samples)
print("number of channels per sample: ", num_channels)


# # reshape for LSTM input -- (num_files, num_windows, features = num_samples * num_channels)
# X_test = X_test.reshape(num_files_test, num_windows, num_samples * num_channels)
# print("reshaped shape of X_train: ", X_test.shape)


# # flatten window-level labels from 2D array to 1D vector
# y_test_flattened = y_test.flatten()


# ------- FOR RUNNING INTERFERENCE WITH SEEN DATA -------------
# TODO: comment/uncomment before running script to run interference with seen data vs actual test set data.
# with open(working_folder+"train_set_for_eval", "rb") as f:
#     X_seen_data, y_seen_data, files_seen_data = pickle.load(f)
# -------------------------------------------------------------


# load model
# model = load_model(working_folder + "model.h5") # TODO: comment/uncomment before running script.
model = load_model('model.h5') # TODO: comment/uncomment before running script.


# define parameters
batch_size = 32
class_names = ["no-pattern", "pattern"]


# function to display confusion matrix and other metrics.
def display_results(y_test, predictions, class_names):
    
    # btw: y_test is originally shape (num_files, num_windows)
    # btw: 'predictions' (the output of the model) is shape (num_files, num_windows, 1)

    threshold = 0.5
    
    print("reshaped shape of y_test: ", y_test.shape)
    print("shape of predictions (output of the model): ", predictions.shape)

    # flatten y_test and predictions (in order to use sklearn metrics)
    flat_y_test = y_test.squeeze(-1).flatten()
    flat_y_predictions = predictions.squeeze(-1).flatten()

    # convert window-level probabilies into binary labels (0 or 1)
    y_pred_labels = (flat_y_predictions >= threshold).astype(int)

    cm = confusion_matrix(flat_y_test, y_pred_labels)

    print("------ Confusion Matrix ------")
    print(cm)

    print("------ Classification Report -------")
    print(classification_report(flat_y_test, y_pred_labels, target_names=class_names))

    # plot cm
    plt.figure(figsize=(10,8))
    df = sns.heatmap(cm, annot=True, fmt='g', cmap='Blues', xticklabels= class_names , yticklabels= class_names)
    plt.xlabel('Predicted')
    plt.ylabel('Actual')
    plt.show() # TODO: comment/uncomment before running script.
    # plt.savefig(working_folder+"evaluate.png") # TODO: comment/uncomment before running script.





# run interference
# btw: model output is (num_files, num_windows, 1)
# TODO: comment/uncomment before running script to run interference with seen data vs actual test set data.
test_loss, test_accuracy = model.evaluate(X_test, y_test, batch_size=batch_size, verbose=0)
print("Accuracy of the CNN-LSTM model:", test_accuracy)


predictions = model.predict(X_test)
display_results(y_test, predictions, class_names)


# # ------- FOR RUNNING INTERFERENCE WITH SEEN DATA -------------
# # TODO: comment/uncomment before running script to run interference with seen data vs actual test set data.
# test_loss, test_accuracy = model.evaluate(X_seen_data, y_seen_data, batch_size=batch_size, verbose=0)
# print("Accuracy of the CNN-LSTM model:", test_accuracy)
# predictions = model.predict(X_seen_data)
# display_results(y_seen_data, predictions, class_names)
# # -------------------------------------------------------------












# def evaluate_model():
#     # # define training and model parameters
#     # input_size = 14
#     # hidden_size = 64
#     # num_layers = 1 # number of LSTM layers. change to 2 if we are dealing with longer term dependencies.
#     # output_size = 1


#     # # instantiate a model object.
#     # model = Classifier(input_size, hidden_size, num_layers, output_size)



#     # load the best model weights from the .pth file (these were saved from after training).
#     model_path = 'model.h5'
#     model = load_model(model_path)

    



#     # set model to evaluation mode.
#     model.eval()


#     # generate predictions.
#     with torch.no_grad():
#         prediction = model(X_test_tensor) # generate predictions on test data.
#         # prediction = torch.sigmoid(prediction).squeeze()
#         prediction = (prediction >= 0.5).int() 



#     # accuracy = (prediction.argmax(dim=1).round() == y_test_tensor).float().mean().item()
#     accuracy = accuracy_score(y_test_tensor, prediction)
#     f1 = f1_score(y_test_tensor, prediction)
#     conf_matrix = confusion_matrix(y_test_tensor, prediction)


#     # display metrics
#     print("Accuracy: ", accuracy)
#     print("F1 score: ", f1)
#     print("Confusion Matrix: \n", conf_matrix)


# if __name__ == "__main__":
#     evaluate_model()