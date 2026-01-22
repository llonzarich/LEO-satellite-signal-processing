function write_raw_complex_binary(iq_array, file_path, append)
    % % Example IQ data
    % I = [0.1, 0.2, 0.3, 0.4]; % In-phase component
    % Q = [0.5, 0.6, 0.7, 0.8]; % Quadrature component
    % % Combine into complex format
    % IQ_data = I + 1i*Q;
    % % Open a file for binary writing
    if append
        fileID = fopen(file_path, 'ab');
    else
        fileID = fopen(file_path, 'wb');
    end
    % Check if the file opened successfully
    if fileID == -1
        error('Failed to open the file.');
    end
    % Write the IQ data to the file
    % Here, we assume single precision (32-bit) for both I and Q components
    fwrite(fileID, [real(iq_array); imag(iq_array)], 'float32');
    % Close the file
    fclose(fileID);
    disp('IQ data has been written to output file');
end