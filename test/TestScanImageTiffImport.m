classdef TestScanImageTiffImport < TestBase

    properties
        tifFile
        tif_struct
        expModificationDate
        epoch
    end
    
    methods
        function self = TestScanImageTiffImport(name)
            self = self@TestBase(name);
            
            import ovation.*;
            addpath /opt/ovation;
            addpath ../../; % folder for the scim_openTif function to read the tif 
            
            self.tifFile = [pwd() '/fixtures/EC20091021_GC3_0_27B03_A1_L_022.tif'];
            
            addpath .
            addpath ..
            self.tif_struct = scim_openTif(self.tifFile, 'header');
                        
            self.expModificationDate = org.joda.time.DateTime(java.io.File(self.tifFile).lastModified());
            %self.drNameSuffix = [num2str(expModificationDate.getYear()) '-' ...
            %    num2str(expModificationDate.getMonthOfYear()) '-'...
            %    num2str(expModificationDate.getDayOfMonth())];
            
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
           
            %if isempty(experiment.getEpochGroups)
                epochGroup = experiment.insertEpochGroup(source, 'test epoch group', self.expModificationDate, self.expModificationDate);
            %else
            %    epochGroups = experiment.getEpochGroups();
            %    epochGroup = epochGroups(1);
            %end
            %if isempty(epochGroup.getEpochs())
                self.epoch = epochGroup.insertEpoch(self.expModificationDate,...
                    self.expModificationDate,...
                    'org.hhmi.janelia.jayaraman.testImportMapping',...
                    []);

            %else
            %    epochs = epochGroup.getEpochs();
            %    self.epoch = epochs(1);
            %end
            
            AppendTifData(self.epoch, self.tifFile, 'example.yaml', 'America/New_York');
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
         

        function testEpochShouldExist(self)
            import ovation.*;
            assert(self.epoch ~= []);
        end
        
        function testDeviceParameters(self)
            r = epoch.getResponse('pmt1');
            device_params = map2struct(r.getDeviceParameters());
            
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
                          'software.version',...
                          'software.minorRev',...
                          'software.beta',...
                          'scanOffsetX',...
                          'motor.absXPosition',...
                          'motor.absYPosition',...
                          'motor.absZPosition',...
                          'motor.relXPosition',...
                          'motor.relYPosition',...
                          'motor.relZPosition',...
                          'distance',...
                          };
            for i=1:length(param_list)
                name = param_list(i);
                name = name{1};
                device_params.(name); % will throw an exception if param in list doesn't exist
            end
        end
        
        function testSamplingRatesAndUnits(self)
            responseNames = self.epoch.getResponseNames();
            for i=1:length(resposeNames)
                r = self.Epoch.getResponse(responseNames(i));
                %TODO: change values for linescan
                assert(r.getUnits() == 'volts');
                XRate = yaml.PMT.XFrameDistance / self.tif_struct.acq.pixelsPerLine;
                YRate = yaml.PMT.YFrameDistance / self.tif_struct.acq.LinesPerFrame;
                ZRate = self.tif_struct.acq.zStepSize;
                assert(r.getSamplingRateUnits() == {'microns/pixel', 'microns/pixel', 'microns/step'});
                assert(r.getSamplingRates() == {XRate, YRate, ZRate});
                assert(r.getDimensionLabels() == {'X', 'Y', 'Z'});
            end
        end
        
        function testAllResponsesHaveFilterColor(self)
            responseNames = self.epoch.getResponseNames();
            for i=1:length(resposeNames)
                r = self.Epoch.getResponse(responseNames(i));
                
                assert(r.getProperty('filterColor'));
                
            end
        end
        
        function testResponseShape(self)
            responseNames = self.epoch.getResponseNames();
            for i=1:length(resposeNames)
                r = self.Epoch.getResponse(responseNames(i));
                
                assert(r.getShape() == [self.tif_struct.acq.pixelsPerLine, self.tif_struct.acq.linesPerFrame, self.tif_struct.acq.numberOfZSlices]);
            end
        end
        
        function testEpochTimeAndScanImageTimeOverlap(self)
            failForBogusTimes = true;
            try
                AppendTifData(self.epoch, self.tifFile, 'America/New_York', failForBogusTimes); 
            catch error
                caught = error;
            end
            
            if ~caught
                throw MSException
            end
        end
        
     end
end
