function [bp, data] = filterTransmitWaveform(bp, data)
arguments (Input)
    bp(1, 1) ornot.BeamformParameters
    data(:, :, :, :, :) {mustBeNumeric}
end
arguments (Output)
    bp(1, 1) ornot.BeamformParameters
    data(:, :, :, :, :) {mustBeNumeric}
end
switch class(bp.emission_parameters)
    case "ZBP.EmissionSineParameters"
        flt = fir1(36, 0.5*bp.emission_parameters.frequency/(bp.sampling_frequency/2), kaiser(37, 5.65));
    case "ZBP.EmissionChirpParameters"
        emissionParameters = bp.emission_parameters;
        emissionParameters.min_frequency = emissionParameters.min_frequency - bp.demodulation_frequency;
        emissionParameters.max_frequency = emissionParameters.max_frequency - bp.demodulation_frequency;
        excitation = ornot.generateChirp(emissionParameters, (0:emissionParameters.duration*bp.sampling_frequency-1)'/bp.sampling_frequency);
        flt = 0.5 * conj(fliplr(excitation));
end
data = filter(flt, 1, data);
bp.time_offset = bp.time_offset + (length(flt) - 1) / (2 * bp.sampling_frequency);
end