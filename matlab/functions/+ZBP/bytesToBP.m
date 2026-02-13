function bp = bytesToBP(bytes)
arguments (Input)
    bytes uint8
end
arguments (Output)
    bp(1,1)
end

assert(len(bytes) >= ZBP.BaseHeader.byteSize);
baseHeader = ZBP.BaseHeader.fromBytes(bytes);
assert(baseHeader.magic == ZBP.Constants.HeaderMagic);

switch baseHeader.major
    case 1
        bp = ZBP.HeaderV1.fromBytes(bytes);
    case 2
        bp = bytesToBPV2(bytes);
end

end


function bp = bytesToBPV2(bytes)
arguments (Input)
    bytes uint8
end
arguments (Output)
    bp(1,1) ZBP.BeamformParametersV2
end

bp.header = ZBP.HeaderV2.fromBytes(bytes);

if bp.header.emission_descriptors_offset >= 0
    bp.emission_descriptor = ZBP.EmissionDescriptor.fromBytes(bytes(bp.header.emission_descriptors_offset + (1:ZBP.EmissionDescriptor.byteSize)));
    switch bp.emission_descriptor.emission_kind
        case ZBP.EmissionKind.Sine
            bp.emission_parameters = ZBP.EmissionSineParameters.fromBytes(bytes(bp.header.emission_descriptor.parameters_offset + (1:ZBP.EmissionSineParameters.byteSize)));
        case ZBP.EmissionKind.Chirp
            bp.emission_parameters = ZBP.EmissionChirpParameters.fromBytes(bytes(bp.header.emission_descriptor.parameters_offset + (1:ZBP.EmissionChirpParameters.byteSize)));
    end
end

if bp.header.contrast_parameters_offset >= 0
    assert(false, "Loading Contrast Parameters not currently supported")
end

if bp.header.channel_mapping_offset >= 0
    channel_count = bp.header.raw_data_dimension(2);
    bp.channel_mapping = typecast(bytes(bp.header.channel_mapping_offset + (1:(2*channel_count))), 'uint16');
end

if bp.header.acquisition_parameters_offset >= 0
    switch bp.header.acquisition_mode
        case ZBP.AcquisitionKind.FORCES
            section_count = bp.header.raw_data_dimension(3);
            offset = bp.header.acquisition_parameters_offset;
            bp.acquisition_parameters(section_count) = ZPB.FORCESParameters;
            for i = 1:section_count
                offset = offset + ZBP.FORCESParameters.byteSize;
                bp.acquisition_parameters(section_count) = ZBP.FORCESParameters.fromBytes(bytes(offset + (1:ZBP.FORCESParameters.byteSize)));
            end
        case ZBP.AcquisitionKind.UFORCES
            section_count = bp.header.raw_data_dimension(3);
            sparse_element_count = bp.header.receive_event_count - 1;
            offset = bp.header.acquisition_parameters_offset;
            bp.acquisition_parameters(section_count) = ZPB.UFORCESParameters;
            bp.sparse_elements = zeros(sparse_element_count, section_count);
            for i = 1:section_count
                offset = offset + ZBP.UFORCESParameters.byteSize;
                bp.acquisition_parameters(section_count) = ZBP.UFORCESParameters.fromBytes(bytes(offset + (1:ZBP.FORCESParameters.byteSize)));
                sparse_elements_offset = bp.acquisition_parameters(section_count).sparse_elements_offset;
                if sparse_elements_offset >= 0
                    bp.sparse_elements(:,i) = typecast(bytes(sparse_elements_offset + (1:(2*sparse_element_count))), 'uint16');
                else
                end
            end
        case ZBP.AcquisitionKind.HERCULES
            section_count = bp.header.raw_data_dimension(3);
            offset = bp.header.acquisition_parameters_offset;
            bp.acquisition_parameters(section_count) = ZPB.HERCULESParameters;
            for i = 1:section_count
                offset = offset + ZBP.HERCULESParameters.byteSize;
                bp.acquisition_parameters(section_count) = ZBP.HERCULESParameters.fromBytes(bytes(offset + (1:ZBP.FORCESParameters.byteSize)));
            end
        case ZBP.AcquisitionKind.RCA_VLS
            receive_count = bp.header.receive_event_count;
            bp.acquisition_parameters = ZBP.VLSParameters.fromBytes(bytes(bp.header.acquisition_parameters_offset + (1:ZBP.VLSParameters.byteSize)));
            bp.focal_depths = typecast(bytes(bp.acquisition_parameters.focal_depths_offset + (1:(4*receive_count))), "single");
            bp.origins = typecast(bytes(bp.acquisition_parameters.origin_offsets_offset + (1:(4*receive_count))), "single");
            bp.transmit_receive_orientation = typecast(bytes(bp.acquisition_parameters.transmit_receive_orientations_offset + (1:receive_count)), "uint8");
        case ZBP.AcquisitionKind.RCA_TPW
            receive_count = bp.header.receive_event_count;
            bp.acquisition_parameters = ZBP.TPWParameters.fromBytes(bytes(bp.header.acquisition_parameters_offset + (1:ZBP.TPWParameters.byteSize)));
            bp.tilting_angles = typecast(bytes(bp.acquisition_parameters.tilting_angles_offset + (1:(4*receive_count))), "single");
            bp.transmit_receive_orientation = typecast(bytes(bp.acquisition_parameters.transmit_receive_orientations_offset + (1:receive_count)), "uint8");
        case ZBP.AcquisitionKind.UHERCULES
            section_count = bp.header.raw_data_dimension(3);
            sparse_element_count = bp.header.receive_event_count - 1;
            offset = bp.header.acquisition_parameters_offset;
            acquisition_parameters(section_count) = ZPB.UHERCULESParameters;
            bp.sparse_elements = zeros(sparse_element_count, section_count);
            for i = 1:section_count
                offset = offset + ZBP.UHERCULESParameters.byteSize;
                acquisition_parameters(section_count) = ZBP.UHERCULESParameters.fromBytes(bytes(offset + (1:ZBP.HERCULESParameters.byteSize)));
                sparse_elements_offset = acquisition_parameters(section_count).sparse_elements_offset;
                if sparse_elements_offset >= 0
                    bp.sparse_elements(:,i) = typecast(bytes(sparse_elements_offset + (1:(2*sparse_element_count))), 'uint16');
                else
                end
            end
    end
end

if bp.header.raw_data_offset >= 0
    bp.data = bytes(bp.header.raw_data_offset + (1:prod(min(bp.header.raw_data_dimension, 1))));
end

end