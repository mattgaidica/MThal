%tetrodeMap is a vector of channels in tetrode order
% chMat = chMap.chMap(:,2:end)';
% allCh = chMat(:)';

%plateVacancyMap is a boolean matrix: col1=ch,col2=0/1 electrode
%present,col3=0/1 gold plated
% [f,p] = uigetfile;
% plateVacancyMap = csvread(fullfile(p,f));

function makeEEGPlot(dataDir,saveDir,tetrodeMap,plateVacancyMap,dataStep,chunkLength)
    sevFiles = dir(fullfile(dataDir,'*.sev'));
    %read one file for base info
    [data,header] = read_tdt_sev(fullfile(dataDir,sevFiles(1).name));
    dataLength = length(data);
    data = [];
    %mark 100ms@100uV
    vMarks = makePlotVoltageMarkers(chunkLength,round(header.Fs/10),100,length(sevFiles));
    t = linspace(0,(chunkLength/header.Fs)*1000,chunkLength);
    for dataStart=1:dataStep:dataLength-chunkLength
        disp(['dataStart:',num2str(dataStart)]);
        for iFile=1:length(sevFiles)
            disp(sevFiles(iFile).name);
            fileLoc = fullfile(dataDir,sevFiles(iFile).name);
            curCh = getSEVChFromFilename(sevFiles(iFile).name);
            [data(curCh,:),~] = extractSEVPart(fileLoc,dataStart,chunkLength);
        end
        %convert rows to tetrode map
        data = data(tetrodeMap,:);
        
        h = figure('position',[0 0 1400 900]);
        mi = min(data,[],2);
        ma = max(data,[],2);
        shift = cumsum([0; abs(ma(1:end-1))+abs(mi(2:end))]);
        shift = repmat(shift,1,chunkLength);
        meanShift = mean(data+shift,2);
        meanShiftPlot = repmat(meanShift,1,chunkLength);

        %appears to happen when recording is off, code below doesn't like
        %zeros
        if(mean(meanShift)==0)
            continue;
        end
        
        %apply different colors
        %blue=good,red=no gold plate,gray=electrode absent
        colorOrder = makeColorOrder(plateVacancyMap,tetrodeMap);
        set(gca,'ColorOrder',colorOrder,'NextPlot','replacechildren');
        %plot
        plot(t,vMarks+meanShiftPlot,'-','color','k','lineWidth',3);
        hold on;
        plot(t,data+shift)

        % edit axes
        set(gca,'ytick',meanShift,'yticklabel',tetrodeMap)
        %set(gca,'xticklabel',num2str(get(gca,'xtick')','%6.3f'))
        grid on
        ylim([mi(1) max(max(shift+data))])
        xlim([0 (dataLength/header.Fs)*1000])
        xlabel('ms')
        ylabel('ch+uV')
        legend('100ms@100uV')

        filename = strcat('samples',num2str(dataStart),'-',num2str(dataStart+chunkLength));
        tightfig;
        title(filename)
        %save, close
        saveas(h,fullfile(saveDir,filename),'fig');
        close(h);
    end
end