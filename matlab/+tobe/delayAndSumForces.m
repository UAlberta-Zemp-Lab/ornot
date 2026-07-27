function image = delayAndSumForces(bp, settings, data, dataFrame, regionIndex)
arguments (Input)
    bp(1,1) ornot.BeamformParameters
    settings(1,1) ornot.BeamformSettings
    data(:, :, :) {mustBeNumeric}
    dataFrame(1,1) {mustBeInteger, mustBePositive} = 1;
    regionIndex(1,1) {mustBeInteger, mustBePositive} = 1;
end
arguments (Output)
    image(:, :, :) {mustBeNumeric}
end

transmitElementCount = bp.receive_event_count;
receiveElementCount = bp.channel_count;

switch bp.acquisition_kind
    case ZBP.AcquisitionKind.FORCES
        assert(...
            isa(bp.acquisition_parameters(dataFrame), 'ZBP.FORCESParameters'), ...
            'tobe:delayAndSumForces:InvalidArgument', ...
            "acquisition_parameters must be of type ZBP.FORCESParameters for FORCES acquisition kind"...
            );
        transmitIndices = 1:bp.receive_event_count;
        transmitElements = transmitIndices - 1;
    case ZBP.AcquisitionKind.UFORCES
        assert(...
            isa(bp.acquisition_parameters(dataFrame), 'ZBP.uFORCESParameters'), ...
            'tobe:delayAndSumForces:InvalidArgument', ...
            "acquisition_parameters must be of type ZBP.uFORCESParameters for uFORCES acquisition kind"...
            );
        % This first transmit event is junk (the leftover elements) for uFORCES
        transmitIndices = 2:bp.receive_event_count;
        transmitElements = [nan, bp.sparse_elements(:, dataFrame)'];
    otherwise
        error(...
            'tobe:delayAndSumForces:InvalidArgument', ...
            'Acquisition kind %s is not supported', string(bp.acquisition_kind)...
            );
end
receiveElements = (1:bp.channel_count) - 1;

[transmitOrientation, receiveOrientation] = ornot.unpackTransmitReceiveOrientation(...
    bp.acquisition_parameters(dataFrame).transmit_focus.transmit_receive_orientation);

transmitElementPositions = zeros(transmitElementCount, 3, 'single');
switch transmitOrientation
    case ZBP.RCAOrientation.Rows
        originOffset = bp.acquisition_parameters(dataFrame).transmit_focus.origin_offset;
        transformedOriginOffset = (reshape(bp.transducer_transform_matrix, 4, 4) * [0; originOffset; 0; 1]);
        transmitElementPositions(:,2) = transformedOriginOffset(2);
        transmitElementPositions(:,1) = single(transmitElements) * bp.transducer_element_pitch(1);
    case ZBP.RCAOrientation.Columns
        originOffset = bp.acquisition_parameters(dataFrame).transmit_focus.origin_offset;
        transformedOriginOffset = (reshape(bp.transducer_transform_matrix, 4, 4) * [originOffset; 0; 0; 1]);
        transmitElementPositions(:,1) = transformedOriginOffset(1);
        transmitElementPositions(:,2) = single(transmitElements) * bp.transducer_element_pitch(2);
end

receiveElementPositions = zeros(receiveElementCount, 3, 'single');
switch receiveOrientation
    case ZBP.RCAOrientation.Rows
        receiveElementPositions(:,2) = single(receiveElements) * bp.transducer_element_pitch(1);
    case ZBP.RCAOrientation.Columns
        receiveElementPositions(:,1) = single(receiveElements) * bp.transducer_element_pitch(2);
end

region = settings.regions(regionIndex);

[imageGridX, imageGridY, imageGridZ] = ndgrid(...
    linspace(0, 1, region.output_points(1)), ...
    linspace(0, 1, region.output_points(2)), ...
    linspace(0, 1, region.output_points(3)) ...
    );
imageGrid = [imageGridX(:), imageGridY(:), imageGridZ(:), ones(numel(imageGridX), 1)];

imageGrid = (region.das_voxel_transform * imageGrid')';
imageGrid = (reshape(bp.transducer_transform_matrix, 4, 4) * imageGrid')';
imageGrid = imageGrid(:,1:3)./imageGrid(:,4);

transmitDistances = tobe.computeSphericallyFocusedDistance(imageGrid, transmitElementPositions);
receiveDistances = tobe.computeCylindricallyFocusedDistance(imageGrid, receiveElementPositions, receiveOrientation);

image = zeros(settings.regions.output_points, 'single');

for transmitIndex = transmitIndices
    transmitDistance = transmitDistances(:, transmitIndex);
    for receiveIndex = 1:receiveElementCount
        receiveDistance = receiveDistances(:, receiveIndex);

        sampleTime = ((transmitDistance + receiveDistance) / bp.speed_of_sound) + bp.time_offset;
        receiveApodizationArg = sqrt((receiveDistance ./ imageGrid(:, 3)).^2 - 1);

        image(:) = image(:) ...
            + ornot.sampleData(bp, settings, ...
            data(:, transmitIndex, receiveIndex), ...
            sampleTime, receiveApodizationArg);
    end
end

end