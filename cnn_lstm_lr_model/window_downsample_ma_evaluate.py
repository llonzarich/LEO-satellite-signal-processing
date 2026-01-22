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


working_folder = "/home/wairimu/training_data_corrected_windowing/" # TODO: comment/uncomment before running script.


# load the testing sets from the train-test-split that was performed in train.py.
with open(working_folder + "test_set.pkl", "rb") as f: # TODO: comment/uncomment before running script.
# with open("test_set.pkl", "rb") as f: # TODO: comment/uncomment before running script.
    X_test, y_test = pickle.load(f)


# ------- FOR RUNNING INTERFERENCE WITH SEEN DATA -------------
# TODO: comment/uncomment before running script to run interference with seen data vs actual test set data.
# with open(working_folder+"train_set_for_eval", "rb") as f:
#     X_seen_data, y_seen_data, files_seen_data = pickle.load(f)
# -------------------------------------------------------------


# load model
model = load_model(working_folder + "model.h5") # TODO: comment/uncomment before running script.
# model = load_model('model.h5') # TODO: comment/uncomment before running script.


# define parameters
batch_size = 32
class_names = ["no-pattern", "pattern"]


# function to display confusion matrix and other metrics.
def display_results(y_test, predictions, class_names):
    y_test = y_test
    y_scores = np.argmax(predictions, axis=1)
    y_pred = (predictions > 0.5).astype("int32")
    y_pred = y_pred.flatten()
    print("y scores: ", y_scores)
    print("y pred: ", y_pred)
    y_scores = y_pred

    classes = len(class_names)
    cm = confusion_matrix(y_test, y_scores)

    print("------ Confusion Matrix ------")
    print(cm)

    print("------ Classification Report -------")
    print(classification_report(y_test, y_scores, target_names=class_names))
    con = np.zeros((classes, classes))
    
    for x in range(len(class_names)):
        for y in range(len(class_names)):
            con[x, y] = cm[x, y]
    
    plt.figure(figsize=(10,8))
    df = sns.heatmap(con, annot=True, fmt='g', cmap='Blues', xticklabels= class_names , yticklabels= class_names)
    plt.xlabel('Predicted')
    plt.ylabel('Actual')
    # plt.show() # TODO: comment/uncomment before running script.
    plt.savefig(working_folder+"evaluate.png") # TODO: comment/uncomment before running script.


# run interference
# TODO: comment/uncomment before running script to run interference with seen data vs actual test set data.
test_loss, test_accuracy = model.evaluate(X_test, y_test, batch_size=batch_size, verbose=0)
print("Accuracy of the CNN-LSTM model:", test_accuracy)
predictions = model.predict(X_test)
print("predictions: ", predictions)
display_results(y_test, predictions, class_names)


# ------- FOR RUNNING INTERFERENCE WITH SEEN DATA -------------
# TODO: comment/uncomment before running script to run interference with seen data vs actual test set data.
# test_loss, test_accuracy = model.evaluate(X_seen_data, y_seen_data, batch_size=batch_size, verbose=0)
# print("Accuracy of the CNN-LSTM model:", test_accuracy)
# predictions = model.predict(X_seen_data)
# display_results(y_seen_data, predictions, class_names)
# -------------------------------------------------------------












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