function [bp, data] = filterTransmitWaveform(bp, data)
arguments (Input)
    bp(1, 1) ornot.BeamformParameters
    data(:, :, :, :, :) {mustBeNumeric}
end
arguments (Output)
    bp(1, 1) ornot.BeamformParameters
    data(:, :, :, :, :) {mustBeNumeric}
end
frame_count = size(data, 4);
assert(isscalar(bp.emission_descriptors) || numel(bp.emission_descriptors) == frame_count, ...
    'ornot:filterTransmitWaveform:InvalidArgument', ...
    "Emission descriptor count must be one or match the number of data frames." ...
    );
assert(isscalar(bp.demodulation_frequencies) || numel(bp.demodulation_frequencies) == frame_count, ...
    'ornot:filterTransmitWaveform:InvalidArgument', ...
    "Demodulation frequency count must be one or match the number of data frames." ...
    );

for frame_index = 1:frame_count
    if isscalar(bp.emission_descriptors)
        descriptor_index = bp.emission_descriptors;
    else
        descriptor_index = bp.emission_descriptors(frame_index);
    end
    emissionParameters = bp.emission_parameters{descriptor_index};
    if isscalar(bp.demodulation_frequencies)
        demodulation_frequency = bp.demodulation_frequencies;
    else
        demodulation_frequency = bp.demodulation_frequencies(frame_index);
    end

    switch class(emissionParameters)
        case "ZBP.EmissionSineParameters"
            flt = fir1(36, 0.5*emissionParameters.frequency/(bp.sampling_frequency/2), kaiser(37, 5.65));
        case "ZBP.EmissionChirpParameters"
            emissionParameters.min_frequency = emissionParameters.min_frequency - demodulation_frequency;
            emissionParameters.max_frequency = emissionParameters.max_frequency - demodulation_frequency;
            excitation = ornot.generateChirp(emissionParameters, ...
                (0:emissionParameters.duration*bp.sampling_frequency-1)'/bp.sampling_frequency);
            flt = 0.5 * conj(fliplr(excitation));
        otherwise
            error('ornot:filterTransmitWaveform:InvalidArgument', ...
                "Unsupported emission parameter class %s.", class(emissionParameters));
    end

    data(:, :, :, frame_index, :) = filter(flt, 1, data(:, :, :, frame_index, :));
    bp.time_delays(frame_index) = bp.time_delays(frame_index) ...
        + single((length(flt) - 1) / (2 * bp.sampling_frequency));
end
end