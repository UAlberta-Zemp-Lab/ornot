function [biasPattern, transmitApodization, receiveApodization, beamformParameters] = createHexDopplerSequence(array, binCount, speedOfSound)
arguments (Input)
    array(1,1) tobe.RowColumnArray
    binCount(1,2) uint16
    speedOfSound(1,1) single
end
arguments (Output)
    biasPattern(:,:) single
    transmitApodization(:,:) single
    receiveApodization(:,:) single
    beamformParameters(1,1) ornot.BeamformParameters
end

% Calculate total transmit count
transmitCount = sum(binCount);
binSize = array.ElementCount./binCount;

assert(all(binCount <= array.ElementCount), ...
    'tobe:createHexpdSequence:InvalidParameter', ...
    "Both Bin Counts must be less than or equal to the array ElementCount in each direction!" ...
    );
assert(all(binSize == floor(binSize)), ...
    'tobe:createHexpdSequence:InvalidParameter', ...
    "Both Bin Counts must be a factor of the array ElementCount in each direction!" ...
    );

% Allocate returns
elementCount = sum(array.ElementCount);
biasPattern = zeros(transmitCount, elementCount, 'single');
transmitApodization = zeros(transmitCount, elementCount, 'single');
receiveApodization = zeros(transmitCount, elementCount, 'single');

% Row Tx, Col Rx Events
rowElements = array.GetElements(ZBP.RCAOrientation.Rows);
columnElements = array.GetElements(ZBP.RCAOrientation.Columns);
hRows = hadamard(single(binCount(1)));
biasRows = repelem(hRows, 1, binSize(1));
patternIndices1 = 1:binCount(1);
biasPattern(patternIndices1 , rowElements) = biasRows;
transmitApodization(patternIndices1 , rowElements) = biasRows;
receiveApodization(patternIndices1 , columnElements) = 1;

% Row Rx, Col Tx Events
hColumns = hadamard(single(binCount(2)));
biasColumns = repelem(hColumns, 1, binSize(2));
patternIndices2 = binCount(1) + (1:binCount(2));
biasPattern(patternIndices2, columnElements) = biasColumns;
transmitApodization(patternIndices2, columnElements) = biasColumns;
receiveApodization(patternIndices2, rowElements) = 1;

arraySize = array.GetSize();
beamformParameters = ornot.BeamformParameters();
beamformParameters.decode_mode = ZBP.DecodeMode.Hadamard;
beamformParameters.speed_of_sound = speedOfSound;
beamformParameters.channel_count = elementCount;
beamformParameters.receive_event_count = transmitCount;
beamformParameters.transducer_transform_matrix = reshape(single([
    1, 0, 0, arraySize(2)/2; % Note (DD): Columns change in X
    0, 1, 0, arraySize(1)/2; % Note (DD): Rows change in Y
    0, 0, 1, 0;
    0, 0, 0, 1;
    ]), 1, []);
beamformParameters.transducer_element_pitch = array.Pitch;
beamformParameters.acquisition_kind = ZBP.AcquisitionKind.HEXDoppler;
hexDopplerParameters = ZBP.HEXDopplerParameters;
hexDopplerParameters.bin_count = binCount;
beamformParameters.acquisition_parameters = hexDopplerParameters;
beamformParameters.time_offset = 0;
end