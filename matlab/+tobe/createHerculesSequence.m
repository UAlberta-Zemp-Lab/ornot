function [biasPattern, transmitApodization, transmitDelays, receiveApodization, beamformParameters] = createHerculesSequence(array, herculesParameters, speedOfSound)
arguments (Input)
    array(1,1) tobe.RowColumnArray
    herculesParameters(:,1) ZBP.HERCULESParameters
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
transmitCount = zeros(1, numel(herculesParameters));
receiveElementCount = zeros(1, numel(herculesParameters));
transmitFoci = [herculesParameters.transmit_focus];
[transmitOrientations, receiveOrientations] = ornot.unpackTransmitReceiveOrientation([transmitFoci.transmit_receive_orientation]);
for n = 1:numel(herculesParameters)
    transmitCount(n) = array.ElementCount(int32(transmitOrientations(n)));
    receiveElementCount(n) = array.ElementCount(int32(receiveOrientations(n)));
end

assert(all(transmitCount == transmitCount(1)), ...
    'tobe:createHerculesSequence:InvalidParameter', ...
    "All HERCULES Sequences must have the same number of transmits!" ...
    );
totalTransmitCount = sum(transmitCount);
transmitCount = transmitCount(1);
assert(all(receiveElementCount== receiveElementCount(1)), ...
    'tobe:createHerculesSequence:InvalidParameter', ...
    "All HERCULES Sequences must have the same number of receive elements!" ...
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
    biasPattern(transmitEvents, transmitElements) = h;
    transmitApodization(transmitEvents, transmitElements) = h;
    if isinf(transmitFoci(n).focal_depth)
        [txDelays, focusTime] = tobe.computeLinearPlanarDelayProfile(...
            transmitFoci(n).steering_angle, speedOfSound, ...
            elementPositions(transmitElements), true);
    else
        [txDelays, focusTime] = tobe.computeLinearFocusedDelayProfile(...
            [transmitFoci(n).origin_offset, transmitFoci(n).focal_depth], ...
            speedOfSound, elementPositions(transmitElements), true);
    end
    transmitDelays(transmitEvents, transmitElements) = repmat(txDelays, [transmitCount, 1]);
    focusTimes(n) = focusTime;
    receiveApodization(transmitEvents, receiveElements) = 1;
end

% Align delays so they all have the same focus time
maxFocusTime = max(focusTimes);
focusTimeDeltas = maxFocusTime - focusTimes;
transmitDelays = transmitDelays + repelem(focusTimeDeltas, transmitCount, 1);
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
beamformParameters.acquisition_kind = ZBP.AcquisitionKind.HERCULES;
beamformParameters.acquisition_parameters = herculesParameters;
beamformParameters.time_offset = timeOffset;
end