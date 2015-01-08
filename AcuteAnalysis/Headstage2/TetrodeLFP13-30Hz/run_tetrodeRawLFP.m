saveDir = 'C:\Users\admin\Documents\MATLAB\MattGaidica\AcuteAnalysis\TetrodeLFP13-30Hz';

for i=1:length(acuteTetrodes)
    channels = chMap.chMap(acuteTetrodes(i),2:end);
    dataLength = 5e4;
    dataStep = 7e5;
    for dataStart=1:dataStep:length(fdata)-dataLength
        dataEnd = dataStart+dataLength;
        h=figure('position',[0 0 800 800]);
        for j=1:4
            subplot(4,1,j);
            plot(filtfilt(SOS,G,double(fdata(channels(j),dataStart:dataEnd))));
            title(['channel:',num2str(chMap.chMap(acuteTetrodes(i),j+1))]);
            xlim([0 dataLength]);
        end
        
        filename = strcat('tetrode',num2str(acuteTetrodes(i)),'_',...
            num2str(dataStart),'-',num2str(dataEnd));
        %save, close
        saveas(h,fullfile(saveDir,filename),'png');
        close(h);
    end
end