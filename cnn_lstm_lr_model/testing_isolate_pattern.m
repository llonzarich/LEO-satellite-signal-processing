
% test: calling select_chunk.m function 

path = "/Volumes/PARTITION3/fc1075mhz_5sec_akirah/maybe_signal";
iq_signal_dir = dir(fullfile(path, '**', '*.raw'));


fprintf("Found %d .raw files in the iq signal dir .\n", length(iq_signal_dir)); % ==> the number of iq files in the hard drive.


% create csv file for signal time interval annotations.
csv_filename = 'auto_annotations_testing.csv';
disp("Name of csv file being written to: " + csv_filename);


% delete the old csv file if it already exists.
if isfile(csv_filename)
    delete(csv_filename);
end


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

    [has_pattern, moving_avg_power_vec, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk] = isolate_pattern(filepath);


    filenames = repmat(string(file_id), size(chunks, 1), 1); 

    % [chunks, labels] = auto_signal_annotating(filepath); 
    % % [chunks, labels] = untitled(filepath);
    % % ==> chunks: 12 x 2 matrix as [start_sec end_sec].
    % % ==> labels: 12 x 1 vector as [0 or 1].
    % % disp(chunks(:,:));
    % % disp(labels(:,:));

    % combine filename, starting sec's, ending sec's, and labels into a table.
    T = table(filenames, chunks(:,1), chunks(:,2), labels, ...
        'VariableNames', {'filename', 'start_sec', 'end_sec', 'label'});

    % append data to csv file.
    if i == 1
        writetable(T, csv_filename);
    else
        writetable(T, csv_filename, 'WriteMode', 'Append', 'WriteVariableNames', false);
    end

    disp("finished writing data for file " + file_id + ".");

end