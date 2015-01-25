% the idea is: run this script from the -rawdata folder. the script then
% goes through all session subdirectories and calls the extractSpikes.m. we
% try to use a parfor loop here so that all sessions can be dealt with in
% parallel.

% adjust parameters for extractSpikes.m below as necessary
% if everything works, .plx files should be created in the correspond
% -processed folders.

matlabpool

rawDataRoot = pwd;

dirs=dir('IM*'); % session subdirectories with HSD files
parfor mydir = 1:length(dirs)
    if isdir(dirs(mydir).name)
        cd(dirs(mydir).name)
        myfile = dir('*.hsd');
        if ~isempty(dir('*.hsd'))
            myfile = myfile.name;
            extractSpikes(myfile)
        else
           disp('No HSD file found...') 
        end
    end
    cd(rawDataRoot)
end

