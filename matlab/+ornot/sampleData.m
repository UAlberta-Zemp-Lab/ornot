function image = sampleData(bp, settings, data, sampleTimes, apodizationArg)
arguments (Input)
    bp(1,1) ornot.BeamformParameters
    settings(1, 1) ornot.BeamformSettings
    data(:, 1)
    sampleTimes(:, 1) single
    apodizationArg(:, 1) single = 0;
end
arguments (Output)
    image(:, 1) {mustBeNumeric}
end

switch (settings.interpolation_mode)
    case OGLBeamformerInterpolationMode.Nearest
        interpolationMethod = 'nearest';
    case OGLBeamformerInterpolationMode.Linear
        interpolationMethod = 'linear';
    case OGLBeamformerInterpolationMode.Cubic
        interpolationMethod = 'pchip';
    otherwise
        error('tobe:sampleData:InvalidArgument', ...
            "Unsupported interpolation mode %d for sampleData.", ...
            settings.interpolation_mode ...
            );
end
% NOTE (DD): MATLAB's interp cannot handle integer data types, so the input needs to be converted to single
% We do want the output to be single regardless
image = single(interp1((0:numel(data)-1)/bp.sampling_frequency, single(data), sampleTimes, interpolationMethod, 0));
if ~isreal(data) && bp.demodulation_frequency ~= 0
    image = image .* exp(2 * pi * 1j * sampleTimes * bp.demodulation_frequency);
end
apodization = cos(settings.receive_fnumber * pi * apodizationArg).^2;
image = image .* apodization;
end