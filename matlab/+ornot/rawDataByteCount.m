function byteCount = rawDataByteCount(bp)
arguments (Input)
    bp(1,1) ornot.BeamformParameters
end
arguments (Output)
    byteCount(1,1) double
end

unitSize = ornot.dataKindByteCount(bp.raw_data_kind) * double(bp.sample_count);
acquisitionCount = double(bp.receive_event_count) ...
    * double(bp.data_frame_count) * double(bp.ensemble_count);
switch bp.data_layout_kind
    case ZBP.DataLayoutKind.Block
        parameters = bp.block_data_layout_parameters;
        unitCount = acquisitionCount * double(bp.channel_count);
        if parameters.units_per_block == 0 || parameters.block_size == 0
            byteCount = unitCount * unitSize;
        else
            byteCount = ceil(unitCount / double(parameters.units_per_block)) ...
                * double(parameters.block_size);
        end
    case ZBP.DataLayoutKind.VsxStack
        parameters = bp.vsx_stack_data_layout_parameters;
        assert(parameters.units_per_stack > 0 ...
                && parameters.stack_channel_count >= bp.channel_count ...
                && parameters.stack_size >= unitSize * parameters.units_per_stack, ...
            'ornot:rawDataByteCount:InvalidVsxStackParameters', ...
            'VSX stack parameters do not describe the data dimensions.');
        stackCount = ceil(acquisitionCount / double(parameters.units_per_stack));
        byteCount = stackCount * double(parameters.stack_channel_count) ...
            * double(parameters.stack_size);
    otherwise
        error('ornot:rawDataByteCount:UnsupportedLayout', ...
            'Unsupported data layout kind: %d.', int32(bp.data_layout_kind));
end
end
