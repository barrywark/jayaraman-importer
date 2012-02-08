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
           
           trial.epochStartTime = ovation.datetime();
           trial.epochEndTime = trial.epochStartTime.plusMillis(10003);
           
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
           pattern = struct();
           save(trial.arena.patternFile, 'pattern');
           
           trial.arena.patternGenerationFunction = 'TestArenaImport.m';
           
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
            
            
        end
        
        
        %TODO: resources
        %TODO: xsg channel links
        %TODO: responses
    end
        
end