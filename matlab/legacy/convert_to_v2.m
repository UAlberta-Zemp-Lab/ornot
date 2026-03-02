addpath(genpath("../../../Verasonics-Biasing-Imaging/src/"));
addpath(genpath("../../../Verasonics-Biasing-Imaging/Ultrasound-Beamforming/src/"));
addpath("submodules/ogl_beamforming/out/");
addpath("submodules/ogl_beamforming/out/matlab/");
addpath("out/");

ornot.LoadLibraries;


directories = [
    "C:\Users\darren\GoogleDrive\Shared drives\Zemp Lab Shared 2025\Ultrasound Data\Darren Dahunsi\251104_MN32-4_test_beamform\";
    "C:\Users\darren\GoogleDrive\Shared drives\Zemp Lab Shared 2025\Ultrasound Data\Darren Dahunsi\260108_MN32-4_optimus_vs\";
    "C:\Users\darren\GoogleDrive\Shared drives\Zemp Lab Shared 2025\Ultrasound Data\Darren Dahunsi\250831_MN32-4_IUS2025_OPTIMUS_UHERCULES\";
    ];
filesets = [
    % directories(1), "251104_MN32-4_ats539_cysts_HERCULES-Tx-Column";
    % get_toml_filesets(directories(2));
    get_bpr_filesets(directories(3));
    ];

for i = 1:size(filesets, 1)
    process_fileset(filesets(i, 1), filesets(i, 2));
end

function process_fileset(directory, fileset_name)
[oldFilename, oldBP] = create_old_file(directory, fileset_name);
assert(~isempty(oldFilename))
vsx_filename = fullfile(directory, sprintf("%s_vsx.mat", fileset_name));
vsx_mat = load(vsx_filename);
data_filename = fullfile(directory, sprintf("%s_00.zst", fileset_name));

if exist(fullfile(directory, sprintf("%s_00.zst", fileset_name)))
    compression_mode = ZBP.DataCompressionKind.ZSTD;
elseif exist(fullfile(directory, sprintf("%s_00.bin", fileset_name)))
    compression_mode = ZBP.DataCompressionKind.None;
else
    assert(false, "Data File missing")
end

settings = ornot.BeamformSettings;
settings.regions = ornot.XZPlaneRegion;
settings.regions.resolution = [2048, 2048];
settings.regions.start_corner = [-50e-3, 0e-3];
settings.regions.end_corner = [50e-3, 100e-3];
settings.regions.y_value = 0e-3;
settings.interpolation_mode = OGLBeamformerInterpolationMode.Linear;
settings.receive_fnumber = 0;
settings.coherency_weighting = false;
settings.decimation_rate = 1;
settings.compute_stages = [
    OGLBeamformerShaderStage.Demodulate, ...
    OGLBeamformerShaderStage.Decode, ...
    OGLBeamformerShaderStage.DAS
    ];

for transmitGroup = 1:numel(vsx_mat.vsx.Scan.TransmitGroups)
    bp = BeamformParameterConverter.VsxToBp(vsx_mat.vsx, vsx_mat.vsx.Scan.TransmitGroups(transmitGroup), compression_mode);
    bp = ornot.GetData(bp, data_filename);
    image = ornot.beamform(bp, settings);
    bp.data = [];

    bytes = bp.ToBytes();
    if transmitGroup > 1
        newFilename = fullfile(directory, sprintf("%s_%d.bp", fileset_name, transmitGroup));
    else
        newFilename = fullfile(directory, sprintf("%s.bp", fileset_name));
    end

    fileId = fopen(newFilename, 'w');
    fwrite(fileId, bytes);
    fclose(fileId);
end
end

function [oldFilename, oldBP] = create_old_file(directory, filesetName)
filename = fullfile(directory, sprintf("%s.bp", filesetName));
targetOldFilename = fullfile(directory, sprintf("%s_old.bp", filesetName));
preRelease1Filename = fullfile(directory, sprintf("%s.bpr", filesetName));
preRelease2Filename = fullfile(directory, sprintf("%s.bpr2", filesetName));
newRelease1Filename = fullfile(directory, sprintf("%s.bp1", filesetName));
newPreRelease1Filename = fullfile(directory, sprintf("%s.bpr1", filesetName));

oldFilename = [];

if isfile(targetOldFilename)
    oldFilename = targetOldFilename;
    oldBP = BeamformParametersV1.ReadFromFile(targetOldFilename);
end

if isempty(oldFilename) && isfile(filename)
    fileID = fopen(filename);
    fileBytes = fread(fileID);
    fclose(fileID);
    baseHeader = ZBP.BaseHeader.fromBytes(fileBytes);
    if baseHeader.major == 1
        copyfile(filename, newRelease1Filename);
        oldFilename = newRelease1Filename;
    end
end

if isempty(oldFilename) && isfile(preRelease2Filename)
    try
        oldBP = BeamformParametersV2.ReadFromFile(preRelease2Filename, 2);
    catch
        oldBP = [];
        fprintf("Failed to read %s\n", preRelease2Filename);
    end
    oldFilename = preRelease2Filename;
end

if isempty(oldFilename) && isfile(preRelease1Filename)
    try
        copyfile(preRelease1Filename, newPreRelease1Filename);
        oldBP = BeamformParametersV2.ReadFromFile(preRelease1Filename, 1);
    catch
        oldBP = [];
        fprintf("Failed to read %s\n", preRelease1Filename);
    end
    oldFilename = newPreRelease1Filename;
end
end

function filesets = get_toml_filesets(directory)
listing = dir(directory);
filesets = string.empty();
for i = 1:numel(listing)
    [~, name, ext] = fileparts(listing(i).name);
    if strcmpi(ext, ".toml")
        filesets = [
            filesets;
            directory, name;
            ];
    end
end
end

function filesets = get_bpr2_filesets(directory)
listing = dir(directory);
filesets = string.empty();
for i = 1:numel(listing)
    [~, name, ext] = fileparts(listing(i).name);
    if strcmpi(ext, ".bpr2")
        filesets = [
            filesets;
            directory, name;
            ];
    end
end
end

function filesets = get_bpr_filesets(directory)
listing = dir(directory);
filesets = string.empty();
for i = 1:numel(listing)
    [~, name, ext] = fileparts(listing(i).name);
    if strcmpi(ext, ".bpr")
        filesets = [
            filesets;
            directory, name;
            ];
    end
end
end