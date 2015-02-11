function sql_addTetrodeSessions(ratID, varargin)
%
% usage: sql_addTetrodeSessions(ratID, varargin)
%
% function to find all the sessions for a given rat ID that include ephys
% recordings, and all the available tetrodes for the implant type for that
% rat, and add entries to the tetrodeSessions chart that aren't already
% there
%
% INPUTS:
%   ratID - "RZZZZ" where ZZZZ is the 4 digit rat identifier
%
% VARARGS:
%   hostip - ip address of the server hosting the sql database
%   user - user name for logging into the sql db
%   password - password for logging into the sql db
%   dbname - name of the sql database
%   sqljava_version - version of the current java-sql interface
%
% OUTPUTS:
%   none

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

if isempty(strcmp(sql_java_path, javaclasspath))
    javaaddpath(sql_java_path);
elseif ~strcmp(sql_java_path, javaclasspath)
    javaaddpath(sql_java_path);
end
                          
jdbcString = sprintf('jdbc:mysql://%s/%s', hostIP, dbName);
jdbcDriver = 'com.mysql.jdbc.Driver';
conn = database(dbName, user , password, jdbcDriver, jdbcString);

if isconnection(conn)

    qry = sprintf('SELECT subjectID, ephysInterface FROM subject WHERE subject.SubjectName = "%s"',ratID);
    rs = fetch(exec(conn, qry));
    subjectID = rs.Data{1};
    if strcmpi(subjectID, 'no data')
        error('sql_addTetrodeSessions:invalidSubject',[ratID ' not found in subject table']);
    end
    ephysInterfaceID = rs.Data{2};
    if isnan(ephysInterfaceID)
        error('sql_addTetrodeSessions:ephys_interface_undefined',['No eletrophysiology interface entered in sql database for' ratID]);
    end
    
    % get the list of tetrodes associated with this rat
    qry = sprintf('SELECT tetrodeID FROM channelMap WHERE channelMap.interfaceID = "%d"',ephysInterfaceID);
    rs = fetch(exec(conn, qry));
    if strcmpi(rs.Data{1},'no data')
        error('sql_addTetrodeSessions:invalid_ephys_interface',['Electrophysiology interface ' num2str(ephysInterfaceID) ' undefined']);
    end
    tetrodeIDlist = zeros(length(rs.Data), 1);
    for iTet = 1 : length(tetrodeIDlist)
        tetrodeIDlist(iTet) = rs.Data{iTet};
    end
    tetrodeIDlist = unique(tetrodeIDlist);
    
    % find all the sessions already entered in the sql database for that
    % rat that have ephys recordings
    qry = sprintf('SELECT sessionID FROM session WHERE session.subjectID = "%d" AND ephysSystemID > "0"',subjectID);
    rs = fetch(exec(conn, qry));
    if strcmpi(rs.Data{1}, 'no data')
        error('sql_addTetrodeSessions:noValidSessions',['No sessions for ' ratID ' found in session table']);
    end 
    sessionID = zeros(length(rs.Data), 1);
    for iSession = 1 : length(sessionID)
        sessionID(iSession) = rs.Data{iSession};
    end
    
    % find the last tetrodeSession ID already in the table
    qry = sprintf('SELECT MAX(tetrodeSessionID) FROM tetrodeSession');
    rs = fetch(exec(conn, qry));
	lastTetSessionID = rs.Data{1};
    if isnan(lastTetSessionID); lastTetSessionID = 0; end
    
    % now loop through the sessions to see if all tetrode-sessions have
    % been set up in the table
    for iSession = 1 : length(sessionID)
        for iTet = 1 : length(tetrodeIDlist)
            if lastTetSessionID > 0
                qry = sprintf('SELECT tetrodeSessionID FROM tetrodeSession WHERE tetrodeSession.sessionID = "%d" AND tetrodeSession.tetrodeID = "%d"', sessionID(iSession), tetrodeIDlist(iTet));
                rs = fetch(exec(conn, qry));
                if ~iscell(rs.Data)
                    tetrodeSessionID = 0;
                else
                    tetrodeSessionID = rs.Data{1};
                end
                if isnumeric(tetrodeSessionID)   % not sure exactly what's going on here; rs.Data{1} = 0 when the current tetrodeSession is not in the table, not sure why but this seems to work
                    if tetrodeSessionID > 0
                        continue; 
                    end    
                end    % a valid tetrodeSession identifier already exists for this tetrode-session combination
            end
            
            lastTetSessionID = lastTetSessionID + 1;
            
            qry = sprintf('INSERT INTO tetrodeSession (tetrodeSessionID, tetrodeID, sessionID) VALUES ("%d", "%d", "%d")', ...
                          lastTetSessionID, ...
                          tetrodeIDlist(iTet), ...
                          sessionID(iSession));
            rs = fetch(exec(conn, qry));

        end
    end
    
    close(conn);
    
else
    
    error('sql_createSessionsFromRaw:invalidConnection','Cannot connect to sql database');
    
end