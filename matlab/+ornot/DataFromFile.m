function bp = DataFromFile(bp, data_filename)
arguments (Input)
    bp(1,1) ornot.BeamformParameters
    data_filename(1,1) string
end
arguments (Output)
    bp(1,1) ornot.BeamformParameters
end

fid = fopen(data_filename);
bytes = fread(fid, "*uint8");
fclose(fid);

bp = ornot.DataFromRaw(bp, bytes);
end
