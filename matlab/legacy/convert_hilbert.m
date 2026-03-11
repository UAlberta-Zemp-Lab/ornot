ornot.LoadLibraries();

data_folder = "C:\Users\darren\GoogleDrive\Shared drives\Zemp Lab Shared 2025\Ultrasound Data\Darren Dahunsi\260305_MN32-4_Example_Data\";
filename = "260305_MN32-4_Example_Filename_FORCES-Tx-Row";

new_filename = "250317_MN45-1_ATS539_Cyst_FORCES-TxRow-Chirp-3e-05_hilbert";

bp_filename = fullfile(data_folder, sprintf("%s.bp", filename));
new_bp_filename = fullfile(data_folder, sprintf("%s.bp", new_filename));
fileId = fopen(bp_filename, 'r');
bytes = fread(fileId);
fclose(fileId);

bp = ornot.BeamformParameters.FromBytes(bytes);

frame_number = 0;
data_filename = fullfile(data_folder, sprintf("%s_%02d.zst", filename, frame_number));
new_data_filename = fullfile(data_folder, sprintf("%s_%02d.zst", new_filename, frame_number));

if isempty(bp.data)
    bp = ornot.GetData(bp, data_filename);
end

data = complex(zeros(size(bp.data, 1), size(bp.data, 2), 'single'));
for i = 1:bp.receive_event_count
    samples = (i - 1) * bp.sample_count + (1:bp.sample_count);
    data(samples, :) = hilbert(bp.data(samples,:));
end
bp.data = data;

bp.raw_data_kind = ZBP.DataKind.Float32Complex;
bp.raw_data_compression_kind = ZBP.DataCompressionKind.None;

new_file_id = fopen(new_data_filename, 'w');
fwrite(new_file_id, bp.data, 'float32');
fclose(new_file_id);

new_file_id = fopen(new_bp_filename, 'w');
fwrite(new_file_id, bp.ToBytes());
fclose(new_file_id);

fileId = fopen(new_bp_filename, 'r');
bytes = fread(fileId);
fclose(fileId);

bp2 = ornot.BeamformParameters.FromBytes(bytes);
assert(all(bp.data == bp2.data, "all"));