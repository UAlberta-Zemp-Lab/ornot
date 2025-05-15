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
bp = upload_parameters(fullfile(data_dir, params_file), lateral, axial, f_number, timeout_ms);
beamformed_data = beamform_data(fullfile(data_dir, data_file), output_points, bp, timeout_ms);

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


function bp = upload_parameters(file, lateral, axial, f_number, timeout_ms)
% NOTE: make an empty bp struct so that MATLAB can control the memory
zbp    = libstruct('zemp_bp_v1', struct());
calllib('ornot', 'unpack_zemp_bp_v1', char(file), zbp);
zbp    = struct(zbp);

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

bp.output_min_coordinate    = zeros(1, 3);
bp.output_max_coordinate    = zeros(1, 3);
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
    assert(calllib('ogl_beamformer_lib', 'beamformer_push_channel_mapping', channel_mapping, numel(channel_mapping), timeout_ms));
    assert(calllib('ogl_beamformer_lib', 'beamformer_push_sparse_elements', sparse_elements, numel(sparse_elements), timeout_ms));
    assert(calllib('ogl_beamformer_lib', 'beamformer_push_focal_vectors',   focal_vectors,   transmit_count,         timeout_ms));

    assert(calllib('ogl_beamformer_lib', 'beamformer_push_parameters', bp, timeout_ms));
catch
    errmsg = calllib('ogl_beamformer_lib', 'beamformer_get_last_error_string');
    error(strcat('beamformer error: ', errmsg));
end
end

function beamformed = beamform_data(file, output_points, bp, timeout_ms)
try
    data_points = bp.rf_raw_dim;
    data_size = prod(data_points) * 2; % int16 data - 2 byte per sample
    data      = libpointer('int16Ptr', int16(zeros(1, prod(data_points))));
    assert(calllib('ornot', 'unpack_compressed_i16_data', char(file), data, data_size));
catch
    % NOTE: ensure parameters are flushed if data file can't be found
    calllib('ogl_beamformer_lib', 'beamformer_start_compute', 0);
    error(strcat('ornot: failed to unpack file: ', char(file)))
end

% NOTE: check ogl_beamformer_lib.h for other options
das_id    = 2;
decode_id = 3;
shader_stages = [decode_id, das_id];
try
    assert(calllib('ogl_beamformer_lib', 'set_beamformer_pipeline', shader_stages, numel(shader_stages)));
catch
    errmsg = calllib('ogl_beamformer_lib', 'beamformer_get_last_error_string');
    error(strcat('beamformer error: ', errmsg));
end

output_points = [output_points(1), 1, output_points(2)];
output_count  = prod(output_points) * 2; % complex singles
output_data   = libpointer('singlePtr', single(zeros(1, output_count)));
data = data.Value;
try
    assert(calllib('ogl_beamformer_lib', 'beamform_data_synchronized', data, data_size, output_points, output_data, timeout_ms));
catch
    errmsg = calllib('ogl_beamformer_lib', 'beamformer_get_last_error_string');
    error(strcat('beamformer error: ', errmsg));
end
beamformed = complex(output_data.Value(1:2:end), output_data.Value(2:2:end));
beamformed = squeeze(reshape(beamformed, output_points))';
end

function load_libraries()
if (~libisloaded('ogl_beamformer_lib'))
    loadlibrary('ogl_beamformer_lib');
end
if (~libisloaded('ornot'))
    loadlibrary('ornot');
end
end
