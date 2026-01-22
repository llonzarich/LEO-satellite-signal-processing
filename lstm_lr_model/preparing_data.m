% -------------------------------------------------------------------------------------------------------------------------------------
% purpose: - this script prepares training data for the LSTM-LR model. 
%          - (1) automatically generate annotations for signal files (computing start_sec, end_sec, and chunk-level labels for a signal file's 12 chunks.
%          - (2) signal file annotations are written to a csv file. (columns = 'filename', 'start_sec', 'end_sec', 'label'. each file has 12 rows for its 12 chunks).
%          - (3) read csv file with annotations.
%          - (4) use the start_sec and end_sec data to chunk the .raw IQ signal file into its 12 relatively even chunks.
%          - (5) feature extraction (chunk-level features): avg power of 10 freq bands, NEO values.
%          - (6) use the chunk-level labels to compute file-level labels 
%          - (7) arrange features and file-level labels into a .mat file that will be passed to the model for training and interference.
%
% -------------------------------------------------------------------------------------------------------------------------------------


% % define path to the iq_signals
% % iq_signal_path = '/Users/lydialonzarich/Desktop/testing';
% iq_signal_path = '/home/llonzarich/Desktop/lstm_lr_model_data/jul17';
% % iq_signal_path = '/media/llonzarich/Elements2/jul16';
% % iq_signal_path = '/home/llonzarich/Desktop/lstm_lr_model_data/synthetic_data';
% % iq_signal_path = '/media/llonzarich/Elements1/jul11tests';
% iq_signal_dir = dir(fullfile(iq_signal_path, '**', '*.raw'));
% 
% % iq_signal_path1 = '/home/llonzarich/Desktop/lstm_lr_model_data/have_pattern';
% % iq_signal_path2 = '/home/llonzarich/Desktop/lstm_lr_model_data/no_patterns';
% % iq_signal_dir1 = dir(fullfile(iq_signal_path1, '**', '*.raw'));
% % iq_signal_dir2 = dir(fullfile(iq_signal_path2, '**', '*.raw'));
% % iq_signal_dir = [iq_signal_dir1; iq_signal_dir2];
% 
% 
% fprintf("Found %d .raw files in the iq signal dir .\n", length(iq_signal_dir)); % ==> the number of iq files in the hard drive.
% 
% 
% % create csv file for signal time interval annotations.
% csv_filename = 'NEW_auto_annotations_jul17.csv';
% disp("Name of csv file being written to: " + csv_filename);
% 
% 
% % delete the old csv file if it already exists.
% if isfile(csv_filename)
%     delete(csv_filename);
% end
% 
% 
% % create csv file with automatically-generated time interval annotations for each raw IQ signal file in the directory. 
% for i = 1:length(iq_signal_dir)
% % for i = 1:196
% % for i = [1, 5, 11, 12, 13]
% 
%     file = iq_signal_dir(i); % 'file' holds the properties of the i-th file in the .raw IQ signal file directory. Use file.name to see the full .raw IQ filename.
% 
%     file_id = file.name(15:20) + ".raw"; % 6 digit file id.
%     disp("6 digit file id: " + file_id)
% 
%     if strcmp(file.name, '.') || strcmp(file.name, '..') || file.isdir
%         continue
%     end
%     [~, ~, ext] = fileparts(file.name);
%     if ~strcmp(ext, '.raw')
%         continue
%     end
% 
%     filepath = fullfile(file.folder, file.name);
%     % disp("filepath: " + filepath)
% 
%     % [chunks, labels] = auto_signal_annotating(filepath); 
%     [chunks, labels] = new_auto_annotating(filepath);
%     % [chunks, labels] = untitled(filepath);
%     % ==> chunks: 12 x 2 matrix as [start_sec end_sec].
%     % ==> labels: 12 x 1 vector as [0 or 1].
% 
%     filenames = repmat(string(file_id), size(chunks, 1), 1); 
% 
%     % [chunks, labels] = auto_signal_annotating(filepath); 
%     % % [chunks, labels] = untitled(filepath);
%     % % ==> chunks: 12 x 2 matrix as [start_sec end_sec].
%     % % ==> labels: 12 x 1 vector as [0 or 1].
%     % % disp(chunks(:,:));
%     % % disp(labels(:,:));
% 
%     % combine filename, starting sec's, ending sec's, and labels into a table.
%     T = table(filenames, chunks(:,1), chunks(:,2), labels, ...
%         'VariableNames', {'filename', 'start_sec', 'end_sec', 'label'});
% 
%     % append data to csv file.
%     if i == 1
%         writetable(T, csv_filename);
%     else
%         writetable(T, csv_filename, 'WriteMode', 'Append', 'WriteVariableNames', false);
%     end
% 
%     disp("finished writing data for file " + file_id + ".");
% 
% end
% 
% 
% disp("The csv file with time annotations has been automatically created!")


% % ------------ combine multiple csv files with annotation data ------------
% % goal: append new csv file (with annotations from new .raw signal files) to the og csv file (with annotations from the original 141 .raw signal files).
% disp("Begining to concatenate og csv file with new csv file(s).")
% 
% 
% % read the csv files.
% % note: readtable() reads the first row as column header rows and the rest as data rows.
% csv1 = readtable('NEW_auto_annotations_ogs.csv'); 
% csv2 = readtable('NEW_auto_annotations_jul11.csv');
% % csv3 = readtable('NEW_auto_annotations_jul16.csv');
% % csv3 = readtable('auto_annotations_jul11_first_half_filtered.csv'); % first half of jul11 data.
% % csv3 = readtable('auto_annotations_jul17data.csv'); % jul17 data.
% % csv3 = readtable('auto_annotations_synthogdata_updated.csv'); % synthetic data from og data WITH 'synth_' before <6 digit file id>.raw in filename column.
% 
% 
% % disp("num rows in csv 1: " + height(csv1));
% % disp("num rows in csv 2: " + height(csv2));
% % disp("num rows in csv 3: " + height(csv3));
% 
% 
% % concatenate tables from csv files vertically. This just stacks the tables (no extra header row).
% csv_append = [csv1; csv2];
% 
% 
% % write data to a new csv file.
% % note: writetable() writes the header row back into the new csv file.
% writetable(csv_append, 'auto_annotations_7.csv');
% 
% 
% disp("Successfully concatenated og csv file with new csv file(s).")
% --------------------------------------------------------------------------------------


% read the csv file with all signal file time and label annotations.
T = readtable('auto_annotations_7.csv');  % or use readmatrix if it's numeric


% Get unique filenames
files = unique(T{:,1});  % assumes filename is in the first column


% Loop through each file and count rows
for i = 1:length(files)
    this_file = files{i};
    count = sum(strcmp(T{:,1}, this_file));  % count rows for this file

    if count ~= 51
        fprintf('File "%s" has %d rows.\n', this_file, count);
    end
end


% define the path to the file with signal time interval annotations.
time_interval_path = "auto_annotations_7.csv";


% force matlab to read the leading 0s in filenames. 
opts = detectImportOptions(time_interval_path);
opts = setvartype(opts, 'filename', 'string');


% open the csv file and read the time interval info as a table data structure.
data = readtable(time_interval_path, opts);


% compile all .raw files from XX into one variable: 'all_iq_files'.
% path1 = "/home/llonzarich/Desktop/lstm_lr_model_data"; % og 141 .raw files + synthetically generated 141 files.
% path2 = "/media/llonzarich/Elements2/jul16"; % new .raw files. I'm only taking the first 150 of the .raw files in this folder.
path1 = "/home/llonzarich/Desktop/lstm_lr_model_data/have_pattern";
path2 = "/home/llonzarich/Desktop/lstm_lr_model_data/no_patterns";
% path3 = "/home/llonzarich/Desktop/lstm_lr_model_data/synthetic_data";
% path3 = "/home/llonzarich/Desktop/lstm_lr_model_data/jul11";
% path4 = "/media/llonzarich/Elements1/jul17";
path3 = "/media/llonzarich/Elements1/jul11tests";
% path4 = "/home/llonzarich/Desktop/lstm_lr_model_data/jul16";


% parse each folder and "grab" all the .raw files.
all_iq_files1 = dir(fullfile(path1, '**', '*.raw')); % have-patterns
all_iq_files2 = dir(fullfile(path2, '**', '*.raw')); % no-patterns
% all_iq_files3 = dir(fullfile(path3, '**', '*.raw')); % synthetic files.
% all_iq_files3 = dir(fullfile(path3, '**', '*.raw')); % 150 jul16 files
% all_iq_files3 = all_iq_files3(1:min(150, length(all_iq_files3))); % only take the first 150 of the .raw files in this folder.
all_iq_files3 = dir(fullfile(path3, '**', '*.raw')); % 661 jul11 files.
% all_iq_files4 = dir(fullfile(path4, '**', '*.raw')); % 150 jul16 files.
disp("number of have-pattern files: " + length(all_iq_files1));
disp("number of no-pattern files: " + length(all_iq_files2));
disp("number of jul11 files: " + length(all_iq_files3));
% disp("number of jul16 files: " + length(all_iq_files4));


% combine all .raw files into 1 list.
all_iq_files = [all_iq_files1; all_iq_files2; all_iq_files3]; 
disp("number of raw signal files: " + numel(all_iq_files)); 
% all_iq_files = [all_iq_files1; all_iq_files2];
% disp("number of iq files: " + size(all_iq_files))
% all_iq_files = [all_iq_files1; all_iq_files2; all_iq_files4];
% all_synth_iq_files = all_iq_files3;
% disp("number of original files: " + length(all_iq_files));
% disp("number of synthetic files: " + length(all_synth_iq_files));


% preallocate an empty string array to store the cleaned up filenames.
iq_filenames = strings(length(all_iq_files), 1);
% synth_iq_filenames = strings(length(all_synth_iq_files), 1);


% populate 'iq_filenames' array with each .raw file's "cleaned-up" name: <6 digit file id>.raw.
for i = 1:length(all_iq_files)
    original_name = all_iq_files(i).name;
    original_path = fullfile(all_iq_files(i).folder, original_name);

    % use regex to extract the 6 digit id.
    tokens = regexp(original_name, 'gqrx_\d+_(\d{6})', 'tokens');
    if ~isempty(tokens)
        time_tag = tokens{1}{1};
        iq_filenames(i) = time_tag + ".raw";
        % disp(iq_filenames(i)) % ==> every .raw file in the hard drive, but with its named shortened.
    else
        warning('Could not extract time tag from: %s', original_name)
    end
end


% % populate 'synth_iq_filenames' array with each .raw file's "cleaned-up" name: <6 digit file id>.raw.
% for i = 1:length(all_synth_iq_files)
%     original_name = all_synth_iq_files(i).name;
%     original_path = fullfile(all_synth_iq_files(i).folder, original_name);
% 
%     % use regex to extract the 6 digit id.
%     tokens = regexp(original_name, 'gqrx_\d+_(\d{6})', 'tokens');
%     if ~isempty(tokens)
%         time_tag = tokens{1}{1};
%         synth_iq_filenames(i) = "synth_" + time_tag + ".raw";
%         % disp(iq_filenames(i)) % ==> every .raw file in the hard drive, but with its named shortened.
%     else
%         warning('Could not extract time tag from: %s', original_name)
%     end
% end
% % disp(synth_iq_filenames)
% % ==> synth_<6 digit file id>.raw



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


% prepare parameters
num_time_chunks = 51;
num_features = 14;
num_rows = height(data); % get the number of rows in the csv file, part 1.
if mod(num_rows, 51) ~= 0
    error("expected 51 rows per file but got %d total rows", num_rows);
end
num_files = num_rows/51; % get the number of files in the csv file, part 2.
disp("num rows: " + num_rows)


% create empty column arrays for each file's features (12 sequences, each with 14 features) and label data.
features = cell(num_files, 1); % num_files cells x 1 cell, every cell has 51 sequences, each with 14 features.
labels = zeros(num_files, 1); 


csv_filenames = data.filename; % 'csv_filenames' holds all of the filenames in the 'filename' column of the csv file. 
csv_labels = data.label; % 'csv_labels' holds all of the labels in the 'labels' column of the csv file. 


% iterate through each file in the csv file. (each file has 12 rows).
% for i = 1:num_files
for i = 2:2

    rows = ((i - 1) * num_time_chunks + 1):(i * num_time_chunks); % "grab" the correct 51 rows for the i-th file.

    target_filename = data.filename(rows(1)); % our "target" file (aka, the file we want to work with for the current iteration) is the filename of the first row of the i-th file (in the csv file).

    disp("target filename: " + target_filename); % ==> <6 digit filename id>.raw


    if startsWith(target_filename, "synth_")
        % if the filename in the csv starts with "synth_", pull the matching .raw file from the all_synth_iq_files folder

        matched_idx = find(synth_iq_filenames == target_filename); 

        disp("matched idx: " + matched_idx)
        disp("matched idx folder: " + all_synth_iq_files(matched_idx).folder)

        iq_signal_file = fullfile(all_synth_iq_files(matched_idx).folder, all_synth_iq_files(matched_idx).name);
        disp("chosen iq .raw file: ")
        disp(iq_signal_file)

    else
        disp("filename does not start with 'synth_'")
        matched_idx = find(iq_filenames == target_filename); % find the index of the corresponding .raw file (aka, the .raw file with the same 6 digit id) from the hard drive.

        disp("matched idx: " + matched_idx)
        disp("matched idx folder: " + all_iq_files(matched_idx).folder)

        iq_signal_file = fullfile(all_iq_files(matched_idx).folder, all_iq_files(matched_idx).name); % use the 'matched_idx' to find the correct .raw file from the hard drive (the one that matches the "target" file).
        disp("chosen iq .raw file: ")
        disp(iq_signal_file) % ==> the path to the .raw file of this iteration.

    end


    if ~isfile(iq_signal_file)
        warning('Missing file: %s', iq_signal_file);
        continue;
    end


    % create empty feature and label matrices for the i-th file
    single_file_feature_matrix = zeros(num_time_chunks, num_features);
    single_file_chunks = zeros(51, 2);
    single_file_chunk_labels = zeros(51, 1); 


    % iterate through the 51 rows of the i-th file.
    for j = 1:num_time_chunks

        % "pull" data from the current row of the csv file.
        start_sec = data.start_sec(rows(j));
        end_sec = data.end_sec(rows(j));
        chunk = [start_sec, end_sec];
        label = data.label(rows(j));

        % extract the j-th chunk's features!
        [avg_bandpowers_vec, neo_feature_vec] = signal_chunking(iq_signal_file, fs, start_sec, end_sec, bands); % ==> 10x1 column vector with the avg power of each of the 10 freq. bands in the i-th chunk.

        % append the j-th chunk's features to the i-th file's feature matrix.
        single_file_feature_matrix(j, :) = [avg_bandpowers_vec; neo_feature_vec]';

        % append the chunk start_sec and end_sec to the i-th file's array.
        single_file_chunks(j, :) = chunk;
        
        % append the chunk-level label (0 or 1) to the i-th file's feature matrix.
        single_file_chunk_labels(j) = label;

    end
    % ==> a 51 x 14 feature matrix for the i-th file.
    % ==> a 51 x 2 vector with chunk start_sec and end_sec annotations for the i-th file.
    % ==> a 51 x 1 vector with the chunk-level labels for the i-th file.


    % determine the file-level label (0 or 1) for the i-th file.
    pattern_detected = detect_pattern(single_file_chunks, single_file_chunk_labels); 


    % append each file's features and label to the main arrays (that we'll use for training data)
    features{i} = single_file_feature_matrix;
    labels(i) = pattern_detected;
    disp("target_filename: ")
    disp(target_filename)
    disp(labels(i))


end


save('lstm_data_8.mat', 'features', 'labels');


