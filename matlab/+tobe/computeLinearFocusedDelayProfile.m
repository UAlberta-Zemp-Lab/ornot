function [delays, focusTime] = computeLinearFocusedDelayProfile(focusPosition, speedOfSound, elementPositions, rectify)
arguments (Input)
    focusPosition(1,2) single % [m] [x/y, z]
    speedOfSound(1,1) single % [m/s]
    elementPositions(1,:) single % [m] [x/y]
    rectify(1,1) logical = false;
end
arguments (Output)
    delays(1,:) single % [s]
    focusTime(1,1) single % [s] Time at which the wave is at the focus
end
baseDelay = -sign(focusPosition(2))*sqrt(sum(focusPosition.^2));
delays = -sign(focusPosition(2))*sqrt((focusPosition(1) - elementPositions).^2 + focusPosition(2).^2) - baseDelay;
focusTime = -baseDelay/speedOfSound;
if rectify
    deltaDelay = min(delays);
    delays = delays - deltaDelay;
    focusTime = focusTime - deltaDelay/speedOfSound;
end
delays = delays / speedOfSound;
end