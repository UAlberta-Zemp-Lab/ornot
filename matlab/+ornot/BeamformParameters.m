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
end