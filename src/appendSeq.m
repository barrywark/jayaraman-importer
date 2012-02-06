function epoch = appendSeq(epoch,...
                               seqFile,...
                               yamlFile)
                                      
    % Add Stimuli and Response information contained in a tif file, to a given Epoch. Return the updated Epoch. 
    %
    %    epoch = appendSeq(epoch, seqFile, yamlFile)
    %                                 
    %      epoch: ovation.Epoch object. The Epoch to attach the Response
    %      and Stimulus to. 
    %
    %      seqFile: path to the generated .SEQ file
    %
    %      yamlFile: path to the user-defined yamlfile. This file contains
    %      a camera name and manufacturer for the camera used to generate
    %      this seq file.
        
    import ovation.*;
   
    [seq_struct, ~] = read_seq_header(seqFile);
    %TODO: get camera number and device_parameters from yaml file?
    device = epoch.getEpochGroup().getExperiment().externalDevice('camera1', 'manufacturer');
    device_params = struct();
    
    shape = [seq_struct.Width, seq_struct.Height];
    units = 'N/A';%% what goes here?
    samplingRate = [seq_struct.FrameRate, seq_struct.FrameRate];
    samplingRateUnits = {'Hz','Hz'}; 
    dimensionLabels = {'Width', 'Height'}; 
        
    f = java.io.File(seqFile);
    uri = f.toURI(); % does the escaping properly
    url = uri.toURL();
    
    data_type = NumericDataType(NumericDataFormat.UnsignedIntegerDataType, 8, NumericByteOrder.ByteOrderBigEndian);%% Is this right?
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
        
    dataRetrievalFunction = 'read_seq_image';
    r.addProperty('__ovation_retrieval_function', dataRetrievalFunction);
    
    r.addProperty('BitDepth', seq_struct.BitDepth);
    r.addProperty('BitDepthReal', seq_struct.BitDepthReal);
    r.addProperty('SizeBytes', seq_struct.SizeBytes);
    r.addProperty('ImageFormat', seq_struct.ImageFormat);
    r.addProperty('NumberFrames', seq_struct.NumberFrames);
    r.addProperty('TrueImageSize', seq_struct.TrueImageSize); %?
        
end
