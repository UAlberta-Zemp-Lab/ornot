function data = decode(bp, data)
arguments (Input)
    bp(1, 1) ornot.BeamformParameters
    data(:, :, :, :, :) {mustBeNumeric}
end

switch bp.decode_mode
    case ZBP.DecodeMode.None
        H = eye(bp.receive_event_count);
    case ZBP.DecodeMode.Hadamard
        H = transpose(hadamard(single(bp.receive_event_count)));
    otherwise
        error('ornot:decode:InvalidArgument', ...
            "Unsupported Decode Mode!" ...
            );
end
H = cast(H, 'like', data);
originalSize = size(data);

data = reshape(data, bp.sample_count, bp.receive_event_count, []);
decodedData = zeros(size(data), 'like', data);
for i = 1:bp.receive_event_count
    % NOTE (DD): This assumes that each row of H corresponds to a transmit event
    decodedData(:, i, :) = sum(data .* reshape(H(:, i), 1, []), 2);
end
data = decodedData;
data = reshape(data, originalSize);
end