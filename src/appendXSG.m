function epoch = appendXSG(epoch,...
        xsg,...
        timezone)
    
    % Add Stimuli and Response information contained in an Ephus XSG, to a given Epoch. Returns the updated Epoch. 
    %
    %    epoch = appendXSG(epoch, xsgPath, timezone)
    %                                 
    %      epoch: ovation.Epoch object. The Epoch to attach the Response
    %      to.
    %
    %      xsg: path to an Ephus XSG file
    %
    %      timezone: Time zone ID where the experiment was performed (e.g.
    %      'America/New_York').
    
    % Copyright (c) 2012 Physion Consulting LLC
    
    import ovaiton.*;
    
    if(~strcmp(xsg.header.xsg.xsg.xsgFileFormatVersion,'1.2.0'))
        error('ovation:xsg_importer:fileVersion',...
            ['XSG file format version ' ...
            xsg.header.xsg.xsg.xsgFileFormatVersion ...
            ' is not supported.']);
    end
    
    % Find trigger time and trace length, making sure values are consistent
    % with the Epoch to which we're appending
    maxDifference = 0.5; %seconds
    checkTimelineBoundaries(epoch, xsg, timezone, maxDifference);
    
    % Check Experiment, Set and Acquisition numbers. Raises an exception if the
    % Epoch to which we're appending doesn't match the Experiment, Set and
    % Acquisition values in the XSG struct.
    checkEpochMatchesXSG(epoch, xsg);
    
    
    % Append protocol parameters
    paramNames = fieldnames(xsg.header.loopGui.loopGui);
    for i = 1:length(paramNames)
        paramName = paramNames{i};
        epoch.addProtocolParameter(paramName,...
            xsg.header.loopGui.loopGui.(paramName));
    end
    
    
    % Create Stimuli for stimulator channels
    appendStimuli(epoch, xsg);
    
    
    % Create Responses for acquirer channels
    appendResponses(epoch,xsg);
    
    % Create stimulus/response for Ephys
    % TODO allow skip ephys
    appendEphys(epoch, xsg);
end

function appendEphys(epoch, xsg)
   % Assumes stim + response for each amplifier 
   
   import ovation.*;
   
   ephys = xsg.header.ephys.ephys;
   ampNames = fieldnames(ephys.amplifierSettings);
   
   
   for i = 1:length(ampNames)
       ampName = ampNames{i};
       
       if(~isfield(ephys.amplifierSettings.(ampName), 'ampState'))
           warning('ovation:xsg_importer:missingEphysAmpState',...
               ['Missing ampState for ' ampName '. Skipping this amplifier channel.']);
           continue;
       end
           
       dev = epoch.getEpochGroup().getExperiment().externalDevice(...
           ampName,...
           ephys.amplifierSettings.(ampName).ampState.uHardwareType); %TODO should we have the real manufacturer?
       
       
       % Stimulus
       pluginID = 'org.janelia.hhmi.jayaraman.ephus';
       
       units = ephys.amplifierSettings.(ampName).output_units;
       dimensionLabels = [ephys.amplifierSettings.(ampName).mode ' stimulus'];
       
       devParams.externalTrigger = ephys.externalTrigger == 1; %boolean
       devParams.selfTrigger = ephys.selfTrigger == 1; % boolean
       devParams.stimOn = ephys.stimOnArray(i); %TODO: boolean?
       devParams.sampleRate = ephys.sampleRate;
       devParams.sampleRateUnits = 'Hz';
       devParams.(ampName) = ephys.amplifierSettings(i).(ampName);

       
       stimParams.pulseSetName = ephys.pulseSetNameArray{i};
       stimParams.pulseName = ephys.pulseNameArray{i};
       stimParams.pulseNumber = ephys.pulseNumber;
       stimParams.pulseParameters = ephys.pulseParameters{i};
       
       epoch.insertStimulus(dev,...
           ovation.struct2map(devParams),...
           pluginID,...
           ovation.struct2map(stimParams),...
           units,...
           dimensionLabels);
       
       
       % Response
       
       units = ephys.amplifierSettings.(ampName).input_units;
       dimensionLabel = [ephys.amplifierSettings.(ampName).mode ' response'];
       
       data = NumericData(xsg.data.ephys.(['trace_' num2str(i)]));
       
       samplingRate = ephys.sampleRate;
       samplingRateUnits = 'Hz';
       
       epoch.insertResponse(dev,...
           ovation.struct2map(devParams),...
           data,...
           units,...
           dimensionLabel,...
           samplingRate,...
           samplingRateUnits,...
           Response.NUMERIC_DATA_UTI);
   end
end

function appendResponses(epoch, xsg)
    import ovation.*;
    
    resp = xsg.header.acquirer.acquirer;
    
   for i = 1:length(resp.channels)
       
       if(~isfield(xsg.data.acquirer, ['channelName_' num2str(i)]))
           continue;
       end
       
       dev = epoch.getEpochGroup().getExperiment().externalDevice(...
           resp.channels(i).channelName,...
           'Ephus');
        
       devParams.boardID = resp.channels(i).boardID;
       devParams.channelID = resp.channels(i).channelID;
       
       samplingRate = resp.sampleRate;
       samplingRateUnits = 'Hz';
       
       units = 'V';
       
       assert(strcmp(xsg.data.acquirer.(['channelName_' num2str(i)]),...
           resp.channels(i).channelName));
       
       data = NumericData(xsg.data.acquirer.(['trace_' num2str(i)]));
       
       epoch.insertResponse(dev,...
           struct2map(devParams),...
           data,...
           units,...
           'Volts',...
           samplingRate,...
           samplingRateUnits,...
           Response.NUMERIC_DATA_UTI);
   end
end

function appendStimuli(epoch, xsg)
    import ovation.*;
    
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
        devParams.sampleRate = stim.sampleRate;
        devParams.sampleRateUnits = 'Hz';
        
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

function [triggerTime, traceLength] = checkTimelineBoundaries(epoch,...
        xsg,...
        timezone,...
        maxDifference)
    
    import ovation.*;
    
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
end


function checkEpochMatchesXSG(epoch, xsg)
    import ovation.*;
    
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
end