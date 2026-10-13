/*
 * page_fault.c - Anonymous mmap and page fault latency benchmark
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <time.h>

static inline unsigned long long get_time_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (unsigned long long)ts.tv_sec * 1000000000ULL + ts.tv_nsec;
}

int main(int argc, char **argv) {
    size_t pages = 10000;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--pages") == 0 && i + 1 < argc) {
            pages = (size_t)atoi(argv[++i]);
        }
    }

    size_t page_size = sysconf(_SC_PAGESIZE);
    size_t total_bytes = pages * page_size;

    char *buf = (char *)mmap(NULL, total_bytes, PROT_READ | PROT_WRITE,
                             MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (buf == MAP_FAILED) {
        perror("mmap");
        return 1;
    }

    // Touch every page triggering soft page fault
    unsigned long long start = get_time_ns();
    for (size_t i = 0; i < pages; i++) {
        buf[i * page_size] = (char)(i & 0xFF);
    }
    unsigned long long end = get_time_ns();

    munmap(buf, total_bytes);

    unsigned long long diff_ns = end - start;
    double lat_us_per_page = ((double)diff_ns / (double)pages) / 1000.0;

    printf("Pages: %zu (Page size: %zu bytes)\n", pages, page_size);
    printf("Total fault time: %.2f ms\n", (double)diff_ns / 1000000.0);
    printf("Latency: %.2f µs\n", lat_us_per_page);

    return 0;
}
