classdef BeamformParametersV2

    % Get Definitions from ORNOT
    properties (Constant)
        magic(1,1) uint64 = 0x5042504D455AFECA;
        version(1,1) uint32 = 2;
    end
    properties
        beamform_mode(1,1) uint16
        decode_mode(1,1) uint16
        construction_mode(1,1) uint16
        sampling_mode(1,1) uint16
        raw_data_dimension (1, 4) uint32
        decoded_data_dimension(1,4) uint32
        transducer_element_pitch(1,2) single
        transducer_bandwidth(1,2) single
        transducer_transform_matrix(4,4) single
        channel_mapping(1,256) uint16
        speed_of_sound(1,1) single
        sampling_frequency(1,1) single
        demodulation_frequency(1,1) single
        time_offset(1,1) single
        group_acquisition_time(1,1) single
        ensemble_repitition_interval(1,1) single
        data_type(1,1) uint16
        excitation(1,4) uint32
        mode_data struct
    end

    methods
        function WriteToFile(obj, filename, prerelease)
            arguments
                obj(1,1) BeamformParametersV2
                filename(1,1) string
                prerelease = 2;
            end
            if not(libisloaded('ornot'))
                try
                    loadlibrary('ornot');
                catch
                end
            end
            [filepath, name, ~] = fileparts(filename);
            switch (prerelease)
                case 0
                    throw(MException('BeamformParameters:IO', "V2 currently unsuppported!"));
                    filename = fullfile(filepath, strcat(name,".bp"));
                case 1
                    filename = fullfile(filepath, strcat(name,".bpr"));
                case 2
                    filename = fullfile(filepath, strcat(name,".bpr2"));
            end
            if prerelease == 0 && libisloaded('ornot')
                bp.magic = obj.magic;
                bp.version = obj.version;
                bp.beamform_mode = obj.beamform_mode;
                bp.decode_mode = obj.decode_mode;
                bp.construction_mode = obj.construction_mode;
                bp.sampling_mode = obj.sampling_mode;
                bp.raw_data_dimension = obj.raw_data_dimension;
                bp.decoded_data_dimension = obj.decoded_data_dimension;
                bp.transducer_element_pitch = obj.transducer_element_pitch;
                bp.transducer_bandwidth = obj.transducer_bandwidth;
                bp.transducer_transform_matrix = obj.transducer_transform_matrix;
                bp.channel_mapping = obj.channel_mapping;
                bp.speed_of_sound = obj.speed_of_sound;
                bp.sampling_frequency = obj.sampling_frequency;
                bp.demodulation_frequency = obj.demodulation_frequency;
                bp.time_offset = obj.time_offset;
                bp.group_acquisition_time = obj.group_acquisition_time;
                bp.ensemble_repitition_interval = obj.ensemble_repitition_interval;
                bp.data_type = obj.data_type;
                bp.excitation = obj.excitation;
                bp.mode_data = obj.mode_data;
                calllib('ornot', 'write_zemp_bp_v2', char(filename), bp);
            elseif (prerelease > 0)
                fileID = fopen(filename, 'w');
                if (fileID < 0)
                    throw(MException('BeamformParameters:IO', sprintf("Failed to create file! %s", filename)));
                end
                try
                    fwrite(fileID, obj.magic, "uint64");
                    fwrite(fileID, obj.version, "uint32");
                    fwrite(fileID, obj.beamform_mode, "uint16");
                    fwrite(fileID, obj.decode_mode, "uint16");
                    fwrite(fileID, obj.construction_mode, "uint16");
                    fwrite(fileID, obj.sampling_mode, "uint16");
                    fwrite(fileID, obj.raw_data_dimension, "uint32");
                    fwrite(fileID, obj.decoded_data_dimension, "uint32");
                    fwrite(fileID, obj.transducer_element_pitch, "single");
                    fwrite(fileID, obj.transducer_bandwidth, "single");
                    fwrite(fileID, obj.transducer_transform_matrix, "single");
                    fwrite(fileID, obj.channel_mapping, "uint16");
                    fwrite(fileID, obj.speed_of_sound, "single");
                    fwrite(fileID, obj.sampling_frequency, "single");
                    fwrite(fileID, obj.demodulation_frequency, "single");
                    fwrite(fileID, obj.time_offset, "single");
                    if (prerelease >= 2)
                        fwrite(fileID, obj.group_acquisition_time, "single");
                    end
                    fwrite(fileID, obj.ensemble_repitition_interval, "single");
                    fwrite(fileID, obj.data_type, "uint16");
                    if (prerelease >= 2)
                        fwrite(fileID, obj.excitation, "uint32");
                    end
                    switch(acquisition.BeamformModes(obj.beamform_mode))
                        case {acquisition.BeamformModes.FORCES, acquisition.BeamformModes.HERCULES, ...
                                acquisition.BeamformModes.UFORCES, acquisition.BeamformModes.UHERCULES, acquisition.BeamformModes.OPTIMUS, ...
                                acquisition.BeamformModes.RCA_VLS, acquisition.BeamformModes.RCA_TPW, ...
                                acquisition.BeamformModes.HEXPD, acquisition.BeamformModes.XDOPPLER}
                            for i = 1:numel(obj.mode_data)
                                fwrite(fileID, obj.mode_data(i).transmit_mode, "uint16");
                                fwrite(fileID, obj.mode_data(i).receive_mode, "uint16");
                                fwrite(fileID, obj.mode_data(i).focal_vector, "single");
                                if (acquisition.BeamformModes(obj.beamform_mode) == acquisition.BeamformModes.UFORCES ...
                                        || acquisition.BeamformModes(obj.beamform_mode) == acquisition.BeamformModes.UHERCULES)
                                    fwrite(fileID, obj.mode_data(i).sparse_elements, "uint16");
                                end
                            end
                        otherwise
                            throw(MException('BeamformParameters:NotImplemented', "Unsupported beamform mode!"));
                    end
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
        function bp = ReadFromFile(filename, prerelease)
            arguments
                filename(1,1) string
                prerelease = 2;
            end
            if not(libisloaded('ornot'))
                try
                    loadlibrary('ornot');
                catch
                end
            end
            [filepath, name, ~] = fileparts(filename);
            switch (prerelease)
                case 0
                    throw(MException('BeamformParameters:IO', "V2 currently unsuppported!"));
                    filename = fullfile(filepath, strcat(name,".bp"));
                case 1
                    filename = fullfile(filepath, strcat(name,".bpr"));
                case 2
                    filename = fullfile(filepath, strcat(name,".bpr2"));
            end
            if prerelease == 0 && libisloaded('ornot')
                bp   = libstruct('zemp_bp_v2');
                calllib('ornot', 'unpack_zemp_bp_v2', char(filename), bp);
                bp = bp.Value;
            else
                fileID = fopen(filename, 'r');
                if (fileID < 0)
                    throw(MException('BeamformParameters:IO', sprintf("Failed to open file! %s", filename)));
                end
                try
                    bp = BeamformParametersV2();
                    magic = fread(fileID, 1, "*uint64");
                    version = fread(fileID, 1, "*uint32");
                    assert(magic == BeamformParametersV2.magic, 'BeamformParameters:IO', "Magic number doesn't match!");
                    assert(version == BeamformParametersV2.version, 'BeamformParameters:IO', "Version number is not correct!");

                    bp.beamform_mode = fread(fileID, 1, "*uint16");
                    bp.decode_mode = fread(fileID, 1, "*uint16");
                    bp.construction_mode = fread(fileID, 1, "*uint16");
                    bp.sampling_mode = fread(fileID, 1, "*uint16");
                    bp.raw_data_dimension = fread(fileID, 4, "*uint32");
                    bp.decoded_data_dimension = fread(fileID, 4, "*uint32");
                    bp.transducer_element_pitch = fread(fileID, 2, "*single");
                    bp.transducer_bandwidth = fread(fileID, 2, "*single");
                    bp.transducer_transform_matrix = reshape(fread(fileID, 16, "*single"), 4, 4);
                    bp.channel_mapping = fread(fileID, 256, "*uint16");
                    bp.speed_of_sound = fread(fileID, 1, "*single");
                    bp.sampling_frequency = fread(fileID, 1, "*single");
                    bp.demodulation_frequency = fread(fileID, 1, "*single");
                    bp.time_offset = fread(fileID, 1, "*single");
                    if (prerelease >= 2)
                        bp.group_acquisition_time = fread(fileID, 1, "*single");
                    end
                    bp.ensemble_repitition_interval = fread(fileID, 1, "*single");
                    bp.data_type = fread(fileID, 1, "*uint16");
                    if (prerelease >= 2)
                        bp.excitation = fread(fileID, 4, "*uint32");
                    end
                    switch(acquisition.BeamformModes(bp.beamform_mode))
                        case {acquisition.BeamformModes.FORCES, acquisition.BeamformModes.HERCULES, ...
                                acquisition.BeamformModes.UFORCES, acquisition.BeamformModes.UHERCULES, acquisition.BeamformModes.OPTIMUS, ...
                                acquisition.BeamformModes.RCA_VLS, acquisition.BeamformModes.RCA_TPW, ...
                                acquisition.BeamformModes.HEXPD, acquisition.BeamformModes.XDOPPLER}
                            if (acquisition.BeamformModes(bp.beamform_mode) == acquisition.BeamformModes.RCA_VLS ...
                                    || acquisition.BeamformModes(bp.beamform_mode) == acquisition.BeamformModes.RCA_TPW)
                                dataCount = bp.decoded_data_dimension(3);
                            else
                                dataCount = bp.raw_data_dimension(3);
                            end
                            for i = 1:dataCount
                                mode_data(i).transmit_mode = fread(fileID, 1, "*uint16");
                                mode_data(i).receive_mode = fread(fileID, 1, "*uint16");
                                mode_data(i).focal_vector = fread(fileID, 2, "*single");
                                if (acquisition.BeamformModes(bp.beamform_mode) == acquisition.BeamformModes.UFORCES ...
                                        || acquisition.BeamformModes(bp.beamform_mode) == acquisition.BeamformModes.UHERCULES)
                                    mode_data(i).sparse_elements = fread(fileID, bp.decoded_data_dimension(3) - 1, "*uint16");
                                end
                            end
                            bp.mode_data = mode_data;
                        case {acquisition.BeamformModes.RCA_VLS, acquisition.BeamformModes.RCA_TPW}

                        otherwise
                            throw(MException('BeamformParameters:IO', "Unsupported beamform mode!"));
                    end
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