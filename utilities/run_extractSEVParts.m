% [f,p]=uigetfile
% [sev, header] = read_tdt_sev(fullfile(p,f));
% fdata=wavefilter(sev(1,8e6:12e6),5);
% ddt_write_v(fullfile('C:\Users\admin\Documents\MATLAB\MattGaidica\ch1_9e6-10e6.ddt')...
%     ,1,length(fdata),header.Fs,fdata/1000);
% 
% extractSpikesTDT_20141205('R0035_20141226b','tetrodelist',{'T09'})

dataDir = '\\172.20.138.142\RecordingsLeventhal2\ChoiceTask\R0035\R0035-rawdata\R0035_20141203a\R0035_20141203a';
sevFiles = dir(fullfile(dataDir,'*.sev'));
%saveDir = 'C:\Users\admin\Documents\MATLAB\MattGaidica';
data = [];
for i=1:length(sevFiles)
    disp(sevFiles(i).name);
    [sev, header] = read_tdt_sev(fullfile(dataDir,sevFiles(i).name));
    C = strsplit(sevFiles(i).name,'_');
    C = strsplit(C{end},'.'); %C{1} = chXX
    %fdata(str2num(C{1}(3:end)),:) = sev(1,2.5e6:5e6); %in brain, recording c
    data(str2num(C{1}(3:end)),:) = sev(1,1:1e5);
%     fileParts = strsplit(sevFiles(i).name,'.');
%     filename = strcat(fileParts(1),'.ddt');
%     ddt_write_v(fullfile(saveDir,filename),1,length(fdata),header.Fs,fdata/1000);
end