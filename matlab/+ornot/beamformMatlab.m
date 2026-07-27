function images = beamformMatlab(bp, settings)
arguments (Input)
    bp(1, 1) ornot.BeamformParameters
    settings(1,1) ornot.BeamformSettings
end
arguments (Output)
    images(:,:,:) cell
end

% Allocate Section Count x Ensemble Count x Region Count images
images_size = [bp.raw_data_dimension(3), bp.raw_data_dimension(4), numel(settings.regions)];
images = cell(images_size);


[bp, data] = ornot.trimData(bp);
for stageIndex = 1:numel(settings.compute_stages)
    compute_stage = settings.compute_stages(stageIndex);
    switch compute_stage
        case OGLBeamformerShaderStage.Demodulate
            [bp, data] = ornot.demodulate(bp, data);
            if ~any(settings.compute_stages == OGLBeamformerShaderStage.Filter)
                [bp, data] = ornot.filterTransmitWaveform(bp, data);
            end
        case OGLBeamformerShaderStage.Hilbert
            data = hilbert(single(data));
            bp.demodulation_frequency = 0;
        case OGLBeamformerShaderStage.Decode
            data = ornot.decode(bp, data);
        case OGLBeamformerShaderStage.DAS
            for i = 1:prod(images_size)
                [section_index, ensemble_index, region_index] = ind2sub(images_size, i);
                d = data(:, :, :, section_index, ensemble_index);

                switch bp.acquisition_kind
                    case {ZBP.AcquisitionKind.FORCES, ZBP.AcquisitionKind.UFORCES}
                        images{section_index, ensemble_index, region_index} ...
                            = tobe.delayAndSumForces(bp, settings, d, section_index, region_index);
                    case {ZBP.AcquisitionKind.HERCULES, ZBP.AcquisitionKind.uHERCULES, ZBP.AcquisitionKind.HERO_PA}
                        images{section_index, ensemble_index, region_index} ...
                            = tobe.delayAndSumHercules(bp, settings, d, section_index, region_index);
                    case {ZBP.AcquisitionKind.RCA_VLS, ZBP.AcquisitionKind.RCA_TPW}
                        images{section_index, ensemble_index, region_index} ...
                            = tobe.delayAndSumRca(bp, settings, d, section_index, region_index);
                    otherwise
                        error(...
                            'tobe:beamformMatlab:InvalidArgument', ...
                            'Acquisition kind %s is not currently supported', string(bp.acquisition_kind)...
                            );
                end
            end
        otherwise
            error('tobe:beamformForces:InvalidArgument', ...
                "Unsupported compute stage %d for beamformForces.", ...
                compute_stage ...
                );
    end
end
end