function image = delayAndSumRca(bp, settings, data, dataFrame, regionIndex)
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

transmitReceiveOrientations = bp.transmit_receive_orientations(:, dataFrame);
[transmitOrientations, receiveOrientations] = ornot.unpackTransmitReceiveOrientation(transmitReceiveOrientations);
switch bp.acquisition_kind
    case ZBP.AcquisitionKind.RCA_VLS
        assert(...
            isa(bp.acquisition_parameters(dataFrame), 'ZBP.VLSParameters'), ...
            'tobe:delayAndSumRca:InvalidArgument', ...
            "acquisition_parameters must be of type ZBP.VLSParameters for RCA_VLS acquisition kind"...
            );
        originOffsets = bp.origin_offsets(:, dataFrame);
        focalDepths = bp.focal_depths(:, dataFrame);
        assert(numel(originOffsets) == bp.receive_event_count);
        assert(numel(focalDepths) == bp.receive_event_count);
        transmitElementPositions = zeros(transmitElementCount, 3, 'single');
        switch transmitOrientations
            case ZBP.RCAOrientation.Rows
                transmitElementPositions(:,2) = originOffsets;
                transmitElementPositions(:,3) = focalDepths;
            case ZBP.RCAOrientation.Columns
                transmitElementPositions(:,1) = originOffsets;
                transmitElementPositions(:,3) = focalDepths;
        end
    case ZBP.AcquisitionKind.RCA_TPW
        assert(...
            isa(bp.acquisition_parameters(dataFrame), 'ZBP.TPWParameters'), ...
            'tobe:delayAndSumRca:InvalidArgument', ...
            "acquisition_parameters must be of type ZBP.TPWParameters for RCA_TPW acquisition kind"...
            );
        tiltingAngles = bp.tilting_angles(:, dataFrame);
    otherwise
        error(...
            'tobe:delayAndSumRca:InvalidArgument', ...
            'Acquisition kind %s is not supported', string(bp.acquisition_kind)...
            );
end
receiveElements = (1:bp.channel_count) - 1;

rowReceiveElementPositions = zeros(receiveElementCount, 3, 'single');
columnReceiveElementPositions = zeros(receiveElementCount, 3, 'single');
rowReceiveElementPositions(:,2) = single(receiveElements) * bp.transducer_element_pitch(1);
columnReceiveElementPositions(:,1) = single(receiveElements) * bp.transducer_element_pitch(2);

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
switch bp.acquisition_kind
    case ZBP.AcquisitionKind.RCA_VLS
        transmitDistances = zeros(size(imageGrid,1), transmitElementCount, 'single');
        rowTransmits = transmitOrientations == ZBP.RCAOrientation.Rows;
        colTransmits = transmitOrientations == ZBP.RCAOrientation.Columns;
        transmitDistances(:, rowTransmits) = tobe.computeCylindricallyFocusedDistance(imageGrid, transmitElementPositions(rowTransmits, :), ZBP.RCAOrientation.Rows);
        transmitDistances(:, colTransmits) = tobe.computeCylindricallyFocusedDistance(imageGrid, transmitElementPositions(colTransmits, :), ZBP.RCAOrientation.Columns);
    case ZBP.AcquisitionKind.RCA_TPW
        transmitDistances = zeros(size(imageGrid,1), transmitElementCount, 'single');
        rowTransmits = transmitOrientations == ZBP.RCAOrientation.Rows;
        colTransmits = transmitOrientations == ZBP.RCAOrientation.Columns;
        transmitDistances(:, rowTransmits) = tobe.computePlanarFocusedDistance(imageGrid, ZBP.RCAOrientation.Rows, tiltingAngles(rowTransmits), originOffsets(rowTransmits));
        transmitDistances(:, colTransmits) = tobe.computePlanarFocusedDistance(imageGrid, ZBP.RCAOrientation.Columns, tiltingAngles(colTransmits), originOffsets(colTransmits));
end
rowReceiveDistances = tobe.computeCylindricallyFocusedDistance(imageGrid, rowReceiveElementPositions, ZBP.RCAOrientation.Rows);
columnReceiveDistances = tobe.computeCylindricallyFocusedDistance(imageGrid, columnReceiveElementPositions, ZBP.RCAOrientation.Columns);

image = zeros(settings.regions.output_points, 'single');

for transmitIndex = 1:transmitElementCount
    transmitDistance = transmitDistances(:, transmitIndex);
    receiveOrientation = receiveOrientations(transmitIndex);
    for receiveIndex = 1:receiveElementCount
        switch receiveOrientation
            case ZBP.RCAOrientation.Rows
                receiveDistance = rowReceiveDistances(:, receiveIndex);
            case ZBP.RCAOrientation.Columns
                receiveDistance = columnReceiveDistances(:, receiveIndex);
        end

        sampleTime = ((transmitDistance + receiveDistance) / bp.speed_of_sound) + bp.time_offset;
        receiveApodizationArg = sqrt((receiveDistance ./ imageGrid(:, 3)).^2 - 1);

        image(:) = image(:) ...
            + ornot.sampleData(bp, settings, ...
            data(:, transmitIndex, receiveIndex), ...
            sampleTime, receiveApodizationArg);
    end
end

end