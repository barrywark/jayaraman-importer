function epoch = appendScanImageTiff(epoch,...
                               tifFile)
                                      
    % Add Stimuli and Response information contained in a tif file, to a given Epoch. Return the updated Epoch. 
    %
    %    epoch = AppendTifData(epoch, tifFile)
    %                                 
    %      epoch: ovation.Epoch object. The Epoch to attach the Response
    %      and Stimulus to. 
    %
    %      tifFile: path to .TIF file
        
    import ovation.*;
    
    %nargchk(4, 5, nargin); %#ok<NCHKI>
    %if(nargin < 4)
    %    ntrials = [];
    %end
    
    tif_struct = scim_openTif(tifFile, 'header');   
    manufacturer = 'pmt_manufacturer'; % fix
    
    %% check that start and end times for the epoch overlap with the tif file
    % get from tiff file? last modified timestamp?
    
    %% create tif response
    
    device_params.software_version = tif_struct.software.version;
    device_params.software_version_minor_revision = tif_struct.software.minorRev;
    device_params.software_version_beta = tif_struct.software.beta;
    device_params.configName = tif_struct.configName;
    device_params.scanOffsetX = tif_struct.init.scanOffsetX;
    
    pmt_parameters = struct();
    acq_names = fieldnames(tif_struct.acq);
    %disp(acq_names);
    for i=1:length(acq_names)
        name = acq_names(i);
        %disp(name);
        name = name{1};
        %disp(name);
        if name(end) == '1' 
            %disp('here')
            pmt_parameters.pmt1.(name) = tif_struct.acq.(name);
        elseif name(end) == '2'
            pmt_parameters.pmt2.(name) = tif_struct.acq.(name);
        elseif name(end) == '3'
            pmt_parameters.pmt3.(name) = tif_struct.acq.(name);
        elseif name(end) == '4'
            pmt_parameters.pmt4.(name) = tif_struct.acq.(name);
        else
            device_params.(name) = tif_struct.acq.(name);
        end  
    end
    %disp(pmt_parameters);
    
    
    if tif_struct.acq.savingChannel1
        deviceName = 'pmt1';
        params = pmt_parameters.pmt1;
        addResponse(deviceName, manufacturer, params, epoch, tif_struct);   
    end
    if tif_struct.acq.savingChannel2
        deviceName = 'pmt2';
        params = pmt_parameters.pmt2;
        addResponse(deviceName, manufacturer, params, epoch, tif_struct); 
    end
    if tif_struct.acq.savingChannel3
        deviceName = 'pmt3';
        params = pmt_parameters.pmt3;
        addResponse(deviceName, manufacturer, params, epoch, tif_struct); 
    end
    if tif_struct.acq.savingChannel4
        deviceName = 'pmt4';
        params = pmt_parameters.pmt4;
        addResponse(deviceName, manufacturer, params, epoch, tif_struct); 
    end

    % empty response with url pointing to response
    function addResponse(deviceName, manufacturer, pmt_params, epoch, tif_struct)
        
        import ovation.*;
        
        pmt = epoch.getEpochGroup().getExperiment().externalDevice(deviceName, manufacturer);
        units = 'volts'; %?
        
        frameDimensionLabel = 'time'; % or space?
        frameSamplingRate = tif_struct.acq.frameRate;
        frameSamplingUnit = 'Hz'; % kHz?
        
        % ask about zstep
        
        % why are pixelsPerline and linesPerFrame swapped, are they
        % appropriately named X and Y?
        [XSamplingRate, XSamplingUnit, XLabel] = getXResolution(tif_struct);
        [YSamplingRate, YSamplingUnit, YLabel] = getYResolution(tif_struct);
        dimensionLabels = [XLabel, YLabel, frameDimensionLabel];
        samplingRate = [XSamplingRate, YSamplingRate, frameSamplingRate];
        samplingRateUnits = {XSamplingUnit, YSamplingUnit, frameSamplingUnit};
        r = epoch.insertResponse(pmt,...
            struct2map(pmt_params),...
            NumericData([0, 0, 0]),...
            units,...
            dimensionLabels,...
            samplingRate,...
            samplingRateUnits,...
            Response.TIFF_DATA_UTI); 
        dataRetrievalFunction = 'scm_openTif';
        %r.addProperty('__ovation_url', relativeUrlToFile);
        r.addProperty('__ovation_retrieval_funcion', dataRetrievalFunction);
        disp(tifFile);
        r.addProperty('__ovation_retrieval_parameters1', tifFile);
        r.addProperty('__ovation_retrieval_parameters2', deviceName(end)); % by chanel number? 
        %TODO: r.addProperty('filterColor', filterColor); %read filter color from text file
    end

    function [resolution, units, label] = getXResolution(tif_struct)
        resolution = tif_struct.acq.pixelsPerLine;
        units = 'cm? pixels?'; % ask about this
        label = 'X'; %?
    end

    function [resolution, units, label] = getYResolution(tif_struct)
        resolution = tif_struct.acq.linesPerFrame;
        units = 'cm? pixels?'; % ask about this
        label = 'Y'; %?
    end
end