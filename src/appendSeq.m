function epoch = appendSeq(epoch,...
                               seqFile,...
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
    
    error(nargchk(4, 5, nargin)); %#ok<NCHKI>
    if(nargin < 5)
        failForBadResponseTimes = false;
    end

    [seq_struct, fid] = read_seq_header(seqFile); % what is fid?
    %TODO: get camera number and deriation_parameters from yaml file?
    device = epoch.getEpochGroup().getExperiment().externalDevice('camera1', 'manufacturer');
    derivation_parameters = struct();
    
    shape = [seq_struct.seq_struct.Height, seq_struct.Width];
    units = 'intensity';
    samplingRate = [seq_struct.FrameRate, seq_struct.Width, seq_struct.Height];
    samplingRateUnits = {'Hz', 'pixels', 'pixels'}; % I'm assuming
    dimensionLabels = {'Frame Number', 'Width', 'Height'};
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
    r.addProperty('__ovation_retrieval_parameter2', seq_struct);
    r.addProperty('__ovation_retrieval_parameter3', fid);
    
    r.addProperty('BitDepth', seq_struct.BitDepth);
    r.addProperty('BitDepthReal', seq_struct.BitDepthReal);
    r.addProperty('SizeBytes', seq_struct.SizeBytes);
    r.addProperty('ImageFormat', seq_struct.ImageFormat);
    r.addProperty('NumberOfFrames', seq_struct.NumberOfFrames);
    r.addProperty('TrueImageSize', seq_struct.TrueImageSize); %?
        
end
