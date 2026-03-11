classdef BeamformParameterConverter

    methods (Static)
        function bp = VsxToBp(vsx, transmitGroup, compressionKind)
            % Note: This assumes channel mapping is done, and only the receive channels are saved
            arguments (Input)
                vsx (1,1) VsxDirector
                transmitGroup(1,1) acquisition.TransmitGroup
                compressionKind(1,1) ZBP.DataCompressionKind
            end
            arguments (Output)
                bp (1,1) ornot.BeamformParameters
            end

            bp = ornot.BeamformParameters;

            scan = vsx.Scan;
            die = scan.Die;
            dieSize = die.Size();

            bp.raw_data_kind = int32(ZBP.DataKind.Int16);
            bp.speed_of_sound = scan.SpeedOfSound;
            switch transmitGroup.BeamformMode
                case acquisition.BeamformModes.FORCES
                    bp.acquisition_kind = int32(ZBP.AcquisitionKind.FORCES);
                case acquisition.BeamformModes.UFORCES
                    bp.acquisition_kind = int32(ZBP.AcquisitionKind.UFORCES);
                case acquisition.BeamformModes.HERCULES
                    bp.acquisition_kind = int32(ZBP.AcquisitionKind.HERCULES);
                case acquisition.BeamformModes.RCA_VLS
                    bp.acquisition_kind = int32(ZBP.AcquisitionKind.RCA_VLS);
                case acquisition.BeamformModes.RCA_TPW
                    bp.acquisition_kind = int32(ZBP.AcquisitionKind.RCA_TPW);
                case acquisition.BeamformModes.UHERCULES
                    bp.acquisition_kind = int32(ZBP.AcquisitionKind.UHERCULES);
                case acquisition.BeamformModes.OPTIMUS
                    bp.acquisition_kind = int32(ZBP.AcquisitionKind.HERCULES); % TODO: Confirm this is intentional
            end
            switch transmitGroup.DecodeMode
                case acquisition.DecodeModes.None
                    bp.decode_mode = int32(ZBP.DecodeMode.None);
                case acquisition.DecodeModes.HadamardDecode
                    bp.decode_mode = int32(ZBP.DecodeMode.Hadamard);
                case acquisition.DecodeModes.WalshDecode
                    bp.decode_mode = int32(ZBP.DecodeMode.Walsh);
            end
            bp.group_acquisition_time = transmitGroup.TransmitTime;

            receiveEvent = transmitGroup.ReceiveEvent;
            switch(receiveEvent.ReceiveMode)
                case acquisition.VsxSampleModes.NS200BW
                    bp.sampling_mode = int32(ZBP.SamplingMode.Standard);
                case {acquisition.VsxSampleModes.BS100BW, acquisition.VsxSampleModes.BS50BW}
                    bp.sampling_mode = int32(ZBP.SamplingMode.Bandpass);
                otherwise
                    throw(MException('acquisition.VsxSampleModes:InvalidArgument', "Unsupported mode"));
            end

            transmitEventNums = transmitGroup.TransmitEvents;
            beamformMode = transmitGroup.BeamformMode;

            if (isa(transmitGroup, 'acquisition.MultiGroup'))
                transmitGroup = transmitGroup.SubGroups;
            elseif (isa(transmitGroup, 'acquisition.OptimusTransmitGroup'))
                transmitGroup = transmitGroup.HeroGroups;
            end

            receiveOrientation = scan.TransmitEvents(transmitEventNums(1)).ImagingPattern.ReceiveOrientation;
            bp.channel_count = receiveOrientation.GetElementCount(die);
            rBuffer = vsx.Resource.RcvBuffer(receiveEvent.ReceiveBufferNum);
            bp.raw_data_dimension = uint32([rBuffer.rowsPerFrame, uint32(bp.channel_count), uint32(receiveEvent.SectionCount), uint32(receiveEvent.EnsembleLength)]);
            bp.receive_event_count = numel(transmitEventNums)/bp.raw_data_dimension(3);
            Receive = vsx.Receive(transmitEventNums(1));
            bp.sample_count = uint32(Receive.endSample - Receive.startSample + 1);

            bp.raw_data_compression_kind = int32(compressionKind);

            bp.transducer_element_pitch = die.Pitch;
            bp.transducer_transform_matrix = reshape(single([
                1,0,0,dieSize(1)/2;
                0,1,0,dieSize(2)/2;
                0,0,1,0;
                0,0,0,1;
                ]), 1, []);

            receiveElementCount = receiveOrientation.GetElementCount(die);
            bp.channel_mapping = int16(0:receiveElementCount-1);
            bp.sampling_frequency = single(Receive.samplesPerWave*vsx.Trans.frequency*1e6);
            bp.demodulation_frequency = single(Receive.demodFrequency * 1e6);
            bp.ensemble_repitition_interval = single(receiveEvent.EnsembleInterval);

            excitation = scan.Excitations(scan.TransmitEvents(transmitEventNums(1)).Excitation);
            bp.time_offset = excitation.GetPeakTime();
            bp.time_offset = bp.time_offset - receiveEvent.ScanDepth(1)*2/scan.SpeedOfSound;

            bp.emission_descriptor = ZBP.EmissionDescriptor;
            switch(class(excitation))
                case "acquisition.SineExcitation"
                    bp.emission_descriptor.emission_kind = int32(ZBP.EmissionKind.Sine);
                    bp.emission_parameters = ZBP.EmissionSineParameters;
                    bp.emission_parameters.cycles = excitation.CycleCount;
                    bp.emission_parameters.frequency = excitation.Frequency;
                case "acquisition.ChirpExcitation"
                    bp.emission_descriptor.emission_kind = int32(ZBP.EmissionKind.Chirp);
                    bp.emission_parameters = ZBP.EmissionChirpParameters;
                    bp.emission_parameters.duration = excitation.Duration;
                    bp.emission_parameters.min_frequency = excitation.Bandwidth(1);
                    bp.emission_parameters.max_frequency = excitation.Bandwidth(2);
            end

            firstTransmitEvent = scan.TransmitEvents(transmitEventNums(1));

            switch(bp.acquisition_kind)
                case {ZBP.AcquisitionKind.FORCES, ZBP.AcquisitionKind.UFORCES}
                    bp.time_offset = bp.time_offset + calculateCylindricalFocusedTransmitDelays(...
                        [0,0,0],firstTransmitEvent.GetFocusPositions(), firstTransmitEvent.TransmitFocus.FocusTime, ...
                        firstTransmitEvent.ImagingPattern.TransmitOrientation, scan.SpeedOfSound); % This calculation presumes that the group does not hold transmits for both orientations of a non-square die
                case {ZBP.AcquisitionKind.HERCULES, ZBP.AcquisitionKind.UHERCULES, ...
                        ZBP.AcquisitionKind.RCA_VLS, ZBP.AcquisitionKind.RCA_TPW}
                    bp.time_offset = bp.time_offset + firstTransmitEvent.TransmitFocus.FocusTime;
            end

            switch bp.acquisition_kind
                case ZBP.AcquisitionKind.FORCES
                    acquisition_parameters(bp.raw_data_dimension(3)) = ZBP.FORCESParameters;
                case ZBP.AcquisitionKind.UFORCES
                    acquisition_parameters(bp.raw_data_dimension(3)) = ZBP.uFORCESParameters;
                case ZBP.AcquisitionKind.HERCULES
                    acquisition_parameters(bp.raw_data_dimension(3)) = ZBP.HERCULESParameters;
                case ZBP.AcquisitionKind.RCA_VLS
                    acquisition_parameters = ZBP.VLSParameters;
                    bp.focal_depths = zeros(1, bp.receive_event_count, "single");
                    bp.origin_offsets = zeros(1, bp.receive_event_count, "single");
                    for i = 1:bp.receive_event_count
                        focus_position = transmitGroup.TransmitFocus(i).GetFocusPositions(transmitGroup.TransmitOrientation(i));
                        bp.focal_depths(i) = focus_position(3);
                        if transmitGroup.TransmitOrientation(i) == tobe.Orientation.Column
                            bp.origin_offsets(i) = focus_position(1);
                        else
                            bp.origin_offsets(i) = focus_position(2);
                        end
                    end
                case ZBP.AcquisitionKind.RCA_TPW
                    acquisition_parameters = ZBP.TPWParameters;
                    bp.tilting_angles = single([transmitGroup.TransmitFocus.SteeringAngle]);
                case ZBP.AcquisitionKind.UHERCULES
                    acquisition_parameters(bp.raw_data_dimension(3)) = ZBP.uHERCULESParameters;
            end

            if bp.acquisition_kind == ZBP.AcquisitionKind.FORCES || bp.acquisition_kind == ZBP.AcquisitionKind.HERCULES ...
                    || bp.acquisition_kind == ZBP.AcquisitionKind.UFORCES || bp.acquisition_kind == ZBP.AcquisitionKind.UHERCULES
                for i = 1:bp.raw_data_dimension(3)
                    acquisition_parameters(i).transmit_focus.focal_depth = transmitGroup(i).TransmitFocus.FocalDepth;
                    acquisition_parameters(i).transmit_focus.steering_angle = transmitGroup(i).TransmitFocus.SteeringAngle;
                    acquisition_parameters(i).transmit_focus.transmit_receive_orientation = transmitGroup(i).TransmitReceiveOrientations.packTransmitReceiveOrientations();
                end
            end

            assert(exist("acquisition_parameters", "var"), "Unsupported acquisition mode!");
            bp.acquisition_parameters = acquisition_parameters;

            if bp.acquisition_kind == ZBP.AcquisitionKind.RCA_VLS || bp.acquisition_kind == ZBP.AcquisitionKind.RCA_TPW
                bp.transmit_receive_orientations = transmitGroup.TransmitReceiveOrientations.packTransmitReceiveOrientations();
            end

            if bp.acquisition_kind == ZBP.AcquisitionKind.UFORCES || bp.acquisition_kind == ZBP.AcquisitionKind.UHERCULES
                bp.sparse_elements = zeros(bp.receive_event_count - 1, bp.raw_data_dimension(3),'uint16');
                for i = 1:bp.raw_data_dimension(3)
                    bp.sparse_elements(:, i) = transmitGroup(i).SparseElements;
                end
            end
        end
    end
end