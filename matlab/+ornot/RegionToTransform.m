function [output_points, output_min_coordinates, output_max_coordinates, beamform_planes, off_axis_positions] = RegionToTransform(regions)
arguments (Input)
    regions ornot.Region
end
arguments (Output)
    output_points(3,:) single
    output_min_coordinates(3,:) single
    output_max_coordinates(3,:) single
    beamform_planes(1,:) uint8
    off_axis_positions(1,:) single
end

output_points = zeros(3, numel(regions), "single");
output_min_coordinates = zeros(3, numel(regions), "single");
output_max_coordinates = zeros(3, numel(regions), "single");
beamform_planes = zeros(1, numel(regions), "uint8");
off_axis_positions = zeros(1, numel(regions), "single");

for i = 1:numel(regions)
    region = regions(i);
    switch class(region)
        case "ornot.XZPlaneRegion"
            output_points([1,3,2], i) = [region.resolution, 1];
            output_min_coordinates([1,3,2], i) = [region.start_corner, region.y_value];
            output_max_coordinates([1,3,2], i) = [region.end_corner, region.y_value];
            beamform_planes(i) = 0;
            off_axis_positions(i) = region.y_value;
        case "ornot.YZPlaneRegion"
            output_points([1,3,2], i) = [region.resolution, 1];
            output_min_coordinates([1,3,2], i) = [region.start_corner, region.x_value];
            output_max_coordinates([1,3,2], i) = [region.end_corner, region.x_value];
            beamform_planes(i) = 1;
            off_axis_positions(i) = region.x_value;
        case "ornot.AxisAlignedVolumeRegion"
            output_points(:, i) = region.resolution;
            output_min_coordinates(:, i) = region.start_corner;
            output_max_coordinates(:, i) = region.end_corner;
            beamform_planes(i) = 0;
        otherwise
            assert(false, "Region not supported!");
    end
end

end