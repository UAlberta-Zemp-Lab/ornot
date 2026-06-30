function [transmitApodization, transmitDelays, receiveApodization, beamformParameters] = createTpwSequence(array, tiltingAngles, transmitOrientations, receiveOrientations, speedOfSound)
arguments (Input)
    array(1,1) tobe.RowColumnArray
    tiltingAngles(:,1) single
    transmitOrientations(:,1) ZBP.RCAOrientation
    receiveOrientations(:,1) ZBP.RCAOrientation
    speedOfSound(1,1) single
end
arguments (Output)
    transmitApodization(:,:) single
    transmitDelays(:,:) single % [s]
    receiveApodization(:,:) single
    beamformParameters(1,1) ornot.BeamformParameters
end

assert(all(size(tiltingAngles) == size(transmitOrientations)), ...
    'tobe:createTpwSequence:InvalidArgument', ...
    "Number of tilting angles must match number of transmit orientations");
assert(all(size(tiltingAngles) == size(receiveOrientations)), ...
    'tobe:createTpwSequence:InvalidArgument', ...
    "Number of tilting angles must match number of receive orientations");

% Calculate total transmit count
transmitCount = numel(tiltingAngles);
receiveElementCount = zeros(1, numel(tiltingAngles));
for n = 1:size(tiltingAngles, 1)
    receiveElementCount(n) = array.ElementCount(int32(receiveOrientations(n)));
end

assert(all(receiveElementCount == receiveElementCount(1)), ...
    'tobe:createTpwSequence:InvalidParameter', ...
    "All TPW Transmits must have the same number of receive elements!" ...
    );
receiveElementCount = receiveElementCount(1);

% Allocate returns
elementCount = sum(array.ElementCount);
transmitApodization = zeros(transmitCount, elementCount, 'single');
transmitDelays = zeros(transmitCount, elementCount, 'single');
receiveApodization = zeros(transmitCount, elementCount, 'single');
focusTimes = zeros(transmitCount, 1, 'single');

% Calculate results
elementPositions = array.GetLineElementPlanarPositions();
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
beamformParameters.channel_count = receiveElementCount;
beamformParameters.receive_event_count = transmitCount;
beamformParameters.transducer_transform_matrix = reshape(single([
    1, 0, 0, arraySize(1)/2;
    0, 1, 0, arraySize(2)/2;
    0, 0, 1, 0;
    0, 0, 0, 1;
    ]), 1, []);
beamformParameters.transducer_element_pitch = array.Pitch;
beamformParameters.acquisition_kind = ZBP.AcquisitionKind.RCA_TPW;
beamformParameters.time_offset = timeOffset;
beamformParameters.tilting_angles = tiltingAngles;
beamformParameters.transmit_receive_orientations = ornot.packTransmitReceiveOrientation(transmitOrientations, receiveOrientations);
end