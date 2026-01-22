addpath(genpath("/home/wairimu/leo-signal-proc/file_rw_utils"));
addpath(genpath("/home/wairimu/leo-signal-proc/matlab_utils"));
addpath(genpath("/home/wairimu/leo-signal-proc/plots"));
addpath(genpath("/home/wairimu/leo-signal-proc/"));
% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/cnn_lstm_lr_model/test_window_downsample_ma_signal_power.m');exit;"

%%
% path = "/media/wairimu/Elements2/fc1075mhz_5sec/plots_done/have_pattern/signal_files/gqrx_20250519_154955_1075059000_2400000_fc.raw";

function segmented_signal = test_window_downsample_ma_signal_power_fn(path)
    F_s = 2.4e6; % wideband signal sampling frequency
    pattern_length = 5;
    n_samples_per_pattern = pattern_length * F_s;
    y = read_complex_binary(path); 
    disp(path);

    signal_power = abs(y).^2; % Calculate signal power
    moving_avg_power = movmean(signal_power, n_samples_per_pattern);
    moving_avg_power = normalize(moving_avg_power, "range", [0 1]);

    % F_s_downsampled_by_3 = 2.4e6/3;
    % F_s_downsampled_by_100 = 2.4e6/100;
    F_s_downsampled_by_1e6 = 2.4e6/1e6;

    % moving_avg_downsampled_by_3 = downsample(moving_avg_power, 3);
    % moving_avg_downsampled_by_100 = downsample(moving_avg_power, 100);
    moving_avg_downsampled_by_1e6 = downsample(moving_avg_power, 1e6);

    % [~, has_pattern, ~, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk] = A5_isolate_pattern(path);
    % [has_pattern, new_peak_locs, new_peak_vals] = findpeaks_method(path);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Define segment length and overlap
    segment_duration = 12; % seconds
    overlap_duration = 11; % seconds (adjust as needed for your desired overlap)

    % Convert durations to samples
    segment_length = int8(segment_duration * F_s_downsampled_by_1e6);
    overlap_samples = int8(overlap_duration * F_s_downsampled_by_1e6);

    % Use buffer to create overlapping segments
    segmented_signal = buffer(moving_avg_downsampled_by_1e6, segment_length, overlap_samples);
    segmented_signal = segmented_signal.';
    % 'segmented_signal' will be a matrix where each column represents a 10-second segment.
    % The rows represent the samples within each segment.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % disp("Fs:");
    % disp(F_s_downsampled_by_1e6)
    % disp("segment length:");
    % disp(segment_length);
    % disp("overlap duration:");
    % disp(overlap_samples);
    % disp("size of segmented signal:");
    % disp(size(segmented_signal));

    % pause
end

% save one file at a time
path = "/media/wairimu/Elements1/24hr_recording";

dirlist = dir(path);
T = struct2table(dirlist);
sortedTable = sortrows(T, 3);
dirlist = table2struct(sortedTable);
for dir_ix = 1:length(dirlist)
    file = dirlist(dir_ix);
    % file = dir(fname_preamble_signal);
    if file.name == "." || file.name == ".." || file.isdir 
        continue
    end
    ext= file.name(end-3:end);
    if ext ~= ".raw" 
        continue
    end
    file_id = file.name(15:20);

    fname = strcat(file.folder, "/", file.name);
    disp(fname);
    segmented_test_signal = test_window_downsample_ma_signal_power_fn(fname);

    save(strcat("/home/wairimu/training_data_corrected_windowing/test_files/24hr_recording/segmented_test_signal_", file_id, ".mat"), "segmented_test_signal");

end

% save multiple files