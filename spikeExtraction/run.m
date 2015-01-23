% update ephys interface and NAS location: spike.subject
% create the recording session: spike.session
% use session ID to fill in all tetrodes: spike.tetrodeSession

sqlCredentials = getSqlCredentials;
extractSpikesTDT('R0040_20150119h',sqlCredentials{:});