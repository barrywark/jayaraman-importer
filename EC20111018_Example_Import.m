% Trial 001

%% Setup
import ovation.*


% ec20111018 is a struct array for trials in the ec20111018 example dataset.
% Each element represents 1 trial. Epoch information is required. The
% other components are optional. Missing components will be skipped during import
% (e.g. a missing XSG field will skip XSG import for that given Epoch)

%% Epoch information

% Start and end times. This shows the start time from the XSG
% header.acquirer.triggerTime and calculates the endTime by adding
% header.acquirer.traceLength to startTime.
ec20111018.epochStartTime = datetime(2011, 10, 18, 12, 31, 26, 619, 'America/New_York');
ec20111018.epochEndTime = ec20111018.epochStartTime.plusMillis(1000* 42.030);

ec20111018.protocolID = 'ec.pattern-3-wide'; % ProtocolID identifies similar trials by type

% These become the protocolParameters of the inserted Epoch. Parameters and
% values likely come from the experiment controlling .m file. These are
% taken from Sung Soo's experiment_attention_v0 as an example only.

% Defined somewhere in experiment_attention_v0
offset_str = 'offset';
osc_per_str = 'osc_per';
osc_amp_str = 'osc_amp';
sh_str = 'sh';
osc_offset_str = 'osc_offset';

% Protocol parameters
ec20111018.protocolParameters.id = [offset_str ',' osc_per_str ',' osc_amp_str ',' sh_str ',' osc_offset_str];
ec20111018.protocolParameters.luminance = offset_str;
ec20111018.protocolParameters.oscillation_period = 1;
ec20111018.protocolParameters.oscillation_amplitude = 1;
ec20111018.protocolParameters.time_to_shift_one_pixel = 1;
ec20111018.protocolParameters.oscillation_side = osc_offset_str;
ec20111018.protocolParameters.pattern_filename = 'some_pattern';
ec20111018.protocolParameters.IIIIIIIIIIIIIIIIIIIIIIIIIIII = 'IIIIIIIIIIIIIIIIIIIIIIIIIIII';
ec20111018.protocolParameters.function_freq = 100;
ec20111018.protocolParameters.initial_static_pos_x = 1;
ec20111018.protocolParameters.initial_static_pos_y = 1;
ec20111018.protocolParameters.initial_static_duration = 1;
ec20111018.protocolParameters.oscillation_init_x = 1;
ec20111018.protocolParameters.oscillation_init_y = 0;
ec20111018.protocolParameters.oscillation_duration = 10;
ec20111018.protocolParameters.oscillation_function_name = 'oscilation function';
ec20111018.protocolParameters.pause_duration = 0.65;
ec20111018.protocolParameters.shift_init_x = 1;
ec20111018.protocolParameters.shift_init_y = 5;
ec20111018.protocolParameters.shift_duration = 1;
ec20111018.protocolParameters.shifting_function = [1,2,3];
ec20111018.protocolParameters.shifting_function_name = 'shifting function';
ec20111018.protocolParameters.finish_pos_x = 1;
ec20111018.protocolParameters.finish_pos_y = 1;
ec20111018.protocolParameters.finish_period = 1;

%% Stimulus informatoin (pattern)

% Pattern and generating .m file (added as Resources)
ec20111018.stimulus.patternFile = 'test/fixtures/EC20111018/patterns/PatternNew_4WideStripesGlobalToSingle_CL_4.mat';
ec20111018.stimulus.patternGenerationFunction = 'test/fixtures/EC20111018/patterns/Pattern_3_Wide_Starting_At_0.m';

% Pattern parameters => Stimulus.stimulusParameters.
% E.g. taken from Pattern_3_Wide_Starting_At_0.m. Any parameters that you
% want to be easily queriable should go here, even if they are duplicated
% in the pattern .mat.
ec20111018.stimulus.patternParameters.x_num = 56; 	% There are 96 pixel around the display (12x8) 
ec20111018.stimulus.patternParameters.y_num = 1; 		% two frames of Y, at 2 different spatial frequencies
ec20111018.stimulus.patternParameters.num_panels = 14; 	% This is the number of unique Panel IDs required.
ec20111018.stimulus.patternParameters.gs_val = 3; 	% This pattern will use 8 intensity levels
ec20111018.stimulus.patternParameters.row_compression = 1;

% Mapping from SD card to Pattern. Stored as stimulusParameters
% TODO: what are the types here?
ec20111018.stimulus.SDcard = containers.Map('KeyType', 'int32', 'ValueType', 'char');
ec20111018.stimulus.SDcard(int32(1)) = 'pattern ID1';
ec20111018.stimulus.SDcard(int32(2)) = 'pattern ID1';


% Arena configuration file (added as Resource).
% If this is a MAT file with a struct, we can add it as deviceParameters to
% make this configuration searchable
%ec20111018.stimulus.arenaConfigurationFile = '...';
ec20111018.stimulus.arenaConfigurationName = '3-wide'; % => deviceParameter

% The presented sequence (ec20111018.xsg.xsgFileName must be present)
ec20111018.stimulus.xsgXSequenceChannel = 'XSignalArena'; % name of xsg channel
ec20111018.stimulus.xsgYSequenceChannel = 'YSignalArena'; % name of xsg channel

%(optional)
ec20111018.stimulus.frameNumber = []; % Vector of frame numbers

% Device parameters
ec20111018.stimulus.controllerMode = 1;
ec20111018.stimulus.controllerParameters = struct(); %Struct of additional controller parameters
ec20111018.stimulus.firmwareVersion = 1;


%% Response data (non-Ephus)

% (optional) DAQ responses recorded directly via NiDAQ driver
ec20111018.responses.channel1Name.deviceParameters = struct();
ec20111018.responses.channel1Name.sampleRateHz = 1000;

% To store data in Ovation
ec20111018.responses.channel1Name.data = []; % Vector of data

% To store data on file system
% ec20111018.responses.channel1Name.dataFilePath = 'path to data file';
% ec20111018.responses.channel1Name.dataStart = startIndex;
% ec20111018.responses.channel1Name.dataEnd = endIndex;


%% XSG

ec20111018.xsg.xsgFilePath = 'test/fixtures/EC20111018/Imaging/AA0001AAAA0001.xsg';

% Mapping from XSG channel name to desired channel name
channelNameMap = containers.Map();
channelNameMap('TreadmillTrigger') = 'TreadmillTrigger';
channelNameMap('XSignalArena') = 'XSignalArena';
channelNameMap('XPositionArenaCL') = 'XPositionArenaCL';
channelNameMap('YSignalArena') = 'YSignalArena';
channelNameMap('CameraTrigger') = 'CameraTrigger';

ec20111018.xsg.channelNameMap = channelNameMap;

%% Imaging (ScanImage)

ec20111018.scanImage.scanImageTIFFPath = 'test/fixtures/EC20111018/Imaging/c232_GC3_rightLT_trial_001.tif';
ec20111018.scanImage.scanImageConfigYAMLPath = 'test/fixtures/EC20111018/ScanImage_config.yaml';

%% SEQ

% There is no SEQ file for the example data set
% ec20111018.seq.seqFilePath = 
% ec20111018.seq.seqConfigYAMLPath = 

%% Run the import
% Aassuming experiment (an ovation.Experiment) and context (an ovation.DataContext) exists in the workspace

srcs = context.getSources('none');
if(numel(srcs) > 0)
    blankSource = srcs(1);
else
    blankSource = context.insertSource('none');
end

fly = context.insertSource('fly');
fly.addProperty('flyID', 'ID-in-the-fly-database');

sessionGroup = experiment.insertEpochGroup(blankSource, 'session', ec20111018.epochStartTime);
flyGroup = experiment.insertEpochGroup(fly, 'fly', ec20111018.epochStartTime);

ImportJayaramanTrials(flyGroup, ec20111018);
