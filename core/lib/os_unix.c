#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

static PLATFORM_ALLOC_MEMORY_BLOCK_FN(os_block_alloc)
{
	MemoryBlock result;
	size pagesize = 4096L;
	size capacity = requested_size;
	if (capacity % pagesize != 0)
		capacity += pagesize - capacity % pagesize;

	result.data = mmap(0, capacity, PROT_READ|PROT_WRITE, MAP_ANON|MAP_PRIVATE, -1, 0);
	if (result.data != MAP_FAILED)
		result.size = capacity;

	return result;
}

static PLATFORM_RELEASE_MEMORY_BLOCK_FN(os_block_release)
{
	munmap(memory.data, memory.size);
}

static PLATFORM_WRITE_NEW_FILE_FN(os_write_new_file)
{
	iptr fd = open(fname, O_WRONLY|O_TRUNC|O_CREAT, 0600);
	if (fd == -1)
		return 0;
	b32 result = write(fd, raw.data, raw.len) == raw.len;
	close(fd);
	return result;
}
