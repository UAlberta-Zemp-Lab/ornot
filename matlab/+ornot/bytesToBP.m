function bp = bytesToBP(bytes)
arguments (Input)
    bytes uint8
end
arguments (Output)
    bp(1,1) ornot.BeamformParameters
end

assert(numel(bytes) >= ZBP.BaseHeader.byteSize);
baseHeader = ZBP.BaseHeader.fromBytes(bytes);
assert(baseHeader.magic == ZBP.Constants.HeaderMagic);

switch baseHeader.major
    case 1
        bp = v1BytesToBP(bytes);
    case 2
        bp = v2BytesToBP(bytes);
end

end


function bp = v1BytesToBP(bytes)
arguments (Input)
    bytes uint8
end
arguments (Output)
    bp(1,1) ornot.BeamformParameters
end

bpV1 = ZBP.HeaderV1.fromBytes(bytes);

bp.raw_data_dimension = bpV1.raw_data_dimension;
bp.raw_data_kind = ZBP.DataKind.Int16;
bp.decode_mode = bpV1.decode_mode;
bp.sampling_mode = ZBP.SamplingMode.Standard;
bp.sampling_frequency = bpV1.sampling_frequency;
bp.demodulation_frequency = bpV1.demodulation_frequency;
bp.speed_of_sound = bpV1.speed_of_sound;
bp.sample_count = bpV1.sample_count;
bp.channel_count = bpV1.channel_count;
bp.receive_event_count = bpV1.receive_event_count;
bp.transducer_transform_matrix = bpV1.transducer_transform_matrix;
bp.transducer_element_pitch = bpV1.transducer_element_pitch;
bp.time_offset = bpV1.time_offset;
bp.acquisition_kind = bpV1.beamform_mode;
bp.contrast_mode = ZBP.ContrastMode.None;
emission_descriptor = ZBP.EmissionDescriptor;
emission_descriptor.emission_kind = ZBP.EmissionKind.Sine;
bp.emission_descriptor = emission_descriptor;
emission_parameters = ZBP.EmissionSineParameters;
emission_parameters.frequency = bp.demodulation_frequency;
emission_parameters.cycles = 1;
bp.emission_parameters = emission_parameters;
bp.channel_mapping = bpV1.channel_mapping;

switch bp.acquisition_kind
    case {ZBP.AcquisitionKind.FORCES}
        acquisition_parameters = ZBP.FORCESParameters;
        acquisition_parameters.transmit_focus.focal_depth = bpV1.focal_depths(1);
        acquisition_parameters.transmit_focus.steering_angle = bpV1.steering_angles(1);
        acquisition_parameters.transmit_receive_orientation = bpV1.transmit_mode;
        bp.acquisition_parameters = acquisition_parameters;
    case {ZBP.AcquisitionKind.UFORCES}
        acquisition_parameters = ZBP.uFORCESParameters;
        acquisition_parameters.transmit_focus.focal_depth = bpV1.focal_depths(1);
        acquisition_parameters.transmit_focus.steering_angle = bpV1.steering_angles(1);
        acquisition_parameters.transmit_receive_orientation = bpV1.transmit_mode;
        bp.acquisition_parameters = acquisition_parameters;
        bp.sparse_elements = bpV1.sparse_elements;
    case {ZBP.AcquisitionKind.HERCULES}
        acquisition_parameters = ZBP.HERCULESParameters;
        acquisition_parameters.transmit_focus.focal_depth = bpV1.focal_depths(1);
        acquisition_parameters.transmit_focus.steering_angle = bpV1.steering_angles(1);
        acquisition_parameters.transmit_receive_orientation = bpV1.transmit_mode;
        bp.acquisition_parameters = acquisition_parameters;
    case {ZBP.AcquisitionKind.RCA_VLS, ZBP.AcquisitionKind.RCA_TPW}
        bp.focal_depths = bpV1.focal_depths;
        bp.origin_offsets = zeros(size(focal_depths));
        bp.tilting_angles = bpV1.steering_angles;
        bp.transmit_receive_orientations = repelem(bpV1.transmit_mode, size(focal_depths));
    case {ZBP.AcquisitionKind.UHERCULES}
        acquisition_parameters = ZBP.uHERCULESParameters;
        acquisition_parameters.transmit_focus.focal_depth = bpV1.focal_depths(1);
        acquisition_parameters.transmit_focus.steering_angle = bpV1.steering_angles(1);
        acquisition_parameters.transmit_receive_orientation = bpV1.transmit_mode;
        bp.acquisition_parameters = acquisition_parameters;
        bp.sparse_elements = bpV1.sparse_elements;
end
end

function bp = v2BytesToBP(bytes)
arguments (Input)
    bytes uint8
end
arguments (Output)
    bp(1,1) ornot.BeamformParameters
end

header = ZBP.HeaderV2.fromBytes(bytes);
bp = ornot.BeamformParameters;
bp.raw_data_dimension = header.raw_data_dimension;
bp.raw_data_kind = header.raw_data_kind;
bp.raw_data_compression_kind = header.raw_data_compression_kind;
bp.decode_mode = header.decode_mode;
bp.sampling_mode = header.sampling_mode;
bp.sampling_frequency = header.sampling_frequency;
bp.demodulation_frequency = header.demodulation_frequency;
bp.speed_of_sound = header.speed_of_sound;
bp.sample_count = header.sample_count;
bp.channel_count = header.channel_count;
bp.receive_event_count = header.receive_event_count;
bp.transducer_transform_matrix = header.transducer_transform_matrix;
bp.transducer_element_pitch = header.transducer_element_pitch;
bp.time_offset = header.time_offset;
bp.group_acquisition_time = header.group_acquisition_time;
bp.ensemble_repitition_interval = header.ensemble_repitition_interval;
bp.acquisition_kind = header.acquisition_mode;
bp.contrast_mode = header.contrast_mode;

if header.emission_descriptors_offset >= 0
    bp.emission_descriptor = ZBP.EmissionDescriptor.fromBytes(bytes(uint32(header.emission_descriptors_offset) + (1:ZBP.EmissionDescriptor.byteSize)));
    switch bp.emission_descriptor.emission_kind
        case ZBP.EmissionKind.Sine
            bp.emission_parameters = ZBP.EmissionSineParameters.fromBytes(bytes(uint32(bp.emission_descriptor.parameters_offset) + (1:ZBP.EmissionSineParameters.byteSize)));
        case ZBP.EmissionKind.Chirp
            bp.emission_parameters = ZBP.EmissionChirpParameters.fromBytes(bytes(uint32(bp.emission_descriptor.parameters_offset) + (1:ZBP.EmissionChirpParameters.byteSize)));
    end
end

if header.contrast_parameters_offset >= 0
    assert(false, "Loading Contrast Parameters not currently supported")
end

if header.channel_mapping_offset >= 0
    channel_count = header.raw_data_dimension(2);
    bp.channel_mapping = typecast(bytes(uint32(header.channel_mapping_offset) + (1:(2*channel_count))), 'uint16');
end

if header.acquisition_parameters_offset >= 0
    switch header.acquisition_mode
        case ZBP.AcquisitionKind.FORCES
            section_count = header.raw_data_dimension(3);
            offset = uint32(header.acquisition_parameters_offset);
            bp.acquisition_parameters = createArray([section_count, 1], "ZBP.FORCESParameters");
            for i = 1:section_count
                bp.acquisition_parameters(i) = ZBP.FORCESParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.FORCESParameters.byteSize)));
                offset = offset + ZBP.FORCESParameters.byteSize;
            end
        case ZBP.AcquisitionKind.UFORCES
            section_count = header.raw_data_dimension(3);
            sparse_element_count = header.receive_event_count - 1;
            offset = uint32(header.acquisition_parameters_offset);
            bp.acquisition_parameters = createArray([section_count, 1], "ZBP.uFORCESParameters");
            bp.sparse_elements = zeros(sparse_element_count, section_count);
            for i = 1:section_count
                bp.acquisition_parameters(i) = ZBP.uFORCESParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.uFORCESParameters.byteSize)));
                offset = offset + ZBP.uFORCESParameters.byteSize;
                sparse_elements_offset = bp.acquisition_parameters(i).sparse_elements_offset;
                if sparse_elements_offset >= 0
                    bp.sparse_elements(:,i) = typecast(bytes(uint32(sparse_elements_offset) + (1:(2*sparse_element_count))), 'uint16');
                else
                end
            end
        case ZBP.AcquisitionKind.HERCULES
            section_count = header.raw_data_dimension(3);
            offset = uint32(header.acquisition_parameters_offset);
            bp.acquisition_parameters = createArray([section_count, 1], "ZBP.HERCULESParameters");
            for i = 1:section_count
                bp.acquisition_parameters(i) = ZBP.HERCULESParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.FORCESParameters.byteSize)));
                offset = offset + ZBP.HERCULESParameters.byteSize;
            end
        case ZBP.AcquisitionKind.RCA_VLS
            receive_count = header.receive_event_count;
            bp.acquisition_parameters = ZBP.VLSParameters.fromBytes(bytes(uint32(header.acquisition_parameters_offset) + (1:ZBP.VLSParameters.byteSize)));
            bp.focal_depths = typecast(bytes(uint32(bp.acquisition_parameters.focal_depths_offset) + (1:(4*receive_count))), "single");
            bp.origin_offsets = typecast(bytes(uint32(bp.acquisition_parameters.origin_offsets_offset) + (1:(4*receive_count))), "single");
            bp.transmit_receive_orientations = typecast(bytes(uint32(bp.acquisition_parameters.transmit_receive_orientations_offset) + (1:receive_count)), "uint8");
        case ZBP.AcquisitionKind.RCA_TPW
            receive_count = header.receive_event_count;
            bp.acquisition_parameters = ZBP.TPWParameters.fromBytes(bytes(uint32(header.acquisition_parameters_offset) + (1:ZBP.TPWParameters.byteSize)));
            bp.tilting_angles = typecast(bytes(uint32(bp.acquisition_parameters.tilting_angles_offset) + (1:(4*receive_count))), "single");
            bp.transmit_receive_orientations = typecast(bytes(uint32(bp.acquisition_parameters.transmit_receive_orientations_offset) + (1:receive_count)), "uint8");
        case ZBP.AcquisitionKind.UHERCULES
            section_count = header.raw_data_dimension(3);
            sparse_element_count = header.receive_event_count - 1;
            offset = uint32(header.acquisition_parameters_offset);
            bp.acquisition_parameters = createArray([section_count, 1], "ZBP.uHERCULESParameters");
            bp.sparse_elements = zeros(sparse_element_count, section_count);
            for i = 1:section_count
                bp.acquisition_parameters(i) = ZBP.uHERCULESParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.uHERCULESParameters.byteSize)));
                offset = offset + ZBP.uHERCULESParameters.byteSize;
                sparse_elements_offset = acquisition_parameters(i).sparse_elements_offset;
                if sparse_elements_offset >= 0
                    bp.sparse_elements(:,i) = typecast(bytes(uint32(sparse_elements_offset) + (1:(2*sparse_element_count))), 'uint16');
                else
                end
            end
    end
end

if header.raw_data_offset >= 0
    bp.data = bytes(header.raw_data_offset + (1:prod(min(header.raw_data_dimension, 1))));
end

end