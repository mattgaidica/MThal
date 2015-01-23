function vMarks=makePlotVoltageMarkers(dataLength,markStep,markVoltage,repRows)
    vMarks = [];
    for i=1:dataLength
        vMarks(1,i) = NaN;
        if(mod(i,markStep)==0)
            vMarks(1,i) = markVoltage;
            vMarks(1,i-1) = -markVoltage;
        end
    end
    vMarks = repmat(vMarks,repRows,1);
end