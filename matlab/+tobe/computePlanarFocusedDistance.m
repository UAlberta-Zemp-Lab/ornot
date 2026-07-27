function distances = computePlanarFocusedDistance(imagePositions, orientation, tiltingAngle, originOffset)
arguments (Input)
    imagePositions(:,3) single % [m] [x, y, z]
    orientation(1,1) ZBP.RCAOrientation
    tiltingAngle(:,1) single % [degrees]
    originOffset(:,1) single = 0; % [m]
end
arguments (Output)
    distances(:,:) single % [m] [size(imagePositions,1), size(tiltingAngle,1)]
end

switch orientation
    case ZBP.RCAOrientation.None
        distances = zeros(size(imagePositions,1), size(tiltingAngle,1), 'single');
        return
    case ZBP.RCAOrientation.Rows
        imagePositions = reshape(imagePositions(:, [2,3]), [], 1, 2);
    case ZBP.RCAOrientation.Columns
        imagePositions = reshape(imagePositions(:, [1,3]), [], 1, 2);
end
cosines = reshape([sind(tiltingAngle), cosd(tiltingAngle)], 1, [], 2);
imagePositions(:,1) = imagePositions(:,1) - originOffset;
distances = sum(imagePositions .* cosines, 3);
end