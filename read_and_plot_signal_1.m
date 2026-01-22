addpath(genpath(fullfile(getenv('HOME'), 'Desktop', 'CMU_REUSE')));


filename = "narrowband_rtlsdr_174315.raw";


wideband = false; % to specify which function we'll call.


if wideband
    % wideband signal -- since these files are large, read only a chunk at a time.
    % function format: read_complex_binary(filename, start, count)
    % every second, 100e6 samples are recorded, with 8 bytes per sample. 

    % F_s = 100e6; % wideband signal sampling frequency.
    % starting_second = 3; % start reading from the 3rd second.
    % duration_seconds = 60; % stop reading at second 30. (reading 30 seconds worth of data).
    % n_bytes_per_sample = 8; % 8 bytes per sample for complex numbers.
    % y = read_complex_binary(filename, starting_second*n_bytes_per_sample*F_s, F_s); % reading 1 second. 
    % y = read_complex_binary(filename, starting_second*n_bytes_per_sample*F_s, duration_seconds*F_s); % reading 30 seconds.
else
    % narrowband signal.
    % function format: read_complex_binary(filename, start, count)
    % every second, 2e6 samples are recorded, with 8 bytes per sample. 
    
    F_s = 2.4e6; % narrowband signal sampling frequency
    starting_second = 0; % start reading from second 0.
    duration_seconds = 60; % stop reading at second 60. (reading 60 seconds worth of data)
    n_bytes_per_sample = 8;
    % y = read_complex_binary(filename, starting_second*n_bytes_per_sample*F_s, F_s);  % reading 1 second. assign the read .raw files (I and Q components) into variable y.
    y = read_complex_binary(filename, starting_second*n_bytes_per_sample*F_s, duration_seconds*F_s);  % reading 60 seconds. assign the read .raw files (I and Q components) into variable y.
    disp('Done reading .raw file')
end


num_samples = length(y);
fprintf('num_samples: %d\n', num_samples)


% plot signal in time domain
disp('Starting to plot signals in time domain')
total_seconds =  num_samples/ F_s;
xaxis = 0:1/F_s:total_seconds;
xaxis = xaxis(1:end-1);
figure; % create a clean figure window.
plot(xaxis, real(y));
hold on;
plot(xaxis, imag(y));
title('Time Domain Signal');
xlabel('Time (s)');
ylabel('Amplitude');
saveas(gcf, 'plotted_signal_files/time_domain_plot_narrowband_rtlsdr_174315.png')


% plot signal in frequency domain
disp('Starting to plot signals in frequency domain')
xaxis_fft = F_s/num_samples*(0:num_samples-1);
figure; % create a clean figure window.
plot(xaxis_fft, abs(fft(y)));
title('Frequency Domain Signal');
xlabel('frequency (Hz)');
ylabel('PSD (V^2/Hz)');
saveas(gcf, 'plotted_signal_files/frequency_domain_plot_narrowband_rtlsdr_174315.png')


return;