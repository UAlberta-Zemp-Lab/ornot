function bsp = OGLBeamformerSimpleParametersFromParameters(parameters, section_number)
arguments (Input)
    parameters(1,1)     ornot.BeamformParameters
    section_number(1,1) uint16 = 1;
end
arguments (Output)
    bsp(1,1) OGLBeamformerSimpleParameters
end

bsp                        = OGLBeamformerSimpleParameters;
bsp.decode_mode            = parameters.decode_mode;
bsp.acquisition_kind       = parameters.acquisition_kind;
bsp.time_offset            = parameters.time_offset;
bsp.sampling_frequency     = parameters.sampling_frequency;
bsp.demodulation_frequency = parameters.demodulation_frequency;
bsp.speed_of_sound         = parameters.speed_of_sound;
bsp.xdc_transform          = parameters.transducer_transform_matrix;
bsp.xdc_element_pitch      = parameters.transducer_element_pitch;
bsp.raw_data_dimensions    = parameters.raw_data_dimension(1:2);
bsp.data_kind              = parameters.raw_data_kind;
bsp.contrast_mode          = parameters.contrast_mode;
bsp.sample_count           = parameters.sample_count;
bsp.channel_count          = parameters.channel_count;
bsp.acquisition_count      = parameters.receive_event_count;

bsp.emission_parameters.kind = parameters.emission_descriptor.emission_kind;
bsp.emission_parameters.data = parameters.emission_parameters.toBytes();

switch parameters.sampling_mode
    case ZBP.SamplingMode.Standard
        bsp.sampling_mode = OGLBeamformerSamplingMode.m4X;
    case ZBP.SamplingMode.Bandpass
        bsp.sampling_mode = OGLBeamformerSamplingMode.m2X;
end

if ~isempty(parameters.channel_mapping)
    bsp.channel_mapping(1:bsp.channel_count) = parameters.channel_mapping(1:bsp.channel_count);
else
    bsp.channel_mapping(1:bsp.channel_count) = 0:(bsp.channel_count - 1);
end

if ~isempty(parameters.sparse_elements)
    sparse = reshape(parameters.sparse_elements, ...
        parameters.receive_event_count - 1, parameters.raw_data_dimension(3));
    bsp.sparse_elements(1:size(sparse, 1)) ...
        = sparse(:, section_number);
end

switch bsp.acquisition_kind
    case ZBP.AcquisitionKind.RCA_VLS
        bsp.single_focus       = 0;
        bsp.single_orientation = 0;
        depths = sign(parameters.focal_depths(:)').*sqrt(parameters.focal_depths(:)'.^2 + parameters.origin_offsets(:)'.^2);
        angles = atan2d(parameters.origin_offsets(:)', -parameters.focal_depths(:)');
        bsp.focal_depths(1:bsp.acquisition_count)    = depths(1:bsp.acquisition_count);
        bsp.steering_angles(1:bsp.acquisition_count) = angles(1:bsp.acquisition_count);
        bsp.transmit_receive_orientations(1:bsp.acquisition_count) = parameters.transmit_receive_orientations(1:bsp.acquisition_count);
    case ZBP.AcquisitionKind.RCA_TPW
        bsp.single_focus       = 0;
        bsp.single_orientation = 0;
        bsp.focal_depths(:)    = inf;
        bsp.steering_angles(1:bsp.acquisition_count) = parameters.tilting_angles(1:bsp.acquisition_count);
        bsp.transmit_receive_orientations(1:bsp.acquisition_count) = parameters.transmit_receive_orientations(1:bsp.acquisition_count);
    case {ZBP.AcquisitionKind.FORCES, ZBP.AcquisitionKind.UFORCES}
        xdc_transform = reshape(parameters.transducer_transform_matrix, 4, 4);
        [~, receive_orientation] = ornot.unpackTransmitReceiveOrientation(parameters.acquisition_parameters(section_number).transmit_focus.transmit_receive_orientation);
        if receive_orientation == ZBP.RCAOrientation.Rows
            xdc_transform(1:2,:) = xdc_transform(2:-1:1,:);
        end
        bsp.xdc_transform      = xdc_transform(:);
        bsp.single_orientation = 1;
        bsp.transmit_receive_orientation = ...
            parameters.acquisition_parameters(section_number).transmit_focus.transmit_receive_orientation;
    case ZBP.AcquisitionKind.HERO_PA
        bsp.single_orientation = 1;
        bsp.transmit_receive_orientation = ...
            parameters.acquisition_parameters(section_number).transmit_receive_orientation;
    otherwise
        bsp.single_focus       = 1;
        bsp.single_orientation = 1;
        bsp.focal_vector = [...
            parameters.acquisition_parameters(section_number).transmit_focus.steering_angle, ...
            parameters.acquisition_parameters(section_number).transmit_focus.focal_depth];
        bsp.transmit_receive_orientation = ...
            parameters.acquisition_parameters(section_number).transmit_focus.transmit_receive_orientation;
end
end
