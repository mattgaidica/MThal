function chSigma = extractSigma_snle_TDT(rawdataPath, chList, validMask, numSigmaSegments, t_chunk, r_upsample, varargin)
%
% usage: chSigma = extractSigma_snle(rawdataPath, chList, numSigmaSegments,
%   chunkSize)
%
% function that calculates......                                    add full description here
%
% INPUTS:
%   rawdataPath - name of the path to the raw data for the current session
%   chList - list of channels for this tetrode
%   validMask - boolean vector the same length as chList. "0"s indicate bad
%       channels that should be ignored; "1"s indicate good channels that
%       should be included in the calculations
%   numSigmaSegments - number of segments to use in calculating sigma
%   chunkSize - size of each data segment to use in calculating sigma
%
% VARARGs:
%   'machineformat' - machine format for reading the binary data (ie, 'b'
%       for big-endian, 'l' for little-endian)
%   'snlewindow' - window width for the smoothed nonlinear energy
%       calculation
%   'windowsize'
%
% OUTPUTS:
%   chSigma - vector containing the standard deviation of the signal on
%       each wire in chList
% 

windowSize    = 12 * r_upsample;
sincLength    = 13;     % length of sinc function for sinc interpolation
maxLevel      = 0;
maxSNLE       = 10^5;   % maximum allowable non-linear energy. Any values 
                        % greater than this are assumed to be noise and
                        % are not included in the standard deviation
                        % calculations (but are thresholded and
                        % extracted as potential spikes)
cutoff_Fs     = 9000;
                        
if isempty(find(validMask, 1))
    disp(['No active channels for ' sessionName]);
    return
end

for iarg = 1 : 2 : nargin - 6
    
    switch lower(varargin{iarg})

        case 'machineformat',
            machineFormat = varargin{iarg + 1};
        case 'snlewindow',
            windowSize = varargin{iarg + 1};
        case 'maxlevel',
            maxLevel = varargin{iarg + 1};
        case 'sinclength',
            sincLength = varargin{iarg + 1};
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
r_upsample = round(r_upsample);
if maxLevel == 0            % allow user to define maxLevel, but if they haven't automatically set it to the upsample ratio + 5
    maxLevel = r_upsample + 4;      % cutoff frequency = samplingrate/(2^(maxlevel+1))
                                    % this should make the cutoff frequency
                                    % ~230 Hz for an initial sampling rate
                                    % of ~30 kHz. For an initial sampling
                                    % rate of 20 kHz, the cutoff will be
                                    % ~150 Hz. May want to use r_upsample +
                                    % 4 if Fs = 20 kHz (cutoff ~300 Hz)
end

% load the header from the first .sev file for this tetrode to get
% recording parameters
cd(rawdataPath);
[~, sessionName, ~] = fileparts(rawdataPath);

% find the names of the .sev files
sevNames = cell(length(chList), 1);
sevInfo = dir('*.sev');
if isempty(sevInfo)
    error('extractSigma_snle_TDT_20141207:noSevFiles',['Cannot find sev files for ' sessionName]);
end
firstValidSev = 0;
for iCh = 1 : length(chList)
    for iSev = 1 : length(sevInfo)
        header = getSEVHeader(sevInfo(iSev).name);
        if header.channelNum == chList(iCh)
            sevNames{iCh} = sevInfo(iSev).name;
            if firstValidSev == 0
                firstValidSev = iSev;
            end
        end
    end
end
if ~firstValidSev
    error('extractSigma_snle_TDT_20141207:noSevFilesForRequestedChannels',['Cannot fine sev files for current tetrode in ' sessionName]);
end

Fs         = header.Fs;
final_Fs   = Fs * r_upsample;
numCh      = length(chList);
datalength = (header.fileSizeBytes - header.dataStartByte) / header.sampleWidthBytes;

if Fs == 0
    Fs = 24414.0625;
end

chunkSize = round(t_chunk * Fs);

padLength = floor((datalength - chunkSize * numSigmaSegments) / numSigmaSegments);
% padLength is the spacing between the segments selected for calculation of
% the standard deviation

if padLength < 0
    if datalength/Fs < 70
        chunkSize = datalength;
        padLength = 0;
        numSigmaSegments = 1;
    else
        chunkSize = round(Fs);
        numSigmaSegments = floor(datalength / chunkSize);
        padLength = 0;
    end
end

totSamples = chunkSize * numSigmaSegments;

wireSamps = zeros(totSamples,numCh);

for iCh = 1 : numCh
    if validMask(iCh)        
        [sev, ~] = read_tdt_sev(sevNames{iCh});    
        wireSampIdx = 1;
        readStartSamp = 1;
        readStopSamp = chunkSize;
        for iChunk = 1 : numSigmaSegments
            temp = sev(readStartSamp : readStopSamp);
            temp = sincInterp(temp, Fs, cutoff_Fs, final_Fs, 'sinclength', sincLength);
            temp = wavefilter(temp', maxLevel);
            SNLEdata = snle( temp, 1, 'windowsize', windowSize );
            wireSamps(wireSampIdx : wireSampIdx + chunkSize * r_upsample - 1, iCh) = SNLEdata;
            wireSampIdx = wireSampIdx + chunkSize * r_upsample;
            readStartSamp = readStartSamp + chunkSize + padLength;
            readStopSamp = readStartSamp + chunkSize-1;
        end
    end    % if validMask(iCh)
end

wireSamps(wireSamps > maxSNLE) = NaN;
% chSigma = nanstd(wireSamps, 0, 1);
chSigma = nanmedian((wireSamps / 0.6745), 1);
chSigma = chSigma';