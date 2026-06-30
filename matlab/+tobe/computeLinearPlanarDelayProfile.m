function [delays, focusTime] = computeLinearPlanarDelayProfile(steeringAngle, speedOfSound, elementPositions, rectify)
arguments (Input)
    steeringAngle(1,1) single % [°]
    speedOfSound(1,1) single % [m/s]
    elementPositions(1,:) single % [m] [x/y]
    rectify(1,1) logical = false;
end
arguments (Output)
    delays(1,:) single % [s]
    focusTime(1,1) single % [s] Time at which the wave is at the focus
end
delays = elementPositions*sind(steeringAngle);
focusTime = 0;
if rectify
    deltaDelay = min(delays, [], "all");
    delays = delays - deltaDelay;
    focusTime = focusTime - deltaDelay/speedOfSound;
end
delays = delays / speedOfSound;
end