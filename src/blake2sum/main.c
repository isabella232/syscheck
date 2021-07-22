#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <assert.h>
#include <dirent.h>
#include <glob.h>
#include <pwd.h>
#include "blake2b.h"

#define errExit(msg)    do { char msgout[500]; snprintf(msgout, 500, "Error %s: %s:%d %s", msg, __FILE__, __LINE__, __FUNCTION__); perror(msgout); exit(1);} while (0)
#define MAXBUF 4096

#define MAX_LEVEL 10	//max directory tree depth
static int level = 1;
static int arg_follow_links = 0;

static inline int is_dir(const char *fname) {
	assert(fname);

	struct stat s;
	int rv = stat(fname, &s);
	if (S_ISDIR(s.st_mode))
		return 1;
	return 0;
}

static inline int is_link(const char *fname) {
	assert(fname);

	char c;
	ssize_t rv = readlink(fname, &c, 1);
	return (rv != -1);
}

// result: array of chars for blake2 checksum
// size: size of checksum array 16 for 128 bit checksum , ... 64 for 512
static void file_checksum(const char *fname) {
	assert(fname);

	int fd = open(fname, O_RDONLY);
	if (fd == -1)
		return;

	off_t size = lseek(fd, 0, SEEK_END);
	if (size <= 0) {
		close(fd);
		return;
	}

	char *content = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
			close(fd);


#if 0
	// unkeyed hash of three ASCII bytes "abc" with BLAKE2b-512 from RFC7693
	unsigned char result[64];
	blake2b(result, 64, NULL, 0, "abc", 3);
//   BLAKE2b-512("abc") = BA 80 A5 3F 98 1C 4D 0D 6A 27 97 B6 9F 12 F6 E9
//                        4C 21 2F 14 68 5A C4 B7 4B 12 BB 6F DB FF A2 D1
//                        7D 87 C5 39 2A AB 79 2D C2 52 D5 DE 45 33 CC 95
//                        18 D3 8A A8 DB F1 92 5A B9 23 86 ED D4 00 99 23
#endif

//	unsigned char checksum[16]; // 128 bits
//	unsigned char checksum[32]; // 256 bits
	unsigned char checksum[64]; // 512 bits
	blake2b(checksum, sizeof(checksum), NULL, 0, content, size);
	munmap(content, size);

	int i;
	for (i = 0; i < sizeof(checksum); i++)
		printf("%02x", (unsigned char ) checksum[i]);
	printf("  %s\n", fname);
	fflush(0);
}

// other functions: scandir, ftw
void list_directory(const char *fname) {
	assert(fname);
	if (level > MAX_LEVEL) {
		fprintf(stderr, "Warning: maximum depth level exceeded for %s\n", fname);
		return;
	}

	if (arg_follow_links == 0 && is_link(fname))
		return;

	if (!is_dir(fname)) {
		file_checksum(fname);
		return;
	}

	DIR *dir;
	struct dirent *entry;

	if (!(dir = opendir(fname)))
		return;

	level++;
	while ((entry = readdir(dir)) != NULL) {
		if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
			continue;
		char *path;
		if (asprintf(&path, "%s/%s", fname, entry->d_name) == -1)
			errExit("asprintf");
		list_directory(path);
		free(path);
	}
	closedir(dir);
	level--;
}



void globbing(const char *fname) {
	assert(fname);

	glob_t globbuf;
	int globerr = glob(fname, GLOB_NOCHECK | GLOB_NOSORT | GLOB_PERIOD, NULL, &globbuf);
	if (globerr) {
		fprintf(stderr, "Error: failed to glob pattern %s\n", fname);
		exit(1);
	}

	int i;
	for (i = 0; i < globbuf.gl_pathc; i++) {
		char *path = globbuf.gl_pathv[i];
		assert(path);
		list_directory(path);
	}

	globfree(&globbuf);
}

void process_config(const char *fname) {
	assert(fname);

	FILE *fp = fopen(fname, "r");
	if (!fp) {
		fprintf(stderr, "Error: cannot open config file %s\n", fname);
		exit(1);
	}

	char buf[MAXBUF];
	int line = 0;
	while (fgets(buf, MAXBUF, fp)) {
		line++;

		// trim \n
		char *ptr = strchr(buf, '\n');
		if (ptr)
			*ptr = '\0';

		ptr = buf;
		while (*ptr == ' ' || *ptr == '\t')
			ptr++;

		// comments, empty line
		if (*ptr == '#' || *ptr == '\0')
			continue;

		// checksum
//		file_checksum(ptr);
		globbing(ptr);
	}

	fclose(fp);
}



void usage(void) {
	printf("Usage: blake2sum [--follow-links]\n");
}

int main(int argc, char **argv) {
	int i;
	for (i = 1; i < argc; i++) {
		if (strcmp(argv[i], "-h") == 0 ||
		    strcmp(argv[i], "-?") == 0 ||
		    strcmp(argv[i], "--help") == 0) {
			usage();
			return 0;
		}
		else if (strcmp(argv[i], "--follow-links") == 0)
			arg_follow_links = 1;
		else {
			fprintf(stderr, "Error: unrecognized %s command line argument\n", argv[i]);
			return 1;
		}
	}

	process_config("config");

	return 0;
}