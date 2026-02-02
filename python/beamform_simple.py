import numpy as np
import matplotlib
import matplotlib.pyplot as plt

from ornot import ornot

library_path = '..'
params_file = 'params.bp'
data_file   = 'data.zst'

lateral_extent = [-30e-3, 30e-3]
axial_extent   = [5e-3,   120e-3]
output_points  = [512, 1024]
f_number       = 0.5

timeout_ms     = 10 * 1000

display_power_threshold = 78

##
## PARAMETER SETUP
##
ornot = ornot(library_path)
ogl   = ornot.ogl
ffi   = ornot.ffi

zbp, bytes = ornot.zbp_from_file(params_file)
bp         = ornot.beamformer_simple_parameters_from_zbp(zbp)

data, data_size = ornot.data_from_file(zbp, data_file)

bp.f_number = f_number

shaders = [
	ogl.BeamformerShaderKind_Demodulate,
	ogl.BeamformerShaderKind_Decode,
	ogl.BeamformerShaderKind_DAS,
];
bp.compute_stages[0:len(shaders)] = shaders
bp.compute_stages_count           = len(shaders)

def fatal(message):
	print(message)
	exit(1)

def must(result):
	if result == 0:
		fatal(ffi.string(ogl.beamformer_get_last_error_string()).decode())

# NOTE: Filter Parameters
with ffi.new("BeamformerFilterParameters *") as filter:
	filter_slot = 0
	demodulate_shader_index = 0
	# NOTE: bind filter to the parameters of the demodulation shader
	bp.compute_stage_parameters[demodulate_shader_index] = filter_slot

	filter.kind = ogl.BeamformerFilterKind_Kaiser
	filter.kaiser.cutoff_frequency = 1.8e6
	filter.kaiser.beta             = 5.65
	filter.kaiser.length           = 36

	# filter.kind = ogl.BeamformerFilterKind_Chirp
	# filter.chirp.duration      = 18e-6
	# NOTE: you may want to choose something better (ZBP V2 will store the correct values)
	# filter.chirp.min_frequency = bp.demodulation_frequency - bp.demodulation_frequency / 2
	# filter.chirp.max_frequency = bp.demodulation_frequency + bp.demodulation_frequency / 2
	# filter.complex             = 1

	filter.sampling_frequency = bp.sampling_frequency / 2

	must(ogl.beamformer_create_filter(filter.kind, ffi.addressof(filter, "kaiser"), ffi.sizeof(filter.kaiser),
	                                  filter.sampling_frequency, filter.complex, filter_slot, 0))

##
## BEAMFORMING
##

points = output_points[0] * output_points[1]
output_count = points * 2 # complex output
output_data = ffi.new("float []", output_count)

bp.output_points[0] = output_points[0]
bp.output_points[2] = output_points[1]
bp.output_min_coordinate[0] = lateral_extent[0]
bp.output_min_coordinate[1] = 0
bp.output_min_coordinate[2] = axial_extent[0]
bp.output_max_coordinate[0] = lateral_extent[1]
bp.output_max_coordinate[1] = 0
bp.output_max_coordinate[2] = axial_extent[1]

must(ogl.beamformer_beamform_data(bp, data, data_size, output_data, timeout_ms))

output = np.frombuffer(ffi.buffer(output_data), dtype=np.complex64)
threshold_value = np.pow(10.0, display_power_threshold / 20.0)
output = np.maximum(0, np.minimum(np.abs(output), threshold_value))
output = output / threshold_value

output = output.reshape(output_points, order="F").T.squeeze()

##
## PLOTTING
##

extent = 1e3 * np.array([
	bp.output_min_coordinate[0],
	bp.output_max_coordinate[0],
	bp.output_min_coordinate[2],
	bp.output_max_coordinate[2],
])

fig, ax = plt.subplots(1, 1, figsize=(10, 5))
ax.imshow(output, extent=extent, cmap='gray')
ax.set_ylabel("Z [mm]")
ax.set_xlabel("X [mm]")

plt.show()

