function [has_pattern, new_peak_locs, new_peak_vals] = findpeaks_method(fname)
    addpath(genpath("/home/wairimu/leo-signal-proc/file_rw_utils"));
    addpath(genpath("/home/wairimu/leo-signal-proc/matlab_utils"));
    PATTERN_LENGTH = 5;
    F_s = 2.4e6;

    y1 = read_complex_binary(fname);
    n_samples_per_pattern = PATTERN_LENGTH * F_s;
    disp(length(y1));
    
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
    % [peak_vals,peak_locs] = findpeaks(y,x,'MinPeakDistance',(PATTERN_LENGTH*2)-2, 'MaxPeakWidth', (PATTERN_LENGTH*2)+1, 'MinPeakWidth', PATTERN_LENGTH-2, 'MinPeakProminence', 0.03);
    [peak_vals,peak_locs] = findpeaks(y,x,'MinPeakDistance',(PATTERN_LENGTH*2)-2, 'MinPeakWidth', PATTERN_LENGTH-2);
    new_peak_locs = [];
    new_peak_vals = [];
    disp("peak locations: " + peak_locs);

    if length(peak_locs) < 2
        has_pattern = 0;
    else


        for ix=2:length(peak_locs)
            peak_diff = abs(peak_locs(ix) - peak_locs(ix-1));
            disp(peak_diff);
            if peak_diff < (2*PATTERN_LENGTH)+2
                new_peak_locs = [new_peak_locs, peak_locs(ix)];
                new_peak_vals = [new_peak_vals, peak_vals(ix)];
                new_peak_locs = [new_peak_locs, peak_locs(ix-1)];
                new_peak_vals = [new_peak_vals, peak_vals(ix-1)];
            end
        end
        
        new_peak_locs = unique(new_peak_locs(~isnan(new_peak_locs)));
        new_peak_vals = unique(new_peak_vals(~isnan(new_peak_vals)));
        disp(new_peak_locs);
        
        meanCycle = mean(diff(new_peak_locs));
        disp(meanCycle);
        meandiffPeaks = abs(meanCycle - PATTERN_LENGTH*2);
        disp(meandiffPeaks);
        % new_peak_locs = peak_locs;
        % new_peak_vals = peak_vals;

        if length(new_peak_locs) < 2

            has_pattern = 0;
            
        else
            
            has_pattern = 1;
        end
    end
end

