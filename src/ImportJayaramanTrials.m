function epochGroup = ImportJayaramanTrials(epochGroup, trials)
    % Imports a sequence of trials into the given EpochGroup.
    %
    %    epochGroup = ImportJayaramanTrials(epochGroup, trials)
    %
    %      epochGroup: New Epochs will be inserted into this EpochGroup
    %
    %      trials: Array of trial structures. Each trial to import is
    %      described by one array element.
    %        See https://github.com/physion/jayaraman-importer/wiki for
    %        struct contents.
    
    % Copyright (c) 2012 Physion Consulting LLC
    
    
    disp('Importing Epochs...');
    for i = 1:length(trials)
        
        if(mod(i,5) == 0)
            disp(['    Epoch ' num2str(i) ' of ' num2str(length(trials)) '...']);
        end
        
        trial = trials(i);
        
        [epoch,xsgInserted] = insertFlyArenaEpoch(epochGroup, trial);
        
        if(isfield(trial, 'xsg') && ~xsgInserted && ~isempty(trial.xsg))
            xsg = load(trial.xsg.xsgFilePath, '-mat');
            appendXSG(epoch,...
                xsg,...
                epoch.getStartTime().getZone().getID());
        end
        
        if(isfield(trial,'scanImage') && ~isempty(trial.scanImage))
            appendScanImageTiff(epoch,...
                trial.scanImage.scanImageTIFFPath,...
                trial.scanImage,...
                epoch.getStartTime().getZone().getID(),...
                true);
        end
        
        if(isfield(trial, 'seq') && ~isempty(trial.seq))
            appendSeq(epoch,...
                trial.seq.seqFilePath,...
                trial.seq);
        end
        
        if(isfield(trial, 'treadmill') && ~isempty(trial.treadmill))
            appendTreadmill(epoch,...
                trial.treadmill.treadmillPath,...
                trial.treadmill);
        end
    end
    
    disp('    Done.')
   
   
end