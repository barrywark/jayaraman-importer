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
    
    xsgInserted = false;
    
    epoch = epochGroup.insertEpoch(trial.epochStartTime,...
        trial.epochEndTime,...
        trial.protocolID,...
        struct2map(trial.protocolParameters));
    
    %% Add stimulus for arena
    
    if(~isfield(trial, 'arena'))
        return;
    end
    
    params = trial.arena.patternParameters;
    if(isfield(trial.arena, 'frameNumber') && ...
            ~isempty(trial.arena.frameNumber))
        params.frameNumber = trial.arena.frameNumber;
    end
    
    device = epochGroup.getExperiment().externalDevice('Fly Arena', '<manufacturer>'); %TODO
    
    devParams.controllerMode = trial.arena.controllerMode;
    devParams.controllerParameters = trial.arena.controllerParameters;
    devParams.firmwareVersion = trial.arena.firmwareVersion;
    devParams.arenaConfiguration = trial.arena.arenaConfigurationName;
    
    units = 'intensity'; % What are the units of output?
    
    if(isfield(trial.arena, 'patternGenerationFunction'))
        [~,patternName,~] = fileparts(trial.arena.patternGenerationFunction);
    elseif(isfield(trial.arena, 'patternFile'))
        [~,patternName,~] = fileparts(trial.arena.patternFile);
    end
    
    stimulus = epoch.insertStimulus(device,...
        struct2map(devParams),...
        ['org.hhmi.janelia.fly-arena.' patternName],...
        struct2map(params),...
        units,...
        []);
    
    
    %% Add resources
    
    % TODO attach or referece (as URL)?
    if(isfield(trial.arena, 'patternFile'))
        stimulus.addResource(trial.arena.patternFile); % .mat
    end
    
    if(isfield(trial.arena, 'patternGenerationFunction'))
        stimulus.addResource(trial.arena.patternGenerationFunction); % .m
    end
    
    if(isfield(trial.arena, 'arenaConfigurationFile') && ...
            ~isempty(trial.arena.arenaConfigurationFile))
        stimulus.addResource(trial.arena.arenaConfigurationFile);
    else
        warning('ovation:fly_arena_import:missingConfiguration',...
            'Arena configuration .MAT is missing');
    end
    
    
    
    
    %% Links for XSG channels
    if(isfield(trial.arena, 'xsgXSequenceChannel') && ...
            isfield(trial.arena, 'xsgYSequenceChannel'))
        
        xsg = load(trial.xsg.xsgFilePath, '-mat');
        disp('      Appending XSG data...');
        appendXSG(epoch,...
            xsg,...
            epoch.getStartTime().getZone().getID());
        
        disp('        adding xsgXSequenceChannel link');
        stimulus.addProperty('xsgXSequenceResponse',...
            epoch.getResponse(trial.arena.xsgXSequenceChannel));
        
        disp('        adding xsgYSequenceChannel link');
        stimulus.addProperty('xsgYSequenceResponse',...
            epoch.getResponse(trial.arena.xsgYSequenceChannel));
        
        xsgInserted = true;
    else
        if(~isfield(trial.arena, 'frameNumber'))
            error('ovation:fly_arena_import:missingConfiguration',...
                'trial.arena must contain .frameNumber or xsgXSequenceChannel');
        end
    end
    
    %% Add responses from trial struct
    if(isfield(trial, 'responses'))
       for i = 1:length(trial.responses.channels)
           
           channel = trial.responses.channels(i);
           
           device = epochGroup.getExperiment().externalDevice(...
               channel.deviceName,...
               channel.deviceManufacturer);
           
           if(isfield(channel, 'data') && ~isempty(channel.data))
               % Insert data directly to database
               data = NumericData(channel.data);
               epoch.insertResponse(device,...
                   struct2map(channel.deviceParameters),...
                   data,...
                   channel.units,...
                   channel.channelName,...
                   channel.samplingRateHz,...
                   'Hz',...
                   Response.NUMERIC_DATA_UTI);
           elseif(isfield(channel, 'dataFileURL') && ~isempty(channel.dataFileURL))
               %TODO we currently don't handle indexing into MAT files (but
               %will soon)
               
               if(isfield(channel, 'dataStartIndex') ||...
                       isfield(channel, 'dataStartIndex'))
                   
                   if(~(isfield(channel, 'dataStartIndex') &&...
                       isfield(channel, 'dataStartIndex')))
                   error('ovation:fly_arena_import:missingConfiguration',...
                       'dataStartIndex and dataEndIndex are required for URL responses');
                   end
                   
                   epoch.insertURLResponse(device,...
                       struct2map(channel.deviceParameters),...
                       channel.dataFileURL,...
                       channel.shape,...
                       channel.dataType,...
                       channel.dataStartIndex,...
                       channel.dataEndIndex,...
                       channel.units,...
                       {channel.channelName},...
                       [channel.samplingRateHz],...
                       {'Hz'},...
                       Response.NUMERIC_DATA_UTI);
                   
               else
                   epoch.insertURLResponse(device,...
                       struct2map(channel.deviceParameters),...
                       channel.dataFileURL,...
                       channel.shape,...
                       channel.dataType,...
                       channel.units,...
                       {channel.channelName},...
                       [channel.samplingRateHz],...
                       {'Hz'},...
                       Response.NUMERIC_DATA_UTI);
               end
           else
               error('ovation:fly_arena_import:missingConfiguration',...
                   'One of trial.resposnes.channels.data or trial.responses.channels.dataFileURL is required');
           end
       end
    end
    
end