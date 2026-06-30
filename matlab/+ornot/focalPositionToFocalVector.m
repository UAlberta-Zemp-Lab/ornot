function focalVector = focalPositionToFocalVector(focalPosition)
arguments (Input)
    focalPosition(:,2) single % [x/y, z] m
end
arguments (Output)
    focalVector(:,2) single % [steering_angle, focal_depth] (°, m)
end
focalVector = [atan2d(focalPosition(:, 1), focalPosition(:, 2)), sqrt(sum(focalPosition.^2, 2))];
focalVector(:, 2) = sign(focalPosition(:, 2)) * focalVector(:, 2);
end