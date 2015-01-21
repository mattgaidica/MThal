%tetrodeMap is a vector of channels in tetrode order, just load these from
%the .mat files I saved in AcuteAnalysis

% %plateVacancyMap is a boolean matrix: col1=ch,col2=0/1 electrode
% %present,col3=0/1 gold plated
% [f,p] = uigetfile;
% plateVacancyMap = csvread(fullfile(p,f));
% 
% dataDir='\\172.20.138.142\RecordingsLeventhal2\ChoiceTask\ephys_test\Acute_20140114\data - 2015-01-14 15_32_35';
% saveDir=fullfile(dataDir,'analysis');

function makeEEGPlot(dataDir,saveDir,tetrodeMap,plateVacancyMap,secondsPerPlot)
    sevFiles = dir(fullfile(dataDir,'*.sev'));
    %read one file for base info
    [data,header] = read_tdt_sev(fullfile(dataDir,sevFiles(1).name));
    samplesPerPlot = floor(header.Fs*secondsPerPlot);
    dataLength = length(data);
    data = [];
    %mark 100ms@100uV
    vMarks = makePlotVoltageMarkers(samplesPerPlot,round(header.Fs/5),100,length(sevFiles));
    t = linspace(0,(samplesPerPlot/header.Fs)*1000,samplesPerPlot);
    for dataStart=1:samplesPerPlot:dataLength-samplesPerPlot
        disp(['dataStart:',num2str(dataStart)]);
        for iFile=1:length(sevFiles)
            disp(sevFiles(iFile).name);
            fileLoc = fullfile(dataDir,sevFiles(iFile).name);
            curCh = getSEVChFromFilename(sevFiles(iFile).name);
            [data(curCh,:),~] = extractSEVPart(fileLoc,dataStart,samplesPerPlot);
        end
        %convert rows to tetrode map
        data = data(tetrodeMap,:);
        
        h = figure('position',[0 0 1400 900]);
        mi = min(data,[],2);
        ma = max(data,[],2);
        shift = cumsum([0; abs(ma(1:end-1))+abs(mi(2:end))]);
        shift = repmat(shift,1,samplesPerPlot);
        meanShift = mean(data+shift,2);
        meanShiftPlot = repmat(meanShift,1,samplesPerPlot);

        %appears to happen when recording is off, code below doesn't like
        %zeros
        if(mean(meanShift)==0)
            disp('Mean=0, skipping!');
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
        xlim([0 max(t)])
        xlabel('ms')
        ylabel('ch+uV')
        legend('50ms@200uV')

        filename = strcat('samples',num2str(dataStart),'-',num2str(dataStart+samplesPerPlot));
        tightfig;
        title(filename)
        %save, close
        hgsave(h,fullfile(saveDir,strcat(filename,'.fig')),'-v7.3');
        close(h);
    end
end