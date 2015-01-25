% partial extraction (connection to nas broke in the middle so we ll do some tetrodes on some sessions again...)

% the idea is: run this script from the -rawdata folder. the script then
% goes through all session subdirectories and calls the extractSpikes.m. we
% try to use a parfor loop here so that all sessions can be dealt with in
% parallel.

% adjust parameters for extractSpikes.m below as necessary
% if everything works, .plx files should be created in the correspond
% -processed folders.

%matlabpool

rawDataRoot = pwd;

dirs=dir('IM*'); % session subdirectories with HSD files

parfor mydir = 1:length(dirs)
    if isdir(dirs(mydir).name)
        cd(dirs(mydir).name)
        myfile = dir('*.hsd');
        if ~isempty(dir('*.hsd'))
            logFile = dir('*.log');
            if ~isempty(logFile)
                behavData = getbehavDataFromLog( logFile(1).name );
                if max(behavData.SSD) ~= 2 % if its not a nogo session...
                    myfile = myfile.name;            
                    extractSpikes(myfile)
                end
            end
        else
           disp('No HSD file found...') 
        end
    end
    cd(rawDataRoot)
end

