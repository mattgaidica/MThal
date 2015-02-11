function validMask = sql_getValidTetChannels(sessionName, tetrodeID, varargin)
%
% usage: sql_getValidTetChannels(sessionName, tetrodeID, varargin)
%
% function to read in valid tetrode channels for a given tetrode-session.
% If the tetrode-session is not found in the sql database, 
%
% INPUTS:
%   sessionName - name of the recording session in the format
%       "RZZZZ_YYYYMMDDX" where ZZZZ is the 4 digit rat identifier,
%       YYYYMMDD is the date, and X is a letter indicating the specific
%       session for that date (i.e., 'a', 'b', etc.)
%   tetrodeID - ID of the tetrode in the tetrode database for which to
%       extract which wires are good
%
% VARARGS:
%   hostip - ip address of the server hosting the sql database
%   user - user name for logging into the sql db
%   password - password for logging into the sql db
%   dbname - name of the sql database
%   sqljava_version - version of the current java-sql interface
%
% OUTPUTS:
%   validMask

% sqlJava_version = '5.0.8';
sqlJava_version = '';

hostIP = '172.20.138.142';
user = 'dleventh';
password = 'amygdala_probe';
dbName = 'spikedb';
 
 for iarg = 1 : 2 : nargin - 2
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

    % get the sessionID from the session table for the given session name
    qry = sprintf('SELECT sessionID FROM session WHERE session.sessionName= "%s"',sessionName);
    rs = fetch(exec(conn, qry));
    sessionID = rs.Data{1};
    if strcmpi(sessionID, 'no data')
        error('sql_getValidTetChannels:invalidSession',[sessionName ' not found in session table']);
    end
    
    % read the "channelvalid" fields from the sql database for this
    % tetrode-session pair
    qry = sprintf('SELECT ch1valid, ch2valid, ch3valid, ch4valid FROM tetrodeSession WHERE tetrodeSession.sessionID = "%d" AND tetrodeSession.tetrodeID = "%d"',...
                  sessionID, ...
                  tetrodeID);
    rs = fetch(exec(conn, qry));
    if strcmpi(rs.Data{1},'no data')
        error('sql_getValidTetChannels:invalidTetrodeSession',['tetrode-session combination not found in sql database']);
    end
    validMask = zeros(1, length(rs.Data));   % made this general in case we have different electrodes with more channels/"tetrode" in the future
    for i_isValid = 1 : length(rs.Data)
        validMask(i_isValid) = rs.Data{i_isValid};
    end
    
    close(conn);
    
else
    
    error('sql_createSessionsFromRaw:invalidConnection','Cannot connect to sql database');
    
end