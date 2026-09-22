function [biasPattern, transmitApodization, transmitDelays, receiveApodization, beamformParameters] = createUHerculesSequence(array, uHerculesParameters, sparseElements, speedOfSound)
arguments (Input)
    array(1,1) tobe.RowColumnArray
    uHerculesParameters(:,1) ZBP.HERCULESParameters
    sparseElements(:,:) uint16
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
receiveElementCount = zeros(1, numel(uHerculesParameters));
transmitFoci = [uHerculesParameters.transmit_focus];
[transmitOrientations, receiveOrientations] = ornot.unpackTransmitReceiveOrientation([transmitFoci.transmit_receive_orientation]);
for n = 1:numel(uHerculesParameters)
    receiveElementCount(n) = array.ElementCount(int32(receiveOrientations(n)));
end

transmitCount = (size(sparseElements, 2) + 1);
assert(size(sparseElements, 1) == numel(transmitFoci), ...
    'tobe:createUHerculesSequence:InvalidParameter', ...
    "Sparse Elements rows must match the number of uHERCULES Sequences!" ...
    );
totalTransmitCount = transmitCount * size(sparseElements, 1);
assert(all(receiveElementCount  == receiveElementCount(1)), ...
    'tobe:createUHerculesSequence:InvalidParameter', ...
    "All uHERCULES Sequences must have the same number of receive elements!" ...
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
    biasPattern(transmitEvents, transmitElements) = repmat(h(:, 1), [1, numel(transmitElements)]);
    biasPattern(transmitEvents, transmitElements(sparseElements)) = h(:, 2:end);
    transmitApodization(transmitEvents, transmitElements) = repmat(h(:, 1), [1, numel(transmitElements)]);
    transmitApodization(transmitEvents, transmitElements(sparseElements)) = h(:, 2:end);
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
beamformParameters.receive_event_count = size(sparseElements, 2) + 1;
beamformParameters.transducer_transform_matrix = reshape(single([
    1, 0, 0, arraySize(1)/2;
    0, 1, 0, arraySize(2)/2;
    0, 0, 1, 0;
    0, 0, 0, 1;
    ]), 1, []);
beamformParameters.transducer_element_pitch = array.Pitch;
beamformParameters.acquisition_kind = ZBP.AcquisitionKind.UHERCULES;
beamformParameters.acquisition_parameters = uHerculesParameters;
beamformParameters.time_offset = timeOffset;
beamformParameters.sparse_elements = sparseElements - 1;
end