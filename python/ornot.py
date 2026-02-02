import os
import cffi

from sys import platform

from ZBP import ZBP

class ornot:
	def __init__(self, library_path):
		self.ffi = cffi.FFI()
		self.ffi.cdef(open('ogl_beamformer_lib_python_ffi.h').read())
		self.ffi.cdef(open('ornot_python_ffi.h').read())

		ornot_name = ""
		ogl_name   = ""
		if platform == "linux" or platform == "linux2":
			ornot_name = "ornot.so"
			ogl_name   = "ogl_beamformer_lib.so"
		elif platform == "darwin":
			ornot_name = "ornot.so"
		elif platform == "win32":
			ornot_name = "ornot.dll"
			ogl_name   = "ogl_beamformer_lib.dll"

		self.ornot = self.ffi.dlopen(os.path.join(library_path, ornot_name))
		if platform != "darwin":
			self.ogl = self.ffi.dlopen(os.path.join(library_path, ogl_name))

	@staticmethod
	def zbp_from_file(file):
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
			zbp = major_version_conversion_table[base.major](bytes)
			if zbp.version == 1: zbp.raw_data_kind = ZBP.DataKind_Int16

			return zbp, bytes

	def data_from_file(self, zbp, file):
		ogl = self.ogl
		data_kind_size_table = {
			ZBP.DataKind_Int16:          2,
			ZBP.DataKind_Int16Complex:   4,
			ZBP.DataKind_Float32:        4,
			ZBP.DataKind_Float32Complex: 8,
			ZBP.DataKind_Float16:        2,
			ZBP.DataKind_Float16Complex: 4,
		}
		data_kind_size = data_kind_size_table.get(zbp.raw_data_kind, -1)
		if data_kind_size == -1:
			raise ValueError(f"Invalid Data Kind {zbp.raw_data_kind}")

		data_points = zbp.raw_data_dimension[0] * zbp.raw_data_dimension[1] * zbp.raw_data_dimension[2] * zbp.raw_data_dimension[3]
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

		data = self.ffi.new(data_kind_ffi_kind[zbp.raw_data_kind], data_points)
		if self.ornot.unpack_zstd_compressed_data(self.ffi.from_buffer(file.encode()), data, data_size) == 0:
			raise RuntimeError(f"Invalid Header File: {file}")

		return data, data_size

	def beamformer_simple_parameters_from_zbp(self, zbp):
		if zbp.version != 1:
			raise ValueError("Only Vesion 1 Parameters Supported")

		ogl = self.ogl

		bp = self.ffi.new("BeamformerSimpleParameters *")
		bp.decode_mode            = zbp.decode_mode
		bp.acquisition_kind       = zbp.beamform_mode
		bp.time_offset            = zbp.time_offset
		bp.sampling_frequency     = zbp.sampling_frequency
		bp.demodulation_frequency = zbp.demodulation_frequency
		bp.speed_of_sound         = zbp.speed_of_sound
		bp.xdc_transform          = zbp.transducer_transform_matrix
		bp.xdc_element_pitch      = zbp.transducer_element_pitch
		bp.raw_data_dimensions    = zbp.raw_data_dimension[0:2]
		bp.data_kind              = zbp.raw_data_kind
		bp.interpolation_mode     = ogl.BeamformerInterpolationMode_Cubic


		# NOTE: v1 data was always collected at 4X sampling, but most
		# parameters had the wrong value saved for demodulation frequency
		bp.sampling_mode          = ogl.BeamformerSamplingMode_4X
		bp.demodulation_frequency = bp.sampling_frequency / 4

		transmit_receive_table = {
			0: ogl.BeamformerRCAOrientation_Rows    << 4 | ogl.BeamformerRCAOrientation_Rows,
			1: ogl.BeamformerRCAOrientation_Rows    << 4 | ogl.BeamformerRCAOrientation_Columns,
			2: ogl.BeamformerRCAOrientation_Columns << 4 | ogl.BeamformerRCAOrientation_Rows,
			3: ogl.BeamformerRCAOrientation_Columns << 4 | ogl.BeamformerRCAOrientation_Columns,
		}
		transmit_receive_orientation = transmit_receive_table.get(zbp.transmit_mode, -1)
		if transmit_receive_orientation == -1: fatal("unhandled transmit mode: 0x%02x" % zbp.transmit_mode)

		bp.sample_count      = zbp.sample_count
		bp.channel_count     = zbp.channel_count
		bp.acquisition_count = zbp.receive_event_count

		bp.channel_mapping[1:bp.channel_count]     = zbp.channel_mapping[1:bp.channel_count]
		bp.sparse_elements[1:bp.acquisition_count] = zbp.sparse_elements[1:bp.acquisition_count]

		if bp.acquisition_kind == ogl.BeamformerAcquisitionKind_HERCULES or bp.acquisition_kind == ogl.BeamformerAcquisitionKind_UHERCULES:
			bp.single_focus       = 1;
			bp.single_orientation = 1;
			bp.transmit_receive_orientation = transmit_receive_orientation;
			bp.focal_vector[0] = zbp.steering_angles[0]
			bp.focal_vector[1] = zbp.focal_depths[0]
		else:
			for i in range(bp.acquisition_count):
				bp.transmit_receive_orientations[i] = transmit_receive_orientation
			bp.steering_angles[0:bp.acquisition_count] = zbp.steering_angles[0:bp.acquisition_count]
			bp.focal_depths[0:bp.acquisition_count]    = zbp.focal_depths[0:bp.acquisition_count]

		return bp
