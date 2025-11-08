%% ======================================================
%   OFDM System Simulation — FFT Visualization Emphasis
%   Author: Shreyas S. Shringare
%% ======================================================
clear; close all; clc;

fprintf('=== OFDM System Simulation Started ===\n');

%% ---------------- 1. SYSTEM PARAMETERS ----------------
ofdm_params.N           = 64;        % FFT Size
ofdm_params.N_data      = 48;        % Data subcarriers
ofdm_params.N_pilot     = 4;         % Pilot subcarriers
ofdm_params.N_cp        = 16;        % Cyclic prefix length
ofdm_params.num_symbols = 10;        % Number of OFDM symbols
ofdm_params.M           = 16;        % 16-QAM
ofdm_params.pilot_pattern = [12, 26, 40, 54]; % Pilot indices

fprintf('FFT Size: %d, Data Subcarriers: %d, CP Length: %d\n', ...
    ofdm_params.N, ofdm_params.N_data, ofdm_params.N_cp);

%% ---------------- 2. TRANSMITTER ----------------
fprintf('\n=== TRANSMITTER PROCESSING ===\n');

num_bits = ofdm_params.N_data * log2(ofdm_params.M) * ofdm_params.num_symbols;
tx_bits = randi([0 1], num_bits, 1);
tx_symbols = qammod(tx_bits, ofdm_params.M, 'InputType', 'bit', 'UnitAveragePower', true);
tx_symbols_matrix = reshape(tx_symbols, ofdm_params.N_data, ofdm_params.num_symbols);

pilot_values = ones(ofdm_params.N_pilot, ofdm_params.num_symbols);

tx_freq = zeros(ofdm_params.N, ofdm_params.num_symbols);
data_idx = setdiff(1:ofdm_params.N, [1, ofdm_params.N/2+1, ofdm_params.pilot_pattern]);
data_idx = data_idx(1:ofdm_params.N_data);

for k = 1:ofdm_params.num_symbols
    tx_freq(data_idx, k) = tx_symbols_matrix(:, k);
    tx_freq(ofdm_params.pilot_pattern, k) = pilot_values(:, k);
end

fprintf('Performing IFFT (Time-domain OFDM Symbol Generation)...\n');
tx_time = ifft(tx_freq, ofdm_params.N);

% Add cyclic prefix
tx_time_cp = [tx_time(end-ofdm_params.N_cp+1:end, :); tx_time];
tx_signal = tx_time_cp(:);

tx_power_dB = 10*log10(mean(abs(tx_signal).^2));
PAPR_dB = 10*log10(max(abs(tx_signal).^2)/mean(abs(tx_signal).^2));
fprintf('Tx Power: %.2f dB, PAPR: %.2f dB\n', tx_power_dB, PAPR_dB);

%% ---------------- 3. CHANNEL ----------------
fprintf('\n=== CHANNEL SIMULATION ===\n');
SNR_dB = 15;
rx_signal_noisy = awgn(tx_signal, SNR_dB, 'measured');

%% ---------------- 4. RECEIVER ----------------
fprintf('\n=== RECEIVER PROCESSING (SNR = %d dB) ===\n', SNR_dB);

rx_signal_cp = reshape(rx_signal_noisy, ofdm_params.N + ofdm_params.N_cp, ofdm_params.num_symbols);
rx_time = rx_signal_cp(ofdm_params.N_cp+1:end, :);
fprintf('Performing FFT (Recover Frequency-domain Subcarriers)...\n');
rx_freq = fft(rx_time, ofdm_params.N);

% Extract data & pilots
[rx_data, rx_pilots] = extract_data_pilots(rx_freq, ofdm_params);
rx_corrected = phase_tracking(rx_data, rx_pilots, ofdm_params);
rx_corrected = rx_corrected(:);

rx_bits = qamdemod(rx_corrected, ofdm_params.M, 'OutputType', 'bit', 'UnitAveragePower', true);
[num_err, ber] = biterr(tx_bits, rx_bits);
fprintf('Bit Error Rate: %.4f (%d errors)\n', ber, num_err);

%% ---------------- 5. VISUALIZATION ----------------
fprintf('\n=== GENERATING PLOTS ===\n');

figure('Name','OFDM Visualization','NumberTitle','off','Position',[200 100 1200 700]);

subplot(2,2,1);
plot(real(tx_signal(1:512)));
title('Transmitted Time-Domain Signal');
xlabel('Sample Index'); ylabel('Amplitude'); grid on;

subplot(2,2,2);
plot(abs(fftshift(abs(tx_freq(:,1)))),'LineWidth',1.2);
title('FFT Magnitude Spectrum of Transmitted Symbol');
xlabel('Subcarrier Index'); ylabel('|X(f)|'); grid on;

subplot(2,2,3);
plot(abs(fftshift(abs(rx_freq(:,1)))),'LineWidth',1.2);
title('FFT Magnitude Spectrum of Received Symbol');
xlabel('Subcarrier Index'); ylabel('|Y(f)|'); grid on;

subplot(2,2,4);
if ~isempty(rx_corrected)
    plot(real(rx_corrected), imag(rx_corrected), 'b.', 'MarkerSize', 8);
    title('Constellation After FFT + Equalization');
    xlabel('In-phase'); ylabel('Quadrature');
    axis equal; grid on;
else
    text(0.1, 0.5, ' No received symbols detected', 'FontSize', 12);
end

fprintf('\n=== Simulation Completed Successfully ===\n');

%% ======================================================
%                SUPPORTING FUNCTIONS
%% ======================================================

function [rx_data, rx_pilots] = extract_data_pilots(rx_freq_equalized, params)
    pilot_idx = params.pilot_pattern;
    null_idx = [1, params.N/2 + 1];
    data_idx = setdiff(1:params.N, [pilot_idx, null_idx]);
    data_idx = data_idx(1:params.N_data);
    rx_data = rx_freq_equalized(data_idx, :);
    rx_pilots = rx_freq_equalized(pilot_idx, :);
    rx_data = rx_data(:);
end

function rx_corrected = phase_tracking(rx_data, rx_pilots, params)
    phase_est = mean(angle(rx_pilots), 'all');
    rx_corrected = rx_data .* exp(-1j * phase_est);
end
