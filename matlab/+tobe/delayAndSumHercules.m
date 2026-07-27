function image = delayAndSumHercules(bp, settings, data, dataFrame, regionIndex)
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

decodedReceiveElementCount = bp.receive_event_count;
receiveElementCount = bp.channel_count;

switch bp.acquisition_kind
    case ZBP.AcquisitionKind.HERCULES
        assert(...
            isa(bp.acquisition_parameters, 'ZBP.HERCULESParameters'), ...
            'tobe:delayAndSumHercules:InvalidArgument', ...
            "acquisition_parameters must be of type ZBP.HERCULESParameters for HERCULES acquisition kind"...
            );
        decodedReceiveIndices = 1:bp.receive_event_count;
        decodedReceiveElements = decodedReceiveIndices - 1;
        transmitFocus = bp.acquisition_parameters(dataFrame).transmit_focus;
    case ZBP.AcquisitionKind.UHERCULES
        assert(...
            isa(bp.acquisition_parameters, 'ZBP.uHERCULESParameters'), ...
            'tobe:delayAndSumHercules:InvalidArgument', ...
            "acquisition_parameters must be of type ZBP.uHERCULESParameters for uHERCULES acquisition kind"...
            );
        % This first transmit event is junk (the leftover elements) for uHERCULES
        decodedReceiveIndices = 2:bp.receive_event_count;
        decodedReceiveElements = [nan, bp.sparse_elements(:, dataFrame)'];
        transmitFocus = bp.acquisition_parameters(dataFrame).transmit_focus;
    case ZBP.AcquisitionKind.HERO_PA
        assert(...
            isa(bp.acquisition_parameters, 'ZBP.HERO_PAParameters'), ...
            'tobe:delayAndSumHercules:InvalidArgument', ...
            "acquisition_parameters must be of type ZBP.HERO_PAParameters for HERO_PA acquisition kind"...
            );
        decodedReceiveIndices = 1:bp.receive_event_count;
        decodedReceiveElements = decodedReceiveIndices - 1;

        transmitFocus = ZBP.RCATransmitFocus();
        transmitFocus.transmit_receive_orientation = bp.acquisition_parameters(dataFrame).transmit_receive_orientation;
    otherwise
        error(...
            'tobe:delayAndSumHercules:InvalidArgument', ...
            'Acquisition kind %s is not supported', string(bp.acquisition_kind)...
            );
end
receiveElements = (1:bp.channel_count) - 1;

[transmitOrientation, receiveOrientation] = ornot.unpackTransmitReceiveOrientation(transmitFocus.transmit_receive_orientation);

decodedReceiveElementPositions = single(decodedReceiveElements) * bp.transducer_element_pitch(transmitOrientation);
receiveElementPositions = single(receiveElements) * bp.transducer_element_pitch(receiveOrientation);
receiveElementPositionsGrid = zeros(decodedReceiveElementCount, receiveElementCount, 3, 'single');
switch receiveOrientation
    case ZBP.RCAOrientation.Rows
        [receiveElementPositionsX, receiveElementPositionsY] = ndgrid(...
            decodedReceiveElementPositions, receiveElementPositions);
        receiveElementPositionsGrid(:,:,1) = reshape(receiveElementPositionsX, decodedReceiveElementCount, receiveElementCount);
        receiveElementPositionsGrid(:,:,2) = reshape(receiveElementPositionsY, decodedReceiveElementCount, receiveElementCount);
    case ZBP.RCAOrientation.Columns
        [receiveElementPositionsX, receiveElementPositionsY] = ndgrid(...
            receiveElementPositions, decodedReceiveElementPositions);
        receiveElementPositionsGrid(:,:,1) = reshape(receiveElementPositionsX', decodedReceiveElementCount, receiveElementCount);
        receiveElementPositionsGrid(:,:,2) = reshape(receiveElementPositionsY', decodedReceiveElementCount, receiveElementCount);
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

if isinf(transmitFocus.focal_depth)
    transmitDistance = tobe.computePlanarFocusedDistance(...
        imageGrid, transmitOrientation, transmitFocus.steering_angle, transmitFocus.origin_offset);
else
    focusPoint = [transmitFocus.origin_offset, transmitFocus.origin_offset, transmitFocus.focal_depth];
    transmitDistance = tobe.computeCylindricallyFocusedDistance(imageGrid, focusPoint, transmitOrientation);
end

image = zeros(settings.regions.output_points, 'single');

for decodedReceiveIndex = decodedReceiveIndices
    for receiveIndex = 1:receiveElementCount
        receiveDistance = tobe.computeSphericallyFocusedDistance(...
            imageGrid, squeeze(receiveElementPositionsGrid(decodedReceiveIndex, receiveIndex, :))');

        sampleTime = ((transmitDistance + receiveDistance) / bp.speed_of_sound) + bp.time_offset;
        receiveApodizationArg = sqrt((receiveDistance ./ imageGrid(:, 3)).^2 - 1);

        image(:) = image(:) ...
            + ornot.sampleData(bp, settings, ...
            data(:, decodedReceiveIndex, receiveIndex), ...
            sampleTime, receiveApodizationArg);
    end
end

end