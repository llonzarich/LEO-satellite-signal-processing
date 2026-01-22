function [window_labels] = label_windows(valid_pattern_chunks, num_pattern_chunks, num_windows, signal_windows)

% -------------------------------------------------------------------------------------------------------
% purpose: determine window-level labels 
% 
% outputs: - a vector of size num_windows, filled with labels (0 or 1)
% -------------------------------------------------------------------------------------------------------

% intiialize an array to store the window labels for the signal file.
window_labels = zeros(num_windows, 1);
disp("size of the initialized window_labels vector: ")
disp(size(window_labels))


% define the threshold for the overlap that we'll allow for a window to be considered a pattern window (label = 1).
overlap_threshold = 0.5; % 50% of the window must overlap the pattern chunk (10sec spike).


% iterate through all windows
for i = 1:num_windows
    
    window_start = signal_windows(i, 1); 
    window_end = signal_windows(i, 2);
    window_length = window_end - window_start;
    % disp("window " + i + " start: " + window_start)
    % disp("window " + i + " end: " + window_end)

    % iterate through each pattern chunk and see if there is overlap
    for j = 1:num_pattern_chunks

        pattern_start = valid_pattern_chunks(j, 1);
        pattern_end = valid_pattern_chunks(j, 2);

        % compute the duration that the window overlaps the pattern chunk
        overlap_start = max(window_start, pattern_start);
        overlap_end = min(window_end, pattern_end);
        overlap_dur = max(0, overlap_end - overlap_start);

        % compute the % that the window overlaps the pattern chunk.
        overlap_percent = overlap_dur / window_length; 

        if overlap_percent >= overlap_threshold
            window_labels(i) = 1;
            break;
        else
            window_labels(i) = 0;
        end

    end
    
end

