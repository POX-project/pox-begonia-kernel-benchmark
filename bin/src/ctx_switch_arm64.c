/* Standalone AArch64 Linux pipe context switch microbenchmark (nostdlib) */
struct timespec {
    long tv_sec;
    long tv_nsec;
};

static inline long sys_read(int fd, void *buf, unsigned long count) {
    register long x8 __asm__("x8") = 63;
    register long x0 __asm__("x0") = fd;
    register long x1 __asm__("x1") = (long)buf;
    register long x2 __asm__("x2") = count;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0), "r"(x1), "r"(x2) : "memory");
    return x0;
}

static inline long sys_write(int fd, const void *buf, unsigned long count) {
    register long x8 __asm__("x8") = 64;
    register long x0 __asm__("x0") = fd;
    register long x1 __asm__("x1") = (long)buf;
    register long x2 __asm__("x2") = count;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0), "r"(x1), "r"(x2) : "memory");
    return x0;
}

static inline void sys_exit(int code) {
    register long x8 __asm__("x8") = 93;
    register long x0 __asm__("x0") = code;
    __asm__ volatile("svc 0" : : "r"(x8), "r"(x0) : "memory");
    while(1);
}

static inline long sys_pipe2(int *pipefd, int flags) {
    register long x8 __asm__("x8") = 59;
    register long x0 __asm__("x0") = (long)pipefd;
    register long x1 __asm__("x1") = flags;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0), "r"(x1) : "memory");
    return x0;
}

static inline long sys_clone(unsigned long flags, void *child_stack) {
    register long x8 __asm__("x8") = 220;
    register long x0 __asm__("x0") = flags;
    register long x1 __asm__("x1") = (long)child_stack;
    register long x2 __asm__("x2") = 0;
    register long x3 __asm__("x3") = 0;
    register long x4 __asm__("x4") = 0;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0), "r"(x1), "r"(x2), "r"(x3), "r"(x4) : "memory");
    return x0;
}

static inline long sys_clock_gettime(int clk_id, struct timespec *ts) {
    register long x8 __asm__("x8") = 113;
    register long x0 __asm__("x0") = clk_id;
    register long x1 __asm__("x1") = (long)ts;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0), "r"(x1) : "memory");
    return x0;
}

static inline long sys_wait4(int pid, int *status, int options, void *rusage) {
    register long x8 __asm__("x8") = 260;
    register long x0 __asm__("x0") = pid;
    register long x1 __asm__("x1") = (long)status;
    register long x2 __asm__("x2") = options;
    register long x3 __asm__("x3") = (long)rusage;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0), "r"(x1), "r"(x2), "r"(x3) : "memory");
    return x0;
}

static inline long sys_close(int fd) {
    register long x8 __asm__("x8") = 57;
    register long x0 __asm__("x0") = fd;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0) : "memory");
    return x0;
}

static void print_str(const char *s) {
    unsigned long len = 0;
    while (s[len]) len++;
    sys_write(1, s, len);
}

static void print_ulong(unsigned long n) {
    char buf[32];
    int idx = 30;
    buf[31] = '\0';
    if (n == 0) {
        buf[idx--] = '0';
    } else {
        while (n > 0 && idx >= 0) {
            buf[idx--] = '0' + (n % 10);
            n /= 10;
        }
    }
    print_str(&buf[idx + 1]);
}

void _start(void) {
    int p1[2], p2[2];
    if (sys_pipe2(p1, 0) < 0 || sys_pipe2(p2, 0) < 0) {
        print_str("pipe failed\n");
        sys_exit(1);
    }

    long pid = sys_clone(17 /* SIGCHLD */, 0);
    if (pid < 0) {
        print_str("clone failed\n");
        sys_exit(1);
    }

    int iters = 20000;
    char token = 'A';

    if (pid == 0) {
        // Child
        sys_close(p1[1]);
        sys_close(p2[0]);
        for (int i = 0; i < iters; i++) {
            if (sys_read(p1[0], &token, 1) != 1) break;
            if (sys_write(p2[1], &token, 1) != 1) break;
        }
        sys_close(p1[0]);
        sys_close(p2[1]);
        sys_exit(0);
    } else {
        // Parent
        sys_close(p1[0]);
        sys_close(p2[1]);

        struct timespec ts1, ts2;
        sys_clock_gettime(1 /* CLOCK_MONOTONIC */, &ts1);
        for (int i = 0; i < iters; i++) {
            if (sys_write(p1[1], &token, 1) != 1) break;
            if (sys_read(p2[0], &token, 1) != 1) break;
        }
        sys_clock_gettime(1 /* CLOCK_MONOTONIC */, &ts2);

        int status = 0;
        sys_wait4((int)pid, &status, 0, 0);
        sys_close(p1[1]);
        sys_close(p2[0]);

        unsigned long long diff_ns = (ts2.tv_sec - ts1.tv_sec) * 1000000000ULL + (ts2.tv_nsec - ts1.tv_nsec);
        unsigned long long total_switches = iters * 2ULL;
        unsigned long long lat_ns = diff_ns / total_switches;
        unsigned long lat_us_int = lat_ns / 1000;
        unsigned long lat_us_dec = (lat_ns % 1000) / 10;

        print_str("Context switches: ");
        print_ulong(total_switches);
        print_str("\nLatency: ");
        print_ulong(lat_us_int);
        print_str(".");
        if (lat_us_dec < 10) print_str("0");
        print_ulong(lat_us_dec);
        print_str(" µs\n");

        sys_exit(0);
    }
}
