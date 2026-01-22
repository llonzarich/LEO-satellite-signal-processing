% -------------------------------------------------------------------------------------------------------------------------------------
% purpose: - this script prepares training data for the logistic regression model. 
%          - arrange training data into csv file with columns being 'band1', 'band2', ..., 'band10', 'label' (signal or no signal -- a 0 or 1 value).
% 
% note: - prior to this, I generated spectrogram images to see time intervals of "signal" and "no signal" chunks. These time intervals were placed into an csv spreadsheet.
% -------------------------------------------------------------------------------------------------------------------------------------


% define the path to the file with spectrogram signal time interval info.
time_interval_path = "spectrogram_time_intervals.csv";


% open the csv file with time interval info as a table data structure.
data = readtable(time_interval_path);


% unpack columns into vectors.
filename = data.filename; % all the entries under the 'filename' column.
start_signal = data.start_signal; % all the entries under the 'start_signal' column.
end_signal = data.end_signal; % all the entries under the 'end_signal' column.
start_no_signal = data.start_no_signal; % all the entries under the 'start_no_signal' column.
end_no_signal = data.end_no_signal; % all the entries under the 'end_no_signal' column.


num_rows = height(data); % get the number of rows in the csv file (aka, the number of raw IQ files).


% define path to the input data (raw IQ files).
iq_file_path = "lr_data/iq_files";


fs = 2e6; % sampling rate.


% define frequency bands: each row is [low_frequency high_frequency]
bands = [ 
    -10e6 -8e6; % band1.
    -8e6 -6e6;  % band2.
    -6e6 -4e6;  % band3.
    -4e6 -2e6;  % band4. 
    -2e6 0e6;   % band5.
    0e6 2e6;    % band6.
    2e6 4e6;    % band7.
    4e6 6e6;    % band8.
    6e6 8e6;    % band9.
    8e6 10e6    % band10.
];


% create output file with header labels.
output_filename = 'training_data.csv';
header = ["filename" "band1", "band2", "band3", "band4", "band5", "band6", "band7", "band8", "band9", "band10", "label"];
writematrix(header, output_filename)


% iterate through each row (file) in the csv file.
for i = 1:num_rows
   
    % calculate sample indices.
    start_signal_sample = round(start_signal(i) * fs);
    end_signal_sample = round(end_signal(i) * fs); 
    num_signal_samples = end_signal_sample - start_signal_sample; 

    start_no_signal_sample = round(start_no_signal(i) * fs);
    end_no_signal_sample = round(end_no_signal(i) * fs);
    num_no_signal_samples = end_no_signal_sample - start_no_signal_sample; 
    % signal_present_idx = round(start_signal(i)*fs):round(end_signal(i)*fs); % old
    % no_signal_idx = round(start_no_signal(i)*fs):round(end_no_signal(i)*fs); % old
    

    % calculate byte offsets of starting index of sample chunks.
    byte_offset_signal = start_signal_sample * 8;
    byte_offset_no_signal = start_no_signal_sample * 8; 


    % load the full raw IQ file.
    iq_signal_file = fullfile(iq_file_path, [filename{i}, '.raw']); % ==> iq_signal_file = 'lr-data/iq-files/iq_signal001.raw'.     

 
    % read chunks of the full IQ data file (chunks are dependent upon pre-defined indices)
    signal_present_chunk = read_complex_binary(iq_signal_file, byte_offset_signal, num_signal_samples); 
    no_signal_chunk = read_complex_binary(iq_signal_file, byte_offset_no_signal, num_no_signal_samples); 


    N1 = length(signal_present_chunk);
    N2 = length(no_signal_chunk);
    f1 = linspace(0, fs, N1);
    f2 = linspace(0, fs, N2);
    

    % take fft of each chunk (time domain --> freq domain).
    fft_signal_present_chunk = abs(fft(signal_present_chunk)) .^ 2;
    fft_no_signal_chunk = abs(fft(no_signal_chunk)) .^ 2;

     
    % intialize 10x1 column vectors to store avg band powers.
    bp_signal_present = zeros(size(bands, 1), 1); % ==> bp_signal_present = (10,1).
    bp_no_signal = zeros(size(bands, 1), 1); % ==> bp_no_signal = (10,1).
    

    % compute avg power of each frequency band.
    % output: a filled 10x1 column vector (the avg power of each of the 10 freq bands.
    for band = 1:size(bands, 1)
        
        % get indices corresponding to the current band
        idx1 = f1 >= bands(band,1) & f1 < bands(band,2);
        idx2 = f2 >= bands(band,1) & f2 < bands(band,2);

        % average the power of the band
        avg_bp1 = mean(fft_signal_present_chunk(idx1));
        avg_bp2 = mean(fft_no_signal_chunk(idx2));

        bp_signal_present(band) = avg_bp1;
        bp_no_signal(band) = avg_bp2; 
    end


    % write to csv file.
    signal_row = [filename(i), bp_signal_present, 1];
    no_signal_row = [filename(i), bp_no_signal, 0];

    writecell(signal_row, output_filename, 'WriteMode', 'append');
    writecell(no_signal_row, output_filename, 'WriteMode', 'append');
   
end

