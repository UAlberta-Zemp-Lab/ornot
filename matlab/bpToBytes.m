function bytes = bpToBytes(bp)
arguments (Input)
    bp(1,1) struct
end
arguments (Output)
    bytes uint8
end
switch (class(bp.header))
    case "ZBP.HeaderV1"
        bp.header.magic = ZBP.Constants.HeaderMagic;
        bp.header.Major = 1;
        bytes = bp.header.toBytes();
    case "ZBP.HeaderV2"
        bytes = bpV2ToBytes(bp);
    otherwise
        assert(false, "Unsupported Version");
end
end


function bytes = bpV2ToBytes(bp)
arguments (Input)
    bp(1,1) struct
end
arguments (Output)
    bytes uint8
end

bp.header.magic = ZBP.Constants.HeaderMagic;
bp.header.Major = 2;
bp.header.Minor = 0;

bytes = [];

offset_alignment = ZBP.Constants.OffsetAlignment;
offset = increment_offset(0, bp.header.byteSize, offset_alignment);

if isfield(bp, "emission_descriptor")
    assert(isfield(bp, "emission_parameters"));
    bp.header.emission_descriptors_offset = offset;
    offset = increment_offset(offset, bp.emission_descriptor.byteSize, offset_alignment);
    bp.emission_descriptor.parameters_offset = offset;
    offset = increment_offset(offset, bp.emission_parameters.byteSize, offset_alignment);
    switch bp.emission_descriptor.emission_kind
        case ZBP.EmissionKind.Sine
            assert(isa(bp.emission_parameters, "EmissionSineParameters"));
        case ZBP.EmissionKind.Chirp
            assert(isa(bp.emission_parameters, "EmissionChirpParameters"));
        otherwise
            assert(false, "Unsupported Emission Kind");
    end
    bytes = set_bytes(bytes, bp.emission_descriptor.toBytes(), bp.header.emission_descriptors_offset);
    bytes = set_bytes(bytes, bp.emission_parameters.toBytes(), bp.emission_descriptor.parameters_offset);
end

if isfield(bp, "contrast_parameters")
    assert(false, "Saving Contrast Parameters not currently supported")
end

if isfield(bp, "channel_mapping")
    bp.header.channel_mapping_offset = offset;
    channel_count = bp.header.raw_data_dimension(2);
    assert(numel(bp.channel_mapping) == channel_count);
    assert(isa(bp.channel_count, "uint16"));
    offset = increment_offset(offset, 2*channel_count, offset_alignment);
    bytes = set_bytes(bytes, typecast(bp.channel_mapping, "uint8"), bp.header.channel_mapping_offset);
end

if isfield(bp, "acquisition_parameters")
    bp.header.acquisition_parameters_offset = offset;
    section_count = bp.header.raw_data_dimension(3);
    switch bp.header.acquisition_mode
        case ZBP.AcquisitionKind.RCA_VLS
            receive_count = bp.header.receive_event_count;
            assert(isa(bp.acquisition_parameters, "ZPB.VLSParameters"));
            assert(isscalar(bp.acquisition_parameters));

            assert(isfield(bp, "focal_depths"));
            assert(numel(bp.focal_depths) == receive_count);
            bp.acquisition_parameters.focal_depths_offset = offset;
            offset = increment_offset(offset, 4*numel(bp.focal_depths), offset_alignment);
            bytes = set_bytes(bytes, typecast(bp.focal_depths, "uint8"));

            assert(isfield(bp, "origin_offsets"));
            assert(numel(bp.origin_offsets) == receive_count);
            bp.acquisition_parameters.origin_offsets_offset = offset;
            offset = increment_offset(offset, 4*numel(bp.origin_offsets), offset_alignment);
            bytes = set_bytes(bytes, typecast(bp.origin_offsets, "uint8"));

            assert(isfield(bp, "transmit_receive_orientations"));
            assert(numel(bp.transmit_receive_orientations) == receive_count);
            bp.acquisition_parameters.transmit_receive_orientations_offset = offset;
            offset = increment_offset(offset, numel(bp.transmit_receive_orientations), offset_alignment);
            bytes = set_bytes(bytes, typecast(bp.transmit_receive_orientations, "uint8"));
        case ZBP.AcquisitionKind.RCA_TPW
            receive_count = bp.header.receive_event_count;
            assert(isa(bp.acquisition_parameters, "ZPB.TPWParameters"));
            assert(isscalar(bp.acquisition_parameters));

            assert(isfield(bp, "tilting_angles"));
            assert(numel(bp.tilting_angles) == receive_count);
            bp.acquisition_parameters.tilting_angles_offset = offset;
            offset = increment_offset(offset, 4*numel(bp.tilting_angles), offset_alignment);
            bytes = set_bytes(bytes, typecast(bp.tilting_angles, "uint8"));

            assert(isfield(bp, "transmit_receive_orientations"));
            assert(numel(bp.transmit_receive_orientations) == receive_count);
            bp.acquisition_parameters.origin_offsets_offset = offset;
            offset = increment_offset(offset, numel(bp.transmit_receive_orientations), offset_alignment);
            bytes = set_bytes(bytes, typecast(bp.transmit_receive_orientations, "uint8"));
        case {ZBP.AcquisitionKind.UFORCES, ZBP.AcquisitionKind.UHERCULES}
            assert(isfield(bp, "sparse_elements"));
            for i = 1:section_count
                bp.acquisition_parameters(i).sparse_elements_offset = offset;
                offset = increment_offset(offset, 2*numel(bp.sparse_elements(:,i)), offset_alignment);
                bytes = set_bytes(bytes, typecast(bp.sparse_elements(:,i), "uint8"), bp.acquisition_parameters(i).sparse_elements_offset);
            end
        otherwise
            assert(false, "Unsupported Acquisition Kind")
    end

    switch bp.header.acquisition_mode
        case ZBP.AcquisitionKind.FORCES
            assert(isa(bp.acquisition_parameters, "ZPB.FORCESParameters"));
        case ZBP.AcquisitionKind.UFORCES
            assert(isa(bp.acquisition_parameters, "ZPB.uFORCESParameters"));
        case ZBP.AcquisitionKind.RCA_VLS
            assert(isa(bp.acquisition_parameters, "ZPB.VLSParameters"));
        case ZBP.AcquisitionKind.RCA_TPW
            assert(isa(bp.acquisition_parameters, "ZPB.TPWParameters"));
        case ZBP.AcquisitionKind.HERCULES
            assert(isa(bp.acquisition_parameters, "ZPB.HERCULESParameters"));
        case ZBP.AcquisitionKind.UHERCULES
            assert(isa(bp.acquisition_parameters, "ZPB.uHERCULESParameters"));
    end

    for i = 1:numel(bp.acquisition_parameters)
        bytes = set_bytes(bytes, bp.acquisition_parameters(i), offset);
        parameter_offset = increment_offset(parameter_offset, bp.acquisition_parameters(i).byteSize, 1);
    end

    offset = increment_offset(offset, 0, offset_alignment);
end

if isfield(bp, "data")
    assert(numel(bp.data) == prod(bp.header.raw_data_dimension));
    bp.header.raw_data_offset = offset;
    offset = increment_offset(offset, numel(typecast(bp.data, 'uint8')), offset_alignment);
    bytes = set_bytes(bytes, typecast(bp.data, 'uint8'), bp.header.raw_data_offset);
end

bytes = set_bytes(bytes, bp.header.toBytes());

file_size = offset;
assert(file_size == numel(bytes));
end

function bytes = set_bytes(bytes, value, offset, size)
arguments (Input)
    bytes (1, :) uint8
    value (1, :) uint8
    offset uint64 = 0;
    size uint64 = numel(value);
end
arguments (Output)
    bytes uint8
end
bytes = [bytes, zeros(1, max(numel(bytes) - offset - size, 0))];
bytes(offset + (1:size)) = value(1:size);
end

function offset = increment_offset(offset, increase, alignment)
arguments (Input)
    offset(1,1) uint64
    increase(1,1) uint64 = 0;
    alignment(1,1) uint64 = 1;
end
arguments (Output)
    offset(1,1) double
end
assert(increase >= 0);
assert(mod(log2(double(alignment)), 1) == 0);

offset = offset + increase;
offset = bitand((offset + alignment - 1), bitcmp(alignment - 1));
end