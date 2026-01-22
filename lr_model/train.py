# ----------------------------------------------------------------------------------------------------------------
# purpose: this script trains the logistic regression model. 
# 
# training data: - feature vectors (10 elements -- each representing the avg power of the frequency band).
#                - labels (signal = 1, no signal = 0).
#
# output: a trained model that can predict whether there is a signal present (1) or no signal present (0) based on an input raw IQ data file.  
# 
# note: there is a way to find the optimal C -- which C offers the smallest difference between training and testing accuracy.
# -----------------------------------------------------------------------------------------------------------------

# import libraries and helper files.
import numpy as np
from sklearn.model_selection import train_test_split # use sklearn to split data into training and testing sets. 
from sklearn.linear_model import LogisticRegression
from load_data import data# script that opened the directory with the data on the csv file.
import joblib # to save weights of trained model to a new file. 


# split data into features and labels
features = data[['band1', 'band2', 'band3', 'band4', 'band5', 'band6', 'band7', 'band8', 'band9', 'band10']] # array 'features' contains data from the columns of the feature variables.
labels = data['label'] # array 'labels' contains the data from the labels column (signal or no signal -- a 1 or 0 value).
print(labels)

# split the data into a training and testing set using the scikit learn train_test_split function.
X_train, X_test, y_train, y_test = train_test_split(features, labels, test_size=.3, train_size=.7, shuffle=True, stratify=labels)


# create the logistic regression model object.
model = LogisticRegression(penalty='l2', class_weight='balanced', tol=0.0001, C=0.50, max_iter=1000) # instantiate a logistic regression model.


# train the logistic regression model on the training data.
model.fit(X_train, y_train)


print("weights: ", model.coef_)


# save the weights of the trained model.
joblib.dump(model, 'model.joblib')







# # prediction model
# class Model:

#     # constructor.
#     # - penalty param: l2 is less prone to overfitting, but l1 is useful for feature selection becuase it can automatically identify redundant features from the model.
#     # - regularization strength param: strong overfitting prevents overfitting and good when data is noisy, but weak regularization allows the model to fit more complex patterns using more features.
#     def __init__(self):
#         self.classify = LogisticRegression(penalty='l1', class_weights='balanced', tol=0.0001, C=0.50, max_iter=2000) # instantiate a logistic regression model.

    
#     # train the prediction model on the training data.
#     def train(self, X_train, y_train):
#         self.classify.fit(X_train, y_train) # use the fit() function to train the mdoel on the training data.
#         return self.classify.score(X_train, y_train) # use the score() function to output the accuracy score of the model on the training data. 
    

#     # have the (trained) model generate predictions on the testing data. 
#     def predict(self, X_test):
#         y_pred = self.classify.predict(X_test) 
#         return y_pred # return the predictions the model predicted with the validation set. 


# lr_model = Model()


# # train the model with the training data
# training_predictions = lr_model.train(X_train, y_train)


# # use the (trained) model to generate predictions on the testing data.
# testing_predictions = lr_model.predict(X_test)
