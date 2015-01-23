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
%repairflag=logical([0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 1 0 0 1 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0]);

q = zeros(1,66);
%q(51:end)=1;
q([29 32 36 40 43 49]);
repairflag = logical(q);
%repairflag=logical([0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 1 0 0 1 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0]);

dirs = dirs(repairflag);

parfor mydir = 1:length(dirs)
    if isdir(dirs(mydir).name)
        cd(dirs(mydir).name)
        myfile = dir('*.hsd');
        if ~isempty(dir('*.hsd'))
            myfile = myfile.name;
            %extractSpikes(myfile,'tetrodes',10:18)
            extractSpikes(myfile)
        else
           disp('No HSD file found...') 
        end
    end
    cd(rawDataRoot)
end

