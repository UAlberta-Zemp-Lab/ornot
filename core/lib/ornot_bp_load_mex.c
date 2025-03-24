#include <mex.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "zemp_bp.h"

#define ARRAY_SIZE 256

#define SET_SCALAR(name, val, out) mxSetField(out, 0, name, mxCreateDoubleScalar((double)(val)))

#define SET_INT_ARRAY(name, data, n, out) do { \
	mxArray* a = mxCreateNumericMatrix(1, n, mxINT16_CLASS, mxREAL); \
	memcpy(mxGetData(a), data, sizeof(int16_t) * n); \
	mxSetField(out, 0, name, a); \
} while (0)

#define SET_UINT_ARRAY(name, data, n, out) do { \
	mxArray* a = mxCreateNumericMatrix(1, n, mxUINT32_CLASS, mxREAL); \
	memcpy(mxGetData(a), data, sizeof(uint32_t) * n); \
	mxSetField(out, 0, name, a); \
} while (0)

#define SET_FLOAT_ARRAY(name, data, n, out) do { \
	mxArray* a = mxCreateNumericMatrix(1, n, mxSINGLE_CLASS, mxREAL); \
	memcpy(mxGetData(a), data, sizeof(float) * n); \
	mxSetField(out, 0, name, a); \
} while (0)

const char* field_names[] = {
	"version", "decode_mode", "beamform_mode",
	"raw_data_dim", "decoded_data_dim",
	"transducer_element_pitch", "transducer_transform_matrix",
	"channel_mapping", "steering_angles", "focal_depths",
	"sparse_elements", "hadamard_rows",
	"speed_of_sound", "center_frequency", "sampling_frequency",
	"time_offset", "transmit_mode"
};



void 
mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
    if (nrhs != 1 || !mxIsChar(prhs[0])) {
        mexErrMsgIdAndTxt("bp_load:input", "Expected a single string input (file path).");
    }

    char* filepath = mxArrayToString(prhs[0]);
    if (!filepath) {
        mexErrMsgIdAndTxt("bp_load:conversion", "Failed to convert input to string.");
    }

    FILE* f = fopen(filepath, "rb");
    if (!f) {
        mxFree(filepath);
        mexErrMsgIdAndTxt("bp_load:file", "Failed to open file.");
    }

    zemp_bp_v1 rec;
    size_t read_bytes = fread(&rec, sizeof(zemp_bp_v1), 1, f);
    fclose(f);
    mxFree(filepath);

    if (read_bytes != 1 || rec.magic != ZEMP_BP_MAGIC) {
        mexErrMsgIdAndTxt("bp_load:data", "Invalid or corrupt file (bad magic number or read failure).");
    }

    mxArray* out = mxCreateStructMatrix(1, 1, sizeof(field_names)/sizeof(field_names[0]), field_names);
	if (!out) {
		mexErrMsgIdAndTxt("bp_load:alloc", "Failed to allocate output structure.");
	}

    SET_SCALAR("version", rec.version, out);
    SET_SCALAR("decode_mode", rec.decode_mode, out);
    SET_SCALAR("beamform_mode", rec.beamform_mode, out);

    SET_UINT_ARRAY("raw_data_dim", rec.raw_data_dim, 4, out);
    SET_UINT_ARRAY("decoded_data_dim", rec.decoded_data_dim, 4, out);
    SET_FLOAT_ARRAY("transducer_element_pitch", rec.transducer_element_pitch, 2, out);
    SET_INT_ARRAY("channel_mapping", rec.channel_mapping, ARRAY_SIZE, out);
    SET_FLOAT_ARRAY("steering_angles", rec.steering_angles, ARRAY_SIZE, out);
    SET_FLOAT_ARRAY("focal_depths", rec.focal_depths, ARRAY_SIZE, out);
    SET_INT_ARRAY("sparse_elements", rec.sparse_elements, ARRAY_SIZE, out);
    SET_INT_ARRAY("hadamard_rows", rec.hadamard_rows, ARRAY_SIZE, out);

    SET_SCALAR("speed_of_sound", rec.speed_of_sound, out);
    SET_SCALAR("center_frequency", rec.center_frequency, out);
    SET_SCALAR("sampling_frequency", rec.sampling_frequency, out);
    SET_SCALAR("time_offset", rec.time_offset, out);
    SET_SCALAR("transmit_mode", rec.transmit_mode, out);

	// Making this 4x4 
	mxArray* tfm = mxCreateNumericMatrix(4, 4, mxSINGLE_CLASS, mxREAL);
	memcpy(mxGetData(tfm), rec.transducer_transform_matrix, sizeof(float) * 16);
	mxSetField(out, 0, "transducer_transform_matrix", tfm);

    plhs[0] = out;
}
