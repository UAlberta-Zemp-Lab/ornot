function [biasPattern, receiveApodization, beamformParameters] = createHeroPhotoacousticSequence(array, heroPaParameters, speedOfSound)
arguments (Input)
    array(1,1) tobe.RowColumnArray
    heroPaParameters(:,1) ZBP.HERO_PAParameters
    speedOfSound(1,1) single
end
arguments (Output)
    biasPattern(:,:) single
    receiveApodization(:,:) single
    beamformParameters(1,1) ornot.BeamformParameters
end

% Calculate total transmit count
transmitCount = zeros(1, numel(heroPaParameters));
receiveElementCount = zeros(1, numel(heroPaParameters));
transmitReceiveOrientations = [heroPaParameters.transmit_receive_orientation];
[transmitOrientations, receiveOrientations] = ornot.unpackTransmitReceiveOrientation(transmitReceiveOrientations);
assert(all(transmitOrientations == ZBP.RCAOrientation.None), ...
    'tobe:createHeroPhotoacousticSequence:InvalidParameter', ...
    "All HERO-PA Sequences must have none as the transmit orientation!" ...
    );
biasOrientations = [ZBP.RCAOrientation.Columns, ZBP.RCAOrientation.Rows];
biasOrientations = biasOrientations(transmitReceiveOrientations);
for n = 1:numel(heroPaParameters)
    transmitCount(n) = array.ElementCount(int32(biasOrientations(n)));
    receiveElementCount(n) = array.ElementCount(int32(receiveOrientations(n)));
end

assert(all(transmitCount == transmitCount(1)), ...
    'tobe:createHeroPhotoacousticSequence:InvalidParameter', ...
    "All HERO-PA Sequences must have the same number of transmits!" ...
    );
totalTransmitCount = sum(transmitCount);
transmitCount = transmitCount(1);
assert(all(receiveElementCount== receiveElementCount(1)), ...
    'tobe:createHeroPhotoacousticSequence:InvalidParameter', ...
    "All HERO-PA Sequences must have the same number of receive elements!" ...
    );
receiveElementCount = receiveElementCount(1);

% Allocate returns
elementCount = sum(array.ElementCount);
biasPattern = zeros(totalTransmitCount, elementCount, 'single');
receiveApodization = zeros(totalTransmitCount, elementCount, 'single');

% Calculate results
for n = 1:numel(receiveOrientations)
    transmitEvents = (n-1)*transmitCount + (1:transmitCount);
    transmitElements = array.GetElements(biasOrientations(n));
    receiveElements = array.GetElements(receiveOrientations(n));
    h = hadamard(transmitCount, 'single');
    biasPattern(transmitEvents, transmitElements) = h;
    receiveApodization(transmitEvents, receiveElements) = 1;
end
arraySize = array.GetSize();

beamformParameters = ornot.BeamformParameters();
beamformParameters.decode_mode = ZBP.DecodeMode.Hadamard;
beamformParameters.speed_of_sound = speedOfSound;
beamformParameters.channel_count = transmitCount;
beamformParameters.receive_event_count = receiveElementCount;
beamformParameters.transducer_transform_matrix = reshape(single([
    1, 0, 0, arraySize(1)/2;
    0, 1, 0, arraySize(2)/2;
    0, 0, 1, 0;
    0, 0, 0, 1;
    ]), 1, []);
beamformParameters.transducer_element_pitch = array.Pitch;
beamformParameters.acquisition_kind = ZBP.AcquisitionKind.HERO_PA;
beamformParameters.acquisition_parameters = heroPaParameters;
end