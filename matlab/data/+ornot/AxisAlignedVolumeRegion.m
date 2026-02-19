classdef AxisAlignedVolumeRegion < ornot.Region
    properties
        resolution(1,3) single = [256, 256, 256];
        start_corner(1,3) single
        end_corner(1,3) single
    end
end