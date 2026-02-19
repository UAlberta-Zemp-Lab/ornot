% Ensure that data is of the correct type as specified by bsp.data_kind
function beamformed = beamformSimpleParameters(bsp, data, timeout_milliseconds)
arguments (Input)
    bsp(1,1) OGLBeamformerSimpleParameters
    data
    timeout_milliseconds(1,1) single = 10*1e3;
end
arguments (Output)
    beamformed single
end

switch bsp.data_kind
    case OGLBeamformerDataKind.Int16
        data_size_multiplier = 2;
    case OGLBeamformerDataKind.Int16Complex
        data_size_multiplier = 4;
    case OGLBeamformerDataKind.Float32
        data_size_multiplier = 4;
    case OGLBeamformerDataKind.Float32Complex
        data_size_multiplier = 8;
end
data_size = data_size_multiplier*prod(bsp.raw_data_dimensions);

output_count = prod(bsp.output_points(1:3)) * 2; % complex singles
output_data  = libpointer('singlePtr', zeros(1, output_count, 'single'));

try
    assert(calllib('ogl_beamformer_lib', 'beamformer_beamform_data', ...
        struct(bsp), data, data_size, output_data, timeout_milliseconds));
catch ME
    errmsg = calllib('ogl_beamformer_lib', 'beamformer_get_last_error_string');
    warning(strcat('beamformer error: ', errmsg));
    rethrow(ME);
end

beamformed = complex(output_data.Value(1:2:end), output_data.Value(2:2:end));
beamformed = squeeze(reshape(beamformed, bsp.output_points(1:3)))';

end