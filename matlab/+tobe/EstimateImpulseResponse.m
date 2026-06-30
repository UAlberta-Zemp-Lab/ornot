function impulseResponse = EstimateImpulseResponse(die, fs)
arguments
    die(1,1) tobe.RowColumnArray
    fs(1,1) single
end
numberOfCycles = 1; % ~1-2 for broad-band transducer
waveform = sin(2*pi*(0:1/fs:numberOfCycles/die.CenterFrequency)*die.CenterFrequency);
impulseResponse = waveform.*hamming(numel(waveform))';
end