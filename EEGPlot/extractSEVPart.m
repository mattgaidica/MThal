function [sev,header]=extractSEVPart(fileLoc,dataStart,samples)
    [sev,header] = read_tdt_sev(fileLoc);
    sev = sev(dataStart:dataStart+samples-1);
end