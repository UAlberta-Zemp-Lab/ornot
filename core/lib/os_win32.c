#define PAGE_READWRITE 0x04
#define MEM_COMMIT     0x1000
#define MEM_RESERVE    0x2000
#define MEM_RELEASE    0x8000

#define GENERIC_WRITE  0x40000000

#define CREATE_ALWAYS  2

#define W32(r) __declspec(dllimport) r __stdcall
W32(b32)    CloseHandle(iptr);
W32(iptr)   CreateFileA(c8 *, u32, u32, void *, u32, u32, void *);
W32(i32)    GetLastError(void);
W32(b32)    WriteFile(iptr, u8 *, i32, i32 *, void *);
W32(void *) VirtualAlloc(u8 *, size, u32, u32);
W32(b32)    VirtualFree(u8 *, size, u32);

static PLATFORM_ALLOC_MEMORY_BLOCK_FN(os_block_alloc)
{
	MemoryBlock result;

	size pagesize = 4096L;
	size capacity = requested_size;
	if (capacity % pagesize != 0)
		capacity += (pagesize - capacity % pagesize);

	result.data = VirtualAlloc(0, capacity, MEM_RESERVE|MEM_COMMIT, PAGE_READWRITE);
	if (result.data)
		result.size = capacity;

	return result;
}

static PLATFORM_RELEASE_MEMORY_BLOCK_FN(os_block_release)
{
	VirtualFree(memory.data, memory.size, MEM_RELEASE);
}

static PLATFORM_WRITE_NEW_FILE_FN(os_write_new_file)
{
	/* TODO(rnp): use overlapped io to write files > 4GB */
	if (raw.len > (size)((u32)-1))
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
