function ch=getSEVChFromFilename(name)
    C = strsplit(name,'_');
    C = strsplit(C{end},'.'); %C{1} = chXX
    ch = str2num(C{1}(3:end));
end