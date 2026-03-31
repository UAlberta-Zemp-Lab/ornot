ornot.LoadLibraries();

data_folder = "data\260305_MN32-4_Example_Data\";
filename = "260305_MN32-4_Example_Filename_TPW-128-10deg-Tx-Row-Chirp-2e-05";
% filename = "260305_MN32-4_Example_Filename_VLS-128-1deg-Tx-Column-Chirp-2e-05";
% filename = "260305_MN32-4_Example_Filename_TPW-128-10deg-Tx-Column-Chirp-2e-05";
% filename = "260305_MN32-4_Example_Filename_HERCULES-Diverging-DepthRatio-0.5-Tx-Row-Chirp-2e-05";
% filename = "260305_MN32-4_Example_Filename_HERCULES-Diverging-DepthRatio-0.5-Tx-Column-Chirp-2e-05";

% Cells should be coherently compounded
% filename = "260305_MN32-4_Example_Filename_OPTIMUS-9Angles-Tx-Row-Chirp-2e-05";
% filename = "260305_MN32-4_Example_Filename_OPTIMUS-9Angles-Tx-Column-Chirp-2e-05";

% Needs Specialized Processing
% filename = "260305_MN32-4_Example_Filename_FORCES-Walking-8-Tx-Row-Chirp-2e-05";
% filename = "260305_MN32-4_Example_Filename_FORCES-Walking-8-Tx-Column-Chirp-2e-05";

lateral_extent = 50e-3 * [-1, 1];
elevational_extent = 50e-3 * [-1, 1];
axial_extent   = 1e-3  * [20, 100];
resolution     = [256, 256, 256];

bp_filename = fullfile(data_folder, sprintf("%s.bp", filename));
fileId = fopen(bp_filename, 'r');
bytes = fread(fileId);
fclose(fileId);

bp = ornot.BeamformParameters.FromBytes(bytes);

frame_number = 0;
data_filename = fullfile(data_folder, sprintf("%s_%02d.zst", filename, frame_number));

if isempty(bp.data)
    bp = ornot.GetData(bp, data_filename);
end

settings = ornot.BeamformSettings;
settings.regions = ornot.Region.CreateAxisAlignedVolume(resolution, lateral_extent, elevational_extent, axial_extent);
settings.interpolation_mode = OGLBeamformerInterpolationMode.Cubic;
settings.receive_fnumber = 0;
settings.coherency_weighting = false;
settings.decimation_rate = 1;
settings.compute_stages = [
    OGLBeamformerShaderStage.Demodulate, ...
    OGLBeamformerShaderStage.Decode, ...
    OGLBeamformerShaderStage.DAS
    ];

imageCells = ornot.beamform(bp, settings);

%% Intensity Transform Image
for i = 1:numel(imageCells)
    volumeViewer(abs(imageCells{i}));
    pause(10);
end