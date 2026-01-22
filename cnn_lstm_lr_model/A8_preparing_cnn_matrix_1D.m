% -------------------------------------------------------------------------------------------------------
% purpose: prepares the 1D input data for the CNN.
% 
% outputs: - a .mat file (to give the CNN) for training, which includes...
%            (1) a 4D tensor with shape: [num_files, num_windows, num_samples_per_window, num_channels=2])
%            (2) file-level labels (0 or 1).
%          - a .mat file for training, which includes...
%            (1) filenames (to make sure I train-val-test set split along the file axis -- not splitting up a file's windows.
% -------------------------------------------------------------------------------------------------------


% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/cnn_lstm_lr_model/windowlabeling_preparing_cnn_matrix_1D.m');exit;"
function preparing_cnn_matrix_1D_fn(path, train_output_fname, val_output_fname, test_output_fname, start_ix)
% function preparing_cnn_matrix_1D_fn(path, tensor_fname, start_ix)
    
    % signal parameters
    F_s = 2.4e6;
    

    % "grab" all .raw files.
    iq_signal_dir = dir(fullfile(path, '**', '*.raw')); TODO: comment/uncomment before running script (if path is to a folder with subdirectories of .raw files). 
    % iq_signal_dir = dir(fullfile(path, '*.raw')); % TODO: comment/uncomment before running script (if path is 1 specific folder with .raw files).
    num_files = length(iq_signal_dir); % TODO: change
    % num_files = 5; % TODO: change
    fprintf("Found %d .raw files in the iq signal dir .\n", num_files); 


    % get all raw IQ signal files. 
    file_list = {iq_signal_dir.name};
    % disp("ANOTHER CHECK: number of files: " + length(file_list))
    
    
    % split files into train/val/test sets.
    [train_files, val_files, test_files, num_train_files, num_val_files, num_test_files] = split_data(file_list, num_files);
    

    % disp("train files: ")
    % disp(train_files)
    % disp("size of train files: ")
    % disp(size(train_files))


    % dynamically find the params for the 4D CNN input "features" tensor: num windows, num samples per window, num_channels.
    first_file = iq_signal_dir(1);
    filepath = fullfile(first_file.folder, first_file.name);
    [~, num_windows, window_samples, ~] = A8_window_signal(filepath);
    num_channels = 2;


    % initialize a 4D tensor and labels array for each split's data
    cnn_input_train = zeros(num_train_files, num_windows, window_samples, num_channels);
    window_labels_train = zeros(num_train_files, num_windows);

    cnn_input_val = zeros(num_val_files, num_windows, window_samples, num_channels);
    window_labels_val = zeros(num_val_files, num_windows);

    cnn_input_test = zeros(num_test_files, num_windows, window_samples, num_channels);
    window_labels_test = zeros(num_test_files, num_windows);


    disp("size of initialized 4D feature tensor for the training set:")
    disp(size(cnn_input_train))

    disp("size of initialized window-labels vector for the training set:")
    disp(size(window_labels_train))

    disp("size of initialized 4D feature tensor for the val set:")
    disp(size(cnn_input_val))

    disp("size of initialized window-labels vector for the val set:")
    disp(size(window_labels_val))

    disp("size of initialized 4D feature tensor for the test set:")
    disp(size(cnn_input_test))

    disp("size of initialized window-labels vector for the test set:")
    disp(size(window_labels_test))


    % % initalize a 4D tensor array for the CNN input "features".
    % cnn_input = zeros(num_files, num_windows, window_samples, num_channels);
    % disp("size of cnn_input:")
    % disp(size(cnn_input))
    % 
    % 
    % % initialize a vector to store window-level labels (0 or 1). 
    % window_labels_vector = zeros(num_files, num_windows);
    % disp("size of window_labels_vector:")
    % disp(size(window_labels_vector))

    
    % initialize a cell array to store filenames in the same order as the labels.
    % file_list = cell(num_files, 1);


    % define start and end idx. 
    if start_ix == 0 
        start_ix = 1;
        end_ix = num_files; % TODO: CHANGE to/from num_files.
    else 
        end_ix = start_ix + num_files; 
    end 


    % initialize train, val, test set counters
    train_idx = 1; 
    val_idx = 1;
    test_idx = 1;


    % iterate through all iq signal files to fill its entry in the 4D 'cnn_input' tensor and assign it a corresponding label (0 or 1).
    for i = start_ix:end_ix

        file = iq_signal_dir(i); % 'file' holds the properties of the i-th file in the .raw IQ signal file directory. Use file.name to see the full .raw IQ filename.
	
        
        % append the filename to the file_list array.
	    file_name = file.name;
	    disp("filename of file " + i + ": " + file_name)
	    file_list{i} = file_name;


        file_id = file.name(15:20) + ".raw"; % 6 digit file id.

        if strcmp(file.name, '.') || strcmp(file.name, '..') || file.isdir
            continue
        end
        [~, ~, ext] = fileparts(file.name);
        if ~strcmp(ext, '.raw')
            continue
        end


        filepath = fullfile(file.folder, file.name);


        % find all pattern chunks in the IQ signal file.
        % (btw: valid_pattern chunks is a matrix with the the start/end times of each (valid) pattern chunk in the file).
        [valid_pattern_chunks, num_pattern_chunks] = A8_find_pattern_chunks(filepath);
        % disp("all valid pattern chunks in file: " + i + ": ")
        % disp(valid_pattern_chunks)


        % split the signal into same-size windows.
        [signal_windows, num_windows, ~, iq_components] = A8_window_signal(filepath);
        % [~, ~, ~, iq_components] = window_signal(filepath);
 
        
        % stack the real and imaginary components of the signal file.
        file_iq_tensor = zeros(num_windows, window_samples, num_channels);
        
        for j = 1:num_windows

            file_iq_tensor(j, :, 1) = iq_components(:, 1, j); % i component.
            file_iq_tensor(j, :, 2) = iq_components(:, 2, j); % q component. 

        end


        disp("size of file_iq_tensor of file " + i + ": ")
        disp(size(file_iq_tensor)) % ==> (num_windows=59, num_samples_per_window=4800, num_channels=2).


        % determine window-level labels for the i-th file
        file_window_labels = A8_label_windows(valid_pattern_chunks, num_pattern_chunks, num_windows, signal_windows);
        disp("window labels for file " + i + ":")
        disp(file_window_labels)


        % append iq components and window labels to the correct split
        if ismember(file_name, train_files)
            % split_type = 'train';
            disp("current train idx: " + train_idx)
            cnn_input_train(train_idx, :, :, :) = file_iq_tensor; 
            window_labels_train(train_idx, :) = file_window_labels;
            train_idx = train_idx + 1;

        elseif ismember(file_name, val_files)
            % split_type = 'val';
            disp("current val idx: " + val_idx)
            cnn_input_val(val_idx, :, :, :) = file_iq_tensor;
            window_labels_val(val_idx, :) = file_window_labels;
            val_idx = val_idx + 1;

        elseif ismember(file_name, test_files)
            % split_type = 'test';
            disp("current test idx: " + test_idx)
            cnn_input_test(test_idx, :, :, :) = file_iq_tensor;
            window_labels_test(test_idx, :) = file_window_labels;
            test_idx = test_idx + 1;

        end

    end


    % disp("testing:")
    % disp(train_files(1, 1))
    % disp(train_files(1, 2))
    % disp(train_files(1, 3))
    % 
    % 
    % disp("size of window_labels:")
    % disp(size(window_labels_train))
    % disp(size(window_labels_val))
    % disp(size(window_labels_test))

    
    % sanity check
    disp("FINAL size of cnn_input_train")
    disp(size(cnn_input_train))
    disp("FINAL number of files in training set:")
    disp(size(train_files))

    disp("FINAL size of cnn_input_val")
    disp(size(cnn_input_val))
    disp("FINAL number of files in val set:")
    disp(size(val_files))

    disp("FINAL size of cnn_input_test")
    disp(size(cnn_input_test))
    disp("FINAL number of files in test set:")
    disp(size(test_files))

    % save .mat files
    save(train_output_fname, 'cnn_input_train', 'window_labels_train', 'train_files');
    save(val_output_fname, 'cnn_input_val', 'window_labels_val', 'val_files');
    save(test_output_fname, 'cnn_input_test', 'window_labels_test', 'test_files');

end


% % % Veronica's calling...
% % TODO: comment/uncomment this section before running script.
pattern_path = "/media/wairimu/Elements2/ch1_usrp/no_pattern";

num_files = 40;
for iteration_ix =1:10

    tensor_fname = ['/home/wairimu/training_data_approach_8/cnn_input_data_' num2str(iteration_ix) '.mat'];
    file_list_name = ['/home/wairimu/training_data_approach_8/file_list_' num2str(iteration_ix) '.mat'];
    % function preparing_cnn_matrix_1D_fn(path, train_output_fname, val_output_fname, test_output_fname, start_ix)
    train_output_fname = ['/home/wairimu/training_data_approach_8/cnn_input_data_train_' num2str(iteration_ix) '.mat'];
    val_output_fname = ['/home/wairimu/training_data_approach_8/cnn_input_data_val_' num2str(iteration_ix) '.mat'];
    test_output_fname = ['/home/wairimu/training_data_approach_8/cnn_input_data_test ' num2str(iteration_ix) '.mat'];
    start_ix = num_files*(iteration_ix-1);
    % preparing_cnn_matrix_1D_fn(pattern_path, tensor_fname, file_list_name, num_files*(iteration_ix-1));
    preparing_cnn_matrix_1D_fn(pattern_path, train_output_fname, val_output_fname, test_output_fname, start_ix)

end





% lydia's calling...
% TODO: comment/uncomment this section before running script.
% path = '/Users/lydialonzarich/Desktop/CMU_REUSE/raw-data';

% % tensor_fname = '8_cnn_input_data.mat';
% % file_list_fname = '8_file_list.mat';
% train_output_fname = '11_cnn_input_data_train.mat';
% val_output_fname = '11_cnn_input_data_val.mat';
% test_output_fname = '11_cnn_input_data_test.mat';

% start_ix = 0;

% preparing_cnn_matrix_1D_fn(path, train_output_fname, val_output_fname, test_output_fname, start_ix)