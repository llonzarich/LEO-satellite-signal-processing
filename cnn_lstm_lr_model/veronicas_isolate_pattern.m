function [has_pattern, moving_avg_power_vec, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk] = isolate_pattern(iq_signal_file)

% -------------------------------------------------------------------------------------------------------
% function: signal_chunking().
%
% purpose: automate the process of annotating a file's moving avg plot with the start_sec, end_sec, and label of all 12 chunks.
%  
% note: - 'pattern' chunks (the 5ish sec transmission uplink) get labeled 1.
%       - 'no_pattern' chunks (noise or the off part of a spike) get labeled 0.
%
% inputs: - the .raw IQ signal file
%
% outputs: 'chunks' array (12 x start_sec and end_sec) and 'labels' array (12 x 0 or 1) for a raw IQ signal file.
% -------------------------------------------------------------------------------------------------------


filename = iq_signal_file; 
% filename = 'gqrx_20250606_221325_1075133000_2400000_fc.raw';

% define the sampling freq.
F_s = 2.4e6;


% define the pattern length (the length of each uplink transmission in seconds).
pattern_length = 5;




% define the number of samples we expect per pattern.
num_samples_per_pattern = pattern_length * F_s;


% read the raw IQ signal file.
iq_signal_read = read_complex_binary(filename); % read the .raw IQ signal file.


% find the number of samples in the given signal file.
actual_num_samples = length(iq_signal_read); 
% disp("number of samples in current signal file: " + actual_num_samples)


% find the duration (in seconds) of the given signal file.
actual_dur_sec = actual_num_samples / F_s;
% disp("duration (in seconds) of current signal file: " + actual_dur_sec)


% define the file length (in seconds)
target_dur_sec = 60;


% compute the number of samples we expect per file.
target_num_samples = target_dur_sec * F_s;


% compute the normalized moving avg of signal power.
signal_power = abs(iq_signal_read).^2; % compute the signal power.
moving_avg_power_vec = movmean(signal_power, num_samples_per_pattern); % compute the moving avg of the signal power.
moving_avg_power_vec = normalize(moving_avg_power_vec, "range", [0 1]); % normalize the moving avg of the signal power.


% define axis.
x = linspace(0, actual_dur_sec, length(moving_avg_power_vec)); % a time vector aligned with the normalized moving avg vector. 
y = moving_avg_power_vec; % a vector for the normalized moving avg power vector   



% plot moving avg power (considering the duration that the file actualllyy is).
figure;
plot(x, y); 
title('Normalized Moving Avg Signal Power of file', filename);
xlabel('Time (seconds)');
ylabel('Normalized Power');


[peak_vals, peak_locs] = findpeaks(y, x, ...
                                    'MinPeakProminence', 0.06);
% ==> vectors with heights of peaks found in the input AND the time (in seconds) at which the peaks occur.
% disp("peak locations (in seconds):")
disp(peak_locs)


% compute the difference between consecutive peaks.
% example: if peaks = [10, 20, 31, 40], then diff_peak_locs = [10, 11, 9]
diff_peak_locs = diff(peak_locs);


has_pattern = 0;
pattern_chunks = [];


% if there are less than 2 peaks, dw about isolating a signal pattern (because there isn't one). 
if numel(peak_locs) < 2
    start_sec_first_pattern_chunk = -1;
    end_sec_last_pattern_chunk = -1;
    return;
end


% set pattern flag to true if there are at least two consecutive peaks.
% iterate through the number of peak differences (there's 1 less of these than there are peaks) and set pattern flag = 1 if there is a pattern.
for j=1:numel(diff_peak_locs)

    % if the difference between two peaks is >8 and <12, then we have found a pattern - 2 consecutive peaks spaced between 8-12 seconds apart.
    if diff_peak_locs(j) > 8 && diff_peak_locs(j) < 12
        disp("pattern found");
        has_pattern = 1; 
    end
end


% get positions where pattern appears
for k = 1:numel(peak_locs)-1
    peak_diff = abs(peak_locs(k) - peak_locs(k+1));

    if peak_diff > 8 && peak_diff < 12 % pattern found
        pattern_chunks = [pattern_chunks; peak_locs(k), peak_locs(k+1)];
        
    end
end


disp("Pattern chunks from line 124:")
disp(pattern_chunks);


if numel(pattern_chunks) < 2
    start_sec_first_pattern_chunk = -1;
    end_sec_last_pattern_chunk = -1;
else

    start_sec_first_pattern_chunk = pattern_chunks(1, 1);
    end_sec_last_pattern_chunk = pattern_chunks(end, 2);
end

disp("starting pattern:");
disp(start_sec_first_pattern_chunk);
disp("end pattern:");
disp(end_sec_last_pattern_chunk);

return;





% % % if the file <70 seconds, pad the end with 0s.
% % % pad now, because now we need to make chunks based on the peaks and changepts, and we need data for places we want to make chunks.
% % if actual_num_samples < target_num_samples
% %     samples_to_target = target_num_samples - actual_num_samples; % number of samples we need to fill with 0s for padding.
% % 
% %     iq_signal_read = [iq_signal_read; zeros(samples_to_target, 1, 'like', iq_signal_read)]; % pad the signal file. 
% % end
% % 
% % 
% % % sanity check to see that the iq signal file is now padded with zeros.
% % actual_num_samples = length(iq_signal_read);
% % actual_dur_sec = actual_num_samples / F_s;
% % disp("signal file duration (in seconds) after padding: " + actual_dur_sec)
% 
% 
% % create vectors for holding data for each file's 12 chunks.
% chunk_bounds = linspace(0, actual_dur_sec, 13); % 12 time intervals.
% chunk_labels = zeros(12, 1); % 12 labels.
% 
% 
% % downsample y so findchangpts() can actually process the signal lol.
% downsampling_fs = 2000;
% y_downsampled = downsample(y, downsampling_fs);
% x_downsampled = downsample(x, downsampling_fs);
% 
% 
% min_sec = 2.5;
% min_distance = round(downsampling_fs * min_sec);
% change_locs = findchangepts(y_downsampled, 'Statistic', 'linear', 'MinDistance', min_distance, 'MinThreshold', 0.5); % option to specify MaxNumChanges.
% % change_locs = findchangepts(y_downsampled, 'Statistic', 'linear', 'MaxNumChanges', 6, 'MinDistance', min_distance); % option to specify MaxNumChanges.
% % ==> vector with indices where bursts or dips start.
% 
% 
% num_change_points = length(change_locs);
% % disp("number of change times: " + num_change_points)
% 
% 
% % convert indeces to time (in seconds) such that peak points and change pts are on the same axis.
% change_points = x_downsampled(change_locs);
% % disp("change_times: " + change_points)
% % disp("change times...:")
% % disp(change_points)
% 
% 
% % include 0 as a change point
% change_points = [0, change_points];
% % disp("change times (including 0 now)...:")
% % disp(change_points)
% 
% 
% 
% % define an array to store [start, end] pairs for pattern chunks.
% pattern_chunks = [];
% 
% 
% 
% % detect signal pattern chunks (1s) -- iterate through each change point to see if a peak occurs 5-8 seconds after it.
% for j = 1:num_change_points
% 
%     change_point = change_points(j); % the i-th change point (in seconds).
%     % disp("change_point " + j + ": " + change_point + newline)
% 
%     % if the current change point comes before the end of the last pattern chunk, skip it.
%     if ~isempty(pattern_chunks)
%         last_end = pattern_chunks(end, 2);
% 
%         if change_point < last_end
%             % disp("ignoring change point " + change_point)
%             continue
%         end
%     end
% 
%     % iterate through each peak point.
%     for k = 1:num_peak_points
%         % disp("HELLOOO from line 141")
% 
% 
%         peak_point = peak_locs(k); % the i-th peak (in seconds).
%         % disp("peak_point " + k + " :" + peak_point + newline);
% 
% 
%         % if the peak point occurs more than 5 and less than 8 seconds after the change point, we know this must be a section with our pattern.
%         if peak_point >= change_point + 1 && peak_point <= change_point + 8
%             % disp("Signal pattern found at " + peak_point + " seconds after change at " + change_point + " seconds." + newline);
% 
%             start_sec_pattern = change_point;
%             % disp("starting sec of pattern " + k + " :" + start_sec_pattern);
%             end_sec_pattern = peak_point;
%             % disp("ending sec of pattern " + k + " :" + end_sec_pattern);
%             chunk_labels(k) = 1;
% 
%             % append the starting second and ending second of the pattern chunk to the pattern_chunks array.
%             pattern_chunks = [pattern_chunks; start_sec_pattern, end_sec_pattern];
% 
% 
%             % % testing to see starting and ending sec of each pattern chunk.
%             % disp("pattern chunk # " + k + "...");
%             % disp("starting sec of pattern chunk: " + pattern_chunks(end, 1));
%             % disp("ending sec of pattern chunk: " + pattern_chunks(end, 2)); 
%             % disp("--------------------------------------------")
% 
%             break % move on to the next change point.           
%         end            
%     end
% end
% 
% % ==> pattern chunks
% disp("HELLO FROM LIKE 251")
% disp(pattern_chunks)
% 
% 
% if numel(pattern_chunks) < 2
%     start_sec_first_pattern_chunk = -1;
%     end_sec_last_pattern_chunk = -1;
% else
% 
%     start_sec_first_pattern_chunk = pattern_chunks(1, 1);
%     end_sec_last_pattern_chunk = pattern_chunks(end, 2);
% end
% 
% disp("starting pattern:");
% disp(start_sec_first_pattern_chunk);
% disp("end pattern:");
% disp(end_sec_last_pattern_chunk);
% 
% return;
% 
% 
% % if there are pattern chunks, sort them by starting times (in seconds).
% if isempty(pattern_chunks)
% 
%     start_no_pattern_gaps = 0;
%     end_no_pattern_gaps = actual_dur_sec;
% else
% 
%     pattern_chunks = sortrows(pattern_chunks, 1);
%     disp("Pattern_chunks (after sorting)...:")
%     disp(pattern_chunks)
% 
%     start_no_pattern_gaps = [0; pattern_chunks(:, 2)]; % an array of all the start times of no-pattern gaps ==> [0; end sec pattern chunk 1; end sec of pattern chunk 2;...].
%     end_no_pattern_gaps = [pattern_chunks(:, 1); actual_dur_sec]; % an array of all the end times of no-pattern gaps ==> [start sec of pattern chunk 1; start sec of pattern chunk 2; ...; 70].
% end
% 
% if numel(pattern_chunks) < 2
%     start_sec_first_pattern_chunk = -1;
%     end_sec_last_pattern_chunk = -1;
% else
% 
%     start_sec_first_pattern_chunk = pattern_chunks(1, 1);
%     end_sec_last_pattern_chunk = pattern_chunks(end, 2);
% end
% 
% disp("starting pattern:");
% disp(start_sec_first_pattern_chunk);
% disp("end pattern:");
% disp(end_sec_last_pattern_chunk);
% 
% return;