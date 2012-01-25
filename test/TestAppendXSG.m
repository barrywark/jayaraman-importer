% Copyright (c) 2012 Physion Consulting, LLC

classdef TestAppendXSG < TestBase
    
    % Copyright (c) 2012 Physion Consulting, LLC
    
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
          
          triggerTime = xsg.header.acquirer.acquirer.triggerTime;
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
            
            badEpoch = self.epochGroup.insertEpoch(startTime.minusHours(1),...
                startTime.minusMinutes(30),...
                self.epoch.getProtocolID(),...
                self.epoch.getProtocolParameters());
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
