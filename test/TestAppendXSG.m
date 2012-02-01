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
            import ovation.*
            
            appendXSG(self.epoch,...
                self.xsg,...
                self.epoch.getStartTime().getZone().getID());
            
            stim = self.xsg.header.stimulator.stimulator;
            for i = 1:length(stim.channels)
                channelName = stim.channels(i).channelName;
                stimulus = self.epoch.getStimulus(channelName);
                
                assert(~isempty(stimulus));
            end
        end
        
        function testShouldCreateStimulusForEachStimulatorChannel(self)
            
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
                
                assert(strcmp(stimulus.getUnits(),'V'));
            end
        end
        
        
        %% Acquirer
        function testShouldSetEphusDeviceChannelParametersForAcquirerResposnes(self)
            import ovation.*
            
            appendXSG(self.epoch,...
                self.xsg,...
                self.epoch.getStartTime().getZone().getID());
            
            resp = self.xsg.header.acquirer.acquirer;
            for i = 1:length(resp.channels)
                channelName = resp.channels(i).channelName;
                response = self.epoch.getResponse(channelName);
                
                assert(~isempty(response));
                
                params = response.getDeviceParameters();
                
                assert(params.get('boardID') == resp.channels(i).boardID);
                assert(params.get('channelID') == resp.channels(i).channelID);
            end
        end
        
        function testShouldCreateResponseWithTraceForEachAcquirerChannel(self)
            import ovation.*
            
            appendXSG(self.epoch,...
                self.xsg,...
                self.epoch.getStartTime().getZone().getID());
            
            resp = self.xsg.header.acquirer.acquirer;
            for i = 1:length(resp.channels)
                channelName = resp.channels(i).channelName;
                response = self.epoch.getResponse(channelName);
                
                assert(~isempty(response));
                
                assert(all([resp.sampleRate] == response.getSamplingRates()));
                assert(strcmp('Hz', char(response.getSamplingUnits())));
                
                data = response.getFloatingPointData();
                
                traceName = ['trace_' num2str(i)];
                assert(all(data == self.xsg.data.acquirer.(traceName)));
                
                assert(Response.NUMERIC_DATA_UTI.equals(response.getUTI()));
            end
        end
        
        
        
        %% EPHYS
        
        %                       version: 0.3000
        %           startButton: 1
        %            sampleRate: 10000
        %           selfTrigger: 0
        %       externalTrigger: 1
        %           stimOnArray: 1
        %            acqOnArray: 1
        %     pulseSetNameArray: {'Current pulse'}
        %        pulseNameArray: {'50pA_2'}
        %                 epoch: 1
        %           traceLength: 42.4400
        %             pulseFile: ''
        %           pulseSetDir: 'C:\DATA\CONFIG\EPHUS\Eugenia\Pulse Sets'
        %           pulseNumber: '2'
        %     amplifierSettings: [1x1 struct]
        %       pulseParameters: {[1x1 struct]}
        %           triggerTime: [2009 12 10 18 59 0.9680]
        function testShouldCreateStimulusForEphys(self)
            import ovation.*
            
            appendXSG(self.epoch,...
                self.xsg,...
                self.epoch.getStartTime().getZone().getID());
            
            ephys = self.xsg.header.ephys.ephys;
            ampNames = fieldnames(ephys.amplifierSettings);
            
            for i = 1:length(ampNames)
                stim = self.epoch.getStimulus(ampNames{i});
                assert(~isempty(stim));
                
                assert(strcmp(char(stim.getUnits()),...
                    ephys.amplifierSettings.(ampNames{i}).output_units));
            end
        end
        
        function testShouldSetStimulusParametersForEphys(self)
            import ovation.*
            
            appendXSG(self.epoch,...
                self.xsg,...
                self.epoch.getStartTime().getZone().getID());
            
            ephys = self.xsg.header.ephys.ephys;
            ampNames = fieldnames(ephys.amplifierSettings);
            
            for i = 1:length(ampNames)
                stim = self.epoch.getStimulus(ampNames{i});
                assert(~isempty(stim));
                
                params = map2struct(stim.getStimulusParameters());
                
                assert(strcmp(ephys.pulseSetNameArray{i}, char(params.pulseSetName)));
                assert(strcmp(ephys.pulseNameArray{i}, char(params.pulseName)));
                
                assert(ephys.pulseNumber == params.pulseNumber);
                
                paramNames = fieldnames(ephys.pulseParameters{i});
                for j = 1:length(paramNames)
                    paramName = paramNames{j};
                    value = ephys.pulseParameters{i}.(paramName);
                    if(ischar(value))
                        assert(strcmp(value, params.(['pulseParameters__' paramName])));
                    elseif(numel(value) > 1)
                        assert(all(value == params.(['pulseParameters__' paramName]).getFloatingPointData()'));
                    else
                        assert(all(value == params.(['pulseParameters__' paramName])));
                    end
                end
            end
        end
        
        function testShouldSetDeviceParmaetersForEphysStimulus(self)
            import ovation.*
            
            appendXSG(self.epoch,...
                self.xsg,...
                self.epoch.getStartTime().getZone().getID());
            
            ephys = self.xsg.header.ephys.ephys;
            ampNames = fieldnames(ephys.amplifierSettings);
            
            for i = 1:length(ampNames)
                ampName = ampNames{i};
                
                stim = self.epoch.getStimulus(ampName);
                assert(~isempty(stim));
                
                params = map2struct(stim.getDeviceParameters());
                
                assert(params.externalTrigger == ephys.externalTrigger == 1);
                assert(params.selfTrigger == ephys.selfTrigger == 1);
                assert(params.stimOn == ephys.stimOnArray(i));
                assert(params.sampleRate == ephys.sampleRate);
                assert(strcmp(params.sampleRateUnits, 'Hz'));
                
                ampSettingsNames = fieldnames(ephys.amplifierSettings(i).(ampName));
                for j = 1:length(ampSettingsNames)
                    ampSettingName = ampSettingsNames{j};
                    value = ephys.amplifierSettings(i).(ampName).(ampSettingName);
                    
                    if(ischar(value))
                        assert(strcmp(value, params.([ampName '__' ampSettingName])));
                    elseif(numel(value) > 1)
                        assert(all(value == params.([ampName '__' ampSettingName]).getFloatingPointData()));
                    elseif(isstruct(value))
                        %skip
                    else
                        assert(all(value == params.([ampName '__' ampSettingName])));
                    end
                end
            end
        end
        
        function testShouldCreateResponseForEphys(self)
            import ovation.*
            
            appendXSG(self.epoch,...
                self.xsg,...
                self.epoch.getStartTime().getZone().getID());
            
            ephys = self.xsg.header.ephys.ephys;
            ampNames = fieldnames(ephys.amplifierSettings);
            
            for i = 1:length(ampNames)
                response = self.epoch.getResponse(ampNames{i});
                assert(~isempty(response));
                
                assert(all(self.xsg.data.ephys.(['trace_' num2str(i)]) == ...
                    response.getFloatingPointData()));
                
                srates = response.getSamplingRates();
                assert(srates(1) == ephys.sampleRate);
                assert(strcmp(response.getSamplingUnits(), 'Hz'));
                assert(strcmp(char(response.getUnits()),...
                    ephys.amplifierSettings.(ampNames{i}).input_units));
                
            end
        end
        
        
        function testShouldSetAmplifierDeviceForEphysResponses(self)
            import ovation.*
            
            appendXSG(self.epoch,...
                self.xsg,...
                self.epoch.getStartTime().getZone().getID());
            
            ephys = self.xsg.header.ephys.ephys;
            ampNames = fieldnames(ephys.amplifierSettings);
            
            for i = 1:length(ampNames)
                ampName = ampNames{i};
                
                response = self.epoch.getResponse(ampName);
                assert(~isempty(response));
                
                params = map2struct(response.getDeviceParameters());
                
                assert(params.externalTrigger == ephys.externalTrigger == 1);
                assert(params.selfTrigger == ephys.selfTrigger == 1);
                assert(params.stimOn == ephys.stimOnArray(i));
                assert(params.sampleRate == ephys.sampleRate);
                assert(strcmp(params.sampleRateUnits, 'Hz'));
                
                ampSettingsNames = fieldnames(ephys.amplifierSettings(i).(ampName));
                for j = 1:length(ampSettingsNames)
                    ampSettingName = ampSettingsNames{j};
                    value = ephys.amplifierSettings(i).(ampName).(ampSettingName);
                    
                    if(ischar(value))
                        assert(strcmp(value, params.([ampName '__' ampSettingName])));
                    elseif(numel(value) > 1)
                        assert(all(value == params.([ampName '__' ampSettingName]).getFloatingPointData()'));
                    elseif(isstruct(value))
                        %pass
                    else
                        assert(all(value == params.([ampName '__' ampSettingName])));
                    end
                end
            end
        end
        
        
    end
end
