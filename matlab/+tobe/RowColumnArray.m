classdef RowColumnArray
    % A Top-Orthogonal-Bottom-Electrode Bias-senstive Row-Column-Array
    % All property and methods assume Row-Column Order
    % (e.g. ElementCount = [RowCount, ColumnCount])
    % Elements are numbered from 1:sum(ElementCount) (Rows first)
    % Assuming the z axis is parallel the transducer face normal,
    % Rows numbers increase in the positive y (elevational) direction,
    % Column numbers increase in the positive x (lateral) direction
    % Geometry
    %           +y, Elevational, Column Orientation
    %            |  +x, Lateral, Row Orientatoin
    %            |/|/
    %            - |
    %           /|/| Scattering Medium
    % -z < - - / /-------------------- +z
    %          |/|/
    %          | -
    %         /|/|
    %       -x   |
    %            |
    %           -y

    %Informational Properties
    properties
        ID(1,1) string = "UNK0000";
        Name(1,1) string = "Unknown Array";
        Maker(1,1) string = "Unknown Maker";
        DateCreated(1,1) datetime = NaT;
    end

    % Physical Properties
    properties
        ElementCount(1,2) uint16 {mustBeNonnegative, mustBeInteger} = 0;
        Pitch(1,2) single {mustBeNonnegative} % [m]
        Kerf(1,2) single {mustBeNonnegative} % [m]
        CenterFrequency(1,1) single {mustBeNonnegative} % [Hz]
        Bandwidth(1,2) single {mustBeNonnegative} % [Hz]
    end

    % Electrical Properties
    properties
        VdcLimits(1,2) single = [0, 0];
        VacLimits(1,2) single = [0, 0];
        DcChannelMapping(1,:) uint16 {mustBeInteger, mustBeVector}
        AcChannelMapping(1,:) uint16 {mustBeInteger, mustBeVector}
        ShortedElements(1,:) uint16 {mustBeInteger, mustBeVector}
        OpenElements(1,:) uint16 {mustBeInteger, mustBeVector}
    end

    methods
        function width = GetWidth(array, orientation)
            arguments (Input)
                array(1,1) tobe.RowColumnArray
                orientation ZBP.RCAOrientation = ZBP.RCAOrientation.empty();
            end
            arguments (Output)
                width single
            end
            if isempty(orientation)
                width = array.Pitch - array.Kerf;
            else
                width = array.Pitch(int32(orientation)) - array.Kerf(int32(orientation));
            end
        end

        % Size is in the order [Row, Column] / [y, x]
        function size = GetSize(array, orientation)
            arguments (Input)
                array(1,1) tobe.RowColumnArray
                orientation ZBP.RCAOrientation = ZBP.RCAOrientation.empty();
            end
            arguments (Output)
                size single
            end
            width = array.GetWidth(orientation);
            if isempty(orientation)
                size = array.Pitch.*single(array.ElementCount - 1) + width;
            else
                size = array.Pitch(int32(orientation)).*single(array.ElementCount(int32(orientation)) - 1) + width;
            end
        end

        function elements = GetElements(array, orientation)
            arguments (Input)
                array(1,1) tobe.RowColumnArray
                orientation(1,1) ZBP.RCAOrientation
            end
            arguments (Output)
                elements uint16
            end
            switch orientation
                case ZBP.RCAOrientation.Rows
                    elements = array.GetRowElements();
                case ZBP.RCAOrientation.Columns
                    elements = array.GetColumnElements();
                otherwise
                    error(...
                        'tobe:RowColumnArray:GetElements:InvalidParameter',...
                        "Invalid Orientation");
            end
        end

        function elements = GetRowElements(array)
            arguments (Input)
                array(1,1) tobe.RowColumnArray
            end
            arguments (Output)
                elements uint16
            end
            elements = 1:array.ElementCount(1);
        end

        function elements = GetColumnElements(array)
            arguments (Input)
                array(1,1) tobe.RowColumnArray
            end
            arguments (Output)
                elements uint16
            end
            elements = array.ElementCount(1) + (1:array.ElementCount(2));
        end

        % Returns the element offset from the center fo the array in the x-y plane
        % Whether the offset is in the lateral direction or elevation direction is
        % determined by if it is a row position or column position
        function positions = GetLineElementPlanarPositions(array)
            arguments (Input)
                array(1,1) tobe.RowColumnArray
            end
            arguments (Output)
                positions(1,:) single
            end
            size = array.GetSize();
            elementCount = array.ElementCount;
            rowPositions = linspace(-size(1)/2, size(1)/2, elementCount(1));
            columnPositions = linspace(-size(2)/2, size(2)/2, elementCount(2));
            positions = [rowPositions, columnPositions];
        end

        % Returns 2 2D matrix of size (array.RowCount, array.ColumnCount)
        function [lateralGrid, elevationalGrid] = GetElementPositionMatrix(array)
            arguments
                array(1,1) tobe.RowColumnArray
            end
            positions = GetLineElementPlanarPositions(array);

            [elevationalGrid, lateralGrid] = meshgrid(positions(1:array.ElementCount(1)), positions((array.ElementCount(1)+1):end));
        end

        function Save(array, filename)
            arguments
                array(1,1) acquisition.Array
                filename = fullfile(sprintf("%s.json", array.Name))
            end

            filetext = jsonencode(array,"PrettyPrint",true);
            fid = fopen(filename, "wt");
            fprintf(fid, filetext);
        end
    end
end