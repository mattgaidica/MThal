% require format: RZZZZ_YYYYMMDDX-N_data_ch??.sev
dataDir = '\\172.20.138.142\RecordingsLeventhal2\ChoiceTask\R0040\R0040-rawdata\R0040_20150119h';
baseName = 'R0040_20150119h_data_';
dirFiles = dir(fullfile(dataDir,'*.sev'));

for i=1:length(dirFiles)
    C = strsplit(dirFiles(i).name,'_');
    C = strsplit(C{end},'.'); %C{1} = chXX
    disp(fullfile(dataDir,[baseName C{1} '.sev']))
    
    movefile(fullfile(dataDir,dirFiles(i).name),...
        fullfile(dataDir,[baseName C{1} '.sev']));
end