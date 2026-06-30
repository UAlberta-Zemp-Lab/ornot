function output = replaceDamagedChannels(die, input, replaceOpen, replaceShort)
arguments (Input)
    die(1,1) tobe.RowColumnArray
    input(:,:) single
    replaceOpen single {mustBeScalarOrEmpty} = [];
    replaceShort single {mustBeScalarOrEmpty} = [];
end

assert(sum(die.ElementCount) == size(input, 2), ...
    'tobe:replaceDamagedChannels:InvalidParameter', ...
    "The number of columns in input should equal the element count of the die!");
output = input;
if ~isempty(replaceOpen)
    output(:,die.OpenElements) = replaceOpen;
end
if ~isempty(replaceShort)
    output(:,die.ShortedElements) = replaceShort;
end
end