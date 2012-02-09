classdef TestArenaImport < TestBase
    
    properties
        
    end
    
    methods
        
        function self = TestArenaImport(name)
            self = self@TestBase(name);
        end
        
        function setUp(self)
            setUp@TestBase(self);
            import ovation.*;
            
            projects = self.context.getProjects();
            project = projects(1);
            experiments = project.getExperiments();
            experiment = experiments(1);
            sources = self.context.getSources();
            source = sources(1);
            
            self.epochGroup = experiment.insertEpochGroup(source,...
                'test epoch group',...
                datetime());
        end
        
        function [trial] = trialStruct(self, protocolID)
            
            % This suite is bound to the XSG fixture
            trial.epochStartTime = ovation.datetime(2011,10,18,12,31,27, 0, 'America/New_York');
            trial.epochEndTime = trial.epochStartTime.plusMillis(42030);
            
            trial.protocolID = protocolID;
            
            params.param1 = 1;
            params.param2 = 'abc';
            trial.protocolParameters = params;
            
            trial.arena.controllerMode = 1;
            trial.arena.firmwareVersion = 2;
            trial.arena.controllerParameters.param1 = 'foo';
            trial.arena.controllerParameters.param2 = 10;
            trial.arena.arenaConfigurationName = 'test-configuration';
            trial.arena.controllerParameters.foo = 'bar';
            
            trial.arena.frameNumber = [1,2,3];
            
            trial.arena.patternParameters.param1 = 'foo';
            trial.arena.patternParameters.param2 = 10;
            
            trial.arena.patternFile = 'TestArenaImportPattern.mat';
            pattern = struct(); %#ok<NASGU>
            save(trial.arena.patternFile, 'pattern');
            
            trial.arena.patternGenerationFunction = 'TestArenaImport.m';
            trial.arena.arenaConfigurationFile = 'TestArenaImportArenaConfig.mat';
            config = struct(); %#ok<NASGU>
            save(trial.arena.arenaConfigurationFile, 'config');
            
        end
        
        
        function testImportEpochProtocolParameters(self)
            
            protocolID = 'testImportEpochProtocolParameters';
            
            trial = self.trialStruct(protocolID);
            params = trial.protocolParameters;
            
            [epoch,~] = insertFlyArenaEpoch(self.epochGroup,...
                trial);
            
            assert(~isempty(epoch));
            assert(epoch.getEpochGroup().getUuid().equals(self.epochGroup.getUuid()));
            
            assert(strcmp(char(epoch.getProtocolID()), protocolID));
            
            actual = ovation.map2struct(epoch.getProtocolParameters());
            
            assert(params.param1 == actual.param1);
            assert(strcmp(params.param2, actual.param2));
            
            assert(trial.epochStartTime.equals(epoch.getStartTime()));
            assert(trial.epochEndTime.equals(epoch.getEndTime()));
        end
        
        function testStimulusInsertion(self)
            protocolID = 'testStimulusDeviceNameAndParameters';
            
            trial = self.trialStruct(protocolID);
            
            [epoch,~] = insertFlyArenaEpoch(self.epochGroup,...
                trial);
            
            s = epoch.getStimulus('Fly Arena');
            
            assert(~isempty(s));
            [~,patternName,~] = fileparts(trial.arena.patternGenerationFunction);
            assert(strcmp(['org.hhmi.janelia.fly-arena.' patternName],...
                char(s.getPluginID())));
            
            
            params = trial.arena.patternParameters;
            actual = ovation.map2struct(s.getStimulusParameters());
            assert(strcmp(params.param1, actual.param1));
            assert(params.param2 == actual.param2);
            
            assert(isequal(trial.arena.frameNumber, actual.frameNumber.getFloatingPointData()'));
            
            assert(s.getUnits().equals('TODO'), 'TODO: stimulus units');
        end
        
        function testStimulusInsertionWithoutPatternGenerationFunction(self)
            protocolID = 'testStimulusInsertionWithoutPatternGenerationFunction';
            
            trial = self.trialStruct(protocolID);
            
            trial.arena = rmfield(trial.arena, 'patternGenerationFunction');
            
            [epoch,~] = insertFlyArenaEpoch(self.epochGroup,...
                trial);
            
            s = epoch.getStimulus('Fly Arena');
            
            assert(~isempty(s));
            [~,patternName,~] = fileparts(trial.arena.patternFile);
            assert(strcmp(['org.hhmi.janelia.fly-arena.' patternName],...
                char(s.getPluginID())));
        end
        
        function testStimulusDeviceNameAndParameters(self)
            protocolID = 'testStimulusDeviceNameAndParameters';
            
            trial = self.trialStruct(protocolID);
            
            [epoch,~] = insertFlyArenaEpoch(self.epochGroup,...
                trial);
            
            s = epoch.getStimulus('Fly Arena');
            dev = s.getExternalDevice();
            
            assert(~isempty(dev));
            
            assert(strcmp('Fly Arena', char(dev.getName())));
            
            
            devParams = ovation.map2struct(s.getDeviceParameters());
            assert(trial.arena.controllerMode == devParams.controllerMode);
            assert(trial.arena.firmwareVersion == devParams.firmwareVersion);
            assert(strcmp(trial.arena.arenaConfigurationName, devParams.arenaConfiguration));
            assert(strcmp(trial.arena.controllerParameters.foo, char(devParams.controllerParameters__foo)));
            
            assert(strcmp('TODO', char(dev.getManufacturer())), 'TODO: device manufacturer');
        end
        
        function testAppendsStimulusResources(self)
            protocolID = 'testAppendsStimulusResources';
            
            trial = self.trialStruct(protocolID);
            
            [epoch,~] = insertFlyArenaEpoch(self.epochGroup,...
                trial);
            
            resourceNames = epoch.getStimulus('Fly Arena').getResourceNames();
            
            self.assertResource(resourceNames,...
                trial.arena.patternFile);
            
            self.assertResource(resourceNames,...
                trial.arena.patternGenerationFunction);
            
            self.assertResource(resourceNames,...
                trial.arena.arenaConfigurationFile);
            
        end
        
        function testShouldCreateXSGChannelLinks(self)
            protocolID = 'testShouldCreateXSGChannelLinks';
            
            trial = self.trialStruct(protocolID);
            
            trial.arena.xsgXSequenceChannel = 'XSignalArena';
            trial.arena.xsgYSequenceChannel = 'YSignalArena';
            trial.xsg.xsgFilePath = 'fixtures/EC20111018/Imaging/AA0001AAAA0001.xsg';
            
            [epoch,importXSG] = insertFlyArenaEpoch(self.epochGroup,...
                trial);
            
            assert(importXSG, 'Should import XSG file');
            
            stim = epoch.getStimulus('Fly Arena');
            
            xsgX = stim.getMyProperty('xsgXSequenceResponse');
            assert(~isempty(xsgX));
            
            xsgY = stim.getMyProperty('xsgYSequenceResponse');
            assert(~isempty(xsgY));
        end
        
        function testShouldSkipXSGChannelLinksIfMissingFromTrialStruct(self)
            protocolID = 'testShouldSkipXSGChannelLinksIfMissingFromTrialStruct';
            
            trial = self.trialStruct(protocolID);
            
            [epoch,~] = insertFlyArenaEpoch(self.epochGroup,...
                trial);
            
            stim = epoch.getStimulus('Fly Arena');
            
            xsgX = stim.getMyProperty('xsgXSequenceResponse');
            assert(isempty(xsgX));
            
            xsgY = stim.getMyProperty('xsgYSequenceResponse');
            assert(isempty(xsgY));
        end
        
        function testShouldThrowErrorIfFraneNumberAndXSGSequenceAreMissing(self)
            protocolID = 'testShouldThrowErrorIfFraneNumberAndXSGSequenceAreMissing';
            
            trial = self.trialStruct(protocolID);
            trial.arena = rmfield(trial.arena, 'frameNumber');
            
            caught = false;
            try
                [~,~] = insertFlyArenaEpoch(self.epochGroup,...
                    trial);
            catch MException
                assert(strcmp(MException.identifier, 'ovation:fly_arena_import:missingConfiguration'));
                caught = true;
            end
            
            assert(caught, 'Should throw error');
        end
        
        function testShouldImportDirectResponseData(self)
            import ovation.*;
            
            protocolID = 'testShouldImportDirectResponseData';
            
            trial = self.trialStruct(protocolID);
            
            trial.responses.channels(1).deviceName = 'dev1';
            trial.responses.channels(1).deviceManufacturer = 'dev1Manufacturer';
            trial.responses.channels(1).channelName = 'channelName1';
            trial.responses.channels(1).samplingRateHz = 1000;
            trial.responses.channels(1).data = rand(1,1000);
            trial.responses.channels(1).units = 'A';
            trial.responses.channels(1).deviceParameters.foo = 'bar';
            
            trial.responses.channels(2).deviceName = 'dev2';
            trial.responses.channels(2).deviceManufacturer = 'dev2Manufacturer';
            trial.responses.channels(2).channelName = 'channelName2';
            trial.responses.channels(2).samplingRateHz = 1000;
            trial.responses.channels(2).dataFileURL = 'file://TestArenaImportPattern.mat';
            trial.responses.channels(2).shape = [1,1000];
            trial.responses.channels(2).dataType = NumericDataType(NumericDataFormat.FloatingPointDataType,...
                8,...
                NumericByteOrder.ByteOrderLittleEndian);
            trial.responses.channels(2).units = 'V';
            trial.responses.channels(2).deviceParameters.foo = 'bar';
            
            
            [epoch,~] = insertFlyArenaEpoch(self.epochGroup,...
                trial);
            
            r1 = epoch.getResponse(trial.responses.channels(1).deviceName);
            assert(~isempty(r1));
            self.assertDirectResponse(r1, trial.responses.channels(1));
            
            r2 = epoch.getResponse(trial.responses.channels(2).deviceName);
            assert(~isempty(r2));
            self.assertDirectResponse(r2, trial.responses.channels(2));
        end
        
        function testShouldThrowErrorIfDirectResponseDataAndURLMissing(self)
            protocolID = 'testShouldImportDirectResponseData';
            
            trial = self.trialStruct(protocolID);
            
            trial.responses.channels(1).deviceName = 'dev1';
            trial.responses.channels(1).deviceManufacturer = 'dev1Manufacturer';
            trial.responses.channels(1).channelName = 'channelName1';
            trial.responses.channels(1).samplingRateHz = 1000;
            trial.responses.channels(1).units = 'A';
            
            
            caught = false;
            try
                [~,~] = insertFlyArenaEpoch(self.epochGroup,...
                    trial);
            catch MException
                assert(strcmp(MException.identifier, 'ovation:fly_arena_import:missingConfiguration'));
                caught = true;
            end
            
            assert(caught, 'Should throw exception');
        end
        
    end
    
    methods(Static)
        function assertResource(resourceNames, filePath)
            [~,expectedName,ext] = fileparts(filePath);
            
            names = cell(1,length(resourceNames));
            for i = 1:length(resourceNames)
                names{i} = char(resourceNames(i));
            end
            
            assert(any(strcmp(names, [expectedName ext])),...
                ['Expected: ' expectedName ext]);
        end
        
        function assertDirectResponse(r, trialResponseChannel)
            import ovation.*;
            
            assert(strcmp(trialResponseChannel.deviceName, ...
                char(r.getExternalDevice().getName())));
            assert(strcmp(trialResponseChannel.deviceManufacturer, ...
                char(r.getExternalDevice().getManufacturer())));
            
           
            if(isfield(trialResponseChannel, 'data') &&...
                    ~isempty(trialResponseChannel.data))
                actual = r.getData();
                expected = NumericData(trialResponseChannel.data);
                
                assert(isequal(actual.getShape(), expected.getShape()));
                assert(isequal(actual.getFloatingPointData(), expected.getFloatingPointData()));
            else
                assert(strcmp(trialResponseChannel.dataFileURL, char(r.getURL())));
                assert(isequal(trialResponseChannel.shape, r.getShape()'));
            end
            
            assert(strcmp(trialResponseChannel.units, char(r.getUnits())));
            srates = r.getSamplingRates();
            assert(trialResponseChannel.samplingRateHz == srates(1));
            srateUnits = r.getSamplingUnits();
            assert(strcmp('Hz', char(srateUnits(1))));
            
            labels = r.getDimensionLabels();
            assert(strcmp(trialResponseChannel.channelName, char(labels(1))));
            
            assert(r.getUTI() == Response.NUMERIC_DATA_UTI);
            
            params = ovation.map2struct(r.getDeviceParameters());
            assert(strcmp(params.foo, trialResponseChannel.deviceParameters.foo));
        end
    end
    
end