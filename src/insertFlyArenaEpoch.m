function [epoch,xsgInserted] = insertFlyArenaEpoch(epochGroup, trial)
    
    import ovation.*;
    
    epoch = epochGroup.insertEpoch(trial.epochStartTime,...
        trial.epochEndTime,...
        trial.protocolID,...
        struct2map(trial.protocolParameters));
    
    % Add stimulus for arena
    
    params = trial.stimulus.patternParameters;
    if(isfield(trial.stimulus, 'frameNumber') && ...
            ~isempty(trial.stimulus.frameNumber))
        params.frameNumber = trial.stimulus.frameNumber;
    end
    
    %TODO--handle SD card mapping: params.patternSDIndex = trial.stimulus.SDcard;
    
    device = epochGroup.getExperiment().externalDevice('Fly Arena', '<manufacturer>'); %TODO
    
    devParams.controllerMode = trial.stimulus.controllerMode;
    devParams.controllerParameters = trial.stimulus.controllerParameters;
    devParams.firmwareMode = trial.stimulus.firmwareVersion;
    devParams.arenaConfiguration = trial.stimulus.arenaConfigurationName;
    
    units = 'intensity'; % What are the units of output?
    stimulus = epoch.insertStimulus(device,...
        struct2map(devParams),...
        'org.hhmi.janelia.fly-arena',... %TODO
        struct2map(params),...
        units,...
        []);
    
    
    %% Add resources
    
    % TODO attach or referece (as URL)?
    stimulus.addResource('??', trial.stimulus.patternFile);
    stimulus.addResource(trial.stimulus.patternGenerationFunction);
    
    if(isfield(trial.stimulus, 'arenaConfigurationFile') && ...
            ~isempty(trial.stimulus.arenaConfigurationFile))
        stimulus.addResource(trial.stimulus.arenaConfigurationFile);
    else
        warning('ovation:fly_arena_import:missingConfiguration',...
            'Arena configuration .MAT is missing');
    end
    
    
    
    
    %% Links for XSG channels
    xsgInserted = false;
    if(isfield(trial.stimulus, 'xsgXSequenceChannel') || ...
            isfield(trial.stimulus, 'xsgYSequenceChannel'))
        
        xsg = load(trial.xsg.xsgFilePath, '-mat');
        appendXSG(epoch,...
            xsg,...
            epoch.getStartTime().getZone().getID());
        
        %TODO
        if(isfield(trial.stimulus, 'xsgXSequenceChannel'))
            stimulus.addProperty('xsgXSequenceResponse',...
                epoch.getResponse(trial.stimulus.xsgXSequenceChannel));
        end
        
        if(isfield(trial.stimulus, 'xsgYSequenceChannel'))
            stimulus.addProperty('xsgYSequenceResponse',...
                epoch.getResponse(trial.stimulus.xsgYSequenceChannel));
        end
        
        xsgInserted = true;
    end
    
    % Add responses from trial struct
    % TODO
    
end