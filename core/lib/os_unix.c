#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

static PLATFORM_ALLOC_MEMORY_BLOCK_FN(os_block_alloc)
{
	MemoryBlock result = {0};
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

static PLATFORM_READ_WHOLE_FILE_FN(os_read_whole_file)
{
	MemoryStream result = {0};
	struct stat sb;
	iptr fd = open(fname, O_RDONLY, 0);
	if (fd != -1 && fstat(fd, &sb) != -1) {
		result.backing = os_block_alloc(sb.st_size);
		size rlen;
		if (result.backing.size &&
		    ((rlen = read(fd, result.backing.data, sb.st_size)) == sb.st_size))
		{
			result.filled = rlen;
		} else if (result.backing.size) {
			os_block_release(result.backing);
			result.backing = (MemoryBlock){0};
		}
	}

	if (fd != -1) close(fd);

	return result;
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
