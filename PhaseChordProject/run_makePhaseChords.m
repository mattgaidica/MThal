dataStart = 1;
dataLength = 1e6;

phaseCorrMatrix = zeros(length(acuteTetrodes)*4);
allCh = [];
for iTet=1:length(acuteTetrodes)
    for iCh=1:4
        allCh = [allCh chMap.chMap(acuteTetrodes(iTet),iCh+1)];
    end
end

tetrodeNames = strsplit(num2str(allCh));

for iCh1=1:length(allCh)
    for iCh2=iCh1:length(allCh)
        disp([num2str(allCh(iCh1)),':',num2str(allCh(iCh2))]);
        data1 = fdata(allCh(iCh1),dataStart:dataStart+dataLength);
        data2 = fdata(allCh(iCh2),dataStart:dataStart+dataLength);
        
        filtData1 = filtfilt(SOS,G,double(data1));
        filtData2 = filtfilt(SOS,G,double(data2));
        
        hx1 = hilbert(filtData1);
        hx2 = hilbert(filtData2);
        
        phases1 = atan2(imag(hx1),real(hx1));
        phases2 = atan2(imag(hx2),real(hx2));
        
        % reflected matrix
        phaseCorrMatrix(iCh1,iCh2) = mean(2*pi-abs(phases2-phases1));
        phaseCorrMatrix(iCh2,iCh1) = phaseCorrMatrix(iCh1,iCh2);
    end
end

minEntry = min(phaseCorrMatrix(:));
phaseCorrMatrix = phaseCorrMatrix-minEntry;
phaseCorrMatrix(1:length(allCh)+1:length(allCh)*length(allCh))=0;
phaseCorrMatrix = phaseCorrMatrix.^4*100;

writePhaseChords(phaseCorrMatrix,tetrodeNames);


    