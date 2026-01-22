% -------------------------------------------------------------------------------------------------------------------------------------
% Purpose: - this script will generate synthetic data by injecting gaussian white noise into the original 141 real, clean raw signal files.
%          - noise will be varying levels of amplitude
% -------------------------------------------------------------------------------------------------------------------------------------


iq_signal_path = '/home/llonzarich/Desktop/lstm_lr_model_data';
iq_signal_dir = dir(fullfile(iq_signal_path, '**', '*.raw'));


fprintf("Found %d .raw files in the iq signal dir .\n", length(iq_signal_dir)); % ==> the number of iq files in the hard drive.


output_dir = '/home/llonzarich/Desktop/lstm_lr_model_data/synthetic_data';


% make the output directory if it doesn't already exist.
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end


% signal parameters
F_s = 2.4e6; % sampling frequency.
snr_db = 10; % signal-to-noise ratio for adding additive gaussian white noise to raw signal files.


% iterate through the raw signal files and add noise to them.
for i = 1:length(iq_signal_dir)

    % 'file' holds the properties of the i-th file in the .raw IQ signal file directory. Use file.name to see the full .raw IQ filename.
    file = iq_signal_dir(i); 


    % generate a new name for the new (synthetically generated) raw signal file.
    [~, base_name, ~] = fileparts(file.name);
    output_filename = fullfile(output_dir, base_name + "_synth.raw");


    if strcmp(file.name, '.') || strcmp(file.name, '..') || file.isdir
        continue
    end
    [~, ~, ext] = fileparts(file.name);
    if ~strcmp(ext, '.raw')
        continue
    end


    % define the path to the i-th raw signal file.
    filepath = fullfile(file.folder, file.name);
    % disp("filepath: " + filepath)


    % read the I and Q components of the raw signal file.
    iq_signal_read = read_complex_binary(filepath); 


    % compute the signal power of the raw signal.
    signal_power = mean(abs(iq_signal_read) .^ 2);
    disp("signal power of the "  + i + " raw signal file: " + signal_power)


    % generate new signal file with noise added to it.
    synth_signal = awgn(iq_signal_read, snr_db, 'measured');


    % write the new (synthetically generated) raw signal to the folder 'synth_data'.
    fid = fopen(output_filename, 'w');
    fwrite(fid, [real(synth_signal) imag(synth_signal)]', 'float32');
    fclose(fid);
end
