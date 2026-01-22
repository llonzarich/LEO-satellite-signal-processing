function [chunks, labels] = new_auto_annotating(iq_signal_file)

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


% define the sampling freq.
F_s = 2.4e6;


% define the pattern length (the length of each uplink transmission in seconds).
pattern_length = 5;


% define the number of samples we expect per pattern.
num_samples_per_pattern = pattern_length * F_s;


% read the raw IQ signal file.
iq_signal_read = read_complex_binary(filename); % read the .raw IQ signal file.














% signal_power = abs(iq_signal_read).^2; % compute the instantaneous signal power.
% 
% 
% % apply light moving avg
% moving_avg_signal = movmean(signal_power, 100);
% 
% % apply SG filtering
% polynomial_order = 3;
% frame_length = 301;
% 
% 
% smoothed_signal = sgolayfilt(moving_avg_signal, polynomial_order, frame_length);
% smoothed_signal = normalize(smoothed_signal, "range", [0, 1]);
% 
% % find the number of samples and duration (seconds) in the given signal file.
% actual_num_samples = length(iq_signal_read); 
% actual_dur_sec = actual_num_samples / F_s;
% x = linspace(0, actual_dur_sec, length(smoothed_signal));
% 
% % visualize
% plot(x, signal_power, 'Color', [0.7 0.7 0.7])
% hold on
% plot(x, smoothed_signal, 'r', 'LineWidth', 2)
% xlabel('Time (s)')
% ylabel('Normalized Power')
% title('SG filter with pre-smoothing via moving avg')
% legend('Original signal', 'smoothed signal')
% grid on
% 
% 
% % use findpeaks() to find peak locations
% [peak_vals, peak_locs] = findpeaks(smoothed_signal, x, ...
%                                     'MinPeakProminence', 0.02);
% % ==> vectors with heights of peaks found in the input AND the time (in seconds) at which the peaks occur.
% disp("peak locations (in seconds):")
% disp(peak_locs)






% find the number of samples in the given signal file.
actual_num_samples = length(iq_signal_read); 
disp("number of samples in current signal file: " + actual_num_samples)


% find the duration (in seconds) of the given signal file.
actual_dur_sec = actual_num_samples / F_s;
disp("duration (in seconds) of current signal file: " + actual_dur_sec)


% define the file length (in seconds)
target_dur_sec = 60;


% compute the number of samples we expect per file.
target_num_samples = target_dur_sec * F_s;
disp("number of samples expected in a signal file: " + target_num_samples)


% if the file <60 seconds, pad the end with 0s
if actual_dur_sec < target_dur_sec
    samples_to_pad = target_num_samples - actual_num_samples; % number of samples we need to fill with 0s for padding.

    iq_signal_read = [iq_signal_read; zeros(samples_to_pad, 1, 'like', iq_signal_read)]; % pad the signal file. 

    actual_dur_sec = target_dur_sec;  % update actual_dur sec after padding.
    disp("signal padded to : " + actual_dur_sec + " seconds.")
end


% if the file >60 seconds, truncate the end.
if actual_dur_sec > target_dur_sec
    iq_signal_read = iq_signal_read(1:target_num_samples); % truncate the file.

    actual_dur_sec = target_dur_sec; % update actual_dur_sec after truncating.
    disp("signal cut to: " + actual_dur_sec + " seconds.")
end


% compute the normalized moving avg of signal power.
signal_power = abs(iq_signal_read).^2; % compute the instantaneous signal power.
moving_avg_power_vec = movmean(signal_power, num_samples_per_pattern); % compute the moving avg of the signal power.
moving_avg_power_vec = normalize(moving_avg_power_vec, "range", [0 1]); % normalize the moving avg of the signal power.


% define axis.
x = linspace(0, actual_dur_sec, length(moving_avg_power_vec)); % a time vector aligned with the normalized moving avg vector. 
y = moving_avg_power_vec; % a vector for the normalized moving avg power vector   



% % plot moving avg power (considering the duration that the file actualllyy is).
% figure;
% plot(x, y); 
% title('Normalized Moving Avg Signal Power of file', filename);
% xlabel('Time (seconds)');
% ylabel('Normalized Power');


% use findpeaks() to find peak locations
[peak_vals, peak_locs] = findpeaks(y, x, ...
                                    'MinPeakProminence', 0.01);
% ==> vectors with heights of peaks found in the input AND the time (in seconds) at which the peaks occur.
disp("peak locations (in seconds):")
disp(peak_locs)


disp("length of x: " + length(x));
disp("length of y: " + length(y));


num_peak_points = length(peak_locs);
disp("number of peaks found: " + num_peak_points);


% create vectors for holding data for each file's 12 chunks.
chunk_bounds = linspace(0, actual_dur_sec, 13); % 12 time intervals.
chunk_labels = zeros(12, 1); % 12 labels.


% downsample y so findchangpts() can actually process the signal lol.
downsampling_fs = 2000;
y_downsampled = downsample(y, downsampling_fs);
x_downsampled = downsample(x, downsampling_fs);


min_sec = 2.5;
min_distance = round(downsampling_fs * min_sec);
change_locs = findchangepts(y_downsampled, 'Statistic', 'linear', 'MinDistance', min_distance, 'MinThreshold', 0.1); % option to specify MaxNumChanges.
% change_locs = findchangepts(y_downsampled, 'Statistic', 'linear', 'MaxNumChanges', 6, 'MinDistance', min_distance); % option to specify MaxNumChanges.
% ==> vector with indices where bursts or dips start.


num_change_points = length(change_locs);
disp("number of change times: " + num_change_points)


% convert indeces to time (in seconds) such that peak points and change pts are on the same axis.
change_points = x_downsampled(change_locs);
% disp("change_times: " + change_points)
% disp("change times...:")
% disp(change_points)


% include 0 as a change point
change_points = [0, change_points];
disp("change times (including 0 now)...:")
disp(change_points)


% ----------------- FIND ALL PATTERN CHUNKS -----------------------------------------------------------

% define an array to store [start, end] pairs for pattern chunks.
pattern_chunks = [];



% goal: we want to choose the change point that follows the peak point that makes the pattern chunk be closest but not exceed 10 seconds
% detect signal pattern chunks (1s) -- iterate through each change point to see if a peak occurs 1-7 seconds after it and the next change point occurs 1-7 seconds after the peak point.
for j = 1:num_change_points

    % chunk_labels(j) = 0; % default label is 0.

    change_point = change_points(j); % the j-th change point (in seconds).
    % disp("first change point considered: " + change_point)
    % next_change_point = change_points(j + 1); % the j-th + 1 change point (in seconds).


    % if the j-th change point comes before the end of the last pattern chunk, skip it.
    if ~isempty(pattern_chunks)
        last_pattern_end = pattern_chunks(end, 2);

        if change_point < last_pattern_end
            % disp("ignoring change point " + change_point)
            continue
        end
    end


    % iterate through each peak point.
    for k = 1:num_peak_points

        peak_point = peak_locs(k); % the k-th peak point (in seconds).
        % disp("peak point being considered atm: " + peak_point)


        % find the idx of the change point that comes RIGHT AFTER the k-th peak point.
        next_change_point_idx = find(change_points > peak_point + 1, 1, 'first'); 


        % if there is no change point after the j-th one, skip this window's iteration
        if isempty(next_change_point_idx)
            continue
        end


        next_change_point = change_points(next_change_point_idx); % the j-th + 1 change point.
        % disp("first change point that follows the peak point: " + next_change_point)


        % define pattern chunk conditions.
        valid_peak = peak_point >= change_point + 1 && peak_point <= change_point + 7; % the peak point must occur more than 1 but less than 7 seconds after the change point.
        valid_next_change_point = next_change_point >= peak_point + 3 && next_change_point <= peak_point + 7; % the next change point must occur more than 1 but less than 7 seconds after the peak point.

        % disp("valid next change point after the peak? " + valid_next_change_point)

        % check peak locations for pattern chunks.
        if valid_peak && valid_next_change_point

            % disp("pattern chunk found!")
        
            % apppend this window to the pattern chunks array.
            pattern_chunks = [pattern_chunks; change_point, next_change_point];

            % label this chunk as 1 (pattern).
            % chunk_labels(j) = 1;

            break
        else
            disp("no spikes that are 10 seconds long")
        end
    end
end


% if there are pattern chunks, sort them by starting times (in seconds).
if isempty(pattern_chunks)
    start_no_pattern_gaps = 0;
    end_no_pattern_gaps = actual_dur_sec;
else
    pattern_chunks = sortrows(pattern_chunks, 1);
    disp("Pattern_chunks (after sorting)...:")
    disp(pattern_chunks)

    start_no_pattern_gaps = [0; pattern_chunks(:, 2)]; % an array of all the start times of no-pattern gaps ==> [0; end sec pattern chunk 1; end sec of pattern chunk 2;...].
    end_no_pattern_gaps = [pattern_chunks(:, 1); actual_dur_sec]; % an array of all the end times of no-pattern gaps ==> [start sec of pattern chunk 1; start sec of pattern chunk 2; ...; 70].
end


num_pattern_chunks = size(pattern_chunks, 1);
disp("number of pattern chunks: " + num_pattern_chunks)


% create an array to hold all pattern chunks that are between 0 and 11 seconds long
valid_pattern_chunks = [];

for i = 1:num_pattern_chunks
    start_pattern_chunk = pattern_chunks(i, 1); 
    end_pattern_chunk = pattern_chunks(i, 2);

    pattern_chunk_dur = end_pattern_chunk - start_pattern_chunk;

    if pattern_chunk_dur >= 9 && pattern_chunk_dur <= 11
        valid_pattern_chunks = [valid_pattern_chunks; start_pattern_chunk, end_pattern_chunk];
    end
end

disp("valid pattern chunks: ")
disp(valid_pattern_chunks)

num_pattern_chunks = size(valid_pattern_chunks, 1);
disp("number of valid pattern chunks: " + num_pattern_chunks)


% ----------------- IMPLEMENT 10-SEC SLIDING WINDOW FOR CHUNKING SIGNAL FILES INTO CONSECUTIVE TIME SEQUENCES -----------------------------------------------------------

disp("HELLO FROM BEGINNING OF SLIDING WINDOW CHUNKING")

% define parameters
buffer = 10 * F_s; % window length (in number of samples).
window_length = 10; % window length (in seconds).
stride = F_s * 1; % the number of samples we'll advance to go to the next window.
stride_sec = 1; % number of seconds we'll advance to go to the next window.


% "collect" all window start and end seconds.
window_starts = 0:stride_sec:(actual_dur_sec - window_length); % windows start from 0 to 50, iterating by 1.
window_ends = 10:stride_sec:actual_dur_sec;


% determine the number of windows.
[m, n] = size(iq_signal_read); % m = time steps, n = features.
num_windows = floor((m - buffer) / stride) + 1;
disp("number of windows in the signal file: " + num_windows)


% % initialize an array to store all 10 second chunks.
% % all_chunks = zeros(num_windows, 1);
% all_chunks = [];


% initialize arrays to store pattern-containing windows and no-pattern-containing windows.
pattern_windows = [];
no_pattern_windows = [];


% initalize an array to store chunk-level labels.
window_labels = zeros(num_windows, 1);


% 3 x 1 row vector to keep track of which pattern chunks have been assigned a window.
pattern_used = zeros(num_pattern_chunks, 1);


% iterate through each pattern chunk to see if it aligns closely with a window. If so, we'll replace that window with the pattern chunk.
for i = 1:num_pattern_chunks

    % disp("HELLO FROM ITERATION " + j)

    % "grab" the start and end seconds of the i-th pattern chunk. 
    start_pattern_chunk = valid_pattern_chunks(i, 1); 
    end_pattern_chunk = valid_pattern_chunks(i, 2);
    % disp("start of the " + i + " pattern chunk: " + start_pattern_chunk)
    % disp("end of the " + i + " pattern chunk: " + end_pattern_chunk)

    % variables used to determine which window we'll replace with the pattern chunk.
    min_diff = inf;
    best_window_idx = -1;


    % iterate through each window.
    for j = 1:num_windows

        % start and end seconds of the j-th window.
        window_start_sec = window_starts(j);
        window_end_sec = window_ends(j);

        % if the window is close (enough) to the j-th window, "flag" that window.
        % the goal of this conditional is to find potential windows that the pattern chunk fits in and can replace.
        % the window chosen for the pattern chunk is the one which has the smallest difference from the start of the pattern chunk to the start of the window AND the end of the pattern chunk to the end of the window.
        if abs(start_pattern_chunk - window_start_sec) <= 1.5 && abs(end_pattern_chunk - window_end_sec) <= 1.5
            
            start_diff = abs(start_pattern_chunk - window_start_sec);
            end_diff = abs(end_pattern_chunk - window_end_sec);
            total_diff = start_diff + end_diff;

            % if the offset between start and end secs of pattern chunk to start and end secs of window is smallest, update variables.
            if total_diff < min_diff
                
                min_diff = total_diff;

                % "flag" this window.
                best_window_idx = j;
            end
        end
    end


    % if a best window was found and that window is labeled 0 atm.
    if best_window_idx > 0 && window_labels(best_window_idx) == 0

        % assign the best window label = 1 (pattern).
        window_labels(best_window_idx) = 1;

        % mark this patter as used. aka, it has found a window.
        pattern_used(i) = 1;

        % append this window to the 'pattern_windows' array, using the pattern chunk's start and end sec's (to ensure chunking accuracy).
        pattern_windows = [pattern_windows; start_pattern_chunk, end_pattern_chunk];
    end
end


% iterate through all windows to handle the 'no pattern' windows.
for i = 1:num_windows

    % if the window was not assigned 1 (aka, it was not chosen to be the "home" of a pattern chunk)...
    if window_labels(i) == 0

        % append this window to the 'no_pattern_windows' array.
        no_pattern_windows = [no_pattern_windows; window_starts(i), window_ends(i)];
    end
end


% disp("pattern windows")
% disp(pattern_windows)
% 
% 
% disp("no pattern windows")
% disp(no_pattern_windows)


% combine and sort all windows / chunks into one array.
all_chunks = [pattern_windows; no_pattern_windows];


% sort chunks based on time (in seconds).
[~, idx] = sort(all_chunks(:,1));
all_chunks = all_chunks(idx, :);
all_labels = window_labels(idx);


disp("all chunks")
disp(all_chunks)


disp("all labels")
disp(window_labels)


% return the chunks and labels.
chunks = all_chunks;
labels = window_labels;

