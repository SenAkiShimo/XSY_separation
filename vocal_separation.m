clear; clc; close all;

%Audio Loading
disp('Loading');
[male_vocal, fs1] = audioread('male.wav');
[female_vocal, fs2] = audioread('female.wav');

% Ensure consistent sampling rates
if fs1 ~= fs2
    error('Sampling rates do not match');
end
fs = fs1;

%Align lengths and take mono channel
min_len = min(length(male_vocal), length(female_vocal));
male_vocal = male_vocal(1:min_len, 1);
female_vocal = female_vocal(1:min_len, 1);

%Artificial Mixing
disp('Simulating "Cocktail Party" effect...');
mixed_signal = male_vocal + female_vocal;
audiowrite('output_mixed.wav', mixed_signal, fs);

%Short-Time Fourier Transform (STFT)
disp('Performing STFT for time-frequency analysis...');
win_len = 512;
hop_len = 256;
% hamming
win = 0.54 - 0.46 * cos(2 * pi * (0:win_len-1)' / (win_len - 1));

[S_male, F, T] = stft(male_vocal, fs, 'Window', win, 'OverlapLength', win_len - hop_len);
[S_female, ~, ~] = stft(female_vocal, fs, 'Window', win, 'OverlapLength', win_len - hop_len);
[S_mix, ~, ~] = stft(mixed_signal, fs, 'Window', win, 'OverlapLength', win_len - hop_len);

%IRM
disp('Calculating Ideal Ratio Mask (IRM) for Female Vocal...');
mag_male = abs(S_male);
mag_female = abs(S_female);

% Calculate the ratio mask to isolate female vocal
% eps prevents division by zero
IRM_female = mag_female ./ (mag_male + mag_female + eps); 

%%Signal Reconstruction
disp('Reconstructing target audio...');
S_separated = S_mix .* IRM_female;
separated_audio = istft(S_separated, fs, 'Window', win, 'OverlapLength', win_len - hop_len);

% Normalize audio
separated_audio = separated_audio / max(abs(separated_audio));
audiowrite('output_isolated_female.wav', separated_audio, fs);

%Plotting
disp('Generating mask visualization...');
figure('Name', 'Ideal Ratio Mask (IRM)');
imagesc(T, F, IRM_female);
axis xy;
ylim();
colormap('jet');
colorbar;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('T-F Mask for Isolated Female Vocal');

disp('Done!');
