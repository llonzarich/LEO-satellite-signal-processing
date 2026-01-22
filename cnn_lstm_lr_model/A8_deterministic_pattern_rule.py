# ------------------------------------------------------------------------------
# purpose: determine file-level labels (0 = no-pattern, 1 = pattern).
# 
# logic: - 1 "run" = 9 consecutive windows labeled 1.
#        - so if we see at least 8 consecutive windows labeled 1 == 1 "run".
#        - so if we see at least 2 consecutive "runs" == pattern
#
# inputs: outputs of model from evaluate.py (35 binary (0 or 1) window-level labels per file).
#
# output: dictionary mapping: {filename: file-level label / pattern detection (0 = no-pattern, 1 = pattern)}.
# ------------------------------------------------------------------------------

import numpy as np
import pandas as pd
from A8_evaluate import predictions, num_files_test, num_windows, testing_files

# convert raw binary probability predictions from label into binary labels.
prediction_labels = (predictions.squeeze(-1) >= 0.5).astype(int)
# btw: prediction_labels is shape (num_files, num_windows)


pattern_detection_list = {}


# default is that a file has no pattern.
pattern_detected = False


# iterate through all test files
for i in range(num_files_test):
    
    ones_count = 0
    run_count = 0

    # iterate thorugh all windows in the i-th file
    for j in range(num_windows):

        if prediction_labels[i, j] == 1:
            
            ones_count += 1

            if ones_count == 8:
                run_count += 1 # run detected. record it.
                ones_count = 0 # reset run counter.
            else:
                one_count = 0 # reset run counter when the sequence of one's is broken.

    # check if file has >= 2 runs
    if run_count >= 2:
        file_level_label = 1
    else:
        file_level_label = 0

    
    # convert filename to string
    filename = str(testing_files[i])


    # assign file-level label
    pattern_detection_list[filename] = file_level_label


# ---------------- PRINT RESULTS -------------------
# for fname, label in file_level_labels.item():
#     print(f"{fname}: {label}")


# ---------------- SAVE RESULTS TO CSV FILE -------------------
output_dir = "10_A8_pattern_detection_list.csv" # TODO: change output dir.

# convert results to dataframe
df_results = pd.DataFrame(list(pattern_detection_list.items()), columns=["filename", "label"])

# save results to csv file
df_results.to_csv(output_dir, index=False)

            



            


