# See LICENSE for license details.

# GENERATED CODE
import struct

class ZBP:
	HeaderMagic = 0x5042504d455afeca

	# RCAOrientation
	RCAOrientation_None    = 0
	RCAOrientation_Rows    = 1
	RCAOrientation_Columns = 2

	# DecodeMode
	DecodeMode_None     = 0
	DecodeMode_Hadamard = 1
	DecodeMode_Walsh    = 2

	# SamplingMode
	SamplingMode_Standard = 0
	SamplingMode_Bandpass = 1

	# AcquisitionKind
	AcquisitionKind_FORCES         = 0
	AcquisitionKind_UFORCES        = 1
	AcquisitionKind_HERCULES       = 2
	AcquisitionKind_RCA_VLS        = 3
	AcquisitionKind_RCA_TPW        = 4
	AcquisitionKind_UHERCULES      = 5
	AcquisitionKind_RACES          = 6
	AcquisitionKind_EPIC_FORCES    = 7
	AcquisitionKind_EPIC_UFORCES   = 8
	AcquisitionKind_EPIC_UHERCULES = 9
	AcquisitionKind_Flash          = 10
	AcquisitionKind_HERO_PA        = 11

	# ContrastMode
	ContrastMode_None = 0

	# EmissionKind
	EmissionKind_Sine  = 0
	EmissionKind_Chirp = 1

	# DataKind
	DataKind_Int16          = 0
	DataKind_Int16Complex   = 1
	DataKind_Float32        = 2
	DataKind_Float32Complex = 3
	DataKind_Float16        = 4
	DataKind_Float16Complex = 5

	# DataCompressionKind
	DataCompressionKind_None = 0
	DataCompressionKind_ZSTD = 1

	class BaseHeader:
		@classmethod
		def from_bytes(cls, bytes):
			result = cls()
			result.magic  = struct.unpack_from('<1Q', bytes, 0)[0]
			result.major  = struct.unpack_from('<1L', bytes, 8)[0]
			result.minor  = struct.unpack_from('<1L', bytes, 12)[0]
			return result

		@staticmethod
		def byte_size():
			return 16

	class HeaderV1:
		@classmethod
		def from_bytes(cls, bytes):
			result = cls()
			result.magic                        = struct.unpack_from('<1Q',   bytes, 0)[0]
			result.version                      = struct.unpack_from('<1L',   bytes, 8)[0]
			result.decode_mode                  = struct.unpack_from('<1h',   bytes, 12)[0]
			result.beamform_mode                = struct.unpack_from('<1h',   bytes, 14)[0]
			result.raw_data_dimension           = struct.unpack_from('<4L',   bytes, 16)
			result.sample_count                 = struct.unpack_from('<1L',   bytes, 32)[0]
			result.channel_count                = struct.unpack_from('<1L',   bytes, 36)[0]
			result.receive_event_count          = struct.unpack_from('<1L',   bytes, 40)[0]
			result.frame_count                  = struct.unpack_from('<1L',   bytes, 44)[0]
			result.transducer_element_pitch     = struct.unpack_from('<2f',   bytes, 48)
			result.transducer_transform_matrix  = struct.unpack_from('<16f',  bytes, 56)
			result.channel_mapping              = struct.unpack_from('<256h', bytes, 120)
			result.steering_angles              = struct.unpack_from('<256f', bytes, 632)
			result.focal_depths                 = struct.unpack_from('<256f', bytes, 1656)
			result.sparse_elements              = struct.unpack_from('<256h', bytes, 2680)
			result.hadamard_rows                = struct.unpack_from('<256h', bytes, 3192)
			result.speed_of_sound               = struct.unpack_from('<1f',   bytes, 3704)[0]
			result.demodulation_frequency       = struct.unpack_from('<1f',   bytes, 3708)[0]
			result.sampling_frequency           = struct.unpack_from('<1f',   bytes, 3712)[0]
			result.time_offset                  = struct.unpack_from('<1f',   bytes, 3716)[0]
			result.transmit_mode                = struct.unpack_from('<1L',   bytes, 3720)[0]
			return result

		@staticmethod
		def byte_size():
			return 3724

	class HeaderV2:
		@classmethod
		def from_bytes(cls, bytes):
			result = cls()
			result.magic                          = struct.unpack_from('<1Q',  bytes, 0)[0]
			result.major                          = struct.unpack_from('<1L',  bytes, 8)[0]
			result.minor                          = struct.unpack_from('<1L',  bytes, 12)[0]
			result.raw_data_dimension             = struct.unpack_from('<4L',  bytes, 16)
			result.raw_data_kind                  = struct.unpack_from('<1l',  bytes, 32)[0]
			result.raw_data_offset                = struct.unpack_from('<1l',  bytes, 36)[0]
			result.raw_data_compression_kind      = struct.unpack_from('<1l',  bytes, 40)[0]
			result.decode_mode                    = struct.unpack_from('<1l',  bytes, 44)[0]
			result.sampling_mode                  = struct.unpack_from('<1l',  bytes, 48)[0]
			result.sampling_frequency             = struct.unpack_from('<1f',  bytes, 52)[0]
			result.demodulation_frequency         = struct.unpack_from('<1f',  bytes, 56)[0]
			result.speed_of_sound                 = struct.unpack_from('<1f',  bytes, 60)[0]
			result.channel_mapping_offset         = struct.unpack_from('<1l',  bytes, 64)[0]
			result.sample_count                   = struct.unpack_from('<1L',  bytes, 68)[0]
			result.channel_count                  = struct.unpack_from('<1L',  bytes, 72)[0]
			result.receive_event_count            = struct.unpack_from('<1L',  bytes, 76)[0]
			result.transducer_transform_matrix    = struct.unpack_from('<16f', bytes, 80)
			result.transducer_element_pitch       = struct.unpack_from('<2f',  bytes, 144)
			result.time_offset                    = struct.unpack_from('<1f',  bytes, 152)[0]
			result.group_acquisition_time         = struct.unpack_from('<1f',  bytes, 156)[0]
			result.ensemble_repitition_interval   = struct.unpack_from('<1f',  bytes, 160)[0]
			result.acquisition_mode               = struct.unpack_from('<1l',  bytes, 164)[0]
			result.acquisition_parameters_offset  = struct.unpack_from('<1l',  bytes, 168)[0]
			result.contrast_mode                  = struct.unpack_from('<1l',  bytes, 172)[0]
			result.contrast_parameters_offset     = struct.unpack_from('<1l',  bytes, 176)[0]
			result.emission_descriptors_offset    = struct.unpack_from('<1l',  bytes, 180)[0]
			return result

		@staticmethod
		def byte_size():
			return 184

	class EmissionDescriptor:
		@classmethod
		def from_bytes(cls, bytes):
			result = cls()
			result.emission_kind      = struct.unpack_from('<1l', bytes, 0)[0]
			result.parameters_offset  = struct.unpack_from('<1l', bytes, 4)[0]
			return result

		@staticmethod
		def byte_size():
			return 8

	class EmissionSineParameters:
		@classmethod
		def from_bytes(cls, bytes):
			result = cls()
			result.cycles     = struct.unpack_from('<1f', bytes, 0)[0]
			result.frequency  = struct.unpack_from('<1f', bytes, 4)[0]
			return result

		@staticmethod
		def byte_size():
			return 8

	class EmissionChirpParameters:
		@classmethod
		def from_bytes(cls, bytes):
			result = cls()
			result.duration       = struct.unpack_from('<1f', bytes, 0)[0]
			result.min_frequency  = struct.unpack_from('<1f', bytes, 4)[0]
			result.max_frequency  = struct.unpack_from('<1f', bytes, 8)[0]
			return result

		@staticmethod
		def byte_size():
			return 12

	class RCATransmitFocus:
		@classmethod
		def from_bytes(cls, bytes):
			result = cls()
			result.focal_depth                   = struct.unpack_from('<1f', bytes, 0)[0]
			result.steering_angle                = struct.unpack_from('<1f', bytes, 4)[0]
			result.origin_offset                 = struct.unpack_from('<1f', bytes, 8)[0]
			result.transmit_receive_orientation  = struct.unpack_from('<1L', bytes, 12)[0]
			return result

		@staticmethod
		def byte_size():
			return 16

	class FORCESParameters:
		@classmethod
		def from_bytes(cls, bytes):
			result = cls()
			result.transmit_focus  = ZBP.RCATransmitFocus.from_bytes( bytes[0:])
			return result

		@staticmethod
		def byte_size():
			return 16

	class uFORCESParameters:
		@classmethod
		def from_bytes(cls, bytes):
			result = cls()
			result.transmit_focus          = ZBP.RCATransmitFocus.from_bytes( bytes[0:])
			result.sparse_elements_offset  = struct.unpack_from('<1l',        bytes, 16)[0]
			return result

		@staticmethod
		def byte_size():
			return 20

	class HERCULESParameters:
		@classmethod
		def from_bytes(cls, bytes):
			result = cls()
			result.transmit_focus  = ZBP.RCATransmitFocus.from_bytes( bytes[0:])
			return result

		@staticmethod
		def byte_size():
			return 16

	class uHERCULESParameters:
		@classmethod
		def from_bytes(cls, bytes):
			result = cls()
			result.transmit_focus          = ZBP.RCATransmitFocus.from_bytes( bytes[0:])
			result.sparse_elements_offset  = struct.unpack_from('<1l',        bytes, 16)[0]
			return result

		@staticmethod
		def byte_size():
			return 20

	class TPWParameters:
		@classmethod
		def from_bytes(cls, bytes):
			result = cls()
			result.tilting_angles_offset                 = struct.unpack_from('<1l', bytes, 0)[0]
			result.transmit_receive_orientations_offset  = struct.unpack_from('<1l', bytes, 4)[0]
			return result

		@staticmethod
		def byte_size():
			return 8

	class VLSParameters:
		@classmethod
		def from_bytes(cls, bytes):
			result = cls()
			result.focal_depths_offset                   = struct.unpack_from('<1l', bytes, 0)[0]
			result.origin_offsets_offset                 = struct.unpack_from('<1l', bytes, 4)[0]
			result.transmit_receive_orientations_offset  = struct.unpack_from('<1l', bytes, 8)[0]
			return result

		@staticmethod
		def byte_size():
			return 12
