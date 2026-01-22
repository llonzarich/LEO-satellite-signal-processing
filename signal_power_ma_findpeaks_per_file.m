addpath(genpath("/home/wairimu/leo-signal-proc/file_rw_utils"));
addpath(genpath("/home/wairimu/leo-signal-proc/matlab_utils"));
addpath(genpath("/home/wairimu/leo-signal-proc/plots"));
close all;
%%
% to run: 
% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/signal_power_findpeaks_max_peak_diff.m');exit;"
% this file & parameters are tested and working for a setup of fc 1075mhz &
% iperf intervals of 5s
%%

path = '/media/XXX/Elements/fc1075mhz_iperfoff';
pattern_folder = '/media/XXX/Elements/fc1075mhz_iperfoff/have_pattern';
no_pattern_folder = '/media/XXX/Elements/fc1075mhz_iperfoff/no_pattern';
pattern_path = strcat(pattern_folder, '/findpeaks_');
no_pattern_path = strcat(no_pattern_folder, '/findpeaks_');

F_s = 2.4e6;

dirlist = dir(path);
T = struct2table(dirlist);
sortedTable = sortrows(T, 3);
dirlist = table2struct(sortedTable);

PATTERN_LENGTH = 5; % 5 second on-off iperf pattern

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

    y1 = read_complex_binary(fname);
    n_samples_per_pattern = PATTERN_LENGTH * F_s;
    
    % moving average of signal power 
    signal_power = abs(y1).^2; % Calculate signal power
    moving_avg_power = movmean(signal_power, n_samples_per_pattern);
    moving_avg_power = normalize(moving_avg_power, "range", [0 1]);
    % [pks,locs] = findpeaks(moving_avg_power_1);
    
    xaxis = (0:length(moving_avg_power)-1)/F_s;
    
    %%1st step - Find a large amount of peaks with non-stringent constraints
    x = xaxis; % x-vector (what you want)
    y = moving_avg_power; % y-vector (what you want)
    minpeakheight = 0; % what you want (fairly small value)
    minpeakdistance = 0; % what you want (fairly small value)
    % [peak_vals,peak_locs] = findpeaks(y,x,'MinPeakDistance',8, 'MaxPeakWidth', 11, 'MinPeakProminence', 0.03); 'MinPeakWidth', 3
    [peak_vals,peak_locs] = findpeaks(y,x,'MinPeakDistance',(PATTERN_LENGTH*2)-2, 'MaxPeakWidth', (PATTERN_LENGTH*2)+1, 'MinPeakWidth', PATTERN_LENGTH-2, 'MinPeakProminence', 0.03);

    if length(peak_locs) < 2
        plot_fname = strcat(no_pattern_path, file_id, '.png');

        disp("No peaks found, skipping file: " + file_id);
        % fig = figure();  
        fig = figure("Visible","off");
        plot(xaxis,moving_avg_power,peak_locs,peak_vals,'o')
        grid on
        title(file_id);
        % 
        % % shg
        exportgraphics(fig, plot_fname);
        movefile fname no_pattern_folder
    else

        new_peak_locs = [];
        new_peak_vals = [];
        for ix=2:length(peak_locs)
            peak_diff = abs(peak_locs(ix) - peak_locs(ix-1));
            if peak_diff < PATTERN_LENGTH+2
                new_peak_locs = [new_peak_locs, peak_locs(ix)];
                new_peak_vals = [new_peak_vals, peak_vals(ix)];
                new_peak_locs = [new_peak_locs, peak_locs(ix-1)];
                new_peak_vals = [new_peak_vals, peak_vals(ix-1)];
            end
        end
        
        new_peak_locs = new_peak_locs(~isnan(new_peak_locs));
        new_peak_vals = new_peak_vals(~isnan(new_peak_vals));
        
        meanCycle = mean(diff(new_peak_locs));
        disp(meanCycle);
        meandiffPeaks = abs(meanCycle - PATTERN_LENGTH*2);
        disp(meandiffPeaks);
        
        % fig = figure();  
        fig = figure("Visible","off");
        plot(xaxis,moving_avg_power,new_peak_locs,new_peak_vals,'o')
        grid on
        title(file_id);
        % shg
        % exportgraphics(fig, plot_fname);

        if length(new_peak_locs) < 2
            plot_fname = strcat(no_pattern_path, file_id, '.png');
            exportgraphics(fig, plot_fname);
            disp("pattern not found " + file_id);
            movefile fname no_pattern_folder
        else
            plot_fname = strcat(pattern_path, file_id, '.png');
            exportgraphics(fig, plot_fname);
            disp("pattern found " + file_id);
            movefile fname pattern_folder

        end
    end
end

