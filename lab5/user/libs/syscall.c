#include <defs.h>
#include <unistd.h>
#include <stdarg.h>
#include <syscall.h>

#define MAX_ARGS 5

static inline int
syscall(int64_t num, ...)
{
    va_list ap;
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i++)
    {
        a[i] = va_arg(ap, uint64_t);
    }
    va_end(ap);

    // 将num（系统调用编号）和数组a中的五个元素（参数）分别加载到寄存器a0到a5中，作为系统调用的参数
    // 执行ecall指令，触发一个异常，进入内核态，执行对应的系统调用
    // 将系统调用的返回值，存储在寄存器a0中，再保存到变量ret中
    asm volatile(
        "ld a0, %1\n"
        "ld a1, %2\n"
        "ld a2, %3\n"
        "ld a3, %4\n"
        "ld a4, %5\n"
        "ld a5, %6\n"
        "ecall\n"
        "sd a0, %0"
        : "=m"(ret)
        : "m"(num), "m"(a[0]), "m"(a[1]), "m"(a[2]), "m"(a[3]), "m"(a[4])
        : "memory");
    return ret;
}

int sys_exit(int64_t error_code)
{
    return syscall(SYS_exit, error_code);
}

int sys_fork(void)
{
    return syscall(SYS_fork);
}

int sys_wait(int64_t pid, int *store)
{
    return syscall(SYS_wait, pid, store);
}

int sys_yield(void)
{
    return syscall(SYS_yield);
}

int sys_kill(int64_t pid)
{
    return syscall(SYS_kill, pid);
}

int sys_getpid(void)
{
    return syscall(SYS_getpid);
}

int sys_putc(int64_t c)
{
    return syscall(SYS_putc, c);
}

int sys_pgdir(void)
{
    return syscall(SYS_pgdir);
}
