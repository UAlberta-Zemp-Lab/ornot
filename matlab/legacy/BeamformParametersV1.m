classdef BeamformParametersV1
    methods (Static)
        function bp = ReadFromFile(filename)
            arguments
                filename(1,1) string
            end
            fileID = fopen(filename, 'r');
            if (fileID < 0)
                MException('BeamformParameters:IO', sprintf("Failed to open file! %s", filename));
            end
            try
                bytes = fread(fileID, "*uint8");
                bp    = ZBP.HeaderV1.fromBytes(bytes);
                assert(bp.magic == ZBP.Constants.HeaderMagic, 'BeamformParameters:IO', "Magic number doesn't match!");
                assert(bp.version == 1, 'BeamformParameters:IO', "Version number is not correct!");
            catch
                if (fileID >=0)
                    fclose(fileID);
                end
                rethrow(ME);
            end
        end
    end
end