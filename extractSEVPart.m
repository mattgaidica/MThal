function [sev,header]=extractSEVPart(fileLoc,dataStart,dataLength)
    [sev,header] = read_tdt_sev(fileLoc);
    sev = sev(dataStart:dataStart+dataLength-1);
end