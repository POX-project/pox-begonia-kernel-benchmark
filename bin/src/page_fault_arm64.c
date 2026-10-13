/* Standalone AArch64 Linux page fault latency microbenchmark (nostdlib) */
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
    unsigned long pages = 10000;
    unsigned long page_size = 4096;
    unsigned long bytes = pages * page_size;

    // PROT_READ|PROT_WRITE = 3, MAP_PRIVATE|MAP_ANONYMOUS = 0x22
    volatile char *buf = (volatile char *)sys_mmap(0, bytes, 3, 0x22, -1, 0);
    if ((long)buf < 0) {
        print_str("mmap failed\n");
        sys_exit(1);
    }

    struct timespec ts1, ts2;
    sys_clock_gettime(1 /* CLOCK_MONOTONIC */, &ts1);
    for (unsigned long i = 0; i < pages; i++) {
        buf[i * page_size] = (char)(i & 0xFF);
    }
    sys_clock_gettime(1 /* CLOCK_MONOTONIC */, &ts2);

    sys_munmap((void *)buf, bytes);

    unsigned long long diff_ns = (ts2.tv_sec - ts1.tv_sec) * 1000000000ULL + (ts2.tv_nsec - ts1.tv_nsec);
    unsigned long long lat_ns = diff_ns / pages;
    unsigned long lat_us_int = lat_ns / 1000;
    unsigned long lat_us_dec = (lat_ns % 1000) / 10;

    print_str("Pages: ");
    print_ulong(pages);
    print_str("\nLatency: ");
    print_ulong(lat_us_int);
    print_str(".");
    if (lat_us_dec < 10) print_str("0");
    print_ulong(lat_us_dec);
    print_str(" µs\n");

    sys_exit(0);
}
