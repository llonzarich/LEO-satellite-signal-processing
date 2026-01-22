% -------------------------------------------------------------------------------------------------------
% purpose: combines all .mat files for the cnn_input_data.mat files.
% 
% assumptions: 'preparing_cnn_matrix_1D_fn.m' saves 1 .mat files per subset of data...
%               (1) 'cnn_input_data.mat': contains 'cnn_input', 'labels_vector', and 'file_list' (list of filenames)
% -------------------------------------------------------------------------------------------------------


% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/cnn_lstm_lr_model/concatenate_tensors.m');exit;"


function concatenate_tensors_fn(fnames)
    
    % get the number of files.
    num_files = length(fnames);


    % initalize empty arrays.
    combined_cnn_input = [];
    combined_labels_vector = [];
    combined_file_list = {};


    for i = 1:num_files
        M = load(sprintf('cnn_input_subset%d.mat', i));

        combined_cnn_input = cat(1, combined_cnn_input, M.cnn_input);
        combined_labels_vector = cat(1, combined_labels_vector, M.labels_vector);
        combined_file_list = [combined_file_list; M.file_list];
    end


    % save the concatenated cnn_input_data.mat files.
    save('/home/wairimu/cnn_input_data_updated.mat', 'combined_cnn_input', 'combined_labels_vector', 'combined_file_list');


end


% define paths to cnn_input 
tensor_fname_has_pattern = "/home/wairimu/cnn_input_data_has_pattern_updated.mat";
tensor_fname_has_pattern2 = '/home/wairimu/cnn_input_data_has_pattern_updated2.mat';
tensor_fname_no_pattern = '/home/wairimu/cnn_input_data_no_pattern_updated.mat';
tensor_fname_no_pattern2 = '/home/wairimu/cnn_input_data_no_pattern_updated2.mat';

tensor_fnames = [tensor_fname_has_pattern tensor_fname_has_pattern2 tensor_fname_no_pattern tensor_fname_no_pattern2];

% concatenate .mat files.
concatenate_tensors_fn(tensor_fnames, -1);
concatenate_tensors_fn(file_list_names, 0);


pattern_path = "/media/wairimu/Elements2/ch1_usrp/no_pattern";
num_files = 40;

for iteration_ix = 1:10
    
    tensor_fname = ['/home/wairimu/training_data_stricter_classification_method/cnn_input_data_' num2str(iteration_ix) '.mat'];
    file_list_name = ['/home/wairimu/training_data_stricter_classification_method/file_list_' num2str(iteration_ix) '.mat'];

    concatenate_tensors_fn
end

