% -------------------------------------------------------------------------------------------------------
% purpose: prepares the input data for the CNN.
% 
% outputs: - a .mat file (to give the CNN) for training, which includes...
%            (1) a 4D tensor with shape: [num_files, num_windows, num_samples_per_window, num_channels=2])
%            (2) file-level labels (0 or 1).
%          - a .mat file for training, which includes...
%            (1) filenames (to make sure I train-val-test set split along the file axis -- not splitting up a file's windows.
% -------------------------------------------------------------------------------------------------------


% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/cnn_lstm_lr_model/preparing_cnn_matrix_1D.m');exit;"
function preparing_cnn_matrix_1D_fn(path, tensor_fname, file_list_fname, start_ix)
% function preparing_cnn_matrix_1D_fn(path, tensor_fname, start_ix)
    
    % signal parameters
    F_s = 2.4e6;
    

    % "grab" all .raw files.
    iq_signal_dir = dir(fullfile(path, '**', '*.raw'));
    num_files = length(iq_signal_dir);
    fprintf("Found %d .raw files in the iq signal dir .\n", num_files); % ==> the number of iq files in the hard drive.


    % dynamically find the number of windows and samples expected per window (considering downsampling) (necessary to initalize the 4D tensor).
    first_file = iq_signal_dir(1);
    % disp("first file: " + first_file.name)
    filepath = fullfile(first_file.folder, first_file.name);
    [~, num_windows, window_samples, ~] = window_signal(filepath);
    disp("num_windows per file: " + num_windows)
    disp("num samples per window: " + window_samples)


    % initalize a 4D tensor array for the CNN input.
    num_features = 2; % I and Q channels
    cnn_input = zeros(num_files, num_windows, window_samples, num_features);
    disp("size of cnn_input:")
    disp(size(cnn_input))


    % initialize a vector to store file-level labels (0 or 1). 
    labels_vector = zeros(num_files, 1);

    
    % initialize a cell array to store filenames in the same order as the labels.
    file_list = cell(num_files, 1);


    % define start and end idx. 
    if start_ix == 0 
        start_ix = 1;
        end_ix = num_files; 
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

        % determine whether the signal file has a pattern (using an older script so I'm just ignoring some of the outputs).
        % [has_pattern, ~, ~] = isolate_pattern_no_downsampling(filepath, 5, -1);
        [~, has_pattern, ~, ~, ~] = isolate_pattern(filepath);


        % assign file-level label based on the boolean variable, 'has_pattern'.
        if has_pattern
            labels_vector(i) = 1;
            disp("file has pattern :)")
        else
            labels_vector(i) = 0;
            disp("file doesn't have pattern :(")
        end


        % split the signal into same-size windows.
        [signal_windows, num_windows, window_samples, iq_components] = window_signal(filepath);


        % stack the real and imaginary components of the signal file.
        for j = 1:num_windows

            cnn_input(i, j, :, 1) = iq_components(:, 1, j); % i component.
            cnn_input(i, j, :, 2) = iq_components(:, 2, j); % q component.

        end
        % disp(i);
    end


    % sanity check
    disp("size of 4D feature tensor CNN input:")
    disp(size(cnn_input))


    % save the 4D features tensor and labels vector to a .mat file.
    save(tensor_fname, 'cnn_input', 'labels_vector')


    % save the file list cell array to a .mat file.
    save(file_list_fname, 'file_list')


    % save the 4D features tensor, labels vector, and list of filenames to a .mat file.
    % save(tensor_fname, 'cnn_input', 'labels_vector', 'file_list')

end


% % Veronica's calling...
% TODO: comment/uncomment this section before running script.
pattern_path = "/media/wairimu/Elements2/ch1_usrp/no_pattern";

% file_list_name3 = '/home/wairimu/file_list3.mat';


num_files = 40;
for iteration_ix =1:10
    
    tensor_fname = ['/home/wairimu/training_data_adjusted_window/cnn_input_data_' num2str(iteration_ix) '.mat'];
    file_list_name = ['/home/wairimu/training_data_adjusted_window/file_list_' num2str(iteration_ix) '.mat'];

    preparing_cnn_matrix_1D_fn(pattern_path, tensor_fname, file_list_name, num_files*(iteration_ix-1));

end





% % lydia's calling...
% TODO: comment/uncomment this section before running script.
% path = "/Volumes/PARTITION3/fc1075mhz_5sec_akirah/no_pattern";
path = '/Users/lydialonzarich/Desktop/CMU_REUSE/raw-data';


% tensor_fname = '3_cnn_input_data.mat';
% file_list_fname = '3_file_list.mat';

% start_ix = 0;

% preparing_cnn_matrix_1D_fn(path, tensor_fname, file_list_fname, start_ix)


