clear; clc; close all;

%Audio Loading
disp('Loading...');

[vocal_power, fs1] = audioread('power.wav');
[vocal_dark, fs2] = audioread('dark.wav');

if fs1 ~= fs2
    error('Sampling rates do not match!');
end
fs = fs1;

min_len = min(length(vocal_power), length(vocal_dark));
vocal_power = vocal_power(1:min_len, 1);
vocal_dark = vocal_dark(1:min_len, 1);

%Artificial Mixing
disp('Simulating the mixed track...');
mixed_signal = vocal_power + vocal_dark;
audiowrite('homo_output_mixed.wav', mixed_signal, fs);

%Manual STFT
disp('Performing Manual STFT for time-frequency analysis...');
win_len = 512;
hop_len = 256;

win = 0.54 - 0.46 * cos(2 * pi * (0:win_len-1)' / (win_len - 1));

num_frames = floor((min_len - win_len) / hop_len) + 1;

S_power = zeros(win_len, num_frames);
S_dark = zeros(win_len, num_frames);
S_mix = zeros(win_len, num_frames);

for i = 1:num_frames
    idx = (i-1)*hop_len + (1:win_len);
    S_power(:, i) = fft(vocal_power(idx) .* win);
    S_dark(:, i) = fft(vocal_dark(idx) .* win);
    S_mix(:, i) = fft(mixed_signal(idx) .* win);
end

S_power = S_power(1:win_len/2+1, :);
S_dark = S_dark(1:win_len/2+1, :);
S_mix = S_mix(1:win_len/2+1, :);

%IRM
disp('Calculating Ideal Ratio Mask (IRM) for Power Vocal...');
mag_power = abs(S_power);
mag_dark = abs(S_dark);

IRM_target = mag_power ./ (mag_power + mag_dark + eps); 


disp('Reconstructing target audio via Overlap-Add...');
S_separated = S_mix .* IRM_target;

S_full = [S_separated; conj(S_separated(end-1:-1:2, :))];
separated_audio = zeros(min_len, 1);

for i = 1:num_frames
    idx = (i-1)*hop_len + (1:win_len);
    frame_time = real(ifft(S_full(:, i)));
    separated_audio(idx) = separated_audio(idx) + frame_time .* win;
end

separated_audio = separated_audio / max(abs(separated_audio));
audiowrite('homo_output_isolated_power.wav', separated_audio, fs);

%Plotting Results
disp('➡️ Generating mask visualization...');
figure('Name', 'Ideal Ratio Mask (IRM)');
imagesc(0:(num_frames-1)*hop_len/fs, 0:fs/win_len:fs/2, IRM_target);
axis xy;
ylim();
colormap('jet');
colorbar;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('T-F Mask for Isolated Power Vocal');

disp('Done!');
