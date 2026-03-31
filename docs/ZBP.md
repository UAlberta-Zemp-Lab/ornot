# ZBP Metadata Files

When ultrasound data is acquired and saved using any our imaging
software all metadata required to reconstruct an image is stored
in a binary `.bp` file. This document aims to describe the format
in detail. Should this file be out of date the [C header][] is the
final source of truth.

The binary format described here is defined in Little Endian byte
order. No support is provided for reading or writing these files
from a Big Endian host. A parameter file is considered invalid if
it is not in Little Endian byte order.

## Constants

### Header Magic

[Magic value][] put in the first 8 bytes of a binary parameter file.

### Offset Alignment

The minimum alignment required for any substructure located in the
binary parameter file.

## Enumerations

### Acquisition Kind

```c
typedef enum {
	ZBP_AcquisitionKind_FORCES         = 0,
	ZBP_AcquisitionKind_UFORCES        = 1,
	ZBP_AcquisitionKind_HERCULES       = 2,
	ZBP_AcquisitionKind_RCA_VLS        = 3,
	ZBP_AcquisitionKind_RCA_TPW        = 4,
	ZBP_AcquisitionKind_UHERCULES      = 5,
	ZBP_AcquisitionKind_RACES          = 6,
	ZBP_AcquisitionKind_EPIC_FORCES    = 7,
	ZBP_AcquisitionKind_EPIC_UFORCES   = 8,
	ZBP_AcquisitionKind_EPIC_UHERCULES = 9,
	ZBP_AcquisitionKind_Flash          = 10,
	ZBP_AcquisitionKind_HERO_PA        = 11,
	ZBP_AcquisitionKind_Count,
} ZBP_AcquisitionKind;
```

Encodes the imaging method used to acquire the data.

### Contrast Mode

```c
typedef enum {
	ZBP_ContrastMode_None = 0,
	ZBP_ContrastMode_Count,
} ZBP_ContrastMode;
```

A placeholder for encoding whether the data contains method of
providing non-linear contrast. Note that some contrast enhancing
methods can be handled directly in the acquisition hardware
meaning that from a saved data or beamforming perspective the data
does not have a contrast mode applied. In that case `None` is also
used since these files are only meant to encode data needed for
image reconstruction.

### Data Kind

```c
typedef enum {
	ZBP_DataKind_Int16          = 0,
	ZBP_DataKind_Int16Complex   = 1,
	ZBP_DataKind_Float32        = 2,
	ZBP_DataKind_Float32Complex = 3,
	ZBP_DataKind_Float16        = 4,
	ZBP_DataKind_Float16Complex = 5,
	ZBP_DataKind_Count,
} ZBP_DataKind;
```

Encodes the underlying data type of the dataset associated with
the parameter file. The Complex kinds should only be used when the
data set contains interleaved complex samples. In this case the
samples may already be in baseband (IQ samples) or they may be
complex RF samples (dataset had a 'hilbert' transform, in the
MATLAB sense, applied).

### Data Compression Kind

```c
typedef enum {
	ZBP_DataCompressionKind_None = 0,
	ZBP_DataCompressionKind_ZSTD = 1,
	ZBP_DataCompressionKind_Count,
} ZBP_DataCompressionKind;
```

Encodes the compression method used when storing the dataset
associated with the parameter file.

### Decode Mode

```c
typedef enum {
	ZBP_DecodeMode_None     = 0,
	ZBP_DecodeMode_Hadamard = 1,
	ZBP_DecodeMode_Walsh    = 2,
	ZBP_DecodeMode_Count,
} ZBP_DecodeMode;
```

Encodes the method used to generate the bias pattern used for a
bias sensitive modality (FORCES, HERCULES, etc.).

### Emission Kind

```c
typedef enum {
	ZBP_EmissionKind_Sine  = 0,
	ZBP_EmissionKind_Chirp = 1,
	ZBP_EmissionKind_Count,
} ZBP_EmissionKind;
```

Encodes the kind of wave emitted to acquire the data associated
with the parameter file.

### RCA Orientation
```c
typedef enum {
	ZBP_RCAOrientation_None    = 0,
	ZBP_RCAOrientation_Rows    = 1,
	ZBP_RCAOrientation_Columns = 2,
	ZBP_RCAOrientation_Count,
} ZBP_RCAOrientation;
```

Encodes the direction that the Row-Column Array transmitted or
received on. The `None` orientation is used when the modality does
not include a transmission, for example when a laser is used to
generate a photo-acoustic emission.

### Sampling Mode

```c
typedef enum {
	ZBP_SamplingMode_Standard = 0,
	ZBP_SamplingMode_Bandpass = 1,
	ZBP_SamplingMode_Count,
} ZBP_SamplingMode;
```

Encodes the sampling method used in the saved data.
* `Standard`: data was sampled at 4x the demodulation frequency.
* `Bandpass`: data was sampled at 2x or 1x the demodulation frequency
  (where 2x and 1x are equivalent for beamforming).

## Structures

### Base Header

```c
typedef struct ZBP_BaseHeader {
	uint64_t magic;
	uint32_t major;
	uint32_t minor;
} ZBP_BaseHeader;
```

A helper structure for quickly determining how to process the
header. The `minor` field is not present in a Version 1 (`major ==
1`) parameters file and should be ignored. Field descriptions
follows.

#### `magic`

File magic value for detecting if the file you loaded looks like a
binary parameters file following the format described here. Should
match the [Header Magic](#header-magic) constant.

#### `major`

The major version of the parameters file. The following are
classified as major revisions:

* Addition or removal of a member of an existing structure.
* Reordering the members of an existing structure.
* Resizing the members of an existing structure.
* Changing the semantic meaning of the members of an existing structure.

#### `minor`

The minor (revision) version of the parameters file. The following
are classified as minor revisions:

* Addition of a value to an existing enumeration.
* Addition of a parameters struct for a newly added enumeration member.
* Addition of meaning to the padding bits of a existing structure.

Code should be written to have a catch all case for loading a
parameters file with a minor version mismatch. It should not be
written to error on a minor version mismatch. The minor stored in
the parameters file may be higher than what the code was
originally written to handle but the file may not use any of the
additions to that minor revision.

### Header Version 2

```c
typedef struct ZBP_HeaderV2 {
	uint64_t magic;
	uint32_t major;
	uint32_t minor;
	uint32_t raw_data_dimension[4];
	int32_t  raw_data_kind;
	int32_t  raw_data_offset;
	int32_t  raw_data_compression_kind;
	int32_t  decode_mode;
	int32_t  sampling_mode;
	float    sampling_frequency;
	float    demodulation_frequency;
	float    speed_of_sound;
	int32_t  channel_mapping_offset;
	uint32_t sample_count;
	uint32_t channel_count;
	uint32_t receive_event_count;
	float    transducer_transform_matrix[16];
	float    transducer_element_pitch[2];
	float    time_offset;
	float    group_acquisition_time;
	float    ensemble_repitition_interval;
	int32_t  acquisition_mode;
	int32_t  acquisition_parameters_offset;
	int32_t  contrast_mode;
	int32_t  contrast_parameters_offset;
	int32_t  emission_descriptors_offset;
} ZBP_HeaderV2;
```

Base structure defining the layout of Version 2 of the binary
parameters file. All `*_offset` parameters represent an offset
from the start of the file. An offset of -1 indicates that the
corresponding data is not included in the file. A description of
each field follows.

#### `magic`, `major`, `minor`

See [Base Header](#base-header).

#### `raw_data_dimension`

The dimensions of the raw data associated with this parameters
file. These dimensions may contain padding elements.

* `[0]`: Receive Events * Samples Per Event + Padding.
* `[1]`: Data Channels.
* `[2]`: Data Frames.
* `[3]`: Ensembles (collections of Data Frames).

#### `raw_data_kind`

A [Data Kind](#data-kind) describing the interpretation of the
binary data associated with this parameters file.

#### `raw_data_offset` (Optional)

An offset from the start of the file to an attached raw data blob.

#### `raw_data_compression_kind`

A [Data Compression Kind](#data-compression-kind) describing the
interpretation of the binary data associated with this parameters
file.

#### `decode_mode`

A [Decode Mode](#decode-mode) describing the way the binary data
associated with this parameters file should be decoded.

#### `sampling_mode`

A [Sampling Mode](#sampling-mode) describing the way the binary
data associated with this parameters file was sampled.

#### `sampling_frequency` [Hz]

The sampling rate in Hz that the binary data associated with this
parameters file was captured at.

#### `demodulation_frequency` [Hz]

The demodulation frequency in Hz that the binary data associated
with this parameters file should be processed with. If the [Data
Kind](#data-kind) is Complex and this frequency is non-zero the
data is assumed to be at baseband. If the [Data Kind](#data-kind)
is Complex and this frequency is 0 then it is assumed the data is
Complex RF data and it should be processed as RF data.

#### `speed_of_sound` [m/s]

The suspected speed of sound in m/s at which to process the binary
data associated with this parameters file.

#### `channel_mapping_offset` (Optional)

An offset to an array of `int16_t` integers representing the
channel mapping which should be applied to the binary data
associated with this parameters file. If it is not present it is
assumed that the channels are already sorted. The length of the
mapping is provided by the [`channel_count`](#channel_count).

#### `sample_count`

The number of samples in the binary data associated with this
parameters file.

#### `channel_count`

The number of receive channels in the binary data associated with
this parameters file. It may mismatch the Data Channels in the
[`raw_data_dimension`](#raw_data_dimension) in which case the
channel mapping must be used to determine which channels are
non-zero.

#### `receive_event_count`

The number of receive events in the binary data associated with
this parameters file.

#### `transducer_transform_matrix`

A $4 \times 4$ affine transformation from the transmit origin to
the corner of the array used to receive binary data associated
with this parameters file. A $4 \times 4$ allows for any arbitrary
offset and tilt to applied to the receiver array.

#### `transducer_element_pitch` [m]

The (row, column) element pitch in meters.

#### `time_offset` [s]

The time in seconds at which the center of the emission pulse is
at the surface of the transmitting array. This value should be
added to any calculated time of flight during beamforming.
Generally, this value is negative but that is not required.

#### `group_acquisition_time` [s]

The amount of time in seconds taken to acquire a single
[Data Frame](#raw_data_dimension).

#### `ensemble_repitition_interval` [s]

The amount of time in seconds between [Ensembles](#raw_data_dimension).

#### `acquisition_mode`

An [Acquistion Kind](#acquistion-kind) describing the way the
binary data associated with this parameters file should be
processed as well as the how to interpret the
[acquisition parameters](#acquisition_parameters_offset)
contained in parameters file.

#### `acquisition_parameters_offset`

A offset to an array of acquisition parameters structures the type
of which are determined by the
[`acquistion_mode`](#acquistion-mode). The length of this array is
given by the count of [Data Frames](#raw_data_dimension). This
offset is required to always be valid.

#### `contrast_mode`

A [Contrast Mode](#contrast-mode) describing the way the binary
data associated with this parameters file should be processed as
well as the how to interpret the
[constrast parameters](#contrast_parameters_offset-optional)
contained in parameters file.

#### `contrast_parameters_offset` (Optional)

An offset to an contrast parameters structure the type of which is
determined by the [`contrast_mode`](#contrast_mode). If the mode
is `None` this offset can be -1.

#### `emission_descriptors_offset`

An offset to an array of [Emission Descriptor](#emission-descriptor)
structures. The number of emission descriptors present is
determined by the number of [Data Frames](#raw_data_dimension)
present. This offset is required to always be valid.

### Emission Descriptor

```c
typedef struct ZBP_EmissionDescriptor {
	int32_t emission_kind;
	int32_t parameters_offset;
} ZBP_EmissionDescriptor;
```

A structure describing the emission used to acquire a single group
in the binary file associated with this parameters file.

#### `emission_kind`

A [Emission Kind](#emission-kind) describing the way the binary
data associated with this parameters file should be processed as
well as the how to interpret the [emission parameters](#parameters_offset)
contained in parameters file.

#### `parameters_offset`

An offset to a emission parameters structure they type of which is
determined by the [Emission Kind](#emission-kind). This offset is
required to always be valid.

### Sine Emission Parameters

```c
typedef struct ZBP_EmissionSineParameters {
	float cycles;
	float frequency;
} ZBP_EmissionSineParameters;
```

A structure describing the parameters relevant to a sine wave
emission.

#### `cycles`

The number of cycles present in the emission.

#### `frequency` [Hz]

The center frequency in Hz of the emission.

### Chirp Emission Parameters

```c
typedef struct ZBP_EmissionChirpParameters {
	float duration;
	float min_frequency;
	float max_frequency;
} ZBP_EmissionChirpParameters;
```

A structure describing the parameters relevant to an RF chirp
emission.

#### `duration` [s]

The duration of the chirp in seconds.

#### `min_frequency` [Hz]

The starting frequency of the chirp in Hz.

#### `max_frequency`

The ending frequency of the chirp in Hz.

### RCA Transmit Focus

```c
typedef struct ZBP_RCATransmitFocus {
	float    focal_depth;
	float    steering_angle;
	float    origin_offset;
	uint32_t transmit_receive_orientation;
} ZBP_RCATransmitFocus;
```

A structure describing a single transmit focus location.

#### `focal_depth` [m]

The focal depth of a emission in meters. May be negative for a
diverging emission and may be infinite for a plane wave emission.

#### `steering_angle` [degrees]

The steering angle of the emission relative to the Z axis.

#### `origin_offset` [m]

The offset from the world origin to origin of the emission in
meters. Primarily useful for focused emissions.

#### `transmit_receive_orientation`

A field encoding the orientation of both the transmit and the
receive phase of an emission. Bits 0-3 contain the Recieve
Orientation. Bits 4-7 contain the Transmit Orientation. The value
of each 4 bit number corresponds to a [RCA Orientation](#rca-orientation).
The upper 24 bits are currently unused padding bits.

### FORCES Parameters

```c
typedef struct ZBP_FORCESParameters {
	ZBP_RCATransmitFocus transmit_focus;
} ZBP_FORCESParameters;
```

A structure containing the aqcuisition parameters when the
[`acquisition_mode`](#acquisition_mode) is
[FORCES](#acquisition-kind).

#### `transmit_focus`

A [RCA Transmit Focus](#rca-transmit-focus).

### uFORCES Parameters

```c
typedef struct ZBP_uFORCESParameters {
	ZBP_RCATransmitFocus transmit_focus;
	int32_t              sparse_elements_offset;
} ZBP_uFORCESParameters;
```

A structure containing the aqcuisition parameters when the
[`acquisition_mode`](#acquisition_mode) is
[uFORCES](#acquisition-kind).

#### `transmit_focus`

A [RCA Transmit Focus](#rca-transmit-focus).

#### `sparse_elements_offset`

An offset to an array of `int16_t` integers corresponding to the
elements used for each sparse emission.

### HERCULES Parameters

```c
typedef struct ZBP_HERCULESParameters {
	ZBP_RCATransmitFocus transmit_focus;
} ZBP_HERCULESParameters;
```

A structure containing the aqcuisition parameters when the
[`acquisition_mode`](#acquisition_mode) is
[HERCULES](#acquisition-kind).

#### `transmit_focus`

A [RCA Transmit Focus](#rca-transmit-focus).

### uHERCULES Parameters

```c
typedef struct ZBP_uHERCULESParameters {
	ZBP_RCATransmitFocus transmit_focus;
	int32_t              sparse_elements_offset;
} ZBP_uHERCULESParameters;
```

A structure containing the aqcuisition parameters when the
[`acquisition_mode`](#acquisition_mode) is
[uHERCULES](#acquisition-kind).

#### `transmit_focus`

A [RCA Transmit Focus](#rca-transmit-focus).

#### `sparse_elements_offset`

An offset to an array of `int16_t` integers corresponding to the
elements used for each sparse emission.

### TPW Parameters

```c
typedef struct ZBP_TPWParameters {
	int32_t tilting_angles_offset;
	int32_t transmit_receive_orientations_offset;
} ZBP_TPWParameters;
```

A structure containing the aqcuisition parameters when the
[`acquisition_mode`](#acquisition_mode) is
[RCA_TPW](#acquisition-kind).

#### `tilting_angles_offset`

An offset to an array of `float32_t` floats describing the tilting
angles in degrees for each emission.

#### `transmit_receive_orientations_offset`

An offset to an array of `uint8_t` integers describing the
transmit and recieve orientations for each emission. Bits 0-3 of
the integer contain the Recieve Orientation. Bits 4-7 contain the
Transmit Orientation. The value of each 4 bit number corresponds
to a [RCA Orientation](#rca-orientation).

### VLS Parameters

```c
typedef struct ZBP_VLSParameters {
	int32_t focal_depths_offset;
	int32_t origin_offsets_offset;
	int32_t transmit_receive_orientations_offset;
} ZBP_VLSParameters;
```

A structure containing the aqcuisition parameters when the
[`acquisition_mode`](#acquisition_mode) is
[RCA_VLS](#acquisition-kind).

#### `focal_depths_offset`

An offset to an array of `float32_t` floats describing the focal
depths in meters for each emission.

#### `origin_offsets_offset`

An offset to an array of `float32_t` floats describing the offsets
from the world origin to the transmit origin in meters for each
emission.

#### `transmit_receive_orientations_offset`

An offset to an array of `uint8_t` integers describing the
transmit and recieve orientations for each emission. Bits 0-3 of
the integer contain the Recieve Orientation. Bits 4-7 contain the
Transmit Orientation. The value of each 4 bit number corresponds
to a [RCA Orientation](#rca-orientation).

### Header Version 1

```c
typedef struct ZBP_HeaderV1 {
	uint64_t magic;
	uint32_t version;
	int16_t  decode_mode;
	int16_t  beamform_mode;
	uint32_t raw_data_dimension[4];
	uint32_t sample_count;
	uint32_t channel_count;
	uint32_t receive_event_count;
	uint32_t frame_count;
	float    transducer_element_pitch[2];
	float    transducer_transform_matrix[16];
	int16_t  channel_mapping[256];
	float    steering_angles[256];
	float    focal_depths[256];
	int16_t  sparse_elements[256];
	int16_t  hadamard_rows[256];
	float    speed_of_sound;
	float    demodulation_frequency;
	float    sampling_frequency;
	float    time_offset;
	uint32_t transmit_mode;
} ZBP_HeaderV1;
```

Base structure defining the layout of Version 1 of the binary
parameters file. A description of each field follows.

#### `magic`, `version`

See [Base Header](#base-header).

#### `decode_mode` (V1)

A [Decode Mode](#decode-mode) describing the way the binary data
associated with this parameters file should be decoded.

#### `beamform_mode`

An [Acquistion Kind](#acquistion-kind) describing the way the
binary data associated with this parameters file should be
processed.

#### `raw_data_dimension` (V1)

The dimensions of the raw data associated with this parameters
file. These dimensions may contain padding elements.

* `[0]`: Receive Events * Samples Per Event + Padding.
* `[1]`: Data Channels.
* `[2]`: Data Frames.
* `[3]`: Ensembles (collections of Data Frames).

#### `sample_count` (V1)

The number of samples in the binary data associated with this
parameters file.

#### `channel_count` (V1)

The number of receive channels in the binary data associated with
this parameters file. It may mismatch the Data Channels in the
[`raw_data_dimension`](#raw_data_dimension-v1) in which case the
channel mapping must be used to determine which channels are
non-zero.

#### `receive_event_count` (V1)

The number of receive events in the binary data associated with
this parameters file.

#### `frame_count`

The number of data frames in the binary data associated with this
parameters file.

#### `transducer_transform_matrix` (V1)

A $4 \times 4$ affine transformation from the transmit origin to
the corner of the array used to receive binary data associated
with this parameters file. A $4 \times 4$ allows for any arbitrary
offset and tilt to applied to the receiver array.

#### `transducer_element_pitch` [m] (V1)

The (row, column) element pitch in meters.

#### `channel_mapping`

An array representing the channel mapping which should be applied
to the binary data associated with this parameters file. The count
of valid entries is provided by the
[`channel_count`](#channel_count-v1).

#### `steering_angles` [degrees]

An array of `float32_t` floats describing the steering angles in
degrees for each emission. The count of valid entries is provided by
[`receive_event_count`](#receive_event_count-v1).

#### `focal_depths` [m]

An array of `float32_t` floats describing the focal depth in
meters for each emission. The count of valid entries is provided by
[`receive_event_count`](#receive_event_count-v1).

#### `sparse_elements`

An array of `int16_t` integers corresponding to the elements used
for each sparse emission. Only valid when the
[`beamform_mode`](#beamform-mode) corresponds to a sparse
[Acquistion Kind](#acquistion-kind). The count of valid entries is
provided by [`receive_event_count`](#receive_event_count-v1).

#### `hadamard_rows`

Not used in any known version 1 files.

#### `speed_of_sound` [m/s] (V1)

The suspected speed of sound in m/s at which to process the binary
data associated with this parameters file.

#### `sampling_frequency` [Hz] (V1)

The sampling rate in Hz that the binary data associated with this
parameters file was captured at.

#### `demodulation_frequency` [Hz] (V1)

The demodulation frequency in Hz that the binary data associated
with this parameters file should be processed with. In most
version 1 files it was not valid and instead should be replaced
with `sampling_frequency / 4`.

#### `time_offset` [s] (V1)

The time in seconds at which the center of the emission pulse is
at the surface of the transmitting array. This value should be
added to any calculated time of flight during beamforming.
Generally, this value is negative but that is not required.

#### `transmit_mode`

A field encoding some of the possible transmit receive
orientations. Bit 0 corresponds to the receive orientation and bit
1 corresponds to the transmit orientation. In both cases a value
of 1 means that columns were used and a value of 0 means that the
rows were used. It can be converted to the version 2 encoding with
the following table:

```c
uint8_t transmit_mode_to_version_2_encoding[] = {
	[0] = ZBP_RCAOrientation_Rows    << 4 | ZBP_RCAOrientation_Rows,
	[1] = ZBP_RCAOrientation_Rows    << 4 | ZBP_RCAOrientation_Columns,
	[2] = ZBP_RCAOrientation_Columns << 4 | ZBP_RCAOrientation_Rows,
	[3] = ZBP_RCAOrientation_Columns << 4 | ZBP_RCAOrientation_Columns,
};
```

## Known Limitations

### Version 2

#### Attached Raw Data

If the attached raw data is compressed with ZSTD there is no way
to determine how many bytes are present. This can be handled by
enforcing that ZSTD compressed data attached to the parameters
file must be only attached at the end. Then the size can be
calculated by subtracting the raw data offset from total file
size.

#### Tiled Arrays

Version 2 does not really contain any provisions for tiled arrays.
They can mostly be handled by storing a separate parameters file
for each tile. Since we basically only have a single example of
this in practice we could not predict how they should be stored. A
future revision could handle them better once we have more
examples available.

[Magic value]: https://en.wikipedia.org/wiki/List_of_file_signatures
[C header]: ../c/generated/zemp_bp.h
