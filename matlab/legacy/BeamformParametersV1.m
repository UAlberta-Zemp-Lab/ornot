classdef BeamformParametersV1

    % Get Definitions ffrom ORNOT
    properties (Constant)
        magic(1,1) uint64 = 0x5042504D455AFECA;
        version(1,1) uint32 = 1;
    end
    properties
        decode_mode(1,1) uint16
        beamform_mode(1,1) uint16
        raw_data_dimension (1, 4) uint32
        decoded_data_dimension(1,4) uint32
        transducer_element_pitch(1,2) single
        transducer_transform_matrix(4,4) single
        channel_mapping(1,256) int16
        steering_angles(1,256) single
        focal_depths(1,256) single
        sparse_elements(1,256) int16
        hadamard_rows(1,256) int16
        speed_of_sound(1,1) single
        center_frequency(1,1) single
        sampling_frequency(1,1) single
        time_offset(1,1) single
        transmit_mode(1,1) uint32
    end

    methods
        function WriteToFile(obj, filename)
            arguments
                obj(1,1) BeamformParametersV1
                filename(1,1) string
            end
            if not(libisloaded('ornot'))
                try
                    loadlibrary('ornot');
                catch
                end
            end
            if libisloaded('ornot')
                bp.magic = obj.magic;
                bp.version = obj.version;
                bp.decode_mode = obj.decode_mode;
                bp.beamform_mode = obj.beamform_mode;
                bp.raw_data_dim = obj.raw_data_dimension;
                bp.decoded_data_dim = obj.decoded_data_dimension;
                bp.transducer_element_pitch = obj.transducer_element_pitch;
                bp.transducer_transform_matrix = obj.transducer_transform_matrix;
                bp.channel_mapping = obj.channel_mapping;
                bp.steering_angles = obj.steering_angles;
                bp.focal_depths = obj.focal_depths;
                bp.sparse_elements = obj.sparse_elements;
                bp.hadamard_rows = obj.hadamard_rows;
                bp.speed_of_sound = obj.speed_of_sound;
                bp.center_frequency = obj.center_frequency;
                bp.sampling_frequency = obj.sampling_frequency;
                bp.time_offset = obj.time_offset;
                bp.transmit_mode = obj.transmit_mode;
                calllib('ornot', 'write_zemp_bp_v1', char(filename), bp);
            else
                fileID = fopen(filename + 'r', 'w');
                if (fileID < 0)
                    throw(MException('BeamformParameters:IO', sprintf("Failed to create file! %s", filename)));
                end
                try
                    fwrite(fileID, obj.magic);
                    fwrite(fileID, obj.version);
                    fwrite(fileID, obj.decode_mode);
                    fwrite(fileID, obj.beamform_mode);
                    fwrite(fileID, obj.raw_data_dimension);
                    fwrite(fileID, obj.decoded_data_dimension);
                    fwrite(fileID, obj.transducer_element_pitch);
                    fwrite(fileID, obj.transducer_transform_matrix);
                    fwrite(fileID, obj.channel_mapping);
                    fwrite(fileID, obj.steering_angles);
                    fwrite(fileID, obj.focal_depths);
                    fwrite(fileID, obj.sparse_elements);
                    fwrite(fileID, obj.hadamard_rows);
                    fwrite(fileID, obj.speed_of_sound);
                    fwrite(fileID, obj.center_frequency);
                    fwrite(fileID, obj.sampling_frequency);
                    fwrite(fileID, obj.time_offset);
                    fwrite(fileID, obj.transmit_mode);
                    fclose(fileID);
                catch ME
                    if (fileID >=0)
                        fclose(fileID);
                    end
                    rethrow(ME);
                end
            end
        end
    end
    methods (Static)
        function bp = ReadFromFile(filename)
            arguments
                filename(1,1) string
            end
            if not(libisloaded('ornot'))
                try
                    loadlibrary('ornot');
                catch
                end
            end
            if libisloaded('ornot')
                bpStruct   = libstruct('zemp_bp_v1', struct());
                assert(calllib('ornot', 'unpack_zemp_bp_v1', char(filename), bpStruct));
                bpStruct = struct(bpStruct);
                bp = BeamformParametersV1();
                assert(double(bp.magic) == bpStruct.magic);
                assert(bp.version == bpStruct.version);
                bp.decode_mode = bpStruct.decode_mode;
                bp.beamform_mode = bpStruct.beamform_mode;
                bp.raw_data_dimension = bpStruct.raw_data_dim;
                bp.decoded_data_dimension = bpStruct.decoded_data_dim;
                bp.transducer_element_pitch = bpStruct.transducer_element_pitch;
                bp.transducer_transform_matrix = reshape(bpStruct.transducer_transform_matrix, [4, 4]);
                bp.channel_mapping = bpStruct.channel_mapping;
                bp.steering_angles = bpStruct.steering_angles;
                bp.focal_depths = bpStruct.focal_depths;
                bp.sparse_elements = bpStruct.sparse_elements;
                bp.hadamard_rows = bpStruct.hadamard_rows;
                bp.speed_of_sound = bpStruct.speed_of_sound;
                bp.center_frequency = bpStruct.center_frequency;
                bp.sampling_frequency = bpStruct.sampling_frequency;
                bp.time_offset = bpStruct.time_offset;
                bp.transmit_mode = bpStruct.transmit_mode;
            else
                fileID = fopen(filename, 'r');
                if (fileID < 0)
                    MException('BeamformParameters:IO', sprintf("Failed to open file! %s", filename));
                end
                try
                    bp = BeamformParametersV1();
                    frewind(fileID);
                    magic = fread(fileID, "uint64");
                    version = fread(fileID, "uint32");
                    assert(magic == BeamformParametersV1.magic, 'BeamformParameters:IO', "Magic number doesn't match!");
                    assert(version == BeamformParametersV1.version, 'BeamformParameters:IO', "Version number is not correct!");

                    bp.decode_mode = fread(fileID, 1, "uint16");
                    bp.beamform_mode = fread(fileID, 1, "uint16");
                    bp.raw_data_dimension = fread(fileID, 4, "uint32");
                    bp.decoded_data_dimension = fread(fileID, 4, "uint32");
                    bp.transducer_element_pitch = fread(fileID, 2, "single");
                    bp.transducer_transform_matrix = fread(fileID, 16, "single");
                    bp.channel_mapping = fread(fileID, 256, "int16");
                    bp.steering_angles = fread(fileID, 256, "int16");
                    bp.focal_depths = fread(fileID, 256, "single");
                    bp.sparse_elements = fread(fileID, 256, "single");
                    bp.hadamard_rows = fread(fileID, 256, "int16");
                    bp.speed_of_sound = fread(fileID, 1, "single");
                    bp.center_frequency = fread(fileID, 1, "single");
                    bp.sampling_frequency = fread(fileID, 1, "single");
                    bp.time_offset = fread(fileID, 1, "single");
                    bp.transmit_mode = fread(fileID, 1, "uint32");
                    fclose(fileID);
                catch ME
                    if (fileID >=0)
                        fclose(fileID);
                    end
                    rethrow(ME);
                end
            end
        end
    end
end