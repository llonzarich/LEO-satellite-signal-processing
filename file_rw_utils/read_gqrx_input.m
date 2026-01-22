% credits: https://practicingelectronics.wordpress.com/2020/06/13/reading-gqrx-sdr-files-into-matlab/
% Reads a "raw" IQ file generate dby GQRX (running in Linux) and plots the
% spectrum.  Format of raw file is 32-bit float I, Q, ...
%
%
% W. Newhall KB2BRD
function nonzero_samples = read_gqrx_input(file, sub_sample)
    filename = strcat(file.folder,  "/", file.name);

    %% sub-sample a large file first or, read file directly to get samples
    if sub_sample
        
        Fs_MHz = 100;
        hw_sampling_time_in_seconds = 30; % usrp sampling time in seconds, HAS TO BE > 1
        sample_time_in_ms = 1*10^1; % only look at 10ms every second, coming to a million samples per second
        sample_chunk_size = sample_time_in_ms * 10^(-3) * Fs_MHz * 10^6; 
        start = 0;
        gap_size = (Fs_MHz*10^6) - sample_chunk_size;
        % total_samples = (Fs_MHz*10^6) * hw_sampling_time_in_seconds;
        iterations = hw_sampling_time_in_seconds; % will get sample_chunk_size samples per second
        s = sample_complex_binary(filename, start, sample_chunk_size, gap_size, iterations);
        disp(size(s));
        Ns = size(s, 1);

    else
        Ns = 60*100*10^6;
        % Ns = Inf;
        %Fs_MHz = 2.4;
        Fs_MHz = 100;
        % Modify limits of plot below if desired.
         
        % Read file
        fid = fopen(filename, 'r');
        s_dat = fread(fid, [2, Ns], 'float32').';
        fclose( fid );
    
        % Format signal data into complex signal
        s = s_dat(:,1) + 1j*s_dat(:,2);
    end
    %% compute average power of samples
    nonzero_samples = nonzeros(s);
    power = 20 * log10((real(nonzero_samples).^2) + (imag(nonzero_samples).^2));
    disp(size(power));
   
    %% plot time domain 
    t_us = (0:Ns-1)/(Fs_MHz);
    f = figure('visible','off');
    plot( t_us, [real(s), imag(s)] );
    xlabel( 'Time (us)' );
    ylabel( 'Normalized Amplitude' );
    legend(["real s", "imag s"]);
    disp(size(t_us));
    % xlim( [min(t_us), max(t_us)] )
    % xlim( [1, 10*10^7])
    % title(strcat('Time-Domain Recorded Signal for filename ', image_name));
    grid on;
    legend('I', 'Q')
    saveas(f, strcat(file.folder, "/statistics/", file.name(1:end-4) , "time_domain.png"));
    %%
    % f = figure('visible','off');
    % % f = figure();
    % xvals = 1:size(power, 1);
    % scatter( xvals, power, ".");
    % xlabel( 'Time (us)' );
    % ylabel( 'Power in dBV' );
    % % disp(size(t_us));qq
    % % xlim( [min(t_us), max(t_us)] )
    % ylim( [-200, -40])
    % % title(strcat('Time-Domain Recorded Signal for filename ', image_name));
    % grid on
    % % legend('I', 'Q')
    % saveas(f, strcat(file.folder, "/statistics/", file.name(1:end-4) , "_power_all_samples_zommed_out.png"));
    %% plot frequency domain 
    % figure(2)
    % plot(f_MHz, S_dB)
    % xlabel( 'Frequency (MHz)' )
    % ylabel( 'Normalized Magnitude (dB)' )
    % % xlim( [min(f_MHz), max(f_MHz)] )
    % ylim( [-40, 90] )
    % title('Spectrum of Recorded Signal for filename ' + filename)
    % grid on
    % pause
    
    %% plot power per every 10s (estimated length of a speedtest)
    % s_chunks = reshape(s, sample_chunk_size*10, []);
    % meanChunkPowerArray = zeros(3, 1);
    % 
    % for ix = 1:hw_sampling_time_in_seconds/10
    %     s1_power = nonzeros(s_chunks(:, ix));
    %     power = 20 * log10((real(s1_power).^2) + (imag(s1_power).^2));
    %     meanChunkPower = mean(power);
    %     disp("average power for first " + (ix*10) + " seconds: " + meanChunkPower + " dB");
    %     meanChunkPowerArray(ix, :) = meanChunkPower;
    % end
    % % savepath = strcat(file.folder, "/statistics/10s_chunk_power.txt");
    % 
    % fid = fopen(savepath, 'a+');
    % fprintf(fid, '%.4f %.4f %.4f\n', meanChunkPowerArray);
    % fclose(fid);
    %% clip out samples that have a power spike
    % samples_with_spike = nonzero_samples(44*10^6 : 54*10^6);
    % spike_power = 20 * log10((real(samples_with_spike).^2) + (imag(samples_with_spike).^2));
    % xaxis = 1:size(power, 1);
    % figure(3)
    % scatter(xaxis, power);
    % xlabel( 'samples' )
    % ylabel( 'power dBV' )
    % % xlim( [min(f_MHz), max(f_MHz)] )
    % ylim( [-70, -30] )
    % % title('Spectrum of Recorded Signal for filename ' + filename)
    % grid on
    % pause
end
