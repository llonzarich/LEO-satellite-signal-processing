function [signal_windows, num_windows, window_samples, iq_components] = og_window_signal(iq_signal_file)

% -------------------------------------------------------------------------------------------------------
% function: window_signal().
%
% purpose: pad/truncate each IQ signal file to 60sec and split it into windows.
%
% inputs: - the raw IQ signal file.
%
% outputs: - the start/end seconds of each window of the trimmed raw IQ signal file.
%          - number of windows
%          - number of samples per window
%          - I and Q channels
% -------------------------------------------------------------------------------------------------------


% define the sampling frequency.
F_s = 2.4e6;


% define the downsampling factor.
downsample_factor = 1000; 


% read the raw IQ signal file.
iq_signal_read = read_complex_binary(iq_signal_file);


% find the num samples in the given signal file.
actual_num_samples = length(iq_signal_read);
%disp("number of samples in signal file: " + actual_num_samples);


% find the dur (in seconds) of the given signal file.
actual_dur_sec = actual_num_samples / F_s;
%disp("duration (in seconds) of current signal file: " + actual_dur_sec)


% define the target file length (in seconds and num samples).
target_dur_sec = 60;
target_num_samples = target_dur_sec * F_s;
%disp("number of samples expected in a signal file: " + target_num_samples)


% pad the end of the signal file if it's <60 seconds.
if actual_dur_sec < target_dur_sec
    samples_to_pad = target_num_samples - actual_num_samples; % number of samples we need to fill with 0s for padding.

    iq_signal_read = [iq_signal_read; zeros(samples_to_pad, 1, 'like', iq_signal_read)]; % pad the signal file. 

    actual_dur_sec = target_dur_sec;  % update actual_dur sec after padding.
    % disp("signal padded to : " + actual_dur_sec + " seconds.")
end


% truncate the end of the signal file if it's >60 seconds.
if actual_dur_sec > target_dur_sec
    iq_signal_read = iq_signal_read(1:target_num_samples); % truncate the file.

    actual_dur_sec = target_dur_sec; % update actual_dur_sec after truncating.
    %disp("signal cut to: " + actual_dur_sec + " seconds.")
end


% downsample the FULL signal file.
downsampled_F_s = F_s / downsample_factor;
downsampled_iq_signal_read = downsample(iq_signal_read, downsample_factor);



% ----------------- IMPLEMENT 10-SEC SLIDING WINDOW FOR SPLITTING SIGNAL FILES -----------------------------------------------------------

% define window parameters
window_length_sec = 2; % TODO: change this according to approach.
stride_sec = 1; % TODO: change this according to approach.
disp("duration of each window: " + window_length_sec + " seconds")


% convert window parameters to samples.
window_samples = window_length_sec * downsampled_F_s; 
stride_samples = stride_sec * downsampled_F_s; 
disp("number of samples in each window: " + window_samples)


% compute the number of windows
signal_length = length(downsampled_iq_signal_read);
num_windows = floor((signal_length - window_samples) / stride_samples) + 1;
disp("number of windows in each signal file: " + num_windows)


% "collect" all window starts and ends (in samples).
window_starts = 1:stride_samples:(signal_length - window_samples + 1); 
window_ends = window_starts + window_samples - 1;
disp("(another check) number of windows in each signal file: " + length(window_starts))
% disp(window_starts)
% disp(window_ends)


% convert window start and ends to seconds.
% window_start_times = (window_starts - 1) / downsampled_F_s; % genuine (has decimals).
% window_end_times = (window_ends - 1) / downsampled_F_s; % genuine (has decimals).
window_start_times = (0:num_windows-1) * stride_sec; % clean
window_end_times = window_start_times + window_length_sec; % clean


% fill a 2D array with the start/end times of each window.
signal_windows = [window_start_times(:), window_end_times(:)];


% initialize a 3D array to store I and Q components as separate channels.
iq_components = zeros(window_samples, 2, num_windows);


% define windows.
for i = 1:num_windows
    start_idx = window_starts(i);
    end_idx = window_ends(i);
    
    window = downsampled_iq_signal_read(start_idx:end_idx);
    % disp("number of samples in downsampled window: " + length(window))
    
    iq_components(:, 1, i) = real(window); % i channel.
    iq_components(:, 2, i) = imag(window); % q channel.
end


end
