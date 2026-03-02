classdef Region
    properties
        output_points(1, 3) single = [1, 1, 1];
        das_voxel_transform(4,4) single = eye(4);
    end

    methods (Static)
        function region = CreateLine(resolution, start_point, end_point)
            arguments (Input)
                resolution(1,1) uint16
                start_point(1,3) single
                end_point(1,3) single
            end
            arguments (Output)
                region(1,1) ornot.Region
            end
            region = ornot.Region;
            region.output_points(1) = resolution;
            region.das_voxel_transform(1:3,1) = end_point - start_point;
            region.das_voxel_transform(1:3,4) = start_point;
            region.das_voxel_transform(2,2) = 1;
            region.das_voxel_transform(3,3) = 1;
            region.das_voxel_transform(4,4) = 1;
        end

        function region = CreateXZPlane(resolution, x_range, z_range, y_position)
            arguments (Input)
                resolution(1,2) uint16
                x_range(1,2) single
                z_range(1,2) single
                y_position(1,1) single = 0
            end
            arguments (Output)
                region(1,1) ornot.Region
            end
            region = ornot.Region;
            region.output_points(1:2) = resolution;
            region.das_voxel_transform = zeros(4);
            region.das_voxel_transform(1,1) = diff(x_range);
            region.das_voxel_transform(3,2) = diff(z_range);
            region.das_voxel_transform(2,3) = 1;
            region.das_voxel_transform(:,4) = [x_range(1), y_position(1), z_range(1), 1];
        end

        function region = CreateYZPlane(resolution, y_range, z_range, x_position)
            arguments (Input)
                resolution(1,2) uint16
                y_range(1,2) single
                z_range(1,2) single
                x_position(1,1) single = 0
            end
            arguments (Output)
                region(1,1) ornot.Region
            end
            region = ornot.Region;
            region.output_points(1:2) = resolution;
            region.das_voxel_transform = zeros(4);
            region.das_voxel_transform(2,1) = diff(y_range);
            region.das_voxel_transform(3,2) = diff(z_range);
            region.das_voxel_transform(1,3) = 1;
            region.das_voxel_transform(:,4) = [x_position(1), y_range(1), z_range(1), 1];
        end

        function region = CreateXYPlane(resolution, x_range, y_range, z_position)
            arguments (Input)
                resolution(1,2) uint16
                x_range(1,2) single
                y_range(1,2) single
                z_position(1,1) single = 0
            end
            arguments (Output)
                region(1,1) ornot.Region
            end
            region = ornot.Region;
            region.output_points(1:2) = resolution;
            region.das_voxel_transform = zeros(4);
            region.das_voxel_transform(1,1) = diff(x_range);
            region.das_voxel_transform(2,2) = diff(y_range);
            region.das_voxel_transform(3,3) = 1;
            region.das_voxel_transform(:,4) = [x_range(1), y_range(1), z_position(1), 1];
        end

        function region = CreateAxisAlignedVolume(resolution, x_range, y_range, z_range)
            arguments (Input)
                resolution(1,3) uint16
                x_range(1,2) single
                y_range(1,2) single
                z_range(1,2) single
            end
            arguments (Output)
                region(1,1) ornot.Region
            end
            region = ornot.Region;
            region.output_points = resolution;
            region.das_voxel_transform(1:3,1) = diff(x_range);
            region.das_voxel_transform(1:3,2) = diff(y_range);
            region.das_voxel_transform(1:3,3) = diff(z_range);
            region.das_voxel_transform(1:3,4) = [x_range(1), y_range(1), z_range(1)];
        end
    end
end