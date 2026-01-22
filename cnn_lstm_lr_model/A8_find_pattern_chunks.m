function [valid_pattern_chunks, num_pattern_chunks] = find_pattern_chunks(iq_signal_file)

% -------------------------------------------------------------------------------------------------------
% function: find_pattern_chunks().
%
% purpose: find all pattern chunks in the IQ signal file
%
% inputs: - the .raw IQ signal file
%
% outputs: a vector with the start/end times of all valid pattern chunks (
% -------------------------------------------------------------------------------------------------------


% define the sampling freq.
F_s = 2.4e6;


% read the raw IQ signal file.
iq_signal_read = read_complex_binary(iq_signal_file); % read the .raw IQ signal file.


% define the pattern length (the length of each uplink transmission in seconds).
pattern_length = 5;


% default: signal file does NOT contain our pattern.
% has_pattern = 0;


% define the number of samples we expect per pattern.
num_samples_per_pattern = pattern_length * F_s;


% find the number of samples in the given signal file.
actual_num_samples = length(iq_signal_read); 
% % disp("number of samples in current signal file: " + actual_num_samples)


% find the duration (in seconds) of the given signal file.
actual_dur_sec = actual_num_samples / F_s;
disp("duration (in seconds) of current signal file: " + actual_dur_sec)


% compute the normalized moving avg of signal power.
signal_power = abs(iq_signal_read).^2; % compute the instantaneous signal power.
moving_avg_power_vec = movmean(signal_power, num_samples_per_pattern); % compute the moving avg of the signal power.
moving_avg_power_vec = normalize(moving_avg_power_vec, "range", [0 1]); % normalize the moving avg of the signal power.


% define axis.
x = linspace(0, actual_dur_sec, length(moving_avg_power_vec)); % a time vector aligned with the normalized moving avg vector. 
y = moving_avg_power_vec; % a vector for the normalized moving avg power vector   


% plot moving avg power (considering the duration that the file actualllyy is).
% figure;
% plot(x, y); 
% title('Normalized Moving Avg Signal Power of file', iq_signal_file);
% xlabel('Time (seconds)');
% ylabel('Normalized Power');


% use findpeaks() to find peak locations.
[peak_vals, peak_locs] = findpeaks(y, x, ...
                                    'MinPeakProminence', 0.06);
% ==> vectors with heights of peaks found in the input AND the time (in seconds) at which the peaks occur.
num_peak_points = length(peak_locs);
disp("number of peaks found: " + num_peak_points);
disp("peak locations (in seconds):")
disp(peak_locs)


% downsample y so findchangpts() can actually process the signal lol.
downsampling_fs = 2000;
y_downsampled = downsample(y, downsampling_fs);
x_downsampled = downsample(x, downsampling_fs);


min_sec = 2.5;
min_distance = round(downsampling_fs * min_sec);
change_locs = findchangepts(y_downsampled, 'Statistic', 'linear', 'MinDistance', min_distance, 'MinThreshold', 0.3); 
% change_locs = findchangepts(y_downsampled, 'Statistic', 'linear', 'MaxNumChanges', 6, 'MinDistance', min_distance); 
% ==> vector with indices where bursts or dips start.


num_change_points = length(change_locs);
% disp("number of change times: " + num_change_points)


% convert indeces to time (in seconds) such that peak points and change pts are on the same axis.
change_points = x_downsampled(change_locs);
% % disp("change_times: " + change_points)
% % disp("change times...:")
% % disp(change_points)


% include 0 and 60 as a change points.
change_points = [0, change_points, 60];
disp("change times (including 0 and 60 now)...:")
disp(change_points)


% ----------------- FIND ALL PATTERN CHUNKS -----------------------------------------------------------

% define an array to store [start, end] pairs for pattern chunks.
pattern_chunks = [];


% goal: we want to choose the change point that follows the peak point that makes the pattern chunk be closest but not exceed 10 seconds
% detect signal pattern chunks (1s) -- iterate through each change point to see if a peak occurs 1-7 seconds after it and the next change point occurs 1-7 seconds after the peak point.
for j = 1:num_change_points

    % chunk_labels(j) = 0; % default label is 0.

    change_point = change_points(j); % the j-th change point (in seconds).
    % % disp("change point considered atm: " + change_point)
    % next_change_point = change_points(j + 1); % the j-th + 1 change point (in seconds).


    % if the j-th change point comes before the end of the last pattern chunk, skip it.
    if ~isempty(pattern_chunks)
        last_pattern_end = pattern_chunks(end, 2);

        if change_point < last_pattern_end
            % % disp("ignoring change point " + change_point)
            continue
        end
    end


    % iterate through each peak point.
    for k = 1:num_peak_points

        peak_point = peak_locs(k); % the k-th peak point (in seconds).
        % % disp("peak point being considered atm: " + peak_point)


        % skip the peak point if it's already been used.
        if ~isempty(pattern_chunks)
            if any(peak_point >= pattern_chunks(:,1) & peak_point <= pattern_chunks(:,2))
                continue
            end
        end


        % find the idx of the change point that comes RIGHT AFTER the k-th peak point.
        next_change_point_idx = find(change_points > peak_point, 1, 'first'); 
        % % disp("next change point idx: " + next_change_point_idx)


        % if there is no change point after the j-th one, skip this window's iteration.
        if isempty(next_change_point_idx)
            continue
        end

        % "grab" the next change point using the appropriate index.
        next_change_point = change_points(next_change_point_idx); % the j-th + 1 change point.
        % % disp("first change point that follows the peak point: " + next_change_point)


        % if the change point that comes right after the k-th peak point is < 1.5 seconds, find the next change point.
        if next_change_point - peak_point < 1.5

            % find the index of the next change point.
            next_change_point_idx = next_change_point_idx + 1;
            % % disp("next change point idx: " + next_change_point_idx)

            % if the index that comes after the end of the file, move on.
            if next_change_point_idx > length(change_points)
                continue
            end

            % "grab" this change point.
            next_change_point = change_points(next_change_point_idx);
            % % disp("new next change point: " + next_change_point)

        end


        % define pattern chunk conditions.
        valid_peak = peak_point >= change_point + 1 && peak_point <= change_point + 7; % the peak point must occur more than 1 but less than 7 seconds after the change point.
        valid_next_change_point = next_change_point >= peak_point + 0.5 && next_change_point <= peak_point + 7; % the next change point must occur more than 1 but less than 7 seconds after the peak point.


        % check peak locations for pattern chunks.
        if valid_peak && valid_next_change_point

            % % disp("pattern chunk found!")

            % apppend this window to the pattern chunks array.
            pattern_chunks = [pattern_chunks; change_point, next_change_point];

            break
        else
            % % disp("no spikes that are 10 seconds apart for this change point")
        end
    end
end


% if there are pattern chunks, sort them by starting times (in seconds).
if isempty(pattern_chunks)
    start_no_pattern_gaps = 0;
    end_no_pattern_gaps = actual_dur_sec;
else
    pattern_chunks = sortrows(pattern_chunks, 1);
    % disp("Pattern_chunks (after sorting)...:")
    % disp(pattern_chunks)

    start_no_pattern_gaps = [0; pattern_chunks(:, 2)]; % an array of all the start times of no-pattern gaps ==> [0; end sec pattern chunk 1; end sec of pattern chunk 2;...].
    end_no_pattern_gaps = [pattern_chunks(:, 1); actual_dur_sec]; % an array of all the end times of no-pattern gaps ==> [start sec of pattern chunk 1; start sec of pattern chunk 2; ...; 70].
end


num_pattern_chunks = size(pattern_chunks, 1);
% disp("number of pattern chunks: " + num_pattern_chunks)


% create an array to hold all pattern chunks that are between 0 and 13 seconds long
valid_pattern_chunks = [];

for i = 1:num_pattern_chunks
    start_pattern_chunk = pattern_chunks(i, 1); 
    end_pattern_chunk = pattern_chunks(i, 2);

    pattern_chunk_dur = end_pattern_chunk - start_pattern_chunk;

    if pattern_chunk_dur >= 8 && pattern_chunk_dur <= 13
        valid_pattern_chunks = [valid_pattern_chunks; start_pattern_chunk, end_pattern_chunk];
        % has_pattern = 1; 
    end
end

disp("valid pattern chunks: ")
disp(valid_pattern_chunks)


num_pattern_chunks = size(valid_pattern_chunks, 1);
disp("number of valid pattern chunks: " + num_pattern_chunks)


