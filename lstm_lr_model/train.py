# ----------------------------------------------------------------------------------------------------------------
# purpose: this script trains the LSTM-logistic regression model. 
# 
# training data: - features: 80 cells (aka files) of 12x10 objects (12 sequences / time steps, 10 features per time step).
#                - labels (signal = 1, no signal = 0).
#
# output: a trained model that can predict whether there is a signal present (1) or no signal present (0) based on an input raw IQ data file.  
# 
# note: - option to add a validation set.
#       - layers: [LSTM_layer; ... (learns temporal patterns from sequences).
#                  linear_layer; ...(maps LSTM output to a single logit -- weight shape: (1, hidden_size), bias shape: (1,))
#                  sigmoid_activation_layer (converts output of linear layer to a probability in [0, 1])
#                  ]
# -----------------------------------------------------------------------------------------------------------------

# import libraries and helper files.
import random
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader, TensorDataset
import numpy as np
from sklearn.model_selection import train_test_split # use sklearn to split data into training and testing sets. 
from sklearn.metrics import accuracy_score
from load_data import data # script that opened the directory with the data on the csv file.
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
import joblib
import pickle

# data was loaded in load_data.py


# set random seed for ensuring fair comparison of model's as I tune parameters.
np.random.seed(42)


# define LSTM-Logistic Regression classifier model
class Classifier(nn.Module):

    def __init__(self, input_size, hidden_size, num_layers, output_size, dropout_prob=0.2):
    # def __init__(self, input_size, hidden_size, num_layers, output_size):
        super(Classifier, self).__init__()
        
        self.hidden_size = hidden_size
        self.num_layers = num_layers

        self.lstm = nn.LSTM(input_size, hidden_size, num_layers, batch_first=True)
        # self.lstm = nn.LSTM(input_size, hidden_size, num_layers, batch_first=True, dropout=dropout_prob if num_layers>1 else 0.0) # LSTM. 
        self.dropout = nn.Dropout(p=dropout_prob) # added for dropout.
        self.fc = nn.Linear(hidden_size, output_size)
        self.sigmoid = nn.Sigmoid()

    def forward(self, x):
        # x is the sequence, and it looks like: (batch, sequence_length=12, input_size=10)
        # note: x.size(0) == batch size, x.size(1) == sequence length, x.size(2) == input size
        if x.dim() == 2:
            x = x.unsqueeze(0)
        
        h0 = torch.zeros(self.num_layers, x.size(0), self.hidden_size).to(x.device) # initialize hidden state.
        c0 = torch.zeros(self.num_layers, x.size(0), self.hidden_size).to(x.device) # initalize cell state.
        
        out, _ = self.lstm(x, (h0, c0)) # extract the last output in the sequence.

        # out = self.fc(out[:, -1, :]) # removed for dropout.
        out = out[:, -1, :] # added for dropout.
        out = self.dropout(out) # added for dropout.
        out = self.fc(out) # added for dropout.
        out = self.sigmoid(out)
        return out.squeeze(1)
    



def prepare_data():
    features = data['features'] # an object array (aka list) of num_files matrices, each 12x10 (12 sequences / time steps, 10 features per time step). 
    labels = data['labels'].squeeze() # a 1D array 'labels' contains the data from the 'Labels' column of the .mat file (0 or 1)
    print(labels)

    # (1) convert 'features' object array of matrices into a single 3D array by stacking all num_files-number of matrices together 
    # (2) # convert 'labels' array into float32's. 
    X = np.stack([f for f in features.squeeze()]) # shape: (num_files, 12, 10)
    y = labels.astype(np.float32) # shape: (num_files,)


    # normalize features across samples and time
    X_reshaped = X.reshape(-1, X.shape[2])  # flatten data for the scalar. 
    scaler = StandardScaler()
    X_reshaped = scaler.fit_transform(X_reshaped) # fit the scaler.
    X = X_reshaped.reshape(X.shape) # reshape back to original shape.
    joblib.dump(scaler, 'scaler.pkl') # save mean and std deviation for scaling new data.


    # split the data into a training and testing set using the scikit learn train_test_split function.
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=.3, train_size=.7, shuffle=True, stratify=labels, random_state=42)


    # split training set into training and validation sets.
    X_train, X_val, y_train, y_val = train_test_split(X_train, y_train, test_size=0.1, shuffle=True, stratify=y_train)


    # save X_train and y_train to be used for interference in assess_features.py
    with open("train_set.pkl", "wb") as f:
        pickle.dump((X_train, y_train), f)


     # save the X_test and y_test to be used for interference in evaluate.py.
    with open("test_set.pkl", "wb") as f:
        pickle.dump((X_test, y_test), f)

    
    # convert data to PyTorch tensors
    X_train_tensor = torch.tensor(X_train, dtype=torch.float32) # features for training.
    y_train_tensor = torch.tensor(y_train, dtype=torch.float32) # binary labels for training.
    X_val_tensor = torch.tensor(X_val, dtype=torch.float32)
    y_val_tensor = torch.tensor(y_val, dtype=torch.float32)
    X_test_tensor = torch.tensor(X_test, dtype=torch.float32) # features for testing.
    y_test_tensor = torch.tensor(y_test, dtype=torch.float32) # binary labels for testing.


    return X_train_tensor, y_train_tensor, X_val_tensor, y_val_tensor, X_test_tensor, y_test_tensor




def train_model():
    X_train_tensor, y_train_tensor, X_val_tensor, y_val_tensor, X_test_tensor, y_test_tensor = prepare_data()


    # bundle the X and y training tensors together into a single tensor dataset (so we can create batches).
    training_data = TensorDataset(X_train_tensor, y_train_tensor)
    validation_data = TensorDataset(X_val_tensor, y_val_tensor)


    # load batches of the training data into 'training_loader', so we have something to iterate over for a loop. Also define batch size (the batch size determines how "quickly" we go through an epoch).
    training_loader = DataLoader(training_data, batch_size=16, shuffle=True)
    validation_loader = DataLoader(validation_data, batch_size=16, shuffle=False)


    # define training and model parameters
    input_size = 14
    hidden_size = 64
    num_layers = 1 # number of LSTM layers. change to 2 if we are dealing with longer term dependencies.
    output_size = 1
    num_epochs = 200
    dropout_prob = 0.2
    patience_counter = 0
    patience_limit = 20


    # instantiate the model object.
    model = Classifier(input_size, hidden_size, num_layers, output_size, dropout_prob)
    # model = Classifier(input_size, hidden_size, num_layers, output_size)


    # define loss function and optimizer
    loss_function = nn.BCELoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=0.0001)


    # define variables to hold the best recorded loss and weights.
    best_loss = float('inf')
    best_weights = None
    training_loss_history = []
    val_loss_history = []
    train_acc_history = []
    val_acc_history = []


    # train the model.
    for epoch in range(num_epochs):

        model.train()
        training_loss = 0.0
        
        for X_batch, y_batch in training_loader:
            # print(X_batch.shape) # ==> [16 or 8, 12, 10] = [batch_size(aka, how many sequences we're processing at once), sequence_length(each sample has 12 time steps), feature_size(each time step has 10 features)].
            
            # forward pass.
            predictions = model(X_batch) # generate a prediction with the model using the batch in the current epoch.
            loss = loss_function(predictions, y_batch) # compute loss.
        
            # backward pass.
            optimizer.zero_grad() # zero out the gradients from the previous iteration.
            loss.backward() # compute loss. 
            
            # update weights (this is what "improves" the model)
            optimizer.step() 
            print(f"Epoch {epoch+1}, Loss: {loss.item():.4f}")

            training_loss += loss.item()
        
        training_loss /= len(training_loader)
        training_loss_history.append(training_loss)


        # compute training accuracy.
        model.eval()
        train_predictions = []
        train_labels = []

        with torch.no_grad():
            for X_batch, y_batch in training_loader:
                predictions = model(X_batch)
                predictions = (predictions >= 0.5).int()
                train_predictions.extend(predictions.numpy())
                train_labels.extend(y_batch.int().numpy())
        
        train_acc = accuracy_score(train_labels, train_predictions)
        train_acc_history.append(train_acc)


        # VALIDATION (for monitoring model's performance during training).
        # compute validation loss and accuracy here.
        val_loss = 0.0
        val_predictions = []
        val_labels = []

        with torch.no_grad():
            for X_batch, y_batch in validation_loader:
                predictions = model(X_batch)
                
                loss = loss_function(predictions, y_batch)
                val_loss += loss.item()

                predictions = (predictions >= 0.5).int()

                val_predictions.extend(predictions.numpy())
                val_labels.extend(y_batch.int().numpy())

        
        val_loss /= len(validation_loader)
        val_loss_history.append(val_loss)

        val_acc = accuracy_score(val_labels, val_predictions)
        val_acc_history.append(val_acc)

        print(f"Epoch {epoch+1}, Training Loss: {training_loss:.4f}, Validation Loss: {val_loss:.4f}")
        print(f"Epoch {epoch+1}, Training acc: {train_acc:.4f}, Validation acc: {val_acc:.4f}")

        if val_loss < best_loss:
            best_loss = val_loss
            best_weights = model.state_dict()
            patience_counter = 0
        else:
            patience_counter += 1
            if patience_counter >= patience_limit:
                print("Early stopping to prevent model overfitting")
                break
    

    torch.save(best_weights, "model.pth")


    # plot losses
    plt.plot(training_loss_history, label='Training Loss')
    plt.plot(val_loss_history, label='Validation Loss')
    plt.xlabel('Epoch')
    plt.ylabel('Loss')
    plt.title('Training vs Validation Loss')
    plt.legend()
    plt.grid(True)
    plt.show()


    # plot accuracy
    plt.figure()
    plt.plot(train_acc_history, label='Training Accuracy')
    plt.plot(val_acc_history, label='Validation Accuracy')
    plt.xlabel('Epoch')
    plt.ylabel('Accuracy')
    plt.title('Training vs Validation Accuracy')
    plt.legend()
    plt.grid(True)
    plt.show()


    return Classifier, X_test_tensor, y_test_tensor


if __name__ == "__main__":
    train_model()
