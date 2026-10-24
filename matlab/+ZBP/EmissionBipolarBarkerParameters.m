% See LICENSE for license details.

% GENERATED CODE

classdef EmissionBipolarBarkerParameters
	properties
		chip_parameters(1,1) ZBP.EmissionSineParameters
		code_length(1,1)     single
	end

	properties (Constant)
		byteSize(1,1) uint32 = 12
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.EmissionBipolarBarkerParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.EmissionBipolarBarkerParameters.byteSize);
			bytes(9:12) = typecast(obj.code_length(:), 'uint8');
			bytes(1:8) = obj.chip_parameters.toBytes();
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.EmissionBipolarBarkerParameters
			end
			out = ZBP.EmissionBipolarBarkerParameters;
			out.code_length(:) = typecast(bytes(9:12), 'single');
			out.chip_parameters = ZBP.EmissionSineParameters.fromBytes(bytes(1:8));
		end
	end
end
