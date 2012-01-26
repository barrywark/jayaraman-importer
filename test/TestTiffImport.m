classdef TestTiffImport < TestBase

    properties
        tifFile
        tif_struct
        expModificationDate
    end
    
    methods
        function self = TestTiffImport(name)
            self = self@TestBase(name);
            
            import ovation.*;
            addpath /opt/ovation;
            addpath ../../; % folder for the scim_openTif function to read the tif 
            
            self.tifFile = [pwd() '/fixtures/EC20091021_GC3_0_27B03_A1_L_022.tif'];
            %self.tif_struct = scim_openTif(self.tifFile);
                        
            self.expModificationDate = org.joda.time.DateTime(java.io.File(self.tifFile).lastModified());
            %self.drNameSuffix = [num2str(expModificationDate.getYear()) '-' ...
            %    num2str(expModificationDate.getMonthOfYear()) '-'...
            %    num2str(expModificationDate.getDayOfMonth())];
            
        end
        
        function setUp(self)
            setUp@TestBase(self);

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
            if isempty(epochGroup.getEpochs())
                epoch = epochGroup.insertEpoch(self.expModificationDate,...
                    self.expModificationDate,...
                    'org.hhmi.janelia.jayaraman.testImportMapping',...
                    []);
            else
                epochs = epochGroup.getEpochs();
                epoch = epochs(1);
            end
            self.tifFile
            AppendTifData(epoch, self.tifFile);
        end
        
        %%Tests
        function testEpochShouldExist(self)
            self.assert(self.epoch ~= []);
        end
        
     end
end