% require format: RZZZZ_YYYYMMDDX-N_data_ch??.sev
dataDir = '\\172.20.138.142\RecordingsLeventhal2\ChoiceTask\R0035\R0035-rawdata\R0035_20141226c\R0035_20141226c';
dirFiles = dir(fullfile(dataDir,'*.sev'));
baseName = 'R0035_20141226c_data_';
for i=1:length(dirFiles)
    C = strsplit(dirFiles(i).name,'_');
    C = strsplit(C{end},'.'); %C{1} = ch??
    disp(fullfile(dataDir,[baseName C{1} '.sev']))
    
    movefile(fullfile(dataDir,dirFiles(i).name),...
        fullfile(dataDir,[baseName C{1} '.sev']));
end