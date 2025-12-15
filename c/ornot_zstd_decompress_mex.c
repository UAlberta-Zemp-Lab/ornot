#include <mex.h>
#include <stdint.h>
#include <zstd.h>

typedef uint8_t u8;
typedef int16_t i16;
typedef int32_t i32;
typedef size_t  ux;

void
mexFunction(i32 nlhs, mxArray *plhs[], i32 nrhs, mxArray *prhs[])
{
	if (nlhs > 1)
		mexErrMsgIdAndTxt("ornot:zstd_decompress", "function returns 1 result");
	if (!nrhs || mxGetClassID(prhs[0]) != mxUINT8_CLASS)
		mexErrMsgIdAndTxt("ornot:zstd_decompress", "function takes a uint8 array");

	ux m = mxGetM(prhs[0]);
	ux n = mxGetN(prhs[0]);
	if (m != 1 && n != 1)
		mexErrMsgIdAndTxt("ornot:zstd_decompress", "expected 1D input data");

	u8 *compressed    = mxGetData(prhs[0]);
	ux requested_size = ZSTD_getFrameContentSize(compressed, m * n);

	mwSignedIndex dims[2] = {1, requested_size / 2};
	plhs[0] = mxCreateNumericArray(2, dims, mxINT16_CLASS, mxREAL);
	if (!plhs[0])
		mexErrMsgIdAndTxt("ornot:zstd_decompress", "failed to allocate space for output data");

	ux decompressed_size = ZSTD_decompress(mxGetData(plhs[0]), requested_size, compressed, m * n);
	if (decompressed_size != requested_size) {
		mexErrMsgIdAndTxt("ornot:zstd_decompress",
		                  "failed to decompress full data: decompressed %zu/%zu bytes",
		                  decompressed_size, requested_size);
	}
}
