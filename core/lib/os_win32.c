#define PAGE_READWRITE 0x04
#define MEM_COMMIT     0x1000
#define MEM_RESERVE    0x2000
#define MEM_RELEASE    0x8000

#define GENERIC_WRITE  0x40000000
#define GENERIC_READ   0x80000000

#define CREATE_ALWAYS  2
#define OPEN_EXISTING  3

PACK(struct w32_file_info {
	u32 dwFileAttributes;
	u64 ftCreationTime;
	u64 ftLastAccessTime;
	u64 ftLastWriteTime;
	u32 dwVolumeSerialNumber;
	u32 nFileSizeHigh;
	u32 nFileSizeLow;
	u32 nNumberOfLinks;
	u32 nFileIndexHigh;
	u32 nFileIndexLow;
});
typedef struct w32_file_info w32_file_info;

#define W32(r) __declspec(dllimport) r __stdcall
W32(b32)    CloseHandle(iptr);
W32(iptr)   CreateFileA(c8 *, u32, u32, void *, u32, u32, void *);
W32(b32)    GetFileInformationByHandle(iptr, w32_file_info *);
W32(i32)    GetLastError(void);
W32(b32)    ReadFile(iptr, u8 *, i32, i32 *, void *);
W32(b32)    WriteFile(iptr, u8 *, i32, i32 *, void *);
W32(void *) VirtualAlloc(u8 *, iz, u32, u32);
W32(b32)    VirtualFree(u8 *, iz, u32);

static PLATFORM_ALLOC_MEMORY_BLOCK_FN(os_block_alloc)
{
	MemoryBlock result = {0};

	iz pagesize = 4096L;
	iz capacity = requested_size;
	if (capacity % pagesize != 0)
		capacity += (pagesize - capacity % pagesize);

	result.data = VirtualAlloc(0, capacity, MEM_RESERVE|MEM_COMMIT, PAGE_READWRITE);
	if (result.data)
		result.size = capacity;

	return result;
}

static PLATFORM_RELEASE_MEMORY_BLOCK_FN(os_block_release)
{
	if (memory.size)
		VirtualFree(memory.data, memory.size, MEM_RELEASE);
}

static PLATFORM_READ_WHOLE_FILE_FN(os_read_whole_file)
{
	MemoryStream result = {0};
	w32_file_info fi;
	iptr h = CreateFileA(fname, GENERIC_READ, 0, 0, OPEN_EXISTING, 0, 0);
	if (h >= 0 && GetFileInformationByHandle(h, &fi)) {
		iz file_size   = (iz)fi.nFileSizeHigh << 32 | (iz)fi.nFileSizeLow;
		result.backing = os_block_alloc(file_size);
		i32 rlen;
		if (result.backing.size && file_size <= (iz)((u32)-1) &&
		    ReadFile(h, result.backing.data, file_size, &rlen, 0) &&
		    rlen == file_size)
		{
			result.filled = rlen;
		} else {
			os_block_release(result.backing);
			result.backing = (MemoryBlock){0};
		}
	}

	if (h != -1) CloseHandle(h);

	return result;
}

static PLATFORM_WRITE_NEW_FILE_FN(os_write_new_file)
{
	/* TODO(rnp): use overlapped io to write files > 4GB */
	if (raw.len > (iz)((u32)-1))
		return 0;

	iptr h = CreateFileA(fname, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, 0, 0);
	if (h == -1)
		return  0;

	i32 wlen;
	WriteFile(h, raw.data, raw.len, &wlen, 0);
	b32 result = wlen == raw.len;
	CloseHandle(h);

	return result;
}
