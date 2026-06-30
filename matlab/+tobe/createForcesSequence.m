function [biasPattern, transmitApodization, transmitDelays, receiveApodization, beamformParameters] = createForcesSequence(array, forcesParameters, speedOfSound, transmitFNumber)
arguments (Input)
    array(1,1) tobe.RowColumnArray
    forcesParameters(:,1) ZBP.FORCESParameters
    speedOfSound(1,1) single
    transmitFNumber(:,1) single = 1;
end
arguments (Output)
    biasPattern(:,:) single
    transmitApodization(:,:) single
    transmitDelays(:,:) single % [s]
    receiveApodization(:,:) single
    beamformParameters(1,1) ornot.BeamformParameters
end

% Calculate total transmit count
transmitCount = zeros(1, numel(forcesParameters));
receiveElementCount = zeros(1, numel(forcesParameters));
transmitFoci = [forcesParameters.transmit_focus];
[transmitOrientations, receiveOrientations] = ornot.unpackTransmitReceiveOrientation([transmitFoci.transmit_receive_orientation]);
for n = 1:numel(forcesParameters)
    transmitCount(n) = array.ElementCount(int32(receiveOrientations(n)));
    receiveElementCount(n) = array.ElementCount(int32(receiveOrientations(n)));
end

assert(all(transmitCount == transmitCount(1)), ...
    'tobe:createForcesSequence:InvalidParameter', ...
    "All FORCES Sequences must have the same number of transmits!" ...
    );
totalTransmitCount = sum(transmitCount);
transmitCount = transmitCount(1);
assert(all(receiveElementCount == receiveElementCount(1)), ...
    'tobe:createForcesSequence:InvalidParameter', ...
    "All FORCES Sequences must have the same number of receive elements!" ...
    );
receiveElementCount = receiveElementCount(1);

% Allocate returns
elementCount = sum(array.ElementCount);
biasPattern = zeros(totalTransmitCount, elementCount, 'single');
transmitApodization = zeros(totalTransmitCount, elementCount, 'single');
transmitDelays = zeros(totalTransmitCount, elementCount, 'single');
receiveApodization = zeros(totalTransmitCount, elementCount, 'single');
focusTimes = zeros(numel(transmitFoci), 1, 'single');

% Calculate results
elementPositions = array.GetLineElementPlanarPositions();
for n = 1:numel(transmitFoci)
    transmitEvents = (n-1)*transmitCount + (1:transmitCount);
    transmitElements = array.GetElements(transmitOrientations(n));
    receiveElements = array.GetElements(receiveOrientations(n));
    h = hadamard(transmitCount, 'single');
    biasPattern(transmitEvents, receiveElements) = h;
    receiveApodization(transmitEvents, receiveElements) = h;
    [txDelays, focusTime] = tobe.computeLinearFocusedDelayProfile(...
        [transmitFoci(n).origin_offset, transmitFoci(n).focal_depth], ...
        speedOfSound, elementPositions(transmitElements), true);
    transmitDelays(transmitEvents, transmitElements) = repmat(txDelays, [transmitCount, 1]);
    focusTimes(n) = focusTime;
    transmitDiameter = abs(transmitFoci(n).focal_depth) / transmitFNumber(n);
    txApodization = ...
        abs(elementPositions(transmitElements) - transmitFoci(n).origin_offset) ...
        <= (transmitDiameter / 2);
    transmitApodization(transmitEvents, transmitElements) = ...
        repmat(txApodization, [transmitCount, 1]);
end

% Align delays so they all have the same focus time
% Since we want all delays to be non-negative,
% we will align the delays to the maximum focus time
[maxFocusTime, n] = max(focusTimes);
focusTimeDeltas = maxFocusTime - focusTimes;
transmitDelays = transmitDelays + repelem(focusTimeDeltas, transmitCount, 1);
timeOffset = maxFocusTime - (transmitFoci(n).focal_depth / speedOfSound);

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
beamformParameters.acquisition_kind = ZBP.AcquisitionKind.FORCES;
beamformParameters.acquisition_parameters = forcesParameters;
beamformParameters.time_offset = timeOffset;
end