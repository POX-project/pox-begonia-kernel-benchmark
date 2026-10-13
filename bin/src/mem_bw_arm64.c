/* Standalone AArch64 Linux memory copy bandwidth benchmark (nostdlib) */
struct timespec {
    long tv_sec;
    long tv_nsec;
};

static inline void *sys_mmap(void *addr, unsigned long length, int prot, int flags, int fd, unsigned long offset) {
    register long x8 __asm__("x8") = 222;
    register long x0 __asm__("x0") = (long)addr;
    register long x1 __asm__("x1") = length;
    register long x2 __asm__("x2") = prot;
    register long x3 __asm__("x3") = flags;
    register long x4 __asm__("x4") = fd;
    register long x5 __asm__("x5") = offset;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0), "r"(x1), "r"(x2), "r"(x3), "r"(x4), "r"(x5) : "memory");
    return (void *)x0;
}

static inline long sys_munmap(void *addr, unsigned long length) {
    register long x8 __asm__("x8") = 215;
    register long x0 __asm__("x0") = (long)addr;
    register long x1 __asm__("x1") = length;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0), "r"(x1) : "memory");
    return x0;
}

static inline long sys_clock_gettime(int clk_id, struct timespec *ts) {
    register long x8 __asm__("x8") = 113;
    register long x0 __asm__("x0") = clk_id;
    register long x1 __asm__("x1") = (long)ts;
    __asm__ volatile("svc 0" : "=r"(x0) : "r"(x8), "0"(x0), "r"(x1) : "memory");
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
    unsigned long size_mb = 64;
    unsigned long bytes = size_mb * 1024 * 1024;

    unsigned long *src = (unsigned long *)sys_mmap(0, bytes, 3, 0x22, -1, 0);
    unsigned long *dst = (unsigned long *)sys_mmap(0, bytes, 3, 0x22, -1, 0);

    if ((long)src < 0 || ((long)dst < 0)) {
        print_str("mmap failed\n");
        sys_exit(1);
    }

    // Initialize and touch pages
    unsigned long words = bytes / 8;
    for (unsigned long i = 0; i < words; i++) {
        src[i] = 0xAA55AA55AA55AA55ULL;
        dst[i] = 0;
    }

    int loops = 10;
    struct timespec ts1, ts2;
    sys_clock_gettime(1 /* CLOCK_MONOTONIC */, &ts1);
    for (int l = 0; l < loops; l++) {
        for (unsigned long i = 0; i < words; i += 8) {
            dst[i] = src[i];
            dst[i+1] = src[i+1];
            dst[i+2] = src[i+2];
            dst[i+3] = src[i+3];
            dst[i+4] = src[i+4];
            dst[i+5] = src[i+5];
            dst[i+6] = src[i+6];
            dst[i+7] = src[i+7];
        }
    }
    sys_clock_gettime(1 /* CLOCK_MONOTONIC */, &ts2);

    sys_munmap(src, bytes);
    sys_munmap(dst, bytes);

    unsigned long long diff_ns = (ts2.tv_sec - ts1.tv_sec) * 1000000000ULL + (ts2.tv_nsec - ts1.tv_nsec);
    unsigned long long total_mb = size_mb * (unsigned long long)loops;
    // throughput in MiB/s = (total_mb * 1,000,000,000) / diff_ns
    unsigned long long mib_per_sec = (total_mb * 1000000000ULL) / diff_ns;

    print_str("Transferred: ");
    print_ulong(total_mb);
    print_str(" MiB\nThroughput: ");
    print_ulong(mib_per_sec);
    print_str(".0 MiB/s\n");

    sys_exit(0);
}
