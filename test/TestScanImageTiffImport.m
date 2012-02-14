classdef TestScanImageTiffImport < TestBase
    
    properties
        tifFile
        tif_struct
        expModificationDate
        epoch
        config
    end
    
    methods
        function self = TestScanImageTiffImport(name)
            self = self@TestBase(name);
            
            import ovation.*;
            addpath /opt/ovation;
            
            self.tifFile = fullfile(pwd(), 'fixtures/EC20091021_GC3_0_27B03_A1_L_022.tif');
            
            self.tif_struct = scim_openTif(self.tifFile, 'header');

            self.expModificationDate = org.joda.time.DateTime(java.io.File(self.tifFile).lastModified());
            
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
            
            if isempty(experiment.getEpochGroups)
                epochGroup = experiment.insertEpochGroup(source, 'test epoch group', self.expModificationDate, self.expModificationDate);
            else
                epochGroups = experiment.getEpochGroups();
                epochGroup = epochGroups(1);
            end
            
            self.epoch = epochGroup.insertEpoch(self.expModificationDate,...
                self.expModificationDate,...
                'org.hhmi.janelia.jayaraman.testImportMapping',...
                []);
            
            assert(~isempty(self.epoch));
            
            self.config.PMT(1).filter = 'red';
            self.config.PMT(1).manufacturer = 'PMT Co.';
            self.config.PMT(2).filter = 'green';
            self.config.PMT(2).manufacturer = 'PMT Co.';
            self.config.XFrameDistance = 10;
            self.config.XFrameDistanceUnits = 'µm';
            self.config.YFrameDistance = 10;
            self.config.YFrameDistanceUnits = 'nm';

            appendScanImageTiff(self.epoch,...
                self.tifFile,...
                self.config,...
                'America/New_York');

        end
        
        %%Tests - should test that the following fields are imported into
        %ovation:
        %   header.configName
        %   header.acq.externallyTriggered
        %   header.acq.averaging
        %   header.acq.numberOfFrames
        %   header.acq.linesPerFrame
        %   header.acq.pixelsPerLine
        %   header.acq.frameRate
        %   header.acq.linescan
        %   header.acq.zoomFactor
        %   header.acq.scanAmplitudeX
        %   header.acq.scanAmplitudeY
        %   header.acq.scanRotation
        %   header.acq.scaleXShift
        %   header.acq.scaleYShift
        %   header.acq.xstep
        %   header.acq.ystep
        %   header.acq.msPerLine
        %   header.acq.pmtOffsetChannel(per channel)
        %   header.acq.pmtOffsetStdDevChannel(per channel)
        %   header.acq.fastScanningX
        %   header.acq.fastScanningY
        %   header.sofware.version
        %   header.sofware.minorRev
        %   header.sofware.beta
        %   header.init.scanOffsetX
        %   header.motor.absXPosition
        %   header.motor.absYPosition
        %   header.motor.absZPosition
        %   header.motor.relXPosition
        %   header.motor.relYPosition
        %   header.motor.relYPosition
        %   header.motor.relZPosition
        %   header.motor.distance
        
        
        function testDeviceParameters(self)
            r = self.epoch.getResponse('pmt1');
            device_params = ovation.map2struct(r.getDeviceParameters());

            param_list = {'configName',...
                          'externallyTriggered',...
                          'numberOfFrames',...
                          'linesPerFrame',...
                          'pixelsPerLine',...
                          'frameRate',...
                          'linescan',...
                          'zoomFactor',...
                          'scanAmplitudeX',...
                          'scanAmplitudeY',...
                          'scanRotation',...
                          'scaleXShift',...
                          'scaleYShift',...
                          'xstep',...
                          'ystep',...
                          'msPerLine',... % actual?
                          'pmtOffsetChannel1',...
                          'pmtOffsetStdDevChannel1',...
                          'fastScanningX',...
                          'fastScanningY',...
                          'software_version',...
                          'software_version_minor_revision',...
                          'software_version_beta',...
                          'scanOffsetX',...
                          'motor_absXPosition',...
                          'motor_absYPosition',...
                          'motor_absZPosition',...
                          'motor_relXPosition',...
                          'motor_relYPosition',...
                          'motor_relZPosition',...
                          'motor_distance',...
                          };
                      
            for i=1:length(param_list)
                name = param_list(i);
                name = name{1};
                device_params.(name); % will throw an exception if param in list doesn't exist
            end
        end
        
        function testSamplingRatesAndUnits(self)
            responseNames = self.epoch.getResponseNames();
            
            for i=1:length(responseNames)
                r = self.epoch.getResponse(responseNames(i));
                                
                assert(strcmp(r.getUnits(), 'V'));
                
                XRate = self.config.XFrameDistance / self.tif_struct.acq.pixelsPerLine;
                XUnit = java.lang.String([self.config.XFrameDistanceUnits '/pixel']);
                XLabel = java.lang.String('X');
                ZRate = self.tif_struct.acq.zStepSize;
                ZUnit = java.lang.String('µm/step');
                ZLabel = java.lang.String('Z');
                if r.getDeviceParameters().get('linescan');
                    YRate = self.tif_struct.acq.msPerLine + self.tif_struct.acq.scanDelay;
                    YUnit = java.lang.String('ms/line');
                    YLabel = java.lang.String('Y');
                else
                    YRate = self.config.YFrameDistance / self.tif_struct.acq.linesPerFrame;
                    YUnit = java.lang.String([self.config.YFrameDistanceUnits '/pixel']);
                    YLabel = java.lang.String('Y');
                end
                
                assert(isequal(r.getSamplingUnits(), [XUnit, YUnit, ZUnit]));
                assertElementsAlmostEqual(r.getSamplingRates(), [XRate, YRate, ZRate]');
                assert(isequal(r.getDimensionLabels(), [XLabel, YLabel, ZLabel]));
            end
        end
        
        function testAllResponsesHaveFilterColor(self)
            responseNames = self.epoch.getResponseNames();
            for i=1:length(responseNames)
                r = self.epoch.getResponse(responseNames(i));
                
                assert(~isempty(r.getProperty('filterColor')));
                
            end
        end
        
        function testResponseShape(self)
            responseNames = self.epoch.getResponseNames();
            for i=1:length(responseNames)
                r = self.epoch.getResponse(responseNames(i));
                
                assert(isequal(r.getShape()', [self.tif_struct.acq.pixelsPerLine, self.tif_struct.acq.linesPerFrame, self.tif_struct.acq.numberOfZSlices]));
            end
        end
        
        function testEpochTimeAndScanImageTimeOverlap(self)
            failForBogusTimes = true;
            
            try
                appendScanImageTiff(self.epoch, self.tifFile, 'America/New_York', failForBogusTimes); 

            catch error
                caught = error;
            end
            
            if isempty(caught)
                throw MSException
            end
        end
        
    end
end
