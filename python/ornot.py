# See LICENSE for license details.

import cffi
import math
import os
import struct

from ZBP import ZBP

class ornot:
	def __init__(self, library_path):
		"""
		Initializes ornot helper class

		Arguments:
		  library_path (string): base path containing ornot.so/ornot.dylib/ornot.dll
		                         and ogl_beamformer_lib.so/ogl_beamformer_lib.dll
		                         libraries
		"""
		from sys import platform

		self.ffi = cffi.FFI()
		self.ffi.cdef(open('ogl_beamformer_lib_python_ffi.h').read())
		self.ffi.cdef(open('ornot_python_ffi.h').read())

		ornot_name = ""
		ogl_name   = ""
		if platform == "linux" or platform == "linux2":
			ornot_name = "ornot.so"
			ogl_name   = "ogl_beamformer_lib.so"
		elif platform == "darwin":
			ornot_name = "ornot.dylib"
		elif platform == "win32":
			ornot_name = "ornot.dll"
			ogl_name   = "ogl_beamformer_lib.dll"

		self.ornot = self.ffi.dlopen(os.path.join(library_path, ornot_name))
		if platform != "darwin":
			self.ogl = self.ffi.dlopen(os.path.join(library_path, ogl_name))

	def data_from_raw(self, parameters, raw):
		"""
		Unpacks raw data decompressing if necessary.

		Arguments:
		  parameters (Parameters): A filled in instance of a Parameters object
		  raw        (uint8 []):   raw bytes

		Returns:
		  (ffi.type): an ffi pointer where type depends on parameters.raw_data_kind
		  int:        size of data in bytes
		"""
		data_kind_size_table = {
			ZBP.DataKind_Int16:          2,
			ZBP.DataKind_Int16Complex:   4,
			ZBP.DataKind_Float32:        4,
			ZBP.DataKind_Float32Complex: 8,
			ZBP.DataKind_Float16:        2,
			ZBP.DataKind_Float16Complex: 4,
		}
		data_kind_size = data_kind_size_table.get(parameters.raw_data_kind, -1)
		if data_kind_size == -1:
			raise ValueError(f"Invalid Data Kind {parameters.raw_data_kind}")

		data_points = parameters.raw_data_dimension[0] * parameters.raw_data_dimension[1] * parameters.raw_data_dimension[2] * parameters.raw_data_dimension[3]
		data_size   = data_kind_size * data_points

		data_kind_ffi_kind = {
			ZBP.DataKind_Int16:          "int16_t []",
			ZBP.DataKind_Int16Complex:   "int16_t []",
			ZBP.DataKind_Float32:        "float []",
			ZBP.DataKind_Float32Complex: "float []",
			# TODO: works fine for passing to beamformer but is weird if you try to inspect in python
			ZBP.DataKind_Float16:        "int16_t []",
			ZBP.DataKind_Float16Complex: "int16_t []",
		}

		raw_size = len(raw)
		raw      = bytes(raw)
		if parameters.raw_data_compression_kind == ZBP.DataCompressionKind_ZSTD:
			data = self.ffi.new(data_kind_ffi_kind[parameters.raw_data_kind], data_points)
			if self.ornot.unpack_zstd_compressed_data(self.ffi.from_buffer(raw), raw_size, data, data_size) == 0:
				raise RuntimeError(f"Invalid File: {file}")

		if parameters.raw_data_compression_kind == ZBP.DataCompressionKind_None:
			data = self.ffi.from_buffer(bytes(raw))
			data = self.ffi.cast(data_kind_ffi_kind[parameters.raw_data_kind], data)

		return data, data_size

	def data_from_file(self, parameters, file):
		"""
		Loads and decompresses a raw data file.

		Arguments:
		  parameters (Parameters): A filled in instance of a Parameters object
		  file       (string):     path to raw data file

		Returns:
		  (ffi.type): an ffi pointer where type depends on parameters.raw_data_kind
		  int:        size of data in bytes
		"""
		with open(file, "rb") as f:
			data, data_size = self.data_from_raw(parameters, f.read())
		return data, data_size

	def beamformer_simple_parameters_from_parameters(self, parameters):
		"""
		Fills in all data dependant (Parameter) members of a
		BeamformerSimpleParameters structure.

		Arguments:
		  parameters (Parameters): A filled in instance of a Parameters object

		Returns:
		  (ffi.BeamformerSimpleParameters *): an ffi compatible parameters structure
		"""
		ogl = self.ogl

		bp = self.ffi.new("BeamformerSimpleParameters *")
		bp.decode_mode            = parameters.decode_mode
		bp.acquisition_kind       = parameters.acquisition_kind
		bp.time_offset            = parameters.time_offset
		bp.sampling_frequency     = parameters.sampling_frequency
		bp.demodulation_frequency = parameters.demodulation_frequency
		bp.speed_of_sound         = parameters.speed_of_sound
		bp.xdc_transform          = parameters.transducer_transform_matrix
		bp.xdc_element_pitch      = parameters.transducer_element_pitch
		bp.raw_data_dimensions    = parameters.raw_data_dimension[0:2]
		bp.data_kind              = parameters.raw_data_kind

		sampling_mode_map = {
			ZBP.SamplingMode_Standard: ogl.BeamformerSamplingMode_4X,
			ZBP.SamplingMode_Bandpass: ogl.BeamformerSamplingMode_2X,
		}
		bp.sampling_mode     = sampling_mode_map[parameters.sampling_mode]

		bp.sample_count      = parameters.sample_count
		bp.channel_count     = parameters.channel_count
		bp.acquisition_count = parameters.receive_event_count

		if len(parameters.channel_mapping) > 0:
			bp.channel_mapping[0:bp.channel_count] = parameters.channel_mapping[0:bp.channel_count]
		else:
			for i in range(bp.channel_count):
				bp.channel_mapping[i] = i

		if (bp.acquisition_kind == ZBP.AcquisitionKind_UFORCES or
		    bp.acquisition_kind == ZBP.AcquisitionKind_UHERCULES):
			bp.sparse_elements[0:bp.acquisition_count] = parameters.acquisition_parameters['sparse_elements'][0:bp.acquisition_count]

		if (bp.acquisition_kind == ZBP.AcquisitionKind_HERCULES or
		    bp.acquisition_kind == ZBP.AcquisitionKind_UHERCULES):
			bp.single_focus       = 1
			bp.single_orientation = 1
			transmit_focus = parameters.acquisition_parameters['transmit_focus']
			bp.transmit_receive_orientation = transmit_focus.transmit_receive_orientation
			bp.focal_vector[0] = transmit_focus.steering_angle
			bp.focal_vector[1] = transmit_focus.focal_depth

		if (bp.acquisition_kind == ZBP.AcquisitionKind_RCA_TPW or
		    bp.acquisition_kind == ZBP.AcquisitionKind_RCA_VLS):
			bp.transmit_receive_orientations[0:bp.acquisition_count] = parameters.acquisition_parameters['transmit_receive_orientations'][0:bp.acquisition_count]

		if bp.acquisition_kind == ZBP.AcquisitionKind_RCA_TPW:
			for i in range(bp.acquisition_count):
				bp.focal_depths[i] = float('inf')
			bp.steering_angles[0:bp.acquisition_count] = parameters.acquisition_parameters['tilting_angles'][0:bp.acquisition_count]

		if bp.acquisition_kind == ZBP.AcquisitionKind_RCA_VLS:
			bp.focal_depths[0:bp.acquisition_count] = parameters.acquisition_parameters['focal_depths'][0:bp.acquisition_count]
			for i in range(bp.acquisition_count):
				origin = -parameters.acquisition_parameters['origin_offsets'][i]
				depth  = bp.focal_depths[i]
				bp.steering_angles[i] = math.asin(origin / depth) * 180 / math.pi


		return bp

	class Parameters:
		@classmethod
		def from_file(cls, file):
			"""
			Unpacks a ZBP header file into a structured format.

			Arguments:
			  file (string): path to parameters file

			Returns:
			  Returns a structure with following fields:
			    raw_data_kind                (uint32)     ZBP.DataKind
			    raw_data_compression_kind    (uint32)     ZBP.DataCompressionKind
			    raw_data_dimension           (uint32 [4]) dimensions of the raw data file (accounts for padding)
			                                              [0]: samples * receive_event_count + padding
			                                              [1]: channel
			                                              [2]: groups
			                                              [3]: ensembles

			    decode_mode                  (uint32)     ZBP.DecodeMode
			    sampling_mode                (uint32)     ZBP.SamplingMode
			    sampling_frequency           (float)      [Hz]
			    demodulation_frequency       (float)      [Hz]
			    speed_of_sound               (float)      [m/s]

			    sample_count                 (uint32)
			    channel_count                (uint32)
			    receive_event_count          (uint32)

			    transducer_transform_matrix  (float [16]) 4x4 Affine Transform for moving from world
			                                              origin to a space oriented with the receiver
			                                              transducer starting at its corner
			    transducer_element_pitch     (float [2])  [m] center to center distance between
			                                              (row, column) elements

			    time_offset                  (float)      [s] time shift to apply to reach time 0

			    group_acquisition_time       (float)      [s] time between each acquisition group
			                                              (if raw_data_dimension[2] > 0)
			    ensemble_repitition_interval (float)      [s] time between ensembles
			                                              (if raw_data_dimension[3] > 0)

			    acquisition_kind             (uint32)     ZBP.AcquisitionKind
			    contrast_mode                (uint32)     ZBP.ContrastMode

			    emission_kinds               (uint32 [])  [ZBP.EmissionKind, ...] one per acquisition group

			    emission_parameters: List of python objects. List[index] depends on emission_kinds[index]:
			      Sine  -> (ZBP.EmissionSineParameters)
			      Chirp -> (ZBP.EmissionChirpParameters)

			    channel_mapping              (int16 [])   Optional, used to remap the data so that
			                                              channel 0 lands on the edge of the array and
			                                              channel channel_count - 1 lands on the other
			                                              end of the array.
			                                              Contains channel_count elements

			    raw_data                     (uint8 [])   Optional, an array of raw data if it was
			                                              included in the file.

			    acquisition_parameters: (dict) fields depend on acquisition_mode:
			      FORCES
			      HERCULES
			        transmit_focus                (ZBP.RCATransmitFocus)
			      UFORCES
			      UHERCULES
			        transmit_focus                (ZBP.RCATransmitFocus)
			        sparse_elements               (int16 [])
			      TPW
			        tilting_angles                (float [])
			        transmit_receive_orientations (uint8 [])
			      VLS
			        focal_depths                  (float [])
			        origin_offsets                (float [])
			        transmit_receive_orientations (uint8 [])

			"""
			result = cls()
			with open(file, "rb") as f:
				bytes = f.read()

			if len(bytes) >= ZBP.BaseHeader.byte_size():
				base = ZBP.BaseHeader.from_bytes(bytes)

			if base != None:
				if base.magic != ZBP.HeaderMagic:
					raise RuntimeError(f"Invalid Header File: {file}")

				major_version_size_table = {
					1: ZBP.HeaderV1.byte_size(),
					2: ZBP.HeaderV2.byte_size(),
				}
				version_size = major_version_size_table.get(base.major, -1)
				if version_size == -1 or len(bytes) < version_size:
					raise RuntimeError(f"Invalid Header File: {file}")

				major_version_conversion_table = {
					1: ZBP.HeaderV1.from_bytes,
					2: ZBP.HeaderV2.from_bytes,
				}
				header = major_version_conversion_table[base.major](bytes)

				if base.major == 1:
					result.raw_data_kind               = ZBP.DataKind_Int16
					result.raw_data_compression_kind   = ZBP.DataCompressionKind_ZSTD
					result.raw_data_dimension          = header.raw_data_dimension
					result.raw_data                    = []

					result.decode_mode                 = header.decode_mode
					result.sampling_mode               = ZBP.SamplingMode_Standard
					result.sampling_frequency          = header.sampling_frequency
					result.demodulation_frequency      = header.demodulation_frequency
					result.speed_of_sound              = header.speed_of_sound

					result.sample_count                = header.sample_count
					result.channel_count               = header.channel_count
					result.receive_event_count         = header.receive_event_count

					result.transducer_transform_matrix = header.transducer_transform_matrix
					result.transducer_element_pitch    = header.transducer_element_pitch

					result.time_offset                 = header.time_offset

					result.acquisition_kind            = header.beamform_mode
					result.contrast_mode               = ZBP.ContrastMode_None

					result.channel_mapping             = header.channel_mapping

					result.emission_kinds      = [ZBP.EmissionKind_Sine]
					result.emission_parameters = [ZBP.EmissionSineParameters()]
					result.emission_parameters[0] .cycles    = 2
					result.emission_parameters[0].frequency = header.sampling_frequency / 4

					transmit_receive_table = {
						0: ZBP.RCAOrientation_Rows    << 4 | ZBP.RCAOrientation_Rows,
						1: ZBP.RCAOrientation_Rows    << 4 | ZBP.RCAOrientation_Columns,
						2: ZBP.RCAOrientation_Columns << 4 | ZBP.RCAOrientation_Rows,
						3: ZBP.RCAOrientation_Columns << 4 | ZBP.RCAOrientation_Columns,
					}
					transmit_receive_orientation = transmit_receive_table.get(header.transmit_mode, -1)
					if transmit_receive_orientation == -1:
						raise ValueError("invalid transmit mode: 0x%02x" % header.transmit_mode)

					result.acquisition_parameters = {}
					acquisition_kind = header.beamform_mode
					if (acquisition_kind == ZBP.AcquisitionKind_FORCES or
					    acquisition_kind == ZBP.AcquisitionKind_HERCULES or
					    acquisition_kind == ZBP.AcquisitionKind_UFORCES or
					    acquisition_kind == ZBP.AcquisitionKind_UHERCULES):
						transmit_focus = ZBP.RCATransmitFocus()
						transmit_focus.focal_depth    = header.focal_depths[0]
						transmit_focus.steering_angle = header.steering_angles[0]
						transmit_focus.origin_offset  = 0
						transmit_focus.transmit_receive_orientation = transmit_receive_orientation
						result.acquisition_parameters['transmit_focus'] = transmit_focus

					if (acquisition_kind == ZBP.AcquisitionKind_UFORCES or
					    acquisition_kind == ZBP.AcquisitionKind_UHERCULES):
						result.acquisition_parameters['sparse_elements'] = header.sparse_elements

					if acquisition_kind == ZBP.AcquisitionKind_RCA_TPW:
						result.acquisition_parameters['tilting_angles'] = header.steering_angles
						result.acquisition_parameters['transmit_receive_orientations'] = []
						for i in range(header.receive_event_count):
							result.acquisition_parameters['transmit_receive_orientations'].append(transmit_receive_orientation)

					if acquisition_kind == ZBP.AcquisitionKind_RCA_VLS:
						result.acquisition_parameters['focal_depths'] = header.focal_depths
						result.acquisition_parameters['transmit_receive_orientations'] = []
						result.acquisition_parameters['origin_offsets']                = []

						for i in range(header.receive_event_count):
							result.acquisition_parameters['origin_offsets'].append(header.focal_depths[i] * math.sin(header.steering_angles[i] * math.pi / 180))
						for i in range(header.receive_event_count):
							result.acquisition_parameters['transmit_receive_orientations'].append(transmit_receive_orientation)

				if base.major == 2:
					result.raw_data_kind                = header.raw_data_kind
					result.raw_data_compression_kind    = header.raw_data_compression_kind
					result.raw_data_dimension           = header.raw_data_dimension

					result.decode_mode                  = header.decode_mode
					result.sampling_mode                = header.sampling_mode
					result.sampling_frequency           = header.sampling_frequency
					result.demodulation_frequency       = header.demodulation_frequency
					result.speed_of_sound               = header.speed_of_sound

					result.sample_count                 = header.sample_count
					result.channel_count                = header.channel_count
					result.receive_event_count          = header.receive_event_count

					result.transducer_transform_matrix  = header.transducer_transform_matrix
					result.transducer_element_pitch     = header.transducer_element_pitch

					result.time_offset                  = header.time_offset
					result.group_acquisition_time       = header.group_acquisition_time
					result.ensemble_repitition_interval = header.ensemble_repitition_interval

					result.acquisition_kind             = header.acquisition_mode
					result.contrast_mode                = header.contrast_mode

					result.channel_mapping = []
					if header.channel_mapping_offset > 0:
						result.channel_mapping = struct.unpack_from('<%dh' % result.channel_count, bytes,
						                                            header.channel_mapping_offset)
					result.emission_kinds      = []
					result.emission_parameters = []
					emission_conversion_table = {
						ZBP.EmissionKind_Sine:  ZBP.EmissionSineParameters.from_bytes,
						ZBP.EmissionKind_Chirp: ZBP.EmissionChirpParameters.from_bytes,
					}
					for i in range(result.raw_data_dimension[2]):
						offset = header.emission_descriptors_offset + i * ZBP.EmissionDescriptor.byte_size()
						emission_descriptor = ZBP.EmissionDescriptor.from_bytes(bytes[offset:])
						result.emission_kinds.append(emission_descriptor.emission_kind)
						parameters = emission_conversion_table.get(emission_descriptor.emission_kind, -1)
						if parameters == -1:
							raise ValueError(f"Invalid Emission Kind {emission_descriptor.emission_kind}")
						result.emission_parameters.append(parameters(bytes[emission_descriptor.parameters_offset:]))

					result.acquisition_parameters = {}
					acquisition_kind = header.acquisition_mode
					acquisition_conversion_table = {
						ZBP.AcquisitionKind_FORCES:    ZBP.FORCESParameters.from_bytes,
						ZBP.AcquisitionKind_HERCULES:  ZBP.HERCULESParameters.from_bytes,
						ZBP.AcquisitionKind_UFORCES:   ZBP.uFORCESParameters.from_bytes,
						ZBP.AcquisitionKind_UHERCULES: ZBP.uHERCULESParameters.from_bytes,
						ZBP.AcquisitionKind_RCA_TPW:   ZBP.TPWParameters.from_bytes,
						ZBP.AcquisitionKind_RCA_VLS:   ZBP.VLSParameters.from_bytes,
					}
					raw_acquisition_parameters = acquisition_conversion_table.get(acquisition_kind, -1)
					if raw_acquisition_parameters != -1:
						raw_acquisition_parameters = raw_acquisition_parameters(bytes[header.acquisition_parameters_offset:])

						if (acquisition_kind == ZBP.AcquisitionKind_FORCES or
						    acquisition_kind == ZBP.AcquisitionKind_HERCULES or
						    acquisition_kind == ZBP.AcquisitionKind_UFORCES or
						    acquisition_kind == ZBP.AcquisitionKind_UHERCULES):
							result.acquisition_parameters['transmit_focus'] = raw_acquisition_parameters.transmit_focus

						if (acquisition_kind == ZBP.AcquisitionKind_UFORCES or
						    acquisition_kind == ZBP.AcquisitionKind_UHERCULES):
							sparse_elements = struct.unpack_from('<%dh' % result.receive_event_count, bytes,
							                                     raw_acquisition_parameters.sparse_elements_offset)
							result.acquisition_parameters['sparse_elements'] = sparse_elements

						if acquisition_kind == ZBP.AcquisitionKind_RCA_TPW:
							tilting_angles = struct.unpack_from('<%df' % result.receive_event_count, bytes,
							                                    raw_acquisition_parameters.tilting_angles_offset)
							result.acquisition_parameters['tilting_angles'] = tilting_angles
							tro_offset = raw_acquisition_parameters.transmit_receive_orientations_offset
							result.acquisition_parameters['transmit_receive_orientations'] = bytes[tro_offset:result.receive_event_count]

						if acquisition_kind == ZBP.AcquisitionKind_RCA_VLS:
							focal_depths = struct.unpack_from('<%df' % result.receive_event_count, bytes,
							                                  raw_acquisition_parameters.focal_depths_offset)
							result.acquisition_parameters['focal_depths'] = focal_depths

							origin_offsets = struct.unpack_from('<%df' % result.receive_event_count, bytes,
							                                    raw_acquisition_parameters.origin_offsets_offset)
							result.acquisition_parameters['origin_offsets'] = origin_offsets

							tro_offset = raw_acquisition_parameters.transmit_receive_orientations_offset
							result.acquisition_parameters['transmit_receive_orientations'] = bytes[tro_offset:result.receive_event_count]

					result.raw_data = []
					if header.raw_data_offset > 0:
						result.raw_data = bytes[header.raw_data_offset:]

				return result
