% NOTE: script assumes a 2D image is being created
data_dir    = "G:\My Drive\Researcher Files\Randy Palamar\250317\250317_MN45-1_3.30MHz_ATS539_Cyst_FORCES-TxRow";
data_file   = "250317_MN45-1_3.30MHz_ATS539_Cyst_FORCES-TxRow_00.zst";
params_file = "250317_MN45-1_3.30MHz_ATS539_Cyst_FORCES-TxRow.bp";

output_points = [512, 1, 1024];
f_number = 1;
lateral = [-40,  40] * 1e-3;
axial   = [ 5,  120] * 1e-3;

timeout_ms = 10 * 1000;

load_libraries();

%%%%%%%%%%%%%%%%%%%%%%
%% Setup Parameters %%
%%%%%%%%%%%%%%%%%%%%%%
fd  = fopen(fullfile(data_dir, params_file), 'r');
zbp = ZBP.HeaderV1.fromBytes(fread(fd, '*uint8'));
fclose(fd); clear fd;

frame_count = zbp.raw_data_dimension(3);

bp                        = OGLBeamformerSimpleParameters();
bp.decode_mode            = zbp.decode_mode;
bp.das_shader_id          = zbp.beamform_mode;
bp.time_offset            = zbp.time_offset;
bp.sampling_frequency     = zbp.sampling_frequency;
bp.demodulation_frequency = zbp.demodulation_frequency;
bp.speed_of_sound         = zbp.speed_of_sound;
bp.xdc_transform          = zbp.transducer_transform_matrix;
bp.xdc_element_pitch      = zbp.transducer_element_pitch;
bp.raw_data_dimensions    = zbp.raw_data_dimension(1:2);
bp.f_number               = f_number;
bp.interpolation_mode     = uint32(OGLBeamformerInterpoloationMode.Cubic)

% NOTE: v1 data was always collected at 4X sampling, but most
% parameters had the wrong value saved for center frequency
bp.sampling_mode          = uint32(OGLBeamformerSamplingMode.m4X);
bp.demodulation_frequency = bp.sampling_frequency / 4;

switch zbp.transmit_mode
	case 0
		transmit_mode = OGLBeamformerRCAOrientation.Rows;
		receive_mode  = OGLBeamformerRCAOrientation.Rows;
	case 1
		transmit_mode = OGLBeamformerRCAOrientation.Rows;
		receive_mode  = OGLBeamformerRCAOrientation.Columns;
	case 2
		transmit_mode = OGLBeamformerRCAOrientation.Columns;
		receive_mode  = OGLBeamformerRCAOrientation.Rows;
	case 3
		transmit_mode = OGLBeamformerRCAOrientation.Columns;
		receive_mode  = OGLBeamformerRCAOrientation.Columns;
	otherwise
		error("unhandled transmit mode: 0x%02x", zbp.transmit_mode);
end

transmit_receive_orientation = bitshift(uint8(transmit_mode), 4) + uint8(receive_mode);

bp.sample_count      = zbp.sample_count;
bp.channel_count     = zbp.channel_count;
bp.acquisition_count = zbp.receive_event_count;

bp.channel_mapping(1:bp.channel_count)     = zbp.channel_mapping(1:bp.channel_count);
bp.sparse_elements(1:bp.acquisition_count) = zbp.sparse_elements(1:bp.acquisition_count);

switch bp.das_shader_id
	case {int32(OGLBeamformerAcquisitionKind.HERCULES), int32(OGLBeamformerAcquisitionKind.UHERCULES)}
		bp.single_focus       = 1;
		bp.single_orientation = 1;
		bp.transmit_receive_orientation = transmit_receive_orientation;
		bp.focal_vector(1) = zbp.steering_angles(1);
		bp.focal_vector(2) = zbp.focal_depths(1);
	otherwise
		bp.transmit_receive_orientations(1:bp.acquisition_count) = transmit_receive_orientation;
		bp.steering_angles(1:bp.acquisition_count) = zbp.steering_angles(1:bp.acquisition_count);
		bp.focal_depths(1:bp.acquisition_count)    = zbp.focal_depths(1:bp.acquisition_count);
end

bp.output_points(1:3)       = output_points;
bp.output_min_coordinate(1) = lateral(1);
bp.output_min_coordinate(2) = 0;
bp.output_min_coordinate(3) = axial(1);
bp.output_max_coordinate(1) = lateral(2);
bp.output_max_coordinate(2) = 0;
bp.output_max_coordinate(3) = axial(2);

shaders = [OGLBeamformerShaderStage.Demodulate, OGLBeamformerShaderStage.Decode, OGLBeamformerShaderStage.DAS];
bp.compute_stages(1:numel(shaders)) = shaders;
bp.compute_stages_count             = numel(shaders);

% NOTE: setup a low pass filter for demodulating
beta                    = 5.65;
cutoff_frequency        = 1.8e6;
filter_length           = 36;
kaiser = OGLBeamformerFilter.Kaiser(cutoff_frequency, beta, filter_length);

filter_parameters       = kaiser.Flatten();
filter_kind             = int32(OGLBeamformerFilterKind.Kaiser);
filter_slot             = 0;
filter_is_complex       = 0;
demodulate_shader_index = 1;

% NOTE: bind the filter (which we will create below) to the shader paramters
bp.compute_stage_parameters(demodulate_shader_index) = filter_slot;

data_points = [bp.raw_data_dimensions, frame_count];
data_size   = prod(data_points) * 2; % int16 data - 2 byte per sample
frame_size  = data_size / frame_count;
data        = libpointer('int16Ptr', zeros(1, prod(data_points), 'int16'));
if ~calllib('ornot', 'unpack_compressed_i16_data', char(fullfile(data_dir, data_file)), data, data_size)
	error(strcat('ornot: failed to unpack file: ', char(fullfile(data_dir, data_file))))
end
data = data.Value;
data = reshape(data, bp.raw_data_dimensions(1), bp.raw_data_dimensions(2), []);

bp.data_kind = int32(OGLBeamformerDataKind.Int16);

%%%%%%%%%%%%%%
%% Beamform %%
%%%%%%%%%%%%%%
output_count = prod(output_points) * 2; % complex singles
output_data  = libpointer('singlePtr', zeros(1, output_count, 'single'));

try
	assert(calllib('ogl_beamformer_lib', 'beamformer_create_filter', filter_kind, filter_parameters, ...
	               numel(filter_parameters), bp.sampling_frequency / 2, filter_is_complex, filter_slot, 0));
	assert(calllib('ogl_beamformer_lib', 'beamformer_beamform_data', struct(bp), data, data_size, ...
	               output_data, timeout_ms));
catch ME
	errmsg = calllib('ogl_beamformer_lib', 'beamformer_get_last_error_string');
	warning(strcat('beamformer error: ', errmsg));
	rethrow(ME);
end

beamformed = complex(output_data.Value(1:2:end), output_data.Value(2:2:end));
beamformed = squeeze(reshape(beamformed, output_points))';

%%%%%%%%%%%%%%%%%%
%% Plot Results %%
%%%%%%%%%%%%%%%%%%
axial_axis   = linspace(axial(1),   axial(2),   output_points(3));
lateral_axis = linspace(lateral(1), lateral(2), output_points(1));
f = figure();
ax = axes(f);
threshold        = 60;
intensity_data   = abs(beamformed);
power_scale_data = min(10^(threshold / 20), intensity_data);
imagesc(ax, lateral_axis*1e3, axial_axis*1e3, power_scale_data);
axis(ax, "image"); colormap(ax, gray); colorbar(ax); clim(ax, [0, 10.^(threshold/20)]);
xlabel(ax, "X [mm]"); ylabel(ax, "Z [mm]");

%%

function load_libraries()
addpath("matlab");
warning('off','MATLAB:structOnObject');
if (~libisloaded('ogl_beamformer_lib'))
    [~, ~] = loadlibrary('ogl_beamformer_lib');
    calllib('ogl_beamformer_lib', 'beamformer_set_global_timeout', 1000);
end
if (~libisloaded('ornot'))
    [~, ~] = loadlibrary('ornot');
end
end
