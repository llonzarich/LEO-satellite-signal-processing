%
% Copyright 2001 Free Software Foundation, Inc.
% 
% This file is part of GNU Radio
% 
% GNU Radio is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3, or (at your option)
% any later version.
% 
% GNU Radio is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with GNU Radio; see the file COPYING.  If not, write to
% the Free Software Foundation, Inc., 51 Franklin Street,
% Boston, MA 02110-1301, USA.
% 
% b = sample_complex_binary('/media/wairimu/Elements/jan27data100mhz/100mhzsamplingrate_sample_2.dat', 100*10^6, 1*10^6, 0);
% disp(size(b));

function v = sample_complex_binary (filename, start, count, gap_size, iterations)

  %% usage: read_complex_binary (filename, [count])
  %% filename: filename
  %% start: start position in samples (ie, start from the 0th sample; start from the 500th sample)
  %% count: sample chunk size
  %% gap_size: gap size between sample chunk
  %% iterations: how many rounds of sampling will be done; equal to total samples/sample chunk size
  %% -------------------------------------------------------------------------------------------------
  %%  open filename and return the contents as a column vector, 
  %%  treating them as 32 bit complex numbers
  %%  sample filename by taking 1 sample every sample_rate samples
  %%  return the sampled contents of filename as a column vector, 
  %%  with each row of the vector being 32 bit complex number
  %%  the returned vector will have (file_size/sample_rate)*chunk_size rows, and 2 columns
  %%  and you will ahve to do this iteration (file_size/sample_rate) times

  m = nargchk (1,5,nargin);
  % if (m)
  %   usage (m);
  % end

  if (nargin < 2)
    start = 0;
    count = Inf;
  end

  f = fopen (filename, 'rb');
  if (f < 0)
    v = 0;
  else
    fseek(f, start, -1);
    t = zeros (2, count*iterations);
    t_count = 1;
    fopen(f)
    chunk = fread(f, [2, count], 'float32');

    % while numel(chunk) == count * 2 % TODO: change this to stop when the number of sample chunks is equal to the number of iterations set by the caller function. currently, this is reading till the end of the file
    while t_count < (count*iterations) % TODO: change this to stop when the number of sample chunks is equal to the number of iterations set by the caller function. currently, this is reading till the end of the file
      chunk_length = size(chunk, 2);
      % If the array is shorter than the desired length, pad with zeros
      if chunk_length < count
          % Pad with zeros at the end
          chunk = [chunk, zeros(2, count - chunk_length)];
      end
      t(:, t_count : t_count+count-1) = chunk;
      % t = cat(2, t, chunk);
      t_count = t_count+count;
      % large_file_count = large_file_count+(2*gap_size);
      % 1 SAMPLE IS 8 BYTES 
      % Skip the gap between samples
      status = fseek(f, 8*(gap_size), 0);
      % disp("status " + status);  
      chunk = fread(f, [2, count], 'float32');
      % disp("size of chunk: "+ numel(chunk));
    end
    % disp("estimated file size: " + ftell(f) + " bytes");
    % trim t
    % t = t(:, 1:t_count-1);
    disp("full length of sample file: " + size (t, 2))
    % trim t to be the length set by the user
    fclose (f);
    v = t(1,:) + t(2,:)*i;
    [r, c] = size (v);
    v = reshape (v, c, r);
    % v = v(1:iterations*count);
  end


  % Read and convert the binary data to a column vector of 32 bit complex numbers
  % while ftell(f) < large_file_size;
  %   chunk = fread(f, [2, count], 'float');
  %   disp("file pointer position after fread:");
  %   disp(ftell(f));
  %   disp("SIZE OF chunk " + numel(chunk));
  %   t(:, t_count : t_count+count-1) = chunk;
  %   t_count = t_count+count;
  %   % large_file_count = large_file_count+(2*gap_size);
  %   % disp("t_count " + t_count);
  %   % disp("large_file_count " + large_file_count);
  %   % 1 SAMPLE IS 8 BYTES 
  %   % Skip the gap between samples
  %   % status = fseek(f, large_file_count - (2*count), 0);
  %   status = fseek(f, 8*(gap_size - count), 0);
  %   disp("file pointer position after fseek:" + ftell(f));
  %   disp("status " + status);
