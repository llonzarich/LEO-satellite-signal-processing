function [actual_dur_sec, has_pattern, moving_avg_power_vec, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk] = A5_isolate_pattern(iq_signal_file)

% -------------------------------------------------------------------------------------------------------
% function: thirtysixsec_isolate_pattern().
%
% purpose: automate the process of annotating start/end seconds of 36 seconds of the file.
%
% logic: (1) finds all pattern chunks
%        (2) determines if any of those pattern chunks are consecutive -- either 2 or 3 consecutive pattern chunks.
%        (3) assigns start/end seconds according to this.
%        (4) if a file has at least 2 consecutive pattern chunks, it's labeled 1, otherwise it's labeled 0.
%
% inputs: - the .raw IQ signal file
%
% outputs: - the duration (in seconds) of the signal file.
%          - has_pattern boolean variable (a file-level label to classify whether or not a signal file has our target pattern or not).
%          - the moving avg power vector 
%          - the starting sec of the first pattern chunk (beginning of main pattern chunk).
%          - the ending sec of the last pattern chunk (end of main pattern chunk).
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


% % plot moving avg power (considering the duration that the file actualllyy is).
% figure;
% plot(x, y); 
% title('Normalized Moving Avg Signal Power of file', filename);
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





% ------------------------ FIND INDICES OF CONSECUTIVE PATTERN CHUNKS FOR TRIMMING FILES TO 36 SECONDS & DETERMINE FILE-LEVEL LABEL -------------------------

% default: signal file does NOT contain our pattern.
has_pattern = 0;


% ==> so, default is that...
start_sec_first_pattern_chunk = 0;
end_sec_last_pattern_chunk = 36;


% if there are no pattern chunks at all...
if num_pattern_chunks == 0
    disp("there are no pattern chunks")
   
    disp("duration of planned trimmed file: " + start_sec_first_pattern_chunk + " - " + end_sec_last_pattern_chunk)
    
    return

end


% variables for finding "best" pattern chunks to trim file around.
count_best_consecutive = 0;
best_start_sec = NaN;
best_end_sec = NaN;


% iterate through all pattern chunks.
for i = 1:num_pattern_chunks

    start_sec = valid_pattern_chunks(i, 1);
    end_sec = valid_pattern_chunks(i, 2);
    pattern_chunk_dur = end_sec - start_sec;


    % first, look for 3 consecutive chunks off of the i-th chunk.
    if i + 2 <= num_pattern_chunks
        disp("there are 3 pattern chunks after the " + i + " pattern chunk, so we can try to look for 3 consecutive pattern chunks...")

        next_start_sec = valid_pattern_chunks(i + 1, 1);
        next_end_sec = valid_pattern_chunks(i + 1, 2);
        next_next_start_sec = valid_pattern_chunks(i + 2, 1);
        next_next_end_sec = valid_pattern_chunks(i + 2, 2);
        
        % check to see if there are 3 consecutive chunks.
        if end_sec == next_start_sec && next_end_sec == next_next_start_sec
            
            if 3 > count_best_consecutive
                count_best_consecutive = 3;
                best_start_sec = start_sec;
                best_end_sec = next_next_end_sec;
            end
        end
    end
            
    %         disp("there are 3 consecutive chunks off of the " + i + " pattern chunk!")
    % 
    %         has_pattern = 1;
    % 
    %         start_sec_first_pattern_chunk = start_sec;
    %         end_sec_last_pattern_chunk = next_next_end_sec;
    %         dur = end_sec_last_pattern_chunk - start_sec_first_pattern_chunk;
    % 
    %         if dur < 36
    %             remaining_dur_sec = 36 - dur;
    %             end_sec_last_pattern_chunk = end_sec_last_pattern_chunk + remaining_dur_sec;
    %         end
    % 
    % 
    %         disp("duration of to-be trimmed file: " + start_sec_first_pattern_chunk + " - " + end_sec_last_pattern_chunk)
    % 
    %         break
    %     else
    %         disp("there are not 3 consecutive chunks off of the " + i + " pattern chunk")
    %     end
    % end

    % try to look for 2 consecutive chunks off of the i-th chunk
    if i + 1 <= num_pattern_chunks
        disp("there are only 2 pattern chunks after the " + i + " pattern chunk, so we can only look for 2 consecutive pattern chunks...")
        
        next_start_sec = valid_pattern_chunks(i + 1, 1);
        next_end_sec = valid_pattern_chunks(i + 1, 2);
        next_pattern_chunk_dur = next_end_sec - next_start_sec;


        if end_sec == next_start_sec 
            if 2 > count_best_consecutive
                count_best_consecutive = 2;
                best_start_sec = start_sec;
                best_end_sec = next_end_sec;
            end
        end
    end
            
    %         disp("there are 2 consecutive chunks off of the " + i + " pattern chunk!")
    % 
    %         has_pattern = 1;
    % 
    %         consecutive_pattern_chunk_dur = pattern_chunk_dur + next_pattern_chunk_dur;
    %         remaining_dur_sec = 36 - consecutive_pattern_chunk_dur;
    % 
    %         start_sec_first_pattern_chunk = start_sec;
    %         end_sec_last_pattern_chunk = next_end_sec + remaining_dur_sec;
    %         disp("duration of to-be trimmed file: " + start_sec_first_pattern_chunk + " - " + end_sec_last_pattern_chunk)
    % 
    %         break
    %     else
    %         disp("there are not 2 consecutive pattern chunks off of the " + i + " pattern chunk")
    %     end
    % end

    % if there are no consecutive chunks
    % if ~has_pattern && i == num_pattern_chunks
    if count_best_consecutive == 0
        if isnan(best_start_sec)
            best_start_sec = start_sec;
            best_end_sec = end_sec;
        end
    end
    %     disp("there are not consecutive pattern chunks off of the " + i + " pattern chunk")
    % 
    %     remaining_dur_sec = 36 - pattern_chunk_dur;
    % 
    %     start_sec_first_pattern_chunk = start_sec;
    %     end_sec_last_pattern_chunk = end_sec + remaining_dur_sec;
    %     disp("duration of to-be trimmed file: " + start_sec_first_pattern_chunk + " - " + end_sec_last_pattern_chunk)
    % 
    % end
end


% for at least 2 consecutive pattern chunks...
if count_best_consecutive >= 2

    has_pattern = 1;

    target_dur = 36;

    pattern_dur_found = best_end_sec - best_start_sec;

    remaining_dur_needed = target_dur - pattern_dur_found;

    start_sec_first_pattern_chunk = best_start_sec;
    end_sec_last_pattern_chunk = best_end_sec + max(0, remaining_dur_needed);

    disp("duration of to-be trimmed file for >=2 consecutive pattern chunks:")
    disp(start_sec_first_pattern_chunk + " - " + end_sec_last_pattern_chunk)

% for solo pattern chunks...
else

    has_pattern = 0;
    
    start_sec_first_pattern_chunk = best_start_sec;

    pattern_chunk_dur = best_end_sec - best_start_sec;

    target_dur = 36;

    remaining_dur_needed = target_dur - pattern_chunk_dur;

    end_sec_last_pattern_chunk = best_end_sec + max(0, remaining_dur_needed);

    disp("duration of to-be trimmed file for solo pattern chunk:")
    disp(start_sec_first_pattern_chunk + " - " + end_sec_last_pattern_chunk)

end


% 
% if ~has_pattern
%     start_sec_first_pattern_chunk = valid_pattern_chunks(1, 1);
%     pattern_chunk_dur = valid_pattern_chunks(1, 2) - valid_pattern_chunks(1, 1);
%     remaining_dur_sec = 36 - pattern_chunk_dur;
%     end_sec_last_pattern_chunk = valid_pattern_chunks(1, 2) + remaining_dur_sec;
%     disp("duration of to-be trimmed file: " + start_sec_first_pattern_chunk + " - " + end_sec_last_pattern_chunk)
% end


% if the planned end sec > the actual length of the file, adjust.
if end_sec_last_pattern_chunk > actual_dur_sec
    disp("the end sec of the planned trimmed file exceeds the actual duration of the signal file")
    
    % find how far the planned end sec goes past the actual length of the file.
    overshot = end_sec_last_pattern_chunk - actual_dur_sec;

    % update the planned start sec to account for that time
    start_sec_first_pattern_chunk = start_sec_first_pattern_chunk - overshot;

    % update the planned end sec
    end_sec_last_pattern_chunk = end_sec_last_pattern_chunk - overshot;
    
    disp("new duration of to-be trimmed file: " + start_sec_first_pattern_chunk + " - " + end_sec_last_pattern_chunk)
end