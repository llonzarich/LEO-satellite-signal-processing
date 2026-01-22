function [avg_bandpowers_vec, neo_feature_vec] = signal_chunking(iq_signal_file, fs, start_sec, end_sec, bands)


% -------------------------------------------------------------------------------------------------------
% function: signal_chunking().
%
% purpose: - creates 1 of the 12 .raw IQ signal file chunks using the 'start_sec' and 'end_sec' annotations (from a row in the csv file).
%          - feature extraction for the just-created chunk
% 
% features extracted per chunk: - avg power of each freq band in that chunk.
%                               - NEO
% 
% inputs: - the start and end seconds of a chunk.
%         - the sampling freq rate. 
%         - the freq bands I defined.
%
% outputs: - a 10x1 column vector with the avg bandpower of each of the 10 freq bands in the signal chunk.
%          - a 4x1 column vector with neo features for each of the 10 freq bands in the signal chunk.
% -------------------------------------------------------------------------------------------------------

    
    % calculate sample indices of the .raw file.
    start_sample = floor(start_sec * fs);
    end_sample = ceil(end_sec * fs); 
    num_samples = end_sample - start_sample;
    % disp("start_sample: " + start_sample)
    % disp("end_sample: " + end_sample)
    % disp("num_samples in this chunk: " + num_samples)
    
    
    % calculate byte offsets of starting index of sample chunks.
    byte_offset = start_sample * 8;


    % get number of complex samples in the file
    file_info = dir(iq_signal_file);
    total_samples = file_info.bytes / 8; 
    % disp("total num_samples in the whole file: " + total_samples)


    % handling feature extraction of zero-padded chunks...
    % if the chunk is located beyond the actual length of the file, return a 10 x 1 vector of 0s (bandpowers) and a 4 x 1 vector of 0s (neo features).
    % note: in 'auto_signal_annoating.m', I padded all files to be 60 seconds long by adding 0s to the end.(aka, I noted start_sec and end_sec of chunks that aren't actually there). 
    if start_sample > total_samples
        avg_bandpowers_vec = zeros(10, 1);
        neo_feature_vec = zeros(4, 1);
        return
    end
    
    
    % read chunks of the full IQ data file (chunks are dependent upon the pre-defined indices)
    signal_chunk = read_complex_binary(iq_signal_file, byte_offset, num_samples);
        

    % the number of samples in the current chunk
    expected_samples = ceil((end_sec - start_sec) * fs);
    
    
    % if the number of samples in the current chunk exceeds the number of samples in the actual chunk.
    if length(signal_chunk) < expected_samples
        pad_len = expected_samples - length(signal_chunk);
        signal_chunk = [signal_chunk; complex(zeros(pad_len, 1))];
    end

    
    N = length(signal_chunk);
    f = linspace(-fs/2, fs/2, N);


    % NEO computation.
    x = abs(signal_chunk);
    neo = x(2:end-1).^2 - x(3:end) .* x(1:end-2);
    neo = abs(neo);


    % NEO feature computations.
    mean_neo = mean(neo); % can avg out noise in a chunk.
    std_neo = std(neo); % captures variability of energy in a chunk (spike/pattern chunks should increase in variance.
    max_neo = max(neo); % the most energetic point in a chunk
    threshold = 0.1 * max_neo;
    num_spikes_neo = sum(neo > threshold); % detects if any spike behavior exists in a chunk


    % create NEO feature vector to return.
    neo_feature_vec = [mean_neo; std_neo; max_neo; num_spikes_neo];
    
    
    % take fft of the chunk (time domain --> freq domain).
    fft_chunk = abs(fftshift(fft(signal_chunk))) .^ 2;
    
    
    % initalize a 10x1 column vector to store the avg power of the signal in each freq band.
    avg_bandpowers_vec = zeros(10, 1);
    
    
    % compute he avg power of the signal in each freq band.
    for band = 1:10
    
        % get the indices corresponding to the current band
        idx = f >= bands(band, 1) & f < bands(band,2);
    
        % find the avg power of the signal in the current band.
        avg_bp = mean(fft_chunk(idx));
        % disp("avg bp of band " + band + ": " + avg_bp)
    
        % append the avg bandpower (of the current band) to the 'avg_bandpowers' vector).
        avg_bandpowers_vec(band) = avg_bp;
    end
    % ==> a filled 10x1 column vector with bandpower features to return.

end

