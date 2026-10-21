function bytes = convertDataLayout(bytes, oldLayout, newLayout, options)
arguments (Input)
    bytes uint8
    oldLayout(1,1) ornot.BeamformParameters
    newLayout(1,1) ornot.BeamformParameters
    options.UnitIndices(:,1) uint32 = uint32.empty(0, 1)
    options.ChannelOrder(:, :, :) uint16 = uint16.empty(0, 0, 0)
end
arguments (Output)
    bytes uint8
end

if oldLayout.raw_data_kind == newLayout.raw_data_kind ...
        && oldLayout.sample_count == newLayout.sample_count ...
        && oldLayout.receive_event_count == newLayout.receive_event_count ...
        && oldLayout.channel_count == newLayout.channel_count ...
        && oldLayout.data_frame_count == newLayout.data_frame_count ...
        && oldLayout.ensemble_count == newLayout.ensemble_count ...
        && oldLayout.data_layout_kind == newLayout.data_layout_kind ...
        && isequal(oldLayout.acquisition_precedence, newLayout.acquisition_precedence) ...
        && isequal(layoutParameters(oldLayout), layoutParameters(newLayout)) ...
        && isempty(options.UnitIndices) && isempty(options.ChannelOrder)
    return
end

oldUnitSize = ornot.dataKindByteCount(oldLayout.raw_data_kind) * double(oldLayout.sample_count);
newUnitSize = ornot.dataKindByteCount(newLayout.raw_data_kind) * double(newLayout.sample_count);
assert(oldUnitSize == newUnitSize, 'ornot:convertDataLayout:IncompatibleLayouts', ...
    'Data layouts must describe units with the same byte size.');

sizes = double([oldLayout.receive_event_count, oldLayout.channel_count, ...
    oldLayout.data_frame_count, oldLayout.ensemble_count]);
assert(isequal(sizes, double([newLayout.receive_event_count, newLayout.channel_count, ...
    newLayout.data_frame_count, newLayout.ensemble_count])), ...
    'ornot:convertDataLayout:IncompatibleLayouts', ...
    'Data layouts must describe the same logical dimensions.');

unitCount = prod(sizes);
assert(numel(bytes) >= ornot.rawDataByteCount(oldLayout), ...
    'ornot:convertDataLayout:InvalidData', 'The input byte array is too small.');

if ~isempty(options.UnitIndices)
    expectedUnitIndexCount = double(oldLayout.receive_event_count) * double(oldLayout.data_frame_count);
    assert(numel(options.UnitIndices) == expectedUnitIndexCount ...
            && isequal(sort(double(options.UnitIndices(:))), (0:(expectedUnitIndexCount - 1)).'), ...
        'ornot:convertDataLayout:InvalidUnitIndices', ...
        'Unit indices must be a zero-based permutation with one entry per receive-event/data-frame pair.');
end
if ~isempty(options.ChannelOrder)
    channelCount = double(oldLayout.channel_count);
    receiveCount = double(oldLayout.receive_event_count);
    dataFrameCount = double(oldLayout.data_frame_count);
    assert(isequal(size(options.ChannelOrder, 1), channelCount) ...
            && size(options.ChannelOrder, 2) == receiveCount ...
            && size(options.ChannelOrder, 3) == dataFrameCount, ...
        'ornot:convertDataLayout:InvalidChannelOrder', ...
        'Channel order must contain one channel permutation per receive-event/data-frame pair.');
    expectedChannelOrder = repmat((0:(channelCount - 1)).', 1, receiveCount * dataFrameCount);
    actualChannelOrder = reshape(double(options.ChannelOrder), channelCount, []);
    assert(isequal(sort(actualChannelOrder, 1), expectedChannelOrder), ...
        'ornot:convertDataLayout:InvalidChannelOrder', ...
        'Each channel order must be a zero-based permutation of all data channels.');
    assert(oldLayout.data_layout_kind == ZBP.DataLayoutKind.VsxStack, ...
        'ornot:convertDataLayout:InvalidChannelOrder', ...
        'Per-acquisition channel ordering is only supported for VSX stack layouts.');
end

source = bytes;
bytes = zeros(1, newUnitSize * unitCount, 'uint8');
for acquisitionIndex = 0:(unitCount - 1)
    indices = logicalIndices(acquisitionIndex, sizes);
    sourceIndices = indices;
    if ~isempty(options.ChannelOrder)
        sourceIndices(2) = double(options.ChannelOrder( ...
            indices(2) + 1, indices(1) + 1, indices(3) + 1));
    end
    oldOffset = layoutOffset(oldLayout, sourceIndices, oldUnitSize, options.UnitIndices);
    newOffset = layoutOffset(newLayout, indices, newUnitSize, uint32.empty(0, 1));
    bytes(newOffset + (1:newUnitSize)) = source(oldOffset + (1:oldUnitSize));
end
end

function indices = logicalIndices(index, sizes)
indices = zeros(1, 4);
indices(1) = mod(index, sizes(1));
index = floor(index / sizes(1));
indices(2) = mod(index, sizes(2));
index = floor(index / sizes(2));
indices(3) = mod(index, sizes(3));
indices(4) = floor(index / sizes(3));
end

function offset = layoutOffset(layout, indices, unitSize, unitIndices)
switch layout.data_layout_kind
    case ZBP.DataLayoutKind.Block
        unitIndex = 0;
        stride = 1;
        dimensions = [layout.receive_event_count, layout.channel_count, ...
            layout.data_frame_count, layout.ensemble_count];
        parameters = layout.block_data_layout_parameters;
        for dimension = double(parameters.precedence(:)')
            unitIndex = unitIndex + indices(dimension + 1) * stride;
            stride = stride * double(dimensions(dimension + 1));
        end
        if parameters.units_per_block == 0 || parameters.block_size == 0
            offset = unitIndex * unitSize;
        else
            offset = floor(unitIndex / double(parameters.units_per_block)) * double(parameters.block_size) ...
                + mod(unitIndex, double(parameters.units_per_block)) * unitSize;
        end
    case ZBP.DataLayoutKind.VsxStack
        parameters = layout.vsx_stack_data_layout_parameters;
        assert(parameters.units_per_stack > 0 ...
                && parameters.stack_channel_count >= layout.channel_count ...
                && parameters.stack_size >= unitSize * double(parameters.units_per_stack), ...
            'ornot:convertDataLayout:InvalidVsxStackParameters', ...
            'VSX stack parameters do not describe the layout dimensions.');
        if ~isempty(unitIndices)
            expectedCount = double(layout.receive_event_count) * double(layout.data_frame_count);
            assert(numel(unitIndices) == expectedCount, ...
                'ornot:convertDataLayout:InvalidUnitIndices', ...
                'Unit indices must contain one entry per receive-event/data-frame pair.');
            tupleIndex = indices(1) + indices(3) * double(layout.receive_event_count) + 1;
            unitIndex = double(unitIndices(tupleIndex)) ...
                + indices(4) * expectedCount;
        else
            unitIndex = indices(1) + indices(3) * double(layout.receive_event_count) ...
                + indices(4) * double(layout.receive_event_count) * double(layout.data_frame_count);
        end

        stackIndex = floor(unitIndex / double(parameters.units_per_stack));
        unitIndexWithinStack = mod(unitIndex, double(parameters.units_per_stack));
        offset = stackIndex * double(parameters.stack_channel_count) * double(parameters.stack_size) ...
            + indices(2) * double(parameters.stack_size) ...
            + unitIndexWithinStack * unitSize;
    otherwise
        error('ornot:convertDataLayout:UnsupportedLayout', ...
            'Unsupported data layout kind: %d.', int32(layout.data_layout_kind));
end
offset = double(offset);
end

function parameters = layoutParameters(layout)
switch layout.data_layout_kind
    case ZBP.DataLayoutKind.Block
        parameters = layout.block_data_layout_parameters;
    case ZBP.DataLayoutKind.VsxStack
        parameters = layout.vsx_stack_data_layout_parameters;
    otherwise
        error('ornot:convertDataLayout:UnsupportedLayout', ...
            'Unsupported data layout kind: %d.', int32(layout.data_layout_kind));
end
end