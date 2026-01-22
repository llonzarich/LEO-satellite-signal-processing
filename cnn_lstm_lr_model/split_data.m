function [train_files, val_files, test_files, num_train_files, num_val_files, num_test_files] = split_data(file_list, num_files)

% ------------------------------------------------------------------------
% purpose: split all files into train/val/test sets
% ------------------------------------------------------------------------


% define split parameters
train_ratio = 0.55;
val_ratio = 0.15;
test_ratio = 0.3;
rng(42);


% collect all file indices, but shuffled
shuffled_indices = randperm(num_files);


% determine the number of files that will be put into each set.
num_train_files = round(train_ratio * num_files);
num_val_files = round(val_ratio * num_files);
num_test_files = num_files - num_train_files - num_val_files;
disp("number of training set files: " + num_train_files)
disp("number of val set files: " + num_val_files)
disp("number of test set files: " + num_test_files)


% determine indices of train, val, and test sets
train_indices = shuffled_indices(1:num_train_files);
val_indices = shuffled_indices(num_train_files + 1:num_train_files + num_val_files);
test_indices = shuffled_indices(num_train_files + num_val_files + 1:end);


% allocate files to each set using indices.
train_files = file_list(train_indices);
val_files = file_list(val_indices);
test_files = file_list(test_indices);

