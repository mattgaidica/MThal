function nasPath = sql_findNASpath(ratID, varargin)
%
% usage: nasPath = sql_findNASpath(ratID, varargin)
%
% function that will query the sql database to get the path on the nas
% server to the data for ratID
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
%   nasPath - string containing the path to the data directory for ratID
           
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

    % first, get the NAS location ID and experiment ID from the subject table
    qry = sprintf('SELECT nasLocation,experimentID FROM subject WHERE subject.subjectName = "%s"',ratID);
    rs = fetch(exec(conn, qry));
    nasLocationID = rs.data{1};
    if strcmpi(nasLocationID, 'no data')
        error('sql_findNASpath:invalidSubject',[ratID ' not found in subject table']);
    end
    experimentID = rs.data{2};

    % next, get the NAS IP address ID and name of the recordings folder from the nasLocation table
    qry = sprintf('SELECT nasIPaddress,recordingsFolder FROM nasLocation WHERE nasLocation.id = %d',nasLocationID);
    rs = fetch(exec(conn, qry));
    nasIPaddressID = rs.data{1};
    recordingsFolder = rs.data{2};

    % next, get the name of the experiment from the experiment table
    qry = sprintf('SELECT experimentName FROM experiment WHERE experiment.ExperimentID = %d',experimentID);
    rs = fetch(exec(conn, qry));
    experimentName = rs.data{1};

    % now, get the IP address from the nasIPaddress table
    qry = sprintf('SELECT IPaddress FROM nasIPaddress WHERE nasIPaddress.id = %d',nasIPaddressID);
    rs = fetch(exec(conn, qry));
    nasIPaddress = rs.data{1};

    if ispc
     IPpath = sprintf('\\\\%s',nasIPaddress);
    elseif ismac
     IPpath = '/Volumes';
    elseif isunix
     IPpath = '';
    end

    nasPath = fullfile(IPpath, recordingsFolder, experimentName);
    
    close(conn);

else

	error('findNASpath:invalidConnection','Cannot connect to sql database');

end