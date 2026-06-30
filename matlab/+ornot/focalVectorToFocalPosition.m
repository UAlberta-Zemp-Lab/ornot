function focalPosition = focalVectorToFocalPosition(focalVector)
arguments (Input)
    focalVector(:,2) single % [steering_angle, focal_depth] (°, m)
end
arguments (Output)
    focalPosition(:,2) single % [x/y, z] m
end
focalPosition = focalVector(:, 2) .* [sind(focalVector(:, 1)), cosd(focalVector(:, 1))];
focalPosition(:, 2) = sign(focalVector(:, 2)) .* focalPosition(:, 2);
end