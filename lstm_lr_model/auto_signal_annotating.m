function [chunks, labels] = auto_signal_annotating(iq_signal_file)

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


% % use NEO to find peaks....
% % (1) compute neo
% x = abs(iq_signal_read);
% x = x(:); % ensure signal is column vector.
% neo = x(2:end-1) .^2 - x(1:end-2) .* x(3:end);
% neo = [0; neo; 0];
% 
% 
% % (2) use neo to find peaks.
% threshold = mean(neo) + 2 * std(neo); % a dynamic threshold.
% disp("number of neo peaks found: " + sum(neo > threshold));

% [peak_vals, peak_locs] = findpeaks(neo, 'MinPeakHeight', threshold, 'MinPeakProminence', 0.02);
% disp("peak locations (in seconds):")
% disp(peak_locs)




[peak_vals, peak_locs] = findpeaks(y, x, ...
                                    'MinPeakProminence', 0.06);
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
change_locs = findchangepts(y_downsampled, 'Statistic', 'linear', 'MinDistance', min_distance, 'MinThreshold', 0.5); % option to specify MaxNumChanges.
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


% define an array to store [start, end] pairs for pattern chunks.
pattern_chunks = [];


% detect signal pattern chunks (1s) -- iterate through each change point to see if a peak occurs 5-8 seconds after it.
for j = 1:num_change_points

    change_point = change_points(j); % the i-th change point (in seconds).
    % disp("change_point " + j + ": " + change_point + newline)

    % if the current change point comes before the end of the last pattern chunk, skip it.
    if ~isempty(pattern_chunks)
        last_end = pattern_chunks(end, 2);

        if change_point < last_end
            disp("ignoring change point " + change_point)
            continue
        end
    end

    % iterate through each peak point.
    for k = 1:num_peak_points
        % disp("HELLOOO from line 141")


        peak_point = peak_locs(k); % the i-th peak (in seconds).
        % disp("peak_point " + k + " :" + peak_point + newline);


        % peak_point_idx = round(peak_point * F_s);
        % change_point_idx = round(change_point * F_s);
        % disp("peak point idx: " + peak_point_idx)
        % disp("change point idx: " + change_point_idx)


        % if the peak point occurs more than 5 and less than 8 seconds after the change point, we know this must be a section with our pattern.
        if peak_point >= change_point + 1 && peak_point <= change_point + 8 
                % (max(iq_signal_read(change_point_idx:peak_point_idx)) - min(iq_signal_read(change_point_idx:peak_point_idx)) > 0.2)
            % disp("Signal pattern found at " + peak_point + " seconds after change at " + change_point + " seconds." + newline);

            start_sec_pattern = change_point;
            % disp("starting sec of pattern " + k + " :" + start_sec_pattern);
            end_sec_pattern = peak_point;
            % disp("ending sec of pattern " + k + " :" + end_sec_pattern);
            chunk_labels(k) = 1;

            % append the starting second and ending second of the pattern chunk to the pattern_chunks array.
            pattern_chunks = [pattern_chunks; start_sec_pattern, end_sec_pattern];


            % testing to see starting and ending sec of each pattern chunk.
            % disp("pattern chunk # " + k + "...");
            % disp("starting sec of pattern chunk: " + pattern_chunks(end, 1));
            % disp("ending sec of pattern chunk: " + pattern_chunks(end, 2)); 
            % disp("--------------------------------------------")

            break % move on to the next change point.           
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



% define an array to store [start, end] pairs of no-pattern gaps
no_pattern_gaps = [];


% % define arrays to store start and end times (in seconds) for no-pattern gaps (between the pattern chunks).
% start_no_pattern_gaps = [0; pattern_chunks(:, 2)]; % an array of all the start times of no-pattern gaps ==> [0; end sec pattern chunk 1; end sec of pattern chunk 2;...].
% end_no_pattern_gaps = [pattern_chunks(:, 1); 70]; % an array of all the end times of no-pattern gaps ==> [start sec of pattern chunk 1; start sec of pattern chunk 2; ...; 70].


% iterate through each no-pattern gap.
for m = 1:length(start_no_pattern_gaps)

    % disp("HELLO FROM ITERATION " + m + " !!!!!!!!!")

    start_gap = start_no_pattern_gaps(m); 
    % disp("start of no-pattern gap " + m + ": " + start_gap);

    end_gap = end_no_pattern_gaps(m);
    % disp("end of no-pattern gap " + m + ": " + end_gap)

    % append the start and end time of each no-pattern gap to the array.
    no_pattern_gaps = [no_pattern_gaps; start_gap, end_gap];
end
% ==> no_pattern_gaps array is filled with [start_sec end_sec] pairs for each no_pattern gap. (the number of rows depends on the number of gaps, and there are 2 columns for each row).


% remove zero-duration gaps
durations = no_pattern_gaps(:,2) - no_pattern_gaps(:,1);
no_pattern_gaps = no_pattern_gaps(durations > 0, :);
% disp("no pattern gaps (after removing zero-duration gaps)...:")
% disp(no_pattern_gaps)


% determine the number of noise chunks we need to create to reach 12 chunks total. 
total_chunks_needed = 12;
num_pattern_chunks = size(pattern_chunks, 1);
num_no_pattern_chunks_needed = total_chunks_needed - num_pattern_chunks;


% define an array to store each no-pattern gap and its duration.
all_no_pattern_gaps = [];


% iterate through each row in 'no_pattern_gaps' (each row is a [start end] pair) to append the no_pattern gap duration to its row.
% note: size(no_pattern_gaps, 1) returns the number of rows, size(no_pattern_gaps, 2) returns the number of columns.
for i = 1:size(no_pattern_gaps, 1)

    % compute the duration of the no-pattern gap.
    % gap_duration = no_pattern_gaps(i-th row, 2nd column) - no_pattern_gaps(i-th row, first column)
    gap_duration = no_pattern_gaps(i, 2) - no_pattern_gaps(i, 1); 
    % disp("NO PATTERN GAP DURATION: " + gap_duration)

    % append duration info to a new array.
    all_no_pattern_gaps = [all_no_pattern_gaps; no_pattern_gaps(i,:), gap_duration]; % ==> an array with 3 columns: [start_sec end_sec duration].
end


% disp("HELLO from line 230")
disp("all no pattern gaps with their durations...:")
disp(all_no_pattern_gaps)


% compute the total duration of all noise chunks 
% total_noise_dur = the sum of the every row's 3rd column == the sum of the durations of every gap.
total_noise_dur = sum(all_no_pattern_gaps(:, 3));


% compute the avg duration of the noise gaps.
avg_no_pattern_gap_dur = total_noise_dur / num_no_pattern_chunks_needed;


% define an array to store start and end sec for each noise chunk...1 noise chunk per row in the form of [start_time end_time] pairs. (example: if there are 3 pattern chunks, this array will have 9 rows, 1 for each of the 9 no-pattern chunks).
no_pattern_chunks = [];


% make a copy of the 'all_no_pattern_gaps' array to extract the (smaller) no-pattern chunks from.
remaining_no_pattern_gaps = all_no_pattern_gaps;
% disp("all no pattern gaps:")
% disp(remaining_no_pattern_gaps)
% includes 0 --> start of a no-pattern hcunk 


% displaying all the times (in sec) for 'pattern chunks' and 'no-pattern gaps'.
% disp("---------------------")
% disp("DISPLAYING THE DATA I HAVE:")
% disp("pattern chunks...:")
% disp(pattern_chunks(:,:));
% disp("no pattern gaps...")
% disp(no_pattern_gaps(:,:))
% disp("---------------------")


% iterate through each no-pattern gap to search for any 5-9 second gaps before pattern bursts.
% note: size(remaining_no_pattern_gaps, 1) gives the number of rows in the 'remaining_no_pattern_gaps' array.
for n = 1:size(remaining_no_pattern_gaps, 1)

    gap_start = remaining_no_pattern_gaps(n, 1); % grab the nth no-pattern gap's start sec (column 1).
    % disp("gap start of iteration " + n + ": " + gap_start)

    gap_end = remaining_no_pattern_gaps(n, 2); % grab the nth no-pattern gap's end sec (column 2).

    % iterate through each pattern chunk.
    % note: size(pattern_chunks, 1) gives the number of rows in 'pattern_chunks' array.
    for q = 1:size(pattern_chunks, 1)

        pattern_start = pattern_chunks(q, 1); % grab the qth pattern chunk start sec (column 1).
        % disp("pattern_start: " + pattern_start)
        % disp("gap_start: " + gap_start)

        if pattern_start > gap_start

            distance = pattern_start - gap_start;  % compute the distance between the start of a pattern chunk and the start of a noise gap.
            % disp("distance: " + distance);

            % if the distance is less than or equal to 8...aka, if the pattern starts <= 8 seconds after the noise gap starts...
            if distance <= 9

                % append a noise chunk to the 'no_pattern_chunks' array. The start sec of the new noise chunk is the start sec of the noise gap, and the end sec of the new noise chunk is the start sec of the pattern pattern chunk. 
                no_pattern_chunks = [no_pattern_chunks; gap_start, pattern_start];

                % update remaining_no_pattern_gaps (remove the nth noise gap from the remaining noise dur because it just became its own chunk). 
                remaining_no_pattern_gaps(n,:) = NaN;

                % match_found = true;
                continue
            end
        end
    end
end



% remove any NaN rows
remaining_no_pattern_gaps = remaining_no_pattern_gaps(~any(isnan(remaining_no_pattern_gaps), 2), :);
% disp("remaining no pattern gaps: ")
% disp(remaining_no_pattern_gaps)


% disp("data...:")
% disp(no_pattern_chunks)
% disp("----------------------")
% disp(remaining_no_pattern_gaps)
% disp(" ------------------------")
% disp(pattern_chunks)
% disp(" ------------------------")
% disp(no_pattern_chunks)


% disp("HELLO FROM LINE 297");


% iterate until we have established 12 chunks total.
% ...or, iterate while the number of noise chunks is less than the number of noise chunks we need to make up 12 chunks total AND  while there are still noise gaps to be chunked
while size(no_pattern_chunks, 1) < num_no_pattern_chunks_needed && ~isempty(remaining_no_pattern_gaps)

    start_time = remaining_no_pattern_gaps(1, 1); % start time of the current gap (column 1 of row 1).

    remaining_no_pattern_gap_dur = remaining_no_pattern_gaps(1, 3); % duration of the current gap (column 3 of row 1).

    % to avoid making a 
    if remaining_no_pattern_gap_dur > avg_no_pattern_gap_dur + 1

        new_end = start_time + avg_no_pattern_gap_dur;

        no_pattern_chunks = [no_pattern_chunks; start_time, new_end];

        remaining_no_pattern_gaps(1,1) = new_end;

        remaining_no_pattern_gaps(1,3) = remaining_no_pattern_gaps(1,2) - new_end;

    else
        no_pattern_chunks = [no_pattern_chunks; remaining_no_pattern_gaps(1,1), remaining_no_pattern_gaps(1,2)];

        remaining_no_pattern_gaps(1,:) = []; 
    end
end

% disp("HELLO FROM LINE 365")
% disp(no_pattern_chunks)
no_pattern_chunks = sortrows(no_pattern_chunks, 1);
disp("all no pattern chunks...:")
disp(no_pattern_chunks)


% display the noise chunks as rows of [start end] pairs
% disp("HELLO FROM LINE 340")
% disp(no_pattern_chunks(:,:));
% disp("------------------------------------")
% disp(pattern_chunks(:,:));


% create full time boundaries
if isempty(pattern_chunks)
    pattern_extent = [0; actual_dur_sec];

else
    pattern_extent = [0; pattern_chunks(:, 1); pattern_chunks(:, 2); actual_dur_sec]; % a vector that contains the time of the start of the file, all the pattern chunk start times, all the pattern chunk end times, and the time of the end of the file.

end


pattern_extent = unique(pattern_extent);


% disp("HELLO FROM LINE 351")


% ensure all chunks are unique
no_pattern_chunks = unique(no_pattern_chunks, 'rows');


% disp("_______________________________")
% disp("pattern_chunks:")
% disp(pattern_chunks)
% disp("no_pattern_chunks")
% disp(no_pattern_chunks)
% disp("_______________________________")


% label chunks.
pattern_labels = ones(size(pattern_chunks, 1), 1);
no_pattern_labels = zeros(size(no_pattern_chunks, 1), 1);


% combine chunks.
all_chunks = [pattern_chunks; no_pattern_chunks];
all_labels = [pattern_labels; no_pattern_labels];


% sort chunks based on time (in seconds).
[~, idx] = sort(all_chunks(:,1));
all_chunks = all_chunks(idx, :);
all_labels = all_labels(idx);


% if there are small chunks and we haven't reached 70 seconds worth of chunks, merge smaller adjacent chunks together.
end_last_chunk = all_chunks(end, 2);
% disp("end sec of last chunk: ")
% disp(end_last_chunk)


% if all_chunks(end, 2) < actual_dur_sec
% 
%     all_chunks(end, 2) = actual_dur_sec;
% end


% if the end_sec of the last chunk is < actual duration of the file...
if end_last_chunk < actual_dur_sec

    % disp("HELLO FROM LINE 355")

    % compute the amount of time that is "unaccounted for"
    unaccounted_for_time = actual_dur_sec - end_last_chunk;
    disp("unaccounted for time: " + unaccounted_for_time)

    % get the durations of all no-pattern chunks.
    % all_chunks_durations = all_chunks(:,2) - all_chunks(:, 1);
    all_no_pattern_chunk_durations = no_pattern_chunks(:, 2) - no_pattern_chunks(:, 1);
    % disp("all chunks durations: ")
    % disp(all_chunks_durations)

    disp("durations of all no-pattern chunks...")
    disp(all_no_pattern_chunk_durations)

    % find all the no-pattern chunks that are <= 3 seconds.
    short_chunk_indices = find(all_no_pattern_chunk_durations <= 3); % indices of short no-pattern chunks.
    disp("short chunk indices: " + short_chunk_indices)

    % create space for the corresponding short no-pattern chunk indices in the entire 'all_chunks' array.  
    short_chunk_indices_in_all_chunks = [];

    % iterate through each short no-pattern chunk.
    for j = 1:length(short_chunk_indices)
        short_idx = short_chunk_indices(j); % get the index of the j-th short no-pattern chunk.

        short_chunk = no_pattern_chunks(short_idx, :); % get the CHUNK of the j-th short no-pattern chunk.

        match_idx = find(all_chunks(:,1) == short_chunk(1) & all_chunks(:,2) == short_chunk(2)); % find the corresponding index in the entire 'all_chunks' array.

        short_chunk_indices_in_all_chunks(end + 1) = match_idx; % append to array. 
    end

    disp("indices of short chunks in the 'all_chunks' array: " + short_chunk_indices_in_all_chunks)


    % if there are no no-pattern chunks <= 3 seconds, absorb the unaccounted for time into the last no-pattern chunk.
    if isempty(short_chunk_indices)
        disp("There are no no-pattern chunks <= 3 seconds, so i'll just absorb the unaccounted for time into the last no-pattern chunk.")

        all_chunks(end, 2) = actual_dur_sec; % make the end_sec of the last chunk just be 70 seconds.

    % if there exist no_pattern chunks <= 3 seconds...
    else

        disp("There are <= 3 second long no-pattern chunks! Let's see if we can merge them with other no-pattern chunks.")


        short_durs = all_no_pattern_chunk_durations(short_chunk_indices);

        % find the index of the shortest chunk among the short chunks.
        [~, min_idx_relative] = min(short_durs);
        min_idx_abs = short_chunk_indices(min_idx_relative);
        target_short_chunk = no_pattern_chunks(min_idx_abs, :);

        match_idx = find(all_chunks(:,1) == target_short_chunk(1) & all_chunks(:,2) == target_short_chunk(2));

        if isempty(match_idx)
            error("could't find matching chunk in all_chunks");
        end

        target_idx = match_idx;
        target_short_chunk_label = all_labels(target_idx);

        % 
        % % iterate through all the short chunks
        % for m = 1:length(short_chunk_indices)
        % 
        %     target_idx = short_chunk_indices_in_all_chunks(m);
        %     disp("target short chunk index: " + target_idx);
        % 
        %     target_short_chunk = all_chunks(target_idx, :);
        %     disp("target short chunk: " + target_short_chunk)
        % 
        %     target_short_chunk_label = all_labels(target_idx);
        %     disp("target short chunk label: " + target_short_chunk_label)
        % 

        % check bounds before accessing neighbors.
        if target_idx == 1 || target_idx == size(all_chunks, 1)
            all_chunks(end, 2) = actual_dur_sec;
            % continue % move to the next short no-pattern chunk if the target short chunk is at the edge (the first chunk or last chunk).
        else
            prev_chunk = all_chunks(target_idx - 1, :);
            next_chunk = all_chunks(target_idx + 1, :);

            prev_label = all_labels(target_idx - 1);
            next_label = all_labels(target_idx + 1);


            % case 1: both neighbors are label 1 == can't merge the chunks.
            if prev_label == 1 && next_label == 1
                disp("short no-pattern chunk is surrounded by pattern chunks. Skipping short chunk at index " + target_idx)

                all_chunks(end, 2) = actual_dur_sec; % absorb the remaining time into the last chunk in 'all_chunks' array.

                % continue % move to the next no-pattern short chunk.

            % case 2: the short no-pattern chunk must be merged with the next chunk (because we can't merge it with the prev pattern chunk).
            elseif prev_label == 1 && next_label == 0
                disp("Merging short no-pattern chunk with next no-pattern chunk")

                merged_chunk = [target_short_chunk(1), next_chunk(2)]; % merged chunk start sec is target chunk start sec, and its end sec is the next chunk's end sec.

                % update chunks
                all_chunks(target_idx,:) = merged_chunk;
                all_chunks(target_idx + 1, :) = NaN;
                all_labels(target_idx) = 0;
                all_labels(target_idx + 1) = NaN;

            % case 3: the short no-pattern chunk must be merged with the prev chunk (becuase we can't merge it with the next pattern chunk).
            elseif prev_label == 0 && next_label == 1
                disp("Merging short no-pattern chunk with previous no-pattern chunk")

                merged_chunk = [prev_chunk(1), target_short_chunk(2)];

                % update chunks.
                all_chunks(target_idx - 1,:) = merged_chunk;
                all_chunks(target_idx,:) = NaN;
                all_labels(target_idx - 1) = 0;
                all_labels(target_idx) = NaN;

            % case 4: the short no-pattern chunk can be merged with the prev or next chunk (both are no-pattern chunks), so we merge it with whichever is shorter.
            elseif prev_label == 0 && next_label == 0

                disp("short no-pattern chunk can be merged with prev OR next chunk")

                disp(prev_chunk(2))
                disp(prev_chunk(1))
                prev_dur = prev_chunk(2) - prev_chunk(1);
                next_dur = next_chunk(2) - next_chunk(1);

                if prev_dur <= next_dur
                    disp("Merging short no-pattern chunk with previous no-pattern chunk")

                    merged_chunk = [prev_chunk(1), target_short_chunk(2)];

                    % update chunks.
                    all_chunks(target_idx - 1,:) = merged_chunk;
                    all_chunks(target_idx,:) = NaN;
                    all_labels(target_idx - 1) = 0;
                    all_labels(target_idx) = NaN;

                else
                    disp("Merging short no-pattern chunk with next no-pattern chunk")

                    merged_chunk = [target_short_chunk(1), next_chunk(2)]; % merged chunk start sec is target chunk start sec, and its end sec is the next chunk's end sec.

                    % update chunks.
                    all_chunks(target_idx,:) = merged_chunk;
                    all_chunks(target_idx + 1, :) = NaN;
                    all_labels(target_idx) = 0;
                    all_labels(target_idx + 1) = NaN;
                end
            end



        end
        % end
    end


    % clean up merged (NaN) rows
    valid_rows = ~any(isnan(all_chunks), 2);
    all_chunks = all_chunks(valid_rows,:);
    all_labels = all_labels(valid_rows);


    % if we merged shorter chunks together, we must create a new chunk at the end to ensure we maintain 12 chunks. 
    if size(all_chunks, 1) < 12
        disp("we lost chunks from merging")

        % find where the last chunk ends.
        last_chunk_end = max(all_chunks(:,2));

        new_chunk_start = last_chunk_end;
        new_chunk_end = actual_dur_sec;

        if new_chunk_start < new_chunk_end 
            all_chunks = [all_chunks; new_chunk_start, new_chunk_end];
            all_labels = [all_labels; 0];
        else
            disp("warning: not enough room to add a chunk")
        end
    end

    % sort all_chunks and all_labels by start time to be cautious.
    [~, sort_idx] = sort(all_chunks(:, 1));
    all_chunks = all_chunks(sort_idx, :);
    all_labels = all_labels(sort_idx);
end


% while we don't have 12 chunks and we have accounted for the entired duration of the signal file...
% split the largest no-pattern chunk -- that isn't surrounded by pattern chunks -- into two separate chunks.
while true

    num_chunks = size(all_chunks, 1);
    dur_accounted_for = abs(max(all_chunks(:,2)) - actual_dur_sec);

    if num_chunks >= 12 || dur_accounted_for >= 0.01
        break
    end

    disp("We have < 12 chunks and no unaccounted for time, so we will split a viable long no-pattern chunk.")

    % find all no-pattern chunks.
    no_patterns_idx = find(all_labels == 0);

    % array to store the no-pattern chunks that are NOT between pattern chunks.
    valid_chunks_to_split = [];

    % iterate through each no-pattern chunk.
    for i = 1:length(no_patterns_idx)

        idx = no_patterns_idx(i); % the i-th no-pattern chunk.

        % check if the previous chunk is a pattern chunk by...
        % (1) checking if the prev label exists (2) checking if it is 1.
        prev_label = (idx > 1) && all_labels(idx - 1) == 1; % as long as the prev index exists, the prev_label is the next label .

        % check if the next chunk is a pattern chunks by...
        % (1) checking if the next label exists (2) checking if it is 1.
        next_label = (idx < length(all_labels)) && all_labels(idx + 1) == 1;

        % if the previous chunk and the next chunk are not both == 1...
        if ~(prev_label && next_label) 
            valid_chunks_to_split(end + 1) = idx; % add the current chunk to the array.
        end
    end

    % if there are viable no-pattern chunks that we can split, we'll choose the longest to split.
    if ~isempty(valid_chunks_to_split)

        % compute durations of all viable no-pattern chunks.
        durations = all_chunks(valid_chunks_to_split, 2) - all_chunks(valid_chunks_to_split, 1);

        % find the index of the longest viable no-pattern chunk.
        [~, max_idx] = max(durations);

        % "grab" the index of the chosen chunk to split from the array.
        chunk_to_split = valid_chunks_to_split(max_idx);
        disp("index of the chunk to split in the array: " + chunk_to_split)

        % "grab" all columns of data (start_sec, end_sec) from the row corresponding to the chunk we'll split.
        chunk = all_chunks(chunk_to_split, :);
        disp("chunk to split: " + chunk)

        % find the midpt of the chunk.
        mid = mean(chunk);

        % make two new chunks -- [start_sec mid; mid end_sec]
        new_chunks = [chunk(1), mid; mid, chunk(2)];
        new_labels = [0; 0];

        % replace the original chunk with the two new chunks.
        all_chunks(chunk_to_split,:) = [];
        all_labels(chunk_to_split) = [];

        all_chunks = [all_chunks; new_chunks];
        all_labels = [all_labels; new_labels];

        % sort chunks and labels by start time.
        [~, sort_idx] = sort(all_chunks(:, 1));
        all_chunks = all_chunks(sort_idx,:);
        all_labels = all_labels(sort_idx,:);

        % sanity check.
        % disp("all chunks...")
        % disp(all_chunks)
    else
        disp("Warning: no suitable chunk to split...")
        break
    end
end


% display all the sorted chunks.
disp("ALL CHUNKS...:")
disp(all_chunks(:,:));


% return the chunks and labels.
chunks = all_chunks;
labels = all_labels;

end