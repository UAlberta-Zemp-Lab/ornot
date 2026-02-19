% By default beamforms the region (0, 0, 0) to (1, 1, 1)
% Then performs a translation, then rotation (with a quaternion), then a scaling
classdef TransformRegion < ornot.Region
    properties
        resolution(1,3) single = [1, 1, 1];
        translation(1,3) single
        rotation(1,4) single
        scale(1,3) single
    end
end