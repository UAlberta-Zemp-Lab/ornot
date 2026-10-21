function images = beamform(bp, settings)
arguments (Input)
    bp(1, 1) ornot.BeamformParameters
    settings(1,1) ornot.BeamformSettings
end
arguments (Output)
    images(:,:,:) cell
end

% Allocate Section Count x Ensemble Count x Region Count images
images_size = [bp.data_frame_count, bp.ensemble_count, numel(settings.regions)];
if nargout ~= 0
    images = cell(images_size);
else
    images = {};
end

targetLayout = ornot.BeamformParameters();
targetLayout.raw_data_kind = bp.raw_data_kind;
targetLayout.sample_count = bp.sample_count;
targetLayout.receive_event_count = bp.receive_event_count;
targetLayout.channel_count = bp.channel_count;
targetLayout.data_frame_count = bp.data_frame_count;
targetLayout.ensemble_count = bp.ensemble_count;
targetLayout.data_layout_kind = ZBP.DataLayoutKind.VsxStack;
targetLayout.acquisition_precedence = uint32([ ...
    ZBP.LayoutPrecedence.ReceiveEvent, ...
    ZBP.LayoutPrecedence.Channel, ...
    ZBP.LayoutPrecedence.DataFrame, ...
    ZBP.LayoutPrecedence.Ensemble]);
beamformerParameters = ZBP.VsxStackDataLayoutParameters;
beamformerParameters.precedence = targetLayout.acquisition_precedence([1, 3, 4]);
beamformerParameters.stack_size = uint32(double(bp.sample_count) ...
    * double(bp.receive_event_count) ...
    * ornot.dataKindByteCount(ZBP.DataKind(bp.raw_data_kind)));
beamformerParameters.stack_channel_count = bp.channel_count;
beamformerParameters.units_per_stack = bp.receive_event_count;
targetLayout.vsx_stack_data_layout_parameters = beamformerParameters;

data = bp.data;
if ~isreal(data)
    dataClass = class(real(data));
    dataBytes = typecast([real(data(:)); imag(data(:))], 'uint8');
else
    dataClass = class(data);
    dataBytes = typecast(data(:), 'uint8');
end
dataBytes = ornot.convertDataLayout(dataBytes, bp, targetLayout, ...
    UnitIndices=bp.unit_indices, ...
    ChannelOrder=bp.acquisition_channel_order);
if ~isreal(data)
    data = typecast(dataBytes, dataClass);
    half = numel(data) / 2;
    data = complex(data(1:half), data(half + 1:end));
else
    data = typecast(dataBytes, dataClass);
end
data = reshape(data, [ ...
    double(bp.sample_count) * double(bp.receive_event_count), ...
    bp.channel_count, bp.data_frame_count, bp.ensemble_count]);

for i = 1:prod(images_size)
    [section_index, ensemble_index, region_index] = ind2sub(images_size, i);

    bsp = ornot.OGLBeamformerSimpleParametersFromParameters(bp, section_index);
    bsp = ornot.updateOglBeamformerSimpleParametersFromSettings(bsp, settings);
    bsp = updateBspFilter(bsp, bp, section_index);

    switch class(data)
        case 'int16'
            if isreal(data)
                bsp.data_kind = int32(OGLBeamformerDataKind.Int16);
            else
                bsp.data_kind = int32(OGLBeamformerDataKind.Int16Complex);
                data = reshape([real(data);imag(data)],[],1);
            end
        case {'single', 'double'}
            if isa(data, 'double')
                data = single(data);
            end
            if isreal(data)
                bsp.data_kind = int32(OGLBeamformerDataKind.Float32);
            else
                bsp.data_kind = int32(OGLBeamformerDataKind.Float32Complex);
                data = reshape([real(data);imag(data)],[],1);
            end
    end

    bsp.output_points(1:3) = settings.regions(region_index).output_points;
    bsp.output_points(4) = settings.average_frame;
    bsp.das_voxel_transform = settings.regions(region_index).das_voxel_transform(:);

    if nargout ~= 0
        images{section_index, ensemble_index, region_index} = ornot.beamformSimpleParameters(bsp, data(:, :, section_index, ensemble_index));
    else
        ornot.beamformSimpleParameters(bsp, data(:, :, section_index));
    end
end

end

function bsp = updateBspFilter(bsp, bp, section_number)
arguments (Input)
    bsp(1,1) OGLBeamformerSimpleParameters
    bp(1,1) ornot.BeamformParameters
    section_number(1,1) uint16 = 1;
end
arguments (Output)
    bsp(1,1) OGLBeamformerSimpleParameters
end

demodulate_shader_index = find(bsp.compute_stages == OGLBeamformerShaderStage.Demodulate);

if ~isempty(demodulate_shader_index)
    filter_slot = mod(section_number - 1, 4);
    filter      = ornot.OGLBeamformerFilterForParameters(bp.sampling_frequency, bp.demodulation_frequencies(section_number), bp.emission_parameters{bp.emission_descriptors(section_number)});
    try
        assert(calllib('ogl_beamformer_lib', 'beamformer_create_filter', struct(filter), filter_slot, 0));
    catch ME
        errmsg = calllib('ogl_beamformer_lib', 'beamformer_get_last_error_string');
        warning(strcat('beamformer error: ', errmsg));
        rethrow(ME);
    end

    bsp.compute_stage_parameters(demodulate_shader_index) = filter_slot;
end
end