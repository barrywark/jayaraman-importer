function epoch = appendScanImageTiff(epoch,...
                               tifFile,...
                               scanImageConfig,... 
                               timezone,...
                               failForBadResponseTimes)

    % Add Stimuli and Response information contained in a tif file, to a
    % given Epoch. Returns the updated Epoch.
    %
    %    epoch = appendScanImageTiff(epoch, tifFile, scanImageConfig,...
    %                                 timezone)
    %                                 
    %      epoch: ovation.Epoch object. The Epoch to attach the Response
    %      and Stimulus to. 
    %
    %      tifFile: path to the scanImage generated .TIF file
    %
    %      scanImageConfig: Matlab struct describing scanImage frame and
    %      PMT configuration.
    %        See https://github.com/physion/jayaraman-importer/wiki for
    %        struct template.
    %     
    %      timezone: Time zone ID where the experiment was performed (e.g.
    %      'America/New_York').
    
    % Copyright (c) 2012 Physion Consulting LLC
        
    import ovation.*;
    
    tif_struct = scim_openTif(tifFile, 'header');   
    
    if(tif_struct.software.version ~= 3.6000)
        error('ovation:scanimage_tiff_importer:fileVersion',...
            ['ScanImage TIFF file format version ' ...
            tif_struct.software.version ...
            ' is not supported.']);
    end
    

    error(nargchk(4, 5, nargin));
    if(nargin < 5)
        failForBadResponseTimes = false;
    end

    
    %% check that start and end times for the epoch overlap with the tif file
    duration = tif_struct.acq.numberOfFrames/tif_struct.acq.frameRate; %in seconds? NOTE: tif_struct.framesPerFile is bogus
    import org.joda.time.*
    fmt = org.joda.time.format.DateTimeFormat.forPattern('MM/dd/yyyy HH:mm:ss');
    fmt = fmt.withZone(DateTimeZone.forID(timezone));
    ts = tif_struct.internal.triggerTimeString;
    idx = strfind(ts, '.');
    if(~isempty(idx))
        ts = ts(1:(idx-1));
    end
    triggerTimeStart = fmt.parseDateTime(ts);
    triggerTimeEnd = triggerTimeStart.plusSeconds(duration);
    if epoch.getStartTime().isAfter(triggerTimeEnd) || epoch.getEndTime().isBefore(triggerTimeStart)
        if failForBadResponseTimes
            err = MException('ovation:scanimage_tiff_importer:timeMismatch', ...
        'Times recorded in scanImage file do not match times recorded in this epoch!');
            throw(err);
        else
            warning('ovation:scanimage_tiff_importer:timeMismatch',...
                'Times recorded in scanImage file do not match times recorded in this epoch.');
        end
        % todo: maybe an interactive prompt so the user can choose to
        % ignore this warning?
    end
    
    ignored_fields.acq = struct();
    ignored_fields.acq.staircaseSlowDim = 1;
    ignored_fields.acq.zoomhundreds = 1;
    ignored_fields.acq.zoomtens = 1;
    ignored_fields.acq.zoomones = 1;
    ignored_fields.acq.fillFraction = 1;
    ignored_fields.acq.samplesAcquiredPerLine = 1;
    ignored_fields.acq.acqDelay = 1;
    ignored_fields.acq.scanDelay = 1;
    ignored_fields.acq.baseZoomFactor = 1;
    ignored_fields.acq.inputRate = 1;
    ignored_fields.acq.inputBitDepth = 1;
    ignored_fields.acq.rboxZoomSetting = 1;
    ignored_fields.acq.acquiringChannel = 1;
    ignored_fields.acq.imagingChannel = 1;
    ignored_fields.acq.savingChannel = 1;
    ignored_fields.acq.maxImage = 1;
    ignored_fields.acq.inputVoltageRange = 1;
    ignored_fields.acq.numberOfChannelsSave = 1;
    ignored_fields.acq.maxMode = 1;
    ignored_fields.acq.saveDuringAcquisition = 1;
    ignored_fields.acq.framesPerFile = 1;
    ignored_fields.init.eom = 1;
    ignored_fields.cycle = 1;
    ignored_fields.internal = 1;
        
    %% create response contained in tif files
    device_params.configName = tif_struct.configName;
    device_params.software_version = tif_struct.software.version;
    device_params.software_version_minor_revision = tif_struct.software.minorRev;
    device_params.software_version_beta = tif_struct.software.beta;
    device_params.configurationName = tif_struct.configName;
    device_params.scanOffsetX = tif_struct.init.scanOffsetX;
    device_params.motor_absXPosition = tif_struct.motor.absXPosition;
    device_params.motor_absYPosition = tif_struct.motor.absYPosition;
    device_params.motor_absZPosition = tif_struct.motor.absZPosition;
    device_params.motor_relXPosition = tif_struct.motor.relXPosition;
    device_params.motor_relYPosition = tif_struct.motor.relYPosition;
    device_params.motor_relZPosition = tif_struct.motor.relZPosition;
    device_params.motor_distance = tif_struct.motor.distance;
    
    pmt_parameters = struct();
    acq_names = fieldnames(tif_struct.acq);

    for i=1:length(acq_names)
        name = acq_names(i);
        name = name{1};
        
        if ~isfield(ignored_fields.acq, name) % if name is NOT in ignored_fields, add it to device params list
            if name(end) == '1'
                if ~isfield(ignored_fields.acq, name(1:end-1))
                    pmt_parameters.pmt1.(name) = tif_struct.acq.(name);
                end
            elseif name(end) == '2'
                if ~isfield(ignored_fields.acq, name(1:end-1))
                    pmt_parameters.pmt2.(name) = tif_struct.acq.(name);
                end
            elseif name(end) == '3'
                if ~isfield(ignored_fields.acq, name(1:end-1))
                    pmt_parameters.pmt3.(name) = tif_struct.acq.(name);
                end
            elseif name(end) == '4'
                if ~isfield(ignored_fields.acq, name(1:end-1))
                    pmt_parameters.pmt4.(name) = tif_struct.acq.(name);
                end
            else
                device_params.(name) = tif_struct.acq.(name);
            end
        
        end
    end

    
    for c = 1:4
        if tif_struct.acq.(['savingChannel' num2str(c)])
            deviceName = ['pmt' num2str(c)];
            params = mergeStruct(pmt_parameters.(['pmt' num2str(c)]), device_params);
            addResponse(deviceName,...
                scanImageConfig.PMT(c),...
                params, epoch,...
                tif_struct,...
                scanImageConfig);
        end
    end
    

    % empty response with url pointing to response

    function r = addResponse(deviceName, pmtInfo, pmt_params, epoch, tif_struct, scanImageConfig)
        import ovation.*;

        pmt = epoch.getEpochGroup().getExperiment().externalDevice(deviceName, pmtInfo.manufacturer);
        units = 'V';% not quite volts - off by some scalar factor
        
        [XSamplingRate, XSamplingUnit, XLabel] = getXResolution(tif_struct, scanImageConfig);
        [YSamplingRate, YSamplingUnit, YLabel] = getYResolution(tif_struct, scanImageConfig);
        [ZSamplingRate, ZSamplingUnit, ZLabel] = getZResolution(tif_struct);
        dimensionLabels = {XLabel, YLabel, ZLabel};
        samplingRate = [XSamplingRate, YSamplingRate, ZSamplingRate];
        samplingRateUnits = {XSamplingUnit, YSamplingUnit, ZSamplingUnit};
        shape = [tif_struct.acq.pixelsPerLine, tif_struct.acq.linesPerFrame, tif_struct.acq.numberOfZSlices];

        url = java.io.File(tifFile).toURI().toURL().toExternalForm();
        
        byteSizeOfEachInt = 4;
        data_type = NumericDataType(NumericDataFormat.UnsignedIntegerDataType, byteSizeOfEachInt, NumericByteOrder.ByteOrderBigEndian);%% Big Endian?
        r = epoch.insertURLResponse(pmt,...
            struct2map(pmt_params),...
            url,...
            shape,...
            data_type,...
            units,...
            dimensionLabels,...
            samplingRate,...
            samplingRateUnits,...
            Response.TIFF_DATA_UTI); 
        dataRetrievalFunction = 'scm_openTif';
        r.addProperty('__ovation_url', tifFile);
        r.addProperty('__ovation_retrieval_funcion', dataRetrievalFunction);
        r.addProperty('__ovation_retrieval_parameter1', tifFile);
        r.addProperty('__ovation_retrieval_parameter2', 'cell');
        r.addProperty('__ovation_retrieval_parameter3', deviceName(end));
        
        r.addProperty('filterColor', pmtInfo.filter);

    end

    function [resolution, units, label] = getXResolution(tif_struct, scanImageConfig)
        
        resolution = scanImageConfig.XFrameDistance / tif_struct.acq.pixelsPerLine;
        units = [scanImageConfig.XFrameDistanceUnits '/pixel'];
        label = 'X';
    end

    function [resolution, units, label] = getYResolution(tif_struct, scanImageConfig)
        if tif_struct.acq.linescan %%TODO is this right??
            resolution = tif_struct.acq.msPerLine + tif_struct.acq.scanDelay ;
            units = 'ms/line';
        else
            resolution = scanImageConfig.YFrameDistance / tif_struct.acq.linesPerFrame;
            units = [scanImageConfig.YFrameDistanceUnits '/pixel'];
        end
        label = 'Y';
    end
    
    function [resolution, units, label] = getZResolution(tif_struct)
        resolution = tif_struct.acq.zStepSize;
        units = 'µm/step';
        label = 'Z';
    end
end
