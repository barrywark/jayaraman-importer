function epoch = appendXSG(epoch,...
        xsg,...
        timezone)
    
    import ovaiton.*;
    
    if(~strcmp(xsg.header.xsg.xsg.xsgFileFormatVersion,'1.2.0'))
        error('ovation:xsg_importer:fileVersion',...
        ['XSG file format version ' ...
        xsg.header.xsg.xsg.xsgFileFormatVersion ...
        ' is not supported.']);
    end
    
    %% Find trigger time and trace length, making sure values are consistent
    
    maxDifference = 0.5; %seconds
    if(isfield(xsg.header, 'acquirer'))
        triggerTime = xsg.header.acquirer.acquirer.triggerTime;
        traceLength = xsg.header.acquirer.acquirer.traceLength;
        
        startTime = ovation.datetime(triggerTime(1),...
            triggerTime(2),...
            triggerTime(3),...
            triggerTime(4),...
            triggerTime(5),...
            floor(triggerTime(6)),...
            rem(triggerTime(6),1) * 1000,... %millis
            timezone);
        
        diff = org.joda.time.Period(startTime, epoch.getStartTime()).toStandardDuration();
        if(abs(diff.getMillis()) > maxDifference*1000)
            error('ovation:xsg_importer:triggerTimeMismatch', 'XSG trigger time differs from epoch startTime by more than 0.5s.');
        end
        
        if(abs(epoch.getDuration() - traceLength) > maxDifference)
            error('ovation:xsg_importer:traceLengthMismatch', 'XSG trace length differs from epoch startTime by more than 0.5s.');
        end
        
    elseif(isfield(xsg.header, 'stimulator'))
        triggerTime = xsg.header.stimulator.stimulator.triggerTime;
        traceLength = xsg.header.stimulator.stimulator.traceLength;
        
        startTime = ovation.datetime(triggerTime(1),...
            triggerTime(2),...
            triggerTime(3),...
            triggerTime(4),...
            triggerTime(5),...
            floor(triggerTime(6)),...
            rem(triggerTime(6),1) * 1000,... %millis
            timezone);
        
        diff = org.joda.time.Period(startTime, epoch.getStartTime()).toStandardDuration();
        if(abs(diff.getMillis()) > maxDifference*1000)
            error('ovation:xsg_importer:triggerTimeMismatch', 'XSG trigger time differs from epoch startTime by more than 0.5s.');
        end
        
        if(abs(epoch.getDuration() - traceLength) > maxDifference)
            error('ovation:xsg_importer:traceLengthMismatch', 'XSG trace length differs from epoch startTime by more than 0.5s.');
        end
        
    elseif(isfield(xsg.header, 'ephys'))
        triggerTime = xsg.header.ephys.ephys.triggerTime;
        traceLength = xsg.header.ephys.ephys.traceLength;
        
        startTime = ovation.datetime(triggerTime(1),...
            triggerTime(2),...
            triggerTime(3),...
            triggerTime(4),...
            triggerTime(5),...
            floor(triggerTime(6)),...
            rem(triggerTime(6),1) * 1000,... %millis
            timezone);
        
        diff = org.joda.time.Period(startTime, epoch.getStartTime()).toStandardDuration();
        if(abs(diff.getMillis()) > maxDifference*1000)
            error('ovation:xsg_importer:triggerTimeMismatch', 'XSG trigger time differs from epoch startTime by more than 0.5s.');
        end
        
        if(abs(epoch.getDuration() - traceLength) > maxDifference)
            error('ovation:xsg_importer:traceLengthMismatch', 'XSG trace length differs from epoch startTime by more than 0.5s.');
        end
    else
        error('ovation:xsg_importer:missingRequiredValue', 'XSG file does not contain ephys, stimulator, or acquirer data.');
    end
    
    %% Check Experiment, Set and Sequence values
    
    experimentNumbers = epoch.getProperty('xsg_experiment_number');
    if(~isempty(experimentNumbers))
        if(length(experimentNumbers) > 1)
            error('ovation:xsg_importer:tooManyExperimentNumberValues',...
                'More than one xsg_experiment_number property value present on this Epoch.');
        end
        
        experimentNumber = experimentNumbers(1);
        
        if(int64(str2double(xsg.header.xsg.xsg.experimentNumber)) ~= experimentNumber)
            error('ovation:xsg_importer:experimentNumberMismatch',...
            'xsg_experiment_number value on this Epoch does not match the experimentNumber in xsg header.');
        end
    end
    
    setIDs = epoch.getProperty('xsg_setID');
    if(~isempty(setIDs))
        if(length(setIDs) > 1)
            error('ovation:xsg_importer:tooManySetIDValues',...
                'More than one xsg_setID property value present on this Epoch.');
        end
        
        setID = setIDs(1);
        if(~strcmp(char(setID), xsg.header.xsg.xsg.setID))
            error('ovation:xsg_importer:setIDMismatch',...
            'xsg_setID value on this Epoch does not match the setID in xsg header.');
        end
    end
        
    acquisitionNumbers = epoch.getProperty('xsg_acquisition_number');
    if(~isempty(acquisitionNumbers))
        if(length(acquisitionNumbers) > 1)
            error('ovation:xsg_importer:tooManySequenceNumberValues',...
                'More than one xsg_sequence_number property value present on this Epoch.');
        end
        
        acquisitionNumber = acquisitionNumbers(1);
        
        if(int64(str2double(xsg.header.xsg.xsg.acquisitionNumber)) ~= acquisitionNumber)
            error('ovation:xsg_importer:acquisitionNumberMismatch',...
            'xsg_acquisition_number value on this Epoch does not match the acquisitionNumber in xsg header.');
        end
    end
    
    %% Append protocol parameters
    paramNames = fieldnames(xsg.header.loopGui.loopGui);
    for i = 1:length(paramNames)
        paramName = paramNames{i};
        epoch.addProtocolParameter(paramName,...
            xsg.header.loopGui.loopGui.(paramName));
    end
    
    
    %% Create Stimuli for stimulator channels
    stim = xsg.header.stimulator.stimulator;
    for i = 1:length(stim.channels)
        dev = epoch.getEpochGroup().getExperiment().externalDevice(...
            stim.channels(i).channelName,...
            'Ephus');
        
        if(~isempty(stim.channels(i).boardID))
            devParams.boardID = stim.channels(i).boardID;
        end
        if(~isempty(stim.channels(i).channelID))
            devParams.channelID = stim.channels(i).channelID;
        end
        if(~isempty(stim.channels(i).portID))
            devParams.portID = stim.channels(i).portID;
        end
        if(~isempty(stim.channels(i).channelID))
            devParams.lineID = stim.channels(i).lineID;
        end
        devParams.externalTrigger = stim.externalTrigger == 1; %boolean
        devParams.selfTrigger = stim.selfTrigger == 1; % boolean
        devParams.stimOn = stim.stimOnArray(i); %TODO: boolean?
        devParams.extraGain = stim.extraGainArray(i);
        
        pluginID = 'org.janelia.hhmi.jayaraman.ephus';
        
        stimParams = stim.pulseParameters{i};
        stimParams.pulseSet = stim.pulseSetNameArray{i};
        stimParams.pulseName = stim.pulseNameArray{i};
        
        units = 'V';
        
        dimensionLabels = [];
        
        epoch.insertStimulus(dev,...
            ovation.struct2map(devParams),...
            pluginID,...
            ovation.struct2map(stimParams),...
            units,...
            dimensionLabels);
    end
end