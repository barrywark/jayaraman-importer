function epoch = insertXSGEpoch(epochGroup,...
        xsg,...
        protocolID,...
        timezone)
    
    import ovation.*
    
    if(~strcmp(xsg.header.xsg.xsg.xsgFileFormatVersion,'1.2.0'))
        error('ovation:xsg_importer:fileVersion',...
        ['XSG file format version ' ...
        xsg.header.xsg.xsg.xsgFileFormatVersion ...
        ' is not supported.']);
    end
    
    %% Find trigger time and trace length, making sure values are consistent
    if(isfield(xsg.header, 'acquirer'))
        triggerTime = xsg.header.acquirer.acquirer.triggerTime;
        traceLength = xsg.header.acquirer.acquirer.traceLength;
        
        if(isfield(xsg.header, 'stimulator'))
            if(any(abs(triggerTime - xsg.header.stimulator.stimulator.triggerTime) > 1))
                throw(MException('ovation:xsg_importer:triggerTimeMismatch',...
                    'Trigger time is different between acquirer, stimulator, and ephys'));
            end
            if(any(abs(traceLength - xsg.header.stimulator.stimulator.traceLength) > 1))
                throw(MException('ovation:xsg_importer:traceLengthMismatch',...
                    'Trace length is different between acquirer, stimulator, and ephys'));
            end
        elseif(isfield(xsg.header, 'ephys'))
            if(any(abs(triggerTime - xsg.header.ephys.ephys.triggerTime) > 1))
                throw(MException('ovation:xsg_importer:triggerTimeMismatch',...
                    'Trigger time is different between acquirer, stimulator, and ephys'));
            end
            if(any(abs(traceLength - xsg.header.ephys.ephys.traceLength) > 1))
                throw(MException('ovation:xsg_importer:traceLengthMismatch',...
                    'Trace length is different between acquirer, stimulator, and ephys'));
            end
        end
        
    elseif(isfield(xsg.header, 'stimulator'))
        triggerTime = xsg.header.stimulator.stimulator.triggerTime;
        traceLength = xsg.header.stimulator.stimulator.traceLength;
        
        if(isfield(xsg.header, 'acquirer'))
            if(any(abs(triggerTime - xsg.header.acquirer.acquirer.triggerTime) > 1))
                throw(MException('ovation:xsg_importer:triggerTimeMismatch',...
                    'Trigger time is different between acquirer, stimulator, and ephys'));
            end
            if(any(abs(traceLength - xsg.header.acquirer.acquirer.traceLength) > 1))
                throw(MException('ovation:xsg_importer:traceLengthMismatch',...
                    'Trace length is different between acquirer, stimulator, and ephys'));
            end
        elseif(isfield(xsg.header, 'ephys'))
            if(any(abs(triggerTime - xsg.header.ephys.ephys.triggerTime) > 1))
                throw(MException('ovation:xsg_importer:triggerTimeMismatch',...
                    'Trigger time is different between acquirer, stimulator, and ephys'));
            end
            if(any(abs(traceLength - xsg.header.ephys.ephys.traceLength) > 1))
                throw(MException('ovation:xsg_importer:traceLengthMismatch',...
                    'Trace length is different between acquirer, stimulator, and ephys'));
            end
        end
        
    elseif(isfield(xsg.header, 'ephys'))
        triggerTime = xsg.header.ephys.ephys.triggerTime;
        traceLength = xsg.header.ephys.ephys.traceLength;
        
        if(isfield(xsg.header, 'stimulator'))
            if(any(abs(triggerTime - xsg.header.stimulator.stimulator.triggerTime) > 1))
                throw(MException('ovation:xsg_importer:triggerTimeMismatch',...
                    'Trigger time is different between acquirer, stimulator, and ephys'));
            end
            if(any(abs(traceLength - xsg.header.stimulator.stimulator.traceLength) > 1))
                throw(MException('ovation:xsg_importer:traceLengthMismatch',...
                    'Trace length is different between acquirer, stimulator, and ephys'));
            end
        elseif(isfield(xsg.header, 'acquirer'))
            if(any(abs(triggerTime - xsg.header.acquirer.acquirer.triggerTime) > 1))
                throw(MException('ovation:xsg_importer:triggerTimeMismatch',...
                    'Trigger time is different between acquirer, stimulator, and ephys'));
            end
            if(any(abs(traceLength - xsg.header.acquirer.acquirer.traceLength) > 1))
                throw(MException('ovation:xsg_importer:traceLengthMismatch',...
                    'Trace length is different between acquirer, stimulator, and ephys'));
            end
        end
    else
        error('ovation:xsg_importer:missingRequiredValue', 'XSG file does not contain ephys, stimulator, or acquirer data.');
    end
    import ovation.*;
    startTime = ovation.util.datetime(triggerTime(1),...
        triggerTime(2),...
        triggerTime(3),...
        triggerTime(4),...
        triggerTime(5),...
        floor(triggerTime(6)),...
        rem(triggerTime(6),1) * 1000,... %millis
        timezone);
    
    endTime = startTime.plusMillis(traceLength * 1000);
    
    epoch = epochGroup.insertEpoch(startTime,...
        endTime,...
        protocolID,...
        struct2map(struct()));
    
    epoch = appendXSG(epoch, xsg, timezone);
end