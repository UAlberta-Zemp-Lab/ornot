classdef BeamformParameters
    %% Depending on the source of this data, some properties may be empty
    properties
        header
        emission_descriptor ZBP.EmissionDescriptor
        emission_parameters
        contrast_parameters
        channel_mapping uint16
        acquisition_parameters
        transmit_receive_orientation uint8
        focal_depths single
        origin_offsets single
        tilting_angles single
        sparse_elements uint16
        data
    end
end