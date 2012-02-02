function epoch = appendScanImageTiff(epoch,...
                               tifFile,...
                               yamlFile,... 
                               timeZone,...
                               failForBadResponseTimes)

    % Add Stimuli and Response information contained in a tif file, to a given Epoch. Return the updated Epoch. 
    %
    %    epoch = AppendTifData(epoch, tifFile)
    %                                 
    %      epoch: ovation.Epoch object. The Epoch to attach the Response
    %      and Stimulus to. 
    %
    %      tifFile: path to the scanImage generated .TIF file
    %
    %      yamlFile: path to the user-defined yamlfile. This file contains
    %      a mapping between pmt and coloredFilter (if there is one). It
    %      also contains the distance (in microns) of the X and Y
    %      dimensions of the image (unless its a linescan experiment, in
    %      which case there is no Y distance)
        
    import ovation.*;
    
    tif_struct = scim_openTif(tifFile, 'header');   
    
    if(tif_struct.software.version ~= 3.6000)
        error('ovation:scanimage_tiff_importer:fileVersion',...
            ['ScanImage TIFF file format version ' ...
            tif_struct.software.version ...
            ' is not supported.']);
    end
    
    manufacturer = 'pmt_manufacturer'; % fix

    error(nargchk(4, 5, nargin)); %#ok<NCHKI>
    if(nargin < 5)
        failForBadResponseTimes = false;
    end

    
    %% check that start and end times for the epoch overlap with the tif file
    duration = tif_struct.acq.numberOfFrames/tif_struct.acq.frameRate; %in seconds? NOTE: tif_struct.framesPerFile is bogus
    import org.joda.time.*
    fmt = org.joda.time.format.DateTimeFormat.forPattern('MM/dd/yyyy HH:mm:ss');
    fmt = fmt.withZone(DateTimeZone.forID('America/New_York'));
    triggerTimeStart = fmt.parseDateTime(tif_struct.internal.triggerTimeString);
    triggerTimeEnd = triggerTimeStart.plusSeconds(duration);
    if epoch.getStartTime().isAfter(triggerTimeEnd) || epoch.getEndTime().isBefore(triggerTimeStart)
        if failForBadResponseTimes
            err = MException('ovation:scanimage_tiff_importer:timeMismatch', ...
        'Times recorded in scanImage file do not match times recorded in this epoch!');
            throw(err);
        else
            disp('Error occurred!! Times recorded in scanImage file do not match times recorded in this epoch!');
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
        
    %% create response contained in tif/yaml files
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
        
        if ~nameInStruct(name, ignored_fields.acq) % if name is NOT in ignored_fields, add it to device params list
            if name(end) == '1'
                if ~nameInStruct(name(1:end-1), ignored_fields.acq)
                    pmt_parameters.pmt1.(name) = tif_struct.acq.(name);
                end
            elseif name(end) == '2'
                if ~nameInStruct(name(1:end-1), ignored_fields.acq)
                    pmt_parameters.pmt1.(name) = tif_struct.acq.(name);
                end
            elseif name(end) == '3'
                if ~nameInStruct(name(1:end-1), ignored_fields.acq)
                    pmt_parameters.pmt1.(name) = tif_struct.acq.(name);
                end
            elseif name(end) == '4'
                if ~nameInStruct(name(1:end-1), ignored_fields.acq)
                    pmt_parameters.pmt1.(name) = tif_struct.acq.(name);
                end
            else
                device_params.(name) = tif_struct.acq.(name);
            end
        
        end
    end
    
    %%TODO: fix
    addpath /Users/kiwiberry/Ovation/jayaraman-importer/yamlmatlab
    yaml_struct = ReadYaml(yamlFile);
    
    if tif_struct.acq.savingChannel1
        deviceName = 'pmt1';
        params = mergeStruct(pmt_parameters.pmt1, device_params);
        addResponse(deviceName, manufacturer, params, epoch, tif_struct, yaml_struct);  
    end
    if tif_struct.acq.savingChannel2
        deviceName = 'pmt2';
        params = mergeStruct(pmt_parameters.pmt2, device_params);
        addResponse(deviceName, manufacturer, params, epoch, tif_struct, yaml_struct);
    end
    if tif_struct.acq.savingChannel3
        deviceName = 'pmt3';
        params = mergeStruct(pmt_parameters.pmt3, device_params);
        addResponse(deviceName, manufacturer, params, epoch, tif_struct, yaml_struct); 
    end
    if tif_struct.acq.savingChannel4
        deviceName = 'pmt4';
        params = mergeStruct(pmt_parameters.pmt4, device_params);
        addResponse(deviceName, manufacturer, params, epoch, tif_struct, yaml_struct);
    end

    % empty response with url pointing to response

    function r = addResponse(deviceName, manufacturer, pmt_params, epoch, tif_struct, yaml)
        import ovation.*;

        pmt = epoch.getEpochGroup().getExperiment().externalDevice(deviceName, manufacturer);
        units = 'volts';% not quite volts - off by some scalar factor
        
        [XSamplingRate, XSamplingUnit, XLabel] = getXResolution(tif_struct, yaml);
        [YSamplingRate, YSamplingUnit, YLabel] = getYResolution(tif_struct, yaml);
        [ZSamplingRate, ZSamplingUnit, ZLabel] = getZResolution(tif_struct);
        dimensionLabels = {XLabel, YLabel, ZLabel};
        samplingRate = [XSamplingRate, YSamplingRate, ZSamplingRate];
        samplingRateUnits = {XSamplingUnit, YSamplingUnit, ZSamplingUnit};
        shape = [0, 0, 0]; %TODO: [tif_struct.acq.pixelsPerLine, tif_struct.acq.linesPerFrame, tif_struct.acq.numberOfZSlices];

        r = epoch.insertResponse(pmt,...
            struct2map(pmt_params),...
            NumericData([0, 0, 0], shape),...
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
        
        r.addProperty('filterColor', yaml.PMT.(deviceName));

    end

    function [resolution, units, label] = getXResolution(tif_struct, yaml)
        
        resolution = yaml.PMT.XFrameDistance / tif_struct.acq.pixelsPerLine;
        units = 'microns/pixel';
        label = 'X';
    end

    function [resolution, units, label] = getYResolution(tif_struct, yaml)
        if tif_struct.acq.linescan %%TODO is this right??
            resolution = tif_struct.acq.msPerLine + tif_struct.acq.scanDelay ;
            units = 'ms/line';
        else
            resolution = yaml.PMT.YFrameDistance / tif_struct.acq.linesPerFrame;
            units = 'microns/pixel';
        end
        label = 'Y';
    end
    
    function [resolution, units, label] = getZResolution(tif_struct)
        resolution = tif_struct.acq.zStepSize;
        units = 'microns/step';
        label = 'Z';
    end
    
    % no good set object in matlab ?? :(
    function inStruct = nameInStruct(name, s)
        try 
            s.(name); % if name is in struct, return 1
            inStruct = true;
            
        catch % if not, return 0
            inStruct = false;
        end
    end
end
