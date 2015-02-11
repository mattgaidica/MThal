function [subjectID, ratID] = sql_getSubjectFromSession(sessionName, varargin)
%
% usage: nasPath = sql_findNASpath(ratID, varargin)
%
% function that will query the sql database to get the path on the nas
% server to the data for ratID
%
% INPUTS:
%   sessionName - string with unique session identifier (e.g., 'R0035_20141203a')
%
% VARARGINs:
%   'hostIP' - IP address of the sql DB host server
%   'user' - user name to login to the sql DB
%   'password' - password to login to the sql DB
%   'dbname' - name of the sql DB
%   'sqljava_version' - version of the sql-java interface
%
% OUTPUT:
%   subjectID - the subject ID from the sql database (this is an integer)
%   ratID - the ratID (subjectName in the sql db), a string in the format
%       "RZZZZ"
           
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
conn = database(dbName, user, password, jdbcDriver, jdbcString);

if isconnection(conn)

    % first, get the subjectID given the session name
    qry = sprintf('SELECT subjectID FROM session WHERE session.sessionName= "%s"', sessionName);
    rs = fetch(exec(conn, qry));
    subjectID = rs.data{1};
    if strcmpi(subjectID, 'no data')
        error('sql_getSubjectFromSession:invalidSession',['Cannot find session ' sessionName ' in sql database']);
    end
    
    % next, get the rat ID given the subjectID
    qry = sprintf('SELECT subjectName FROM subject WHERE subject.subjectID = %d', subjectID);
    rs = fetch(exec(conn, qry));
    ratID = rs.data{1};
    
    close(conn);

else

	error('sql_getSubjectFromSession:invalidConnection','Cannot connect to sql database');

end