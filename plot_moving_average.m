addpath(genpath("/home/wairimu/leo-signal-proc/file_rw_utils"));
addpath(genpath("/home/wairimu/leo-signal-proc/matlab_utils"));
addpath(genpath("/home/wairimu/leo-signal-proc/plots"));
%%
close all;
%%
F_s = 2.4e6;
path = "/media/wairimu/Elements2/ch1_usrp/no_pattern/gqrx_20250725_070930_1075000000_2409638_fc.raw";

has_pattern_fnames = ["gqrx_20250725_020717_1075000000_2409638_fc.raw"
 "gqrx_20250725_021223_1075000000_2409638_fc.raw"
 "gqrx_20250725_022540_1075000000_2409638_fc.raw"
 "gqrx_20250725_032149_1075000000_2409638_fc.raw"
 "gqrx_20250725_084022_1075000000_2409638_fc.raw"
 "gqrx_20250725_030428_1075000000_2409638_fc.raw"
 "gqrx_20250725_043520_1075000000_2409638_fc.raw"
 "gqrx_20250725_045039_1075000000_2409638_fc.raw"
 "gqrx_20250725_052218_1075000000_2409638_fc.raw"
 "gqrx_20250725_073400_1075000000_2409638_fc.raw"
 "gqrx_20250725_040442_1075000000_2409638_fc.raw"
 "gqrx_20250725_051205_1075000000_2409638_fc.raw"
 "gqrx_20250725_070930_1075000000_2409638_fc.raw"
 "gqrx_20250725_083212_1075000000_2409638_fc.raw"
 "gqrx_20250725_053635_1075000000_2409638_fc.raw"
 "gqrx_20250725_020211_1075000000_2409638_fc.raw"
 "gqrx_20250725_043115_1075000000_2409638_fc.raw"
 "gqrx_20250725_045343_1075000000_2409638_fc.raw"
 "gqrx_20250725_063954_1075000000_2409638_fc.raw"];

for i = 1:length(has_pattern_fnames)
    path = strcat("/media/wairimu/Elements2/ch1_usrp/no_pattern/", has_pattern_fnames(i));
    y = read_complex_binary(path); 
    % y = y(1:length(y)/2);
    num_samples = length(y);
    
    % plot time domain signal
    total_seconds =  num_samples/ F_s;
    xaxis = 0:1/F_s:total_seconds;
    xaxis = xaxis(1:end-1);
    
    pattern_length = 5; % 5 second on-off iperf pattern
    n_samples_per_pattern = pattern_length * F_s;
    
    % moving average of signal power 
    signal_power = abs(y).^2; % Calculate signal power
        moving_avg_power = movmean(signal_power, n_samples_per_pattern);
        moving_avg_power = normalize(moving_avg_power, "range", [0 1]);
    % Plotting the moving average of signal power
    fig = figure()
    plot((0:length(moving_avg_power)-1)/F_s, moving_avg_power);
    xlabel("Time (s)");
    ylabel("Moving Average Signal Power");
    grid on
    % title("Moving Average of Signal Power");
    plot_path_part = char(has_pattern_fnames(i));
    plot_path = ['/home/wairimu/training_data_stricter_classification_method/test_data_plots/' plot_path_part(1:end-3) 'png'];
    exportgraphics(fig, plot_path );
end
