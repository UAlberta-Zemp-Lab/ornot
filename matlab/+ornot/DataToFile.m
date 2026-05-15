function DataToFile(data, compressionKind, data_filename)
arguments (Input)
    data {mustBeNumeric}
    compressionKind(1,1) ZBP.DataCompressionKind
    data_filename(1,1) string
end
arguments (Output)
end

bytes = ornot.DataToRaw(data, compressionKind);
fid = fopen(data_filename, "w");
fwrite(fid, bytes);
fclose(fid);
end
