figure;
dataRange = 27100000:27199999;
h(1) = subplot(2,1,1);
plot(t,data(9,dataRange));
xlabel('ms')
ylabel('uv')
title('RAW ch9,21600000:21699999');

h(2) = subplot(2,1,2);
plot(t,wavefilter(data(9,dataRange),5));
xlabel('ms')
ylabel('uv')
title('HIGHPASS ch9,21600000:21699999');

linkaxes(h)
xlim([0 max(t)])
tightfig