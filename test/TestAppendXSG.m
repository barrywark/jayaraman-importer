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
                floor(triggerTime(6)),...
                rem(triggerTime(6),1) * 1000);
            
            self.epoch = self.epochGroup.insertEpoch(startTime,...
                startTime.plusHours(1),... % TODO
                'jayarama-importer.test.TestAppendXSG',...
                struct2map(struct()));
        end
        
        function testShouldRaiseExceptionIfTriggerTimeMismatch(self)
            % Trigger time in .ephys, .stimulator, .acquirer
            
            badStartTime = self.epoch.getStartTime().minusHours(1);
            badEpoch = self.epochGroup.insertEpoch(badStartTime,...
                badStartTime.plusMillis(self.xsg.header.acquirer.acquirer.traceLength*1000),...
                self.epoch.getProtocolID(),...
                self.epoch.getProtocolParameters());
            
            self.checkThrows(badEpoch, ...
                'ovation:importer:xsg:triggerTimeMismatch');
        end
        
        function testShouldRaiseExceptionIfTraceLengthMismatch(self)
            % traceLength time in .ephys, .stimulator, .acquirer
            
            badEpoch = self.epochGroup.insertEpoch(self.epoch.getStartTime(),...
                self.epoch.getStartTime().plusSeconds(self.xsg.header.acquirer.acquirer.traceLength*2),...
                self.epoch.getProtocolID(),...
                self.epoch.getProtocolParameters());
            
            self.checkThrows(badEpoch,...
                'ovation:importer:xsg:traceLengthMismatch');
      
        end
        
        function testShouldRaiseExceptionIfExperimentMismatch(self)
            % If experiment, set, and acquisition number properties are
            % present on the Epoch, they must match the values in
            % xsg.header.xsg.xsg]
            
            self.epoch.addProperty('xsg_experiment_number',...
                int64(str2double(self.xsg.header.xsg.xsg.experimentNumber)) + 1);
            
            self.checkThrows(self.epoch,...
                'ovation:importer:xsg:experimentNumberMismatch');
            
        end
        
        function testShouldRaiseExceptionIfSetIDMismatch(self)
            % If experiment, set, and acquisition number properties are
            % present on the Epoch, they must match the values in
            % xsg.header.xsg.xsg]
            
            self.epoch.addProperty('xsg_set_number',...
                [self.xsg.header.xsg.xsg.setID 'foo']);
            
            self.checkThrows(self.epoch,...
                'ovation:importer:xsg:traceLengthMismatch');
            
        end
        
        function testShouldRaiseExceptionIfAcquisitionNumberMismatch(self)
            % If experiment, set, and acquisition number properties are
            % present on the Epoch, they must match the values in
            % xsg.header.xsg.xsg]
            
            self.epoch.addProperty('xsg_sequence_number',...
                int64(str2double(self.xsg.header.xsg.xsg.acquisitionNumber)) + 1);
            
            self.checkThrows(self.epoch,...
                'ovation:importer:xsg:traceLengthMismatch');
            
        end
        
        function checkThrows(self, epoch, exceptionID)
            caughtException = false;
            try
                appendXSG(epoch,...
                    self.xsg,...
                    self.epoch.getStartTime().getZone().getID());
            catch ex
                if (strcmp(ex.identifier,exceptionID))
                    caughtException = true;
                else
                    rethrow(ex);
                end
            end
            
            assert(caughtException);
        end
            
        
        %% Protocol
        
        % loopGui params
        
        %% Stimulator
        function testShouldSetEphusDeviceChannelForStimulatorStimuli(self)
            %assert(false);
        end
        
        function testShouldCreateStimulusForEachStimulatorChannel(self)
            %Pulse as stimulus parameters
            %assert(false)
        end
        
        
        %% Acquirer
        function testShouldSetEphusDeviceChannelForAcquirerResposnes(self)
            
        end
        
        function testShouldCreateResponseForEachAcquirerChannel(self)
            
        end
        
        
        
        %% EPHYS
        
        function testShouldSupportOneAmplifier(~)
            % We support one amplifer. Two-amp support is not been tested
            assert(true);
        end
        
        function testShouldCreateStimulusForEphysIfSpecified(self)
            
        end
        
        function testShouldCreateResponseForEphysIfSpecified(self)
            
        end
        
        
        function testShouldSetAmplifierDeviceForEphysResponses(self)
            
        end
        
        function testShouldSetAmplifierDeviceForEphysStimuli(self)
            
        end
        
        function testShouldIncludeAmplifierConfigurationIfSpecified(self)
            % xsg.header.ephys.ephys.amplifierSettings contains amplifier
            % settings. The user must tell appendXSG whether to use the
            % amplifier settings (by specifying the appropriate channel
            % names).
            
        end
        
    end
end
