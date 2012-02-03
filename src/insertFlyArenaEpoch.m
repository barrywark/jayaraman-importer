function [epoch,xsgInserted] = insertFlyArenaEpoch(epochGroup, trial)
    
    import ovation.*;
    
    epoch = epochGroup.insertEpoch(trial.epochStartTime,...
        trial.epochEndTime,...
        trial.protocolID,...
        struct2map(trial.protocolParameters));
    
    % Add stimulus for arena
    
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
    stimulus.addResource('??', trial.arena.patternFile);
    stimulus.addResource(trial.arena.patternGenerationFunction);
    
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
    
    % Add responses from trial struct
    % TODO
    
end