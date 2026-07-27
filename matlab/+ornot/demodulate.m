function [bp, data] = demodulate(bp, data)
arguments (Input)
    bp(1, 1) ornot.BeamformParameters
    data(:, :, :, :, :) {mustBeNumeric}
end
arguments (Output)
    bp(1, 1) ornot.BeamformParameters
    data(:, :, :, :, :) {mustBeNumeric}
end

frame_count = size(data, 4);
demodulation_frequencies = bp.demodulation_frequencies;
assert(isscalar(demodulation_frequencies) || numel(demodulation_frequencies) == frame_count, ...
    'ornot:demodulate:InvalidArgument', ...
    "Demodulation frequency count must be one or match the number of data frames." ...
    );
if isscalar(demodulation_frequencies)
    demodulation_frequencies = repmat(demodulation_frequencies, 1, frame_count);
end

if any(demodulation_frequencies ~= 0)
    if isreal(data) && bp.sampling_mode == ZBP.SamplingMode.Bandpass
        data = complex(data(1:2:2*floor(size(data, 1)/2), :, :, :, :), data(2:2:2*floor(size(data, 1)/2), :, :, :, :));
        bp.sampling_frequency = bp.sampling_frequency / 2;
    end
    t = (0:(size(data, 1)-1))'/bp.sampling_frequency;
    phase = exp(-1j * 2 * pi * t .* demodulation_frequencies);
    phase = reshape(phase, size(data, 1), 1, 1, frame_count, 1);
    data = single(data) .* phase;
end
end