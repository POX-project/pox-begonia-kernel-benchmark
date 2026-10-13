/*
 * mem_bw.c - RAM sequential read, write, and memcpy bandwidth benchmark
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdint.h>

static inline unsigned long long get_time_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (unsigned long long)ts.tv_sec * 1000000000ULL + ts.tv_nsec;
}

int main(int argc, char **argv) {
    size_t size_mb = 64;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--size") == 0 && i + 1 < argc) {
            size_mb = (size_t)atoi(argv[++i]);
        }
    }

    size_t bytes = size_mb * 1024 * 1024;
    uint64_t *src = (uint64_t *)malloc(bytes);
    uint64_t *dst = (uint64_t *)malloc(bytes);

    if (!src || !dst) {
        fprintf(stderr, "Failed to allocate %zu MB\n", size_mb);
        return 1;
    }

    // Warm-up and touch pages
    memset(src, 0xAA, bytes);
    memset(dst, 0x55, bytes);

    int loops = 10;
    unsigned long long start = get_time_ns();
    for (int l = 0; l < loops; l++) {
        memcpy(dst, src, bytes);
    }
    unsigned long long end = get_time_ns();

    double total_sec = (double)(end - start) / 1000000000.0;
    double total_mb = (double)(size_mb * loops);
    double mb_per_sec = total_mb / total_sec;

    printf("Buffer size: %zu MiB\n", size_mb);
    printf("Transferred: %.0f MiB in %.3f sec\n", total_mb, total_sec);
    printf("Throughput: %.1f MiB/s\n", mb_per_sec);

    free(src);
    free(dst);
    return 0;
}
