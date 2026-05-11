function bp = DataFromRaw(bp, bytes)
arguments (Input)
	bp(1,1) ornot.BeamformParameters
	bytes   uint8
end
arguments (Output)
	bp(1,1) ornot.BeamformParameters
end

switch bp.raw_data_compression_kind
	case ZBP.DataCompressionKind.ZSTD
		data_point_count = prod(max(bp.raw_data_dimension, 1));
		data_byte_size = ornot.dataKindByteCount(bp.raw_data_kind) * data_point_count;

		data = libpointer('uint8Ptr', zeros(1, data_byte_size, 'uint8'));
		if ~calllib('ornot', 'unpack_zstd_compressed_data', bytes, numel(bytes), data, data_byte_size)
			error('ornot: failed to decompress data');
		end
	case ZBP.DataCompressionKind.None
	otherwise
    error('ornot: unsuppored data compression kind');
end

data = data.Value;
switch bp.raw_data_kind
	case ZBP.DataKind.Int16
		bp.data = typecast(data, 'int16');
	case ZBP.DataKind.Int16Complex
		bp.data = typecast(data, 'int16');
		bp.data = complex(bp.data(1:2:end), bp.data(2:2:end));
	case ZBP.DataKind.Float32
		bp.data = typecast(data, 'single');
	case ZBP.DataKind.Float32Complex
		bp.data = typecast(data, 'single');
		bp.data = complex(bp.data(1:2:end), bp.data(2:2:end));
	case ZBP.DataKind.Float16
		bp.data = typecast(typecast(data, 'uint16'), 'half');
	case ZBP.DataKind.Float16Complex
		bp.data = typecast(typecast(data, 'uint16'), 'half');
		bp.data = complex(bp.data(1:2:end), bp.data(2:2:end));
end

bp.data = reshape(bp.data, bp.raw_data_dimension);
end
