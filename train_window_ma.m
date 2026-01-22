addpath(genpath("/home/wairimu/leo-signal-proc/file_rw_utils"));
addpath(genpath("/home/wairimu/leo-signal-proc/matlab_utils"));
addpath(genpath("/home/wairimu/leo-signal-proc/plots"));
addpath(genpath("/home/wairimu/leo-signal-proc/"));
% matlab -nodisplay -nosplash -nodesktop -r "run('/home/wairimu/leo-signal-proc/cnn_lstm_lr_model/train_window_ma.m');exit;"

%%


load("/home/wairimu/window_tensor_concat.mat", 'window_tensor_concat');
disp(size(window_tensor_concat));
disp(window_tensor_concat);
disp(window_tensor_concat(1));