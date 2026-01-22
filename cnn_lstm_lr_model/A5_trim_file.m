function [trimmed_signal] = A5_trim_file(iq_signal_file, start_sec_first_pattern_chunk, end_sec_last_pattern_chunk, F_s)

% -------------------------------------------------------------------------------------------------------
% function: trim_file().
%
% purpose: trim the raw IQ signal file to be ONLY the section bounded by the input start and end seconds
%
% inputs: - the .raw IQ signal file
%         - start/end times of the pattern chunk
%         - sampling frequency, F_s
%
% outputs: - the trimmed raw IQ signal file.
% -------------------------------------------------------------------------------------------------------


filename = iq_signal_file;


disp("planned start sec of signal file: " + start_sec_first_pattern_chunk)
disp("planned end sec of signal file: " + end_sec_last_pattern_chunk)


% calculate sample indices of the raw IQ signal file.
start_sample = floor(start_sec_first_pattern_chunk * F_s);
end_sample = ceil(end_sec_last_pattern_chunk * F_s);
num_samples = end_sample - start_sample;
disp("start_sample: " + start_sample)
disp("end_sample: " + end_sample)
disp("num samples in trimmed file: " + num_samples)


% calculate byte offsets of starting index of sample chunks.
byte_offset = start_sample * 8;


% get number of complex samples in the file
file_info = dir(filename);
total_samples = file_info.bytes / 8;
disp("num_samples in the whole file: " + total_samples)



% read ONLY the pattern chunk of the full IQ signal file.
trimmed_signal = read_complex_binary(filename, byte_offset, num_samples);


end




