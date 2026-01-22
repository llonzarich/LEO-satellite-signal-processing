clc;
close all;
clear all;

addpath(genpath("/home/debroglie2/leo-signal-proc/file_rw_utils"));
addpath(genpath("/home/debroglie2/leo-signal-proc/matlab_utils"));
addpath(genpath("/home/debroglie2/leo-signal-proc/file_rw_utils"));
addpath(genpath("/home/debroglie2/leo-signal-proc/matlab_plotting_utils"));
addpath(genpath("/home/debroglie2/leo-signal-proc/plots"));
%%
path = '/media/debroglie2/T7/fc1075mhz_8sec';
F_s = 2.4e6;

dirlist = dir(path);
T = struct2table(dirlist);
sortedTable = sortrows(T, 3);
dirlist = table2struct(sortedTable);

% plots_done_fname = strcat(path, '/plots_done_fnames.txt');

fig = figure("Visible","off");
paperSize=[50,50,1260,820];
printSize=[0 0 16 9];
fig.Position = paperSize; 
fig.PaperPosition = printSize;
% disp(dirlist)

for i = 1:length(dirlist)
    file = dirlist(i);
    if file.name == "." || file.name == ".." || file.isdir 
        continue
    end
    ext= file.name(end-3:end);
    if ext ~= ".raw" 
        continue
    end

    % plots_done_array = readlines(plots_done_fname);
    % file_already_done = false;
    % for countix = 1:length(plots_done_array)
    %     if ismember(plots_done_array(countix), file.name) 
    %         file_already_done = true;
    %         break
    %     end
    % end
    % if file_already_done
    %     continue
    % end

    file_id = file.name(15:20);
    
    % for j = 0:iterations_in_sec
        % start = j*8*100*10^6; 
    file_path = strcat(file.folder, '/', file.name);
    y = read_complex_binary(file_path); 
    num_samples = length(y);
    total_seconds =  num_samples/ F_s;
    xaxis = 0:1/F_s:total_seconds;
    xaxis = xaxis(1:end-1);

    % compute stft
    % divide signal into 256-sample segments 
    % window each segment using a Kaiser window with shape parameter β = 5
    % specify 220 samples of overlap between adjoining segments
    % specify DFT length of 512 
    % output frequency and time values at which STFT is computed
    samples_in_segment = 1000;
    % samples_in_segment = 1e4;
    overlap_btwn_segments_in_samples = 10;
    % overlap_btwn_segments_in_samples = 1e2;
    % dft_length = frame_length_in_samples;
    dft_length = 2000;
    % dft_length = 2e4;

    window = kaiser(samples_in_segment,5);

    % fig = figure("Visible","off");

    [s,f,t] = stft(y,F_s,Window=window,OverlapLength=overlap_btwn_segments_in_samples,FFTLength=dft_length);
    % stft(y,fs,Window=window,OverlapLength=overlap_btwn_segments_in_samples,FFTLength=dft_length);

    % fig = figure()
    sdb = mag2db(abs(s));
    mesh(t,f/1000,sdb);
    % mesh(f/1e6,t,sdb');

    cc = max(sdb(:))+[-20 0];
    % cc = max(sdb(:))+[-60 60];
    ax = gca;
    ax.CLim = cc;
    view(2)
    a = colorbar

    a.Label.String ="signal strength (dB)";
    xlabel('time (s)')
    ylabel('frequency (MHz)')
    plot_fname = strcat('/home/debroglie2/may19plots/spectrogram_', file_id, '.png');
    % plot_fname = '/home/debroglie2/spectrogram.png';
    disp(plot_fname)
    % savefig(gcf, plot_fname, 'compact');
    % tic; savefig(gcf, plot_fname, 'compact', '-v7.3'); toc;
    
    tic; exportgraphics(fig, plot_fname); toc;
    clf(fig);

    % exportgraphics(fig, plot_fname, 'Resolution', 1000);

    % exportgraphics(fig, '/home/debroglie2/leo-signal-proc/plots/100MHz_spectrogram_ch1_2.pdf', 'Resolution', 1000);
    % matlab -nodisplay -nosplash -nodesktop -r "run('/home/debroglie2/leo-signal-proc/compute_stft.m');exit;"

    % instead of writing filename to file, move to plots_done folder -- this may be a faster operation
    % writelines(file.name, plots_done_fname, WriteMode="append");
    move_command = ['mv' ' ' file_path '/plots_done'];
    disp(move_command);
    system(move_command);

end
return;
