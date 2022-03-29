clc
clear
close all
load("data/ArrayData.mat")
load("data/CleanTrials.mat")
fs = 200;

num_channels = numel(chan);
% removing bad trials
for ch_no = 1:num_channels
    chan(ch_no).lfp = chan(ch_no).lfp(:, Intersect_Clean_Trials);
end
num_trials = size(chan(1).lfp, 2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% LFP analysis
%% part a - finding the most dominant frequency oscillation using 
Ps = 0;
for ch_no = 1:num_channels
    lfp_data = chan(ch_no).lfp;
    lfp_data = zscore(lfp_data);
    for trial_no = 1:num_trials
        trial_data = lfp_data(:, trial_no);
        m = length(trial_data);
        n = pow2(nextpow2(m));
        Y = fft(trial_data, n);
        Y = fftshift(Y);
        Ps = Ps+abs(Y);
    end
end
normalize_constant = 10*log10((num_channels*num_trials)^2);

f = (-n/2:n/2-1)*(fs/n);
Ps_plot = 10*log10(Ps.^2/n);
pink_noise = 1./f(n/2+2:end);
[~,~,spectrum_regressed] = regress(Ps_plot(n/2+2:end), pink_noise');
pink_spectrum = Ps_plot(n/2+2:end) - spectrum_regressed;

figure
loglog(f(n/2+2:end), pink_spectrum, '--r', 'LineWidth', 2)
hold on
loglog(f(n/2+2:end), Ps_plot(n/2+2:end), 'k', 'LineWidth', 2)
title('Averaged power spectrum of all trials of all channels (not normalized)')
xlabel('Frequency (Hz)')
ylabel('Power (dB)')
xlim([1, 100])
legend('Estimated Pink Noise')
grid on

figure
plot(f(n/2+2:end), pink_spectrum-normalize_constant, '--r', 'LineWidth', 2)
hold on
plot(f(n/2+2:end), Ps_plot(n/2+2:end)-normalize_constant, 'k', 'LineWidth', 2)
title('Averaged power spectrum of all trials of all channels')
xlabel('Frequency (Hz)')
ylabel('Power (dB)')
xlim([1, 100])
legend('Estimated Pink Noise')
grid on

% removing pink noise
figure
hold on
spectrum_clean = Ps_plot(n/2+2:end) - pink_spectrum;
plot(f(n/2+2:end), Ps_plot(n/2+2:end)-normalize_constant, 'r', 'LineWidth', 2) 

plot(f(n/2+2:end), spectrum_clean-normalize_constant, 'k', 'LineWidth', 2) 

legend('Original', 'Denoised (No Pink Noise)')
title('Averaged power spectrum of all trials of all channels')
xlabel('Frequency (Hz)')
ylabel('Power (dB)')
xlim([1, 70])
grid on
%% part b - clustering electrodes based on their dominant oscillation frequency
clc
close all

figure
hold on
dominant_freq_mat = ChannelPosition*nan;
normalize_constant = 10*log10((num_trials)^2);
for ch_no = 1:num_channels
    lfp_data = chan(ch_no).lfp;
    Ps = 0;
    for trial_no = 1:num_trials
        trial_data = lfp_data(:, trial_no);
        trial_data = zscore(trial_data);
        m = length(trial_data);
        n = pow2(nextpow2(m));
        Y = fft(trial_data, n);
        Y = fftshift(Y);
        Ps = Ps+abs(Y);
    end
    f = (-n/2:n/2-1)*(fs/n);
    Ps = 10*log10(Ps.^2/n);
    Ps_plot = removePinkNoise(Ps, f, n);
    plot(f(n/2+2:end), Ps_plot(n/2+2:end)-normalize_constant)
    [row, ~] = find(Ps_plot(n/2+2:end) == max(Ps_plot(n/2+2:end)));
    f_tmp = f(n/2+2:end);
    dominant_freq = f_tmp(row);
    [row, col] = find(ChannelPosition==ch_no);
    dominant_freq_mat(row, col) = dominant_freq;
end

title('Averaged power spectrum over all trials of each channel')
xlabel('Frequency (Hz)')
ylabel('Power (dB)')
xlim([0, 70])
ylim([-40, 10])
grid on

figure
plt = imagesc(dominant_freq_mat);
set(plt,'AlphaData', ~isnan(dominant_freq_mat))
colormap jet
colorbar
caxis([0, 13])
title('Dominant Frequencies')
%% part c - time-frequncy analysis of the LFP data
clc
close all
% STFT
stft_map = 0;
for ch_no = 1:num_channels
    lfp_data = chan(ch_no).lfp;
    lfp_data = zscore(lfp_data);
    for trial_no = 1:num_trials
        trial_data = lfp_data(:, trial_no);
        [s,f,time_stft] = stft(trial_data,fs,'Window',kaiser(60,5),'OverlapLength',40,'FFTLength',fs);
        stft_map = stft_map + abs(s); 
    end
end
%%
stft_map_tmp = [];

for t = 1:size(stft_map, 2)
    Ps = stft_map(:, t);
    n = length(Ps);
    Ps_plot = removePinkNoise(Ps, f', n);
    stft_map_tmp(:, t) = Ps_plot;
%     figure
%     plot(f(n/2+2:end), Ps(n/2+2:end), 'r')
%     hold on
%     plot(f(n/2+2:end), Ps_plot(n/2+2:end), '--b')
end

figure
imagesc(time_stft-1.2,f,flipud(stft_map));
ylim([0, 40])
colorbar
set(gca,'YDir','normal')

figure
imagesc(time_stft-1.2,f,flipud(stft_map_tmp));
ylim([0, 40])
colorbar
set(gca,'YDir','normal')
%% Functions

function Ps_plot = removePinkNoise(Ps, f, n)
    pink_noise = 1./f(n/2+2:end);
    [~,~,spectrum_regressed] = regress(Ps(n/2+2:end), pink_noise');
    pink_spectrum = Ps(n/2+2:end)-spectrum_regressed;
    Ps_plot = Ps;
    Ps_plot(n/2+2:end) = Ps(n/2+2:end)-pink_spectrum;
end