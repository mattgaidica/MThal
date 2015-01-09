function [sev,header]=extractSEVPart(fileLoc,dataStart,chunkLength)
    [sev,header] = read_tdt_sev(fileLoc);
    sev = sev(dataStart:dataStart+chunkLength-1);
end