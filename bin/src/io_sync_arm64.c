/* Standalone AArch64 Linux 4KiB sync IOPS microbenchmark (nostdlib) */
struct timespec {
    long tv_sec;
    long tv_nsec;
};

static inline long sys_openat(int dirfd, const char *path, int flags, int mode) {
    register long x8 __asm__("x8") = 56;
    register long x0 __asm__("x0") = dirfd;
    register long x1 __asm__("x1") = (long)path;
    register long x2 __asm__("x2") = flags;
    register long x3 __asm__("x3") = mode;
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

static inline long sys_fdatasync(int fd) {
    register long x8 __asm__("x8") = 83;
    register long x0 __asm__("x0") = fd;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0) : "memory");
    return x0;
}

static inline long sys_close(int fd) {
    register long x8 __asm__("x8") = 57;
    register long x0 __asm__("x0") = fd;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0) : "memory");
    return x0;
}

static inline long sys_unlinkat(int dirfd, const char *path, int flags) {
    register long x8 __asm__("x8") = 35;
    register long x0 __asm__("x0") = dirfd;
    register long x1 __asm__("x1") = (long)path;
    register long x2 __asm__("x2") = flags;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0), "r"(x1), "r"(x2) : "memory");
    return x0;
}

static inline long sys_clock_gettime(int clk_id, struct timespec *ts) {
    register long x8 __asm__("x8") = 113;
    register long x0 __asm__("x0") = clk_id;
    register long x1 __asm__("x1") = (long)ts;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0), "r"(x1) : "memory");
    return x0;
}

static inline void sys_exit(int code) {
    register long x8 __asm__("x8") = 93;
    register long x0 __asm__("x0") = code;
    __asm__ volatile("svc 0" : : "r"(x8), "r"(x0) : "memory");
    while(1);
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

static char block_buf[4096] __attribute__((aligned(4096)));

void _start(void) {
    const char *path = "/data/local/tmp/pox_bench/tmp/io_sync_test.bin";
    // O_WRONLY|O_CREAT|O_TRUNC = 01|0100|01000 = 01101 = 577
    long fd = sys_openat(-100 /* AT_FDCWD */, path, 577, 0644);
    if (fd < 0) {
        print_str("open failed\n");
        sys_exit(1);
    }

    for (int i = 0; i < 4096; i++) {
        block_buf[i] = (char)(i & 0xFF);
    }

    int count = 200;
    struct timespec ts1, ts2;
    sys_clock_gettime(1 /* CLOCK_MONOTONIC */, &ts1);
    for (int i = 0; i < count; i++) {
        sys_write((int)fd, block_buf, 4096);
        sys_fdatasync((int)fd);
    }
    sys_clock_gettime(1 /* CLOCK_MONOTONIC */, &ts2);

    sys_close((int)fd);
    sys_unlinkat(-100, path, 0);

    unsigned long long diff_ns = (ts2.tv_sec - ts1.tv_sec) * 1000000000ULL + (ts2.tv_nsec - ts1.tv_nsec);
    unsigned long long iops = (count * 1000000000ULL) / diff_ns;

    print_str("Operations: ");
    print_ulong(count);
    print_str("\nIOPS: ");
    print_ulong(iops);
    print_str(".0\n");

    sys_exit(0);
}
