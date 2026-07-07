
function bsp = updateOglBeamformerSimpleParametersFromSettings(bsp, settings)
arguments (Input)
    bsp(1,1) OGLBeamformerSimpleParameters
    settings(1,1) ornot.BeamformSettings
end
arguments (Output)
    bsp(1,1) OGLBeamformerSimpleParameters
end

bsp.interpolation_mode = settings.interpolation_mode;
bsp.coherency_weighting = settings.coherency_weighting;
bsp.f_number = settings.receive_fnumber;
bsp.decimation_rate = settings.decimation_rate;

bsp.compute_stages_count = numel(settings.compute_stages);
bsp.compute_stages(1:bsp.compute_stages_count) = settings.compute_stages;
end