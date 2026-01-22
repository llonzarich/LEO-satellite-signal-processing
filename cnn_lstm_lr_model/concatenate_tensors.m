% -------------------------------------------------------------------------------------------------------
% purpose: combines all .mat files for the cnn_input_data.mat files and the file_list.mat files.
% 
% assumptions: 'preparing_cnn_matrix_1D_fn.m' saves 2 .mat files per subset of data...
%               (1) 'cnn_input_data.m': contains 'cnn_input' and 'labels_vector'
%               (2) 'file_list.m': contains 'file_list' (array of file names).
% -------------------------------------------------------------------------------------------------------


% this function combines all .mat files for the cnn_input_data.mat files and the file_list.mat files.
% assumption: 'preparing_cnn_matrix_1D_fn.m' saves 2 .mat files per subset of data: .

% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/cnn_lstm_lr_model/concatenate_tensors.m');exit;"
function concatenate_tensors_fn(fnames, file_names, working_folder)
    
    % get the number of files.
    num_files = length(fnames);


    % concatenate cnn_input_data.mat files
    if file_names == -1
        % initialize an empty array to store concatenated 4D feature tensors ('cnn_input') and 'labels_vector' (no cell array because we only have numeric values).
        combined_cnn_input = [];
        combined_labels_vector = [];
        disp("combining cnn input data...");
        for i =1:num_files
            M = load(fnames(i));
            
            combined_cnn_input = cat(1, combined_cnn_input, M.cnn_input);
            combined_labels_vector = cat(1, combined_labels_vector, M.labels_vector);
            disp(i);
        end
        
        save([working_folder '/cnn_input_data.mat'], 'combined_cnn_input', 'combined_labels_vector');


    % concatenate file_list.mat files
    else
        % initialize an empty cell array to concatenate file names (use cell array because we have strings).
        combined_file_list = {};
        disp("combining file names...");
        for i =1:num_files
            M = load(fnames(i));

            combined_file_list = [combined_file_list; M.file_list];
            disp(i);
        end

        % save the concatenated file_list.mat files.
        save([working_folder '/file_names.mat'], 'combined_file_list');
        % save('/home/wairimu/training_files/file_names.mat', 'combined_file_list');
   
    end
end

NUM_FILES_TO_CONCATENATE = 10; % number of files to concatenate. 

tensor_fnames = strings(NUM_FILES_TO_CONCATENATE, 1);
file_list_names = strings(NUM_FILES_TO_CONCATENATE, 1);
working_folder = '/home/wairimu/training_files_approach_7/';

% for iteration_ix = 1:10
for iteration_ix = 1:NUM_FILES_TO_CONCATENATE
    
    tensor_fname = strcat("/home/wairimu/training_files_approach_7/cnn_input_data_", num2str(iteration_ix), ".mat");
    file_list_name = strcat("/home/wairimu/training_files_approach_7/file_list_", num2str(iteration_ix), ".mat");
    % tensor_fname = strcat("/home/wairimu/training_files/cnn_input_data_", num2str(iteration_ix), ".mat");
    % file_list_name = strcat("/home/wairimu/training_files/file_list_", num2str(iteration_ix), ".mat");

    tensor_fnames(iteration_ix) = tensor_fname;
    file_list_names(iteration_ix) = file_list_name;
    disp(iteration_ix);
end


% concatenate cnn_input_data.mat files
concatenate_tensors_fn(tensor_fnames, -1, working_folder);


% concatenate file_list.mat files
concatenate_tensors_fn(file_list_names, 0, working_folder);