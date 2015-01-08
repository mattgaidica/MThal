saveDir = 'C:\Users\admin\Documents\MATLAB\MattGaidica\AcuteAnalysis\AllChHighPass';
chMat = chMap.chMap(acuteTetrodes,2:end)';
allCh = chMat(:)';
dataLength = 1e5;
dataStep = 7e5;

for dataStart=1:dataStep:length(fdata)-dataLength
    dataEnd = dataStart+dataLength;
    h=figure('position',[0 0 1400 900]);
    for i=1:length(allCh)
        hs(i) = subplot(8,4,i);
        plot(wavefilter(fdata(allCh(i),dataStart:dataEnd),5));
        title(['channel:',num2str(allCh(i))]);
        xlim([0 dataLength]);
    end
    linkaxes(hs,'x');
    filename = strcat('allCh_',num2str(dataStart),'-',num2str(dataEnd));
    tightfig;
    %save, close
    saveas(h,fullfile(saveDir,filename),'fig');
    saveas(h,fullfile(saveDir,filename),'png');
    close(h);
end