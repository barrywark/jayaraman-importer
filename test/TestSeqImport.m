classdef TestSeqImport < TestBase

    properties
        seqFile
        seq_struct
        expModificationDate
        epoch
        yaml
        fid
    end
    
    methods
        function self = TestSeqImport(name)
            self = self@TestBase(name);
            
            import ovation.*;
            addpath /opt/ovation;
            
            self.seqFile = '~/Downloads/092311cal7.seq';%%[pwd() '/fixtures/092311cal7.seq'];
            
            self.yaml = ReadYaml([pwd() '/../example.yaml']);            
            self.expModificationDate = org.joda.time.DateTime(java.io.File(self.seqFile).lastModified());
            [self.seq_struct, self.fid] = read_seq_header(self.seqFile);
            
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
            
            appendSeq(self.epoch, self.seqFile, self.yaml);
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
        
        %function testDeviceParameters(self)
        %    responseNames = self.epoch.getResponseNames();
        %    for j=1:length(responseNames)
        %        r = self.epoch.getResponse(responseNames(j));
        %        device_params = ovation.map2struct(r.getDeviceParameters());

%            param_list = {};
%            for i=1:length(param_list)
%                name = param_list(i);
%                name = name{1};
%                device_params.(name); % will throw an exception if param in list doesn't exist
%            end
%            end
%        end
        
        function testSamplingRatesAndUnits(self)
            responseNames = self.epoch.getResponseNames();
            for i=1:length(responseNames)
                r = self.epoch.getResponse(responseNames(i));
                                
                samplingRates = [self.seq_struct.FrameRate, self.seq_struct.Width, self.seq_struct.Height];
                samplingRateUnits = [java.lang.String('Hz'), java.lang.String('pixels'), java.lang.String('pixels')];
                dimensionLabels = [java.lang.String('Width'), java.lang.String('Height')];
                assert(strcmp(r.getUnits(), 'intensity'));
                
                assert(isequal(r.getSamplingUnits(), samplingRateUnits));
                assertElementsAlmostEqual(r.getSamplingRates(), samplingRates');
                assert(isequal(r.getDimensionLabels(), dimensionLabels));
            end
        end
        
        function testResponseShape(self)
            responseNames = self.epoch.getResponseNames();
            for i=1:length(responseNames)
                r = self.epoch.getResponse(responseNames(i));
                
                shape = [self.seq_struct.Height, self.seq_struct.Width];
                assert(isequal(r.getShape(), shape));
            end
        end
        
     end
end
