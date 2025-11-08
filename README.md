# OFDM System Simulation (MATLAB)

This project implements a complete Orthogonal Frequency Division Multiplexing (OFDM) transmit–receive chain using FFT/IFFT-based signal processing. It demonstrates how digital data can be encoded, transmitted over noisy channels, and recovered with high accuracy.

## Key Features
- 16-QAM modulation and demodulation  
- 64-point FFT/IFFT based OFDM waveform generation  
- Cyclic prefix insertion for multipath resistance  
- Pilot subcarriers for phase error correction  
- AWGN channel model (SNR = 15 dB)  
- BER, PAPR, spectrum, and constellation analysis  

## System Parameters
| Parameter | Value |
|---------|-------|
| FFT Size | 64 |
| Data Subcarriers | 48 |
| Pilot Subcarriers | 4 |
| Cyclic Prefix Length | 16 |
| Modulation Scheme | 16-QAM |
| Channel | AWGN (15 dB SNR) |
| OFDM Symbols | 10 |

## Workflow
1. Generate random bits  
2. Map bits to 16-QAM symbols  
3. Insert data + pilot subcarriers  
4. Perform IFFT → time-domain OFDM signal  
5. Add cyclic prefix and transmit through AWGN  
6. Remove CP and perform FFT at receiver  
7. Use pilot tones for phase correction  
8. Demodulate and recover transmitted bits  
9. Evaluate BER and visualize results  

## Output Highlights
| Metric | Result |
|-------|--------|
| Bit Error Rate (BER) | ~0.0026 |
| Errors per transmission | 5–30 bits (varies with noise) |
| PAPR | ~8.2 dB |
| Constellation | Clear 16-QAM clusters with minor noise spread |

## Visualizations Produced
- Time-domain transmitted waveform  
- Transmitted spectrum (subcarrier structure)  
- Received spectrum (noise effects visible)  
- Recovered 16-QAM constellation plot  

## How to Run
1. Open MATLAB  
2. Place all `.m` files in the same folder  
3. Run:
```matlab
ofdm_simulation
