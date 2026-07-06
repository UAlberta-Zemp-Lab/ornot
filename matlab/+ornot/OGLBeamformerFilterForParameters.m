function filter = OGLBeamformerFilterForParameters(bp)
arguments (Input)
    bp(1,1) ornot.BeamformParameters
end
arguments (Output)
    filter(1,1) OGLBeamformerFilter
end

filter = OGLBeamformerFilter;
filter.sampling_frequency = bp.sampling_frequency / 2;
switch class(bp.emission_parameters)
    case "ZBP.EmissionSineParameters"
        kaiser                  = OGLBeamformerFilterParameters.Kaiser;
        kaiser.length           = 36;
        kaiser.beta             = 5.65;
        kaiser.cutoff_frequency = 0.5*bp.emission_parameters.frequency;

        filter.kind = OGLBeamformerFilterKind.Kaiser;
        filter.data = kaiser.toBytes();
    case "ZBP.EmissionChirpParameters"
        chirp                   = OGLBeamformerFilterParameters.MatchedChirp;
        chirp.duration          = bp.emission_parameters.duration;
        chirp.min_frequency     = bp.emission_parameters.min_frequency - bp.demodulation_frequency;
        chirp.max_frequency     = bp.emission_parameters.max_frequency - bp.demodulation_frequency;

        filter.kind    = OGLBeamformerFilterKind.MatchedChirp;
        filter.data    = chirp.toBytes();
        filter.complex = 1;
end
end
