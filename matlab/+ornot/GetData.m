function bp = GetData(bp, data_filename)
arguments (Input)
    bp(1,1) ornot.BeamformParametersV2
    data_filename(1,1) string
end
arguments (Output)
    bp(1,1) ornot.BeamformParametersV2
end

switch bp.header.raw_data_kind
    case ZBP.DataKind.Int16
        data_size_byte_multiplier = 2;
        lib_pointer_class = 'int16Ptr';
        is_complex = false;
        is_half = false;
    case ZBP.DataKind.Int16Complex
        data_size_byte_multiplier = 4;
        lib_pointer_class = 'int16Ptr';
        is_complex = true;
        is_half = false;
    case ZBP.DataKind.Float32
        data_size_byte_multiplier = 4;
        lib_pointer_class = 'singlePtr';
        is_complex = false;
        is_half = false;
    case ZBP.DataKind.Float32Complex
        data_size_byte_multiplier = 8;
        lib_pointer_class = 'singlePtr';
        is_complex = true;
        is_half = false;
    case ZBP.DataKind.Float16
        data_size_byte_multiplier = 2;
        lib_pointer_class = 'int16Ptr';
        is_complex = false;
        is_half = true;
    case ZBP.DataKind.Float16Complex
        lib_pointer_class = 'int16Ptr';
        data_size_byte_multiplier = 4;
        is_complex = true;
        is_half = true;
end

data_point_count = prod(bp.header.raw_data_dimension);
if is_complex
    data_point_count = 2 * data_point_count;
end
data_byte_size = data_size_byte_multiplier * data_point_count;
data = libpointer(lib_pointer_class, zeros(1, data_point_count, lib_pointer_class(1:(end-3))));
if ~calllib('ornot', 'unpack_zstd_compressed_data', char(data_filename), data, data_byte_size)
    error(strcat('ornot: failed to unpack file: ', char(data_filename)));
end
data = data.Value;
if is_half
    data = typecast(data, 'half');
end
if is_complex
    data = complex(data(1:2:end), data(2:2:end));
end
bp.data = reshape(data, bp.header.raw_data_dimension);
end