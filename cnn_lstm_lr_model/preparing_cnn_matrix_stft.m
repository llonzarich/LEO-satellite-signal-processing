% this script prepares the 2D input data for the CNN by taking the stft of the signal in windowed segments and stacking each window on top of each other. 


% signal parameters
F_s = 2.4e6;
num_samples = x;


% window parameters
window_len = 2^14; % recommended to be a power of 2.
num_fft_pts = 2 * window_len; % number of fft points.
overlap = x; % defining the overlap to be 75%.
hop = window_len * (1 - overlap); % hop size
w = hanning(window_len, 'periodic'); % hanning window.
overlap_len = window_len - hop;


% grab a file
path = "/Volumes/PARTITION3/fc1075mhz_5sec_akirah/maybe_signal";
iq_signal_dir = dir(fullfile(path, '**', '*.raw'));
fprintf("Found %d .raw files in the iq signal dir .\n", length(iq_signal_dir)); % ==> the number of iq files in the hard drive.


% for i = 1:length(iq_signal_dir)
for i = 9:9
% for i = [1, 5, 11, 12, 13]

    file = iq_signal_dir(i); % 'file' holds the properties of the i-th file in the .raw IQ signal file directory. Use file.name to see the full .raw IQ filename.
    
    file_id = file.name(15:20) + ".raw"; % 6 digit file id.
    disp("6 digit file id: " + file_id)

    if strcmp(file.name, '.') || strcmp(file.name, '..') || file.isdir
        continue
    end
    [~, ~, ext] = fileparts(file.name);
    if ~strcmp(ext, '.raw')
        continue
    end

    filepath = fullfile(file.folder, file.name);
    % disp("filepath: " + filepath)


    % read the raw IQ signal file.
    iq_signal_read = read_complex_binary(filepath); % read the .raw IQ signal file.

    
    % perform STFT
    [s, f, t] = stft(iq_signal_read, F_s, "Window", w, "OverlapLength", overlap_len, "FFTLength",num_fft_pts);
    % ==> signal is divided into overlapping segments of length 'window_len' with the specified overlap.
    % ==> s stores the resulting spectra for each windowed segment.
    % ==> f stores the corresponding frequency values. 
    % ==> t stores the corresponding time values.

    
    % filter out frequencies < 0
    positive_freq = f >= 0;
    f_pos = f(positive_freq,:); 
    s_positive = s(positive_freq,:);
    sf_w = s_positive / sum(w);
    abs_sf = abs(sf_w);
    avg_mag_s = 2 * abs_sf(1:nfft/2+1);
    avg_mag_sdB = 20*log10(avg_mag_s);

end