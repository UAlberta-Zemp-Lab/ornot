classdef BeamformSettings
    properties
        regions ornot.Region
        interpolation_mode(1,1) OGLBeamformerInterpolationMode
        receive_fnumber(1,1) single = 0;
        coherency_weighting(1,1) logical = false;
        decimation_rate(1,1) uint8 = 1;
        compute_stages(:,1) OGLBeamformerShaderStage = [ ...
            OGLBeamformerShaderStage.Demodulate, ...
            OGLBeamformerShaderStage.Decode, ...
            OGLBeamformerShaderStage.DAS
            ];
    end
end