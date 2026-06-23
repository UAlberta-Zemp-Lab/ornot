% See LICENSE for license details.

% GENERATED CODE

classdef XDopplerParameters
	properties
		angle_count(1,2)           int32
		tilting_angles_offset(1,1) int32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 12
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.XDopplerParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.XDopplerParameters.byteSize);
			bytes(1:8)  = typecast(obj.angle_count(:),           'uint8');
			bytes(9:12) = typecast(obj.tilting_angles_offset(:), 'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.XDopplerParameters
			end
			out = ZBP.XDopplerParameters;
			out.angle_count(:)           = typecast(bytes(1:8),  'int32');
			out.tilting_angles_offset(:) = typecast(bytes(9:12), 'int32');
		end
	end
end
