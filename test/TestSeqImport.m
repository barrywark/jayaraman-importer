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
            
            self.seqFile = 'fixtures/092311cal7.seq';
            
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
            
            assert(~isempty(self.epoch));
            
            appendSeq(self.epoch, self.seqFile, self.yaml);
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
                                
                samplingRates = [self.seq_struct.FrameRate, 1, 1];
                samplingRateUnits = [java.lang.String('Hz'), java.lang.String('pixels'), java.lang.String('pixels')];
                dimensionLabels = [java.lang.String('Frame Number'), java.lang.String('Width'), java.lang.String('Height')];
                assert(strcmp(r.getUnits(), 'a.u.'));
                
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
                assert(isequal(r.getShape()', shape));
            end
        end
        
     end
end
