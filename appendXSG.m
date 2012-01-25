function epoch = appendXSG(epoch,...
        xsg,...
        timezone)
    
    import ovaiton.*;
    
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
            error('ovation:importer:xsg:triggerTimeMismatch', 'XSG trigger time differs from epoch startTime by more than 0.5s.');
        end
        
        if(abs(epoch.getDuration() - traceLength) > maxDifference)
            error('ovation:importer:xsg:traceLengthMismatch', 'XSG trace length differs from epoch startTime by more than 0.5s.');
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
            error('ovation:importer:xsg:triggerTimeMismatch', 'XSG trigger time differs from epoch startTime by more than 0.5s.');
        end
        
        if(abs(epoch.getDuration() - traceLength) > maxDifference)
            error('ovation:importer:xsg:traceLengthMismatch', 'XSG trace length differs from epoch startTime by more than 0.5s.');
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
            error('ovation:importer:xsg:triggerTimeMismatch', 'XSG trigger time differs from epoch startTime by more than 0.5s.');
        end
        
        if(abs(epoch.getDuration() - traceLength) > maxDifference)
            error('ovation:importer:xsg:traceLengthMismatch', 'XSG trace length differs from epoch startTime by more than 0.5s.');
        end
    else
        error('ovation:importer:xsg:missingRequiredValue', 'XSG file does not contain ephys, stimulator, or acquirer data.');
    end
    
    %% Check Experiment, Set and Sequence values
    
    experimentNumber = epoch.getProperty('xsg_experiment_number');
    if(~isempty(experimentNumber))
        if(length(experimentNumber) > 1)
            error('ovation:importer:xsg:tooManyExperimentNumberValues',...
                'More than one xsg_experiment_number property value present on this Epoch.');
        end
        
        experimentNumber = experimentNumber(1);
        
        if(int64(str2double(xsg.header.xsg.xsg.experimentNumber)) ~= experimentNumber)
            error('ovation:importer:xsg:experimentNumberMismatch',...
            'xsg_experiment_number value on this Epoch does not match the experimentNumber in xsg header.');
        end
    end
    
    
end