function [transmitApodization, transmitDelays, receiveApodization, beamformParameters] = createVlsSequence(array, focalDepths, originOffsets, transmitOrientations, receiveOrientations, speedOfSound)
arguments (Input)
    array(1,1) tobe.RowColumnArray
    focalDepths(:,1) single
    originOffsets(:,1) single
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

assert(all(size(focalDepths) == size(originOffsets)), ...
    'tobe:createVlsSequence:InvalidArgument', ...
    "Number of focal depths must match number of origin offsets");
assert(all(size(focalDepths) == size(transmitOrientations)), ...
    'tobe:createVlsSequence:InvalidArgument', ...
    "Number of focal depths must match number of transmit orientations");
assert(all(size(focalDepths) == size(receiveOrientations)), ...
    'tobe:createVlsSequence:InvalidArgument', ...
    "Number of focal depths must match number of receive orientations");

% Calculate total transmit count
transmitCount = numel(focalDepths);
receiveElementCount = zeros(1, numel(focalDepths));
for n = 1:size(focalDepths, 1)
    receiveElementCount(n) = array.ElementCount(int32(receiveOrientations(n)));
end

assert(all(receiveElementCount == receiveElementCount(1)), ...
    'tobe:createVlsSequence:InvalidParameter', ...
    "All VLS Transmits must have the same number of receive elements!" ...
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
for n = 1:numel(focalDepths)
    transmitElements = array.GetElements(transmitOrientations(n));
    receiveElements = array.GetElements(receiveOrientations(n));
    transmitApodization(n, transmitElements) = 1;
    [transmitDelays(n, transmitElements), focusTime] = tobe.computeLinearFocusedDelayProfile(...
        [originOffsets(n), focalDepths(n)], ...
        speedOfSound, elementPositions(transmitElements), true);
    focusTimes(n) = focusTime;
    receiveApodization(n, receiveElements) = 1;
end

% Align delays so they all have the same focus time
[maxFocusTime, n] = max(focusTimes);
focusTimeDeltas = maxFocusTime - focusTimes;
transmitDelays = transmitDelays + focusTimeDeltas;
[timeOffset, focusTime] = tobe.computeLinearFocusedDelayProfile(...
    [originOffsets(n), focalDepths(n)], ...
    speedOfSound, 0, true);
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
beamformParameters.acquisition_kind = ZBP.AcquisitionKind.RCA_VLS;
beamformParameters.time_offset = timeOffset;
beamformParameters.focal_depths = focalDepths;
beamformParameters.acquisition_parameters = ZBP.VLSParameters();
beamformParameters.origin_offsets = originOffsets;
beamformParameters.transmit_receive_orientations = ornot.packTransmitReceiveOrientation(transmitOrientations, receiveOrientations);
end