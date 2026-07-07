function fixMultiDataFrameEmissionParameters(filename)
arguments (Input)
    filename(1,1) string
end

fileID = fopen(filename, 'rw');
if fileID == -1
    error('ornot:fixMultiDataFrameEmissionParameters:RuntimeError: failed to open file');
end
bytes = fread(fileID, 1, 'uint8'); % skip magic number

assert(numel(bytes) >= ZBP.BaseHeader.byteSize);
baseHeader = ZBP.BaseHeader.fromBytes(bytes);
assert(baseHeader.magic == ZBP.Constants.HeaderMagic);
assert(baseHeader.major == 2);
header = ZBP.HeaderV2.fromBytes(bytes);

if header.raw_data_dimension(3) > 1 && header.emission_descriptors_offset ~= -1
    % We will leave the original emission descriptors in place,
    % but we will duplicate the emission descriptor for each frame, and let them point to the original emission parameters.
    emissionDescriptorBytes = bytes(header.emission_descriptors_offset + (1:ZBP.EmissionDescriptor.byteSize));
    % The following only works when the byte size of the emission descriptor is a multiple of the alignment, which it is.
    assert(ZBP.EmissionDescriptor.byteSize/ZBP.Constants.Alignment == floor(ZBP.EmissionDescriptor.byteSize/ZBP.Constants.Alignment));
    emissionDescriptorBytes = repmat(emissionDescriptorBytes, 1, header.raw_data_dimension(3));

    % Raw Data must be last to handle the case where the raw data is compressed.
    if header.raw_data_offset ~= -1
        rawDataBytes = bytes((header.raw_data_offset + 1):end);
        bytes((header.raw_data_offset + 1):end) = [];
    end

    % Point to the new emission descriptors
    bytes = [bytes, emissionDescriptorBytes];
    header.emission_descriptors_offset = numel(bytes) - numel(emissionDescriptorBytes) + 1;

    if header.raw_data_offset ~= -1
        bytes = [bytes, rawDataBytes];
        header.raw_data_offset = numel(bytes) - numel(rawDataBytes) + 1;
    end

    % Remove the contribution of the emission pulse length from the time offset,
    % since the emission pulse length is add right before beamforming.
    emissionDescriptor = ZBP.EmissionDescriptor.fromBytes(emissionDescriptorBytes);
    switch emissionDescriptor.emission_kind
        case ZBP.EmissionKind.Sine
            emissionParameters = ZBP.EmissionSineParameters.fromBytes(bytes(emissionDescriptor.emission_parameters_offset + (1:ZBP.EmissionSineParameters.byteSize)));
            header.time_offset = header.time_offset - emissionParameters.cycles / emissionParameters.frequency / 2;
        case ZBP.EmissionKind.Chirp
            emissionParameters = ZBP.EmissionChirpParameters.fromBytes(bytes(emissionDescriptor.emission_parameters_offset + (1:ZBP.EmissionChirpParameters.byteSize)));
            header.time_offset = header.time_offset - emissionParameters.duration / 2;
    end

    bytes(1:ZBP.HeaderV2.byteSize) = header.toBytes();

    fseek(fileID, 0, 'bof');
    fwrite(fileID, bytes, 'uint8');
end



fclose(fileID);

end