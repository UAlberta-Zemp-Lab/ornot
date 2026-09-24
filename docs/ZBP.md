# ZBP Metadata Files

When ultrasound data is acquired and saved using any of our
imaging software all metadata required to reconstruct an image is
stored in a binary `.bp` file. This document aims to describe the
format in detail. Should this file be out of date the [C header][]
is the final source of truth.

The binary format described here is defined in Little Endian byte
order. No support is provided for reading or writing these files
from a Big Endian host. A parameter file is considered invalid if
it is not in Little Endian byte order.

Furthermore, these files are only meant to describe what is
necessary for beamforming, they do contain any metadata that is
context dependent.

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
	ZBP_AcquisitionKind_HEXDoppler     = 12,
	ZBP_AcquisitionKind_XDoppler       = 13,
	ZBP_AcquisitionKind_Count,
} ZBP_AcquisitionKind;
```

Encodes the imaging method used to acquire the data.

### Contrast Mode

```c
typedef enum {
	ZBP_ContrastMode_None = 0,
	ZBP_ContrastMode_A1S2 = 1,
	ZBP_ContrastMode_A2   = 2,
	ZBP_ContrastMode_Count,
} ZBP_ContrastMode;
```

Encodes whether the data was acquired using a method capable of
providing non-linear contrast. For example,
`ZBP_ContrastMode_A1S2` means that one batch of `sample_count`
samples from a single channel should be added, and two should be
subtracted to generate non-linear contrast.

### Contrast Data Flags

```c
typedef enum {
	ZBP_ContrastDataFlags_Reduced = 1 << 0,
} ZBP_ContrastDataFlags;
```

A bit field used to record operations performed on a
[Contrast](#contrast-mode) data set prior to saving.

* `Reduced`: samples were combined prior to saving.
  Usually done in hardware.

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

### Data Layout

```c
typedef enum {
	ZBP_DataLayout_Standard = 0,
	ZBP_DataLayout_Count,
} ZBP_DataLayout;

```

Placeholder for storing raw data in a different layout. For
performance we may need to acquire data with a different layout
than we have been using. Without writing the shuffling ourselves
it is too slow to reorganize the data prior to saving.

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
* `Standard`: data was sampled at 4x the system's transmit frequency.
* `Bandpass`: data was sampled at 2x or 1x system's transmit frequency.
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

### Header Version 3

```c
typedef struct ZBP_HeaderV3 {
	uint64_t                magic;
	uint32_t                major;
	uint32_t                minor;
	uint32_t                raw_data_dimension[4];
	uint64_t                raw_data_size;
	int32_t                 raw_data_offset;
	ZBP_DataKind            raw_data_kind;
	ZBP_DataCompressionKind raw_data_compression_kind;
	ZBP_DataLayout          raw_data_layout;
	ZBP_DecodeMode          decode_mode;
	ZBP_SamplingMode        sampling_mode;
	float                   sampling_frequency;
	float                   speed_of_sound;
	int32_t                 channel_mapping_offset;
	uint32_t                sample_count;
	uint32_t                channel_count;
	uint32_t                receive_event_count;
	uint32_t                transducer_tile_count[2];
	float                   transducer_element_pitch[2];
	float                   group_acquisition_time;
	float                   ensemble_repetition_interval;
	ZBP_AcquisitionKind     acquisition_mode;
	int32_t                 acquisition_parameters_offset;
	ZBP_ContrastMode        contrast_mode;
	uint32_t                contrast_data_flags;
	int32_t                 contrast_parameters_offset;
	int32_t                 emission_descriptors_offset;
	int32_t                 time_delays_offset;
	int32_t                 demodulation_frequencies_offset;
	int32_t                 transducer_transforms_offset;
	uint32_t                string_count;
	int32_t                 string_table_offset;
} ZBP_HeaderV3;
```

Base structure defining the layout of Version 3 of the binary
parameters file. All `*_offset` parameters represent an offset
from the start of the file. An offset of -1 indicates that the
corresponding data is not included in the file. A description of
each field follows.

#### `magic`, `major`, `minor`

See [Base Header](#base-header).

#### `raw_data_dimension`

The dimensions of the raw data associated with this parameters
file. These dimensions may contain padding elements.

* `[0]`: Receive Events * Samples Per Event + Padding
* `[1]`: Data Channels
* `[2]`: Data Frames
* `[3]`: Ensembles (collections of Data Frames)

A single Data Frame contains all data necessary to reconstruct a
single image/volume. For example FORCES-128 requires 128 receive
events and the collection of those receive events form a single
Data Frame.

#### `raw_data_size`

If the file contains attached data this indicates the number of
bytes after [`raw_data_offset`](#raw_data_offset-optional) which
contain data.

#### `raw_data_offset` (Optional)

An offset from the start of the file to an attached raw data blob.

#### `raw_data_kind`

A [Data Kind](#data-kind) describing the interpretation of the
binary data associated with this parameters file.

#### `raw_data_compression_kind`

A [Data Compression Kind](#data-compression-kind) describing the
interpretation of the binary data associated with this parameters
file.

#### `raw_data_layout`

A [Data Layout](#data-layout) describing the layout of the binary
data associated with this parameters file.

#### `decode_mode`

A [Decode Mode](#decode-mode) describing the way the binary data
associated with this parameters file should be decoded.

#### `sampling_mode`

A [Sampling Mode](#sampling-mode) describing the way the binary
data associated with this parameters file was sampled.

#### `sampling_frequency` [Hz]

The sampling rate in Hz that the binary data associated with this
parameters file was captured at.

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

#### `transducer_tile_count`

The number of transducer tiles in the (row, column) direction.
Each value must always be at least `1`. The product of these two
elements gives the total number of affine transformations pointed
to by [`transducer_transforms_offset`](#transducer_transforms_offset).

#### `transducer_element_pitch` [m]

The (row, column) element pitch in meters.

#### `group_acquisition_time` [s]

The amount of time in seconds taken to acquire a single
[Data Frame](#raw_data_dimension).

#### `ensemble_repetition_interval` [s]

The amount of time in seconds between [Ensembles](#raw_data_dimension).

#### `acquisition_mode`

An [Acquisition Kind](#acquisition-kind) describing the way the
binary data associated with this parameters file should be
processed as well as the how to interpret the
[acquisition parameters](#acquisition_parameters_offset)
contained in parameters file.

#### `acquisition_parameters_offset`

A offset to an array of acquisition parameters structures the type
of which are determined by the
[`acquisition_mode`](#acquisition_mode). The length of this array
is given by the count of [Data Frames](#raw_data_dimension). This
offset is required to always be valid.

#### `contrast_mode`

A [Contrast Mode](#contrast-mode) describing the way the binary
data associated with this parameters file should be processed as
well as the how to interpret the
[contrast parameters](#contrast_parameters_offset-optional)
contained in parameters file.

#### `contrast_data_flags`

A bit mask of [Contrast Data Flags](#contrast-data-flags)
describing any modifications applied to the data prior to saving.
The primary purpose is to allow use of some acquisition hardware
techniques while still documenting that a contrast enhancing
method was applied.

#### `contrast_parameters_offset` (Optional)

An offset to an contrast parameters structure the type of which is
determined by the [`contrast_mode`](#contrast_mode). If the mode
is `None` this offset can be -1.

#### `emission_descriptors_offset`

An offset to an array of [Emission Descriptor](#emission-descriptor)
structures. The number of emission descriptors present is determined
by the number of [Data Frames](#raw_data_dimension). When there is no
emission, such as when [`acquisition_mode`](#acquisition_mode) is
[`HERO_PA`](#hero-pa-parameters), this offset can be -1.

#### `demodulation_frequencies_offset`

An offset to an array of `float32_t` demodulation frequencies
stored in [Hz] that the binary data associated with this
parameters file should be processed with. The exists one entry per
[Data Frame](#raw_data_dimension). If the [Data Kind](#data-kind)
is Complex and this frequency is non-zero the data is assumed to
be at baseband. If the [Data Kind](#data-kind) is Complex and this
frequency is 0 then it is assumed the data is Complex RF data and
it should be processed as RF data.

#### `transducer_transforms_offset`

An offset to an array of 4x4 affine transformations from the
transmit origin to the center of the element in the corner of the
each array used to receive the binary data associated with this
parameters file. A 4x4 matrix allows for any arbitrary offset and
tilt to applied to each receiver array.

#### `time_delays_offset` [s]

An offset to an array of `float32_t` values representing the
additional time delay which should be applied to the binary data
associated with each frame of data referred to by this parameters
file. The length of this array is given by the count of
[Data Frames](#raw_data_dimension).

#### `string_count`

Count of entries in the string table located at
[`string_table_offset`](#string_table_offset).

#### `string_table_offset`

An offset to a table of [String Table Entries](#string-table-entry).
The number of entries is given by [`string_count`](#string_count).

### Header Version 2

Version 2 contains the following differences from Version 3:

* No `raw_data_size` see [limitations](#attached-raw-data-v2).
* No `raw_data_layout`.
* No `contrast_data_flags`.
* Single `transducer_transform_matrix` instead of `transducer_tile_count`
  and `transducer_transforms_offset`. See [limitations](#tiled-arrays-v2).
* Single `time_offset` instead of `time_delays_offset`. In Version 2.1 the
  `time_offset` does not include the contribution of the emission.
* Single `demodulation_frequency` instead of `demodulation_frequencies_offset`.
* No `string_count` or `string_table_offset`.

### Header Version 1

Version 1 contains the following differences from Version 2:

* No `minor` version field.
* No `sampling_mode` parameter. Assume `ZBP_SamplingMode_Standard`.
* No `raw_data_kind`, `raw_data_offset`, or `raw_data_compression_kind`.
  Raw data could not be attached to these files and compression needs to be
  determined externally (e.g. by file name). All files saved with this header
  used `ZBP_DataKind_Int16`.
* No `group_acquisition_time` or `ensemble_repetition_interval`.
* No `contrast_mode`.
* No `acquisition_parameters_offset`. Which of the included parameter arrays
  are relevant needs to be determined based on the `beamform_mode` field
  (a.k.a. `acquisition_mode`).
* No `emission_descriptors_offset`. Emission parameters must be determined
  externally but were often just a two cycle sine wave at the recorded
  `demodulation_frequency`.
* `frame_count` member which is a duplicate of `raw_data_dimension[2]`.
* `channel_mapping`, `steering_angles`, `focal_depths`,
  and `sparse_elements` are always included as fixed size
  256 element arrays.
* `hadamard_rows` field which is not used in any known V1 files.
* `demodulation_frequency` is generally not accurate and should be replaced
  by `sampling_frequency / 4`.
* `transmit_mode` field encoding the Tx and Rx orientation in a different
  format described below.

#### `transmit_mode`

A field encoding some of the possible transmit receive
orientations. Bit 0 corresponds to the receive orientation and bit
1 corresponds to the transmit orientation. In both cases a value
of 1 means that columns were used and a value of 0 means that the
rows were used. It can be converted to the standard encoding with
the following table:

```c
uint8_t transmit_mode_to_standard_encoding[] = {
	[0] = ZBP_RCAOrientation_Rows    << 4 | ZBP_RCAOrientation_Rows,
	[1] = ZBP_RCAOrientation_Rows    << 4 | ZBP_RCAOrientation_Columns,
	[2] = ZBP_RCAOrientation_Columns << 4 | ZBP_RCAOrientation_Rows,
	[3] = ZBP_RCAOrientation_Columns << 4 | ZBP_RCAOrientation_Columns,
};
```

### Emission Descriptor

```c
typedef struct ZBP_EmissionDescriptor {
	int32_t emission_kind;
	int32_t parameters_offset;
} ZBP_EmissionDescriptor;
```

A structure describing the emission used to acquire a single Data Frame
in the binary file associated with this parameters file.

#### `emission_kind`

A [Emission Kind](#emission-kind) describing the way the binary
data associated with this Data Frame should be processed and how to
interpret the emission parameter structure referenced by
[`parameters_offset`](#parameters_offset).

#### `parameters_offset`

An offset to the emission parameters structure for this Data Frame. The
type of the structure is determined by the [Emission Kind](#emission-kind).
This offset is required to always be valid.

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

#### `max_frequency` [Hz]

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

The focal depth of an emission in meters. May be negative for a
diverging emission and may be infinite for a plane wave emission.

#### `steering_angle` [degrees]

The steering angle of the emission measured between the Z axis and
axis orthogonal to the Transmit Orientation.

#### `origin_offset` [m]

The offset from the world origin to origin of the emission in
meters. Measured along the axis orthogonal to the Transmit
Orientation. Primarily useful for focused emissions.

#### `transmit_receive_orientation`

A field encoding the orientation of both the transmit and the
receive phase of an emission. Bits 0-3 contain the Receive
Orientation. Bits 4-7 contain the Transmit Orientation. The value
of each 4 bit number corresponds to a [RCA Orientation](#rca-orientation).
The upper 24 bits are currently unused padding bits.

### FORCES Parameters

```c
typedef struct ZBP_FORCESParameters {
	ZBP_RCATransmitFocus transmit_focus;
} ZBP_FORCESParameters;
```

A structure containing the acquisition parameters when the
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

A structure containing the acquisition parameters when the
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

A structure containing the acquisition parameters when the
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

A structure containing the acquisition parameters when the
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

A structure containing the acquisition parameters when the
[`acquisition_mode`](#acquisition_mode) is
[RCA_TPW](#acquisition-kind).

#### `tilting_angles_offset`

An offset to an array of `float32_t` floats describing the tilting
angles in degrees for each emission.

#### `transmit_receive_orientations_offset`

An offset to an array of `uint8_t` integers describing the
transmit and receive orientations for each emission. Bits 0-3 of
the integer contain the Receive Orientation. Bits 4-7 contain the
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

A structure containing the acquisition parameters when the
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
transmit and receive orientations for each emission. Bits 0-3 of
the integer contain the Receive Orientation. Bits 4-7 contain the
Transmit Orientation. The value of each 4 bit number corresponds
to a [RCA Orientation](#rca-orientation).

### HERO PA Parameters

```c
typedef struct ZBP_HERO_PAParameters {
	uint32_t transmit_receive_orientation;
} ZBP_HERO_PAParameters;
```

A structure containing the acquisition parameters when the
[`acquisition_mode`](#acquisition_mode) is
[HERO_PA](#acquisition-kind).

#### `transmit_receive_orientation`

A field encoding the orientation of both the transmit and the
receive phase of an emission. Bits 0-3 contain the Receive
Orientation. Bits 4-7 contain the Transmit Orientation. The value
of each 4 bit number corresponds to a [RCA Orientation](#rca-orientation).
The upper 24 bits are currently unused padding bits.

### HEXDoppler Parameters

```c
typedef struct ZBP_HEXDopplerParameters {
	int32_t bin_count[2];
	int32_t bin_size[2];
} ZBP_HEXDopplerParameters;
```

A structure containing the acquisition parameters when the
[`acquisition_mode`](#acquisition_mode) is [HEXDoppler](#acquisition-kind).

#### `bin_count`

The number of bins in each orientation. Rows first, then Columns. Must add up to [`receive_event_count`](#receive_event_count).

#### `bin_size`

The number elements in a bin in each orientation. Rows transmits first, then Columns.

### XDoppler Parameters

```c
typedef struct ZBP_XDopplerParameters {
	int32_t angle_count[2];
	int32_t tilting_angles_offset;
} ZBP_XDopplerParameters;
```

A structure containing the acquisition parameters when the
[`acquisition_mode`](#acquisition_mode) is
[XDoppler](#acquisition-kind).

#### `angle_count`

The number of angle transmits in each orientation. Rows transmits first,
then Columns. Must add up to [`receive_event_count`](#receive_event_count).

#### `tilting_angles_offset`

An offset to an array of `float32_t` floats describing the tilting
angles in degrees for each emission.

### String Table Entry

```c
typedef struct ZBP_StringTableEntry {
	uint32_t string_tag_length;
	int32_t  string_tag_offset;
	uint32_t string_length;
	int32_t  string_offset;
} ZBP_StringTableEntry;
```

Used to describe a string embedded in the file. Strings are stored
as `(tag, value)` pairs. Embedded strings need not be `0`
terminated. In general it is expected that `tags` are stored
immediately prior to their `values` but they may also be stored in
separate groups.

## Known Limitations

### Version 2

#### Attached Raw Data (V2)

Since the format lacks metadata about the size of attached raw
data when it is compressed, the size must be calculated
indirectly. This can be handled by requiring that compressed data
be attached as the final section in the parameters file-this way,
the size can be calculated by subtracting the `raw_data_offset`
from the total file size.

#### Tiled Arrays (V2)

Version 2 does not really contain any provisions for tiled arrays.
They can mostly be handled by storing a separate parameters file
for each tile. Since we basically only have a single example of
this in practice we could not predict how they should be stored. A
future revision could handle them better once we have more
examples available.

[Magic value]: https://en.wikipedia.org/wiki/List_of_file_signatures
[C header]: ../c/generated/zemp_bp.h
