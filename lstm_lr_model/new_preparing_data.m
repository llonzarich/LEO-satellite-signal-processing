% -------------------------------------------------------------------------------------------------------------------------------------
% purpose: - this script prepares training data for the LSTM-LR model. 
%          - (1) automatically generate annotations for signal files (computing start_sec, end_sec, and chunk-level labels for a signal file's 12 chunks.
%          - (2) signal file annotations are written to a csv file. (columns = 'filename', 'start_sec', 'end_sec', 'label'. each file has 12 rows for its 12 chunks).
%          - (3) read csv file with annotations.
%          - (4) use the start_sec and end_sec data to chunk the .raw IQ signal file into its 12 relatively even chunks.
%          - (5) feature extraction (chunk-level features): avg power of 10 freq bands, NEO values.
%          - (6) use the chunk-level labels to compute file-level labels 
%          - (7) arrange features and file-level labels into a .mat file that will be passed to the model for training and interference.
% % -------------------------------------------------------------------------------------------------------------------------------------


% define path to the iq_signals
% iq_signal_path = '/Users/lydialonzarich/Desktop/testing';
iq_signal_path = '/home/llonzarich/Desktop/lstm_lr_model_data/have_pattern';
% iq_signal_path = '/media/llonzarich/Elements2/jul16';
% iq_signal_path = '/home/llonzarich/Desktop/lstm_lr_model_data/synthetic_data';
% iq_signal_path = '/media/llonzarich/Elements1/jul11tests';
iq_signal_dir = dir(fullfile(iq_signal_path, '**', '*.raw'));


fprintf("Found %d .raw files in the iq signal dir .\n", length(iq_signal_dir)); % ==> the number of iq files in the hard drive.


% create csv file for signal time interval annotations.
csv_filename = 'auto_annotations_testing.csv';
disp("Name of csv file being written to: " + csv_filename);


% delete the old csv file if it already exists.
if isfile(csv_filename)
    delete(csv_filename);
end


% create csv file with automatically-generated time interval annotations for each raw IQ signal file in the directory. 
% for i = 1:length(iq_signal_dir)
for i = 1:336
% for i = [1, 5, 11, 12, 13]

    file = iq_signal_dir(i); % 'file' holds the properties of the i-th file in the .raw IQ signal file directory. Use file.name to see the full .raw IQ filename.
    
    file_id = file.name(15:20) + ".raw"; % 6 digit file id.
    disp("6 digit file id: " + file_id)

    if strcmp(file.name, '.') || strcmp(file.name, '..') || file.isdir
        continue
    end
    [~, ~, ext] = fileparts(file.name);
    if ~strcmp(ext, '.raw')
        continue
    end

    filepath = fullfile(file.folder, file.name);
    % disp("filepath: " + filepath)

    [chunks, labels] = auto_signal_annotating(filepath); 
    % [chunks, labels] = new_auto_annotating(filepath);
    % [chunks, labels] = untitled(filepath);
    % ==> chunks: 12 x 2 matrix as [start_sec end_sec].
    % ==> labels: 12 x 1 vector as [0 or 1].

    filenames = repmat(string(file_id), size(chunks, 1), 1); 

    % [chunks, labels] = auto_signal_annotating(filepath); 
    % % [chunks, labels] = untitled(filepath);
    % % ==> chunks: 12 x 2 matrix as [start_sec end_sec].
    % % ==> labels: 12 x 1 vector as [0 or 1].
    % % disp(chunks(:,:));
    % % disp(labels(:,:));

    % combine filename, starting sec's, ending sec's, and labels into a table.
    T = table(filenames, chunks(:,1), chunks(:,2), labels, ...
        'VariableNames', {'filename', 'start_sec', 'end_sec', 'label'});

    % append data to csv file.
    if i == 1
        writetable(T, csv_filename);
    else
        writetable(T, csv_filename, 'WriteMode', 'Append', 'WriteVariableNames', false);
    end

    disp("finished writing data for file " + file_id + ".");

end


disp("The csv file with time annotations has been automatically created!")
