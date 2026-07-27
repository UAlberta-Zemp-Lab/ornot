function distances = computeSphericallyFocusedDistance(imagePositions, elementPositions)
arguments (Input)
    imagePositions(:,3) single % [m] [x, y, z]
    elementPositions(:,3) single % [m] [x, y, z]
end
arguments (Output)
    distances(:,:) single % [m] [size(imagePositions,1), size(elementPositions,1)]
end

imagePositions = reshape(imagePositions, [], 1, 3);
elementPositions = reshape(elementPositions, 1, [], 3);
distances = sqrt(sum((imagePositions - elementPositions).^2, 3));

end