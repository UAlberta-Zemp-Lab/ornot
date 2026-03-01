addpath("submodules/ogl_beamforming/out/matlab/");
addpath("submodules/ogl_beamforming/out/");
addpath("out");


ornot.LoadLibraries();

data_folder = "C:\Users\darren\Source\Data\260227_MN32-4_Example_Data\";
filename = "260227_MN32-4_Example_Filename_FORCES-Tx-Column";
% filename = "260227_MN32-4_Example_Filename_HERCULES-Diverging-DepthRatio-0.5-Tx-Column-Chirp-2e-05";  
% filename = "260227_MN32-4_Example_Filename_VLS-128-Tx-Column-Chirp-2e-05";
% filename = "260227_MN32-4_Example_Filename_TPW-128-Tx-Column-Chirp-2e-05";
% filename = "260227_MN32-4_Example_Filename_OPTIMUS-9Angles-TxRow-Chirp-2e-05";
% filename = "260227_MN32-4_Example_Filename_FORCES-Walking-8-Tx-Column-Chirp-2e-05";

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
settings.regions = ornot.Region.CreateYZPlane([512, 512], 50e-3*[-1, 1], [20, 100]*1e-3);
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
    image = squeeze(imageCells{i});
    image = image/max(abs(image), [], "all");
    image = 20*log10(abs(image));

    % Display the beamformed image
    figure;
    imagesc(linspace(-50,50, size(image, 2)), linspace(20, 100, size(image, 1)), image);
    axis equal;
    colorbar;
    colormap("gray");
    clim([-60, 0]);
    title('Beamformed Image');
    xlabel('X Position (mm)');
    ylabel('Z Position (mm)');
end