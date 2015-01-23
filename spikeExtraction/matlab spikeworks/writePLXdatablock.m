function writePLXdatablock( fid, spikes, ts )
%
% usage: writePLXdatablock( fid, spikes, ts )
%
% Write PLX datablocks corresponding to the data
% found in the arrays spikes, ts, and channel
% We assume these are spikes on the given channel, 
% of the length of the waveforms given in spikes
%
% INPUTS:
%	fid - pointer to an open PLX file with headers written in (using writePLXfileheader and  writePLXchanheader)
%	spikes     - numspikes by len(spike) by 4 array of spikes on a tetrode (the actual waveforms?)
%	channel    - the channel number that the spikes are found on
%	ts         - time-stamps corresponding the spikes (int16's in tick counts, I think - DL 20120515)


% Only the time-stamps, spikes & channel number change when writing all spikes and 
% time-stamps out from a particular channel, so we can make 
% slices of byte-bread to sandwich the time-stamp that stay constant

numSpikes = size(spikes, 1);
numWires  = size(spikes, 3);    % check that the dimensions are correct for my data structures
% OLD CODE HERE
% for iSpike = 1 : 1%numSpikes
%     for iWire = 1 : numWires
%    
%         fwrite(fid, 1,'int16', 0, 'l');    % not sure why these constants are written, but it worked in Alex's python code
%         fwrite(fid, 0,'int16', 0, 'l');
%         fwrite(fid, ts(iSpike),'uint32', 0, 'l');    % write the timestamp
%         fwrite(fid, iWire, 'int16', 0, 'n'); %changed from 'b' by Matt Gaidica, 20141231

%         fwrite(fid, [0 1 size(spikes, 2)], 'int16', 0, 'l');
%         fwrite(fid, squeeze(spikes(iSpike, :, iWire)), 'int16', 0, 'l');
%         
%     end
% end

% MERGED FROM SAMPLE
for iSpike = 1 : numSpikes
    for iWire = 1 : numWires
        fwrite(fid, 1, 'integer*2');           % type: 1 = spike
        fwrite(fid, 0, 'integer*2');           % upper byte of 5-byte timestamp
        fwrite(fid, ts(iSpike), 'integer*4');    % lower 4 bytes, write the timestamp
        fwrite(fid, iWire, 'integer*2'); % ch number
        
% Why do these two lines appears in the Plexon SDK but don't work for us?
%         fwrite(fid, 0, 'integer*2');  % unit no. (0 = unsorted)
%         fwrite(fid, 1, 'integer*2');           % no. of waveforms = 1
        fwrite(fid, [0 1 size(spikes, 2)],'integer*2'); % no. of samples per waveform
        fwrite(fid, squeeze(spikes(iSpike, :, iWire)),'integer*2'); %waveform data
    end
end

% SAMPLE CODE FROM PLEXON SDK
% for ispike = 1:n
% 
%   fwrite(plx_id, 1, 'integer*2');           % type: 1 = spike
%   fwrite(plx_id, 0, 'integer*2');           % upper byte of 5-byte timestamp
%   fwrite(plx_id, ts(ispike)*freq, 'integer*4');  % lower 4 bytes
%   fwrite(plx_id, ch, 'integer*2');          % channel number

%   fwrite(plx_id, units(ispike), 'integer*2');  % unit no. (0 = unsorted)
%   fwrite(plx_id, 1, 'integer*2');           % no. of waveforms = 1
%   fwrite(plx_id, npw, 'integer*2');         % no. of samples per waveform
% 
%   fwrite(plx_id, wave(ispike, 1:npw), 'integer*2');
%    
% end