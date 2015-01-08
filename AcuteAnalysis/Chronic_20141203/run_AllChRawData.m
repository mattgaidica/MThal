saveDir = 'C:\Users\admin\Documents\MATLAB\MattGaidica\AcuteAnalysis\Chronic_20141203';
chMat = chMap.chMap(:,2:end)';
allCh = chMat(:)';
dataLength = 1e5;
dataStep = 5e5;
t = linspace(0,(dataLength/header.Fs)*1000,dataLength);
%[f,p]=uigetfile;
%h1_csv=csvread(fullfile(p,f));
%mark 100uV @ 100ms intervals
vMarks = makePlotVoltageMarkers(dataLength,round(header.Fs/10),100,size(data,1));

for dataStart=6e5:dataStep:length(data)-dataLength
    dataEnd = (dataStart+dataLength)-1;
    sig = data(allCh,dataStart:dataEnd);
    h = figure('position',[0 0 1400 900]);
    
    mi = min(sig,[],2);
    ma = max(sig,[],2);
    shift = cumsum([0; abs(ma(1:end-1))+abs(mi(2:end))]);
    shift = repmat(shift,1,dataLength);
    meanShift = mean(sig+shift,2);
    meanShiftPlot = repmat(meanShift,1,dataLength);
    
    if(mean(meanShift)==0)
        continue;
    end
    
    colorOrder = makeColorOrder(h1_csv,allCh);
    set(gca, 'ColorOrder',colorOrder,'NextPlot','replacechildren');
    plot(t,vMarks+meanShiftPlot,'-','color','k','lineWidth',3);
    hold on;
    plot(t,sig+shift)
    
    % edit axes
    set(gca,'ytick',meanShift,'yticklabel',allCh)
    %set(gca,'xticklabel',num2str(get(gca,'xtick')','%6.3f'))
    grid on
    ylim([mi(1) max(max(shift+sig))])
    xlim([0 (dataLength/header.Fs)*1000])
    xlabel('ms')
    ylabel('ch+uV')
    legend('100ms@100uV')

    filename = strcat('samples',num2str(dataStart),'-',num2str(dataEnd));
    tightfig;
    title(filename)
    %save, close
    saveas(h,fullfile(saveDir,filename),'fig');
    close(h);
end