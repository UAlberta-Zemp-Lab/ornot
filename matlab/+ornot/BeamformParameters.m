classdef BeamformParameters
    %% Depending on the source of this data, some properties may be empty
    properties
        raw_data_dimension(1,4)            uint32
        raw_data_kind(1,1)                 ZBP.DataKind
        raw_data_compression_kind(1,1)     ZBP.DataCompressionKind
        decode_mode(1,1)                   ZBP.DecodeMode
        sampling_mode(1,1)                 ZBP.SamplingMode
        sampling_frequency(1,1)            single
        demodulation_frequency(1,1)        single
        speed_of_sound(1,1)                single
        sample_count(1,1)                  uint32
        channel_count(1,1)                 uint32
        receive_event_count(1,1)           uint32
        transducer_transform_matrix(1,16)  single
        transducer_element_pitch(1,2)      single
        time_offset(1,1)                   single
        group_acquisition_time(1,1)        single
        ensemble_repitition_interval(1,1)  single
        acquisition_kind(1,1)              ZBP.AcquisitionKind
        contrast_mode(1,1)                 ZBP.ContrastMode
        emission_descriptor ZBP.EmissionDescriptor
        emission_parameters
        contrast_parameters
        channel_mapping uint16
        acquisition_parameters
        transmit_receive_orientations uint8
        focal_depths single
        origin_offsets single
        tilting_angles single
        sparse_elements uint16
        data
    end

    methods
        function bytes = ToBytes(bp)
            arguments (Input)
                bp(1,1) ornot.BeamformParameters
            end
            arguments (Output)
                bytes uint8
            end

            header = ZBP.HeaderV2;
            header.magic = ZBP.Constants.HeaderMagic;
            header.major = 2;
            header.minor = 0;
            header.raw_data_dimension = bp.raw_data_dimension;
            header.raw_data_kind = int32(bp.raw_data_kind);
            header.raw_data_compression_kind = int32(bp.raw_data_compression_kind);
            header.decode_mode = int32(bp.decode_mode);
            header.sampling_mode = int32(bp.sampling_mode);
            header.sampling_frequency = bp.sampling_frequency;
            header.demodulation_frequency = bp.demodulation_frequency;
            header.speed_of_sound = bp.speed_of_sound;
            header.sample_count = bp.sample_count;
            header.channel_count = bp.channel_count;
            header.receive_event_count = bp.receive_event_count;
            header.transducer_transform_matrix = bp.transducer_transform_matrix;
            header.transducer_element_pitch = bp.transducer_element_pitch;
            header.time_offset = bp.time_offset;
            header.group_acquisition_time = bp.group_acquisition_time;
            header.ensemble_repitition_interval = bp.ensemble_repitition_interval;
            header.acquisition_mode = int32(bp.acquisition_kind);
            header.contrast_mode = int32(bp.contrast_mode);

            bytes = [];

            offset_alignment = ZBP.Constants.OffsetAlignment;
            offset = increment_offset(0, header.byteSize, offset_alignment);

            if ~isempty(bp.emission_descriptor)
                assert(~isempty(bp.emission_parameters));
                header.emission_descriptors_offset = offset;
                offset = increment_offset(offset, bp.emission_descriptor.byteSize, offset_alignment);
                bp.emission_descriptor.parameters_offset = offset;
                offset = increment_offset(offset, bp.emission_parameters.byteSize, offset_alignment);
                switch bp.emission_descriptor.emission_kind
                    case ZBP.EmissionKind.Sine
                        assert(isa(bp.emission_parameters, "ZBP.EmissionSineParameters"));
                    case ZBP.EmissionKind.Chirp
                        assert(isa(bp.emission_parameters, "ZBP.EmissionChirpParameters"));
                    otherwise
                        assert(false, "Unsupported Emission Kind");
                end
                bytes = set_bytes(bytes, bp.emission_descriptor.toBytes(), header.emission_descriptors_offset);
                bytes = set_bytes(bytes, bp.emission_parameters.toBytes(), bp.emission_descriptor.parameters_offset);
            else
                header.emission_descriptors_offset = -1;
            end

            if ~isempty(bp.contrast_parameters)
                assert(false, "Saving Contrast Parameters not currently supported")
            else
                header.contrast_parameters_offset = -1;
            end

            if ~isempty(bp.channel_mapping)
                header.channel_mapping_offset = offset;
                assert(numel(bp.channel_mapping) == bp.channel_count);
                offset = increment_offset(offset, 2*bp.channel_count, offset_alignment);
                bytes = set_bytes(bytes, typecast(bp.channel_mapping, "uint8"), header.channel_mapping_offset);
            else
                header.channel_mapping_offset = -1;
            end

            if ~isempty(bp.acquisition_parameters)
                section_count = bp.raw_data_dimension(3);
                switch bp.acquisition_kind
                    case ZBP.AcquisitionKind.RCA_VLS
                        receive_count = bp.receive_event_count;
                        assert(isa(bp.acquisition_parameters, "ZBP.VLSParameters"));
                        assert(isscalar(bp.acquisition_parameters));

                        assert(~isempty(bp.focal_depths));
                        assert(numel(bp.focal_depths) == receive_count);
                        bp.acquisition_parameters.focal_depths_offset = offset;
                        offset = increment_offset(offset, 4*numel(bp.focal_depths), offset_alignment);
                        bytes = set_bytes(bytes, typecast(bp.focal_depths, "uint8"), bp.acquisition_parameters.focal_depths_offset);

                        assert(~isempty(bp.origin_offsets));
                        assert(numel(bp.origin_offsets) == receive_count);
                        bp.acquisition_parameters.origin_offsets_offset = offset;
                        offset = increment_offset(offset, 4*numel(bp.origin_offsets), offset_alignment);
                        bytes = set_bytes(bytes, typecast(bp.origin_offsets, "uint8"), bp.acquisition_parameters.origin_offsets_offset);

                        assert(~isempty(bp.transmit_receive_orientations));
                        assert(numel(bp.transmit_receive_orientations) == receive_count);
                        bp.acquisition_parameters.transmit_receive_orientations_offset = offset;
                        offset = increment_offset(offset, numel(bp.transmit_receive_orientations), offset_alignment);
                        bytes = set_bytes(bytes, typecast(bp.transmit_receive_orientations, "uint8"), bp.acquisition_parameters.transmit_receive_orientations_offset);
                    case ZBP.AcquisitionKind.RCA_TPW
                        receive_count = bp.receive_event_count;
                        assert(isa(bp.acquisition_parameters, "ZBP.TPWParameters"));
                        assert(isscalar(bp.acquisition_parameters));

                        assert(~isempty(bp.tilting_angles));
                        assert(numel(bp.tilting_angles) == receive_count);
                        bp.acquisition_parameters.tilting_angles_offset = offset;
                        offset = increment_offset(offset, 4*numel(bp.tilting_angles), offset_alignment);
                        bytes = set_bytes(bytes, typecast(bp.tilting_angles, "uint8"), bp.acquisition_parameters.tilting_angles_offset  );

                        assert(~isempty(bp.transmit_receive_orientations));
                        assert(numel(bp.transmit_receive_orientations) == receive_count);
                        bp.acquisition_parameters.transmit_receive_orientations_offset = offset;
                        offset = increment_offset(offset, numel(bp.transmit_receive_orientations), offset_alignment);
                        bytes = set_bytes(bytes, typecast(bp.transmit_receive_orientations, "uint8"), bp.acquisition_parameters.transmit_receive_orientations_offset);
                    case {ZBP.AcquisitionKind.UFORCES, ZBP.AcquisitionKind.UHERCULES}
                        assert(~isempty(bp.sparse_elements));
                        for i = 1:section_count
                            bp.acquisition_parameters(i).sparse_elements_offset = offset;
                            offset = increment_offset(offset, 2*numel(bp.sparse_elements(:,i)), offset_alignment);
                            bytes = set_bytes(bytes, typecast(bp.sparse_elements(:,i), "uint8"), bp.acquisition_parameters(i).sparse_elements_offset);
                        end
                end

                switch bp.acquisition_kind
                    case ZBP.AcquisitionKind.FORCES
                        assert(isa(bp.acquisition_parameters, "ZBP.FORCESParameters"));
                    case ZBP.AcquisitionKind.UFORCES
                        assert(isa(bp.acquisition_parameters, "ZBP.uFORCESParameters"));
                    case ZBP.AcquisitionKind.RCA_VLS
                        assert(isa(bp.acquisition_parameters, "ZBP.VLSParameters"));
                    case ZBP.AcquisitionKind.RCA_TPW
                        assert(isa(bp.acquisition_parameters, "ZBP.TPWParameters"));
                    case ZBP.AcquisitionKind.HERCULES
                        assert(isa(bp.acquisition_parameters, "ZBP.HERCULESParameters"));
                    case ZBP.AcquisitionKind.UHERCULES
                        assert(isa(bp.acquisition_parameters, "ZBP.uHERCULESParameters"));
                    otherwise
                        assert(false, "Unsupported Acquisition Kind")
                end

                header.acquisition_parameters_offset = offset;
                for i = 1:numel(bp.acquisition_parameters)
                    bytes = set_bytes(bytes, bp.acquisition_parameters(i).toBytes(), offset);
                    offset = increment_offset(offset, bp.acquisition_parameters(i).byteSize, 1);
                end

                offset = increment_offset(offset, 0, offset_alignment);
            else
                header.acquisition_parameters_offset = -1;
            end

            if ~isempty(bp.data)
                assert(numel(bp.data) == prod(bp.raw_data_dimension));
                header.raw_data_offset = offset;
                offset = increment_offset(offset, numel(typecast(bp.data(:), 'uint8')), offset_alignment);
                bytes = set_bytes(bytes, typecast(bp.data, 'uint8'), header.raw_data_offset);
            else
                header.raw_data_offset = -1;
            end

            bytes = set_bytes(bytes, header.toBytes());

            file_size = offset;
            assert(file_size == numel(bytes));
        end
    end

    methods (Static)
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
                case 2
                    bp = ornot.BeamformParameters.FromV2Bytes(bytes);
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

            bp.raw_data_dimension = bpV1.raw_data_dimension;
            bp.raw_data_kind = ZBP.DataKind.Int16;
            bp.decode_mode = bpV1.decode_mode;
            bp.sampling_mode = ZBP.SamplingMode.Standard;
            bp.sampling_frequency = bpV1.sampling_frequency;
            bp.demodulation_frequency = bpV1.demodulation_frequency;
            bp.speed_of_sound = bpV1.speed_of_sound;
            bp.sample_count = bpV1.sample_count;
            bp.channel_count = bpV1.channel_count;
            bp.receive_event_count = bpV1.receive_event_count;
            bp.transducer_transform_matrix = bpV1.transducer_transform_matrix;
            bp.transducer_element_pitch = bpV1.transducer_element_pitch;
            bp.time_offset = bpV1.time_offset;
            bp.acquisition_kind = bpV1.beamform_mode;
            bp.contrast_mode = ZBP.ContrastMode.None;
            emission_descriptor = ZBP.EmissionDescriptor;
            emission_descriptor.emission_kind = ZBP.EmissionKind.Sine;
            bp.emission_descriptor = emission_descriptor;
            emission_parameters = ZBP.EmissionSineParameters;
            emission_parameters.frequency = bp.demodulation_frequency;
            emission_parameters.cycles = 1;
            bp.emission_parameters = emission_parameters;
            bp.channel_mapping = bpV1.channel_mapping;

            switch bp.acquisition_kind
                case {ZBP.AcquisitionKind.FORCES}
                    acquisition_parameters = ZBP.FORCESParameters;
                    acquisition_parameters.transmit_focus.focal_depth = bpV1.focal_depths(1);
                    acquisition_parameters.transmit_focus.steering_angle = bpV1.steering_angles(1);
                    acquisition_parameters.transmit_receive_orientation = bpV1.transmit_mode;
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
                    bp.focal_depths = bpV1.focal_depths;
                    bp.origin_offsets = zeros(size(focal_depths));
                    bp.tilting_angles = bpV1.steering_angles;
                    bp.transmit_receive_orientations = repelem(bpV1.transmit_mode, size(focal_depths));
                case {ZBP.AcquisitionKind.UHERCULES}
                    acquisition_parameters = ZBP.uHERCULESParameters;
                    acquisition_parameters.transmit_focus.focal_depth = bpV1.focal_depths(1);
                    acquisition_parameters.transmit_focus.steering_angle = bpV1.steering_angles(1);
                    acquisition_parameters.transmit_receive_orientation = bpV1.transmit_mode;
                    bp.acquisition_parameters = acquisition_parameters;
                    bp.sparse_elements = bpV1.sparse_elements;
            end
        end

        function bp = FromV2Bytes(bytes)
            arguments (Input)
                bytes uint8
            end
            arguments (Output)
                bp(1,1) ornot.BeamformParameters
            end

            header = ZBP.HeaderV2.fromBytes(bytes);
            bp = ornot.BeamformParameters;
            bp.raw_data_dimension = header.raw_data_dimension;
            bp.raw_data_kind = header.raw_data_kind;
            bp.raw_data_compression_kind = header.raw_data_compression_kind;
            bp.decode_mode = header.decode_mode;
            bp.sampling_mode = header.sampling_mode;
            bp.sampling_frequency = header.sampling_frequency;
            bp.demodulation_frequency = header.demodulation_frequency;
            bp.speed_of_sound = header.speed_of_sound;
            bp.sample_count = header.sample_count;
            bp.channel_count = header.channel_count;
            bp.receive_event_count = header.receive_event_count;
            bp.transducer_transform_matrix = header.transducer_transform_matrix;
            bp.transducer_element_pitch = header.transducer_element_pitch;
            bp.time_offset = header.time_offset;
            bp.group_acquisition_time = header.group_acquisition_time;
            bp.ensemble_repitition_interval = header.ensemble_repitition_interval;
            bp.acquisition_kind = header.acquisition_mode;
            bp.contrast_mode = header.contrast_mode;

            if header.emission_descriptors_offset >= 0
                bp.emission_descriptor = ZBP.EmissionDescriptor.fromBytes(bytes(uint32(header.emission_descriptors_offset) + (1:ZBP.EmissionDescriptor.byteSize)));
                switch bp.emission_descriptor.emission_kind
                    case ZBP.EmissionKind.Sine
                        bp.emission_parameters = ZBP.EmissionSineParameters.fromBytes(bytes(uint32(bp.emission_descriptor.parameters_offset) + (1:ZBP.EmissionSineParameters.byteSize)));
                    case ZBP.EmissionKind.Chirp
                        bp.emission_parameters = ZBP.EmissionChirpParameters.fromBytes(bytes(uint32(bp.emission_descriptor.parameters_offset) + (1:ZBP.EmissionChirpParameters.byteSize)));
                end
            end

            if header.contrast_parameters_offset >= 0
                assert(false, "Loading Contrast Parameters not currently supported")
            end

            if header.channel_mapping_offset >= 0
                channel_count = header.raw_data_dimension(2);
                bp.channel_mapping = typecast(bytes(uint32(header.channel_mapping_offset) + (1:(2*channel_count))), 'uint16');
            end

            if header.acquisition_parameters_offset >= 0
                switch header.acquisition_mode
                    case ZBP.AcquisitionKind.FORCES
                        section_count = header.raw_data_dimension(3);
                        offset = uint32(header.acquisition_parameters_offset);
                        bp.acquisition_parameters = createArray([section_count, 1], "ZBP.FORCESParameters");
                        for i = 1:section_count
                            bp.acquisition_parameters(i) = ZBP.FORCESParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.FORCESParameters.byteSize)));
                            offset = offset + ZBP.FORCESParameters.byteSize;
                        end
                    case ZBP.AcquisitionKind.UFORCES
                        section_count = header.raw_data_dimension(3);
                        sparse_element_count = header.receive_event_count - 1;
                        offset = uint32(header.acquisition_parameters_offset);
                        bp.acquisition_parameters = createArray([section_count, 1], "ZBP.uFORCESParameters");
                        bp.sparse_elements = zeros(sparse_element_count, section_count);
                        for i = 1:section_count
                            bp.acquisition_parameters(i) = ZBP.uFORCESParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.uFORCESParameters.byteSize)));
                            offset = offset + ZBP.uFORCESParameters.byteSize;
                            sparse_elements_offset = bp.acquisition_parameters(i).sparse_elements_offset;
                            if sparse_elements_offset >= 0
                                bp.sparse_elements(:,i) = typecast(bytes(uint32(sparse_elements_offset) + (1:(2*sparse_element_count))), 'uint16');
                            else
                            end
                        end
                    case ZBP.AcquisitionKind.HERCULES
                        section_count = header.raw_data_dimension(3);
                        offset = uint32(header.acquisition_parameters_offset);
                        bp.acquisition_parameters = createArray([section_count, 1], "ZBP.HERCULESParameters");
                        for i = 1:section_count
                            bp.acquisition_parameters(i) = ZBP.HERCULESParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.FORCESParameters.byteSize)));
                            offset = offset + ZBP.HERCULESParameters.byteSize;
                        end
                    case ZBP.AcquisitionKind.RCA_VLS
                        receive_count = header.receive_event_count;
                        bp.acquisition_parameters = ZBP.VLSParameters.fromBytes(bytes(uint32(header.acquisition_parameters_offset) + (1:ZBP.VLSParameters.byteSize)));
                        bp.focal_depths = typecast(bytes(uint32(bp.acquisition_parameters.focal_depths_offset) + (1:(4*receive_count))), "single");
                        bp.origin_offsets = typecast(bytes(uint32(bp.acquisition_parameters.origin_offsets_offset) + (1:(4*receive_count))), "single");
                        bp.transmit_receive_orientations = typecast(bytes(uint32(bp.acquisition_parameters.transmit_receive_orientations_offset) + (1:receive_count)), "uint8");
                    case ZBP.AcquisitionKind.RCA_TPW
                        receive_count = header.receive_event_count;
                        bp.acquisition_parameters = ZBP.TPWParameters.fromBytes(bytes(uint32(header.acquisition_parameters_offset) + (1:ZBP.TPWParameters.byteSize)));
                        bp.tilting_angles = typecast(bytes(uint32(bp.acquisition_parameters.tilting_angles_offset) + (1:(4*receive_count))), "single");
                        bp.transmit_receive_orientations = typecast(bytes(uint32(bp.acquisition_parameters.transmit_receive_orientations_offset) + (1:receive_count)), "uint8");
                    case ZBP.AcquisitionKind.UHERCULES
                        section_count = header.raw_data_dimension(3);
                        sparse_element_count = header.receive_event_count - 1;
                        offset = uint32(header.acquisition_parameters_offset);
                        bp.acquisition_parameters = createArray([section_count, 1], "ZBP.uHERCULESParameters");
                        bp.sparse_elements = zeros(sparse_element_count, section_count);
                        for i = 1:section_count
                            bp.acquisition_parameters(i) = ZBP.uHERCULESParameters.fromBytes(bytes(uint32(offset) + (1:ZBP.uHERCULESParameters.byteSize)));
                            offset = offset + ZBP.uHERCULESParameters.byteSize;
                            sparse_elements_offset = acquisition_parameters(i).sparse_elements_offset;
                            if sparse_elements_offset >= 0
                                bp.sparse_elements(:,i) = typecast(bytes(uint32(sparse_elements_offset) + (1:(2*sparse_element_count))), 'uint16');
                            else
                            end
                        end
                end
            end

            if header.raw_data_offset >= 0
                bp.data = bytes(header.raw_data_offset + (1:prod(min(header.raw_data_dimension, 1))));
            end

        end
    end

    methods (Static, Access=private)
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