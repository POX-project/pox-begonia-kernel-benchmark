/*
 * ctx_switch.c - Nanosecond-precision pipe context switch microbenchmark
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>

static inline unsigned long long get_time_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (unsigned long long)ts.tv_sec * 1000000000ULL + ts.tv_nsec;
}

int main(int argc, char **argv) {
    int iterations = 20000;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--iterations") == 0 && i + 1 < argc) {
            iterations = atoi(argv[++i]);
        }
    }

    int p1[2], p2[2];
    if (pipe(p1) < 0 || pipe(p2) < 0) {
        perror("pipe");
        return 1;
    }

    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return 1;
    }

    if (pid == 0) {
        // Child
        close(p1[1]);
        close(p2[0]);
        char token = 'x';
        for (int i = 0; i < iterations; i++) {
            if (read(p1[0], &token, 1) != 1) break;
            if (write(p2[1], &token, 1) != 1) break;
        }
        close(p1[0]);
        close(p2[1]);
        _exit(0);
    } else {
        // Parent
        close(p1[0]);
        close(p2[1]);
        char token = 'o';

        // Warm up
        for (int i = 0; i < 50; i++) {
            write(p1[1], &token, 1);
            read(p2[0], &token, 1);
        }

        unsigned long long start = get_time_ns();
        for (int i = 0; i < iterations; i++) {
            write(p1[1], &token, 1);
            read(p2[0], &token, 1);
        }
        unsigned long long end = get_time_ns();

        close(p1[1]);
        close(p2[0]);
        waitpid(pid, NULL, 0);

        unsigned long long diff_ns = end - start;
        // Each round involves 2 context switches (parent -> child -> parent)
        double total_switches = (double)iterations * 2.0;
        double latency_us = ((double)diff_ns / total_switches) / 1000.0;

        printf("Context switches: %.0f\n", total_switches);
        printf("Total time: %.2f ms\n", (double)diff_ns / 1000000.0);
        printf("Latency: %.2f µs\n", latency_us);
    }

    return 0;
}
