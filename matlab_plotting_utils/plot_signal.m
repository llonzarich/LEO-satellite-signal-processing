addpath(genpath('/home/wairimu/leo-signal-proc/file_rw_utils'));
addpath(genpath('/home/wairimu/leo-signal-proc/matlab_utils'));
addpath(genpath('/home/wairimu/leo-signal-proc/matlab_plotting_utils'));

% fname = '/home/wairimu/feb20data/fc1125mhz_fs100mhz_strong_signal.raw';
% fname1 = '/media/wairimu/T7/feb9data/startup_3/gqrx_20250209_200014_1133196700_100000000_fc.raw';

samples = 100*10^6;
% path = '/media/wairimu/Elements/feb21data/speedtest_signals/1125mhz_fc';
% path = '/media/wairimu/T7/starlink_off_1125mhz/starlink_on_iperf_200mbps';
% path = '/media/wairimu/Elements/iperf_continuously_fox_chapel';
path = '/media/wairimu/Elements/starlink_off';
dirlist = dir(path);
T = struct2table(dirlist);
sortedTable = sortrows(T, 3, 'descend');
dirlist = table2struct(sortedTable);
plots_done_fname = strcat(path, '/plots_done_fnames.txt');


for dir_ix = 1:length(dirlist)
    file = dirlist(dir_ix);
    % file = dir(fname_preamble_signal);
    if strcmp(file.name, '.') || strcmp(file.name, '..') || file.isdir 
        continue
    end
    ext= file.name(end-3:end);
    if strcmp(ext,'.txt') || strcmp(ext,'.png')
        continue
    end 

    fname = strcat(file.folder, '/', file.name);

    % check whether file name has been executed already 
    plots_done_array = readlines(plots_done_fname);
    file_already_done = false;
    for countix = 1:length(plots_done_array)
        % disp(plots_done_array(countix));
        % disp(strcat(fname(1:end-4)));
        if ismember(plots_done_array(countix), fname) 
            file_already_done = true;
            break
        end
    end
    if file_already_done
        continue
    end

    iterations_in_sec = floor(file.bytes/(100*10^6*8));
    iterations_in_msec = 100*floor(file.bytes/(100*10^6*8));
    iterations = iterations_in_sec;
    % disp(strcat('plotting ', fname));

    % create folder for plots
    plots_folder = strcat(fname(1:end-4), '_plots');
    mkdir(plots_folder);
    % disp(strcat("created plots folder ", plots_folder));

    for i = 0:iterations

        path_to_save_image = strcat(plots_folder, '/second_', num2str(i),  '.png');

        % check if this second was already plotted
        plots_folder_dir = dir(plots_folder);
        plots_folder_dir = struct2cell(plots_folder_dir);
        if any(ismember(plots_folder_dir(1, :), path_to_save_image))
            continue
        end

        start = i*8*samples;

        y_chunk = read_complex_binary(fname, start, samples); % 10^6 samples is equal to 10ms of data
        y_chunk = nonzeros(y_chunk);

        % only plot this if the chunk actually has a signal
        %if sum(real(y_chunk)>0.06) < 5 || sum(imag(y_chunk)>0.06) < 5
        %    continue
        % end
        disp(strcat('path to save image: ', path_to_save_image));

        fig = figure('Visible','off');
        plot(real(y_chunk));
        hold on;
        plot(imag(y_chunk));
        xlabel( 'time' )
        ylabel( 'amplitude' )
        % ylim( [-70, -30] )
        title(strcat("time domain for second " + num2str(i)));
        grid on
        exportgraphics(fig, path_to_save_image);

        % pause(10);

    end
    % pause(10);
    % write fname in plots_done_fname
    writelines(fname, plots_done_fname, WriteMode="append");

end
