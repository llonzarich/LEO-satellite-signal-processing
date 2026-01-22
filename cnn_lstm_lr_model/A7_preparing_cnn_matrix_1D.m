% -------------------------------------------------------------------------------------------------------
% purpose: prepares the input data for the CNN.
%
% Logic: (1) call 'thirtysixsec_isolate_pattern.m' -- get start sec, end sec, and file-level label of a trimmed signal file (36 sec) (determine start/end sec of trimmed file according to consecutive pattern chunks).
%        (2) call 'trim_file.m' -- actually trim the signal file to be seconds.
%        (3) call 'thirtysixsec_window_signal.m' -- split the 36sec signal into sequences of overlapping same-size windows.
%        (4) fill and save 'cnn_input' 4D tensor, 'labels_vector', and 'files_list' to .mat files.
% 
% outputs: - a .mat file (to give the CNN) for training, which includes...
%            (1) a 4D tensor with shape: [num_files, num_windows, num_samples_per_window, num_channels=2])
%            (2) file-level labels (0 or 1).
%          - a .mat file for training, which includes...
%            (1) filenames (to make sure I train-val-test set split along the file axis -- not splitting up a file's windows.
% -------------------------------------------------------------------------------------------------------


% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/cnn_lstm_lr_model/thirtysixsec_preparing_cnn_matrix_1D.m');exit;"
function preparing_cnn_matrix_1D_fn(path, tensor_fname, file_list_fname, start_ix)
% function preparing_cnn_matrix_1D_fn(path, tensor_fname, start_ix)
    
    % signal parameters
    F_s = 2.4e6;
    

    % "grab" all .raw files.
    iq_signal_dir = dir(fullfile(path, '**', '*.raw'));
    % num_files = length(iq_signal_dir); %TODO:change 
    num_files = 1; % TODO: change
    fprintf("Found %d .raw files in the iq signal dir .\n", num_files); 


    % manually assign the number of windows and samples expected per window (considering downsampling) (necessary to initalize the 4D tensor).
    num_windows = 35;
    window_samples = 4800;
    num_features = 2; % i and q channels.


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
        end_ix = num_files; % TODO: change to/from 'num_files'.
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
        [~, has_pattern, ~, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk] = A7_isolate_pattern(filepath);

        
        % assign file-level label based on the boolean variable, 'has_pattern'.
        if has_pattern
            labels_vector(i) = 1;
            disp("file has pattern :)")
        else
            labels_vector(i) = 0;
            disp("file doesn't have pattern :(")
        end

        
        % trim the signal file to be the 36 seconds.
        trimmed_file = A7_trim_file(filepath, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk, F_s);


        % split the signal into 35 2sec windows w/ 1sec stride. 
        [~, num_windows, ~, iq_components] = A7_window_signal(trimmed_file);
        % disp("signal windows (downsampled by a factor of 1000):")
        % disp(signal_windows)
        disp("number of windows for file " + i + ": " + num_windows)
        disp("number of samples in each window: " + window_samples)
        % disp("size of iq_components for iteration " + i + ": ")
        % disp(size(iq_components))


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
% pattern_path = "/media/wairimu/Elements2/ch1_usrp/no_pattern";
% 
% % file_list_name3 = '/home/wairimu/file_list3.mat';
% 
% 
% num_files = 40;
% for iteration_ix =1:10
% 
%     tensor_fname = ['/home/wairimu/training_files_approach_7/cnn_input_data_' num2str(iteration_ix) '.mat'];
%     file_list_name = ['/home/wairimu/training_files_approach_7/file_list_' num2str(iteration_ix) '.mat'];
% 
%     preparing_cnn_matrix_1D_fn(pattern_path, tensor_fname, file_list_name, num_files*(iteration_ix-1));
% 
% end




% lydia's calling...
path = '/Users/lydialonzarich/Desktop/CMU_REUSE/raw-data';

tensor_fname = '10_cnn_input_data.mat';
file_list_fname = '10_file_list.mat';

start_ix = 0;

preparing_cnn_matrix_1D_fn(path, tensor_fname, file_list_fname, start_ix)
