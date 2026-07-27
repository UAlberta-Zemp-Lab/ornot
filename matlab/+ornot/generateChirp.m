function excitation = generateChirp(emissionParameters, times, tapering)
arguments (Input)
    emissionParameters(1, 1) ZBP.EmissionChirpParameters
    times(1, :) {mustBeNumeric}
    tapering(1,1) {mustBeNumeric} = 0.20;
end
arguments (Output)
    excitation(1, :) {mustBeNumeric}
end
f1 = emissionParameters.min_frequency;
f2 = emissionParameters.max_frequency;
B =  f2 - f1; % Bandwidth [Hz]
D = emissionParameters.duration;
f = f1 + B/(2*D) * times;
arg = 2*pi*f.*times;
excitation = complex(cos(arg), sin(arg));
% Apply tapering
excitation = excitation .* tukeywin(length(excitation), tapering)';
end