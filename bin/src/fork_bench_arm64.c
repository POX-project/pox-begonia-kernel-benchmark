/* Standalone AArch64 Linux kernel clone/fork latency microbenchmark (nostdlib) */

struct timespec {
    long tv_sec;
    long tv_nsec;
};

static inline long sys_clock_gettime(int clk_id, struct timespec *tp) {
    register long x8 __asm__("x8") = 113;
    register long x0 __asm__("x0") = clk_id;
    register long x1 __asm__("x1") = (long)tp;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0), "r"(x1) : "memory");
    return x0;
}

static inline void sys_exit(int code) {
    register long x8 __asm__("x8") = 93;
    register long x0 __asm__("x0") = code;
    __asm__ volatile("svc 0" : : "r"(x8), "r"(x0) : "memory");
    while(1);
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

static inline long sys_wait4(long pid, int *status, int options, void *rusage) {
    register long x8 __asm__("x8") = 260;
    register long x0 __asm__("x0") = pid;
    register long x1 __asm__("x1") = (long)status;
    register long x2 __asm__("x2") = options;
    register long x3 __asm__("x3") = (long)rusage;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0), "r"(x1), "r"(x2), "r"(x3) : "memory");
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

static void print_str(const char *s) {
    unsigned long len = 0;
    while(s[len]) len++;
    sys_write(1, s, len);
}

static void print_ulong(unsigned long n) {
    char buf[32];
    int idx = 30;
    buf[31] = '\0';
    if (n == 0) { buf[idx--] = '0'; }
    else {
        while (n > 0) {
            buf[idx--] = '0' + (n % 10);
            n /= 10;
        }
    }
    print_str(&buf[idx + 1]);
}

void _start(int argc, char **argv) {
    int iters = 500;
    struct timespec start, end;

    sys_clock_gettime(1 /* CLOCK_MONOTONIC */, &start);

    for (int i = 0; i < iters; i++) {
        long pid = sys_clone(17 /* SIGCHLD */, 0);
        if (pid == 0) {
            sys_exit(0);
        } else if (pid > 0) {
            int status = 0;
            sys_wait4(pid, &status, 0, 0);
        }
    }

    sys_clock_gettime(1, &end);

    long total_ns = (end.tv_sec - start.tv_sec) * 1000000000L + (end.tv_nsec - start.tv_nsec);
    unsigned long avg_ns = (unsigned long)(total_ns / iters);
    unsigned long whole_ms = avg_ns / 1000000;
    unsigned long frac_ms = (avg_ns % 1000000) / 10000;

    print_str("Iterations: ");
    print_ulong(iters);
    print_str("\n");

    print_str("Fork Latency: ");
    print_ulong(whole_ms);
    print_str(".");
    if (frac_ms < 10) print_str("0");
    print_ulong(frac_ms);
    print_str(" ms\n");

    sys_exit(0);
}
