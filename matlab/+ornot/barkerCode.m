function code = barkerCode(code_length)
arguments (Input)
    code_length(1,1) {mustBeInteger, mustBePositive}
end
arguments (Output)
    code(1,:) double
end

switch code_length
    case 2
        code = [1 1];
    case 3
        code = [1 1 0];
    case 4
        code = [1 1 0 1];
    case 5
        code = [1 1 1 0 1];
    case 7
        code = [1 1 1 0 0 1 0];
    case 11
        code = [1 1 1 0 0 0 1 0 0 1 0];
    case 13
        code = [1 1 1 1 1 0 0 1 1 0 1 0 1];
    otherwise
        error('ornot:barkerCode:UnsupportedLength', ...
            'Unsupported Barker code length: %d.', code_length);
end
end