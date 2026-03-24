function byteCount = dataKindByteCount(kind)
arguments (Input)
    kind ZBP.DataKind
end
arguments (Output)
    byteCount double
end
byteCount = zeros(size(kind));
for i = 1:numel(kind)
    switch kind(i)
        case {ZBP.DataKind.Int16, ZBP.DataKind.Float16}
            byteCount(i) = 2;
        case {ZBP.DataKind.Int16Complex, ZBP.DataKind.Float16Complex, ZBP.DataKind.Float32}
            byteCount(i) = 4;
        case ZBP.DataKind.Float32Complex
            byteCount(i) = 8;
    end
end
end