function [epoch,xsgInserted] = insertFlyArenaEpoch(epochGroup, trial)
    % Inserts a single Fly Arena trial described by the trial strcutre into
    % the given EpochGroup.
    %    
    %    [epoch,xsgInserted] = insertFlyArenaEpoch(epochGroup, trial)
    %
    %      epochGroup: The fly arena Epoch will be inserted into this
    %        EpochGroup.
    %
    %      trial: Trial struct (see ImportJayaramanTrials.m)
    %
    %    Returns
    %    -------
    %
    %      epoch: newly inserted Epoch
    %      xsgInserted: true if XSG data was provided and inserted
    

    % Copyright (c) 2012 Physion Consulting LLC
    
    import ovation.*;
    
    epoch = epochGroup.insertEpoch(trial.epochStartTime,...
        trial.epochEndTime,...
        trial.protocolID,...
        struct2map(trial.protocolParameters));
    
    %% Add stimulus for arena
    
    params = trial.arena.patternParameters;
    if(isfield(trial.arena, 'frameNumber') && ...
            ~isempty(trial.arena.frameNumber))
        params.frameNumber = trial.arena.frameNumber;
    end
    
    %TODO--handle SD card mapping: params.patternSDIndex = trial.arena.SDcard;
    
    device = epochGroup.getExperiment().externalDevice('Fly Arena', '<manufacturer>'); %TODO
    
    devParams.controllerMode = trial.arena.controllerMode;
    devParams.controllerParameters = trial.arena.controllerParameters;
    devParams.firmwareMode = trial.arena.firmwareVersion;
    devParams.arenaConfiguration = trial.arena.arenaConfigurationName;
    
    units = 'intensity'; % What are the units of output?
    stimulus = epoch.insertStimulus(device,...
        struct2map(devParams),...
        'org.hhmi.janelia.fly-arena',... %TODO
        struct2map(params),...
        units,...
        []);
    
    
    %% Add resources
    
    % TODO attach or referece (as URL)?
    stimulus.addResource(trial.arena.patternFile); % .mat
    stimulus.addResource(trial.arena.patternGenerationFunction); % .m
    
    if(isfield(trial.arena, 'arenaConfigurationFile') && ...
            ~isempty(trial.arena.arenaConfigurationFile))
        stimulus.addResource(trial.arena.arenaConfigurationFile);
    else
        warning('ovation:fly_arena_import:missingConfiguration',...
            'Arena configuration .MAT is missing');
    end
    
    
    
    
    %% Links for XSG channels
    xsgInserted = false;
    if(isfield(trial.arena, 'xsgXSequenceChannel') || ...
            isfield(trial.arena, 'xsgYSequenceChannel'))
        
        xsg = load(trial.xsg.xsgFilePath, '-mat');
        appendXSG(epoch,...
            xsg,...
            epoch.getStartTime().getZone().getID());
        
        %TODO
        if(isfield(trial.arena, 'xsgXSequenceChannel'))
            stimulus.addProperty('xsgXSequenceResponse',...
                epoch.getResponse(trial.arena.xsgXSequenceChannel));
        end
        
        if(isfield(trial.arena, 'xsgYSequenceChannel'))
            stimulus.addProperty('xsgYSequenceResponse',...
                epoch.getResponse(trial.arena.xsgYSequenceChannel));
        end
        
        xsgInserted = true;
    end
    
    %% Add responses from trial struct
    if(isfield(trial, 'responses'))
       for i = 1:legnth(trial.responses)
           
           device = epochGroup.getExperiment().externalDevice(...
               trial.responses(i).deviceName,...
               trial.responses(i).deviceManufacturer);
           
           if(isfield(trial.responses(i), 'data'))
               % Insert data directly to database
               data = NumericData(trial.responses(i).data);
               epoch.insertResponse(device,...
                   struct2map(trial.responses(i).deviceParameters),...
                   data,...
                   ec20111018.responses.channels(1).units,...
                   trial.responses(i).channelName,...
                   trial.responses(i).samplingRateHz,...
                   'Hz',...
                   Response.NUMERIC_DATA_UTI);
           end
           
           
           %TODO we currently don't handle indexing into MAT files (but
           %will soon)
           if(isfield(trial.responses(i), 'dataFileURL'))
               if(isfield(trial.responses(i), 'dataStartIndex') ||...
                       isfield(trial.responses(i), 'dataStartIndex'))
                   
                   if(~(isfield(trial.responses(i), 'dataStartIndex') &&...
                       isfield(trial.responses(i), 'dataStartIndex')))
                   error('ovation:fly_arena_import:missingConfiguration',...
                       'dataStartIndex and dataEndIndex are required for URL responses');
                   end
                   
                   epoch.insertURLResponse(device,...
                       struct2map(trial.responses(i).deviceParameters),...
                       trial.responses(i).dataFileURL,...
                       trial.responses(i).shape,...
                       trial.responses(i).dataType,...
                       trial.responses(i).dataStartIndex,...
                       trial.responses(i).dataEndIndex,...
                       trial.responses(i).units,...
                       {trial.responses(i).channelName},...
                       [trial.responses(i).samplingRate],...
                       {'Hz'},...
                       Response.NUMERIC_DATA_UTI);
                   
               else
                   epoch.insertURLResponse(device,...
                       struct2map(trial.responses(i).deviceParameters),...
                       trial.responses(i).dataFileURL,...
                       trial.responses(i).shape,...
                       trial.responses(i).dataType,...
                       trial.responses(i).units,...
                       {trial.responses(i).channelName},...
                       [trial.responses(i).samplingRate],...
                       {'Hz'},...
                       Response.NUMERIC_DATA_UTI);
               end
           end
       end
    end
    
end