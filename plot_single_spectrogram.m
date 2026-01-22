clc;
close all;
clear all;

% TODO: change this to the folder where read_complex_binary is located
addpath(genpath("/home/llonzarich/Desktop/leo-signal-proc/file_rw_utils"));
%%
% TODO: change this to the folder where the .raw file is
path = '/media/llonzarich/9CF29030F290111E/fc1075mhz_5sec_akirah/best_signal/gqrx_20250607_004127_1075133000_2400000_fc.raw';
F_s = 2.4e6;

paperSize=[50,50,1260,820];
printSize=[0 0 16 9];
fig.Position = paperSize; 
fig.PaperPosition = printSize;
% disp(dirlist)

y = read_complex_binary(path); 
num_samples = length(y);
total_seconds =  num_samples/ F_s;
xaxis = 0:1/F_s:total_seconds;
xaxis = xaxis(1:end-1);

% compute stft
% divide signal into 1000-sample segments 
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

fig = figure()
sdb = mag2db(abs(s));
mesh(t,f/1000,sdb);
% mesh(f/1e6,t,sdb');

cc = max(sdb(:))+[-12 -8];
% cc = max(sdb(:))+[-60 60];
ax = gca;
ax.CLim = cc;
view(2)
a = colorbar

a.Label.String ="signal strength (dB)";
xlabel('time (s)')
ylabel('frequency (KHz)')


return;