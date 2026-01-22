# --------------------------------------------------------------------------------
# purpose: - this script evaluates the trained model on unseen testing data. 
#          - compute the accuracy and F1 score.
# --------------------------------------------------------------------------------

# import libraries
from sklearn.metrics import accuracy_score, classification_report, f1_score # from geeksforgeeks. This allows us to generate metrics about accuracy and precision of the model.
from sklearn.metrics import confusion_matrix # this allows us to generate a confusion matrix to visualize the model's performance.
import time # to measure the speed at which the prediction model was trained and how fast it predicts.
import joblib
from train import X_test, y_test


# load the trained model
model = joblib.load('model.joblib')


# generate predictions on test data.
y_pred = model.predict(X_test)


# evaluate the model 
accuracy = accuracy_score(y_test, y_pred)
f1 = f1_score(y_test, y_pred)
conf_matrix = confusion_matrix(y_test, y_pred)

print("Accuracy: ", accuracy)
print("F1 score: ", f1)
print("Confusion Matrix: \n", conf_matrix)

# or: metrics = model.classification_report(y_test, prediction)

