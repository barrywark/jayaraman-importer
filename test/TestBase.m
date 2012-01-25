% Copyright (c) 2012 Physion Consulting, LLC

classdef TestBase < TestCase
    
    properties
        context
        connection_file
        username
        password
        xsgFile
        experiment
        epochGroup
    end
    
    methods
        function self = TestBase(name)
            self = self@TestCase(name);
            
            import ovation.*;
            
            % N.B. these values should match those in runtestsuite
            self.connection_file = 'ovation/matlab_test.connection';
            self.username = 'TestUser';
            self.password = 'password';
            
            % N.B. these values should match those in runtestsuite
            self.xsgFile = 'fixtures/AA0002AAAA0002.xsg';
        end

        function setUp(self)
            import ovation.*;
            
            self.context = Ovation.connect(self.connection_file, self.username, self.password);
            
            itr = self.context.query('Experiment', 'true');
            
            self.experiment = itr.next();
            
            src = self.context.insertSource('test-batch');
            self.epochGroup = self.experiment.insertEpochGroup(src, 'Session', datetime());
            
        end

        function tearDown(self)
            self.context.close();
        end

    end
end
