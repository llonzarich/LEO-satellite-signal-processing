% -------------------------------------------------------------------------------------------------------
% purpose: prepares the 1D input data for the CNN.
% 
% outputs: - a .mat file (to give the CNN) for training, which includes...
%            (1) a 4D tensor with shape: [num_files, num_windows, num_samples_per_window, num_channels=2])
%            (2) file-level labels (0 or 1).
% -------------------------------------------------------------------------------------------------------


% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/cnn_lstm_lr_model/preparing_cnn_matrix_1D.m');exit;"
function preparing_cnn_matrix_1D_fn(path, tensor_fname, file_list_fname, start_ix)
% function preparing_cnn_matrix_1D_fn(path, tensor_fname, start_ix)
    
    % signal parameters
    F_s = 2.4e6;
    


    % "grab" all .raw files.
    iq_signal_dir = dir(fullfile(path, '**', '*.raw'));
    num_files = length(iq_signal_dir);
    % num_files = 40;
    fprintf("Found %d .raw files in the iq signal dir .\n", num_files); % ==> the number of iq files in the hard drive.


    % % dynamically find the number samples expected per file (considering downsampling) (necessary to initalize the 4D tensor).
    % first_file = iq_signal_dir(1);
    % disp("first file: " + first_file.name)
    % num_samples_per_first_file.bytes
    

    % initalize a 3D tensor for the CNN feature input.
    cnn_input = cell(num_files, 1);


    % initialize a vector to store file-level labels (0 or 1). 
    labels_vector = zeros(num_files, 1);

    
    % initialize a cell array to store filenames in the same order as the labels.
    file_list = cell(num_files, 1);


    % define start and end idx.
    % if start_ix == 0
    %     start_ix = 1;
    %     end_ix = num_files;
    % else 
    %     end_ix = start_ix + num_files;
    % end
    start_ix = 4;
    end_ix = 4;


    % iterate through all iq signal files to fill its entry in the 3D 'cnn_input' tensor and assign it a corresponding label (0 or 1).
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


        % (1) determine start/end times of the section of the signal file that contains pattern (pattern = at least 2 consecutive 10ish sec spikes).
        % (2) determine determine whether the signal file has a pattern.
        [actual_dur_sec, has_pattern, ~, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk] = isolate_pattern(filepath);


        
        % assign file-level label based on the boolean variable, 'has_pattern'.
        if has_pattern
            labels_vector(i) = 1;
            disp("file has pattern :)")
        else
            labels_vector(i) = 0;
            disp("file doesn't have pattern :(")
        end

        
        % trim signal (IF there are at least 2 consecutive 10ish sec spikes)
        trimmed_signal = trim_file(filepath, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk, F_s);
        

        % compute the signal power of the trimmed signal (the signal isn't trimmed if there is no pattern).
        i = trimmed_signal(:, 1);
        q = trimmed_signal(:, 2);
        signal_power = i.^2 + q.^2;

        
        % append the signal power to the cnn_input cell array.
        cnn_input{i} = signal_power;

    end


    % save features (signal power) and labels vector to a .mat file.
    save(tensor_fname, 'cnn_input', 'labels_vector')


    % save the file list cell array to a .mat file.
    save(file_list_fname, 'file_list')

end


% % Veronica's calling...
% % define paths to .raw files.
% % has_pattern_path = '/media/wairimu/Elements2/fc1075mhz_5sec/plots_done/have_pattern/signal_files';
% pattern_path = "/media/wairimu/Elements2/ch1_usrp/no_pattern";
% 
% % file_list_name3 = '/home/wairimu/file_list3.mat';
% 
% 
% num_files = 40;
% for iteration_ix = 1:10
% 
%     tensor_fname = ['/home/wairimu/training_files/cnn_input_data_' num2str(iteration_ix) '.mat'];
%     file_list_name = ['/home/wairimu/file_list_' num2str(iteration_ix) '.mat'];
% 
%     preparing_cnn_matrix_1D_fn(pattern_path, tensor_fname, file_list_name, num_files*(iteration_ix-1));
% 
% end


% % Veronica's calling...
% % define paths to .raw files.
% has_pattern_path = '/media/wairimu/Elements2/fc1075mhz_5sec/plots_done/have_pattern/signal_files';
% no_pattern_path = '/media/wairimu/Elements2/fc1075mhz_5sec/plots_done/no_pattern/signal_files';
% 
% % define output file paths and names for tensor .mat files (have 'cnn_input', 'label_vector', and 'file_list' elements).
% tensor_fname_has_pattern = '/home/wairimu/cnn_input_data_has_pattern_updated.mat';
% tensor_fname_has_pattern2 = '/home/wairimu/cnn_input_data_has_pattern_updated2.mat';
% tensor_fname_no_pattern = '/home/wairimu/cnn_input_data_no_pattern_updated.mat';
% tensor_fname_no_pattern2 = '/home/wairimu/cnn_input_data_no_pattern_updated2.mat';
% 
% % function call ==> 1 .mat file with a filled 4D feature tensor, labels vector, and list of filenames for each subset of data.
% preparing_cnn_matrix_1D_fn(has_pattern_path, tensor_fname_has_pattern, file_list_name_has_pattern, 1);
% preparing_cnn_matrix_1D_fn(has_pattern_path, tensor_fname_has_pattern2, file_list_name_has_pattern2, 40);
% preparing_cnn_matrix_1D_fn(no_pattern_path, tensor_fname_no_pattern, file_list_name_no_pattern, 1);
% preparing_cnn_matrix_1D_fn(no_pattern_path, tensor_fname_no_pattern2, file_list_name_no_pattern2, 40);









% lydia's calling...
path = "/Volumes/PARTITION3/fc1075mhz_5sec_akirah/no_pattern";

tensor_fname = '2_cnn_input_data.mat';
file_list_fname = '2_file_list.mat';

start_ix = 1;

preparing_cnn_matrix_1D_fn(path, tensor_fname, file_list_fname, start_ix)

