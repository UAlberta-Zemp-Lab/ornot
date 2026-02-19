classdef BeamformParameterConverter

    methods (Static)
        function bp = VsxToBpV1(vsx, transmitGroup)

            scan = vsx.Scan;
            die = scan.Die;
            dieSize = die.Size();

            receiveEvent = transmitGroup.ReceiveEvent;

            rBuffer = vsx.Resource.RcvBuffer(receiveEvent.ReceiveBufferNum);

            txEvents = scan.TransmitEvents;
            transmitOrientation = txEvents(1).ImagingPattern.TransmitOrientation;
            receiveOrientation = txEvents(1).ImagingPattern.ReceiveOrientation;

            version = uint32(1);

            switch (transmitGroup.BeamformMode)
                case {acquisition.BeamformModes.FORCES, acquisition.BeamformModes.UFORCES, ...
                        acquisition.BeamformModes.HERCULES, acquisition.BeamformModes.RCA_VLS, ...
                        acquisition.BeamformModes.RCA_TPW, acquisition.BeamformModes.UHERCULES}
                otherwise
                    throw(MException('BeamformParameters:InvalidArgument', "Beamform Mode is not supported!"));
            end

            decode_mode   = int16(transmitGroup.DecodeMode);
            beamform_mode = int16(transmitGroup.BeamformMode);
            trOrientations = transmitGroup.TransmitReceiveOrientations(1);
            if (trOrientations.TransmitOrientation == tobe.Orientation.Row)
                if (trOrientations.ReceiveOrientation == tobe.Orientation.Row)
                    transmit_mode = int32(acquisition.TransmitModes.RowTxRowRx);
                else
                    transmit_mode = int32(acquisition.TransmitModes.RowTxColRx);
                end
            else
                if (trOrientations.ReceiveOrientation == tobe.Orientation.Row)
                    transmit_mode = int32(acquisition.TransmitModes.ColTxRowRx);
                else
                    transmit_mode = int32(acquisition.TransmitModes.ColTxColRx);
                end
            end

            sectionCount = receiveEvent.SectionCount;
            sectionLength = numel(txEvents)/sectionCount;

            transmitCount = sectionLength;

            raw_data_dim = uint32([uint32(rBuffer.rowsPerFrame), uint32(receiveOrientation.GetElementCount(die)), uint32(sectionCount), uint32(receiveEvent.EnsembleLength)]);
            decoded_data_dim = uint32([1,receiveOrientation.GetElementCount(die), transmitCount, 1]);
            Receive = evalin('base', 'Receive');
            decoded_data_dim(1) = Receive(1).endSample - Receive(1).startSample + 1;

            transducer_transform_matrix = single([
                1,0,0,dieSize(1)/2;
                0,1,0,dieSize(2)/2;
                0,0,1,0;
                0,0,0,1;
                ]);

            % NOTE(rnp): all other languages we will use with this data use 0-based indexing;
            % the code to add 1 back to the whole array in matlab is easy
            channel_mapping = int16(0:receiveOrientation.GetElementCount(die)-1);

            speed_of_sound = scan.SpeedOfSound;
            sampling_frequency = single(vsx.Receive(1).samplesPerWave*vsx.Trans.frequency*1e6);
            time_offset = -vsx.Receive(1).startDepth*2 / (vsx.Trans.frequency*1e6);
            switch (transmitGroup.BeamformMode)
                case {acquisition.BeamformModes.HERCULES, acquisition.BeamformModes.RCA_VLS, acquisition.BeamformModes.RCA_TPW}
                    time_offset = time_offset + scan.TransmitEvents(1).TransmitFocus.FocusTime;
                case {acquisition.BeamformModes.FORCES, acquisition.BeamformModes.UFORCES}
                    time_offset = time_offset + calculateCylindricalFocusedTransmitDelays([0,0,0],scan.TransmitEvents(1).GetFocusPositions(),scan.TransmitEvents(1).TransmitFocus.FocusTime,transmitOrientation,scan.SpeedOfSound);
            end

            transmitFoci = [scan.TransmitEvents(1:min(transmitCount, 256)).TransmitFocus];
            steering_angles = single([transmitFoci.SteeringAngle]);
            focal_depths    = single([transmitFoci.FocalDepth]);

            if (isfield(vsx.TW(1), "Parameters"))
                center_frequency = vsx.TW(1).Parameters(1)*1e6;
            else
                center_frequency = die.CenterFrequency;
            end
            transducer_element_pitch = single(die.Pitch);

            sparse_elements = -1*ones(1, 256, 'int16');
            hadamard_rows = -1*ones(1, 256, 'int16');
            switch(transmitGroup.BeamformMode)
                case {acquisition.BeamformModes.UFORCES, acquisition.BeamformModes.UHERCULES}
                    sparse_elements(1:numel(transmitGroup.SparseElements)) = int16(transmitGroup.SparseElements);
                    %case {acquisition.BeamformModes.READI}
                    %hadamard_rows(1:numel(obj.hadamardRows)) = int16(obj.HadamardRows);
            end

            bp = BeamformParametersV1();
            bp.decode_mode = decode_mode;
            bp.beamform_mode = beamform_mode;
            bp.raw_data_dimension = raw_data_dim;
            bp.decoded_data_dimension = decoded_data_dim;
            bp.speed_of_sound = speed_of_sound;
            bp.center_frequency = center_frequency;
            bp.sampling_frequency = sampling_frequency;
            bp.time_offset = time_offset;
            bp.transmit_mode = transmit_mode;
            bp.transducer_element_pitch = transducer_element_pitch;
            bp.transducer_transform_matrix = transducer_transform_matrix;
            bp.channel_mapping(1:numel(channel_mapping)) = channel_mapping;
            bp.steering_angles(1:numel(steering_angles)) = steering_angles;
            bp.focal_depths(1:numel(focal_depths)) = focal_depths;
            bp.sparse_elements(1:numel(sparse_elements)) = sparse_elements;
            bp.hadamard_rows(1:numel(hadamard_rows)) = hadamard_rows;
        end

        function bp = VsxToBpV2PreRelease(vsx, transmitGroup)
            bp = BeamformParametersV2();

            scan = vsx.Scan;
            die = scan.Die;
            dieSize = die.Size();

            bp.data_type = 0;
            bp.speed_of_sound = scan.SpeedOfSound;
            bp.beamform_mode = transmitGroup.BeamformMode;
            bp.decode_mode = transmitGroup.DecodeMode;
            bp.group_acquisition_time = transmitGroup.TransmitTime;
            bp.construction_mode = 0; % TODO: Define these modes

            receiveEvent = transmitGroup.ReceiveEvent;
            bp.sampling_mode = receiveEvent.ReceiveMode.ToOglSamplingMode();

            transmitEventNums = transmitGroup.TransmitEvents;
            beamformMode = transmitGroup.BeamformMode;

            if (isa(transmitGroup, 'acquisition.MultiGroup'))
                transmitGroup = transmitGroup.SubGroups;
            elseif (isa(transmitGroup, 'acquisition.OptimusTransmitGroup'))
                transmitGroup = transmitGroup.HeroGroups;
            end

            receiveOrientation = scan.TransmitEvents(transmitEventNums(1)).ImagingPattern.ReceiveOrientation;
            sectionCount = receiveEvent.SectionCount;
            sectionLength = numel(transmitEventNums)/sectionCount;
            rBuffer = vsx.Resource.RcvBuffer(receiveEvent.ReceiveBufferNum);
            Receive = vsx.Receive(transmitEventNums(1));
            sampleCount = Receive.endSample - Receive.startSample + 1;
            receiveElementOrientation = receiveOrientation.GetElementCount(die);

            bp.raw_data_dimension = uint32([rBuffer.rowsPerFrame, uint32(receiveElementOrientation), uint32(receiveEvent.SectionCount), uint32(receiveEvent.EnsembleLength)]);
            bp.decoded_data_dimension = uint32([sampleCount, receiveElementOrientation, sectionLength, 1]);

            bp.transducer_element_pitch = die.Pitch;
            bp.transducer_bandwidth = die.Bandwidth;
            bp.transducer_transform_matrix = single([
                1,0,0,dieSize(1)/2;
                0,1,0,dieSize(2)/2;
                0,0,1,0;
                0,0,0,1;
                ]);

            receiveElementCount = receiveOrientation.GetElementCount(die);
            bp.channel_mapping(1:receiveElementCount) = int16(0:receiveElementCount-1);
            bp.sampling_frequency = single(Receive.samplesPerWave*vsx.Trans.frequency*1e6);
            bp.demodulation_frequency = Receive.demodFrequency * 1e6;
            bp.ensemble_repitition_interval = receiveEvent.EnsembleInterval;

            excitation = scan.Excitations(scan.TransmitEvents(transmitEventNums(1)).Excitation);
            bp.time_offset = excitation.GetPeakTime();
            bp.time_offset = bp.time_offset - receiveEvent.ScanDepth(1)*2/scan.SpeedOfSound;
            excitationData = acquisition.ExcitationData.FromObject(excitation);
            bp.excitation = excitationData.ToBytes();

            firstTransmitEvent = scan.TransmitEvents(transmitEventNums(1));

            switch(beamformMode)
                case {acquisition.BeamformModes.FORCES, acquisition.BeamformModes.UFORCES}
                    bp.time_offset = bp.time_offset + calculateCylindricalFocusedTransmitDelays(...
                        [0,0,0],firstTransmitEvent.GetFocusPositions(), firstTransmitEvent.TransmitFocus.FocusTime, ...
                        firstTransmitEvent.ImagingPattern.TransmitOrientation, scan.SpeedOfSound); % This calculation presumes that the group does not hold transmits for both orientations of a non-square die
                case {acquisition.BeamformModes.HERCULES, acquisition.BeamformModes.UHERCULES, acquisition.BeamformModes.OPTIMUS, ...
                        acquisition.BeamformModes.RCA_VLS, acquisition.BeamformModes.RCA_TPW}
                    bp.time_offset = bp.time_offset + firstTransmitEvent.TransmitFocus.FocusTime;
            end

            switch (beamformMode)
                case {acquisition.BeamformModes.FORCES, acquisition.BeamformModes.UFORCES, ...
                        acquisition.BeamformModes.HERCULES, acquisition.BeamformModes.UHERCULES, acquisition.BeamformModes.OPTIMUS, ...
                        acquisition.BeamformModes.RCA_VLS, acquisition.BeamformModes.RCA_TPW, ...
                        acquisition.BeamformModes.HEXPD, acquisition.BeamformModes.XDOPPLER}
                    if (beamformMode == acquisition.BeamformModes.RCA_VLS ...
                            || beamformMode == acquisition.BeamformModes.RCA_TPW)
                        modeLength = sectionLength;
                    else
                        modeLength = numel(transmitGroup);
                    end
                    for i = 1:modeLength
                        if (beamformMode == acquisition.BeamformModes.RCA_VLS ...
                                || beamformMode == acquisition.BeamformModes.RCA_TPW)
                            transmitOrientation = transmitGroup.TransmitOrientation(i);
                            focalDepth = transmitGroup.TransmitFocus(i).FocalDepth;
                            steeringAngle = transmitGroup.TransmitFocus(i).SteeringAngle;
                        else
                            transmitOrientation = transmitGroup(i).TransmitOrientation;
                            focalDepth = transmitGroup(i).TransmitFocus.FocalDepth;
                            steeringAngle = transmitGroup(i).TransmitFocus.SteeringAngle;
                        end
                        receiveOrientation = transmitOrientation.Invert();

                        modeData(i).transmit_mode = uint16(transmitOrientation.GetOGLBeamformerTransmitMode());
                        modeData(i).receive_mode = uint16(receiveOrientation.GetOGLBeamformerTransmitMode());
                        modeData(i).focal_vector = [single(focalDepth), single(steeringAngle)];
                        if (beamformMode == acquisition.BeamformModes.UFORCES || beamformMode == acquisition.BeamformModes.UHERCULES)
                            modeData(i).sparse_elements = zeros(1, bp.decoded_data_dimension(3) - 1,'uint16');
                            sparseElements = transmitGroup(i).SparseElements;
                            modeData(i).sparse_elements(1:numel(sparseElements)) = sparseElements;
                        end
                    end
                    bp.mode_data = modeData;
                otherwise
                    throw(MException('BeamformParameters:NotImplemented', "Unsupported beamform mode!"));
            end
        end

        function bp = VsxToBpV2(vsx, transmitGroup, compressionKind)
            % Note: This assumes channel mapping is done, and only the receive channels are saved
            arguments (Input)
                vsx (1,1) VsxDirector
                transmitGroup(1,1) acquisition.TransmitGroup
                compressionKind(1,1) ZBP.DataCompressionKind
            end
            arguments (Output)
                bp (1,1) ZBP.BeamformParametersV2
            end

            bp = ZBP.BeamformParametersV2;

            scan = vsx.Scan;
            die = scan.Die;
            dieSize = die.Size();

            bp.header = ZBP.HeaderV2;

            bp.header.raw_data_kind = int32(ZBP.DataKind.Int16);
            bp.header.speed_of_sound = scan.SpeedOfSound;
            switch transmitGroup.BeamformMode
                case acquisition.BeamformModes.FORCES
                    bp.header.acquisition_mode = int32(ZBP.AcquisitionKind.FORCES);
                case acquisition.BeamformModes.UFORCES
                    bp.header.acquisition_mode = int32(ZBP.AcquisitionKind.UFORCES);
                case acquisition.BeamformModes.HERCULES
                    bp.header.acquisition_mode = int32(ZBP.AcquisitionKind.HERCULES);
                case acquisition.BeamformModes.RCA_VLS
                    bp.header.acquisition_mode = int32(ZBP.AcquisitionKind.RCA_VLS);
                case acquisition.BeamformModes.RCA_TPW
                    bp.header.acquisition_mode = int32(ZBP.AcquisitionKind.RCA_TPW);
                case acquisition.BeamformModes.UHERCULES
                    bp.header.acquisition_mode = int32(ZBP.AcquisitionKind.UHERCULES);
                case acquisition.BeamformModes.OPTIMUS
                    bp.header.acquisition_mode = int32(ZBP.AcquisitionKind.HERCULES); % TODO: Confirm this is intentional
            end
            switch transmitGroup.DecodeMode
                case acquisition.DecodeModes.None
                    bp.header.decode_mode = int32(ZBP.DecodeMode.None);
                case acquisition.DecodeModes.HadamardDecode
                    bp.header.decode_mode = int32(ZBP.DecodeMode.Hadamard);
                case acquisition.DecodeModes.WalshDecode
                    bp.header.decode_mode = int32(ZBP.DecodeMode.Walsh);
            end
            bp.header.group_acquisition_time = transmitGroup.TransmitTime;

            receiveEvent = transmitGroup.ReceiveEvent;
            switch(receiveEvent.ReceiveMode)
                case acquisition.VsxSampleModes.NS200BW
                    bp.header.sampling_mode = int32(ZBP.SamplingMode.Standard);
                case {acquisition.VsxSampleModes.BS100BW, acquisition.VsxSampleModes.BS50BW}
                    bp.header.sampling_mode = int32(ZBP.SamplingMode.Bandpass);
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
            bp.header.channel_count = receiveOrientation.GetElementCount(die);
            rBuffer = vsx.Resource.RcvBuffer(receiveEvent.ReceiveBufferNum);
            bp.header.raw_data_dimension = uint32([rBuffer.rowsPerFrame, uint32(bp.header.channel_count), uint32(receiveEvent.SectionCount), uint32(receiveEvent.EnsembleLength)]);
            bp.header.receive_event_count = numel(transmitEventNums)/bp.header.raw_data_dimension(3);
            Receive = vsx.Receive(transmitEventNums(1));
            bp.header.sample_count = uint32(Receive.endSample - Receive.startSample + 1);

            bp.header.raw_data_compression_kind = int32(compressionKind);

            bp.header.transducer_element_pitch = die.Pitch;
            bp.header.transducer_transform_matrix = reshape(single([
                1,0,0,dieSize(1)/2;
                0,1,0,dieSize(2)/2;
                0,0,1,0;
                0,0,0,1;
                ]), 1, []);

            receiveElementCount = receiveOrientation.GetElementCount(die);
            bp.channel_mapping = int16(0:receiveElementCount-1);
            bp.header.sampling_frequency = single(Receive.samplesPerWave*vsx.Trans.frequency*1e6);
            bp.header.demodulation_frequency = single(Receive.demodFrequency * 1e6);
            bp.header.ensemble_repitition_interval = single(receiveEvent.EnsembleInterval);

            excitation = scan.Excitations(scan.TransmitEvents(transmitEventNums(1)).Excitation);
            bp.header.time_offset = excitation.GetPeakTime();
            bp.header.time_offset = bp.header.time_offset - receiveEvent.ScanDepth(1)*2/scan.SpeedOfSound;

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

            switch(bp.header.acquisition_mode)
                case {ZBP.AcquisitionKind.FORCES, ZBP.AcquisitionKind.UFORCES}
                    bp.header.time_offset = bp.header.time_offset + calculateCylindricalFocusedTransmitDelays(...
                        [0,0,0],firstTransmitEvent.GetFocusPositions(), firstTransmitEvent.TransmitFocus.FocusTime, ...
                        firstTransmitEvent.ImagingPattern.TransmitOrientation, scan.SpeedOfSound); % This calculation presumes that the group does not hold transmits for both orientations of a non-square die
                case {ZBP.AcquisitionKind.HERCULES, ZBP.AcquisitionKind.UHERCULES, ...
                        ZBP.AcquisitionKind.RCA_VLS, ZBP.AcquisitionKind.RCA_TPW}
                    bp.header.time_offset = bp.header.time_offset + firstTransmitEvent.TransmitFocus.FocusTime;
            end

            switch bp.header.acquisition_mode
                case ZBP.AcquisitionKind.FORCES
                    acquisition_parameters(bp.header.raw_data_dimension(3)) = ZBP.FORCESParameters;
                case ZBP.AcquisitionKind.UFORCES
                    acquisition_parameters(bp.header.raw_data_dimension(3)) = ZBP.uFORCESParameters;
                case ZBP.AcquisitionKind.HERCULES
                    acquisition_parameters(bp.header.raw_data_dimension(3)) = ZBP.HERCULESParameters;
                case ZBP.AcquisitionKind.RCA_VLS
                    acquisition_parameters = ZBP.VLSParameters;
                    focus_positions = transmitGroup.TransmitFocus.GetFocusPositions();
                    bp.focal_depths = focus_positions(:, 3);
                    bp.origin_offsets = zeros(1, bp.header.receive_event_count, "single");
                    for i = 1:bp.header.receive_event_count
                        if transmitGroup.TransmitOrientation(i) == tobe.Orientation.Column
                            bp.origin_offsets(i) = focus_positions(i, 1);
                        else
                            bp.origin_offsets(i) = focus_positions(i, 2);
                        end
                    end
                case ZBP.AcquisitionKind.RCA_TPW
                    acquisition_parameters = ZBP.TPWParameters;
                    bp.tilting_angle = single([transmitGroup.TransmitFocus.SteeringAngle]);
                case ZBP.AcquisitionKind.UHERCULES
                    acquisition_parameters(bp.header.raw_data_dimension(3)) = ZBP.uHERCULESParameters;
            end

            if bp.header.acquisition_mode == ZBP.AcquisitionKind.FORCES || bp.header.acquisition_mode == ZBP.AcquisitionKind.HERCULES ...
                    || bp.header.acquisition_mode == ZBP.AcquisitionKind.UFORCES || bp.header.acquisition_mode == ZBP.AcquisitionKind.UHERCULES
                for i = 1:bp.header.raw_data_dimension(3)
                    acquisition_parameters(i).transmit_focus.focal_depth = transmitGroup(i).TransmitFocus.FocalDepth;
                    acquisition_parameters(i).transmit_focus.steering_angle = transmitGroup(i).TransmitFocus.SteeringAngle;
                    acquisition_parameters(i).transmit_focus.transmit_receive_orientation = transmitGroup(i).TransmitReceiveOrientations.packTransmitReceiveOrientations();
                end
            end

            assert(exist("acquisition_parameters", "var"), "Unsupported acquisition mode!");
            bp.acquisition_parameters = acquisition_parameters;

            if bp.header.acquisition_mode == ZBP.AcquisitionKind.RCA_VLS || bp.header.acquisition_mode == ZBP.AcquisitionKind.RCA_TPW
                bp.transmit_receive_orientations = transmitGroup.TransmitReceiveOrientations.packTransmitReceiveOrientations();
            end

            if bp.header.acquisition_mode == ZBP.AcquisitionKind.UFORCES || bp.header.acquisition_mode == ZBP.AcquisitionKind.UHERCULES
                bp.sparse_elements = zeros(bp.header.receive_event_count - 1, bp.header.raw_data_dimension(3),'uint16');
                for i = 1:bp.header.raw_data_dimension(3)
                    bp.sparse_elements(:, i) = transmitGroup(i).SparseElements;
                end
            end
        end

        function bp = SimToBpV2(scan, transmitGroup, sampleCount)
            bp = BeamformParametersV2();

            die = scan.Die;
            dieSize = die.Size();

            bp.data_type = 0;
            bp.speed_of_sound = scan.SpeedOfSound;
            bp.beamform_mode = transmitGroup.BeamformMode;
            bp.decode_mode = transmitGroup.DecodeMode;
            bp.group_acquisition_time = transmitGroup.TransmitTime;
            bp.construction_mode = 0; % TODO: Define these modes

            receiveEvent = transmitGroup.ReceiveEvent;
            bp.sampling_mode = receiveEvent.ReceiveMode.ToOglSamplingMode();

            transmitEventNums = transmitGroup.TransmitEvents;
            beamformMode = transmitGroup.BeamformMode;

            if (isa(transmitGroup, 'acquisition.MultiGroup'))
                transmitGroup = transmitGroup.SubGroups;
            elseif (isa(transmitGroup, 'acquisition.OptimusTransmitGroup'))
                transmitGroup = transmitGroup.HeroGroups;
            end

            receiveOrientation = scan.TransmitEvents(transmitEventNums(1)).ImagingPattern.ReceiveOrientation;
            sectionCount = receiveEvent.SectionCount;
            sectionLength = numel(transmitEventNums)/sectionCount;

            receiveElementOrientation = receiveOrientation.GetElementCount(die);

            bp.raw_data_dimension = uint32([uint32(sampleCount)*uint32(sectionLength), uint32(die.ElementCount), uint32(receiveEvent.SectionCount), uint32(receiveEvent.EnsembleLength)]);
            bp.decoded_data_dimension = uint32([sampleCount, receiveElementOrientation, sectionLength, 1]);

            bp.transducer_element_pitch = die.Pitch;
            bp.transducer_bandwidth = die.Bandwidth;
            bp.transducer_transform_matrix = single([
                1,0,0,dieSize(1)/2;
                0,1,0,dieSize(2)/2;
                0,0,1,0;
                0,0,0,1;
                ]);

            bp.channel_mapping = 0:255;
            bp.sampling_frequency = single(scan.FieldIIParameters.SamplingRatio*die.CenterFrequency);
            bp.demodulation_frequency = scan.Excitations(1).Frequency;
            bp.ensemble_repitition_interval = receiveEvent.EnsembleInterval;

            excitation = scan.Excitations(scan.TransmitEvents(transmitEventNums(1)).Excitation);
            bp.time_offset = excitation.GetPeakTime();
            bp.time_offset = bp.time_offset - receiveEvent.ScanDepth(1)*2/scan.SpeedOfSound;
            excitationData = acquisition.ExcitationData.FromObject(excitation);
            bp.excitation = excitationData.ToBytes();

            firstTransmitEvent = scan.TransmitEvents(transmitEventNums(1));

            switch(beamformMode)
                case {acquisition.BeamformModes.FORCES, acquisition.BeamformModes.UFORCES}
                    bp.time_offset = bp.time_offset + calculateCylindricalFocusedTransmitDelays(...
                        [0,0,0],firstTransmitEvent.GetFocusPositions(), firstTransmitEvent.TransmitFocus.FocusTime, ...
                        firstTransmitEvent.ImagingPattern.TransmitOrientation, scan.SpeedOfSound); % This calculation presumes that the group does not hold transmits for both orientations of a non-square die
                case {acquisition.BeamformModes.HERCULES, acquisition.BeamformModes.UHERCULES, acquisition.BeamformModes.OPTIMUS, ...
                        acquisition.BeamformModes.RCA_VLS, acquisition.BeamformModes.RCA_TPW}
                    bp.time_offset = bp.time_offset + firstTransmitEvent.TransmitFocus.FocusTime;
            end

            switch (beamformMode)
                case {acquisition.BeamformModes.FORCES, acquisition.BeamformModes.UFORCES, ...
                        acquisition.BeamformModes.HERCULES, acquisition.BeamformModes.UHERCULES, acquisition.BeamformModes.OPTIMUS, ...
                        acquisition.BeamformModes.RCA_VLS, acquisition.BeamformModes.RCA_TPW, ...
                        acquisition.BeamformModes.HEXPD, acquisition.BeamformModes.XDOPPLER}
                    if (beamformMode == acquisition.BeamformModes.RCA_VLS ...
                            || beamformMode == acquisition.BeamformModes.RCA_TPW)
                        modeLength = sectionLength;
                    else
                        modeLength = numel(transmitGroup);
                    end
                    for i = 1:modeLength
                        if (beamformMode == acquisition.BeamformModes.RCA_VLS ...
                                || beamformMode == acquisition.BeamformModes.RCA_TPW)
                            transmitOrientation = transmitGroup.TransmitOrientation(i);
                            focalDepth = transmitGroup.TransmitFocus(i).FocalDepth;
                            steeringAngle = transmitGroup.TransmitFocus(i).SteeringAngle;
                        else
                            transmitOrientation = transmitGroup(i).TransmitOrientation;
                            focalDepth = transmitGroup(i).TransmitFocus.FocalDepth;
                            steeringAngle = transmitGroup(i).TransmitFocus.SteeringAngle;
                        end
                        receiveOrientation = transmitOrientation.Invert();

                        modeData(i).transmit_mode = uint16(transmitOrientation.GetOGLBeamformerTransmitMode());
                        modeData(i).receive_mode = uint16(receiveOrientation.GetOGLBeamformerTransmitMode());
                        modeData(i).focal_vector = [single(focalDepth), single(steeringAngle)];
                        if (beamformMode == acquisition.BeamformModes.UFORCES || beamformMode == acquisition.BeamformModes.UHERCULES)
                            modeData(i).sparse_elements = zeros(1, bp.decoded_data_dimension(3) - 1,'uint16');
                            sparseElements = transmitGroup(i).SparseElements;
                            modeData(i).sparse_elements(1:numel(sparseElements)) = sparseElements;
                        end
                    end
                    bp.mode_data = modeData;
                otherwise
                    throw(MException('BeamformParameters:NotImplemented', "Unsupported beamform mode!"));
            end
        end
    end
end