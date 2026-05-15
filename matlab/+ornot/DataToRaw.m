function bytes = DataToRaw(data, compressionKind)
arguments (Input)
    data {mustBeNumeric}
    compressionKind(1,1) ZBP.DataCompressionKind
end
arguments (Output)
    bytes   uint8
end

if ~isreal(data)
    data = [real(data(:)), imag(data(:))]';
end
data = typecast(data(:), 'uint8');

switch compressionKind
    case ZBP.DataCompressionKind.ZSTD
        bytes = libpointer('uint8Ptr', zeros(1, calllib('ornot', 'zstd_compress_bound', numel(data)), 'uint8'));
        outputCount = libpointer('uint64Ptr', uint64(numel(bytes.Value)));
        if outputCount.Value > 0
            if ~calllib('ornot', 'zstd_compress', bytes, outputCount, data, numel(data))
                error('ornot: failed to compress data');
            end
        end
        bytes = bytes.Value(1:outputCount.Value);
    case ZBP.DataCompressionKind.None
        bytes = data;
    otherwise
        error('ornot: unsupported data compression kind');
end
end
