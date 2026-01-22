% -------------------------------------------------------------------------------------------------------
% purpose: combines all .mat files each training set into combined .mat files per set
% 
% assumptions: 'A_8_preparing_cnn_matrix_1D_fn.m' saves 3 .mat files - 1 for each train/val/test set. per subset of data...
%               (1) 'cnn_input_data_train.mat': contains 'cnn_input_train', 'window_labels_train', and 'train_files'.
%               (2) 'cnn_input_data_val.mat': contains 'cnn_input_val', 'window_labels_val', and 'val_files'.
%               (3) 'cnn_input_data_test.mat': contains 'cnn_input_test', 'window_labels_test', and 'test_files'.
% -------------------------------------------------------------------------------------------------------

% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/cnn_lstm_lr_model/concatenate_tensors.m');exit;"
function concatenate_tensors_fn(fnames, set, working_folder)
    
    % get the number of files.
    num_files = length(fnames);


    % concatenate cnn_input_data_train.mat files
    if set == 0
        
        combined_cnn_input_train = [];
        combined_window_labels_train = [];
        combined_train_files = {};

        disp("combining .mat files for training data...")

        for i = 1:num_files
            M = load(fnames(i));

            combined_cnn_input_train = cat(1, combined_cnn_input_train, M.cnn_input_train);
            combined_window_labels_train = cat(1, combined_window_labels_train, M.window_labels_train);
            combined_train_files = [combined_train_files; M.train_files];
            
            disp(i)
        end
        
        save([working_folder '/cnn_input_data_train.mat'], 'combined_cnn_input_train', 'combined_window_labels_train', 'combined_train_files');


    % concatenate cnn_input_data_val.mat files
    elseif set == 1

        combined_cnn_input_val = [];
        combined_window_labels_val = [];
        combined_val_files = {};

        disp("combining .mat files for val data...")

        for i = 1:num_files
            M = load(fnames(i));

            combined_cnn_input_val = cat(1, combined_cnn_input_val, M.cnn_input_val);
            combined_window_labels_val = cat(1, combined_window_labels_val, M.window_labels_val);
            combined_val_files = [combined_val_files; M.val_files];
            
            disp(i)
        end
        
        save([working_folder '/cnn_input_data_val.mat'], 'combined_cnn_input_val', 'combined_window_labels_val', 'combined_val_files');


    % concatenate cnn_input_data_test.mat files
    else
        
        combined_cnn_input_test = [];
        combined_window_labels_test = [];
        combined_test_files = {};

        disp("combining .mat files for training data...")

        for i = 1:num_files
            M = load(fnames(i));

            combined_cnn_input_test = cat(1, combined_cnn_input_test, M.cnn_input_test);
            combined_window_labels_test = cat(1, combined_window_labels_test, M.window_labels_test);
            combined_train_files = [combined_test_files; M.test_files];
            
            disp(i)
        end
        
        save([working_folder '/cnn_input_data_test.mat'], 'combined_cnn_input_test', 'combined_window_labels_test', 'combined_test_files');
       
    end
end


NUM_FILES_TO_CONCATENATE = 10; % number of files to concatenate. 


train_fnames = strings(NUM_FILES_TO_CONCATENATE, 1);
val_fnames = strings(NUM_FILES_TO_CONCATENATE, 1);
test_fnames = strings(NUM_FILES_TO_CONCATENATE, 1);
working_folder = 'fill in your path to folder';


% fill each file list with file names
for iteration_ix = 1:NUM_FILES_TO_CONCATENATE
    
    train_fname = strcat("fill in your path to .mat file. should end in .../cnn_input_data_train_", num2str(iteration_ix), ".mat");
    val_fname = strcat("fill in your path to .mat file. should end in /cnn_input_data_val_", num2str(iteration_ix), ".mat");
    test_fname = strcat("fill in your path to .mat file. should end in /cnn_input_data_test_", num2str(iteration_ix), ".mat");

    train_fnames(iteration_ix) = train_fname;
    val_fnames(iteration_ix) = val_fname;
    test_fnames(iteration_ix) = test_fname;
    disp(iteration_ix);

end


% concatenate cnn_input_data_train.mat files
concatenate_tensors_fn(train_fnames, 0, working_folder);

% concatenate cnn_input_data_val.mat files
concatenate_tensors_fn(val_fnames, 1, working_folder);

% concatenate cnn_input_data_test.mat files
concatenate_tensors_fn(test_fnames, 2, working_folder);