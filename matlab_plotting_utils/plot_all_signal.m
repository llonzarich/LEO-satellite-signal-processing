addpath(genpath("/home/debroglie2/leo-signal-proc/file_rw_utils"));
addpath(genpath("/home/debroglie2/leo-signal-proc/matlab_utils"));
addpath(genpath("/home/debroglie2/leo-signal-proc/plots"));
%%
path = '/media/debroglie2/Elements/may13';
F_s = 2.4e6;

dirlist = dir(path);
T = struct2table(dirlist);
sortedTable = sortrows(T, 3);
dirlist = table2struct(sortedTable);

plots_done_fname = strcat(path, '/plots_done_fnames.txt');

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

    % iterations_in_sec = floor(file.bytes/(100*10^6*8));

    disp(file.name);
    % file_id = file.name(15:20);
    file_id = file.name(1:end-4);

    disp(file_id);
    
    % for j = 0:iterations_in_sec
        % start = j*8*100*10^6; 
    y_chunk = read_complex_binary_from_rtlsdr(strcat(file.folder, '/', file.name)); 
    num_samples = length(y_chunk);
    total_seconds =  num_samples/ F_s;
    xaxis = 0:1/F_s:total_seconds;
    xaxis = xaxis(1:end-1);

    % fig = figure("Visible","off");
    % xaxis_fft = F_s/num_samples*(0:num_samples-1);
    % plot(xaxis_fft, abs(fft(y_chunk)));
    % title('signal fft');
    % xlabel('frequency(Hz)');
    % ylabel('Amplitude');
    % % xticks(1:xaxis_fft(end));
    % grid on;
    % path_to_save_image = strcat(path, '/', file_id, '_fft.png');
    % exportgraphics(fig, path_to_save_image);

    fig = figure("Visible","off");
    plot(xaxis, real(y_chunk));   
    hold on;
    plot(xaxis, imag(y_chunk));             % Plot the original signal
    title('signal');
    xlabel('Time [s]');
    ylabel('Amplitude');
    xticks(1:xaxis(end));
    grid on;
    % saveas(fig, strcat("/home/debroglie2/leo-signal-proc/pss_plots/", file_id, "_signal_", num2str(j), ".png"));
    path_to_save_image = strcat(path, '/', file_id, '.pdf');
    disp(path_to_save_image);
    exportgraphics(fig, path_to_save_image);
    % end
    disp(file.name)
    disp(plots_done_fname)

    % fileID = fopen(plots_done_fname,'w');
    % nbytes = fprintf(fileID,file.name)
    % writelines(file.name, plots_done_fname, WriteMode="append");

end
return;
