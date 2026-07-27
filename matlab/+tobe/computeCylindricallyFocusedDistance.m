function distances = computeCylindricallyFocusedDistance(imagePositions, elementPositions, orientation)
arguments (Input)
    imagePositions(:,3) single % [m] [x, y, z]
    elementPositions(:,3) single % [m] [x, y, z]
    orientation(1,1) ZBP.RCAOrientation
end
arguments (Output)
    distances(:,:) single % [m] [size(imagePositions,1), size(elementPositions,1)]
end


switch orientation
    case ZBP.RCAOrientation.None
        distances = zeros(size(imagePositions,1), size(elementPositions,1), 'single');
        return
    case ZBP.RCAOrientation.Rows
        imagePositions = reshape(imagePositions(:, [2,3]), [], 1, 2);
        elementPositions = reshape(elementPositions(:, [2,3]), 1, [], 2);
    case ZBP.RCAOrientation.Columns
        imagePositions = reshape(imagePositions(:, [1,3]), [], 1, 2);
        elementPositions = reshape(elementPositions(:, [1,3]), 1, [], 2);
end
distances = sqrt(sum((imagePositions - elementPositions).^2, 3));

end