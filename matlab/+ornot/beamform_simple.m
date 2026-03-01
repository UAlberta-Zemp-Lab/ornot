addpath("submodules/ogl_beamforming/out/matlab/");
addpath("submodules/ogl_beamforming/out/");
addpath("out");


ornot.LoadLibraries();

data_folder = "C:\Users\darren\Source\Data\260227_MN32-4_Example_Data\";
filename = "260227_MN32-4_Example_Filename_FORCES-Tx-Column";

bp_filename = fullfile(data_folder, sprintf("%s.bp", filename));
fileId = fopen(bp_filename, 'r');
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
region.resolution   = [512, 512];
region.start_corner = [-50e-3, 0e-3];
region.end_corner   = [50e-3, 100e-3];
region.y_value      = 0e-3;
settings.regions    = region;
settings.interpolation_mode = OGLBeamformerInterpolationMode.Cubic;
settings.receive_fnumber = 0;
settings.coherency_weighting = false;
settings.decimation_rate = 1;
settings.compute_stages = [
    OGLBeamformerShaderStage.Demodulate, ...
    OGLBeamformerShaderStage.Decode, ...
    OGLBeamformerShaderStage.DAS
    ];

image = ornot.beamform(bp, settings);

% Intensity Transform Image
image = squeeze(image{1});
image = image/max(abs(image), [], "all");
image = 20*log10(abs(image));

% Display the beamformed image
figure;
imagesc(linspace(-50,50, size(image, 2)), linspace(0,100, size(image, 1)), image);
axis equal;
colorbar;
colormap("gray");
clim([-60, 0]);
title('Beamformed Image');
xlabel('X Position (mm)');
ylabel('Z Position (mm)');