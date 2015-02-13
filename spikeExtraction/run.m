% update ephys interface and NAS location: spike.subject
% create the recording session: spike.session
% use session ID to fill in all tetrodes: spike.tetrodeSession

% sqlCredentials = getSqlCredentials;
extractSpikesTDT('R0040_20150119h');

figure('position',[0 0 1000 9000]);
s(1)=subplot(2,1,1);
plot(fdata(1,:));
s(2)=subplot(2,1,2);
plot(SNLEdata(1,:));
hold on;
plot(ts,SNLEdata(1,ts),'*','color','red');
linkaxes(s,'x');