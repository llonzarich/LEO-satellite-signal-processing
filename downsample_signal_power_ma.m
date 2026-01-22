addpath(genpath("/home/wairimu/leo-signal-proc/file_rw_utils"));
addpath(genpath("/home/wairimu/leo-signal-proc/matlab_utils"));
addpath(genpath("/home/wairimu/leo-signal-proc/plots"));
addpath(genpath("/home/wairimu/leo-signal-proc/"));
% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/read_and_plot_signal.m');exit;"

%%
path = "/media/wairimu/Elements2/fc1075mhz_5sec/plots_done/have_pattern/signal_files/gqrx_20250519_154955_1075059000_2400000_fc.raw";
% wideband signal -- since these files are large, read only a chunk at a time
% format: read_complex_binary(path_to_file, start, count)
% every second, 100e6 samples are recorded, with 8 bytes per sample
% so the following command reads from the 3rd second, and reads 1 second worth of data
F_s = 2.4e6; % wideband signal sampling frequency
n_samples_per_pattern = 5*2.4e6;
y = read_complex_binary(path); 


signal_power = abs(y).^2; % Calculate signal power
moving_avg_power = movmean(signal_power, n_samples_per_pattern);
moving_avg_power = normalize(moving_avg_power, "range", [0 1]);

fig1 = figure("visible", "off");
% [pks,locs] = findpeaks(moving_avg_power);
plot(moving_avg_power);
grid on;
shg;
exportgraphics(fig1, "/home/wairimu/plots_folder/moving_avg_power.png", "Resolution", 300);

% [~, has_pattern, ~, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk] = A5_isolate_pattern(path);
[has_pattern, new_peak_locs, new_peak_vals] = findpeaks_method(path);

% isolate peaks (window the peaks)
sorted_locs = sort(new_peak_locs);
disp("peak locs:");
disp(sorted_locs);
moving_avg_downsampled_by_3 = downsample(moving_avg_power, 3);
moving_avg_downsampled_by_100 = downsample(moving_avg_power, 100);
moving_avg_downsampled_by_1e6 = downsample(moving_avg_power, 1e6);

F_s_downsampled_by_3 = 2.4e6/3;
F_s_downsampled_by_100 = 2.4e6/100;
F_s_downsampled_by_1e6 = 2.4e6/1e6;

fig = figure("visible", "off");
% [pks,locs] = findpeaks(moving_avg_power);
plot(moving_avg_downsampled_by_3);
grid on;
shg;
exportgraphics(fig, "/home/wairimu/plots_folder/moving_avg_downsampled_by_3.png", "Resolution", 300);

fig = figure("visible", "off");
% [pks,locs] = findpeaks(moving_avg_power);
plot(moving_avg_downsampled_by_100);
grid on;
shg;
exportgraphics(fig, "/home/wairimu/plots_folder/moving_avg_downsampled_by_100.png", "Resolution", 300);

fig = figure("visible", "off");
% [pks,locs] = findpeaks(moving_avg_power);
plot(moving_avg_downsampled_by_1e6);
grid on;
shg;
exportgraphics(fig, "/home/wairimu/plots_folder/moving_avg_downsampled_by_1e6.png", "Resolution", 300);

for loc_ix = 1:length(sorted_locs)
    start_sec = sorted_locs(loc_ix)-6;
    start_sec = max(start_sec, 0.1);
    end_sec = sorted_locs(loc_ix)+6;
    end_sec = min(end_sec, 60);
    disp("start sec: ")
    disp(start_sec)
    disp("end sec: ")
    disp(end_sec)
    
    % Extract the signal segment based on the identified start and end seconds
    signal_segment = moving_avg_downsampled_by_3(start_sec*F_s_downsampled_by_3:end_sec*F_s_downsampled_by_3);
    disp(end_sec*F_s_downsampled_by_3);
    disp(start_sec*F_s_downsampled_by_3);
    fig2 = figure("visible", "off");
    % [pks,locs] = findpeaks(moving_avg_power);
    plot(signal_segment);
    grid on;
    shg;
    exportgraphics(fig2, strcat("/home/wairimu/plots_folder/peak",num2str(loc_ix),"_downsampled_by_3.png"), "Resolution", 300);

    signal_segment = moving_avg_downsampled_by_100(start_sec*F_s_downsampled_by_100:end_sec*F_s_downsampled_by_100);
    disp(end_sec*F_s_downsampled_by_100);
    disp(start_sec*F_s_downsampled_by_100);
    fig2 = figure("visible", "off");
    % [pks,locs] = findpeaks(moving_avg_power);
    plot(signal_segment);
    grid on;
    shg;
    exportgraphics(fig2, strcat("/home/wairimu/plots_folder/peak",num2str(loc_ix),"_downsampled_by_100.png"), "Resolution", 300);

    signal_segment = moving_avg_downsampled_by_1e6(start_sec*F_s_downsampled_by_1e6:end_sec*F_s_downsampled_by_1e6);
    disp(end_sec*F_s_downsampled_by_1e6);
    disp(start_sec*F_s_downsampled_by_1e6);
    fig2 = figure("visible", "off");
    % [pks,locs] = findpeaks(moving_avg_power);
    plot(signal_segment);
    grid on;
    shg;
    exportgraphics(fig2, strcat("/home/wairimu/plots_folder/peak",num2str(loc_ix),"_downsampled_by_1e6.png"), "Resolution", 300);

end
return;
%%
