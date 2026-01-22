% function [pattern_detected] = detect_pattern(chunk_labels)
function[pattern_detected] = detect_pattern(chunks, chunk_labels)
% -------------------------------------------------------------------------------------------------------
% function: detect_pattern()
% purpose: - determine whether a given signal has "our" pattern or not. I
%            I am specifying that "our" pattern is recognized in the signal
%            file by AT LEAST 2 cycles of signal transmission
%            uplink --> transmission off.
%          - this threshold can be modified (i.e., we could increase or
%            decrease how strict we are about what we'll consider our signal.
% inputs: chunk_labels (a vector with the 0/1 labels for each of the 12 rows of a signal file from the csv file.)
% outputs a 0 or 1 to determine whether there is our pattern in the file
% -------------------------------------------------------------------------------------------------------


    pattern_detected = 0; % default is 'no signal pattern' found in this signal file.
    num_chunks = length(chunk_labels);
    indices_with_pattern = [];
    
    
    % find indices (aka, chunks) where there is a pattern (labeled 1).
    for i = 1:num_chunks
        if chunk_labels(i) == 1 
            indices_with_pattern(end+1) = i;
        end
    end


    % chunks(:, 1) gives start_sec of each chunk
    % chunks(:, 2) gives end_sec of each chunk


    % check if any two of the indices where the pattern begins are spaced such that the end sec of the i-th index with pattern = the start sec of the i + 1 indix with pattern.
    % iterate through all the indices that have a pattern (labeled 1)
    for j = 1:(length(indices_with_pattern) - 1)

        curr_pattern_idx = indices_with_pattern(j);
        next_pattern_idx = indices_with_pattern(j + 1);

        curr_pattern_end_sec = chunks(curr_pattern_idx,2);
        next_pattern_start_sec = chunks(next_pattern_idx, 1);

        disp("current pattern chunk end sec: " + curr_pattern_end_sec)
        disp("next pattern chunk start_sec: " + next_pattern_start_sec)

        % if the end_sec of the j-th index where a pattern begins is equal to the start_sec of the j+1st index of a pattern chunk, then the signal has our pattern.
        if curr_pattern_end_sec == next_pattern_start_sec
           pattern_detected = 1;
           break
       end
    end
end





    % for i = 1:num_chunks
    % 
    %     if chunk_labels(i) == 1
    %         pattern_detected = 1;
    %     end
    % 
    % end



    % 
    % % find indices (aka chunks) where [1 0] pattern begins.
    % for i = 1:(num_chunks - 1)
    %     % subsequence = chunk_labels(i:i + pattern_length - 1);
    % 
    %     if chunk_labels(i) == 1 && chunk_labels(i + 1) == 0
    %         indices_with_pattern(end+1) = i;
    %     end
    % end
   



    
% end

    % iterate through all chunks and find indices of [1 0]. 
    % if the indices are spaced apart by 1, then the file gets a 1.
    % example: index 5 (aka, chunk5) we see [1 0] then if index 7 has [1 0]
    % we give hte file a 1 if not, we go to the next index (n) with [1 0] and see if index n + 2 has [1 0] pattern etc etc....
    
    


    % % iterate through each of the 12 chunk labels (each file has 12 time chunks, so each file has 12 corresponding labels).
    % while i < chunks
    % 
    %     % if the current chunk label = 1 and the next chunk exists (aka, i != 12 because that would mean i+1=13, but there aren't > 12 chunks) AND has a label = 0,...
    %     if chunk_labels(i) == 1 && i + 1 <= chunks && chunk_labels(i+1) == 0
    %         num_cycles = num_cycles + 1;
    %         i = i + 2; % skip over the i+1 iteration.
    % 
    %     % if the current chunk label = 0,...    
    %     else
    %         i = i + 1; % move to the next iteration.
    %     end
    % end
    % 
    % 
    % % determine if we saw our pattern (2 cycles of 1 0).
    % if num_cycles >= 2
    %     disp("MORE THAN 2 CYCLES")
    %     pattern_detected = 1;
    % end




    % pattern_detected = 0; % default is 'no signal pattern' found in this signal file.
    % pattern = [1 0 1 0]; % define our pattern to be 2 cycles of signal transmission uplink --> transmission off.
    % chunks = length(chunk_labels);
    
    % % iterate through the data with a sliding window.
    % for i = 1:(chunks - length(pattern) + 1)
    % 
    %     % extract a subsequence of the same length as the pattern.
    %     subsequence = chunk_labels(i:i + length(pattern) - 1);
    % 
    %     if isequal(subsequence, pattern)
    %         pattern_detected = 1;
    %         break
    %     end
    % end
% end