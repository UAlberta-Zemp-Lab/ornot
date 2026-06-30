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
biasPattern = zeros(totalTransmitCount, elementCount, 'single');
transmitApodization = zeros(totalTransmitCount, elementCount, 'single');
receiveApodization = zeros(totalTransmitCount, elementCount, 'single');

% Row Tx, Col Rx Events
rowElements = array.GetElements(ZBP.RCAOrientation.Rows);
columnElements = array.GetElements(ZBP.RCAOrientation.Columns);
hRows = hadamard(binCount(1));
biasRows = repelem(hRows, 1, binSize(1));
biasPattern(rowElements, rowElements) = biasRows;
transmitApodization(rowElements, rowElements) = biasRows;
receiveApodization(rowElements, columnElements) = 1;

% Row Rx, Col Tx Events
hColumns = hadamard(binCount(2));
biasColumns = repelem(hColumns, 1, binSize(2));
biasPattern(columnElements, columnElements) = biasColumns;
transmitApodization(columnElements, columnElements) = biasColumns;
receiveApodization(columnElements, rowElements) = 1;

beamformParameters = ornot.BeamformParameters();
beamformParameters.decode_mode = ZBP.DecodeMode.Hadamard;
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
beamformParameters.acquisition_kind = ZBP.AcquisitionKind.HEXDoppler;
hexDopplerParameters = ZBP.HEXDopplerParameters;
hexDopplerParameters.bin_count = binCount;
beamformParameters.acquisition_parameters = hexDopplerParameters;
beamformParameters.time_offset = 0;
end