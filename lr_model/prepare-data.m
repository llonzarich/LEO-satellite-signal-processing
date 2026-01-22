% -------------------------------------------------------------------------------------------------------------------------------------
% purpose: - this script prepares training data for the logistic regression model. 
%          - arrange training data into csv file with columns being 'band1', 'band2', ..., 'band10', 'label' (signal or no signal -- a 0 or 1 value).
% -------------------------------------------------------------------------------------------------------------------------------------



% define path to the input data (raw IQ files).
iq_file_path = "lr-data/iq-files";


% open the iq file directory.
iq_signals = open(iq_file_path);


for signal in iq_signals: # iterate through each file in the directory.

    % convert time ranges to sample indices
    signal_present = signal[0:30000000] % indices that correspond to the part of signal that has our signal (based off spectrogram).
    no_signal = signal[30000000:70000000] % indices that correspond to the part of signal that has no signal (based off spectrogram). 


    % compute FFT of 'signal_present' bit AND 'no_signal' bit
    ff


% place features and lables into an an array
data = [features, labels]; % features is Nx10 and labels is Nx10.
header = ["band1", "band2", "band3", "band4", "band5", "band6", "band7", "band8", "band9", "band10", "label"];
filename = 'training_data.csv';
writecell([header; num2cell(data)], filename) % writes features and labels to a CSV file, training_data.csv, with a header row.
