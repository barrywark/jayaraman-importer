% Copyright (c) 2012 Physion Consulting, LLC

function runtestsuite(test_folder)
    % This script builds a new Ovation database for testing and imports the
    % test fixture. Run this script from the pladps-importer/test directory.
    %
    % After running runtestsuite, you may run runtests (the Matlab xUnit test
    % runner) to re-run the test suite without building a new database or
    % re-importing the test fixture data.
    
    error(nargchk(0, 1, nargin)); %#ok<NCHKI>
    if(nargin < 1)
        test_folder = [pwd() '/'];
    else
        test_folder = [test_folder '/'];
    end
    
    % N.B. these values should match in TestBase
    connection_file = [test_folder 'ovation/matlab_test.connection'];
    username = 'TestUser';
    password = 'password';
    
    % We're tied to the test fixture defined by these files, but this is the
    % only dependency. There shouldn't be any magic numbers in the test code.
    xsgFile = [test_folder 'fixtures/AA0002AAAA0002.xsg'];
    setenv('XSG_FILE', xsgFile);
    
    % Delete the test database if it exists
    if(exist(connection_file, 'file') ~= 0)
        ovation.util.deleteLocalOvationDatabase(connection_file);
    end
    
    % Create a test database
    system('mkdir -p ovation');
    
    connection_file = ovation.util.createLocalOvationDatabase([test_folder '/ovation'], ...
        'matlab_test',...
        username,...
        password,...
        'license.txt',...
        'ovation-development');
    
    import ovation.*
    ctx = Ovation.connect(connection_file, username, password);
    project = ctx.insertProject('TestImportMapping',...
        'TestImportMapping',...
        datetime());
    
    expt = project.insertExperiment('TestImportMapping',...
        datetime());
    source = ctx.insertSource('animal');
    
    
    runtests(test_folder, '-xmlfile', 'test-output.xml');
end
