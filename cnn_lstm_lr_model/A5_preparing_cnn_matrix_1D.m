% -------------------------------------------------------------------------------------------------------
% purpose: prepares the input data for the CNN.
%
% Logic: (1) call 'thirtysixsec_isolate_pattern.m' -- get start sec, end sec, and file-level label of a trimmed signal file (36 sec) (determine start/end sec of trimmed file according to consecutive pattern chunks).
%        (2) call 'trim_file.m' -- actually trim the signal file to be seconds.
%        (3) call 'thirtysixsec_window_signal.m' -- split the 36sec signal into sequences of overlapping same-size windows.
%        (4) fill and save 'cnn_input' 4D tensor, 'labels_vector', and 'files_list' to .mat files.
% 
% outputs: - a .mat file (to give the CNN) for training, which includes...
%            (1) a 4D tensor with shape: [num_files, num_windows, num_samples_per_window, signal_power=1]
%            (2) file-level labels (0 or 1).
%          - a .mat file for training, which includes...
%            (1) filenames (to make sure I train-val-test set split along the file axis -- not splitting up a file's windows.
% -------------------------------------------------------------------------------------------------------


% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/cnn_lstm_lr_model/A5_preparing_cnn_matrix_1D.m');exit;"
function preparing_cnn_matrix_1D_fn(path, tensor_fname, file_list_fname, start_ix)
% function preparing_cnn_matrix_1D_fn(path, tensor_fname, start_ix)
    
    % signal parameters
    F_s = 2.4e6;
    PATTERN_LENGTH = 5;
    

    % "grab" all .raw files.
    iq_signal_dir = dir(fullfile(path, '**', '*.raw'));
    % num_files = length(iq_signal_dir);
    num_files = 40; % TODO: change
    fprintf("Found %d .raw files in the iq signal dir .\n", num_files); % ==> the number of iq files in the hard drive.


    % dynamically find the number of samples expected per window (considering downsampling) (necessary to initalize the 4D tensor).
    first_file = iq_signal_dir(1);
    filepath = fullfile(first_file.folder, first_file.name);
    [~, ~, window_samples, ~] = A5_window_signal(filepath);
    disp("num samples per window: " + window_samples)
    num_windows = 13;
    num_features = 1; % signal power.


    % initalize a 4D tensor array for the CNN input.
    cnn_input = zeros(num_files, num_windows, window_samples, num_features);
    disp("size of 4D feature tensor CNN input:")
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
        % disp("filepath: " + filepath)


        % determine whether the signal file has a pattern 
        % also get the start/end times of the 36sec pattern chunk
        [~, has_pattern, ~, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk] = A5_isolate_pattern(filepath);

        
        % assign file-level label based on the boolean variable, 'has_pattern'.
        if has_pattern
            labels_vector(i) = 1;
            disp("file has pattern :)")
        else
            labels_vector(i) = 0;
            disp("file doesn't have pattern :(")
        end

        
        % trim the signal file to be the 36 seconds.
        trimmed_signal = A5_trim_file(filepath, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk, F_s);

        
        % split the signal into 13 x 12sec windows. 
        [~, num_windows, ~, iq_components] = A5_window_signal(trimmed_signal);


        % disp("number of windows: " + num_windows)
        % disp("number of samples in each window: " + window_samples)
        % disp("size of iq_components for iteration " + i + ": ")
        % disp(size(iq_components))


        % stack the real and imaginary components of the signal file.
        for j = 1:num_windows
            i_channel = iq_components(:, 1, j);
            q_channel = iq_components(:, 2, j);

            window_signal_power = mean(i_channel.^2 + q_channel.^2);


            %% TODO: uncomment this if wanting to train only on signal power
            % train on moving average of signal power 
            n_samples_per_pattern = PATTERN_LENGTH * F_s;

            % signal_power = abs(y1).^2; % Calculate signal power
            moving_avg_power = movmean(window_signal_power, n_samples_per_pattern);
            moving_avg_power = normalize(moving_avg_power, "range", [0 1]);
            disp("size of window signal power: ")
            disp(size(window_signal_power));
            disp("size of moving average of window sigal power");
            disp(size(moving_avg_power));
            cnn_input(i, j, 1, 1) = moving_avg_power; 

            %%

            % cnn_input(i, j, 1, 1) = window_signal_power; 


        end
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
% % TODO: comment/uncomment this section before running script.
pattern_path = "/media/wairimu/Elements2/ch1_usrp/no_pattern";

num_files = 40;
for iteration_ix =1:10

    tensor_fname = ['/home/wairimu/training_data_moving_avg_signal_power/cnn_input_data_' num2str(iteration_ix) '.mat'];
    file_list_name = ['/home/wairimu/training_data_moving_avg_signal_power/file_list_' num2str(iteration_ix) '.mat'];

    preparing_cnn_matrix_1D_fn(pattern_path, tensor_fname, file_list_name, num_files*(iteration_ix-1));

end








% lydia's calling...
% TODO: comment/uncomment this section before running script.
% path = '/Users/lydialonzarich/Desktop/CMU_REUSE/raw-data';

% tensor_fname = '11_cnn_input_data.mat';
% file_list_fname = '11_file_list.mat';

% start_ix = 0;

% preparing_cnn_matrix_1D_fn(path, tensor_fname, file_list_fname, start_ix)
