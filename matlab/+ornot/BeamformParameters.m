classdef BeamformParameters
    %% Depending on the source of this data, some properties may be empty
    properties
        raw_data_kind(1,1)                    ZBP.DataKind
        raw_data_compression_kind(1,1)        ZBP.DataCompressionKind
        data_layout_kind(1,1)                 ZBP.DataLayoutKind = ZBP.DataLayoutKind.VsxStack
        block_data_layout_parameters(1,1)     ZBP.BlockDataLayoutParameters = ZBP.BlockDataLayoutParameters
        vsx_stack_data_layout_parameters(1,1)  ZBP.VsxStackDataLayoutParameters = ZBP.VsxStackDataLayoutParameters
        element_count(1,2)                    uint32 = uint32([0, 0])
        acquisition_precedence(1,4)           uint32 = uint32([ ...
            ZBP.LayoutPrecedence.ReceiveEvent, ...
            ZBP.LayoutPrecedence.Channel, ...
            ZBP.LayoutPrecedence.DataFrame, ...
            ZBP.LayoutPrecedence.Ensemble])
        sample_count(1,1)                     uint32
        receive_event_count(1,1)              uint32
        channel_count(1,1)                    uint32
        data_frame_count(1,1)                 uint32
        ensemble_count(1,1)                   uint32
        decode_mode(1,1)                      ZBP.DecodeMode
        sampling_mode(1,1)                    ZBP.SamplingMode
        sampling_frequency(1,1)               single
        speed_of_sound(1,1)                   single
        transducer_transform_matrices(4,4,:) single
        transducer_tile_count(1,2)            uint32
        transducer_element_pitch(1,2)         single
        group_acquisition_time(1,1)           single
        ensemble_repetition_interval(1,1)     single
        acquisition_kind(1,1)                 ZBP.AcquisitionKind
        contrast_mode(1,1)                    ZBP.ContrastMode
        contrast_data_flags(1,1)              uint32
        demodulation_frequencies(1,:)         single
        time_delays(1,:)                      single
        strings(:,2)                          string
        emission_descriptors uint8
        % NOTE (DD): MATLAB won't allow for heterogenous arrays, without the classes being specifically defined as subclasses of a common superclass.
        % This means that we can't load emission parameters of different types into a single array, so we will load them into a cell array instead.
        emission_parameters cell
        contrast_parameters
        channel_mapping uint16
        row_channel_mapping uint16
        column_channel_mapping uint16
        unit_indices(:,1) uint32 = uint32.empty(0, 1)
        acquisition_channel_order uint16 % zero-based source channel order, channel x receive event x data frame
        acquisition_parameters
        transmit_receive_orientations uint8 % receive_event_count x data_frame_count
        focal_depths single % receive_event_count x data_frame_count
        origin_offsets single % receive_event_count x data_frame_count
        tilting_angles single % receive_event_count x data_frame_count
        sparse_elements uint16 % (receive_event_count - 1) x data_frame_count
        transmit_foci ZBP.RCATransmitFocus % receive_event_count x data_frame_count
        data
    end

    methods
        function bp = BeamformParameters()
            blockParameters = ZBP.BlockDataLayoutParameters;
            blockParameters.precedence = uint32([ ...
                ZBP.LayoutPrecedence.ReceiveEvent, ...
                ZBP.LayoutPrecedence.Channel, ...
                ZBP.LayoutPrecedence.DataFrame, ...
                ZBP.LayoutPrecedence.Ensemble]);
            blockParameters.block_size = uint32(0);
            blockParameters.units_per_block = uint32(0);
            bp.block_data_layout_parameters = blockParameters;

            stackParameters = ZBP.VsxStackDataLayoutParameters;
            stackParameters.precedence = uint32([ ...
                ZBP.LayoutPrecedence.ReceiveEvent, ...
                ZBP.LayoutPrecedence.DataFrame, ...
                ZBP.LayoutPrecedence.Ensemble]);
            stackParameters.stack_size = uint32(0);
            stackParameters.stack_channel_count = uint32(0);
            stackParameters.units_per_stack = uint32(0);
            stackParameters.row_channel_mapping_offset = int32(-1);
            stackParameters.column_channel_mapping_offset = int32(-1);
            stackParameters.unit_indices_offset = int32(-1);
            bp.vsx_stack_data_layout_parameters = stackParameters;
        end

        function ToFile(bp, filename)
            arguments (Input)
                bp(1,1) ornot.BeamformParameters
                filename(1,1) string
            end
            arguments (Output)
            end

            bytes = bp.ToBytes();
            fileId = fopen(filename, 'w');
            fwrite(fileId, bytes);
            fclose(fileId);
        end

        function bytes = ToBytes(bp)
            arguments (Input)
                bp(1,1) ornot.BeamformParameters
            end
            arguments (Output)
                bytes uint8
            end

            increment_offset = @ornot.BeamformParameters.increment_offset;
            set_bytes = @ornot.BeamformParameters.set_bytes;

            header = ZBP.HeaderV4;
            header.magic = ZBP.Constants.HeaderMagic;
            header.major = 4;
            header.minor = 0;
            header.sample_count = bp.sample_count;
            header.receive_event_count = bp.receive_event_count;
            header.channel_count = bp.channel_count;
            header.data_frame_count = bp.data_frame_count;
            header.ensemble_count = bp.ensemble_count;
            header.raw_data_kind = int32(bp.raw_data_kind);
            header.raw_data_compression_kind = int32(bp.raw_data_compression_kind);
            header.data_layout_kind = uint32(bp.data_layout_kind);
            header.element_count = bp.element_count;
            header.acquisition_precedence = bp.acquisition_precedence;
            header.decode_mode = int32(bp.decode_mode);
            header.sampling_mode = int32(bp.sampling_mode);
            header.sampling_frequency = bp.sampling_frequency;
            header.speed_of_sound = bp.speed_of_sound;
            header.transducer_element_pitch = bp.transducer_element_pitch;
            header.transducer_tile_count = bp.transducer_tile_count;
            header.group_acquisition_time = bp.group_acquisition_time;
            header.ensemble_repetition_interval = bp.ensemble_repetition_interval;
            header.acquisition_mode = int32(bp.acquisition_kind);
            header.contrast_mode = int32(bp.contrast_mode);

            dataByteCount = prod(...
                uint64(header.sample_count) * ...
                uint64(header.receive_event_count) * ...
                uint64(header.channel_count) * ...
                uint64(header.data_frame_count) * ...
                uint64(header.ensemble_count));
            assert(dataByteCount > 0, ...
                'ornot:BeamformParameters:InvalidArgument', ...
                'Data Byte count must be greater than 0');

            bytes = [];

            offset_alignment = ZBP.Constants.OffsetAlignment;
            offset = increment_offset(0, header.byteSize, offset_alignment);

            if ~isempty(bp.emission_descriptors)
                parameterOffsets = zeros(1, numel(bp.emission_parameters), 'uint32');
                parameterOffset = offset;
                for i = 1:numel(bp.emission_parameters)
                    parameterOffsets(i) = parameterOffset;
                    parameterOffset = increment_offset(parameterOffset, bp.emission_parameters{i}.byteSize, offset_alignment);
                    bytes = set_bytes(bytes, bp.emission_parameters{i}.toBytes(), parameterOffsets(i));
                end
                offset = parameterOffset;
                header.emission_descriptors_offset = offset;
                for i = 1:numel(bp.emission_descriptors)
                    emissionDescriptor = ZBP.EmissionDescriptor();
                    assert(bp.emission_descriptors(i) <= numel(bp.emission_parameters), "Emission Descriptor Index Out of Range");
                    emissionParameter = bp.emission_parameters{bp.emission_descriptors(i)};
                    switch class(emissionParameter)
                        case "ZBP.EmissionSineParameters"
                            emissionDescriptor.emission_kind = int32(ZBP.EmissionKind.Sine);
                        case "ZBP.EmissionChirpParameters"
                            emissionDescriptor.emission_kind = int32(ZBP.EmissionKind.Chirp);
                        otherwise
                            assert(false, "Unsupported Emission");
                    end
                    emissionDescriptor.parameters_offset = parameterOffsets(bp.emission_descriptors(i));
                    bytes = set_bytes(bytes, emissionDescriptor.toBytes(), offset);
                    offset = increment_offset(offset, emissionDescriptor.byteSize, offset_alignment);
                end
            else
                header.emission_descriptors_offset = -1;
            end

            assert(numel(bp.time_delays) == bp.data_frame_count)
            header.time_delays_offset = offset;
            offset = increment_offset(offset, 4*numel(bp.time_delays), offset_alignment);
            bytes = set_bytes(bytes, typecast(bp.time_delays, "uint8"), header.time_delays_offset);

            assert(numel(bp.demodulation_frequencies) == bp.data_frame_count)
            header.demodulation_frequencies_offset = offset;
            offset = increment_offset(offset, 4*numel(bp.demodulation_frequencies), offset_alignment);
            bytes  = set_bytes(bytes, typecast(bp.demodulation_frequencies, "uint8"), header.demodulation_frequencies_offset);

            assert(size(bp.transducer_transform_matrices, 3) == prod(bp.transducer_tile_count))
            header.transducer_transforms_offset = offset;
            offset = increment_offset(offset, 4*numel(bp.transducer_transform_matrices), offset_alignment);
            bytes = set_bytes(bytes, typecast(bp.transducer_transform_matrices(:), "uint8"), header.transducer_transforms_offset);

            if ~isempty(bp.contrast_parameters)
                assert(false, "Saving Contrast Parameters not currently supported")
            else
                header.contrast_parameters_offset = -1;
            end

            assert(~isempty(bp.acquisition_parameters), ...
                "Acquisition Parameters are empty, but acquisition kind requires acquisition parameters");

            switch bp.acquisition_kind
                case ZBP.AcquisitionKind.EPIC_FORCES
                    assert(isa(bp.acquisition_parameters, "ZBP.EPIC_FORCESParameters"));

                    assert(all(size(bp.transmit_foci) == [bp.receive_event_count, bp.data_frame_count]));

                    for i = 1:bp.data_frame_count
                        bp.acquisition_parameters(i).transmit_foci_offset = offset;
                        offset = increment_offset(offset, bp.receive_event_count*ZBP.RCATransmitFocus.byteSize, offset_alignment);
                        tfOffset = bp.acquisition_parameters(i).transmit_foci_offset;
                        for j = 1:bp.receive_event_count
                            bytes = set_bytes(bytes, bp.transmit_foci(j, i).toBytes(), tfOffset);
                            tfOffset = increment_offset(tfOffset, ZBP.RCATransmitFocus.byteSize, 1);
                        end
                    end
                case ZBP.AcquisitionKind.RCA_VLS
                    assert(isa(bp.acquisition_parameters, "ZBP.VLSParameters"));

                    assert(all(size(bp.focal_depths) == [bp.receive_event_count, bp.data_frame_count]));
                    assert(all(size(bp.origin_offsets) == [bp.receive_event_count, bp.data_frame_count]));
                    assert(all(size(bp.transmit_receive_orientations) == [bp.receive_event_count, bp.data_frame_count]));

                    for i = 1:bp.data_frame_count
                        focalDepths = bp.focal_depths(:, i);
                        bp.acquisition_parameters(i).focal_depths_offset = offset;
                        offset = increment_offset(offset, 4*numel(focalDepths), offset_alignment);
                        bytes = set_bytes(bytes, typecast(focalDepths, "uint8"), bp.acquisition_parameters(i).focal_depths_offset);

                        originOffsets = bp.origin_offsets(:, i);
                        bp.acquisition_parameters(i).origin_offsets_offset = offset;
                        offset = increment_offset(offset, 4*numel(originOffsets), offset_alignment);
                        bytes = set_bytes(bytes, typecast(originOffsets, "uint8"), bp.acquisition_parameters(i).origin_offsets_offset);

                        orientations = bp.transmit_receive_orientations(:, i);
                        bp.acquisition_parameters(i).transmit_receive_orientations_offset = offset;
                        offset = increment_offset(offset, numel(orientations), offset_alignment);
                        bytes = set_bytes(bytes, typecast(orientations, "uint8"), bp.acquisition_parameters(i).transmit_receive_orientations_offset);
                    end
                case ZBP.AcquisitionKind.RCA_TPW
                    assert(isa(bp.acquisition_parameters, "ZBP.TPWParameters"));

                    assert(all(size(bp.tilting_angles) == [bp.receive_event_count, bp.data_frame_count]));
                    assert(all(size(bp.transmit_receive_orientations) == [bp.receive_event_count, bp.data_frame_count]));

                    for i = 1:bp.data_frame_count
                        tiltingAngles = bp.tilting_angles(:, i);
                        bp.acquisition_parameters(i).tilting_angles_offset = offset;
                        offset = increment_offset(offset, 4*numel(tiltingAngles), offset_alignment);
                        bytes = set_bytes(bytes, typecast(tiltingAngles, "uint8"), bp.acquisition_parameters(i).tilting_angles_offset);

                        orientations = bp.transmit_receive_orientations(:, i);
                        bp.acquisition_parameters(i).transmit_receive_orientations_offset = offset;
                        offset = increment_offset(offset, numel(orientations), offset_alignment);
                        bytes = set_bytes(bytes, typecast(orientations, "uint8"), bp.acquisition_parameters(i).transmit_receive_orientations_offset);
                    end
                case {ZBP.AcquisitionKind.UFORCES, ZBP.AcquisitionKind.UHERCULES}
                    assert(all(size(bp.sparse_elements) == [bp.receive_event_count - 1, bp.data_frame_count]));

                    for i = 1:bp.data_frame_count
                        bp.acquisition_parameters(i).sparse_elements_offset = offset;
                        offset = increment_offset(offset, 2*numel(bp.sparse_elements(:,i)), offset_alignment);
                        bytes = set_bytes(bytes, typecast(bp.sparse_elements(:,i), "uint8"), bp.acquisition_parameters(i).sparse_elements_offset);
                    end
                case ZBP.AcquisitionKind.HERO_PA
                    assert(isa(bp.acquisition_parameters, "ZBP.HERO_PAParameters"));
                    assert(isscalar(bp.acquisition_parameters));
                case ZBP.AcquisitionKind.HEXDoppler
                    assert(isa(bp.acquisition_parameters, "ZBP.HEXDopplerParameters"));
                    assert(isscalar(bp.acquisition_parameters));

                    assert(sum(bp.acquisition_parameters.bin_count) == bp.receive_event_count);
                case ZBP.AcquisitionKind.XDoppler
                    assert(isa(bp.acquisition_parameters, "ZBP.XDopplerParameters"));
                    assert(isscalar(bp.acquisition_parameters));

                    assert(sum(bp.acquisition_parameters.angle_count) == bp.receive_event_count);

                    assert(~isempty(bp.tilting_angles));
                    assert(numel(bp.tilting_angles) == bp.receive_event_count);
                    bp.acquisition_parameters.tilting_angles_offset = offset;
                    offset = increment_offset(offset, 4*numel(bp.tilting_angles), offset_alignment);
                    bytes = set_bytes(bytes, typecast(bp.tilting_angles, "uint8"), bp.acquisition_parameters.tilting_angles_offset);
            end

            switch bp.acquisition_kind
                case ZBP.AcquisitionKind.FORCES
                    assert(isa(bp.acquisition_parameters, "ZBP.FORCESParameters"));
                case ZBP.AcquisitionKind.UFORCES
                    assert(isa(bp.acquisition_parameters, "ZBP.uFORCESParameters"));
                case ZBP.AcquisitionKind.EPIC_FORCES
                    assert(isa(bp.acquisition_parameters, "ZBP.EPIC_FORCESParameters"));
                case ZBP.AcquisitionKind.RCA_VLS
                    assert(isa(bp.acquisition_parameters, "ZBP.VLSParameters"));
                case ZBP.AcquisitionKind.RCA_TPW
                    assert(isa(bp.acquisition_parameters, "ZBP.TPWParameters"));
                case ZBP.AcquisitionKind.HERCULES
                    assert(isa(bp.acquisition_parameters, "ZBP.HERCULESParameters"));
                case ZBP.AcquisitionKind.UHERCULES
                    assert(isa(bp.acquisition_parameters, "ZBP.uHERCULESParameters"));
                case ZBP.AcquisitionKind.HERO_PA
                    assert(isa(bp.acquisition_parameters, "ZBP.HERO_PAParameters"));
                case ZBP.AcquisitionKind.HEXDoppler
                    assert(isa(bp.acquisition_parameters, "ZBP.HEXDopplerParameters"));
                case ZBP.AcquisitionKind.XDoppler
                    assert(isa(bp.acquisition_parameters, "ZBP.XDopplerParameters"));
                otherwise
                    assert(false, "Unsupported Acquisition Kind")
            end

            header.acquisition_parameters_offset = offset;
            for i = 1:numel(bp.acquisition_parameters)
                bytes = set_bytes(bytes, bp.acquisition_parameters(i).toBytes(), offset);
                offset = increment_offset(offset, bp.acquisition_parameters(i).byteSize, 1);
            end

            offset = increment_offset(offset, 0, offset_alignment);

            rowMappingValues = bp.row_channel_mapping;
            columnMappingValues = bp.column_channel_mapping;
            if ~isempty(bp.channel_mapping)
                assert(bp.data_layout_kind == ZBP.DataLayoutKind.VsxStack, ...
                    'ornot:BeamformParameters:UnsupportedV4ChannelMapping', ...
                    'Version 4 channel mappings require a VSX stack layout.');
                assert(numel(bp.channel_mapping) == bp.channel_count, ...
                    'ornot:BeamformParameters:InvalidChannelMapping', ...
                    'Channel mapping length must match the channel count.');
                channelMapping = bp.channel_mapping(:) + uint16(1);
                if isempty(rowMappingValues)
                    rowMappingValues = channelMapping;
                end
                if isempty(columnMappingValues)
                    columnMappingValues = channelMapping;
                end
            end

            switch bp.data_layout_kind
                case ZBP.DataLayoutKind.Block
                    blockParameters = bp.block_data_layout_parameters;
                    if isempty(blockParameters.precedence)
                        blockParameters.precedence = bp.acquisition_precedence;
                    end
                    layoutParameters = blockParameters.toBytes();
                case ZBP.DataLayoutKind.VsxStack
                    stackParameters = bp.vsx_stack_data_layout_parameters;
                    if stackParameters.stack_size == 0
                        stackParameters.precedence = bp.acquisition_precedence([1, 3, 4]);
                        stackParameters.stack_size = uint32(double(bp.sample_count) ...
                            * double(bp.receive_event_count) ...
                            * ornot.dataKindByteCount(bp.raw_data_kind));
                        stackParameters.stack_channel_count = bp.channel_count;
                        stackParameters.units_per_stack = bp.receive_event_count;
                    end
                otherwise
                    error('ornot:BeamformParameters:UnsupportedDataLayout', ...
                        'Unsupported data layout kind: %d.', int32(bp.data_layout_kind));
            end

            if bp.data_layout_kind == ZBP.DataLayoutKind.VsxStack
                stackParameters.row_channel_mapping_offset = -1;
                stackParameters.column_channel_mapping_offset = -1;
                stackParameters.unit_indices_offset = -1;
                if ~isempty(rowMappingValues)
                    assert(numel(rowMappingValues) == stackParameters.stack_channel_count, ...
                        "Row channel mapping length must match the VSX stack channel count!");
                    stackParameters.row_channel_mapping_offset = int32(offset);
                    offset = increment_offset(offset, 2*numel(rowMappingValues), offset_alignment);
                    assert(all(rowMappingValues(:) > 0), ...
                        "Row channel mappings must use one-based Verasonics channel numbers!");
                    rowMappingBytes = rowMappingValues(:) - uint16(1);
                    bytes = set_bytes(bytes, typecast(rowMappingBytes, "uint8"), ...
                        uint64(stackParameters.row_channel_mapping_offset));
                end
                if ~isempty(columnMappingValues)
                    assert(numel(columnMappingValues) == stackParameters.stack_channel_count, ...
                        "Column channel mapping length must match the VSX stack channel count!");
                    stackParameters.column_channel_mapping_offset = int32(offset);
                    offset = increment_offset(offset, 2*numel(columnMappingValues), offset_alignment);
                    assert(all(columnMappingValues(:) > 0), ...
                        "Column channel mappings must use one-based Verasonics channel numbers!");
                    columnMappingBytes = columnMappingValues(:) - uint16(1);
                    bytes = set_bytes(bytes, typecast(columnMappingBytes, "uint8"), ...
                        uint64(stackParameters.column_channel_mapping_offset));
                end
                if ~isempty(bp.unit_indices)
                    expectedUnitIndexCount = double(bp.receive_event_count) ...
                        * double(bp.data_frame_count);
                    assert(numel(bp.unit_indices) == expectedUnitIndexCount, ...
                        "VSX stack unit indices must contain one entry per receive-event/data-frame pair!");
                    assert(isequal(sort(double(bp.unit_indices(:))), ...
                        (0:(expectedUnitIndexCount - 1)).'), ...
                        "VSX stack unit indices must be a zero-based permutation of all receive-event/data-frame units!");
                    stackParameters.unit_indices_offset = int32(offset);
                    offset = increment_offset(offset, 4*numel(bp.unit_indices), offset_alignment);
                    bytes = set_bytes(bytes, typecast(bp.unit_indices(:), "uint8"), ...
                        uint64(stackParameters.unit_indices_offset));
                end
                layoutParameters = stackParameters.toBytes();
            end
            header.data_layout_offset = offset;
            bytes = set_bytes(bytes, layoutParameters, header.data_layout_offset);
            offset = increment_offset(offset, numel(layoutParameters), offset_alignment);

            if ~isempty(bp.data)
                uncompressedData = ornot.DataToRaw(bp.data, ZBP.DataCompressionKind.None);
                dataSizeParameters = bp;
                dataSizeParameters.sample_count = sample_count;
                dataSizeParameters.data_frame_count = bp.data_frame_count;
                dataSizeParameters.ensemble_count = ensemble_count;
                expectedDataSize = ornot.rawDataByteCount(dataSizeParameters);
                assert(numel(uncompressedData) == expectedDataSize, ...
                    'ornot:BeamformParameters:InvalidDataSize', ...
                    'The data array size does not match the physical data-layout parameters.');
                d = ornot.DataToRaw(bp.data, bp.raw_data_compression_kind);
                header.raw_data_offset = offset;
                header.raw_data_size = numel(d);
                offset = increment_offset(offset, numel(d), offset_alignment);
                bytes = set_bytes(bytes, [], header.raw_data_offset);
                bytes = cat(2, bytes, d(:)');
            else
                header.raw_data_offset = -1;
            end

            header.string_count = size(bp.strings, 1);
            if header.string_count
                header.string_table_offset = offset;
                offset = increment_offset(offset, header.string_count * ZBP.StringTableEntry.byteSize, offset_alignment);
                for i = 1:size(bp.strings, 1)
                    entry = ZBP.StringTableEntry;
                    entry.string_tag_length = strlength(bp.strings(i, 1));
                    entry.string_length     = strlength(bp.strings(i, 2));
                    entry.string_tag_offset = offset;
                    offset = increment_offset(offset, entry.string_tag_length, 1);
                    entry.string_offset     = offset;
                    offset = increment_offset(offset, entry.string_length, 1);

                    bytes = set_bytes(bytes, entry.toBytes(), header.string_table_offset + int32((i - 1) * ZBP.StringTableEntry.byteSize));
                    bytes = set_bytes(bytes, uint8(char(bp.strings(i, 1))), entry.string_tag_offset, entry.string_tag_length);
                    bytes = set_bytes(bytes, uint8(char(bp.strings(i, 2))), entry.string_offset,     entry.string_length);
                end
            else
                header.string_table_offset = -1;
            end

            offset = increment_offset(offset, 0, offset_alignment);

            bytes = set_bytes(bytes, header.toBytes());

            file_size = bitand((numel(bytes) + uint64(offset_alignment) - 1), bitcmp(uint64(offset_alignment) - 1));;
            assert(file_size == offset);
        end
    end

    methods (Static)
        function bp = FromFile(filename)
            arguments (Input)
                filename(1,1) string
            end
            arguments (Output)
                bp(1,1) ornot.BeamformParameters
            end
            fileId = fopen(filename, 'r');
            bytes = fread(fileId, '*uint8');
            fclose(fileId);
            bp = ornot.BeamformParameters.FromBytes(bytes);
        end

        function bp = FromBytes(bytes)
            arguments (Input)
                bytes uint8
            end
            arguments (Output)
                bp(1,1) ornot.BeamformParameters
            end

            assert(numel(bytes) >= ZBP.BaseHeader.byteSize);
            baseHeader = ZBP.BaseHeader.fromBytes(bytes);
            assert(baseHeader.magic == ZBP.Constants.HeaderMagic);

            switch baseHeader.major
                case 1
                    bp = ornot.BeamformParameters.FromV1Bytes(bytes);
                case {2, 3, 4}
                    bp = ornot.BeamformParameters.FromV2V3Bytes(bytes, baseHeader.major);
            end

        end

        function bp = FromV1Bytes(bytes)
            arguments (Input)
                bytes uint8
            end
            arguments (Output)
                bp(1,1) ornot.BeamformParameters
            end

            bpV1 = ZBP.HeaderV1.fromBytes(bytes);

            bp = ornot.BeamformParameters;
            bp.raw_data_kind = ZBP.DataKind.Int16;
            bp.decode_mode = bpV1.decode_mode;
            bp.sampling_mode = ZBP.SamplingMode.Standard;
            bp.sampling_frequency = bpV1.sampling_frequency;
            bp.demodulation_frequencies = bpV1.demodulation_frequency;
            bp.speed_of_sound = bpV1.speed_of_sound;
            bp.sample_count = bpV1.sample_count;
            bp.receive_event_count = bpV1.receive_event_count;
            bp.channel_count = bpV1.raw_data_dimension(2);
            bp.data_frame_count = bpV1.raw_data_dimension(3);
            bp.ensemble_count = bpV1.raw_data_dimension(4);
            bp.data_layout_kind = ZBP.DataLayoutKind.VsxStack;
            bp.acquisition_precedence = uint32([ ...
                ZBP.LayoutPrecedence.Channel, ...
                ZBP.LayoutPrecedence.ReceiveEvent, ...
                ZBP.LayoutPrecedence.DataFrame, ...
                ZBP.LayoutPrecedence.Ensemble]);
            vsxStackParameters = ZBP.VsxStackDataLayoutParameters;
            vsxStackParameters.precedence = bp.acquisition_precedence([2, 3, 4]);
            vsxStackParameters.stack_size = raw_data_dimension(1) ...
                * ornot.dataKindByteCount(bp.raw_data_kind);
            vsxStackParameters.stack_channel_count = bpV1.raw_data_dimension(2);
            vsxStackParameters.units_per_stack = bpV1.receive_event_count;
            bp.vsx_stack_data_layout_parameters = vsxStackParameters;
            bp.transducer_transform_matrices = bpV1.transducer_transform_matrix;
            bp.transducer_element_pitch = bpV1.transducer_element_pitch;
            bp.time_delays = bpV1.time_offset;
            bp.acquisition_kind = bpV1.beamform_mode;
            bp.contrast_mode = ZBP.ContrastMode.None;
            emission_parameters = ZBP.EmissionSineParameters;
            emission_parameters.frequency = bp.demodulation_frequencies(1);
            emission_parameters.cycles = 1;
            bp.emission_descriptors = 1;
            bp.emission_parameters = {emission_parameters};
            bp.channel_mapping = bpV1.channel_mapping;

            switch bp.acquisition_kind
                case {ZBP.AcquisitionKind.FORCES}
                    acquisition_parameters = ZBP.FORCESParameters;
                    acquisition_parameters.transmit_focus.focal_depth = bpV1.focal_depths(1);
                    acquisition_parameters.transmit_focus.steering_angle = bpV1.steering_angles(1);
                    acquisition_parameters.transmit_focus.transmit_receive_orientation = bpV1.transmit_mode;
                    bp.acquisition_parameters = acquisition_parameters;
                case {ZBP.AcquisitionKind.UFORCES}
                    acquisition_parameters = ZBP.uFORCESParameters;
                    acquisition_parameters.transmit_focus.focal_depth = bpV1.focal_depths(1);
                    acquisition_parameters.transmit_focus.steering_angle = bpV1.steering_angles(1);
                    acquisition_parameters.transmit_receive_orientation = bpV1.transmit_mode;
                    bp.acquisition_parameters = acquisition_parameters;
                    bp.sparse_elements = bpV1.sparse_elements;
                case {ZBP.AcquisitionKind.HERCULES}
                    acquisition_parameters = ZBP.HERCULESParameters;
                    acquisition_parameters.transmit_focus.focal_depth = bpV1.focal_depths(1);
                    acquisition_parameters.transmit_focus.steering_angle = bpV1.steering_angles(1);
                    acquisition_parameters.transmit_receive_orientation = bpV1.transmit_mode;
                    bp.acquisition_parameters = acquisition_parameters;
                case {ZBP.AcquisitionKind.RCA_VLS, ZBP.AcquisitionKind.RCA_TPW}
                    receive_count = bpV1.receive_event_count;
                    bp.focal_depths = reshape(bpV1.focal_depths(1:receive_count), [], 1);
                    bp.origin_offsets = zeros(size(bp.focal_depths), 'single');
                    bp.tilting_angles = reshape(bpV1.steering_angles(1:receive_count), [], 1);
                    bp.transmit_receive_orientations = repmat(uint8(bpV1.transmit_mode), size(bp.focal_depths));
                case {ZBP.AcquisitionKind.UHERCULES}
                    acquisition_parameters = ZBP.uHERCULESParameters;
                    acquisition_parameters.transmit_focus.focal_depth = bpV1.focal_depths(1);
                    acquisition_parameters.transmit_focus.steering_angle = bpV1.steering_angles(1);
                    acquisition_parameters.transmit_receive_orientation = bpV1.transmit_mode;
                    bp.acquisition_parameters = acquisition_parameters;
                    bp.sparse_elements = bpV1.sparse_elements;
            end
        end

        function bp = FromV2V3Bytes(bytes, major)
            arguments (Input)
                bytes uint8
                major uint32
            end
            arguments (Output)
                bp(1,1) ornot.BeamformParameters
            end

            if major == 4
                header = ZBP.HeaderV4.fromBytes(bytes);
            elseif major == 3
                header = ZBP.HeaderV3.fromBytes(bytes);
            elseif major == 2
                header = ZBP.HeaderV2.fromBytes(bytes);
            end

            bp = ornot.BeamformParameters;
            bp.raw_data_kind = header.raw_data_kind;
            bp.raw_data_compression_kind = header.raw_data_compression_kind;
            bp.decode_mode = header.decode_mode;
            bp.sampling_mode = header.sampling_mode;
            bp.sampling_frequency = header.sampling_frequency;
            bp.speed_of_sound = header.speed_of_sound;
            bp.transducer_element_pitch = header.transducer_element_pitch;
            bp.group_acquisition_time = header.group_acquisition_time;
            bp.ensemble_repetition_interval = header.ensemble_repetition_interval;
            bp.acquisition_kind = header.acquisition_mode;
            bp.contrast_mode = header.contrast_mode;

            if major == 4
                bp.data_layout_kind = ZBP.DataLayoutKind(int32(header.data_layout_kind));
                bp.element_count = header.element_count;
                bp.acquisition_precedence = header.acquisition_precedence;
                bp.sample_count = header.sample_count;
                bp.receive_event_count = header.receive_event_count;
                bp.channel_count = header.channel_count;
                bp.data_frame_count = header.data_frame_count;
                bp.ensemble_count = header.ensemble_count;
                switch bp.data_layout_kind
                    case ZBP.DataLayoutKind.Block
                        parameterByteCount = 24;
                    case ZBP.DataLayoutKind.VsxStack
                        parameterByteCount = 36;
                    otherwise
                        error('ornot:BeamformParameters:UnsupportedDataLayout', ...
                            'Unsupported data layout kind: %d.', int32(header.data_layout_kind));
                end
                assert(header.data_layout_offset >= 0 ...
                    && double(header.data_layout_offset) + parameterByteCount <= numel(bytes), ...
                    'ornot:BeamformParameters:InvalidDataLayoutOffset', ...
                    'The Version 4 layout parameters are missing or out of bounds.');
                layoutBytes = bytes(double(header.data_layout_offset) + (1:parameterByteCount));
                switch bp.data_layout_kind
                    case ZBP.DataLayoutKind.Block
                        bp.block_data_layout_parameters = ...
                            ZBP.BlockDataLayoutParameters.fromBytes(layoutBytes);
                    case ZBP.DataLayoutKind.VsxStack
                        bp.vsx_stack_data_layout_parameters = ...
                            ZBP.VsxStackDataLayoutParameters.fromBytes(layoutBytes);
                end
                channel_mapping_offset = int32(-1);
            else
                bp.sample_count = header.sample_count;
                bp.receive_event_count = header.receive_event_count;
                bp.channel_count = header.channel_count;
                channel_mapping_offset = int32(-1);
                if major == 3
                    bp.data_frame_count = header.raw_data_dimension(3);
                    bp.ensemble_count = header.raw_data_dimension(4);
                    channel_mapping_offset = header.channel_mapping_offset;
                else
                    bp.data_frame_count = header.raw_data_dimension(3);
                    bp.ensemble_count = header.raw_data_dimension(4);
                    if major == 2
                        channel_mapping_offset = header.channel_mapping_offset;
                    end
                end
                bp.data_layout_kind = ZBP.DataLayoutKind.VsxStack;
                bp.acquisition_precedence = uint32([ ...
                    ZBP.LayoutPrecedence.ReceiveEvent, ...
                    ZBP.LayoutPrecedence.Channel, ...
                    ZBP.LayoutPrecedence.DataFrame, ...
                    ZBP.LayoutPrecedence.Ensemble]);

                if major == 3 && header.raw_data_layout_offset >= 0
                    layoutOffset = double(header.raw_data_layout_offset);
                    assert(layoutOffset + 120 <= numel(bytes), ...
                        'ornot:BeamformParameters:InvalidLegacyLayoutOffset', ...
                        'The Version 3 layout is missing or out of bounds.');
                    bp.raw_data_kind = ZBP.DataKind(typecast(bytes(layoutOffset + (1:4)), 'uint32'));
                    bp.sample_count = typecast(bytes(layoutOffset + (5:8)), 'uint32');
                    bp.receive_event_count = typecast(bytes(layoutOffset + (9:12)), 'uint32');
                    bp.channel_count = typecast(bytes(layoutOffset + (13:16)), 'uint32');
                    bp.data_frame_count = typecast(bytes(layoutOffset + (17:20)), 'uint32');
                    bp.ensemble_count = typecast(bytes(layoutOffset + (21:24)), 'uint32');
                    bp.data_layout_kind = ZBP.DataLayoutKind(int32(typecast( ...
                        bytes(layoutOffset + (29:32)), 'uint32')));
                    bp.acquisition_precedence = typecast(bytes(layoutOffset + (33:48)), 'uint32');
                    channel_mapping_offset = typecast(bytes(layoutOffset + (49:52)), 'int32');
                    layoutBytes = bytes(layoutOffset + (53:88));
                    switch bp.data_layout_kind
                        case ZBP.DataLayoutKind.Block
                            bp.block_data_layout_parameters = ...
                                ZBP.BlockDataLayoutParameters.fromBytes(layoutBytes(1:24));
                        case ZBP.DataLayoutKind.VsxStack
                            bp.vsx_stack_data_layout_parameters = ...
                                ZBP.VsxStackDataLayoutParameters.fromBytes(layoutBytes);
                    end
                else
                    vsxStackParameters = ZBP.VsxStackDataLayoutParameters;
                    vsxStackParameters.precedence = bp.acquisition_precedence([1, 3, 4]);
                    vsxStackParameters.stack_size = uint32(double(bp.sample_count) ...
                        * double(bp.receive_event_count) ...
                        * ornot.dataKindByteCount(ZBP.DataKind(header.raw_data_kind)));
                    vsxStackParameters.stack_channel_count = header.raw_data_dimension(2);
                    vsxStackParameters.units_per_stack = bp.receive_event_count;
                    bp.vsx_stack_data_layout_parameters = vsxStackParameters;
                end
            end

            data_frame_count = bp.data_frame_count;
            if major == 3 || major == 4
                bp.time_delays = typecast(bytes(uint32(header.time_delays_offset) + (1:(4*data_frame_count))), 'single');
                bp.demodulation_frequencies = typecast(bytes(uint32(header.demodulation_frequencies_offset) + (1:(4*data_frame_count))), 'single');
                bp.transducer_tile_count = header.transducer_tile_count;
                matrices = typecast(bytes(uint32(header.transducer_transforms_offset) + uint32(1:(4*16*prod(bp.transducer_tile_count)))), 'single');
                bp.transducer_transform_matrices = reshape(matrices, 4, 4, []);
                bp.contrast_data_flags = header.contrast_data_flags;

                if header.string_count > 0
                    bp.strings = strings(header.string_count, 2);
                    for i = 1:header.string_count
                        entry = ZBP.StringTableEntry.fromBytes(bytes(header.string_table_offset + int32(1:ZBP.StringTableEntry.byteSize)));
                        bp.strings(i,1) = string(char(bytes(entry.string_tag_offset + int32(1:entry.string_tag_length)))');
                        bp.strings(i,2) = string(char(bytes(entry.string_offset + int32(1:entry.string_length)))');
                    end
                end
            elseif major == 2
                bp.time_delays = ones(1, data_frame_count) * header.time_offset;
                bp.demodulation_frequencies = ones(1, data_frame_count) * header.demodulation_frequency;
                bp.transducer_tile_count = [1, 1];
                bp.transducer_transform_matrices = header.transducer_transform_matrix;
            end

            if header.emission_descriptors_offset >= 0
                emissionDescriptors = createArray([data_frame_count, 1], "ZBP.EmissionDescriptor");
                offset = uint32(header.emission_descriptors_offset);
                for i = 1:data_frame_count
                    emissionDescriptors(i) = ZBP.EmissionDescriptor.fromBytes(bytes(offset + (1:ZBP.EmissionDescriptor.byteSize)));
                    offset = offset + ZBP.EmissionDescriptor.byteSize;
                end
                [uniqueParameterOffsets, descriptorIndices, bp.emission_descriptors] = unique([emissionDescriptors.parameters_offset]);
                parameterKinds = [emissionDescriptors(descriptorIndices).emission_kind];
                bp.emission_parameters = cell(numel(uniqueParameterOffsets), 1);
                for i = 1:numel(uniqueParameterOffsets)
                    switch parameterKinds(i)
                        case ZBP.EmissionKind.Sine
                            bp.emission_parameters{i} = ZBP.EmissionSineParameters.fromBytes(...
                                bytes(uint32(uniqueParameterOffsets(i)) + (1:ZBP.EmissionSineParameters.byteSize)));
                        case ZBP.EmissionKind.Chirp
                            bp.emission_parameters{i} = ZBP.EmissionChirpParameters.fromBytes(...
                                bytes(uint32(uniqueParameterOffsets(i)) + (1:ZBP.EmissionChirpParameters.byteSize)));
                    end
                end
            end

            if header.contrast_parameters_offset >= 0
                assert(false, "Loading Contrast Parameters not currently supported")
            end

            if channel_mapping_offset >= 0
                channel_count = bp.channel_count;
                bp.channel_mapping = typecast(bytes(uint32(channel_mapping_offset) + (1:(2*channel_count))), 'uint16');
            end
            if bp.data_layout_kind == ZBP.DataLayoutKind.VsxStack
                stackParameters = bp.vsx_stack_data_layout_parameters;
                if stackParameters.row_channel_mapping_offset > 0
                    bp.row_channel_mapping = typecast(bytes( ...
                        double(stackParameters.row_channel_mapping_offset) ...
                        + (1:(2*stackParameters.stack_channel_count))), 'uint16');
                    bp.row_channel_mapping = bp.row_channel_mapping + uint16(1);
                end
                if stackParameters.column_channel_mapping_offset > 0
                    bp.column_channel_mapping = typecast(bytes( ...
                        double(stackParameters.column_channel_mapping_offset) ...
                        + (1:(2*stackParameters.stack_channel_count))), 'uint16');
                    bp.column_channel_mapping = bp.column_channel_mapping + uint16(1);
                end
                if stackParameters.unit_indices_offset > 0
                    unitIndexCount = double(bp.receive_event_count) ...
                        * double(bp.data_frame_count);
                    bp.unit_indices = typecast(bytes( ...
                        double(stackParameters.unit_indices_offset) + (1:(4*unitIndexCount))), 'uint32');
                end
            end

            data_frame_count = bp.data_frame_count;
            receive_count = bp.receive_event_count;
            sparse_element_count = bp.receive_event_count - 1;
            if header.acquisition_parameters_offset >= 0
                switch header.acquisition_mode
                    case ZBP.AcquisitionKind.FORCES
                        offset = uint32(header.acquisition_parameters_offset);
                        bp.acquisition_parameters = createArray([data_frame_count, 1], "ZBP.FORCESParameters");
                        for i = 1:data_frame_count
                            bp.acquisition_parameters(i) = ZBP.FORCESParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.FORCESParameters.byteSize)));
                            offset = offset + ZBP.FORCESParameters.byteSize;
                        end
                    case ZBP.AcquisitionKind.UFORCES
                        offset = uint32(header.acquisition_parameters_offset);
                        bp.acquisition_parameters = createArray([data_frame_count, 1], "ZBP.uFORCESParameters");
                        bp.sparse_elements = zeros(sparse_element_count, data_frame_count);
                        for i = 1:data_frame_count
                            bp.acquisition_parameters(i) = ZBP.uFORCESParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.uFORCESParameters.byteSize)));
                            offset = offset + ZBP.uFORCESParameters.byteSize;
                            sparse_elements_offset = bp.acquisition_parameters(i).sparse_elements_offset;
                            if sparse_elements_offset >= 0
                                bp.sparse_elements(:,i) = typecast(bytes(uint32(sparse_elements_offset) + (1:(2*sparse_element_count))), 'uint16');
                            else
                            end
                        end
                    case ZBP.AcquisitionKind.HERCULES
                        offset = uint32(header.acquisition_parameters_offset);
                        bp.acquisition_parameters = createArray([data_frame_count, 1], "ZBP.HERCULESParameters");
                        for i = 1:data_frame_count
                            bp.acquisition_parameters(i) = ZBP.HERCULESParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.FORCESParameters.byteSize)));
                            offset = offset + ZBP.HERCULESParameters.byteSize;
                        end
                    case ZBP.AcquisitionKind.EPIC_FORCES
                        offset = uint32(header.acquisition_parameters_offset);
                        bp.acquisition_parameters = createArray([data_frame_count, 1], "ZBP.EPIC_FORCESParameters");
                        for i = 1:data_frame_count
                            bp.acquisition_parameters(i) = ZBP.EPIC_FORCESParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.EPIC_FORCESParameters.byteSize)));
                            offset = offset + ZBP.EPIC_FORCESParameters.byteSize;
                        end
                        bp.transmit_foci = createArray([bp.receive_event_count, data_frame_count], "ZBP.RCATransmitFocus");
                        for i = 1:data_frame_count
                            transmitFociOffset = uint32(bp.acquisition_parameters(i).transmit_foci_offset);
                            for j = 1:bp.receive_event_count
                                bp.transmit_foci(j, i) = ZBP.RCATransmitFocus.fromBytes(bytes(uint32(transmitFociOffset) + (1:ZBP.RCATransmitFocus.byteSize)));
                                transmitFociOffset = transmitFociOffset + ZBP.RCATransmitFocus.byteSize;
                            end
                        end
                    case ZBP.AcquisitionKind.RCA_VLS
                        offset = uint32(header.acquisition_parameters_offset);
                        bp.acquisition_parameters = createArray([data_frame_count, 1], "ZBP.VLSParameters");
                        for i = 1:data_frame_count
                            bp.acquisition_parameters(i) = ZBP.VLSParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.VLSParameters.byteSize)));
                            offset = offset + ZBP.VLSParameters.byteSize;
                        end
                        bp.focal_depths = createArray([receive_count, data_frame_count], "single");
                        bp.origin_offsets = createArray([receive_count, data_frame_count], "single");
                        bp.transmit_receive_orientations = createArray([receive_count, data_frame_count], "uint8");
                        for i = 1:data_frame_count
                            focalDepthsOffset = uint32(bp.acquisition_parameters(i).focal_depths_offset);
                            originOffsetsOffset = uint32(bp.acquisition_parameters(i).origin_offsets_offset);
                            transmitReceiveOrientationsOffset = uint32(bp.acquisition_parameters(i).transmit_receive_orientations_offset);
                            bp.focal_depths(:, i) = typecast(bytes(uint32(focalDepthsOffset) + (1:(4*receive_count))), "single");
                            bp.origin_offsets(:, i) = typecast(bytes(uint32(originOffsetsOffset) + (1:(4*receive_count))), "single");
                            bp.transmit_receive_orientations(:, i) = typecast(bytes(uint32(transmitReceiveOrientationsOffset) + (1:receive_count)), "uint8");
                        end
                    case ZBP.AcquisitionKind.RCA_TPW
                        offset = uint32(header.acquisition_parameters_offset);
                        bp.acquisition_parameters = createArray([data_frame_count, 1], "ZBP.TPWParameters");
                        for i = 1:data_frame_count
                            bp.acquisition_parameters(i) = ZBP.TPWParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.TPWParameters.byteSize)));
                            offset = offset + ZBP.TPWParameters.byteSize;
                        end
                        bp.tilting_angles = createArray([receive_count, data_frame_count], "single");
                        bp.transmit_receive_orientations = createArray([receive_count, data_frame_count], "uint8");
                        for i = 1:data_frame_count
                            tiltingAnglesOffset = uint32(bp.acquisition_parameters(i).tilting_angles_offset);
                            transmitReceiveOrientationsOffset = uint32(bp.acquisition_parameters(i).transmit_receive_orientations_offset);
                            bp.tilting_angles(:, i) = typecast(bytes(uint32(tiltingAnglesOffset) + (1:(4*receive_count))), "single");
                            bp.transmit_receive_orientations(:, i) = typecast(bytes(uint32(transmitReceiveOrientationsOffset) + (1:receive_count)), "uint8");
                        end
                    case ZBP.AcquisitionKind.UHERCULES
                        offset = uint32(header.acquisition_parameters_offset);
                        bp.acquisition_parameters = createArray([data_frame_count, 1], "ZBP.uHERCULESParameters");
                        bp.sparse_elements = zeros(sparse_element_count, data_frame_count);
                        for i = 1:data_frame_count
                            bp.acquisition_parameters(i) = ZBP.uHERCULESParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.uHERCULESParameters.byteSize)));
                            offset = offset + ZBP.uHERCULESParameters.byteSize;
                            sparse_elements_offset = acquisition_parameters(i).sparse_elements_offset;
                            if sparse_elements_offset >= 0
                                bp.sparse_elements(:,i) = typecast(bytes(uint32(sparse_elements_offset) + (1:(2*sparse_element_count))), 'uint16');
                            else
                            end
                        end
                    case ZBP.AcquisitionKind.HERO_PA
                        offset = uint32(header.acquisition_parameters_offset);
                        bp.acquisition_parameters = createArray([data_frame_count, 1], "ZBP.HERO_PAParameters");
                        for i = 1:data_frame_count
                            bp.acquisition_parameters(i) = ZBP.HERO_PAParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.HERO_PAParameters.byteSize)));
                            offset = offset + ZBP.HERO_PAParameters.byteSize;
                        end
                    case ZBP.AcquisitionKind.HEXDoppler
                        bp.acquisition_parameters = ZBP.HEXDopplerParameters.fromBytes(bytes(uint32(header.acquisition_parameters_offset) + (1:ZBP.HEXDopplerParameters.byteSize)));
                    case ZBP.AcquisitionKind.XDoppler
                        bp.acquisition_parameters = ZBP.XDopplerParameters.fromBytes(bytes(uint32(header.acquisition_parameters_offset) + (1:ZBP.XDopplerParameters.byteSize)));
                        bp.tilting_angles = typecast(bytes(uint32(bp.acquisition_parameters.tilting_angles_offset) + (1:(4*receive_count))), "single");
                end
            end

            bp.acquisition_channel_order = ...
                ornot.BeamformParameters.normalizeVsxStackChannelOrder(bp);

            if header.raw_data_offset >= 0
                byteCount = 0;
                if major == 3 || major == 4
                    byteCount = header.raw_data_size;
                elseif major == 2
                    switch header.raw_data_compression_kind
                        case ZBP.DataCompressionKind.None
                            byteCount = ornot.dataKindByteCount(header.raw_data_kind)*prod(max(header.raw_data_dimension, 1));
                        case ZBP.DataCompressionKind.ZSTD
                            byteCount = numel(bytes) - header.raw_data_offset;
                    end
                end

                % NOTE(DD): These ranges have to be double not uint64, otherwise MATLAB
                % in its infinite wisdom will instantiate an array that is 8 times
                % larger than the data itself :)
                rawDataStart = double(header.raw_data_offset) + 1;
                rawDataEnd = double(rawDataStart + byteCount - 1);
                bp = ornot.DataFromRaw(bp, bytes(rawDataStart:rawDataEnd));
            end

            % NOTE(DD): V2.1 data files have a bug where the emission peak excitation time is not added to the time offset
            if header.major == 2 && header.minor == 1
                if ~isempty(bp.emission_descriptors) && ~isempty(bp.emission_parameters)
                    for i = 1:bp.data_frame_count
                        emissionDescriptor = bp.emission_descriptors(i);
                        emissionParameters = bp.emission_parameters{emissionDescriptor};
                        switch class(emissionParameters)
                            case 'ZBP.EmissionSineParameters'
                                bp.time_delays(i) = bp.time_delays(i) + emissionParameters.cycles / emissionParameters.frequency / 2;
                            case 'ZBP.EmissionChirpParameters'
                                bp.time_delays(i) = bp.time_delays(i) + emissionParameters.duration / 2;
                            otherwise
                                error('ornot:FromV2Bytes:InvalidParameter', 'Unsupported EmissionType!');
                        end
                    end
                end
            end
        end
    end

    methods (Static, Access=private)
        function channelOrder = normalizeVsxStackChannelOrder(bp)
            arguments (Input)
                bp(1,1) ornot.BeamformParameters
            end
            arguments (Output)
                channelOrder uint16
            end

            channelOrder = uint16.empty(0, 0, 0);
            if bp.data_layout_kind ~= ZBP.DataLayoutKind.VsxStack
                return
            end
            channelCount = double(bp.channel_count);
            receiveCount = double(bp.receive_event_count);
            dataFrameCount = double(bp.data_frame_count);
            if ~isempty(bp.channel_mapping)
                assert(numel(bp.channel_mapping) == channelCount ...
                    && numel(unique(bp.channel_mapping)) == channelCount, ...
                    'ornot:BeamformParameters:InvalidChannelMapping', ...
                    'The legacy channel mapping must contain one unique entry per data channel.');
                [~, sourceChannelOrder] = sort(bp.channel_mapping(:), 'ascend');
                channelOrder = repmat(uint16(sourceChannelOrder - 1), ...
                    1, receiveCount, dataFrameCount);
                return
            end
            if isempty(bp.row_channel_mapping) && isempty(bp.column_channel_mapping)
                return
            end
            if ~isempty(bp.row_channel_mapping) && ~isempty(bp.column_channel_mapping) ...
                    && isequal(bp.row_channel_mapping, bp.column_channel_mapping)
                mapping = bp.row_channel_mapping(:);
                assert(numel(mapping) == channelCount ...
                    && numel(unique(mapping)) == channelCount, ...
                    'ornot:BeamformParameters:InvalidChannelMapping', ...
                    'VSX channel mappings must contain one unique entry per data channel.');
                [~, sourceChannelOrder] = sort(mapping, 'ascend');
                channelOrder = repmat(uint16(sourceChannelOrder - 1), ...
                    1, receiveCount, dataFrameCount);
                return
            end
            if ~isempty(bp.transmit_receive_orientations)
                rawReceiveOrientations = bp.transmit_receive_orientations;
            elseif ~isempty(bp.transmit_foci)
                rawReceiveOrientations = reshape( ...
                    [bp.transmit_foci.transmit_receive_orientation], receiveCount, dataFrameCount);
            elseif ~isempty(bp.acquisition_parameters) ...
                    && isprop(bp.acquisition_parameters(1), 'transmit_receive_orientation')
                rawReceiveOrientations = repmat( ...
                    bp.acquisition_parameters(1).transmit_receive_orientation, ...
                    receiveCount, dataFrameCount);
            else
                assert(~isempty(bp.acquisition_parameters) ...
                    && isprop(bp.acquisition_parameters(1), 'transmit_focus'), ...
                    'ornot:BeamformParameters:MissingReceiveOrientations', ...
                    'VSX row/column channel maps require receive orientations to normalize channel order.');
                rawReceiveOrientations = zeros(receiveCount, dataFrameCount, 'uint32');
                for dataFrameIndex = 1:dataFrameCount
                    focus = bp.acquisition_parameters(dataFrameIndex).transmit_focus;
                    rawReceiveOrientations(:, dataFrameIndex) = ...
                        focus.transmit_receive_orientation;
                end
            end
            assert(isequal(size(rawReceiveOrientations), [receiveCount, dataFrameCount]), ...
                'ornot:BeamformParameters:InvalidReceiveOrientations', ...
                'Receive orientations must contain one value per receive-event/data-frame pair.');

            receiveOrientations = ZBP.RCAOrientation(bitand(uint32(rawReceiveOrientations), uint32(15)));
            channelOrder = repmat(uint16((0:(channelCount - 1)).'), 1, receiveCount, dataFrameCount);
            for dataFrameIndex = 1:dataFrameCount
                for receiveIndex = 1:receiveCount
                    switch receiveOrientations(receiveIndex, dataFrameIndex)
                        case ZBP.RCAOrientation.Rows
                            mapping = bp.row_channel_mapping;
                        case ZBP.RCAOrientation.Columns
                            mapping = bp.column_channel_mapping;
                        otherwise
                            continue
                    end
                    if isempty(mapping)
                        continue
                    end
                    assert(numel(mapping) == channelCount, ...
                        'ornot:BeamformParameters:InvalidChannelMapping', ...
                        'VSX channel mappings must contain one entry per data channel.');
                    assert(numel(unique(mapping)) == numel(mapping), ...
                        'ornot:BeamformParameters:InvalidChannelMapping', ...
                        'VSX channel mappings must contain unique channel numbers.');
                    [~, sourceChannelOrder] = sort(mapping(:), 'ascend');
                    channelOrder(:, receiveIndex, dataFrameIndex) = uint16(sourceChannelOrder - 1);
                end
            end
        end

        function bytes = set_bytes(bytes, value, offset, size)
            arguments (Input)
                bytes (1, :) uint8
                value (1, :) uint8
                offset uint64 = 0;
                size uint64 = numel(value);
            end
            arguments (Output)
                bytes uint8
            end
            bytes = [bytes, zeros(1, max(offset + size - numel(bytes), 0))];
            bytes(offset + (1:size)) = value(1:size);
        end

        function offset = increment_offset(offset, increase, alignment)
            arguments (Input)
                offset(1,1) uint64
                increase(1,1) uint64 = 0;
                alignment(1,1) uint64 = 1;
            end
            arguments (Output)
                offset(1,1) double
            end
            assert(increase >= 0);
            assert(mod(log2(double(alignment)), 1) == 0);

            offset = offset + increase;
            offset = bitand((offset + alignment - 1), bitcmp(alignment - 1));
        end

    end
end