function [signal_windows, num_windows, window_samples, iq_components] = A5_window_signal(trimmed_file)

% -------------------------------------------------------------------------------------------------------
% function: thirtysixsec_window_signal().
%
% purpose: split the trimmed 36 second raw IQ signal file sequences of overlapping same-size windows.
%
% inputs: - the trimmed 36 second raw IQ signal file.
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


% define the downsampled frequency.
downsampled_F_s = F_s / downsample_factor;


% downsample the FULL trimmed signal file.
downsampled_iq_signal_read = downsample(trimmed_file, downsample_factor);
disp("btw, the number of samples in trimmed signal file: " + length(trimmed_file))
disp("number of samples in downsampled trimmed signal file: " + length(downsampled_iq_signal_read))


% define the number of samples we expect in the downsampled trimmed 36 second signal file
target_num_samples = 36 * downsampled_F_s;
disp("target number of samples we expect in the downsampled trimmed 36 second signal file: " + target_num_samples)


% ----------------- IMPLEMENT 10-SEC SLIDING WINDOW FOR SPLITTING SIGNAL FILES -----------------------------------------------------------

%disp("HELLO FROM THE BEGINNING OF SPLITTING SIGNAL FILE WITH SLIDING WINDOW")


% define window parameters
window_length_sec = 12; % TODO: change this according to approach.
stride_sec = 2; % TODO: change this according to approach.


% convert window parameters to samples.
window_samples = window_length_sec * downsampled_F_s; 
stride_samples = stride_sec * downsampled_F_s; 
disp("window length in seconds: " + window_length_sec)
disp("window length in number of samples: " + window_samples)


% determine the number of windows.
signal_length = length(downsampled_iq_signal_read);
num_windows = floor((signal_length - window_samples) / stride_samples) + 1;
disp("number of windows in the signal file: " + num_windows)


% "collect" all window start and end seconds.
window_starts = 1:stride_samples:(signal_length - window_samples + 1); 
window_ends = window_starts + window_samples - 1;


% convert window start and ends to seconds.
% window_start_times = (window_starts - 1) / downsampled_F_s; % genuine (has decimals).
% window_end_times = (window_ends - 1) / downsampled_F_s; % genuine (has decimals).
window_start_times = (0:num_windows-1) * stride_sec; % clean
window_end_times = window_start_times + window_length_sec; % clean


% fill a cell 2D array with the start/end times of each window.
signal_windows = [window_start_times(:), window_end_times(:)];


% initialize a 3D array to store I and Q components as separate channels.
iq_components = zeros(window_samples, 2, num_windows);


% define windows.
for i = 1:num_windows
    start_idx = window_starts(i);
    end_idx = window_ends(i);
    % disp("window end: " + i + ": " + window_ends(i))
    
    window = downsampled_iq_signal_read(start_idx:end_idx);
    % disp("number of samples in downsampled window: " + length(window))
    
    iq_components(:, 1, i) = real(window); % i channel.
    iq_components(:, 2, i) = imag(window); % q channel.
end


end
