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

mixed_signal = vocal_power + vocal_dark;

%Manual STFT
disp('Performing STFT to get Magnitude Spectrograms...');
win_len = 512; hop_len = 256;
win = 0.54 - 0.46 * cos(2 * pi * (0:win_len-1)' / (win_len - 1));
num_frames = floor((min_len - win_len) / hop_len) + 1;

S_power = zeros(win_len, num_frames);
S_mix = zeros(win_len, num_frames);

for i = 1:num_frames
    idx = (i-1)*hop_len + (1:win_len);
    S_power(:, i) = fft(vocal_power(idx) .* win);
    S_mix(:, i) = fft(mixed_signal(idx) .* win);
end


V_power = abs(S_power(1:win_len/2+1, :));
V_mix = abs(S_mix(1:win_len/2+1, :));

%Learn Dictionary
disp('Learning Power spectral dictionary via NMF...');
num_bases = 30; 
num_iter = 100;
[F_bins, T_frames] = size(V_power);

W_power = rand(F_bins, num_bases);
H_power = rand(num_bases, T_frames);

for iter = 1:num_iter
    H_power = H_power .* ((W_power' * V_power) ./ (W_power' * W_power * H_power + eps));
    W_power = W_power .* ((V_power * H_power') ./ (W_power * H_power * H_power' + eps));
    W_power = W_power ./ (sum(W_power, 1) + eps);
end

%Extract Power from the Mix
disp('Extracting Power...');
H_mix_power = rand(num_bases, T_frames);

for iter = 1:num_iter
    H_mix_power = H_mix_power .* ((W_power' * V_mix) ./ (W_power' * W_power * H_mix_power + eps));
end

V_reconstructed_power = W_power * H_mix_power;

Mask_NMF = V_reconstructed_power ./ (V_mix + eps);

%Manual iSTFT 
disp('Reconstructing target audio via Overlap-Add...');
S_separated = S_mix(1:win_len/2+1, :) .* Mask_NMF;
S_full = [S_separated; conj(S_separated(end-1:-1:2, :))];
separated_audio = zeros(min_len, 1);

for i = 1:num_frames
    idx = (i-1)*hop_len + (1:win_len);
    frame_time = real(ifft(S_full(:, i)));
    separated_audio(idx) = separated_audio(idx) + frame_time .* win;
end

separated_audio = separated_audio / max(abs(separated_audio));
audiowrite('output_nmf_power.wav', separated_audio, fs);

disp('Done!');
