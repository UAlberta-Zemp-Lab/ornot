function [transmit_orientation, receive_orientation] = unpackTransmitReceiveOrientation(transmit_receive_orientation)
%UNPACKTRANSMITRECEIVEORIENTATION Transmit Orientations are packed in the
%top 4 bits of a uint8 while Receive Orientations are packed in the bottom
%4 bits, with values matching the enum ZBP.RCAOrientation
arguments (Input)
    transmit_receive_orientation uint8
end
arguments (Output)
    transmit_orientation ZBP.RCAOrientation
    receive_orientation ZBP.RCAOrientation
end
transmit_orientation = createArray(size(transmit_receive_orientation), "ZBP.RCAOrientation");
receive_orientation = createArray(size(transmit_receive_orientation), "ZBP.RCAOrientation");
for i = 1:numel(transmit_receive_orientation)
    transmit_receive_orientation(i) = ...
        bitshift(uint8(transmit_orientation), 4) ...
        + uint8(receive_orientation);
    transmit_orientation(i) = ZBP.RCAOrientation(bitand(bitshift(transmit_receive_orientation(i), -4), 15));
    receive_orientation(i) = ZBP.RCAOrientation(bitand(transmit_receive_orientation(i), 15));
end
end