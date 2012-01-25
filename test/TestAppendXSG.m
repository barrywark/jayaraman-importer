% Copyright (c) 2012 Physion Consulting, LLC

classdef TestAppendXSG < TestBase
    
    properties
        xsg
        epoch
    end
    
    methods
        function self = TestAppendXSG(name)
            self = self@TestBase(name);
            self.xsg = load(self.xsgFile, '-mat');
        end
        
        function setUp(self)
            setUp@TestBase(self);
            
            import ovation.*
            
            triggerTime = self.xsg.header.acquirer.acquirer.triggerTime;
            startTime = datetime(triggerTime(1),...
                triggerTime(2),...
                triggerTime(3),...
                triggerTime(4),...
                triggerTime(5),...
                triggerTime(6));
            
            self.epoch = self.epochGroup.insertEpoch(startTime,...
                startTime.plusHours(1),... % TODO
                'jayarama-importer.test.TestAppendXSG',...
                struct2map(struct()));
        end
        
        function testShouldRaiseExceptionIfTriggerTimeMismatch(self)
            % Trigger time in .ephys, .stimulator, .acquirer
            
            badStartTime = self.epoch.getStartTime().minusHours(1);
            badEpoch = self.epochGroup.insertEpoch(self.epoch.getStartTime().minusHours(1),...
                badStartTime.plusMillis(self.xsg.header.acquirer.acquirer.traceLength*1000),...
                self.epoch.getProtocolID(),...
                self.epoch.getProtocolParameters());
            
            caughtException = false;
            try
                appendXSG(badEpoch,...
                    self.xsg,...
                    self.epoch.getStartTime().getZone().getID());
            catch ex
                if (strcmp(ex.identifier,'ovation:importer:xsg:triggerTimeMismatch'))
                    caughtException = true;
                else
                    rethrow(ex);
                end
            end
            
            assert(caughtException);
        end
        
        function testShouldRaiseExceptionIfTraceLengthMismatch(self)
            % traceLength time in .ephys, .stimulator, .acquirer
            
            badEpoch = self.epochGroup.insertEpoch(self.epoch.getStartTime(),...
                self.epoch.getStartTime().plusSeconds(self.xsg.header.acquirer.acquirer.traceLength*2),...
                self.epoch.getProtocolID(),...
                self.epoch.getProtocolParameters());
            
            caughtException = false;
            try
                appendXSG(badEpoch,...
                    self.xsg,...
                    self.epoch.getStartTime().getZone().getID());
            catch ex
                if (strcmp(ex.identifier,'ovation:importer:xsg:traceLengthMismatch'))
                    caughtException = true;
                else
                    rethrow(ex);
                end
            end
            
            assert(caughtException);
        end
        
        function testShouldRaiseExceptionIfPrefixMismatch(self)
            % If experiment, set, and sequence number properties are
            % present on the Epoch, they must match the values in
            % xsg.header.xsg.xsg]
            
            assert(false)
        end
        
        %% Protocol
        
        % loopGui params
        
        %% Stimulator
        function testShouldSetEphusDeviceChannelForStimulatorStimuli(self)
            assert(false);
        end
        
        function testShouldCreateStimulusForEachStimulatorChannel(self)
            %Pulse as stimulus parameters
            assert(false)
        end
        
        
        %% Acquirer
        function testShouldSetEphusDeviceChannelForAcquirerResposnes(self)
            assert(false)
        end
        
        function testShouldCreateResponseForEachAcquirerChannel(self)
            assert(false)
        end
        
        
        
        %% EPHYS
        
        function testShouldSupportOneAmplifier(~)
            % We support one amplifer. Two-amp support is not been tested
            assert(true);
        end
        
        function testShouldCreateStimulusForEphysIfSpecified(self)
            assert(false)
        end
        
        function testShouldCreateResponseForEphysIfSpecified(self)
            assert(false)
        end
        
        
        function testShouldSetAmplifierDeviceForEphysResponses(self)
            assert(false)
        end
        
        function testShouldSetAmplifierDeviceForEphysStimuli(self)
            assert(false)
        end
        
        function testShouldIncludeAmplifierConfigurationIfSpecified(self)
            % xsg.header.ephys.ephys.amplifierSettings contains amplifier
            % settings. The user must tell appendXSG whether to use the
            % amplifier settings (by specifying the appropriate channel
            % names).
            
            assert(false)
        end
        
    end
end
