directories = [
    "C:\Users\darren\GoogleDrive\Shared drives\Zemp Lab Shared 2025\Ultrasound Data\Darren Dahunsi\260108_MN32-4_optimus_vs\"
    ];
filesets = [
    directories(1), "260108_MN32-4_optimus_vs_FORCES-Tx-Column-Chirp-2e-05"
    ];

for i = 1:size(filesets, 1)
    process_fileset(filesets(i, 1), filesets(i, 2));
end

function process_fileset(directory, filesetName)
[oldFilename, oldBP] = create_old_file(directory, filesetName);
assert(~isempty(oldFilename))
vsxFilename = fullfile(directory, sprintf("%s_vsx.mat", filesetName));
vsxMat = load(vsxFilename);

if exist(fullfile(directory, sprintf("%s_00.zst", filesetName)))
    compression_mode = ZBP.DataCompressionKind.ZSTD;
elseif exist(fullfile(directory, sprintf("%s_00.bin", filesetName)))
    compression_mode = ZBP.DataCompressionKind.None;
else
    assert(false, "Data File missing")
end

for transmitGroup = 1:numel(vsxMat.vsx.Scan.TransmitGroups)
    bp = BeamformParameterConverter.VsxToBpV2(vsxMat.vsx, vsxMat.vsx.Scan.TransmitGroups(transmitGroup), compression_mode);
    bytes = ZBP.bpToBytes(bp);
    if transmitGroup > 1
        newFilename = fullfile(directory, sprintf("%s_%d.bp", filesetName, transmitGroup));
    else
        newFilename = fullfile(directory, sprintf("%s.bp", filesetName));
    end
    fileId = fopen(newFilename, 'w');
    fwrite(fileId, bytes);
    fclose(fileId);
end
end

function [oldFilename, oldBP] = create_old_file(directory, filesetName)
filename = fullfile(directory, sprintf("%s.bp", filesetName));
targetOldFilename = fullfile(directory, sprintf("%s_old.bp", filesetName));
preReleaseFilename = fullfile(directory, sprintf("%s.bpr", filesetName));
preRelease2Filename = fullfile(directory, sprintf("%s.bpr2", filesetName));

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
        copyfile(filename, targetOldFilename);
        oldFilename = targetOldFilename;
        oldBP = ZBP.bytesToBP(fileBytes);
    end
end

if isempty(oldFilename) && isfile(preRelease2Filename)
    oldBP = BeamformParametersV2.ReadFromFile(preRelease2Filename, 2);
    oldFilename = preRelease2Filename;
end

if isempty(oldFilename) && isfile(preReleaseFilename)
    oldBP = BeamformParametersV2.ReadFromFile(preReleaseFilename, 1);
    oldFilename = preReleaseFilename;
end
end