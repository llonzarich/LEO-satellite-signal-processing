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


    % initalize a 3D tensor array for the CNN input.
    num_samples_per_file = 122090001;
    num_features = 2; % I and Q channels.
    cnn_input = zeros(num_files, num_samples_per_file, num_features);
    disp("size of 2D feature tensor CNN input:")
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
        % also get the start/end times of the 36sec pattern chunk
        [~, has_pattern, ~, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk] = A2_isolate_pattern(filepath);

        
        % assign file-level label based on the boolean variable, 'has_pattern'.
        if has_pattern
            labels_vector(i) = 1;
            disp("file has pattern :)")
        else
            labels_vector(i) = 0;
            disp("file doesn't have pattern :(")
        end

        
        % trim the signal file to be the 36 seconds.
        trimmed_file = A2_trim_file(filepath, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk, F_s);


        num_samples_trimmed_file = length(trimmed_file);
        % disp("number of samples in trimmed file: " + num_samples_trimmed_file)

        % initialize a 2D array to store I and Q components as separate channels.
        iq_components = zeros(num_samples_trimmed_file, 2);


        % get I and Q components of each sample in signal file
        iq_components(:, 1) = real(trimmed_file); % i channel.
        iq_components(:, 2) = imag(trimmed_file); % q channel.


        cnn_input(i, :, 1) = iq_components(:, 1); % i component.
        cnn_input(i, :, 2) = iq_components(:, 2); % q component.
        
    end


    % sanity check
    disp("size of 2D feature tensor CNN input:")
    disp(size(cnn_input))


    % save the 2D features tensor and labels vector to a .mat file.
    save(tensor_fname, 'cnn_input', 'labels_vector')


    % save the file list cell array to a .mat file.
    save(file_list_fname, 'file_list')

end


% % % Veronica's calling...
% % TODO: comment/uncomment this section before running script.
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

tensor_fname = '2_cnn_input_data.mat';
file_list_fname = '2_file_list.mat';

start_ix = 0;

preparing_cnn_matrix_1D_fn(path, tensor_fname, file_list_fname, start_ix)
