classdef XZPlaneRegion < ornot.Region
    properties
        resolution(1,2) single = [1024, 1024];
        start_corner(1,2) single
        end_corner(1,2) single
        y_value(1,1) single
    end
end