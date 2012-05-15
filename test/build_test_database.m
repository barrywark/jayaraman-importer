% Copyright (c) 2012 Physion Consulting, LLC

function build_test_database(test_folder)
    % This script builds a new Ovation database for testing and imports the
    % test fixture. Run this script from the pladps-importer/test directory.
    %
    % After running runtestsuite, you may run runtests (the Matlab xUnit test
    % runner) to re-run the test suite without building a new database or
    % re-importing the test fixture data.
        
    error(nargchk(0, 1, nargin)); %#ok<NCHKI>
    if(nargin < 1)
        test_folder = pwd();
    end
    
    % N.B. these values should match in TestBase
    connection_file = fullfile(test_folder, 'ovation', 'matlab_test.connection');
    username = 'TestUser';
    password = 'password';
    
    % We're tied to the test fixture defined by these files, but this is the
    % only dependency. There shouldn't be any magic numbers in the test code.
    xsgFile = fullfile(test_folder, 'fixtures/AA0002AAAA0002.xsg');
    setenv('XSG_FILE', xsgFile);
    
    % Delete the test database if it exists
    if(exist(connection_file, 'file') ~= 0)
        ovation.util.deleteLocalOvationDatabase(connection_file, true);
    end
    
    % Create a test database
    system('mkdir -p ovation');
    
    connection_file = ovation.util.createLocalOvationDatabase(fullfile(test_folder, 'ovation'), ...
        'matlab_test',...
        username,...
        password);
    
    import ovation.*
    
    ctx = Ovation.connect(fullfile(pwd(), connection_file), username, password);
    
    project = ctx.insertProject('TestImportMapping',...
        'TestImportMapping',...
        datetime());
    
    expt = project.insertExperiment('TestImportMapping',...
        datetime());
    source = ctx.insertSource('animal');
end