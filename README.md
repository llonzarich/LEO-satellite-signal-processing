## Pattern Detection Using ML Models


## Description: 
- This repository includes scripts for implementing various ML pipelines to detect signal patterns in low-SNR satellite signals.
- Each ML pipeline includes a MATLAB-based signal processing component and Python-based model training and evaluation component.
- Note: Each folder containing a different ML pipeline has a separate system overview and usage instruction section below.


## MATLAB Setup:
- MATLAB (Version R2024a or later) (this is just what I used)
- MATLAB Signal Processing Toolbox (Version 24.1 or later) 
- Use the following command in your MATLAB terminal to verify installation of required products: 
`[~, products] matlab.codetools.requiredFilesAndProducts(‘preparing_data.m’)`


## Python Setup:
Inside your project folder...
- Create and activate a virtual environment (optional, but recommended)
- Install all necessary Python dependencies using the following command in your terminal: `pip install -r requirements.txt`


## System Overview and Usage Instructions:
### LSTM - LR Model:
(1) Data Preparation (MATLAB)
- `preparing_data.m`
    - Purpose: MAIN workspace
    - Logic:
        - Calls: `auto_signal_annotating.m `OR `new_auto_annotating.m` 
        - Outputs: chunk annotations for per file
        - Appends the chunk annotations for each file to a .csv file
        - Saves .csv file with chunk annotations for all files
        - Calls: `signal_chunking.m`
        - Outputs: feature extraction per chunk per each file (size num_chunks x 14 features)
        - For each file, append each chunk's start_sec and end_sec to an array to store chunk start/end times and append each chunk's label to an array to store chunk-level labels (these arrays are used as input into `detect_pattern.m`)
        - Calls: `detect_pattern.m`
        - Outputs: a file-level label (0 = no-pattern, 1 = pattern)
    - Outputs: a .mat file with...
        - Features: [num_files x 12 time steps x 14 features per time step] tensor
        - Labels: [num_files x 1] vector
- `auto_signal_annotating.m` OR `new_auto_annotating.m`
    - Purposes:
        - Automatically divides a signal into annotated chunks
        - Determines chunk-level labels (0 = “no-pattern” or 1 = “pattern”)
        - Records the start/end times of each chunk 
        - [optional]: Plots the moving average power on accurately scaled axes to visualize the smoothed signal over time
    - Notes on script differences:
        - `auto_signal_annotating.m`: divides the signal into 12 5ish second chunks with “pattern” chunks corresponding to the 5ish second on transmission, and “no-pattern” chunks corresponding to the no-pattern gaps -- the parts of the signal that remain after “pattern” chunks have been determined -- divided evenly to reach 12 chunks. 
        - `new_auto_annotating.m`: divides the signal into 51 10ish second chunks with “pattern” chunks corresponding to the ENTIRE characteristic spike and “no-pattern” chunks corresponding to all windows that we create with the sliding window that don’t perfectly contain the characteristic spike.
    - Calling script: `preparing_data.m`
    - Input: 1 raw complex-valued IQ signal file
    - Outputs:
        - Times array (size num_chunks x 2): the start/end times of each chunk
        - Labels vector (size num_chunks x 1): the chunk labels (0 = “no-pattern” and 1 = “pattern”)
    - Logic
        - Calls `findpeaks()` to locate all peaks in the signal
        - Calls `findchangepts()` to locate all instantaneous bursts in signal power in the signal 
        - Observes the locations of these points in relation to each other to determine characteristic pattern bursts (5ish second on transmission) or spikes (10ish second on-off transmission) in the signal
- `signal_chunking.m`
    - Purpose: feature extraction for 1 chunk
    - Calling script: `preparing_data.m`
    - Inputs:
        - 1 complex-valued IQ signal file
        - Sampling frequency (F_s)
        - 1 chunk’s bounds (start_sec, end_sec)
        - Frequency bands 
    - Outputs: features of 1 chunk...
        - 10x1 bandpower feature vector
        - 4x1 NEO feature vector
    - Logic: 
        - Uses the start_sec, end_sec and sampling frequency to create chunk bound indices
        - Calls: `read_complex_binary.m` to read (a chunk of the) complex valued IQ signal file 
        - Extracts features from that chunk
- `read_complex_binary.m`
    - Purpose: read the complex-valued IQ signal file 
    - Calling script: `signal_chunking.m`
    - Inputs:
        - 1 complex-valued IQ signal file
        - Byte offset
        - The number of samples to read from the signal file
    - Outputs: The real and imaginary components of (a chunk of the) IQ signal 
- `detect_pattern.m`
    - Purpose: determines whether a signal file contains our pattern based on a user-defined spike threshold
    - Calling script: `preparing_data.m`
    - Inputs:
        - Chunk-level times array: the start/end times of each chunk in 1 file
        - Chunk-level labels vector: the labels of each chunk in 1 file
    - Output: Boolean file-level label: 0 = “no-pattern” or 1 = “pattern” 

(2) Model Training and Evaluation (Python)
- `load_data.py`
    - Purpose: loads the .mat file from MATLAB
    - Returns: the .mat file... 
        - Features cell array (size num_files x num_time_steps x num_features)
        - Labels vector (size num_files x 1) 
- `train.py`
    - Purposes:
        - Trains the LSTM-LR model
        - Displays the training vs validation loss and accuracy plots
    - Inputs: the .mat file with features and labels 
    - Outputs:
        - The trained model
        - The test set (X_test, y_test)
- `evaluate.py`
    - Purpose:
        - Evaluates model on unseen test data
        - Computes accuracy, F1-score, and confusion matrix




### CNN - LSTM - LR Model:
(1) Data Preparation (MATLAB)
- `preparing_cnn_matrix_1D.m`
    - Purpose: MAIN workspace
    - Logic:
        - For each IQ signal file in the directory…
        - Calls: `isolate_pattern.m`
        - Outputs: a boolean variable, `has_pattern`, to specify whether a signal file has our pattern or not (0 = no-pattern detected, 1 = pattern detected)
        - Calls: `window_signal.m`
        - Outputs:
            - `signal_windows`: the 11 windows of the equal size
            - `num_windows`: the number of windows the signal was divided into
            - `window_samples`: the number of samples in each window
            - `iq_components:` the a matrix of the I and Q components for each window
        - Arrange the window and associated I and Q components for each window in the output 4D tensor 
        - Outputs: a .mat file with…
            - `cnn_input`: A 4D tensor with shape [num_files, num_windows, num_samples_per_window, num_channels]
            - `labels_vector`: A vector with shape [num_files, 1] to store file-level labels
- `isolate_pattern.m`
    - Purposes:
        - Automates the process of isolating the section of a signal file which contains all pattern chunks and annotating its start/end times
        - Determines a signal file-level label 
    - USER NOTE: the most up-to-date model no longer only considers the isolated pattern chunks, so the only output I care about from this function is the ‘has_pattern’ boolean variable
    - Calling script: `preparing_cnn_matrix_1D.m`
    - Input: 1 complex-valued IQ signal file
    - Outputs:
        - Boolean file-level label (0 = “no-pattern” and 1 = “pattern”)
        - Moving average power vector
        - Start time of the first pattern chunk (start time of the main pattern chunk)
        - End time of the last pattern chunk (end time of the main pattern chunk)
    - Logic
        - Calls `findpeaks()` to locate all peaks in the signal
        - Calls `findchangepts()` to locate all instantaneous bursts in signal power in the signal 
        - Observes the locations of these points in relation to each other to determine characteristic spikes (10ish second on-off transmission) in the signal
        - Labels each characteristic spike as a “pattern” chunk and records its start/end times
        - Isolates the section of the signal file containing all pattern chunks by “grabbing” the start time of the first pattern chunk and the end time of the last pattern chunk
- `window_signal.m`
    - Purpose: split the IQ signal file into windows of equal length.
    - Calling script: preparing_cnn_matrix_1D.m
    - Input: 1 raw IQ signal file
    - Outputs: 
        - `signal_windows`: the 11 windows of the equal size
        - `num_windows`: the number of windows the signal was divided into
        - `window_samples`: the number of samples in each window
        - `iq_components`: the a matrix of the I and Q components for each window

(2) Model Training and Evaluation (Python)
- `load_data.py`
    - Purpose: loads the .mat file from MATLAB
    - Returns: the .mat file... 
        - Features=X=`cnn_input` 4D tensor
        - Labels=y=`labels_vector` (size num_files x 1) 
- `train.py`
    - Purposes:
        - Trains the CNN-LSTM-LR model
        - Displays the training vs validation loss and accuracy plots
    - Inputs: the .mat file with features=`cnn_input` 4D tensor and labels=`labels_vector`
    - Outputs:
        - The trained model
        - The test set (X_test, y_test)
- `evaluate.py`
    - Purpose:
        - Evaluates model on unseen test data
        - Computes accuracy, confusion matrix, and other metrics
- User Notes:
    - To load multiple datasets to train different models in different train.py scripts:
        - define a new variable in `load_data.py` to hold the loaded data from each dataset i.e. 'data1 = loadmat(cnn_data_path1)', 'data2 = loadmat(cnn_data_path2)', etc.
        - import the loaded data into each `train.py` script using 'from load_data.py import data1' in training script 1, 'from load_data.py import data2' in training script 2, etc.


