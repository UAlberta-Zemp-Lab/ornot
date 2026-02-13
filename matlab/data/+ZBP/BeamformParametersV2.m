classdef BeamformParametersV2
    properties
        header(1,1) ZBP.HeaderV2
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