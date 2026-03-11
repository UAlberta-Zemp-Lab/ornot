# See LICENSE for license details.
import numpy as np
import ornot

from ZBP import ZBP

class BeamformingRuns:
	"""
	A collection of basic beamforming runs.
	"""

	def __init__(self, library_path):
		"""
		Initializes an ImagingRuns instance.

		Arguments:
		  library_path (string): base path containing ornot.so/ornot.dylib/ornot.dll
		                         and ogl_beamformer_lib.so/ogl_beamformer_lib.dll
		                         libraries
		"""
		self.ornot = ornot.ornot(library_path)

	def __fatal(self, message):
		print(message)
		exit(1)

	def __must(self, result):
		ffi = self.ornot.ffi
		ogl = self.ornot.ogl
		if result == 0:
			self.__fatal(ffi.string(ogl.beamformer_get_last_error_string()).decode())

	def single_wire(self, parameters_file, data_file, location_x, location_z, region_width, points, f_number=0.5, timeout_ms=1000, skip_2d=False):
		"""
		Beamform a single point target using offline parameters and data files.

		Arguments:
			parameters_file (string): path to parameters file associated with the data
			data_file       (string): path to data file containing raw data described by parameters
			location_x      (float):  the x location of the wire in meters [m]
			location_z      (float):  the z location of the wire in meters [m]
			region_width    (float):  the width of the region around the wire to beamform
			points          (int):    the number of points to beamform
			f_number        (float):  the dynamic receive F# to use in beamforming
			timeout_ms      (int):    the number of milliseconds to wait for beamforming to complete
			skip_2d         (bool):   wether to include a 2D region around the wire in the output

		Returns:
			An output structure defined as follows:
			output = {
				axial        (complex float []):   Beamformed Axial Point Spread Function
				axial_axis   (float []):           Axis for beamformed points [m]
				lateral      (complex float []):   Beamformed Lateral Point Spread Function
				lateral_axis (float []):           Axis for beamformed points [m]
			Optional:
				image        (complex float [][]): A 2D region around the wire location
				image_extent (float []):           The extents of the region [m]
			}
		"""
		ornot = self.ornot
		ffi   = self.ornot.ffi
		ogl   = self.ornot.ogl

		parameters = ornot.Parameters.from_file(parameters_file)
		bp = ornot.beamformer_simple_parameters_from_parameters(parameters)

		if len(parameters.raw_data) == 0:
			data, data_size = ornot.data_from_file(parameters, data_file)
		else:
			data, data_size = ornot.data_from_raw(parameters, parameters.raw_data)

		bp.interpolation_mode = ogl.BeamformerInterpolationMode_Cubic
		bp.f_number           = f_number

		shaders = [
			ogl.BeamformerShaderKind_Demodulate,
			ogl.BeamformerShaderKind_Decode,
			ogl.BeamformerShaderKind_DAS,
		]
		bp.compute_stages[0:len(shaders)] = shaders
		bp.compute_stages_count           = len(shaders)

		# NOTE: Filter Parameters
		with ffi.new("BeamformerFilterParameters *") as filter:
			filter_slot = 0
			demodulate_shader_index = 0
			# NOTE: bind filter to the parameters of the demodulation shader
			bp.compute_stage_parameters[demodulate_shader_index] = filter_slot

			filter_size = 0
			if parameters.emission_kinds[0] == ZBP.EmissionKind_Sine:
				filter_size = ffi.sizeof(filter.kaiser)
				filter.kind = ogl.BeamformerFilterKind_Kaiser
				filter.kaiser.cutoff_frequency = 0.5 * parameters.emission_parameters[0].frequency
				filter.kaiser.beta             = 5.65
				filter.kaiser.length           = 36

			if parameters.emission_kinds[0] == ZBP.EmissionKind_Chirp:
				filter_size    = ffi.sizeof(filter.matched_chirp)
				filter.kind    = ogl.BeamformerFilterKind_MatchedChirp
				filter.complex = 1
				filter.matched_chirp.duration      = parameters.emission_parameters[0].duration
				filter.matched_chirp.min_frequency = parameters.emission_parameters[0].min_frequency - bp.demodulation_frequency
				filter.matched_chirp.max_frequency = parameters.emission_parameters[0].max_frequency - bp.demodulation_frequency

			filter.sampling_frequency = bp.sampling_frequency / 2
			self.__must(ogl.beamformer_create_filter(filter.kind, ffi.addressof(filter, "kaiser"), filter_size,
			                                         filter.sampling_frequency, filter.complex, filter_slot, 0))

		output = {}
		output_count = points * 2 # complex output

		# NOTE: axial image
		axial_data = ffi.new("float []", output_count)
		bp.output_points[0] = points
		bp.das_voxel_transform = ornot.Affine.Line(location_x, 0, location_z - region_width / 2,
		                                           location_x, 0, location_z + region_width / 2)

		self.__must(ogl.beamformer_beamform_data(bp, data, data_size, axial_data, timeout_ms))
		axial = np.frombuffer(ffi.buffer(axial_data), dtype=np.complex64)

		output['axial']      = axial
		output['axial_axis'] = np.linspace(location_z - region_width / 2, location_z + region_width / 2, points)

		# NOTE: lateral image
		lateral_data = ffi.new("float []", output_count)
		bp.output_points[0] = points
		bp.das_voxel_transform = ornot.Affine.Line(location_x - region_width / 2, 0, location_z,
		                                           location_x + region_width / 2, 0, location_z)

		self.__must(ogl.beamformer_beamform_data(bp, data, data_size, lateral_data, timeout_ms))
		lateral = np.frombuffer(ffi.buffer(lateral_data), dtype=np.complex64)

		output['lateral']      = lateral
		output['lateral_axis'] = np.linspace(location_x - region_width / 2, location_x + region_width / 2, points)

		if not skip_2d:
			output_2d_points = [256, 256]
			output_count     = output_2d_points[0] * output_2d_points[1] * 2
			output_data      = ffi.new("float []", output_count)
			bp.output_points[0] = output_2d_points[0]
			bp.output_points[1] = output_2d_points[1]
			bp.das_voxel_transform = ornot.Affine.XZ(location_x - region_width / 2, location_z - region_width / 2,
			                                         location_x + region_width / 2, location_z + region_width / 2, 0)

			extent = np.array([
				location_x - region_width / 2,
				location_x + region_width / 2,
				location_z + region_width / 2,
				location_z - region_width / 2,
			])

			self.__must(ogl.beamformer_beamform_data(bp, data, data_size, output_data, timeout_ms))
			image = np.frombuffer(ffi.buffer(output_data), dtype=np.complex64)
			image = image.reshape(output_2d_points, order="F").T.squeeze()
			output['image']        = image
			output['image_extent'] = extent

		return output
