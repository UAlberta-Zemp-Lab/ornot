addpath("..");
%% Depends on commit 33162b of VBI
addpath(genpath("../../../Verasonics-Biasing-Imaging/src/"));
%% Depends on commit 9b2324 of UB
addpath(genpath("../../../Verasonics-Biasing-Imaging/Ultrasound-Beamforming/src/"));
addpath(genpath("../../../Verasonics-Biasing-Imaging/Ultrasound-Beamforming/util/"));

warning('off', 'MATLAB:class:LoadInvalidDefaultElement');
warning('off', 'MATLAB:load:classNotFound');

global failures;
failures = [];
ornot.LoadLibraries;

directory = "C:\Users\darren\GoogleDrive\Shared drives\Zemp Lab Shared Drive\Zemplab Backup\Ultrasound Data\HERCULES\";

replaceData = false;

if replaceData
    vrsFiles = dir(strcat(directory, "/**/*.vrs"));

    for i = 1:numel(vrsFiles)
        vrsFilename = fullfile(vrsFiles(i).folder, vrsFiles(i).name);
        vrsFile = VRSFile(vrsFilename);
        data = vrsFile.GetData();
        newVrsFilename = strrep(vrsFilename, "vrs", "zst");
        newVrsFilename = strrep(newVrsFilename, "_Intensity", "");
        assert(strcmpi(vrsFile.DataType, "int16"));
        assert(calllib('ornot', 'write_data_with_zstd_compression', char(newVrsFilename), ...
            data, 2*numel(data)), "Writing Compressed Data Failed!");
    end
end

filesetMarkers = dir(strcat(directory, "/**/postVsx.mat"));
filesets = strings(numel(filesetMarkers),2);
for i = 1:numel(filesetMarkers)
    [folderPath, name, ~] = fileparts(string(filesetMarkers(i).folder));
    filesets(i, :) = [folderPath, name];
end

for i = 35:numel(filesets)
    process_fileset(filesets(i, 1), filesets(i, 2));
end

function process_fileset(directory, fileset_name)
realDirectory = fullfile(directory, fileset_name);
create_old_file(realDirectory);
vsx_filename = fullfile(realDirectory, "postVsx.mat");
vsx_mat = load(vsx_filename);
vsx = vsx_mat.vsx;

global failures;

if exist(fullfile(realDirectory, sprintf("%s_00.zst", fileset_name)))
    compression_mode = ZBP.DataCompressionKind.ZSTD;
elseif exist(fullfile(realDirectory, sprintf("%s_00.bin", fileset_name)))
    compression_mode = ZBP.DataCompressionKind.None;
else
    w = sprintf("Failed to process %s. Data File missing!", vsx.Filename);
    failures = [failures;w];
    return
end

settings = ornot.BeamformSettings;
% settings.regions = [
%     ornot.Region.CreateXZPlane([512, 512], 50e-3*[-1, 1], [20, 100]*1e-3)
%     ornot.Region.CreateYZPlane([512, 512], 50e-3*[-1, 1], [20, 100]*1e-3)
%     ];
settings.regions = [
    ornot.Region.CreateXZPlane([512, 512], 80e-3*[-1, 1], [0, 165]*1e-3)
    ornot.Region.CreateYZPlane([512, 512], 80e-3*[-1, 1], [0, 165]*1e-3)
    ];

settings.interpolation_mode = OGLBeamformerInterpolationMode.Linear;
settings.receive_fnumber = 0.5;
settings.coherency_weighting = false;
settings.decimation_rate = 1;
settings.compute_stages = [
    % OGLBeamformerShaderStage.Demodulate, ...
    OGLBeamformerShaderStage.Decode, ...
    OGLBeamformerShaderStage.DAS
    ];
settings.average_frame = 1;

[bp, success, w] = convert(vsx, compression_mode);
if ~success
    failures = [failures;w];
    return
end
sprintf("Suceeded in processing %s!", vsx.Filename);

for i = 0:settings.average_frame - 1
    data_filename = fullfile(realDirectory, sprintf("%s_%02g.zst", fileset_name, i));
    bp = ornot.GetData(bp, data_filename);
    % tempBp = chirpFilter(bp, vsx);
    % tempBp = hilbertFilter(bp, vsx);
    image = ornot.beamform(bp, settings);
end
% bp = tempBp;
% bp.raw_data_kind = ZBP.DataKind.Float32Complex;
bp.data = [];
bytes = bp.ToBytes();

%% Write
% hilbertDir = fullfile(realDirectory, "hilbert");
% mkdir(hilbertDir);
% newFilename = fullfile(hilbertDir, sprintf("%s.bp", fileset_name));

newFilename = fullfile(realDirectory, sprintf("%s.bp", fileset_name));

fileId = fopen(newFilename, 'w');
fwrite(fileId, bytes);
fclose(fileId);
end

function create_old_file(directory)

bpFiles = dir(strcat(directory, "/*.bp"));
for i = 1:numel(bpFiles)
    copyfile(fullfile(directory, bpFiles(i).name), fullfile(directory, strcat(bpFiles(i).name, "1")));
end
end

function [bp, success, w] = convert(vsx, compressionKind)
arguments(Input)
    vsx (1,1) VsxDirector
    compressionKind(1,1) ZBP.DataCompressionKind
end
arguments(Output)
    bp (1,1) ornot.BeamformParameters
    success(1,1) logical
    w
end
bp = ornot.BeamformParameters;
success = false;
w = [];

scan = vsx.Scan;
die = scan.Die;
dieSize = die.Size();

Trans = vsx.Trans;
Receive = vsx.Receive;

rcvBuffer = vsx.Resource.RcvBuffer;

txEvents = scan.TransmitEvents;
excitation = txEvents(1).Excitation;
transmitOrientation = txEvents(1).ImagingPattern.TransmitOrientation;
receiveOrientation = txEvents(1).ImagingPattern.ReceiveOrientation;

if (isempty(scan.TransmitsPerFrame))
    transmitCount = scan.AcquisitionCount;
else
    transmitCount = scan.TransmitsPerFrame;
end

bp.raw_data_dimension = [rcvBuffer.rowsPerFrame, rcvBuffer.colsPerFrame, 1, 1];
bp.raw_data_kind = ZBP.DataKind.Int16;
bp.raw_data_compression_kind = compressionKind;
bp.decode_mode = ZBP.DecodeMode.Hadamard;
bp.sampling_mode = ZBP.SamplingMode.Standard;
bp.sampling_frequency = single(Receive(1).samplesPerWave*Trans.frequency*1e6);
bp.demodulation_frequency = die.CenterFrequency;
bp.speed_of_sound = scan.SpeedOfSound;
bp.sample_count = Receive(1).endSample - Receive(1).startSample + 1;
bp.channel_count = receiveOrientation.GetElementCount(die);
if transmitCount > 256
    w = sprintf("Failed to process %s. Transmit Count exceeds 256 (%d)!", vsx.Filename, transmitCount);
    return
end
bp.receive_event_count = transmitCount;
transducer_transform_matrix = single([...
    1,0,0,dieSize(1)/2;
    0,1,0,dieSize(2)/2;
    0,0,1,0;
    0,0,0,1;
    ]);
bp.transducer_transform_matrix = transducer_transform_matrix(:);
bp.transducer_element_pitch = die.Pitch;
bp.group_acquisition_time = scan.PulseRepetitionInterval * transmitCount; % Not certain if this includes the biasing wait time, but probably does

bp.channel_mapping = Trans.ConnectorES(receiveOrientation.GetElements(die)) - 1;

bp.emission_descriptor = ZBP.EmissionDescriptor;
switch class(excitation)
    case "acquisition.SineExcitation"
        bp.emission_descriptor.emission_kind = int32(ZBP.EmissionKind.Sine);
        bp.emission_parameters = ZBP.EmissionSineParameters;
        bp.emission_parameters.cycles = excitation.CycleCount;
        bp.emission_parameters.frequency = excitation.Frequency;
        bp.time_offset = bp.time_offset + excitation.CycleCount / excitation.Frequency;
    case "acquisition.ChirpExcitation"
        % Any Use of Chirp Excitations prior to June 8th, 2025
        % accidently has the bandwidth hardcoded to 4 MHz about the die's center frequency
        bp.emission_descriptor.emission_kind = int32(ZBP.EmissionKind.Chirp);
        bp.emission_parameters = ZBP.EmissionChirpParameters;
        bp.emission_parameters.duration = excitation.Duration;
        bp.emission_parameters.min_frequency = excitation.Frequency - 2e6;
        bp.emission_parameters.max_frequency = excitation.Frequency + 2e6;
        bp.time_offset = bp.time_offset + excitation.Duration / 2;
        % bp.demodulation_frequency = excitation.Frequency;
    otherwise
        w = sprintf("Failed to process %s. Invalid Excitation!", vsx.Filename);
        return
end

if scan.BeamformMode ~= acquisition.BeamformModes.INVALID
    switch scan.BeamformMode
        case acquisition.BeamformModes.FORCES
            bp.acquisition_kind = ZBP.AcquisitionKind.FORCES;
        case acquisition.BeamformModes.UFORCES
            bp.acquisition_kind = ZBP.AcquisitionKind.UFORCES;
        case acquisition.BeamformModes.HERCULES
            bp.acquisition_kind = ZBP.AcquisitionKind.HERCULES;
        case acquisition.BeamformModes.RCA_VLS
            bp.acquisition_kind = ZBP.AcquisitionKind.RCA_VLS;
        case acquisition.BeamformModes.RCA_TPW
            bp.acquisition_kind = ZBP.AcquisitionKind.RCA_TPW;
        otherwise
            w = sprintf("Failed to process %s Invalid Mode!", vsx.Filename);
            return
    end
else
    if contains(vsx.Filename, "UFORCES", "IgnoreCase",true)
        bp.acquisition_kind = ZBP.AcquisitionKind.UFORCES;
    elseif contains(vsx.Filename, "FORCES", "IgnoreCase",true)
        bp.acquisition_kind = ZBP.AcquisitionKind.FORCES;
    elseif contains(vsx.Filename, "HERCULES", "IgnoreCase",true)
        bp.acquisition_kind = ZBP.AcquisitionKind.HERCULES;
    elseif contains(vsx.Filename, "VLS", "IgnoreCase",true)
        bp.acquisition_kind = ZBP.AcquisitionKind.RCA_VLS;
    elseif contains(vsx.Filename, "TPW", "IgnoreCase",true)
        bp.acquisition_kind = ZBP.AcquisitionKind.RCA_TPW;
    else
        w = sprintf("Failed to process %s. Invalid Mode!", vsx.Filename);
        return
    end
end


bp.time_offset = bp.time_offset - (Receive(1).startDepth*2 / (Trans.frequency*1e6));
switch(bp.acquisition_kind)
    case {ZBP.AcquisitionKind.FORCES, ZBP.AcquisitionKind.UFORCES}
        bp.time_offset = bp.time_offset + calculateCylindricalFocusedTransmitDelays(...
            [0,0,0],txEvents(1).GetFocusPositions(), txEvents(1).FocusTime, ...
            transmitOrientation, scan.SpeedOfSound); % This calculation presumes that the group does not hold transmits for both orientations of a non-square die
    case {ZBP.AcquisitionKind.HERCULES, ZBP.AcquisitionKind.RCA_VLS, ZBP.AcquisitionKind.RCA_TPW}
        if ~isinf(txEvents(1).FocusTime)
            bp.time_offset = bp.time_offset + txEvents(1).FocusTime;
        else
            w = sprintf("Failed to process %s. Infinte Focus Time!", vsx.Filename);
            return
        end
end

switch bp.acquisition_kind
    case ZBP.AcquisitionKind.FORCES
        acquisition_parameters(bp.raw_data_dimension(3)) = ZBP.FORCESParameters;
    case ZBP.AcquisitionKind.UFORCES
        acquisition_parameters(bp.raw_data_dimension(3)) = ZBP.uFORCESParameters;
    case ZBP.AcquisitionKind.HERCULES
        acquisition_parameters(bp.raw_data_dimension(3)) = ZBP.HERCULESParameters;
    case ZBP.AcquisitionKind.RCA_VLS
        acquisition_parameters = ZBP.VLSParameters;
        bp.focal_depths = zeros(1, bp.receive_event_count, "single");
        bp.origin_offsets = zeros(1, bp.receive_event_count, "single");
        for i = 1:bp.receive_event_count
            focus_position = txEvents(i).GetFocusPositions();
            bp.focal_depths(i) = focus_position(3);
            if txEvents(i).ImagingPattern.TransmitOrientation == tobe.Orientation.Column
                bp.origin_offsets(i) = focus_position(1);
            else
                bp.origin_offsets(i) = focus_position(2);
            end
        end
    case ZBP.AcquisitionKind.RCA_TPW
        acquisition_parameters = ZBP.TPWParameters;
        bp.tilting_angles = single([txEvents.SteeringAngle]);
end

if bp.acquisition_kind == ZBP.AcquisitionKind.FORCES || bp.acquisition_kind == ZBP.AcquisitionKind.HERCULES ...
        || bp.acquisition_kind == ZBP.AcquisitionKind.UFORCES
    acquisition_parameters.transmit_focus.focal_depth = txEvents.FocalDepth;
    acquisition_parameters.transmit_focus.steering_angle = txEvents.SteeringAngle;
    if transmitOrientation == tobe.Orientation.Row
        tx_orientation = ZBP.RCAOrientation.Rows;
    elseif transmitOrientation == tobe.Orientation.Column
        tx_orientation = ZBP.RCAOrientation.Columns;
    end
    if receiveOrientation == tobe.Orientation.Row
        rx_orientation = ZBP.RCAOrientation.Rows;
    elseif receiveOrientation == tobe.Orientation.Column
        rx_orientation = ZBP.RCAOrientation.Columns;
    end
    acquisition_parameters.transmit_focus.transmit_receive_orientation = ornot.packTransmitReceiveOrientation(tx_orientation, rx_orientation);
end

assert(exist("acquisition_parameters", "var"), "Unsupported acquisition mode!");
bp.acquisition_parameters = acquisition_parameters;

if bp.acquisition_kind == ZBP.AcquisitionKind.RCA_VLS || bp.acquisition_kind == ZBP.AcquisitionKind.RCA_TPW
    tx_orientations = createArray(1, bp.receive_event_count, "ZBP.RCAOrientation");
    rx_orientations = createArray(1, bp.receive_event_count, "ZBP.RCAOrientation");
    for i = 1:bp.receive_event_count
        if txEvents(i).ImagingPattern.TransmitOrientation == tobe.Orientation.Row
            tx_orientations(i) = ZBP.RCAOrientation.Rows;
        elseif txEvents(i).ImagingPattern.TransmitOrientation == tobe.Orientation.Column
            tx_orientations(i) = ZBP.RCAOrientation.Columns;
        end
        if txEvents(i).ImagingPattern.ReceiveOrientation == tobe.Orientation.Row
            rx_orientations(i) = ZBP.RCAOrientation.Rows;
        elseif txEvents(i).ImagingPattern.ReceiveOrientation == tobe.Orientation.Column
            rx_orientations(i) = ZBP.RCAOrientation.Columns;
        end
    end
    bp.transmit_receive_orientations = ornot.packTransmitReceiveOrientation(tx_orientations, rx_orientations);
end

if bp.acquisition_kind == ZBP.AcquisitionKind.UFORCES
    saveBuilder = [];
    for i = 1:numel(vsx.builders)
        if strcmpi(class(vsx.builders(i)), "SaveProcess")
            saveBuilder = vsx.builders(i);
            break
        end
    end

    if ~isempty(saveBuilder) && ~isempty(saveBuilder.sparseElements)
        bp.sparse_elements = uint16(saveBuilder.sparseElements);
    else
        bp.sparse_elements = uint16(linspace(1, double(transmitOrientation.GetElementCount(die)), bp.receive_event_count - 1));
    end
end

success = true;
end

function bp = chirpFilter(bp, vsx)
arguments(Input)
    bp (1,1) ornot.BeamformParameters
    vsx(1,1) VsxDirector
end
arguments(Output)
    bp (1,1) ornot.BeamformParameters
end

filterFs = 250e6;
impulseResponse = vsx.Scan.Die.GetImpulseResponse(filterFs);
excitation = vsx.Scan.TransmitEvents(1).Excitation;
matchedFilter = excitation.GetMatchedFilter(filterFs, impulseResponse);
matchedFilter = matchedFilter.*chebwin(length(matchedFilter), 90)';

filterL = 2^(nextpow2(numel(matchedFilter)) + 3);
filterAxis = filterFs/filterL*(0:filterL-1);
filterFft = fft(matchedFilter', filterL)/sum(abs(matchedFilter'));

for i = 1:bp.receive_event_count
    samples = (i - 1) * bp.sample_count + (1:bp.sample_count);
    acq = bp.data(samples, :);
    if (true)
        %% conv
        [p, q] = rat(filterFs/bp.sampling_frequency);
        acq = resample(single(acq), p, q);
        filteredAcq = convn(acq, reshape(matchedFilter', [],1), 'full')/sum(abs(matchedFilter'));
        filteredAcq = resample(filteredAcq, q, p);
    else
        %% fft
        dataL = 2^(nextpow2(size(acq, 1)) + 2);
        dataAxis = bp.sampling_frequency/dataL*(0:dataL-1);
        dataFft = fft(single(acq), dataL, 1);
        filteredDataFft = dataFft.*interp1(filterAxis, filterFft, dataAxis', 'cubic');
        filteredAcq = ifft(filteredDataFft, dataL, 1,"symmetric");
    end

    bp.data(samples, :) = filteredAcq(1:bp.sample_count, :);
end
bp.time_offset = bp.time_offset + excitation.Duration / 2;
bp.demodulation_frequency = excitation.Frequency;
bp.emission_descriptor.emission_kind = int32(ZBP.EmissionKind.Sine);
bp.emission_parameters = ZBP.EmissionSineParameters;
bp.emission_parameters.cycles = 1;
bp.emission_parameters.frequency = excitation.Frequency;

end

function bp = hilbertFilter(bp, vsx)
arguments(Input)
    bp (1,1) ornot.BeamformParameters
    vsx(1,1) VsxDirector
end
arguments(Output)
    bp (1,1) ornot.BeamformParameters
end

data = complex(zeros(size(bp.data, 1), size(bp.data, 2), 'single'));
for i = 1:bp.receive_event_count
    samples = (i - 1) * bp.sample_count + (1:bp.sample_count);
    data(samples, :) = bp.data(samples,:);
end
bp.data = data;

bp.raw_data_kind = ZBP.DataKind.Float32Complex;
end