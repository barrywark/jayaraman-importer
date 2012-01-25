function epoch = AppendTifData(epoch,...
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
    
    tif_struct = scim_openTif(tifFile);
    %% linescan
    if tif_struct.acq.linescan
        % do other stuff
    end    
    
    %% check that start and end times for the epoch overlap with the tif file
    % get from tiff file? last modified timestamp?
    
    %% create tif response
    %device = epoch.getExperiment().externalDevice('', '');% scanimage name
    %and manufacturer. do we need this?
    
    device_params.software_version = tif_struct.software.version;
    device_params.software_version_minor_revision = tif_struct.software.minorRev;
    device_params.software_version_beta = tif_struct.software.beta;
    device_params.configName = tif_struct.configName;
    device_params.scanOffsetX = tif_struct.init.scanOffsetX;
    
    pmt_parameters = struct();
    acq_names = fieldnames(tif_struct.acq);
    for i=0:length(acq_names)
        name = acq_names(i);
        name = name{1};
        if name(end) == '1' 
            pmt_paramters.pmt1.(name) = tif_struct.acq.(name);
        elseif name(end) == '2'
            pmt_paramters.pmt2.(name) = tif_struct.acq.(name);
        elseif name(end) == '3'
            pmt_paramters.pmt3.(name) = tif_struct.acq.(name);
        elseif name(end) == '4'
            pmt_paramters.pmt4.(name) = tif_struct.acq.(name);
        else
            device_params.(name) = tif_struct.acq.(name);
        end  
    end
    
    if tif_struct.savingChanel1
        deviceName = 'pmt1';
        params = pmt_parameters.pmt1;
        addResponse(deviceName, manufacturer, params, tif_struct);   
    end
    if tif_struct.savingChanel2
        deviceName = 'pmt2';
        params = pmt_parameters.pmt2;
        addResponse(deviceName, manufacturer, params, tif_struct); 
    end
    if tif_struct.savingChanel3
        deviceName = 'pmt3';
        params = pmt_parameters.pmt3;
        addResponse(deviceName, manufacturer, params, tif_struct); 
    end
    if tif_struct.savingChanel4
        deviceName = 'pmt4';
        params = pmt_parameters.pmt4;
        addResponse(deviceName, manufacturer, params, tif_struct); 
    end

    function addResponse(deviceName, manufacturer, pmt_params, epoch, tif_struct)
        pmt = experiment.externalDevice(deviceName, manufacturer);
        units = 'volts'; %?
        dimensionLabels = ['X', 'Y', 'frame'];
        samplingRate = [tif_struct.acq.pixelsPerLine, tif_struct.acq.linesPerFrame, tif_struct.acq.frameRate];
        samplingRateUnits = ['pixels', 'pixels', 'Hz';
        r = epoch.insertResponse(pmt,...
            struct2map(pmt_params),...
            NumericData([0, 0, 0]),...
            units,...
            dimensionLabels;...
            samplingRate,...
            samplingRateUnits,...
            Response.TIFF_DATA_UTI); % empy response with url pointing to response
        %r.addProperty('__ovation_url', relativeUrlToFile);
        %r.addProperty('__ovation_retrieval_funcion', dataRetrievalFunction);
        %r.addProperty('__ovation_retrieval_parameters', {deviceName(end)}); %chanel number 
        %TODO: r.addProperty('filterColor', filterColor); %read filter color from text file
    end
end