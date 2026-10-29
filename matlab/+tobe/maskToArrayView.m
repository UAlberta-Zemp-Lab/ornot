function filter = maskToArrayView(grid, arraySize, angle, txOrientation, apertureShadow)
arguments
    grid (:,:,:,3)
    arraySize (1,2)
    angle
    txOrientation ZBP.RCAOrientation
    apertureShadow (1,1) logical = false
end

switch txOrientation
    case ZBP.RCAOrientation.Rows
        lateralSize = arraySize(2);
        elevationalSize = arraySize(1);
        lateralPosition = grid(:,:,:,2);
        elevationalPosition = grid(:,:,:,1);
    case ZBP.RCAOrientation.Columns
        lateralSize = arraySize(1);
        elevationalSize = arraySize(2);
        lateralPosition = grid(:,:,:,1);
        elevationalPosition = grid(:,:,:,2);
    otherwise
        error("Unsupported RCA transmit orientation: %s", string(txOrientation));
end

if apertureShadow
    filter = abs(lateralPosition) <= lateralSize / 2 & ...
        abs(elevationalPosition) <= elevationalSize / 2;
    return;
end

axialPosition = grid(:,:,:,3);
if isscalar(angle)
    lateralPass = angleFilter(lateralPosition, axialPosition, angle, lateralSize, 0);
else
    lateralPass = angleFilter(lateralPosition, axialPosition, angle(1), lateralSize, -1) & ...
        angleFilter(lateralPosition, axialPosition, angle(2), lateralSize, 1);
end
elevationalPass = abs(elevationalPosition) <= elevationalSize / 2;
filter = lateralPass & elevationalPass;
end

function lateralPass = angleFilter(lateralPosition, axialPosition, angle, lateralSize, side)
if angle == 0
    if side == 0
        lateralPass = abs(lateralPosition) <= lateralSize / 2;
    elseif side < 0
        lateralPass = lateralPosition >= lateralSize / 2;
    else
        lateralPass = lateralPosition <= lateralSize / 2;
    end
elseif side == 0
    focusDepth = -lateralSize / 2 / tand(angle);
    axialPosition = axialPosition - focusDepth;
    registeredAngle = atand(lateralPosition ./ axialPosition);
    lateralPass = abs(registeredAngle) <= angle;
elseif side < 0
    lateralPosition = lateralPosition + lateralSize / 2;
    registeredAngle = atand(lateralPosition ./ axialPosition);
    lateralPass = registeredAngle >= angle;
else
    lateralPosition = lateralPosition - lateralSize / 2;
    registeredAngle = atand(lateralPosition ./ axialPosition);
    lateralPass = registeredAngle <= angle;
end
end
