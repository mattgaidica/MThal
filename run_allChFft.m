dataStart = 1;
dataLength = 1e5;

Fs = header.Fs; % Sampling frequency
T = 1/Fs; % Sample time
L = length(fdata_1); % Length of signal
t = (0:L-1)*T; % Time vector
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
f = Fs/2*linspace(0,1,NFFT/2+1);

allA = [];
for i=1:length(allCh)
    disp(num2str(allCh(i)));
    Y = fft(double(fdata_1(allCh(i),dataStart:dataStart+dataLength)),NFFT)/L;
    A = 2*abs(Y(1:NFFT/2+1));
    if(i==1)
        allA = A;
    else
        allA = mean([allA;A]);
    end
end

figure;
plot(f,allA);
xlim([10 2000]);