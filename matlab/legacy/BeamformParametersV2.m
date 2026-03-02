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