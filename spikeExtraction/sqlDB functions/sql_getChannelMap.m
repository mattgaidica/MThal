function chMap = sql_getChannelMap(ratID, varargin)
%
% usage: chMap = findNASpath(ratID, varargin)
%
% function that will query the sql database to find the mapping from
% tetrodes to channel numbers for ratID
%
% INPUTS:
%   ratID - string with unique rat identifier (e.g., 'R0023')
%
% VARARGINs:
%   'hostIP' - IP address of the sql DB host server
%   'user' - user name to login to the sql DB
%   'password' - password to login to the sql DB
%   'dbname' - name of the sql DB
%   'sqljava_version' - version of the sql-java interface
%
% OUTPUT:
%   chMap - structure with the following fields:
%           .tetNames - names of the "tetrodes" (e.g., 'T01', 'E01', etc.)
%           .chMap - m x n array, where the first element of each row is
%                    the tetrode ID, and the last n-1 elements are the
%                    channel numbers for that tetrode. If there are
%                    different numbers of channels for each "tetrode",
%                    extra spaces for individual tetrodes are filled with
%                    zeros
           
% sqlJava_version = '5.0.8';
sqlJava_version = '';

hostIP = '172.20.138.142';
user = 'dleventh';
password = 'amygdala_probe';
dbName = 'spikedb';
 
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
     end
 end
 
versionString   = ['R' version('-release')];

if ispc
    matlabParentDir = fullfile('C:\Program Files', ...
                               'MATLAB', ...
                               versionString);
elseif ismac
    matlabParentDir = fullfile('/Applications', ...
                               ['MATLAB_' versionString '.app']);

elseif isunix
    
end

sql_java_main_path = fullfile(matlabParentDir, ...
                              'java', ...
                              'jarext');
                          
if isempty(sqlJava_version)
    cd(sql_java_main_path);
    java_connector_folder = dir('mysql-connector-java-*');

    if length(java_connector_folder) > 1
        java_connector_folder = java_connector_folder(1);
    end

    sql_java_path = fullfile(matlabParentDir, ...
                             'java', ...
                             'jarext', ...
                             java_connector_folder.name, ...
                             [java_connector_folder.name '-bin.jar']);
else             
    sql_java_path = fullfile(matlabParentDir, ...
                             'java', ...
                             'jarext', ...
                             ['mysql-connector-java-' sqlJava_version], ...
                             ['mysql-connector-java-' sqlJava_version '-bin.jar']);
end

if ~any(strcmp(javaclasspath('-static'),sql_java_path)) && ...
   ~any(strcmp(javaclasspath('-dynamic'),sql_java_path))
    javaaddpath(sql_java_path);
% elseif ~strcmp(sql_java_path, javaclasspath)
%     javaaddpath(sql_java_path);
end

jdbcString = sprintf('jdbc:mysql://%s/%s', hostIP, dbName);
jdbcDriver = 'com.mysql.jdbc.Driver';
conn = database(dbName, user , password, jdbcDriver, jdbcString);

if isconnection(conn)

    % first, get the ephys interface type from the subject table
    qry = sprintf('SELECT ephysInterface FROM subject WHERE subject.subjectName = "%s"',ratID);
    rs = fetch(exec(conn, qry));
    ephysInterfaceID = rs.data{1};
    if strcmpi(ephysInterfaceID, 'no data')
        error('sql_getChannelMap:invalidSubject',[ratID ' not found in subject table']);
    end
    
    % next, get the NAS IP address ID and name of the recordings folder from the nasLocation table
    qry = sprintf('SELECT tetrodeID, channelNumber FROM channelMap WHERE channelMap.interfaceID = %d',ephysInterfaceID);
    rs = fetch(exec(conn, qry));
    numChannels = size(rs.data, 1);
    tetrodeIDs = zeros(numChannels, 1);
    channelList = zeros(numChannels, 1);
    for iCh = 1 : numChannels
        tetrodeIDs(iCh) = rs.data{iCh, 1};
        channelList(iCh) = rs.data{iCh, 2};
    end
    
    unique_tetIDs = unique(tetrodeIDs);
    % find the maximum number of channel numbers for each tetrode
    maxChannels = 0;
    for iTet = 1 : length(unique_tetIDs)
        temp = find(tetrodeIDs == unique_tetIDs(iTet));
        if length(temp) > maxChannels
            maxChannels = length(temp);
        end
    end
    
    chMap.chMap = zeros(length(unique_tetIDs), maxChannels + 1);
    chMap.chMap(:,1) = unique_tetIDs;
    chMap.tetNames = cell(length(unique_tetIDs), 1);
    
    for iTet = 1 : length(unique_tetIDs)
        temp = find(tetrodeIDs == unique_tetIDs(iTet));
        chMap.chMap(iTet, 2:(length(temp)+1)) = channelList(temp)';
        
        qry = sprintf('SELECT tetrodeName FROM tetrode WHERE tetrode.tetrodeID = %d',unique_tetIDs(iTet));
        rs = fetch(exec(conn, qry));
        chMap.tetNames{iTet} = rs.data{1};
    end
    
    close(conn);
    
else

	error('sql_getChannelMap:invalidConnection','Cannot connect to sql database');

end