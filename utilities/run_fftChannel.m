channel = 4;
dataStart = 1;
dataLength = 1e6;

rawData = fdata_1(channel,dataStart:dataStart+dataLength);
%hpData = wavefilter(rawData,5);

Fs = header.Fs; % Sampling frequency
T = 1/Fs; % Sample time
L = length(rawData); % Length of signal
t = (0:L-1)*T; % Time vector
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
f = Fs/2*linspace(0,1,NFFT/2+1);

Y = fft(double(rawData),NFFT)/L;
A = 2*abs(Y(1:NFFT/2+1));
figure;
plot(f,A);
xlim([10 2000]);

% locs = [];
% locs(channel,:) = absPeakDetection(data);