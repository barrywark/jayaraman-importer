classdef TestTreadmillImport < TestBase

    properties
        treadmillFile
        expModificationDate
        epoch
        yaml
        frameRate1
        frameRate2
        responseLength
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
            shutterSpeed1 = arrayfun(@(high, low) uint16(low) + high*(2^8), A, B);
            shutterSpeed2 = arrayfun(@(high, low) uint16(low) + high*(2^8), C, D);
            self.frameRate1 = median(shutterSpeed1);
            self.frameRate2 = median(shutterSpeed2);
            self.responseLength = length(shutterSpeed1);
            addpath .
            
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
        
        function testSamplingRatesAndUnitsOnXYResponses(self)
            responseNames = {'camera1_XY', 'camera2_XY'};
            shutterRates = [self.frameRate1, self.frameRate2];
            
            for i=1:length(responseNames)
                r = self.epoch.getResponse(responseNames(i));
                                
                samplingRates = [1, shutterRates(i)];
                samplingRateUnits = [java.lang.String('pixels'), java.lang.String('clock cycles')];
                dimensionLabels = [java.lang.String('Delta XY'), java.lang.String('Time')];
                units = 'pixels';
                shape = [self.responseLength, 2];
                                
                assert(isequal(r.getShape(), shape'));
                assert(strcmp(r.getUnits(), units));
                assert(self.arrayEquals(r.getSamplingUnits(), samplingRateUnits));
                assert(isequal(r.getSamplingRates(), samplingRates'));
                assert(self.arrayEquals(r.getDimensionLabels(), dimensionLabels));
            end
        end
        
        function testSamplingRatesAndUnitsOnOtherResponses(self)
            responseNames = {'camera1_SurfaceQuality', 'camera2_SurfaceQuality'};
            shutterRates = [self.frameRate1, self.frameRate2];
          
            for i=1:length(responseNames)
                r = self.epoch.getResponse(responseNames(i));
                                
                samplingRates = [shutterRates(i)];
                samplingRateUnits = java.lang.String('clock cycles');
                dimensionLabels = [java.lang.String('Surface Quality')];
                units = java.lang.String('a.u.');
                shape = [self.responseLength];
                
                assert(isequal(r.getShape(), shape));
                assert(strcmp(r.getUnits(), units));
                actualSRUnits = r.getSamplingUnits();
                actualDLabels = r.getDimensionLabels();
                assert(strcmp(actualSRUnits(1), samplingRateUnits));
                assert(isequal(r.getSamplingRates(), samplingRates'));
                assert(strcmp(actualDLabels(1), dimensionLabels));
            end
        end
        
        function testSamplingRatesAndUnitsOnShutterSpeedResponses(self)
            responseNames = {'camera1_ShutterSpeed', 'camera2_ShutterSpeed'};
            shutterRates = [self.frameRate1, self.frameRate2];
            
            for i=1:length(responseNames)
                r = self.epoch.getResponse(responseNames(i));
                                
                samplingRates = [shutterRates(i)];
                samplingRateUnits = 'clock cycles';
                dimensionLabels = 'Shutter Speed';
                units = 'clock cycles';
                shape = [self.responseLength];
                
                assert(isequal(r.getShape(), shape));
                assert(strcmp(r.getUnits(), units));
                actualSRUnits = r.getSamplingUnits();
                actualDLabels = r.getDimensionLabels();
                assert(strcmp(actualSRUnits(1), samplingRateUnits));
                assert(isequal(r.getSamplingRates(), samplingRates'));
                assert(strcmp(actualDLabels(1), dimensionLabels));
            end
        end
        
        function equals = arrayEquals(self, array1, array2)
            if (length(array1) ~=length(array2))
                equals = false;
                return;
            end
            for i=1:length(array1)
                if ~isequal(array1(i), array2(i))
                    equals = false;
                    return;
                end
            end
            equals = true;
        end
                
     end
end
