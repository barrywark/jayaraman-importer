function epoch = appendTreadmill(epoch,...
                               treadmillFile,...
                               yamlFile)
                                      
    % Add Stimuli and Response information contained in a tif file, to a given Epoch. Return the updated Epoch. 
    %
    %    epoch = appendTreadmill(epoch, treadmillFile, yamlFile)
    %                                 
    %      epoch: ovation.Epoch object. The Epoch to attach the Response
    %      to.
    %
    %      treadmillFile: path to the generated .TXT file containing the
    %      Response data
    %
    %      yamlFile: path to the user-defined yamlfile. This file contains
    %      a camera name and manufacturer for each camera used to generate
    %      this .TXT file.
        
    import ovation.*;

    [~,~,deltaX1,...
        deltaY1,...
        deltaX2,...
        deltaY2,...
        surfaceQuality1,...
        surfaceQuality2,...
        highShutterSpeed1,...
        lowShutterSpeed1,...
        highShutterSpeed2,...
        lowShutterSpeed2] = textread(treadmillFile);
    
    
    
    %TODO: get camera number and deriation_parameters from yaml file?
    camera1_XY = epoch.getEpochGroup().getExperiment().externalDevice('camera1_XY', 'manufacturer');
    camera2_XY = epoch.getEpochGroup().getExperiment().externalDevice('camera2_XY', 'manufacturer');
    camera1_SurfaceQuality = epoch.getEpochGroup().getExperiment().externalDevice('camera1_SurfaceQuality', 'manufacturer');
    camera2_SurfaceQuality = epoch.getEpochGroup().getExperiment().externalDevice('camera2_SurfaceQuality', 'manufacturer');
    camera1_ShutterSpeed = epoch.getEpochGroup().getExperiment().externalDevice('camera1_ShutterSpeed', 'manufacturer');
    camera2_ShutterSpeed = epoch.getEpochGroup().getExperiment().externalDevice('camera2_ShutterSpeed', 'manufacturer');
    device_params = struct();
    device_params.zero_centered = 128;

    shutterSpeed1 = arrayfun(@(high, low) uint16(low) + high*(2^8), highShutterSpeed1, lowShutterSpeed1);
    shutterSpeed2 = arrayfun(@(high, low) uint16(low) + high*(2^8), highShutterSpeed2, lowShutterSpeed2);
    frameRate1 = median(shutterSpeed1);
    frameRate2 = median(shutterSpeed2);
    
    %% Insert the shutter speeds calculated per frame on each camera
    % 
    units = 'clock cycles';
    samplingRate = [frameRate1];
    samplingRateUnits = {'clock cycles'};
    dimensionLabels = {'Shutter Speed'};
    epoch.insertResponse(camera1_ShutterSpeed,...
            struct2map(device_params),...
            NumericData(shutterSpeed1),...
            units,...
            dimensionLabels,...
            samplingRate,...
            samplingRateUnits,...
            'org.hhmi.jayaraman.treadmill'); 
        
    samplingRate = [frameRate2];
    epoch.insertResponse(camera2_ShutterSpeed,...
            struct2map(device_params),...
            NumericData(shutterSpeed2),...
            units,...
            dimensionLabels,...
            samplingRate,...
            samplingRateUnits,...
            'org.hhmi.jayaraman.treadmill');
        
    clear shutterSpeed1;
    clear shutterSpeed2;
    
    %% Insert the data corresponding to the distance travelled by the fly since the previous frame
    %
    units = 'pixels'; % microns?
    samplingRate = [1, frameRate1];
    samplingRateUnits = {'pixels', 'clock cycles'};
    dimensionLabels = {'Delta XY', 'Time'};

    length = size(deltaX1, 1);
    shape = [length, 2];
    ndata = NumericData(reshape([deltaX1, deltaY1], 1, 2*length), shape);
    epoch.insertResponse(camera1_XY,...
            struct2map(device_params),...
            ndata,...
            units,...
            dimensionLabels,...
            samplingRate,...
            samplingRateUnits,...
            'org.hhmi.jayaraman.treadmill'); 
        
    samplingRate = [1, frameRate2];
    ndata = NumericData(reshape([deltaX2, deltaY2], 1, 2*length), shape);
    epoch.insertResponse(camera2_XY,...
            struct2map(device_params),...
            ndata,...
            units,...
            dimensionLabels,...
            samplingRate,...
            samplingRateUnits,...
            'org.hhmi.jayaraman.treadmill'); 
        
        
    %% Insert the surface quality information for each camera, calculated at each frame 
    units = 'N/A';% TODO: get right
    samplingRate = [frameRate1];
    samplingRateUnits = {'clock cycles'};
    dimensionLabels = {'Surface Quality'};
    epoch.insertResponse(camera1_SurfaceQuality,...
            struct2map(device_params),...
            NumericData(surfaceQuality1),...
            units,...
            dimensionLabels,...
            samplingRate,...
            samplingRateUnits,...
            'org.hhmi.jayaraman.treadmill'); 
        
    samplingRate = [frameRate2];
    epoch.insertResponse(camera2_SurfaceQuality,...
            struct2map(device_params),...
            NumericData(surfaceQuality2),...
            units,...
            dimensionLabels,...
            samplingRate,...
            samplingRateUnits,...
            'org.hhmi.jayaraman.treadmill'); 
        
end
