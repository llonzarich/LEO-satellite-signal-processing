% -------------------------------------------------------------------------------------------------------
% purpose: prepares the 1D input data for the CNN.
%
% update: this script references the folder a .raw file is in ('has_pattern' vs 'no_pattern') in order to assign its file-level label. 
%
% outputs: - a .mat file (to give the CNN) for training, which includes:
%            (1) a 4D tensor with shape: [num_files, num_windows, num_samples_per_window, num_channels=2])
%            (2) file-level labels (0 or 1).
% -------------------------------------------------------------------------------------------------------


% signal parameters
F_s = 2.4e6;


% "grab" all .raw files.
path1 = "/Volumes/PARTITION3/fc1075mhz_5sec_akirah/has_pattern"; % path to 'has_pattern' .raw files
path2 = "/Volumes/PARTITION3/fc1075mhz_5sec_akirah/no_pattern"; % path to 'no_pattern' .raw files.

iq_signal_dir1 = dir(fullfile(path1, '**', '*.raw')); % all .raw files in the 'has_pattern' folder.
iq_signal_dir2 = dir(fullfile(path2, '**', '*.raw')); % all .raw files in the 'no_pattern' folder.

all_iq_signal_files = [iq_signal_dir1; iq_signal_dir2];

num_files = length(all_iq_signal_files);
fprintf("Found %d .raw files in the iq signal dir .\n", num_files); % ==> the number of iq files in the hard drive.


% hard code the number of windows I want and the number of samples expected per window (considering downsampling) (necessary to initalize the 4D tensor.
num_windows = 11;
window_samples = 24000;


% initalize a 4D tensor array for the CNN input.
cnn_input = zeros(num_files, num_windows, window_samples, 2);


% initialize a vector to store file-level labels (0 or 1). 
labels_vector = zeros(num_files, 1);


% iterate through all iq signal files to fill its entry in the 4D 'cnn_input tensor and assign it a corresponding label (0 or 1). 
% for i = 1:num_files
for i = 22:22
% for i = [1, 5, 11, 12, 13]

    file = all_iq_signal_files(i); % 'file' holds the properties of the i-th file in the .raw IQ signal file directory. Use file.name to see the full .raw IQ filename.
    % disp(file)

    
    % if the signal file is from the 'has_pattern' folder, assign it label = 1.
    if contains(file.folder, 'has_pattern')
        labels_vector(i) = 1;
        disp("file has pattern :)")
    end


    % if the signal file is from the 'no_pattern' folder, assign it label = 0.
    if contains(file.folder, 'no_pattern')
        labels_vector(i) = 0;
        disp("file doesn't have pattern :(")
    end


    file_id = file.name(15:20) + ".raw"; % 6 digit file id.
    disp("6 digit file id: " + file_id)


    if strcmp(file.name, '.') || strcmp(file.name, '..') || file.isdir
        continue
    end
    [~, ~, ext] = fileparts(file.name);
    if ~strcmp(ext, '.raw')
        continue
    end


    filepath = fullfile(file.folder, file.name);
    % disp("filepath: " + filepath)


    % determine whether the signal file has a pattern (using an older script so I'm just ignoring some of the outputs).
    [~, has_pattern, ~, ~, ~] = isolate_pattern(filepath);


    % split the signal into 11 10-second windows. 
    [signal_windows, num_windows, window_samples, iq_components] = window_signal(filepath);
    % disp("signal windows (downsampled by a factor of 1000):")
    % disp(signal_windows)
    disp("number of windows: " + num_windows)
    disp("number of samples in each window: " + window_samples)
    disp("size of iq_components for iteration " + i + ": ")
    disp(size(iq_components))


    % stack the real and imaginary components of the signal file.
    for j = 1:num_windows

        cnn_input(i, j, :, 1) = iq_components(:, 1, j); % i component.
        cnn_input(i, j, :, 2) = iq_components(:, 2, j); % q component.

    end

end


% sanity check
disp("size of 4D tensor CNN input:")
disp(size(cnn_input))


save('TEST_cnn_input_data.mat', 'cnn_input', 'labels_vector')
