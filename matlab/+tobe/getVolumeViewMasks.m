function filter = getVolumeViewMasks(parameters, region, array, dataFrameIndex)
arguments
    parameters (1,1) ornot.BeamformParameters
    region (1,1) ornot.Region
    array (1,1) tobe.RowColumnArray
    dataFrameIndex (1,1) double {mustBeInteger, mustBePositive} = 1
end

arraySize = array.GetSize();
transform = region.das_voxel_transform;
resolution = double(region.output_points);
coordinates = cell(1, 3);
for dimension = 1:3
    if resolution(dimension) == 1
        coordinates{dimension} = 0;
    else
        coordinates{dimension} = linspace(0, 1, resolution(dimension));
    end
end
[u, v, w] = ndgrid(coordinates{:});
points = [u(:), v(:), w(:), ones(numel(u), 1)]';
transformedPoints = transform * points;
xGrid = reshape(transformedPoints(1, :), resolution);
yGrid = reshape(transformedPoints(2, :), resolution);
zGrid = reshape(transformedPoints(3, :), resolution);
grid = cat(4, xGrid, yGrid, zGrid);
[steeringAngles, orientations, apertureShadow] = getTransmitMetadata(parameters);
if ismember(parameters.acquisition_kind, ...
        [ZBP.AcquisitionKind.RCA_VLS, ZBP.AcquisitionKind.RCA_TPW])
    % Each reconstructed RCA frame already combines every transmit event.
    filter = false(resolution);
    for orientation = unique(orientations(:))'
        filter = filter | tobe.maskToArrayView( ...
            grid, arraySize, 0, orientation, apertureShadow);
    end
    return;
end

assert(dataFrameIndex <= numel(steeringAngles), ...
    "Acquisition index exceeds available transmit metadata.");

steeringAngle = steeringAngles(dataFrameIndex);
if steeringAngle == 0
    angles = 0;
else
    angles = [steeringAngle, steeringAngle];
end
filter = tobe.maskToArrayView(grid, arraySize, angles, orientations(dataFrameIndex), apertureShadow);
end

function [steeringAngles, orientations, apertureShadow] = getTransmitMetadata(parameters)
apertureShadow = false;
switch parameters.acquisition_kind
    case ZBP.AcquisitionKind.RCA_VLS
        steeringAngles = zeros(size(parameters.origin_offsets));
        [orientations, ~] = ornot.unpackTransmitReceiveOrientation(parameters.transmit_receive_orientations);
        apertureShadow = true;
    case ZBP.AcquisitionKind.RCA_TPW
        steeringAngles = zeros(size(parameters.tilting_angles));
        [orientations, ~] = ornot.unpackTransmitReceiveOrientation(parameters.transmit_receive_orientations);
        apertureShadow = true;
    otherwise
        foci = parameters.transmit_foci;
        if isempty(foci)
            foci = [parameters.acquisition_parameters.transmit_focus];
        end
        steeringAngles = [foci.steering_angle];
        [transmitOrientations, receiveOrientations] = ornot.unpackTransmitReceiveOrientation( ...
            uint8([foci.transmit_receive_orientation]));
        orientations = transmitOrientations;
        missingTransmitOrientation = orientations == ZBP.RCAOrientation.None;
        orientations(missingTransmitOrientation) = receiveOrientations(missingTransmitOrientation);
end
steeringAngles = steeringAngles(:);
orientations = orientations(:);
end
