function extractSpikesTDT(sessionName, varargin)
%
% usage: extractSpikesTDT_20141205( sessionName, varargin )
%
% This function will                                                  % ADD IN THE FUNCTION DESCRIPTION HERE
%
% INPUTS:
%   sessionName - full path to the session to be analyzed
%
% VARARGINs:
%   'hostIP' - IP address of the sql DB host server
%   'user' - user name to login to the sql DB
%   'password' - password to login to the sql DB
%   'dbname' - name of the sql DB
%   'sqljava_version' - version of the sql-java interface
%
%   'tetrodelist' - list of tetrodes on which to perform the analysis
%       (default is to analyze all non-EEG/EMG channels). Enter as 't01',
%       'r03', etc. in a cell array
%   'threshold'
%   'numsigmasegments'                                                  % NEED TO ADD IN THE REST OF THE VARARGS
%
% DEPENDENCIES:
%   extractSigma_snle_TDT_20141207
%   appendNexWaveforms
%   channelTypeFromHeader
%   extract_timestamps_sincInterp
%   getBytesPerSample
%   gettimestampsSNLE
%   lfpFs
%   readHSD
%   wavefilter


%%%%%%%%%%%%%%channel map is pulled out from a database channelMap table.%%%%%%%%%%%%%%
javaaddpath('C:\Program Files\MATLAB\R2014b\java\jarext\mysql-connector-java-5.1.34\mysql-connector-java-5.1.34-bin.jar')
% hostIP = '172.20.138.142';
% user = 'dleventh';
% password = 'amygdala_probe';
% dbName = 'spikedb';

tetrodeList      = {};
rel_threshold    = 5;   % in units of standard deviation
numSigmaSegments = 60;  % number of segments to use to calculate the standard deviation of the signal on each wire
sigmaChunkLength = 1;   % duration in seconds of data chunks to use to extract the standard deviations of the wavelet-filtered signals
snle_window      = 12;    % Alex's default
r_upsample       = 2;     % the upsampling ratio
waveLength       = 24;    % width of waveform sampling window in A-D clock ticks
peakLoc          = 8;     % location of waveform peak in A-D clock ticks
deadTime         = 16;    % dead time in A-D clock ticks
overlapTolerance = 16;     % amount waveforms can overlap on different wires
% of the same tetrode (in A-D clock ticks) and
% still be counted as the same waveform
maxSNLE          = 10^7;  % maximum allowable non-linear energy. Any values
% greater than this are assumed to be noise and
% are not included in the standard deviation
% calculations (but are thresholded and
% extracted as potential spikes)
maxLevel = r_upsample + 4;    % max wavelet filtering level = upsampling ratio + 5
cutoff_Fs        = 9000; % cutoff of the anti-aliasing filter, needed for the sincInterp function
startTime        = 0;
endTime          = 0;

 for iarg = 1 : 2 : nargin - 1
     switch lower(varargin{iarg})
         case 'hostip'
             hostIP = varargin{iarg + 1};
         case 'user',
             user = varargin{iarg + 1};
         case 'password',
             password = varargin{iarg + 1};
         case 'dbname',
             dbName = varargin{iarg + 1};
         case 'sqljava_version',
             sqlJava_version = varargin{iarg + 1};
         case 'tetrodelist',
             tetrodeList = varargin{iarg + 1};
         case 'threshold',
             rel_threshold = varargin{iarg + 1};
         case 'numsigmasegments',
             numSigmaSegments = varargin{iarg + 1};
         case 'machineformat',
             machineFormat = varargin{iarg + 1};
         case 'upsampleratio',
             r_upsample = varargin{iarg + 1};
         case 'wavelength',
             waveLength = varargin{iarg + 1};
         case 'peakloc',
             peakLoc = varargin{iarg + 1};
         case 'deadtime',
             deadTime = varargin{iarg + 1};
         case 'overlaptolerance',
             overlapTolerance = varargin{iarg + 1};
         case 'maxsnle',
             maxSNLE = varargin{iarg + 1};
         case 'sincinterp_cutoff_fs',
            cutoff_Fs = varargin{iarg + 1};
         case 'starttime',
             startTime = varargin{iarg + 1};            % added in to make it possible to set start and end times for processing (for example, in case there was a long period before recording was initiated after turning on the software).
         case 'endtime',                                % this functionality has not been added to the code yet, though. -DL 12/15/2014
             endTime = varargin{iarg + 1};
     end
 end

[~, ratID] = sql_getSubjectFromSession(sessionName, ...
                                               'hostip', hostIP, ...
                                               'user', user, ...
                                               'password', password, ...
                                               'dbname', dbName);
chMap = sql_getChannelMap(ratID, ...
                          'hostip', hostIP, ...
                          'user', user, ...
                          'password', password, ...
                          'dbname', dbName);
                      
if isempty(tetrodeList); tetrodeList = chMap.tetNames; end
if ~iscell(tetrodeList); tetrodeList = {tetrodeList}; end

nasPath = sql_findNASpath(ratID, ...
                          'hostip', hostIP, ...
                          'user', user, ...
                          'password', password, ...
                          'dbname', dbName);
                      
sessionTDTpath       = fullfile(nasPath, ratID, [ratID '-rawdata'], sessionName, sessionName);
processedSessionPath = fullfile(nasPath, ratID, [ratID '-processed']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if ~exist(processedSessionPath, 'dir')
    mkdir(processedSessionPath);            % defined above after nasPath extracted from the sql db
end

tetChannels = zeros(length(tetrodeList), size(chMap.chMap, 2));
numValidTets = 0;
for iTet = 1 : length(tetrodeList)
    tetIdx = find(strcmpi(tetrodeList{iTet}, chMap.tetNames));
    if ~isempty(tetIdx)
        numValidTets = numValidTets + 1;
        tetChannels(numValidTets,:) = chMap.chMap(tetIdx,:);
    end
end
tetChannels = tetChannels(1:numValidTets, :);
tetWireStd = zeros(numValidTets, 4);
for iTet = 1 : numValidTets
    % updated by Matt 20141231
    validMask = sql_getValidTetChannels(sessionName, tetChannels(iTet), ...
                                        'hostip', hostIP, ...
                                        'user', user, ...
                                        'password', password, ...
                                        'dbname', dbName);
                                    
%     validMask = sql_getValidTetChannels(sessionName, chMap.chMap(iTet, 1), ...
%                                         'hostip', hostIP, ...
%                                         'user', user, ...
%                                         'password', password, ...
%                                         'dbname', dbName);

	validMask(isnan(validMask)) = 0;
                                                                 % working on the assumption that all channels that haven't been marked in the database are bad or don't exist (for example, single wires)
    if ~any(validMask)
        disp(['Skipping ' sessionName ', tetrode ' tetrodeList{iTet} ' - no valid channels']);
        continue;
    end    % no valid channels for this tetrode
    
    disp(['calculating single wire standard deviations for tetrode ' tetrodeList{iTet}]);
    
    tetWireStd(iTet, :) = extractSigma_snle_TDT(sessionTDTpath, ...            % NOTE: As of 20141208, it's actually not the standard deviation, but the median of the snle / 0.6745 
                          chMap.chMap(tetChannels(iTet), 2:end), ...
                          validMask, ...
                          numSigmaSegments, sigmaChunkLength, r_upsample, ...
                          'snlewindow', snle_window, ...
                          'maxlevel', maxLevel, ...
                          'maxsnle', maxSNLE, ...
                          'sincinterp_cutoff_fs', cutoff_Fs, ...
                          'starttime', startTime, ...
                          'endtime', endTime);
                      
%     tetWireStd(iTet, :) = extractSigma_snle_TDT_20141207(sessionTDTpath, ...            % NOTE: As of 20141208, it's actually not the standard deviation, but the median of the snle / 0.6745 
%                           chMap.chMap(iTet, 2:end), ...
%                           validMask, ...
%                           numSigmaSegments, sigmaChunkLength, r_upsample, ...
%                           'snlewindow', snle_window, ...
%                           'maxlevel', maxLevel, ...
%                           'maxsnle', maxSNLE, ...
%                           'sincinterp_cutoff_fs', cutoff_Fs, ...
%                           'starttime', startTime, ...
%                           'endtime', endTime);

end

tet_thresholds  = rel_threshold * tetWireStd;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% at this point, should have standard deviations for the wavelet filtered
% signal on each relevant wire - now time to do the thresholding!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iTet = 1 : length(tetrodeList)
    % updated by Matt 20141231
    validMask = sql_getValidTetChannels(sessionName, tetChannels(iTet), ...
                                        'hostip', hostIP, ...
                                        'user', user, ...
                                        'password', password, ...
                                        'dbname', dbName);
                                    
%     validMask = sql_getValidTetChannels(sessionName, chMap.chMap(iTet, 1), ...
%                                         'hostip', hostIP, ...
%                                         'user', user, ...
%                                         'password', password, ...
%                                         'dbname', dbName);

	validMask(isnan(validMask)) = 0;
    
    extract_PLXtimestamps_sincInterp_TDT(sessionTDTpath, tetrodeList{iTet}, chMap.chMap(iTet, 2:end), tet_thresholds(iTet, :), validMask, ...
        'wavelength', waveLength, ...
        'peakloc', peakLoc, ...
        'snlewindow', snle_window, ...
        'deadtime', deadTime, ...
        'upsampleratio', r_upsample, ...
        'overlaptolerance', overlapTolerance, ...
        'starttime', startTime, ...
        'endtime', endTime);
end
