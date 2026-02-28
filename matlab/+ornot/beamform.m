function images = beamform(bp, settings)
arguments (Input)
    bp(1, 1) ornot.BeamformParameters
    settings(1,1) ornot.BeamformSettings
end
arguments (Output)
    images(:,:,:) cell
end

[output_points, output_min_coordinates, ...
    output_max_coordinates, beamform_planes, off_axis_positions] ...
    = ornot.RegionToTransform(settings.regions);

% Allocate Section Count x Ensemble Count x Region Count images
images = cell(bp.raw_data_dimension(3), bp.raw_data_dimension(4), numel(settings.regions));

bsp = OGLBeamformerSimpleParameters;
bsp = updateBspFromBP(bsp, bp);
bsp = updateBspFromSettings(bsp, settings);
% bsp = setupLowPassFilter(bsp, settings);

data = bp.data;
switch class(data)
    case 'int16'
        if isreal(data)
            bsp.data_kind = int32(OGLBeamformerDataKind.Int16);
        else
            bsp.data_kind = int32(OGLBeamformerDataKind.Int16Complex);
        end
    case {'single', 'double'}
        if isa(data, 'double')
            data = single(data);
        end
        if isreal(data)
            bsp.data_kind = int32(OGLBeamformerDataKind.Float32);
        else
            bsp.data_kind = int32(OGLBeamformerDataKind.Float32Complex);
        end
end



for i = 1:numel(images)
    [section_index, ensemble_index, region_index] = ind2sub([bp.raw_data_dimension(3), bp.raw_data_dimension(4), numel(settings.regions)], i);

    bsp = updateBspFromBPSection(bsp, bp, section_index);

    bsp.output_min_coordinate = output_min_coordinates(:, region_index);
    bsp.output_max_coordinate = output_max_coordinates(:, region_index);
    bsp.output_points(1:3) = output_points(:, region_index);
    bsp.beamform_plane = beamform_planes(:, region_index);
    bsp.off_axis_pos = off_axis_positions(:, region_index);

    images{section_index, ensemble_index, region_index} = ornot.beamformSimpleParameters(bsp, data(:, :, section_index));
end

end

function bsp = updateBspFromBP(bsp, bp)
arguments (Input)
    bsp(1,1) OGLBeamformerSimpleParameters
    bp(1,1) ornot.BeamformParameters
end
arguments (Output)
    bsp(1,1) OGLBeamformerSimpleParameters
end

bsp.raw_data_dimensions = bp.raw_data_dimension(1:2);
bsp.decode_mode = bp.decode_mode;
switch bp.sampling_mode
    case ZBP.SamplingMode.Standard
        bsp.sampling_mode = OGLBeamformerSamplingMode.m4X;
    case ZBP.SamplingMode.Bandpass
        bsp.sampling_mode = OGLBeamformerSamplingMode.m2X;
end
bsp.sampling_frequency = bp.sampling_frequency;
bsp.demodulation_frequency = bp.demodulation_frequency;
bsp.speed_of_sound = bp.speed_of_sound;
bsp.sample_count = bp.sample_count;
bsp.channel_count = bp.channel_count;
bsp.acquisition_count = bp.receive_event_count;
bsp.xdc_transform = bp.transducer_transform_matrix;
bsp.xdc_element_pitch = bp.transducer_element_pitch;
bsp.time_offset = bp.time_offset;
bsp.acquisition_kind = bp.acquisition_kind;

bsp.channel_mapping(1:numel(bp.channel_mapping)) = bp.channel_mapping;

bsp.emission_kind = bp.emission_descriptor.emission_kind;
bsp.emission_parameters(1:bp.emission_parameters.byteSize) = bp.emission_parameters.toBytes();
end

function bsp = updateBspFromBPSection(bsp, bp, section_number)
arguments (Input)
    bsp(1,1) OGLBeamformerSimpleParameters
    bp(1,1) ornot.BeamformParameters
    section_number(1,1) uint16 = 1;
end
arguments (Output)
    bsp(1,1) OGLBeamformerSimpleParameters
end

if ~isempty(bp.sparse_elements)
    sparse_elements = reshape(bp.sparse_elements, ...
        bp.receive_event_count - 1, bp.raw_data_dimension(3));
    bsp.sparse_elements(1:size(sparse_elements, 1)) ...
        = sparse_elements(:, section_number);
end

switch bsp.acquisition_kind
    case ZBP.AcquisitionKind.RCA_VLS
        bsp.single_focus = 0;
        bsp.single_orientation = 0;
        bsp.focal_depths(1:numel(bp.focal_depths)) ...
            = sign(bp.focal_depths(:)').*sqrt(bp.focal_depths(:)'.^2 + bp.origin_offsets(:)'.^2);
        bsp.steering_angles(1:numel(bp.focal_depths)) ...
            = atan2d(bp.origin_offsets(:)', -bp.focal_depths(:)');
        bsp.transmit_receive_orientations(1:numel(bp.transmit_receive_orientations)) = bp.transmit_receive_orientations;
    case ZBP.AcquisitionKind.RCA_TPW
        bsp.single_focus = 0;
        bsp.single_orientation = 0;
        bsp.focal_depths(:) = inf;
        bsp.steering_angles(1:numel(bp.tilting_angles)) = bp.tilting_angles;
        bsp.transmit_receive_orientations(1:numel(bp.transmit_receive_orientations)) = bp.transmit_receive_orientations;
    otherwise
        bsp.single_focus = 1;
        bsp.single_orientation = 1;
        bsp.focal_vector = [...
            bp.acquisition_parameters(section_number).transmit_focus.steering_angle, ...
            bp.acquisition_parameters(section_number).transmit_focus.focal_depth];
        bsp.transmit_receive_orientation = ...
            bp.acquisition_parameters(section_number).transmit_focus.transmit_receive_orientation;
end

demodulate_shader_index = find(bsp.compute_stages == OGLBeamformerShaderStage.Demodulate);

% These are applied at baseband
if ~isempty(demodulate_shader_index)
    filter_slot = mod(section_number - 1, 4);
    switch class(bp.emission_parameters)
        case "ZBP.EmissionSineParameters"
            filter_kind             = int32(OGLBeamformerFilterKind.Kaiser);
            kaiser                  = OGLBeamformerFilter.Kaiser;
            kaiser.length           = 36;
            kaiser.beta             = 5.65;
            kaiser.cutoff_frequency = 0.5*bp.emission_parameters.frequency;
            filter_parameters       = kaiser.Pack();
            filter_is_complex       = 0;
        case "ZBP.EmissionChirpParameters"
            filter_kind             = int32(OGLBeamformerFilterKind.MatchedChirp);
            chirp                   = OGLBeamformerFilter.MatchedChirp;
            chirp.duration          = bp.emission_parameters.duration;
            chirp.min_frequency     = bp.emission_parameters.min_frequency - bsp.demodulation_frequency;
            chirp.max_frequency     = bp.emission_parameters.max_frequency - bsp.demodulation_frequency;
            filter_parameters       = chirp.Pack();
            filter_is_complex       = 1;
    end

    try
        assert(calllib('ogl_beamformer_lib', 'beamformer_create_filter', filter_kind, filter_parameters, ...
            numel(filter_parameters), bsp.sampling_frequency / 2, filter_is_complex, filter_slot, 0));
    catch ME
        errmsg = calllib('ogl_beamformer_lib', 'beamformer_get_last_error_string');
        warning(strcat('beamformer error: ', errmsg));
        rethrow(ME);
    end

    bsp.compute_stage_parameters(demodulate_shader_index) = filter_slot;
end
end

function bsp = updateBspFromSettings(bsp, settings)
arguments (Input)
    bsp(1,1) OGLBeamformerSimpleParameters
    settings(1,1) ornot.BeamformSettings
end
arguments (Output)
    bsp(1,1) OGLBeamformerSimpleParameters
end

bsp.interpolation_mode = settings.interpolation_mode;
bsp.coherency_weighting = settings.coherency_weighting;
bsp.f_number = settings.receive_fnumber;
bsp.decimation_rate = settings.decimation_rate;

bsp.compute_stages_count = numel(settings.compute_stages);
bsp.compute_stages(1:bsp.compute_stages_count) = settings.compute_stages;
end

function bsp = setupLowPassFilter(bsp, settings)
arguments (Input)
    bsp(1,1) OGLBeamformerSimpleParameters
    settings(1,1) ornot.BeamformSettings
end
arguments (Output)
    bsp(1,1) OGLBeamformerSimpleParameters
end

demodulate_shader_index = find(bsp.compute_stages == OGLBeamformerShaderStage.Demodulate);

if isempty(demodulate_shader_index)
    return
end

filter_parameters       = settings.low_pass_demodulate_filter.Pack();
filter_kind             = int32(OGLBeamformerFilterKind.Kaiser);
filter_slot             = 0;
filter_is_complex       = 0;

try
    assert(calllib('ogl_beamformer_lib', 'beamformer_create_filter', filter_kind, filter_parameters, ...
        numel(filter_parameters), bsp.sampling_frequency / 2, filter_is_complex, filter_slot, 0));
catch ME
    errmsg = calllib('ogl_beamformer_lib', 'beamformer_get_last_error_string');
    warning(strcat('beamformer error: ', errmsg));
    rethrow(ME);
end

bsp.compute_stage_parameters(demodulate_shader_index) = filter_slot;
end