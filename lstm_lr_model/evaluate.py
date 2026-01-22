# --------------------------------------------------------------------------------
# purpose: - this script evaluates the trained model on unseen testing data. 
#          - compute the accuracy, F1 score, and confusion matrix
# --------------------------------------------------------------------------------

# import libraries
import torch 
import pickle
# import torch.nn as nn
from sklearn.metrics import accuracy_score, classification_report, f1_score, confusion_matrix # for generating metrics about accuracy and precision of the model.
from train import Classifier


# load the testing sets from the train-test-split that was performed in train.py.
with open("test_set.pkl", "rb") as f:
    X_test, y_test = pickle.load(f)


# convert X_test and y_test into tensors
X_test_tensor = torch.tensor(X_test, dtype=torch.float32)
y_test_tensor = torch.tensor(y_test, dtype=torch.float32)


print("Test labels distribution:", torch.bincount(y_test_tensor.long()))


def evaluate_model():
    # define training and model parameters
    input_size = 14
    hidden_size = 64
    num_layers = 1 # number of LSTM layers. change to 2 if we are dealing with longer term dependencies.
    output_size = 1


    # instantiate a model object.
    model = Classifier(input_size, hidden_size, num_layers, output_size)



    # load the best model weights from the .pth file (these were saved from after training).
    path = "model.pth"
    model.load_state_dict(torch.load(path))


    # set model to evaluation mode.
    model.eval()


    # generate predictions.
    with torch.no_grad():
        prediction = model(X_test_tensor) # generate predictions on test data.
        # prediction = torch.sigmoid(prediction).squeeze()
        prediction = (prediction >= 0.5).int() 



    # accuracy = (prediction.argmax(dim=1).round() == y_test_tensor).float().mean().item()
    accuracy = accuracy_score(y_test_tensor, prediction)
    f1 = f1_score(y_test_tensor, prediction)
    conf_matrix = confusion_matrix(y_test_tensor, prediction)


    # display metrics
    print("Accuracy: ", accuracy)
    print("F1 score: ", f1)
    print("Confusion Matrix: \n", conf_matrix)


if __name__ == "__main__":
    evaluate_model()