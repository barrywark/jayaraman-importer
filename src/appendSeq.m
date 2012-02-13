function epoch = appendSeq(epoch,...
        seqFile,...
        seqConfig)
    
    % Add Stimuli and Response information contained in a tif file, to a given Epoch. Return the updated Epoch.
    %
    %    epoch = appendSeq(epoch, seqFile, yamlFile)
    %
    %      epoch: ovation.Epoch object. The Epoch to attach the Response
    %      and Stimulus to.
    %
    %      seqFile: path to the generated .SEQ file
    %
    %      seqConfig: Struct describing seq capture configuration.
    
    % Copyright (c) 2012 Physion Consulting LLC
    
    import ovation.*;
    
    [seq_struct, ~] = read_seq_header(seqFile);
    %TODO: get camera number and device_parameters from yaml file?
    device = epoch.getEpochGroup().getExperiment().externalDevice('camera1',...
        seqConfig.cameraManufacturer);
    device_params = struct();
    
    shape = [seq_struct.Width, seq_struct.Height];
    units = 'intensity (a.u.)';
    samplingRate = [seq_struct.FrameRate,...
        seqConfig.samplingRateX,...
        seqConfig.samplingRateY];
    
    samplingRateUnits = {'Hz',...
        seqConfig.samplingRateUnitsX,...
        seqConfig.samplingRateUnitsY};
    dimensionLabels = {'Frame Number', 'Width', 'Height'};
    
    url = java.io.File(seqFile).toURI().toURL().toExternalForm();
    
    intByteSize = 1; % data is uint8
    data_type = NumericDataType(NumericDataFormat.UnsignedIntegerDataType,...
        intByteSize,...
        NumericByteOrder.ByteOrderNeutral);
    
    r = epoch.insertURLResponse(device,...
        struct2map(device_params),...
        url,...
        shape,...
        data_type,...
        units,...
        dimensionLabels,...
        samplingRate,...
        samplingRateUnits,...
        'org.hhmi.jayaraman.seq');
    
    r.addProperty('BitDepth', seq_struct.BitDepth);
    r.addProperty('BitDepthReal', seq_struct.BitDepthReal);
    r.addProperty('SizeBytes', seq_struct.SizeBytes);
    r.addProperty('ImageFormat', seq_struct.ImageFormat);
    r.addProperty('NumberFrames', seq_struct.NumberFrames);
    r.addProperty('TrueImageSize', seq_struct.TrueImageSize); %?
    
end
