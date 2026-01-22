% -------------------------------------------------------------------------------------------------------
% purpose: prepares the 1D input data for the CNN.
% 
% outputs: - a .mat file (to give the CNN) for training, which includes...
%            (1) a 4D tensor with shape: [num_files, num_windows, num_samples_per_window, num_channels=2])
%            (2) file-level labels (0 or 1).
%          - a .mat file for training, which includes...
%            (1) filenames (to make sure I train-val-test set split along the file axis -- not splitting up a file's windows.
% -------------------------------------------------------------------------------------------------------


% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/cnn_lstm_lr_model/preparing_cnn_matrix_1D.m');exit;"
% function preparing_cnn_matrix_1D_fn(path, tensor_fname, file_list_fname, start_ix)
% function preparing_cnn_matrix_1D_fn(path, tensor_fname, start_ix)
function preparing_cnn_matrix_1D_fn(path, output_fname, start_ix)
    
    % signal parameters
    F_s = 2.4e6;
    

    % "grab" all .raw files.
    iq_signal_dir = dir(fullfile(path, '**', '*.raw'));
    % num_files = length(iq_signal_dir);
    num_files = 15;
    fprintf("Found %d .raw files in the iq signal dir .\n", num_files); % ==> the number of iq files in the hard drive.


    % % dynamically find the number of windows and samples expected per window (considering downsampling) (necessary to initalize the 4D tensor).
    % first_file = iq_signal_dir(1);
    % filepath = fullfile(first_file.folder, first_file.name);
    % [~, num_windows, window_samples, ~] = window_signal(filepath);
    % num_features = 2; % I and Q channels.


    % create cell arrays for data
    ALL_cnn_input = {}; % the 4D tensor
    ALL_window_labels = {};
    file_list = {};


    % % initalize a 4D tensor array for the CNN input.
    % cnn_input = zeros(num_files, num_windows, window_samples, num_features);
    % disp("size of cnn_input:")
    % disp(size(cnn_input))
    % 
    % 
    % % initialize a vector to store window-level labels (0 or 1). 
    % window_labels_vector = zeros(num_files, num_windows);
    % disp("size of window_labels_vector:")
    % disp(size(window_labels_vector))
    % 
    % 
    % % initialize a cell array to store filenames in the same order as the labels.
    % file_list = cell(num_files, 1);


    % define start and end idx. 
    if start_ix == 0 
        start_ix = 1;
        end_ix = 15; 
    else 
        end_ix = start_ix + num_files; 
    end 


    % iterate through all iq signal files to fill its entry in the 4D 'cnn_input' tensor and assign it a corresponding label (0 or 1).
    for i = start_ix:end_ix

        file = iq_signal_dir(i); % 'file' holds the properties of the i-th file in the .raw IQ signal file directory. Use file.name to see the full .raw IQ filename.
	
        
        % append the filename to the file_list array.
	    file_name = file.name;
	    disp("filename: " + file_name)
	    file_list{i} = file_name;


        file_id = file.name(15:20) + ".raw"; % 6 digit file id.
        % disp("6 digit file id: " + file_id)


        if strcmp(file.name, '.') || strcmp(file.name, '..') || file.isdir
            continue
        end
        [~, ~, ext] = fileparts(file.name);
        if ~strcmp(ext, '.raw')
            continue
        end


        filepath = fullfile(file.folder, file.name);
        % disp("filepath: " + filepath)


        % find all pattern chunks in the IQ signal file.
        [valid_pattern_chunks, num_pattern_chunks] = find_pattern_chunks(filepath);
        

        % split the signal into same-size windows 
        [signal_windows, num_windows, window_samples, iq_components] = window_signal(filepath);
        % disp("signal window 1:")
        % disp(signal_windows(1,:))
        % disp("number of windows per file: " + num_windows)
        % disp("number of samples in each window: " + window_samples)


        % preallocate and fill file_cnn_input for the i-th file.
        file_cnn_input = zeros(num_windows, window_samples, 2);
        disp("size of cnn_input for file " + i)
        disp(size(file_cnn_input))


        % stack the real and imaginary components of the signal file.
        for j = 1:num_windows

            file_cnn_input(j, :, 1) = iq_components(:, 1, j); % i component.
            file_cnn_input(j, :, 2) = iq_components(:, 2, j); % q component.

        end


        % preallocate and fill 'file_window_labels'  with file-level labels for the i-th file.
        file_window_labels = label_windows(valid_pattern_chunks, num_pattern_chunks, num_windows, signal_windows);
        disp("window labels for file " + i + ":")
        disp(file_window_labels)
        disp("number of window labels for file " + i + ":" + size(file_window_labels))


        % save cnn_input info and window-level labels into the ALL_... arrays
        ALL_cnn_input{i} = file_cnn_input;
        ALL_window_labels{i} = file_window_labels;

    end


    disp("number of files we got data for: " + size(file_list))
    disp("size of ALL_cnn_input (4D tensor):")
    disp(size(ALL_cnn_input)) 
    disp("size of ALL_window_labels:")
    disp(size(ALL_window_labels))



    % % ----------- SPLIT ALL FILES INTO TRAIN-VAL-TEST SETS -----------------
    % 
    % disp("BEGIN SPLITTING ALL DATA INTO TRAIN, VAL, AND TEST SETS")
    % 
    % 
    % % splitting parameters
    % train_ratio = 0.55;
    % val_ratio = 0.15;
    % test_ratio = 0.3;
    % rng(42);
    % 
    % 
    % % collect all indices, but shuffled.
    % shuffled_indices = randperm(num_files);
    % 
    % 
    % num_train_files = round(train_ratio * num_files);
    % num_val_files = round(val_ratio * num_files);
    % num_test_files = num_files - num_train_files - num_val_files;
    % 
    % 


    % % ----------- SPLIT ALL FILES INTO TRAIN-VAL-TEST SETS -----------------
    % rng(42);
    % 
    % % collect all indices, but shuffled.
    % shuffled_indices = randperm(num_files);
    % 
    % % determine the number of files that will be put into each set.
    % num_train_files = round(train_ratio * num_files);
    % num_val_files = round(val_ratio * num_files);
    % num_test_files = num_files - num_train_files - num_val_files;
    % disp("number of training set files: " + num_train_files)
    % disp("number of val set files: " + num_val_files)
    % disp("number of test set files: " + num_test_files)
    % 
    % % determine indices of train, val, and test sets
    % train_idx = indices(1:num_train_files);
    % val_idx = indices(num_train_files + 1:num_train_files + num_val_files);
    % test_idx = indices(num_train_files + num_val_files + 1:end);
    % 
    % % create train, val, and test sets using indices
    % train_set.X = ALL_cnn_input(train_idx);
    % train_set.y = ALL_window_labels(train_idx);
    % train_set.files = file_list(train_idx);
    % disp("training set files: " + train_set.files)
    % 
    % val_set.X = ALL_cnn_input(val_idx);
    % val_set.y = ALL_window_labels(val_idx);
    % val_set.files = file_list(val_idx);
    % disp("val set files: " + val_set.files)
    % 
    % test_set.X = ALL_cnn_input(test_idx);
    % test_set.y = ALL_window_labels(test_idx);
    % test_set.files = file_list(test_idx);
    % disp("test set files: " + test_set.files)
    % 
    % 
    % % save all data from each set to a .mat file
    % save(output_fname, 'train_set', 'val_set', 'test_set');

end


% % Veronica's calling...
% TODO: comment/uncomment this section before running script.
% pattern_path = "/media/wairimu/Elements2/ch1_usrp/no_pattern";
% 
% % file_list_name3 = '/home/wairimu/file_list3.mat';
% 
% 
% num_files = 40;
% for iteration_ix =1:10
% 
%     tensor_fname = ['/home/wairimu/training_data_adjusted_window/cnn_input_data_' num2str(iteration_ix) '.mat'];
%     file_list_name = ['/home/wairimu/training_data_adjusted_window/file_list_' num2str(iteration_ix) '.mat'];
% 
%     preparing_cnn_matrix_1D_fn(pattern_path, tensor_fname, file_list_name, num_files*(iteration_ix-1));
% 
% end





% lydia's calling...2
% TODO: comment/uncomment this section before running script.
path = "/Volumes/PARTITION3/fc1075mhz_5sec_akirah/no_pattern";

% tensor_fname = '8_cnn_input_data.mat';
% file_list_fname = '8_file_list.mat';
output_fname = '8_cnn_input_data.mat';

start_ix = 0;

% preparing_cnn_matrix_1D_fn(path, tensor_fname, file_list_fname, start_ix)
preparing_cnn_matrix_1D_fn(path, output_fname, start_ix)
