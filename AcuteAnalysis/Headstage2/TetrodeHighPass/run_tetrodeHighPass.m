saveDir = 'C:\Users\admin\Documents\MATLAB\MattGaidica\AcuteAnalysis\TetrodeHighPass';

for i=1:length(acuteTetrodes)
    channels = chMap.chMap(acuteTetrodes(i),2:end);
    dataLength = 1e5;
    dataStep = 7e5;
    for dataStart=1:dataStep:length(fdata)-dataLength
        dataEnd = dataStart+dataLength;
        h=figure('position',[0 0 800 800]);
        for j=1:4
            hs(j)=subplot(4,1,j);
            plot(wavefilter(fdata(channels(j),dataStart:dataEnd),5));
            title(['channel:',num2str(chMap.chMap(acuteTetrodes(i),j+1))]);
            xlim([0 dataLength]);
        end
        linkaxes(hs,'x');
        filename = strcat('tetrode',num2str(acuteTetrodes(i)),'_',...
            num2str(dataStart),'-',num2str(dataEnd));

        %save, close
        saveas(h,fullfile(saveDir,filename),'fig');
        saveas(h,fullfile(saveDir,filename),'png');
        close(h);
    end
end