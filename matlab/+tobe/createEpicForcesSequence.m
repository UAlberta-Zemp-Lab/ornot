function [biasPattern, transmitApodization, transmitDelays, receiveApodization, beamformParameters] = createEpicForcesSequence(array, transmitFoci, speedOfSound)
arguments (Input)
    array(1,1) tobe.RowColumnArray
    transmitFoci(:,:) ZBP.RCATransmitFocus % [num_data_frame, receive_event_count]
    speedOfSound(1,1) single
end
arguments (Output)
    biasPattern(:,:) single
    transmitApodization(:,:) single
    transmitDelays(:,:) single % [s]
    receiveApodization(:,:) single
    beamformParameters(1,1) ornot.BeamformParameters
end

% Calculate total transmit count
transmitCount = size(transmitFoci, 2);
totalTransmitCount = numel(transmitFoci);
receiveElementCount = size(transmitFoci, 2);
numDataFrame = size(transmitFoci, 1);

for i = 1:numDataFrame
    assert(all([transmitFoci(i, :).transmit_receive_orientation] ==transmitFoci(i, 1).transmit_receive_orientation), ...
        'tobe:createEpicForcesSequence:InvalidParameter', ...
        "All EPIC FORCES in a given data frame must share the same orientation!" ...
        );
end

% Allocate returns
elementCount = sum(array.ElementCount);
biasPattern = zeros(totalTransmitCount, elementCount, 'single');
transmitApodization = zeros(totalTransmitCount, elementCount, 'single');
transmitDelays = zeros(totalTransmitCount, elementCount, 'single');
receiveApodization = zeros(totalTransmitCount, elementCount, 'single');
focusTimes = zeros(totalTransmitCount, 1, 'single');
h = hadamard(receiveElementCount, 'single');

% Calculate results
elementPositions = array.GetLineElementPlanarPositions();
for n = 1:numel(transmitFoci)
    transmitEvents = n;
    [j, i] = ind2sub(fliplr(size(transmitFoci)), n);
    [transmitOrientation, receiveOrientation] = ornot.unpackTransmitReceiveOrientation(transmitFoci(i, j).transmit_receive_orientation);
    transmitElements = array.GetElements(transmitOrientation);
    receiveElements = array.GetElements(receiveOrientation);
    
    biasPattern(n, receiveElements) = h(mod(n-1, receiveElementCount) + 1, :);
    receiveApodization(n, receiveElements) = h(mod(n-1, receiveElementCount) + 1, :);
    if isinf(transmitFoci(i, j).focal_depth)
        [txDelays, focusTime] = tobe.computeLinearPlanarDelayProfile(...
            transmitFoci(i, j).steering_angle, speedOfSound, ...
            elementPositions(transmitElements), true);
    else
        [txDelays, focusTime] = tobe.computeLinearFocusedDelayProfile(...
            [transmitFoci(i, j).origin_offset, transmitFoci(i, j).focal_depth], ...
            speedOfSound, elementPositions(transmitElements), true);
    end

    transmitDelays(n, transmitElements) = txDelays;
    focusTimes(n) = focusTime;
    transmitApodization(n, transmitElements) = 1;
end

% Align delays so they all have the same focus time
% Since we want all delays to be non-negative,
% we will align the delays to the maximum focus time
maxFocusTime = max(focusTimes);
focusTimeDeltas = maxFocusTime - focusTimes;
transmitDelays = transmitDelays + focusTimeDeltas;
timeOffset = maxFocusTime;

arraySize = array.GetSize();

beamformParameters = ornot.BeamformParameters();
beamformParameters.decode_mode = ZBP.DecodeMode.Hadamard;
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
beamformParameters.acquisition_kind = ZBP.AcquisitionKind.EPIC_FORCES;
beamformParameters.acquisition_parameters = createArray([numDataFrame, 1], "ZBP.EPIC_FORCESParameters");
beamformParameters.transmit_foci = transmitFoci;
beamformParameters.time_offset = timeOffset;
end