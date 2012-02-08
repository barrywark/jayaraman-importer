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
    
    % Copyright (c) 2012 Physion Consulting LLC
        
    import ovation.*;
   
    [seq_struct, fid] = read_seq_header(seqFile);
    %TODO: get camera number and deriation_parameters from yaml file?
    device = epoch.getEpochGroup().getExperiment().externalDevice('camera1', 'manufacturer');
    derivation_params = struct();
    
    shape = [seq_struct.Height, seq_struct.Width];
    units = 'intensity';
    samplingRate = [seq_struct.FrameRate, seq_struct.Width, seq_struct.Height];
    samplingRateUnits = {'Hz', 'pixels', 'pixels'}; % I'm assuming
    dimensionLabels = {'Width', 'Height'};
    r = epoch.insertResponse(device,...
            struct2map(derivation_params),...
            NumericData([0, 0, 0], shape),...
            units,...
            dimensionLabels,...
            samplingRate,...
            samplingRateUnits,...
            'public.seq'); % is this right? 
        
    dataRetrievalFunction = 'read_seq_image';
    r.addProperty('__ovation_url', seqFile);
    r.addProperty('__ovation_retrieval_funcion', dataRetrievalFunction);
    r.addProperty('__ovation_retrieval_parameter1', seqFile);
    r.addProperty('__ovation_retrieval_parameter2', fid);
    
    r.addProperty('BitDepth', seq_struct.BitDepth);
    r.addProperty('BitDepthReal', seq_struct.BitDepthReal);
    r.addProperty('SizeBytes', seq_struct.SizeBytes);
    r.addProperty('ImageFormat', seq_struct.ImageFormat);
    r.addProperty('NumberFrames', seq_struct.NumberFrames);
    r.addProperty('TrueImageSize', seq_struct.TrueImageSize); %?
        
end
