% Matlab code for wavelet filtering.
% This function requires the Wavelet Toolbox.

function fdata = wavefilter(data, goodWires, maxlevel)
%
% usage: fdata = wavefilter(data, maxlevel)
%
% INPUTS:
%   data - an N x M array of continuously-recorded raw data
%		where N is the number of channels, each containing M samples
%   goodWires - vector containing "true" for each usable wire, and "false"
%       for each bad wire, so unneccessary calculations aren't made
%   maxlevel - the level of decomposition to perform on the data. This integer
%		implicitly defines the cutoff frequency of the filter.
% 		Specifically, cutoff frequency = samplingrate/(2^(maxlevel+1))
%
% OUTPUTS:
%   fdata - wavelet filtered data in an N x M array, where N is the number
%       of channels, and M is the number of samples

[numwires, numpoints] = size(data);
fdata = zeros(numwires, numpoints);

% We will be using the Daubechies(4) wavelet.
% Other available wavelets can be found by typing 'wavenames'
% into the Matlab console.
wname = 'db4'; 

for i=1:numwires % For each wire
    if goodWires(i)
        % Decompose the data
        [c,l] = wavedec(data(i,:), maxlevel, wname);
        % Zero out the approximation coefficients
        c = wthcoef('a', c, l);
        % then reconstruct the signal, which now lacks low-frequency components
        fdata(i,:) = waverec(c, l, wname);
    end
end