function [bp, data] = demodulate(bp, data)
arguments (Input)
    bp(1, 1) ornot.BeamformParameters
    data(:, :, :, :, :) {mustBeNumeric}
end
arguments (Output)
    bp(1, 1) ornot.BeamformParameters
    data(:, :, :, :, :) {mustBeNumeric}
end

if bp.demodulation_frequency ~= 0
    if isreal(data) && bp.sampling_mode == ZBP.SamplingMode.Bandpass
        data = complex(data(1:2:2*floor(size(data, 1)/2), :, :, :, :), data(2:2:2*floor(size(data, 1)/2), :, :, :, :));
        bp.sampling_frequency = bp.sampling_frequency / 2;
    end
    t = (0:(size(data, 1)-1))'/bp.sampling_frequency;
    phase = exp(-1j * 2 * pi * bp.demodulation_frequency * t);
    phase = reshape(phase, [], 1);
    data = single(data) .* phase;
end
end