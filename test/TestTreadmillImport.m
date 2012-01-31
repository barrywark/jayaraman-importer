classdef TestTreadmillImport < TestBase

    properties
        treadmillFile
        expModificationDate
        epoch
        yaml
        shutterSpeed0
        shutterSpeed1
    end
    
    methods
        function self = TestTreadmillImport(name)
            self = self@TestBase(name);
            
            import ovation.*;
            addpath /opt/ovation;
            
            self.treadmillFile = [pwd() '/fixtures/092311tr7.txt'];
            
            self.yaml = ReadYaml([pwd() '/../example.yaml']);            
            self.expModificationDate = org.joda.time.DateTime(java.io.File(self.treadmillFile).lastModified());
            
            [~,~,~,~,~,~,~,~,A,B,C,D] = textread(self.treadmillFile);
            self.shutterSpeed0 = arrayfun(@(high, low) uint16(low) + high*(2^8), A, B);
            self.shutterSpeed1 = arrayfun(@(high, low) uint16(low) + high*(2^8), C, D);
            
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
           
                epochGroup = experiment.insertEpochGroup(source, 'test epoch group', self.expModificationDate, self.expModificationDate);
           
                self.epoch = epochGroup.insertEpoch(self.expModificationDate,...
                    self.expModificationDate,...
                    'org.hhmi.janelia.jayaraman.testImportMapping',...
                    []);

                       
            appendTreadmill(self.epoch, self.treadmillFile, 'example.yaml');
        end
        
      
        function testEpochShouldExist(self)
            import ovation.*;
            assert(self.epoch ~= []);
        end
        
        function testDeviceParameters(self)
            responseNames = self.epoch.getResponseNames();
            param_list = {'zero_centered'};
            for j=1:length(responseNames)
                r = self.epoch.getResponse(responseNames(j));
                device_params = ovation.map2struct(r.getDeviceParameters());
                
                for i=1:length(param_list)
                    name = param_list(i);
                    name = name{1};
                    device_params.(name); % will throw an exception if param in list doesn't exist
                end
            end
        end
        
        function testSamplingRatesAndUnits(self)
            responseNames = {'camera1', 'camera2'};
            shutterRates = [uint16(median(self.shutterSpeed0)), uint16(median(self.shutterSpeed1))];
            disp(shutterRates);
            for i=1:length(responseNames)
                r = self.epoch.getResponse(responseNames(i));
                                
                samplingRates = [1, shutterRates(i)];
                samplingRateUnits = [java.lang.String('N/A'), java.lang.String('clock cycles/frame')];
                dimensionLabels = [java.lang.String('delta-XY'), java.lang.String('time')];
                assert(strcmp(r.getUnits(), 'pixels'));
                
                assert(isequal(r.getSamplingUnits(), samplingRateUnits));
                assert(isequal(r.getSamplingRates(), samplingRates'));
                assert(isequal(r.getDimensionLabels(), dimensionLabels));
            end
        end
        
        function testResponseShape(self)
            responseNames = {'camera1', 'camera2'};
            for i=1:length(responseNames)
                r = self.epoch.getResponse(responseNames(i));
                
                shape = [length(self.shutterSpeed0), 2];
                assert(isequal(r.getShape(), shape));
            end
        end
        
     end
end
