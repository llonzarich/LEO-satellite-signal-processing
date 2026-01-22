% usage: read_complex_binary(filename, [start], [count])
%
% reads USRP IQ samples saved as 32-bit unsigned floats.
% output is the contents of filename -- as a complex valued column vector.



function v = read_complex_binary (filename, start, count)


m = nargchk (1,3,nargin);
if (m)
    usage (m);
end


if (nargin < 2)
    start = 0;
    count = Inf;
end


f = fopen (filename, 'rb');


if (f < 0)
    v = 0;
else
    fseek(f, start, -1);
    t = fread (f, [2, count], 'float32');
    fclose (f);
    v = t(1,:) + t(2,:) * 1i;
    [r, c] = size (v);
    v = reshape (v, c, r);
end


% [filepath, name, ext] = fileparts(filename);
% save(['iq_samples_' name '.mat'], 'v', '-v7.3');