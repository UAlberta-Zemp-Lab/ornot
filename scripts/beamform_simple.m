% NOTE: script assumes a 2D image is being created
data_dir    = "G:\My Drive\Researcher Files\Randy Palamar\250317\250317_MN45-1_3.30MHz_ATS539_Cyst_FORCES-TxRow";
data_file   = "250317_MN45-1_3.30MHz_ATS539_Cyst_FORCES-TxRow_00.zst";
params_file = "250317_MN45-1_3.30MHz_ATS539_Cyst_FORCES-TxRow.bp";

output_points = [512, 1024];
f_number = 1;
lateral = [-40,  40] * 1e-3;
axial   = [ 5,  120] * 1e-3;

timeout_ms = 10 * 1000;

load_libraries();
[bp, frame_count] = upload_parameters(fullfile(data_dir, params_file), lateral, axial, f_number);
beamformed_data = beamform_data(fullfile(data_dir, data_file), output_points, bp, frame_count, timeout_ms);

%% Plot Results
axial_axis   = linspace(axial(1),   axial(2),   output_points(2));
lateral_axis = linspace(lateral(1), lateral(2), output_points(1));
f = figure();
ax = axes(f);
threshold        = 60;
intensity_data   = abs(beamformed_data);
power_scale_data = min(10^(threshold / 20), intensity_data);
imagesc(ax, lateral_axis*1e3, axial_axis*1e3, power_scale_data);
axis(ax, "image"); colormap(ax, gray); colorbar(ax); clim(ax, [0, 10.^(threshold/20)]);
xlabel(ax, "X [mm]"); ylabel(ax, "Z [mm]");

%%


function [bp, frame_count] = upload_parameters(file, lateral, axial, f_number)
% NOTE: make an empty bp struct so that MATLAB can control the memory
zbp    = libstruct('zemp_bp_v1', struct());
calllib('ornot', 'unpack_zemp_bp_v1', char(file), zbp);
zbp    = struct(zbp);

frame_count = zbp.raw_data_dim(3);

bp                    = OGLBeamformerParameters();
bp.transmit_mode      = zbp.transmit_mode;
bp.decode             = zbp.decode_mode;
bp.das_shader_id      = zbp.beamform_mode;
bp.time_offset        = zbp.time_offset;
bp.sampling_frequency = zbp.sampling_frequency;
bp.center_frequency   = zbp.center_frequency;
bp.speed_of_sound     = zbp.speed_of_sound;
bp.xdc_transform      = zbp.transducer_transform_matrix;
bp.dec_data_dim       = zbp.decoded_data_dim;
bp.xdc_element_pitch  = zbp.transducer_element_pitch;
bp.rf_raw_dim         = zbp.raw_data_dim(1:2);
bp.f_number           = f_number;
bp.interpolate        = 1;

bp.output_min_coordinate(1) = lateral(1);
bp.output_min_coordinate(2) = 0;
bp.output_min_coordinate(3) = axial(1);
bp.output_max_coordinate(1) = lateral(2);
bp.output_max_coordinate(2) = 0;
bp.output_max_coordinate(3) = axial(2);

transmit_count = single(zbp.decoded_data_dim(3));

channel_mapping = zbp.channel_mapping(1:transmit_count);

if zbp.sparse_elements(1) == -1
    sparse_elements = linspace(0, transmit_count - 1, transmit_count);
else
    sparse_elements = zbp.sparse_elements;
end

focal_vectors = zeros(1, 2 * transmit_count);
focal_vectors(1:2:end) = zbp.steering_angles(1:transmit_count);
focal_vectors(2:2:end) = zbp.focal_depths(1:transmit_count);

try
    assert(calllib('ogl_beamformer_lib', 'beamformer_push_channel_mapping', channel_mapping, numel(channel_mapping)));
    assert(calllib('ogl_beamformer_lib', 'beamformer_push_sparse_elements', sparse_elements, numel(sparse_elements)));
    assert(calllib('ogl_beamformer_lib', 'beamformer_push_focal_vectors',   focal_vectors,   transmit_count));

    assert(calllib('ogl_beamformer_lib', 'beamformer_push_parameters', struct(bp)));
catch
    errmsg = calllib('ogl_beamformer_lib', 'beamformer_get_last_error_string');
    error(strcat('beamformer error: ', errmsg));
end
end

function beamformed = beamform_data(file, output_points, bp, frame_count, timeout_ms)
try
    data_points = [bp.rf_raw_dim, frame_count];
    data_size   = prod(data_points) * 2; % int16 data - 2 byte per sample
    frame_size  = data_size / frame_count;
    data        = libpointer('int16Ptr', int16(zeros(1, prod(data_points))));
    assert(calllib('ornot', 'unpack_compressed_i16_data', char(file), data, data_size));
catch
    error(strcat('ornot: failed to unpack file: ', char(file)))
end

shader_stages = [OGLBeamformerShaderStage.Demodulate, OGLBeamformerShaderStage.Decode, OGLBeamformerShaderStage.DAS];

beta = 5.65;
cutoff_frequency = 1.8e6;
filter_length = 36;

try
    assert(calllib('ogl_beamformer_lib', 'beamformer_push_pipeline', ...
        int32(shader_stages), numel(shader_stages), ...
        int32(OGLBeamformerDataKind.Int16)));
    assert(calllib('ogl_beamformer_lib', 'beamformer_create_kaiser_low_pass_filter', beta, cutoff_frequency, bp.sampling_frequency / 2, filter_length, 0));
    assert(calllib('ogl_beamformer_lib', 'beamformer_set_pipeline_stage_parameters', 0, 0));
catch
    errmsg = calllib('ogl_beamformer_lib', 'beamformer_get_last_error_string');
    error(strcat('beamformer error: ', errmsg));
end

output_points = [output_points(1), 1, output_points(2)];
output_count  = prod(output_points) * 2; % complex singles
output_data   = libpointer('singlePtr', single(zeros(1, output_count)));
data = data.Value;
try
    assert(calllib('ogl_beamformer_lib', 'beamform_data_synchronized', data, frame_size, output_points, output_data, timeout_ms));
catch
    errmsg = calllib('ogl_beamformer_lib', 'beamformer_get_last_error_string');
    error(strcat('beamformer error: ', errmsg));
end
beamformed = complex(output_data.Value(1:2:end), output_data.Value(2:2:end));
beamformed = squeeze(reshape(beamformed, output_points))';
end

function load_libraries()
addpath("matlab");
if (~libisloaded('ogl_beamformer_lib'))
    loadlibrary('ogl_beamformer_lib');
end
if (~libisloaded('ornot'))
    loadlibrary('ornot');
end
end
