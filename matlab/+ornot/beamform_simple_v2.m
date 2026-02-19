addpath("submodules/ogl_beamforming/out/matlab/");
addpath("submodules/ogl_beamforming/out/");
addpath("out");

addpath("matlab\functions\");
addpath("matlab\data\");
addpath("matlab\generated\");
addpath("matlab\legacy\");

ornot.LoadLibraries();

data_folder = "C:\Users\darren\GoogleDrive\Shared drives\Zemp Lab Shared 2025\Ultrasound Data\Darren Dahunsi\260108_MN32-4_optimus_vs\";
filename = "260108_MN32-4_optimus_vs_FORCES-Tx-Column-Chirp-2e-05";

bp_filename = fullfile(data_folder, sprintf("%s.bp", filename));
fileId = fopen(bp_filename, 'w');
bytes = fread(fileId);
fclose(fileId);

bp = ornot.bytesToBP(bytes);

frame_number = 0;
data_filename = fullfile(data_folder, sprintf("%s_%02d.zst", filename, frame_number));

if isempty(bp.data)
    bp = ornot.GetData(bp, data_filename);
end

settings = ornot.BeamformSettings;
region = ornot.XZPlaneRegion;
region.resolution   = [2048, 2048];
region.start_corner = [-50e-3, 0e-3];
region.end_corner   = [50e-3, 100e-3];
region.y_value      = 0e-3;
settings.regions    = region;
settings.interpolation_mode = OGLBeamformerInterpolationMode.Linear;
settings.receive_fnumber = 0;
settings.coherency_weighting = false;
settings.decimation_rate = 1;
settings.compute_stages = [
    OGLBeamformerShaderStage.Demodulate, ...
    OGLBeamformerShaderStage.Decode, ...
    OGLBeamformerShaderStage.DAS
    ];

image = ornot.BeamformV2(bp, settings);