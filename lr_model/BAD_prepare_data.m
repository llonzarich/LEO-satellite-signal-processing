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
% bands = [ 
%     -10e6 -8e6; % band1.
%     -8e6 -6e6;  % band2.
%     -6e6 -4e6;  % band3.
%     -4e6 -2e6;  % band4. 
%     -2e6 0e6;   % band5.
%     0e6 2e6;    % band6.
%     2e6 4e6;    % band7.
%     4e6 6e6;    % band8.
%     6e6 8e6;    % band9.
%     8e6 10e6    % band10.
% ];
bands = [
    0     1e6;
    1e6 2e6;
    2e6 3e6;
    3e6 4e6;
    4e6 5e6;
    5e6 6e6;
    6e6 7e6;
    7e6 8e6;
    8e6 9e6;
    9e6 10e6
];

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


    % load and read the full raw IQ file. % old
    % load the full raw IQ file.
    iq_signal_file = fullfile(iq_file_path, [filename{i}, '.raw']); % ==> iq_signal_file = 'lr-data/iq-files/iq_signal001.raw'.     
    % iq_signal = read_complex_binary(iq_signal_file); % old

 
    % read chunks of the full IQ data file (chunks are dependent upon pre-defined indices)
    signal_present_chunk = read_complex_binary(iq_signal_file, byte_offset_signal, num_signal_samples); 
    no_signal_chunk = read_complex_binary(iq_signal_file, byte_offset_no_signal, num_no_signal_samples); 

    % chunk the IQ data into "signal" chunk and "no signal" chunk % old
    % signal_present_chunk = read_complex_binary(iq_signal_file,start_signal(i)*8*fs, end_signal(i)*fs); % mid
    % no_signal_chunk = read_complex_binary(iq_signal_file, start_no_signal(i)*8*fs, end_no_signal(i)*fs); % mi
    % signal_present_chunk = iq_signal(signal_present_idx); % old
    % no_signal_chunk = iq_signal(no_signal_idx); % old
    % disp("signal present chunk of iq data file: " + signal_present_chunk) % old
    % disp("no signal chunk of iq data file: " + no_signal_chunk) % old

   
    % compute PSD (necessary to extract bandpowers with bandpower() fxn).
    % format: [vector_of_PSD, corresponding_freq_vals] = pwelch(signal_segment, window, overlap_between_segments, FFT_length, sampling_frequency).
    [Pxx_signal_present_chunk, f1] = pwelch(signal_present_chunk, [], [], [], fs, 'twosided');
    [Pxx_no_signal_chunk, f2] = pwelch(no_signal_chunk, [], [], [], fs, 'twosided');


    disp("last value in f1: " + f1(end))
    disp("first value in f2: " + f2(end))
    
    % intialize 10x1 column vectors to store avg band powers.
    bp_signal_present = zeros(size(bands, 1), 1); % ==> bp_signal_present = (10,1).
    bp_no_signal = zeros(size(bands, 1), 1); % ==> bp_no_signal = (10,1).
    

    % compute avg power of each frequency band.
    % output: a filled 10x1 column vector (the avg power of each of the 10 freq bands.
    for band = 1:size(bands, 1)

        % compute the avg bandpowers at the current band.
        % format: bandpower(time_domain_signal, scalar_sampling_frequency, freq_range)
        % format: bandpower(psd, freq_vector_corresp_to_psd, freq_range/band_of_interest).
        avg_bp1 = bandpower(Pxx_signal_present_chunk, f1, 'psd', bands(band, :));
        avg_bp2 = bandpower(Pxx_no_signal_chunk, f2, 'psd', bands(band, :));

        % append the avg band powers to the column vectors.
        bp_signal_present(band) = avg_bp1;
        bp_no_signal(band) = avg_bp2; 
        % band_powers_signal_present.append(avg_bp1); 
        % band_powers_no_signal.append(avg_bp2);

    end


    % header = ["band1", "band2", "band3", "band4", "band5", "band6", "band7", "band8", "band9", "band10", "label"];
    % data1 = [bp_signal_present, 1];
    % data2 = [bp_no_signal, 0];
    % data = [data1; data2];
    % filename = 'training_data.csv';
    % writematrix(header, filename);
    % writematrix(data, filename, 'WriteMode', 'append');



    % 
    % disp("filename of each iteration: " + filename(i))
    % 
    % % place features and lables into an an array
    % % data1 = [bp_signal_present, 1];
    % % data2 = bp_no_signal 
    % header = ["band1", "band2", "band3", "band4", "band5", "band6", "band7", "band8", "band9", "band10", "label"];
    % % writecell(header, filename); 
    % disp(header)
    % writematrix(header)
    % disp("hello")
    % 
    % 
    % 
    % filename = 'training_data.csv'; 
    % writematrix(filename(i), [num2cell(bp_signal_present)], 1) % writes features and labels of signal chunk to a CSV file, training_data.csv.
    % writematrix(filename(i), [num2cell(bp_no_signal)], 0) % writes features and labels of no signal chunk to a CSV file, training_data.csv.
    % % % place features and lables into an an array
    % % % data = [features, labels]; % features is Nx10 and labels is Nx1.
    % % % header = ["band1", "band2", "band3", "band4", "band5", "band6", "band7", "band8", "band9", "band10", "label"];
    % % % filename = 'training_data.csv';
    % % % write
end





    % 
    % % return the I and Q elements of the .raw file as a column vector.
    % y = read_complex_binary(signal_present); % read the raw IQ data for the chunk of the .raw file corresponding to "signal". 
    % z = read_complex_binary(no_signal); % read the raw IQ data for the chunk of the .raw file corresponding to "no signal".
    % % F_s = 2.4e6; % narrowband signal sampling frequency
    % % starting_second = 0; % start reading from second 0.
    % % duration_seconds = 60; % stop reading at second 60. (reading 60 seconds worth of data)
    % % n_bytes_per_sample = 8;
    % % % y = read_complex_binary(filename, starting_second*n_bytes_per_sample*F_s, F_s);  % reading 1 second. assign the read .raw files (I and Q components) into variable y.
    % % y = read_complex_binary(filename, starting_second*n_bytes_per_sample*F_s, duration_seconds*F_s);  % reading 60 seconds. assign the read .raw files (I and Q components) into variable y.
    % % disp('Done reading .raw file')


    % compute FFT of the chunks of the .raw file that correspond to "signal" and "no signal".
    % Converting signal from time domain --> frequency domain.
%     Y = fft(y); % signal chunk.
%     Z = fft(z); % no signal chunk.
% 
% 
% 
%     % find the avg power of each frequency band 
%     % p = bandpower
% % 
% end
% 
% 
% 
% 
% % find the avg power of each frequency band 
% 
% 
% % place features and lables into an an array
% data = [features, labels]; % features is Nx10 and labels is Nx10.
% header = ["band1", "band2", "band3", "band4", "band5", "band6", "band7", "band8", "band9", "band10", "label"];
% filename = 'training_data.csv';
% writecell([header; num2cell(data)], filename) % writes features and labels to a CSV file, training_data.csv, with a header row.
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% with data as file:
%     reader = csv.DictReader(file);
%     for row in reader
% 
% num_files = length(data);
% 
% 
% for ii=1:num_files
%     disp(data(i).name) % display the filename.
%     name = data(i).name;
%     filename = fullfile(time_interval_path, data(i).name);
%     file(i) = readmatrix(filename); 
% end
% 
% 
% 
% 
% % unpack the csv file
% row = row.split(",");
% (start_signal, end_signal, start_no_signal, end_no_signal) = row;
% 
% 
% % create lists to hold data for time intervals.
% start_signal = [];
% end_signal = [];
% start_no_signal = [];
% end_no_signal = []; 
% 
% 
% % iterate through the csv file to populate each list.
% for time_interval_csv[i:]
%     temp1 = start_signal(i);
%     temp2 = end_signal(i);
%     temp3 = start_no_signal(i);
%     temp4 = end_no_signal(i);
% 
%     start_signal.append(temp1);
%     end_signal.append(temp2);
%     start_no_signal.append(temp3);
%     end_no_signal.append(temp4);
% end
% 
% 
% % % define path to the input data (raw IQ files).
% % iq_file_path = "lr-data/iq-files";
% % 
% % 
% % % open the iq file directory.
% % iq_signals = open(iq_file_path);
% % 
% % 
% % for signal in iq_signals: % iterate through each file in the directory.
% % 
% %     % convert time ranges to sample indices
% %     signal_present = signal[start_signal(i):end_signal(i)];
% %     no_signal = signal[start_no_signal(i):end_no_signal(i)];
% %     % signal_present = signal[0:30000000] % indices that correspond to the part of signal that has our signal (based off spectrogram).
% %     % no_signal = signal[30000000:70000000] % indices that correspond to the part of signal that has no signal (based off spectrogram). 
% % 
% % 
% %     % compute FFT of 'signal_present' bit AND 'no_signal' bit
% %     ff
% % end