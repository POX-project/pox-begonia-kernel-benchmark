/*
 * io_sync.c - 4KiB direct synchronous write & fsync microbenchmark
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>

static inline unsigned long long get_time_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (unsigned long long)ts.tv_sec * 1000000000ULL + ts.tv_nsec;
}

int main(int argc, char **argv) {
    int count = 500;
    const char *path = "/data/local/tmp/pox_bench/tmp/io_direct_test.bin";

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--count") == 0 && i + 1 < argc) {
            count = atoi(argv[++i]);
        }
    }

    void *buf;
    if (posix_memalign(&buf, 4096, 4096) != 0) {
        perror("posix_memalign");
        return 1;
    }
    memset(buf, 0x5A, 4096);

    int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC | O_SYNC, 0644);
    if (fd < 0) {
        // Fallback without O_SYNC if filesystem restricts it
        fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    }
    if (fd < 0) {
        perror("open");
        free(buf);
        return 1;
    }

    unsigned long long start = get_time_ns();
    for (int i = 0; i < count; i++) {
        if (write(fd, buf, 4096) != 4096) {
            perror("write");
            break;
        }
        fdatasync(fd);
    }
    unsigned long long end = get_time_ns();

    close(fd);
    unlink(path);
    free(buf);

    double total_sec = (double)(end - start) / 1000000000.0;
    double iops = (double)count / total_sec;

    printf("Operations: %d (4KiB sync writes)\n", count);
    printf("Total time: %.3f sec\n", total_sec);
    printf("IOPS: %.1f\n", iops);

    return 0;
}
