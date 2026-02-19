function bytes = bpToBytes(bp)
arguments (Input)
    bp(1,1)
end
arguments (Output)
    bytes uint8
end
switch (class(bp))
    case "ZBP.HeaderV1"
        bp.magic = ZBP.Constants.HeaderMagic;
        bp.Major = 1;
        bytes = bp.toBytes();
    case "ornot.BeamformParametersV2"
        bytes = bpV2ToBytes(bp);
    otherwise
        assert(false, "Unsupported Version");
end
end


function bytes = bpV2ToBytes(bp)
arguments (Input)
    bp(1,1) ornot.BeamformParametersV2
end
arguments (Output)
    bytes uint8
end

bp.header.magic = ZBP.Constants.HeaderMagic;
bp.header.major = 2;
bp.header.minor = 0;

bytes = [];

offset_alignment = ZBP.Constants.OffsetAlignment;
offset = increment_offset(0, bp.header.byteSize, offset_alignment);

if ~isempty(bp.emission_descriptor)
    assert(~isempty(bp.emission_parameters));
    bp.header.emission_descriptors_offset = offset;
    offset = increment_offset(offset, bp.emission_descriptor.byteSize, offset_alignment);
    bp.emission_descriptor.parameters_offset = offset;
    offset = increment_offset(offset, bp.emission_parameters.byteSize, offset_alignment);
    switch bp.emission_descriptor.emission_kind
        case ZBP.EmissionKind.Sine
            assert(isa(bp.emission_parameters, "ZBP.EmissionSineParameters"));
        case ZBP.EmissionKind.Chirp
            assert(isa(bp.emission_parameters, "ZBP.EmissionChirpParameters"));
        otherwise
            assert(false, "Unsupported Emission Kind");
    end
    bytes = set_bytes(bytes, bp.emission_descriptor.toBytes(), bp.header.emission_descriptors_offset);
    bytes = set_bytes(bytes, bp.emission_parameters.toBytes(), bp.emission_descriptor.parameters_offset);
end

if ~isempty(bp.contrast_parameters)
    assert(false, "Saving Contrast Parameters not currently supported")
end

if ~isempty(bp.channel_mapping)
    bp.header.channel_mapping_offset = offset;
    assert(numel(bp.channel_mapping) == bp.header.channel_count);
    offset = increment_offset(offset, 2*bp.header.channel_count, offset_alignment);
    bytes = set_bytes(bytes, typecast(bp.channel_mapping, "uint8"), bp.header.channel_mapping_offset);
end

if ~isempty(bp.acquisition_parameters)
    bp.header.acquisition_parameters_offset = offset;
    section_count = bp.header.raw_data_dimension(3);
    switch bp.header.acquisition_mode
        case ZBP.AcquisitionKind.RCA_VLS
            receive_count = bp.header.receive_event_count;
            assert(isa(bp.acquisition_parameters, "ZBP.VLSParameters"));
            assert(isscalar(bp.acquisition_parameters));

            assert(~isempty(bp.focal_depths));
            assert(numel(bp.focal_depths) == receive_count);
            bp.acquisition_parameters.focal_depths_offset = offset;
            offset = increment_offset(offset, 4*numel(bp.focal_depths), offset_alignment);
            bytes = set_bytes(bytes, typecast(bp.focal_depths, "uint8"));

            assert(~isempty(bp.origin_offsets));
            assert(numel(bp.origin_offsets) == receive_count);
            bp.acquisition_parameters.origin_offsets_offset = offset;
            offset = increment_offset(offset, 4*numel(bp.origin_offsets), offset_alignment);
            bytes = set_bytes(bytes, typecast(bp.origin_offsets, "uint8"));

            assert(~isempty(bp.transmit_receive_orientations));
            assert(numel(bp.transmit_receive_orientations) == receive_count);
            bp.acquisition_parameters.transmit_receive_orientations_offset = offset;
            offset = increment_offset(offset, numel(bp.transmit_receive_orientations), offset_alignment);
            bytes = set_bytes(bytes, typecast(bp.transmit_receive_orientations, "uint8"));
        case ZBP.AcquisitionKind.RCA_TPW
            receive_count = bp.header.receive_event_count;
            assert(isa(bp.acquisition_parameters, "ZBP.TPWParameters"));
            assert(isscalar(bp.acquisition_parameters));

            assert(~isempty(bp.tilting_angles));
            assert(numel(bp.tilting_angles) == receive_count);
            bp.acquisition_parameters.tilting_angles_offset = offset;
            offset = increment_offset(offset, 4*numel(bp.tilting_angles), offset_alignment);
            bytes = set_bytes(bytes, typecast(bp.tilting_angles, "uint8"));

            assert(~isempty(bp.transmit_receive_orientations));
            assert(numel(bp.transmit_receive_orientations) == receive_count);
            bp.acquisition_parameters.origin_offsets_offset = offset;
            offset = increment_offset(offset, numel(bp.transmit_receive_orientations), offset_alignment);
            bytes = set_bytes(bytes, typecast(bp.transmit_receive_orientations, "uint8"));
        case {ZBP.AcquisitionKind.UFORCES, ZBP.AcquisitionKind.UHERCULES}
            assert(~isempty(bp.sparse_elements));
            for i = 1:section_count
                bp.acquisition_parameters(i).sparse_elements_offset = offset;
                offset = increment_offset(offset, 2*numel(bp.sparse_elements(:,i)), offset_alignment);
                bytes = set_bytes(bytes, typecast(bp.sparse_elements(:,i), "uint8"), bp.acquisition_parameters(i).sparse_elements_offset);
            end
    end

    switch bp.header.acquisition_mode
        case ZBP.AcquisitionKind.FORCES
            assert(isa(bp.acquisition_parameters, "ZBP.FORCESParameters"));
        case ZBP.AcquisitionKind.UFORCES
            assert(isa(bp.acquisition_parameters, "ZBP.uFORCESParameters"));
        case ZBP.AcquisitionKind.RCA_VLS
            assert(isa(bp.acquisition_parameters, "ZBP.VLSParameters"));
        case ZBP.AcquisitionKind.RCA_TPW
            assert(isa(bp.acquisition_parameters, "ZBP.TPWParameters"));
        case ZBP.AcquisitionKind.HERCULES
            assert(isa(bp.acquisition_parameters, "ZBP.HERCULESParameters"));
        case ZBP.AcquisitionKind.UHERCULES
            assert(isa(bp.acquisition_parameters, "ZBP.uHERCULESParameters"));
        otherwise
            assert(false, "Unsupported Acquisition Kind")
    end

    for i = 1:numel(bp.acquisition_parameters)
        bytes = set_bytes(bytes, bp.acquisition_parameters(i).toBytes(), offset);
        offset = increment_offset(offset, bp.acquisition_parameters(i).byteSize, 1);
    end

    offset = increment_offset(offset, 0, offset_alignment);
end

if ~isempty(bp.data)
    assert(numel(bp.data) == prod(bp.header.raw_data_dimension));
    bp.header.raw_data_offset = offset;
    offset = increment_offset(offset, numel(typecast(bp.data(:), 'uint8')), offset_alignment);
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
bytes = [bytes, zeros(1, max(offset + size - numel(bytes), 0))];
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