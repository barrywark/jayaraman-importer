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
            
            traceLength = self.xsg.header.acquirer.acquirer.traceLength;
            self.epoch = self.epochGroup.insertEpoch(startTime,...
                startTime.plusMillis(traceLength * 1000),...
                'jayarama-importer.test.TestAppendXSG',...
                struct2map(struct()));
        end
        
        function testShouldRequireFileFormatVersion(self)
           xsgMod = self.xsg;
           xsgMod.header.xsg.xsg.xsgFileFormatVersion = '1.3.0';
           
           self.checkThrows(self.epoch,...
               'ovation:xsg_importer:fileVersion',...
               xsgMod);
        end
        
        function testShouldRaiseExceptionIfTriggerTimeMismatch(self)
            % Trigger time in .ephys, .stimulator, .acquirer
            
            badStartTime = self.epoch.getStartTime().minusHours(1);
            badEpoch = self.epochGroup.insertEpoch(badStartTime,...
                badStartTime.plusMillis(self.xsg.header.acquirer.acquirer.traceLength*1000),...
                self.epoch.getProtocolID(),...
                self.epoch.getProtocolParameters());
            
            self.checkThrows(badEpoch, ...
                'ovation:xsg_importer:triggerTimeMismatch');
        end
        
        function testShouldRaiseExceptionIfTraceLengthMismatch(self)
            % traceLength time in .ephys, .stimulator, .acquirer
            
            badEpoch = self.epochGroup.insertEpoch(self.epoch.getStartTime(),...
                self.epoch.getStartTime().plusSeconds(self.xsg.header.acquirer.acquirer.traceLength*2),...
                self.epoch.getProtocolID(),...
                self.epoch.getProtocolParameters());
            
            self.checkThrows(badEpoch,...
                'ovation:xsg_importer:traceLengthMismatch');
      
        end
        
        function testShouldRaiseExceptionIfExperimentMismatch(self)
            % If experiment, set, and acquisition number properties are
            % present on the Epoch, they must match the values in
            % xsg.header.xsg.xsg]
            
            self.epoch.addProperty('xsg_experiment_number',...
                int64(str2double(self.xsg.header.xsg.xsg.experimentNumber)) + 1);
            
            self.checkThrows(self.epoch,...
                'ovation:xsg_importer:experimentNumberMismatch');
            
        end
        
        function testShouldRaiseExceptionIfSetIDMismatch(self)
            % If experiment, set, and acquisition number properties are
            % present on the Epoch, they must match the values in
            % xsg.header.xsg.xsg]
            
            self.epoch.addProperty('xsg_setID',...
                [self.xsg.header.xsg.xsg.setID 'foo']);
            
            self.checkThrows(self.epoch,...
                'ovation:xsg_importer:setIDMismatch');
            
        end
        
        function testShouldRaiseExceptionIfAcquisitionNumberMismatch(self)
            % If experiment, set, and acquisition number properties are
            % present on the Epoch, they must match the values in
            % xsg.header.xsg.xsg]
            
            self.epoch.addProperty('xsg_acquisition_number',...
                int64(str2double(self.xsg.header.xsg.xsg.acquisitionNumber)) + 1);
            
            self.checkThrows(self.epoch,...
                'ovation:xsg_importer:acquisitionNumberMismatch');
            
        end
        
        function checkThrows(self, epoch, exceptionID, xsg)
            caughtException = false;
            try
                if(nargin < 4)
                    xsg = self.xsg;
                end
                
                appendXSG(epoch,...
                    xsg,...
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
            
        
        %% Protocol parameters
        
        function testShouldAddLoopGUIParamsToProtocolParameters(self)
            appendXSG(self.epoch,...
                self.xsg,...
                self.epoch.getStartTime().getZone().getID());
            
            paramNames = fieldnames(self.xsg.header.loopGui.loopGui);
            for i = 1:length(paramNames)
                paramName = paramNames{i};
                assert(self.xsg.header.loopGui.loopGui.(paramName) == ...
                    self.epoch.getProtocolParameter(paramName));
            end
        end
        
        %% Stimulator
        function testShouldSetEphusDeviceChannelForStimulatorStimuli(self)
            %assert(false);
        end
        
        function testShouldCreateStimulusForEachStimulatorChannel(self)
            %Pulse as stimulus parameters
            
            import ovation.*
            
            appendXSG(self.epoch,...
                self.xsg,...
                self.epoch.getStartTime().getZone().getID());
            
            stim = self.xsg.header.stimulator.stimulator;
            for i = 1:length(stim.channels)
                channelName = stim.channels(i).channelName;
                stimulus = self.epoch.getStimulus(channelName);
                
                % Check device parameters
                devParams = map2struct(stimulus.getDeviceParameters());
                if(~isempty(stim.channels(i).boardID))
                    assert(devParams.boardID == stim.channels(i).boardID);
                end
                if(~isempty(stim.channels(i).channelID))
                    assert(devParams.channelID == stim.channels(i).channelID);
                end
                if(~isempty(stim.channels(i).portID))
                    assert(devParams.portID == stim.channels(i).portID);
                end
                if(~isempty(stim.channels(i).lineID))
                    assert(devParams.lineID == stim.channels(i).lineID);
                end
                
                assert(devParams.externalTrigger == stim.externalTrigger);
                assert(devParams.selfTrigger == stim.selfTrigger);
                assert(devParams.stimOn == stim.stimOnArray(i));
                assert(devParams.extraGain == stim.extraGainArray(i));
                
                % Check stimulus parameters
                stimParams = stim.pulseParameters{i};
                stimParams.pulseSet = stim.pulseSetNameArray{i};
                stimParams.pulseName = stim.pulseNameArray{i};
                
                stimParamNames = fieldnames(stimParams);
                
                % Make sure all the parameters (at least by key) were
                % transfered. This is a shortcut to testing all the values.
                % Since struct2map is tested independently, I'm confident
                % in the *values* that are converted, as long as they are
                % present here.
                for k = 1:length(stimParamNames)
                    paramName = stimParamNames{k};
                    param = stimulus.getStimulusParameter(paramName);
                    assert(~isempty(param));
                end
            end
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
