addpath(genpath("/home/wairimu/leo-signal-proc/file_rw_utils"));
addpath(genpath("/home/wairimu/leo-signal-proc/matlab_utils"));
addpath(genpath("/home/wairimu/leo-signal-proc/plots"));
addpath(genpath("/home/wairimu/leo-signal-proc/"));
% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/cnn_lstm_lr_model/window_downsample_ma_signal_power.m');exit;"

%%
% path = "/media/wairimu/Elements2/fc1075mhz_5sec/plots_done/have_pattern/signal_files/gqrx_20250519_154955_1075059000_2400000_fc.raw";

function [window_tensor, labels_vector] = window_downsample_ma_signal_power_fn(path)
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
    [has_pattern, new_peak_locs, new_peak_vals] = findpeaks_method(path);

    if has_pattern == 1
        disp("has pattern");
        num_windows = length(new_peak_locs);
        num_samples_per_window = int16(12*F_s_downsampled_by_1e6);
        window_tensor = zeros(num_windows, num_samples_per_window);
        labels_vector = ones(num_windows, 1); % Initialize labels vector

        % isolate peaks (window the peaks)
        sorted_locs = sort(new_peak_locs);
        % disp("peak locs:");
        % disp(sorted_locs);

        for loc_ix = 1:num_windows
            start_sec = sorted_locs(loc_ix)-6;
            start_sec = max(start_sec, 0.1);
            end_sec = sorted_locs(loc_ix)+6;
            end_sec = min(end_sec, 60);

            start_ix = max(start_sec*F_s_downsampled_by_1e6, 1);
            end_ix = min(end_sec*F_s_downsampled_by_1e6, length(moving_avg_downsampled_by_1e6));

            % Extract the signal segment for different downsampling extents
            % signal_segment_downsample_by_3 = moving_avg_downsampled_by_3(start_sec*F_s_downsampled_by_3:end_sec*F_s_downsampled_by_3);
            % signal_segment_downsample_by_1e2 = moving_avg_downsampled_by_100(start_sec*F_s_downsampled_by_100:end_sec*F_s_downsampled_by_100);
            signal_segment_downsample_by_1e6 = moving_avg_downsampled_by_1e6(start_ix:end_ix);
            % disp("start ix and end ix: ");
            % disp(start_ix);
            % disp(end_ix);
            % disp("length of signal_segment_downsample_by_1e6:");
            % disp(size(signal_segment_downsample_by_1e6));

            % pad if shorter
            if length(signal_segment_downsample_by_1e6) < num_samples_per_window
                samples_to_pad = num_samples_per_window - length(signal_segment_downsample_by_1e6);
            else
                samples_to_pad = 0;
            end
            signal_segment_downsample_by_1e6 = [signal_segment_downsample_by_1e6; zeros(samples_to_pad, 1, 'like', signal_segment_downsample_by_1e6)]; % pad the signal file. 
            % disp("length of signal_segment_downsample_by_1e6 after padding:");
            % disp(size(signal_segment_downsample_by_1e6));
            % 
            window_tensor(loc_ix, :) = signal_segment_downsample_by_1e6;

            fig = figure("Visible", "off");
            plot(signal_segment_downsample_by_1e6); 
            title('has pattern');
            xlabel('Time (seconds)');
            ylabel('normalized moving avg power');
            path = char(path);

            plot_fname = strcat("/home/wairimu/plots_folder/has_pattern/", path(60:65), "_window_", num2str(loc_ix), ".png");
            exportgraphics(fig, plot_fname);        
        end

    else
        disp("no pattern");
        path = char(path);

        fig = figure("Visible", "off");
        plot(moving_avg_downsampled_by_1e6); 
        title('has pattern');
        xlabel('Time (seconds)');
        ylabel('normalized moving avg power');
        path = char(path);
        plot_fname = strcat("/home/wairimu/plots_folder/no_pattern/", path(60:65), "_full_moving_avg.png");
        exportgraphics(fig, plot_fname); 

        num_samples_per_window = int8(12*F_s_downsampled_by_1e6);
        % 
        % disp(num_samples_per_window);
        % disp("length of moving_avg_downsampled_by_1e6:");
        % disp(length(moving_avg_downsampled_by_1e6));

        num_windows = idivide(length(moving_avg_downsampled_by_1e6), num_samples_per_window);
        % disp("number of windows:");
        % disp(num_windows);
        % disp("moving avg before clipping: ");

        % disp(moving_avg_downsampled_by_1e6);

        moving_avg_downsampled_by_1e6 = moving_avg_downsampled_by_1e6(1:int16(num_windows)*int16(num_samples_per_window));
        % disp("moving avg after clipping: ");
        % disp(moving_avg_downsampled_by_1e6);
        % window_tensor = reshape(moving_avg_downsampled_by_1e6, num_windows, num_samples_per_window);
        window_tensor = reshape(moving_avg_downsampled_by_1e6, num_samples_per_window, num_windows);
        window_tensor = window_tensor.';


        % window_tensor = resize(moving_avg_downsampled_by_1e6, [2 3]);
        % disp("window tensor: ");
        % disp(window_tensor);

        labels_vector = zeros(num_windows, 1); % Initialize labels vector
        % plotting
        for loc_ix = 1:num_windows
            signal_segment_downsample_by_1e6 = window_tensor(loc_ix, :);

            fig = figure("Visible", "off");
            plot(signal_segment_downsample_by_1e6); 
            title('has pattern');
            xlabel('Time (seconds)');
            ylabel('normalized moving avg power');
            path = char(path);
            plot_fname = strcat("/home/wairimu/plots_folder/no_pattern/", path(60:65), "_window_", num2str(loc_ix), ".png");
            exportgraphics(fig, plot_fname);      
        end
    end
    disp("size of window tensor:");
    disp(size(window_tensor));
end
    
pattern_path = "/media/wairimu/Elements2/ch1_usrp/no_pattern";

dirlist = dir(pattern_path);
T = struct2table(dirlist);
sortedTable = sortrows(T, 3);
dirlist = table2struct(sortedTable);

window_tensor_concat = 0;
labels_concat = 0;

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
    % fname = '/media/wairimu/Elements2/ch1_usrp/no_pattern/gqrx_20250519_192317_1075059000_2400000_fc.raw';
    [window_tensor, labels_vector] = window_downsample_ma_signal_power_fn(fname);
    if window_tensor_concat == 0
        window_tensor_concat = window_tensor;
        labels_concat = labels_vector;
    else
        window_tensor_concat = [window_tensor_concat; window_tensor];
        labels_concat = [labels_concat; labels_vector];
    end

end

save("/home/wairimu/window_tensor_concat.mat", "window_tensor_concat");
save("/home/wairimu/labels_concat.mat", "labels_concat");
