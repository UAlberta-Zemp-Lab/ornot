function [bp, data, timestamps] = trimData(bp)
arguments (Input)
    bp(1, 1) ornot.BeamformParameters
end
arguments (Output)
    bp(1, 1) ornot.BeamformParameters
    data(:, :, :, :, :) {mustBeNumeric}
    timestamps int32
end

raw_data_dimension = max(bp.raw_data_dimension, 1);

assert(all(raw_data_dimension == size(bp.data, 1:4)), ...
    'ornot:trimData:InvalidArgument', ...
    "BeamformParameters.raw_data_dimension must match the size of BeamformParameters.data." ...
    );
if isempty(bp.channel_mapping)
    channel_mapping = 1:bp.channel_count;
else
    channel_mapping = bp.channel_mapping(1:bp.channel_count) + 1;
end
data = bp.data(1:bp.sample_count*bp.receive_event_count, channel_mapping, :, :);

data = reshape(data, bp.sample_count, bp.receive_event_count, bp.channel_count, raw_data_dimension(3), raw_data_dimension(4));
bp.data = [];

% The first two samples potentially hold a timestamp
if all (data(1:2, 1, 1, 1, 1) == data(1:2, 1, :, 1, 1))
    timestamps = zeros(size(data, 2, 4, 5), 'int32');
    for n = 1:numel(timestamps)
        [i, j, k] = ind2sub(size(timestamps), n);
        timestamps(i, j, k) = typecast(data(1:2, i, 1, j, k), 'int32');
    end
    data = data(3:end,:,:,:,:);
    bp.sample_count = bp.sample_count - 2;
    bp.time_offset = bp.time_offset - (2 / bp.sampling_frequency);
else
    timestamps = int32.empty();
end
end