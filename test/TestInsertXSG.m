% Copyright (c) 2012 Physion Consulting, LLC

classdef TestInsertXSG < TestBase
    
    properties
        xsg
    end
    
    methods
        function self = TestInsertXSG(name)
            self = self@TestBase(name);
            self.xsg = load(self.xsgFile, '-mat');
        end
        
        
        function testShouldUseProvidedProtocolID(self)
            protocolID = 'testShouldUseProvidedProtocolID';
            timezone = 'America/New_York';
            epoch = insertXSGEpoch(self.epochGroup, self.xsg, protocolID, timezone);
            
            assert(epoch.getProtocolID().equals(protocolID));
        end
        
        function testShouldInsertEpochWithXSGTriggerTimeStartTime(self)
            
            import ovation.*
            
            timezone = 'America/New_York';
            epoch = insertXSGEpoch(self.epochGroup, self.xsg, 'protocol', timezone);
            
            % Acquirer
            triggerTime = self.xsg.header.acquirer.acquirer.triggerTime;
            startTime = datetime(triggerTime(1),...
                triggerTime(2),...
                triggerTime(3),...
                triggerTime(4),...
                triggerTime(5),...
                floor(triggerTime(6)),...
                rem(triggerTime(6),1) * 1000,... %millis
                timezone);
            
            diff = org.joda.time.Period(startTime, epoch.getStartTime()).toStandardDuration();
            assert(diff.getMillis() < 500);
            
            % Stimulator
            triggerTime = self.xsg.header.stimulator.stimulator.triggerTime;
            startTime = datetime(triggerTime(1),...
                triggerTime(2),...
                triggerTime(3),...
                triggerTime(4),...
                triggerTime(5),...
                floor(triggerTime(6)),...
                rem(triggerTime(6),1) * 1000,... %millis
                timezone);
            
            diff = org.joda.time.Period(startTime, epoch.getStartTime()).toStandardDuration();
            assert(diff.getMillis() < 500);
            
            % Ephys
            triggerTime = self.xsg.header.ephys.ephys.triggerTime;
            startTime = datetime(triggerTime(1),...
                triggerTime(2),...
                triggerTime(3),...
                triggerTime(4),...
                triggerTime(5),...
                floor(triggerTime(6)),...
                rem(triggerTime(6),1) * 1000,... %millis
                timezone);
            
            diff = org.joda.time.Period(startTime, epoch.getStartTime()).toStandardDuration();
            assert(diff.getMillis() < 500);
            
            
        end
    end
end