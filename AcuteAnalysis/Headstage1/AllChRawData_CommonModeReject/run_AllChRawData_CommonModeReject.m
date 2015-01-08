saveDir = 'C:\Users\admin\Documents\MATLAB\MattGaidica\AcuteAnalysis\Headstage1\AllChRawData_CommonModeReject';
chMat = chMap.chMap(acuteTetrodes,2:end)';
allCh = chMat(:)';
dataLength = 1e5;
dataStep = 5e5;

fdata_1_cma = commonModeAverage(fdata_1(allCh,:));

for dataStart=1:dataStep:length(fdata_1)-dataLength
    dataEnd = dataStart+dataLength;
    h=figure('position',[0 0 1400 900]);
    for i=1:length(allCh)
        hs(i) = subplot(8,4,i);
        plot(fdata_1(allCh(i),dataStart:dataEnd)-fdata_1_cma(1,dataStart:dataEnd));
        title(['channel:',num2str(allCh(i))]);
        xlim([0 dataLength]);
    end
    linkaxes(hs,'x');
    filename = strcat('allCh_',num2str(dataStart),'-',num2str(dataEnd));
    tightfig;
    %save, close
    saveas(h,fullfile(saveDir,filename),'fig');
    close(h);
end