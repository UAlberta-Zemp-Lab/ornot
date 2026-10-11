function filter = OGLBeamformerFilterForParameters(samplingFrequency, demodulationFrequency, emissionParameters)
arguments (Input)
    samplingFrequency(1,1) single {mustBePositive}
    demodulationFrequency(1,1) single {mustBeNonnegative}
    emissionParameters(1,1) {mustBeA(emissionParameters, ...
        ["ZBP.EmissionSineParameters", "ZBP.EmissionChirpParameters", "ZBP.EmissionUnipolarBurstParameters", "ZBP.EmissionUnipolarBarkerParameters"])}
end
arguments (Output)
    filter(1,1) OGLBeamformerFilter
end

filter = OGLBeamformerFilter;
filter.sampling_frequency = samplingFrequency / 2;
switch class(emissionParameters)
    case "ZBP.EmissionSineParameters"
        kaiser                  = OGLBeamformerFilterParameters.Kaiser;
        kaiser.length           = 36;
        kaiser.beta             = 5.65;
        kaiser.cutoff_frequency = 0.5*emissionParameters.frequency;

        filter.kind = OGLBeamformerFilterKind.Kaiser;
        filter.data = kaiser.toBytes();
    case "ZBP.EmissionChirpParameters"
        chirp                   = OGLBeamformerFilterParameters.MatchedChirp;
        chirp.duration          = emissionParameters.duration;
        chirp.min_frequency     = emissionParameters.min_frequency - demodulationFrequency;
        chirp.max_frequency     = emissionParameters.max_frequency - demodulationFrequency;

        filter.kind    = OGLBeamformerFilterKind.MatchedChirp;
        filter.data    = chirp.toBytes();
        filter.complex = 1;
    case "ZBP.EmissionUnipolarBurstParameters"
        kaiser                  = OGLBeamformerFilterParameters.Kaiser;
        kaiser.length           = 36;
        kaiser.beta             = 5.65;
        kaiser.cutoff_frequency = 0.5*emissionParameters.frequency;

        filter.kind = OGLBeamformerFilterKind.Kaiser;
        filter.data = kaiser.toBytes();
    case "ZBP.EmissionUnipolarBarkerParameters"
        barker                 = OGLBeamformerFilterParameters.MatchedBarker;
        barker.code_length     = uint32(emissionParameters.code_length);
        barker.chip_duration   = emissionParameters.burst_parameters.cycles / emissionParameters.burst_parameters.frequency;
        barker.polarity        = emissionParameters.burst_parameters.polarity;
        barker.unipolar        = true;

        filter.kind = OGLBeamformerFilterKind.MatchedBarker;
        filter.data = barker.toBytes();
end
end
