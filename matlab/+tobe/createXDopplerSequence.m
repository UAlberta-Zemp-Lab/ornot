function [transmitApodization, transmitDelays, receiveApodization, beamformParameters] = createXDopplerSequence(array, angleCount, tiltingAngles, speedOfSound)
arguments (Input)
    array(1,1) tobe.RowColumnArray
    angleCount(1,2) uint16
    tiltingAngles(:,1) single
    speedOfSound(1,1) single
end
arguments (Output)
    transmitApodization(:,:) single
    transmitDelays(:,:) single % [s]
    receiveApodization(:,:) single
    beamformParameters(1,1) ornot.BeamformParameters
end

% Calculate total transmit count
transmitCount = sum(angleCount);

% In this case we can assume the same tilting angles are to be used in both directions
if tiltingAngles == transmitCount/2 && angleCount(1) == angleCount(2)
    tiltingAngles = repmat(tiltingAngles, [2, 1]);
end

assert(all(transmitCount == numel(tiltingAngles)), ...
    'tobe:createHexpdSequence:InvalidParameter', ...
    "Total transmit count must equal the number of angles given!" ...
    );

% Allocate returns
elementCount = sum(array.ElementCount);
transmitApodization = zeros(transmitCount, elementCount, 'single');
transmitDelays = zeros(transmitCount, elementCount, 'single');
receiveApodization = zeros(transmitCount, elementCount, 'single');
focusTimes = zeros(transmitCount, 1, 'single');

% Calculate results
elementPositions = array.GetLineElementPlanarPositions();
transmitOrientations = repelem([ZBP.RCAOrientation.Rows; ZBP.RCAOrientation.Columns], array.ElementCount);
receiveOrientations = repelem([ZBP.RCAOrientation.Columns; ZBP.RCAOrientation.Rows], fliplr(array.ElementCount));
for n = 1:numel(tiltingAngles)
    transmitElements = array.GetElements(transmitOrientations(n));
    receiveElements = array.GetElements(receiveOrientations(n));
    transmitApodization(n, transmitElements) = 1;
    [transmitDelays(n, transmitElements), focusTime] = tobe.computeLinearPlanarDelayProfile(...
        tiltingAngles(n), speedOfSound, ...
        elementPositions(transmitElements), true);
    focusTimes(n) = focusTime;
    receiveApodization(n, receiveElements) = 1;
end

% Align delays so they all have the same focus time
[maxFocusTime, n] = max(focusTimes);
focusTimeDeltas = maxFocusTime - focusTimes;
transmitDelays = transmitDelays + focusTimeDeltas;
[timeOffset, focusTime] = tobe.computeLinearPlanarDelayProfile(...
    tiltingAngles(n), speedOfSound, ...
    0, true);
timeOffset = timeOffset + maxFocusTime - focusTime;
arraySize = array.GetSize();

beamformParameters = ornot.BeamformParameters();
beamformParameters.decode_mode = ZBP.DecodeMode.None;
beamformParameters.speed_of_sound = speedOfSound;
beamformParameters.channel_count = elementCount;
beamformParameters.receive_event_count = transmitCount;
beamformParameters.transducer_transform_matrix = reshape(single([
    1, 0, 0, arraySize(1)/2;
    0, 1, 0, arraySize(2)/2;
    0, 0, 1, 0;
    0, 0, 0, 1;
    ]), 1, []);
beamformParameters.transducer_element_pitch = array.Pitch;
beamformParameters.acquisition_kind = ZBP.AcquisitionKind.XDoppler;
xDopplerParameters = ZBP.XDopplerParameters;
xDopplerParameters.angle_count = angleCount;
beamformParameters.acquisition_parameters = xDopplerParameters;
beamformParameters.time_offset = timeOffset;
beamformParameters.tilting_angles = tiltingAngles;
end