classdef TestBase < TestCase
    properties
        context
        connection_file
        username
        password
    end
    
    methods
        function self = TestBase(name)
            self = self@TestCase(name);
            
            import ovation.*;
            
            % N.B. these values should match those in runtestsuite
            self.connection_file = 'ovation/matlab_test.connection';
            self.username = 'TestUser';
            self.password = 'password';
        end

        function setUp(self)
            import ovation.*;
            
            self.context = Ovation.connect(self.connection_file, self.username, self.password);
            
        end

        function tearDown(self)
            self.context.close();
        end

    end
end
