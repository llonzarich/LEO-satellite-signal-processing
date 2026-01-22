% -------------------------------------------------------------------------------------------------------------------------------------
% purpose: - this script prepares training data for the logistic regression model using fft. 
%          - arrange training data into csv file with columns being 'band1', 'band2', ..., 'band10', 'label' (signal or no signal -- a 0 or 1 value).
%          - this script accounts for iq files with (1) 0 ‘no_signal’ chunks (2) 1 ’no_signal’ chunk and (3) 2 ‘no_signal’ chunks.
% 
% note: - prior to this, I generated moving avg plots to see time intervals of "signal" and "no signal" chunks. These time intervals were placed into an csv spreadsheet.
%       - iq files have either 0, 1, or 2 no signal chunks.
% -------------------------------------------------------------------------------------------------------------------------------------


% define the path to the file with spectrogram signal time interval info.
time_interval_path = "signal_time_intervals.csv";


% make matlab reads leading 0s in filenames. 
opts = detectImportOptions(time_interval_path);
opts = setvartype(opts, 'filename', 'string');


% open the csv file with time interval info as a table data structure.
data = readtable(time_interval_path, opts);


num_rows = height(data); % get the number of rows in the csv file (aka, the number of raw IQ files).


% compile all of the .raw files from the hard drive into one variable, 'iq_files'.
base_path = "/Volumes/PARTITION3"; % path to the hard drive, 'PARTITION3'.
iq_files = dir(fullfile(base_path, '**', '*.raw')); % parsing each folder in the hard drive to "grab" all of the .raw files.
iq_files = iq_files(~startsWith({iq_files.name}, '._')); % remove the ._ from the path (macOS puts this in for some reason). 
% fprintf("Found %d .raw files .\n", length(iq_files)); % ==> the number of iq files in the hard drive.
% disp(iq_files(1)) % ==> displays the attributes of the .raw file at index 1 (i.e. name, folder, date, bytes)


% preallocate an empty string array to store the cleaned up filenames.
iq_filenames = strings(length(iq_files), 1);


% populate the 'iq_filenames' array with each .raw file's "cleaned-up" name: <6 digit id>.raw.
for i = 1:length(iq_files)
    original_name = iq_files(i).name;
    original_path = fullfile(iq_files(i).folder, original_name);

    % extract 6 digit time tag using regex
    tokens = regexp(original_name, 'gqrx_\d+_(\d{6})', 'tokens');
    if ~isempty(tokens)
        time_tag = tokens{1}{1};
        iq_filenames(i) = time_tag + ".raw";
        % disp(iq_filenames(i)) % ==> every .raw file in the hard drive, but with its named shortened.
    else
        warning('Could not extract time tag from: %s', original_name)
    end
end


fs = 2.4e6; % sampling rate.


% define frequency bands: each row is [low_frequency high_frequency]
bands = [
    -1200e3, -960e3;
    -960e3, -720e3;
    -720e3, -480e3;
    -480e3, -240e3;
    -240e3, 0;
    0, 240e3;
    240e3, 480e3;
    480e3, 720e3;
    720e3, 960e3;
    960e3, 1200e3
];


% create output file with header labels.
output_filename = 'training_data.csv';
header = ["filename" "band1", "band2", "band3", "band4", "band5", "band6", "band7", "band8", "band9", "band10", "label"];
writematrix(header, output_filename)


% to hold all of hte filenames in the 'filename' column of the csv file.
csv_filenames = data.filename;
% disp(csv_filenames(1))


% iterate through each row (file) in the csv file.
% for i = 1:num_rows
for i = 1:6
    
    % case 0: no 'no-signal' chunks.
    if isnan(data.start_no_signal_2(i)) && isnan(data.end_no_signal_2(i)) && isnan(data.start_no_signal_1(i)) && isnan(data.end_no_signal_1(i))
        
        target_filename = data.filename(i); % assign our "target filename" to be the filename of the current row / the i'th row in the csv file.

        % find the index of the corresponding .raw file (aka, the .raw file with the same 6 digit id) from the hard drive.
        matched_idx = find(iq_filenames == target_filename); 
        
        % create (and assign) the path to the .raw file that corresponds to the target filename from the csv file.
        iq_signal_file = fullfile(iq_files(matched_idx).folder, iq_files(matched_idx).name); 
        
        % calculate sample indices of the .raw file
        start_signal_sample = floor(data.start_signal(i) * fs);
        end_signal_sample = ceil(data.end_signal(i) * fs); 
        num_signal_samples = end_signal_sample - start_signal_sample;

        % calculate byte offsets of starting index of sample chunks.
        byte_offset_signal = start_signal_sample * 8;

        % read chunks of the full IQ data file (chunks are dependent upon pre-defined indices)
        signal_present_chunk = read_complex_binary(iq_signal_file, byte_offset_signal, num_signal_samples); 

        N1 = length(signal_present_chunk);
        f1 = linspace(0, fs, N1);

        % take fft of each chunk (time domain --> freq domain).
        fft_signal_present_chunk = abs(fft(signal_present_chunk)) .^ 2;

        % intialize 10x1 column vectors to store avg band powers.
        bp_signal_present = zeros(size(bands, 1), 1); % ==> bp_signal_present = (10,1).

        % compute avg power of each frequency band.
        % output: a filled 10x1 column vector (the avg power of each of the 10 freq bands.
        for band = 1:size(bands, 1)

            % get indices corresponding to the current band
            idx1 = f1 >= bands(band,1) & f1 < bands(band,2);

            % average the power of the band
            avg_bp1 = mean(fft_signal_present_chunk(idx1));

            bp_signal_present(band) = avg_bp1;
        end

        % write to csv file.
        signal_row = [{target_filename}, num2cell(bp_signal_present'), {1}];
        writecell(signal_row, output_filename, 'WriteMode', 'append');


    % case 1: 1 'no-signal' chunk.
    elseif isnan(data.start_no_signal_2(i)) && isnan(data.end_no_signal_2(i))
        
        target_filename = data.filename(i); % assign our "target filename" to be the filename of the current row / the i'th row in the csv file.
        % disp("target_filename: ") 
        % disp(target_filename) % ==> <6 digit filename id>.raw 

        % find the index of the corresponding .raw file (aka, the .raw file with the same 6 digit id) from the hard drive.
        matched_idx = find(iq_filenames == target_filename); 
        
        % create (and assign) the path to the .raw file that corresponds to the target filename from the csv file.
        iq_signal_file = fullfile(iq_files(matched_idx).folder, iq_files(matched_idx).name); 
        % disp("chosen iq .raw file: ")
        % disp(iq_signal_file) % ==> the path to the .raw file for this iteration.

        % calculate sample indices of the .raw file
        start_signal_sample = floor(data.start_signal(i) * fs);
        end_signal_sample = ceil(data.end_signal(i) * fs); 
        num_signal_samples = end_signal_sample - start_signal_sample;
        
        start_no_signal_sample = floor(data.start_no_signal_1(i) * fs);
        end_no_signal_sample = ceil(data.end_no_signal_1(i) * fs);
        num_no_signal_samples = end_no_signal_sample - start_no_signal_sample; 
        % disp(num_no_signal_samples);

        % calculate byte offsets of starting index of sample chunks.
        byte_offset_signal = start_signal_sample * 8;
        byte_offset_no_signal = start_no_signal_sample * 8; 


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
        signal_row = [{target_filename}, num2cell(bp_signal_present'), {1}];
        no_signal_row = [{target_filename}, num2cell(bp_no_signal'), {0}];

        writecell(signal_row, output_filename, 'WriteMode', 'append');
        writecell(no_signal_row, output_filename, 'WriteMode', 'append');


    % case 2: 2 'no-signal' chunks.
    else
        target_filename = data.filename(i); % assign our "target filename" to be the filename of the current row / the i'th row in the csv file.

        % find the index of the corresponding .raw file (aka, the .raw file with the same 6 digit id) from the hard drive.
        matched_idx = find(iq_filenames == target_filename); 
        
        % create (and assign) the path to the .raw file that corresponds to the target filename from the csv file.
        iq_signal_file = fullfile(iq_files(matched_idx).folder, iq_files(matched_idx).name); 
        
        % calculate sample indices of the .raw file
        start_signal_sample = floor(data.start_signal(i) * fs);
        end_signal_sample = ceil(data.end_signal(i) * fs); 
        num_signal_samples = end_signal_sample - start_signal_sample;
        
        start_no_signal_sample_1 = floor(data.start_no_signal_1(i) * fs);
        end_no_signal_sample_1 = ceil(data.end_no_signal_1(i) * fs);
        num_no_signal_samples_1 = end_no_signal_sample_1 - start_no_signal_sample_1; 
        disp(num_no_signal_samples_1)

        start_no_signal_sample_2 = floor(data.start_no_signal_2(i) * fs);
        end_no_signal_sample_2 = ceil(data.end_no_signal_2(i) * fs); 
        num_no_signal_samples_2 = end_no_signal_sample_2 - start_no_signal_sample_2;
        disp(num_no_signal_samples_2)

        % calculate byte offsets of starting index of sample chunks.
        byte_offset_signal = start_signal_sample * 8;
        byte_offset_no_signal_1 = start_no_signal_sample_1 * 8; 
        byte_offset_no_signal_2 = start_no_signal_sample_2 * 8;
        
        % read chunks of the full IQ data file (chunks are dependent upon pre-defined indices)
        signal_present_chunk = read_complex_binary(iq_signal_file, byte_offset_signal, num_signal_samples); 
        no_signal_chunk_1 = read_complex_binary(iq_signal_file, byte_offset_no_signal_1, num_no_signal_samples_1);
        no_signal_chunk_2 = read_complex_binary(iq_signal_file, byte_offset_no_signal_2, num_no_signal_samples_2);

        N1 = length(signal_present_chunk);
        N2 = length(no_signal_chunk_1);
        N3 = length(no_signal_chunk_2);
        f1 = linspace(0, fs, N1);
        f2 = linspace(0, fs, N2);
        f3 = linspace(0, fs, N3);
        
        % take fft of each chunk (time domain --> freq domain).
        fft_signal_present_chunk = abs(fft(signal_present_chunk)) .^ 2;
        fft_no_signal_chunk_1 = abs(fft(no_signal_chunk_1)) .^ 2;
        fft_no_signal_chunk_2 = abs(fft(no_signal_chunk_2)) .^ 2;

        % intialize 10x1 column vectors to store avg band powers.
        bp_signal_present = zeros(size(bands, 1), 1); % ==> bp_signal_present = (10,1).
        bp_no_signal_1 = zeros(size(bands, 1), 1); % ==> bp_no_signal = (10,1).
        bp_no_signal_2 = zeros(size(bands, 1), 1); 

        % compute avg power of each frequency band.
        % output: a filled 10x1 column vector (the avg power of each of the 10 freq bands.
        for band = 1:size(bands, 1)

            % get indices corresponding to the current band
            idx1 = f1 >= bands(band,1) & f1 < bands(band,2);
            idx2 = f2 >= bands(band,1) & f2 < bands(band,2);
            idx3 = f3 >= bands(band,1) & f3 < bands(band,2);

            % average the power of the band
            avg_bp1 = mean(fft_signal_present_chunk(idx1));
            avg_bp2 = mean(fft_no_signal_chunk_1(idx2));
            avg_bp3 = mean(fft_no_signal_chunk_2(idx3));

            bp_signal_present(band) = avg_bp1;
            bp_no_signal_1(band) = avg_bp2; 
            bp_no_signal_2(band) = avg_bp3;
        end

        % write to csv file.
        signal_row = [{target_filename}, num2cell(bp_signal_present'), {1}];
        no_signal_row_1 = [{target_filename}, num2cell(bp_no_signal_1'), {0}];
        no_signal_row_3 = [{target_filename}, num2cell(bp_no_signal_2'), {0}];

        writecell(signal_row, output_filename, 'WriteMode', 'append');
        writecell(no_signal_row, output_filename, 'WriteMode', 'append');
        writecell(no_signal_row_3, output_filename, 'WriteMode', 'append');

    end


end

