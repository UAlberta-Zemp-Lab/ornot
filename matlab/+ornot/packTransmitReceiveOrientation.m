function transmit_receive_orientation = packTransmitReceiveOrientation(transmit_orientation, receive_orientation)
%PACKTRANSMITRECEIVEORIENTATION Transmit Orientations are packed in the
%top 4 bits of a uint8 while Receive Orientations are packed in the bottom
%4 bits, with values matching the enum OGLBeamformerRCAOrientation
arguments (Input)
    transmit_orientation OGLBeamformerRCAOrientation
    receive_orientation OGLBeamformerRCAOrientation
end
arguments (Output)
    transmit_receive_orientation uint8
end
assert(all(size(transmit_orientation) == size(receive_orientation)));
transmit_receive_orientation = zeros(size(transmit_orientation), 'uint8');
for i = 1:numel(transmit_orientation)
    transmit_receive_orientation(i) = ...
        bitshift(uint8(transmit_orientation(i)), 4) ...
        + uint8(receive_orientation(i));
end
end