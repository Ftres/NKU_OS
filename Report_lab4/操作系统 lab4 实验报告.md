# 操作系统 lab4 实验报告

小组成员：

- 2110408 吴振华

- 2112426 怀硕

- 2113635 王祎宁

---

## 实验目的

- 了解内核线程创建/执行的管理过程
- 了解内核线程的切换和基本调度过程

----

## 实验内容

实验2/3完成了物理和虚拟内存管理，这给创建内核线程（内核线程是一种特殊的进程）打下了提供内存管理的基础。当一个程序加载到内存中运行时，首先通过ucore OS的内存管理子系统分配合适的空间，然后就需要考虑如何分时使用CPU来“并发”执行多个程序，让每个运行的程序（这里用线程或进程表示）“感到”它们各自拥有“自己”的CPU。

本次实验将首先接触的是内核线程的管理。内核线程是一种特殊的进程，内核线程与用户进程的区别有两个：

- 内核线程只运行在内核态
- 用户进程会在在用户态和内核态交替运行
- 所有内核线程共用ucore内核内存空间，不需为每个内核线程维护单独的内存空间
- 而用户进程需要维护各自的用户内存空间

相关原理介绍可看附录B：【原理】进程/线程的属性与特征解析。

### 提前说明

需要注意的是，在ucore的调度和执行管理中，**对线程和进程做了统一的处理**。且由于ucore内核中的所有内核线程共享一个内核地址空间和其他资源，所以这些内核线程从属于同一个唯一的内核进程，即ucore内核本身。

---

## 实验报告要求

对实验报告的要求：

- 填写各个基本练习中要求完成的报告内容

- 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）

- 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

----

## 练习

对实验报告的要求：

- 基于markdown格式来完成，以文本方式为主
- 填写各个基本练习中要求完成的报告内容
- 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
- 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

### 练习0：填写已有实验

本实验依赖实验2/3。请把你做的实验2/3的代码填入本实验中代码中有“LAB2”,“LAB3”的注释相应部分。

对于三个文件进行相应代码的补充：

- default_pmm.c

- vmm.c

- swap_fifo.c

### 练习1：分配并初始化一个进程控制块（需要编码）

alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

> 【提示】在alloc_proc函数的实现中，需要初始化的proc_struct结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明proc_struct中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

#### 进程控制块

在实验四中，进程管理信息用struct proc_struct表示，在*kern/process/proc.h*中定义如下：

```c
struct proc_struct {
    enum proc_state state;                  // Process state 进程状态
    int pid;                                // Process ID 进程号
    int runs;                               // the running times of Proces 进程运行的次数
    uintptr_t kstack;                       // Process kernel stack 进程的内核栈地址
    volatile bool need_resched;             // bool value: need to be rescheduled to release CPU? 是否需要schedule
    struct proc_struct *parent;             // the parent process 父进程
    struct mm_struct *mm;                   // Process's memory management field 进程的内存管理块
    struct context context;                 // Switch here to run process 上下文
    struct trapframe *tf;                   // Trap frame for current interrupt 进程的中断帧
    uintptr_t cr3;                          // CR3 register: the base addr of Page Directroy Table(PDT) 页表的基址
    uint32_t flags;                         // Process flag 进程的flag值
    char name[PROC_NAME_LEN + 1];           // Process name 进程名称
    list_entry_t list_link;                 // Process link list 进程链表
    list_entry_t hash_link;                 // Process hash list 进程哈希表
};
```

各个变量：

- state：进程状态，proc.h中定义了四种状态：创建（UNINIT）、睡眠（SLEEPING）、就绪（RUNNABLE）、退出（ZOMBIE，等待父进程回收其资源）
- pid：进程ID，调用本函数时尚未指定，默认值设为-1
- runs：线程运行总数，默认值0
- need_resched：标志位，表示该进程是否需要重新参与调度以释放CPU，初值0（false，表示不需要）
- parent：父进程控制块指针，初值NULL
- mm：用户进程虚拟内存管理单元指针，由于系统进程没有虚存，其值为NULL
- context：进程上下文，默认值全零
- tf：中断帧指针，默认值NULL
- cr3：该进程页目录表的基址寄存器，初值为ucore启动时建立好的内核虚拟空间的页目录表首地址boot_cr3（在kern/mm/pmm.c的pmm_init函数中初始化）
- flags：进程标志位，默认值0
- name：进程名数组

比较重要的成员变量：

- `mm`：这里面保存了内存管理的信息，包括内存映射，虚存管理等内容。
  
  ```c
  struct mm_struct {
      list_entry_t mmap_list;        // linear list link which sorted by start addr of vma
      struct vma_struct *mmap_cache; // current accessed vma, used for speed purpose
      pde_t *pgdir;                  // the PDT of these vma
      int map_count;                 // the count of these vma
      void *sm_priv;                 // the private data for swap manager
  };
  ```

- `state`：进程所处的状态。uCore中进程状态有四种：
  
  - `PROC_UNINIT`
  
  - `PROC_SLEEPING`
  
  - `PROC_RUNNABLE`
  
  - `PROC_ZOMBIE`。

- `parent`：进程的父进程的指针。在内核中，**只有内核创建的idle进程没有父进程**，其他进程都有父进程。进程的父子关系组成了一棵进程树，这种父子关系有利于维护父进程对于子进程的一些特殊操作。

- `context`：进程执行的上下文，即几个关键的寄存器的值。这些寄存器的值用于在进程切换中还原之前进程的运行状态。

- `tf`：进程的中断帧。**当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中**（注意这里需要保存的执行状态数量不同于上下文切换）。系统调用可能会改变用户寄存器的值，我们可以通过调整中断帧来使得系统调用返回特定的值。

- `cr3`：`cr3`寄存器是x86架构的特殊寄存器，用来保存页表所在的基址。出于legacy的原因，这里仍然保留了这个名字，但其值仍然是页表基址所在的位置。

- `kstack`: 每个线程都有一个内核栈，并且位于内核地址空间的不同位置。
  
  - 对于内核线程，该栈就是运行时的程序使用的栈；
  
  - 对于普通进程，该栈是发生特权级改变的时候使保存被打断的硬件信息用的栈。
  
  uCore在创建进程时分配了 2 个连续的物理页（memlayout.h中KSTACKSIZE定义）作为内核栈的空间。这个栈很小，所以内核中的代码应该尽可能的紧凑，并且避免在栈上分配大的数据结构，以免栈溢出，导致系统崩溃。
  
  kstack记录了分配给该进程/线程的内核栈的位置。主要作用有以下几点：
  
  - 首先，当内核准备从一个进程切换到另一个的时候，需要根据kstack 的值正确的设置好 tss （可以回顾一下在实验一中讲述的 tss 在中断处理过程中的作用），以便在进程切换以后再发生中断时能够使用正确的栈。
  
  - 其次，内核栈位于内核地址空间，并且是不共享的（每个线程都拥有自己的内核栈），因此不受到 mm 的管理，当进程退出的时候，内核能够根据 kstack 的值快速定位栈的位置并进行回收。

为了管理系统中所有的进程控制块，uCore维护了如下全局变量（位于*kern/process/proc.c*）：

● static struct proc *current：当前占用CPU且处于“运行”状态进程控制块指针。通常这个变量是只读的，只有在进程切换的时候才进行修改，并且整个切换和修改过程需要保证操作的原子性，目前至少需要屏蔽中断。

● static struct proc *initproc：本实验中，指向一个内核线程。本实验以后，此指针将指向第一个用户态进程。

● static list_entry_t hash_list[HASH_LIST_SIZE]：所有进程控制块的哈希表，proc_struct中的成员变量hash_link将基于pid链接入这个哈希表中。

● list_entry_t proc_list：所有进程控制块的双向线性列表，proc_struct中的成员变量list_link将链接入这个链表中。

#### 进程上下文

进程上下文使用结构体`struct context`保存，其中包含了`ra`，`sp`，`s0~s11`共14个寄存器。

为什么不需要保存所有的寄存器呢？这里巧妙地利用了编译器对于函数的处理。寄存器可以分为调用者保存（caller-saved）寄存器和被调用者保存（callee-saved）寄存器。因为线程切换在一个函数当中，所以编译器会自动帮助我们生成保存和恢复调用者保存寄存器的代码，在实际的进程切换过程中我们只需要保存被调用者保存寄存器.

#### 补充代码：

```c
// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL)
    {
        // LAB4:EXERCISE1 YOUR CODE
        /*
         * below fields in proc_struct need to be initialized
         *       enum proc_state state;                      // Process state
         *       int pid;                                    // Process ID
         *       int runs;                                   // the running times of Proces
         *       uintptr_t kstack;                           // Process kernel stack
         *       volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
         *       struct proc_struct *parent;                 // the parent process
         *       struct mm_struct *mm;                       // Process's memory management field
         *       struct context context;                     // Switch here to run process
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        memset(proc, 0, sizeof(struct proc_struct));     // 结构体中的大多数成员变量在初始化时置 0 即可
        proc->state = PROC_UNINIT;                       // 设置进程为“初始”态,进程状态设置为 PROC_UNINIT
        proc->pid = -1;                                  // 设置进程pid的未初始化值,pid 赋值为 -1，表示进程尚不存在
        proc->cr3 = boot_cr3;                            // 内核态进程的公用页目录表,使用内核页目录表的基址

    }
    return proc;
}
```

- 结构体中的大多数成员变量在初始化时置 0 即可

- proc->state = PROC_UNINIT; ==> 设置进程为“初始”态,进程状态设置为 PROC_UNINIT

- proc->pid = -1; ==> 设置进程pid的未初始化值,pid 赋值为 -1，表示进程尚不存在

- proc->cr3 = boot_cr3; ==> 内核态进程的公用页目录表,使用内核页目录表的基址

##### Question 请说明proc_struct中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

- `context`：进程执行的上下文，即几个关键的寄存器的值。这些寄存器的值用于在进程切换中还原之前进程的运行状态。
  
  寄存器列表如下：
  
  ```c
  struct context {
      uintptr_t ra;
      uintptr_t sp;
      uintptr_t s0;
      uintptr_t s1;
      uintptr_t s2;
      uintptr_t s3;
      uintptr_t s4;
      uintptr_t s5;
      uintptr_t s6;
      uintptr_t s7;
      uintptr_t s8;
      uintptr_t s9;
      uintptr_t s10;
      uintptr_t s11;
  };
  ```

- `tf`：进程的中断帧。**当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中**（这里需要保存的执行状态数量不同于上下文切换）。系统调用可能会改变用户寄存器的值，可以通过调整中断帧来使得系统调用返回特定的值。

```c
struct pushregs {
    uintptr_t zero;  // Hard-wired zero
    uintptr_t ra;    // Return address
    uintptr_t sp;    // Stack pointer
    uintptr_t gp;    // Global pointer
    uintptr_t tp;    // Thread pointer
    uintptr_t t0;    // Temporary
    uintptr_t t1;    // Temporary
    uintptr_t t2;    // Temporary
    uintptr_t s0;    // Saved register/frame pointer
    uintptr_t s1;    // Saved register
    uintptr_t a0;    // Function argument/return value
    uintptr_t a1;    // Function argument/return value
    uintptr_t a2;    // Function argument
    uintptr_t a3;    // Function argument
    uintptr_t a4;    // Function argument
    uintptr_t a5;    // Function argument
    uintptr_t a6;    // Function argument
    uintptr_t a7;    // Function argument
    uintptr_t s2;    // Saved register
    uintptr_t s3;    // Saved register
    uintptr_t s4;    // Saved register
    uintptr_t s5;    // Saved register
    uintptr_t s6;    // Saved register
    uintptr_t s7;    // Saved register
    uintptr_t s8;    // Saved register
    uintptr_t s9;    // Saved register
    uintptr_t s10;   // Saved register
    uintptr_t s11;   // Saved register
    uintptr_t t3;    // Temporary
    uintptr_t t4;    // Temporary
    uintptr_t t5;    // Temporary
    uintptr_t t6;    // Temporary
};

struct trapframe {
    struct pushregs gpr;
    uintptr_t status;
    uintptr_t epc;
    uintptr_t badvaddr;
    uintptr_t cause;
};
```

----

### 练习2：为新创建的内核线程分配资源（需要编码）

创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用**do_fork**函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们**实际需要"fork"的东西就是stack和trapframe**。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：

- 调用alloc_proc，首先获得一块用户信息块。
- 为进程分配一个内核栈。
- 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
- 复制原进程上下文到新进程
- 将新进程添加到进程列表
- 唤醒新进程
- 返回新进程号

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

补充代码：

```c
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
    {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    // LAB4:EXERCISE2 YOUR CODE
    /*
     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
     *                 setup the kernel entry point and stack of process
     *   hash_proc:    add proc into proc hash_list
     *   get_pid:      alloc a unique pid for process
     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
     * VARIABLES:
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */

    //    1. call alloc_proc to allocate a proc_struct
    //   分配并初始化进程控制块（alloc_proc函数）
    if ((proc = alloc_proc()) == NULL)
    {
        goto fork_out;
    }
    proc->parent = current; // 设置父进程

    //    2. call setup_kstack to allocate a kernel stack for child process
    //    分配并初始化内核栈（setup_stack函数）
    if (setup_kstack(proc) != 0)
    {
        goto bad_fork_cleanup_proc;
    }

    //    3. call copy_mm to dup OR share mm according clone_flag
    //    根据clone_flags决定是复制还是共享内存管理系统（copy_mm函数）
    if (copy_mm(clone_flags, proc) != 0)
    {
        goto bad_fork_cleanup_kstack;
    }

    //    4. call copy_thread to setup tf & context in proc_struct
    //    设置进程的中断帧和上下文（copy_thread函数）
    copy_thread(proc, stack, tf);

    //    5. insert proc_struct into hash_list && proc_list
    //    把设置好的进程加入链表
    bool intr_flag;
    local_intr_save(intr_flag); //禁止中断
    {
        proc->pid = get_pid();
        hash_proc(proc);
        list_add(&proc_list, &(proc->list_link));
        nr_process++;
    }
    local_intr_restore(intr_flag); //恢复中断

    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    将新建的进程设为就绪态
    wakeup_proc(proc);

    //    7. set ret vaule using child proc's pid
    //    将返回值设为线程id
    ret = proc->pid;

fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```

##### Question 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

分配id：`proc->pid = get_pid();`，聚焦于`get_pid`函数：

```c
// get_pid - alloc a unique pid for process
static int
get_pid(void)
{
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    if (++last_pid >= MAX_PID)
    {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe)
    {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list)
        {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid)
            {
                if (++last_pid >= next_safe)
                {
                    if (last_pid >= MAX_PID)
                    {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid)
            {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}
```

这段代码会不断的在链表中遍历，直到找到一个合适的last_pid才会返回，这个last_pid满足两个条件:

- 不大于MAX_PID

- 未被分配过

因此ucore为每个新fork的线程分配了一个唯一的id。

----

### 练习3：编写proc_run 函数（需要编码）

proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

- 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
- 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。
- 切换当前进程为要运行的进程。
- 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lcr3(unsigned int cr3)`函数，可实现修改CR3寄存器值的功能。
- 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。
- 允许中断。

请回答如下问题：

- 在本实验的执行过程中，创建且运行了几个内核线程？

代码补充：

```c
// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
void proc_run(struct proc_struct *proc)
{
    // 首先判断要切换到的进程是不是当前进程，若是则不需进行任何处理。
    // 调用local_intr_save和local_intr_restore函数去使能中断，避免在进程切换过程中出现中断。
    if (proc != current)
    {
        // LAB4:EXERCISE3 YOUR CODE
        /*
         * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
         * MACROs or Functions:
         *   local_intr_save():        Disable interrupts
         *   local_intr_restore():     Enable Interrupts
         *   lcr3():                   Modify the value of CR3 register
         *   switch_to():              Context switching between two processes
         */
        struct proc_struct *prev = current, *next = proc;
        bool intr_flag;
        local_intr_save(intr_flag);
        {
            // 将当前进程设为传入的进程
            current = proc;
            // 修改页表项
            // 重新加载 cr3 寄存器(页目录表基址) 进行进程间的页表切换
            lcr3(next->cr3);
            // 使用 switch_to 进行上下文切换。
            switch_to(&(prev->context), &(next->context));
        }
        local_intr_restore(intr_flag);
    }
}
```

##### switch_to:

首先把当前寄存器的值送到原线程的 context 中保存，再将新线程的 context 赋予各寄存器。

```asm
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
    STORE sp, 1*REGBYTES(a0)
    STORE s0, 2*REGBYTES(a0)
    STORE s1, 3*REGBYTES(a0)
    STORE s2, 4*REGBYTES(a0)
    STORE s3, 5*REGBYTES(a0)
    STORE s4, 6*REGBYTES(a0)
    STORE s5, 7*REGBYTES(a0)
    STORE s6, 8*REGBYTES(a0)
    STORE s7, 9*REGBYTES(a0)
    STORE s8, 10*REGBYTES(a0)
    STORE s9, 11*REGBYTES(a0)
    STORE s10, 12*REGBYTES(a0)
    STORE s11, 13*REGBYTES(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
    LOAD sp, 1*REGBYTES(a1)
    LOAD s0, 2*REGBYTES(a1)
    LOAD s1, 3*REGBYTES(a1)
    LOAD s2, 4*REGBYTES(a1)
    LOAD s3, 5*REGBYTES(a1)
    LOAD s4, 6*REGBYTES(a1)
    LOAD s5, 7*REGBYTES(a1)
    LOAD s6, 8*REGBYTES(a1)
    LOAD s7, 9*REGBYTES(a1)
    LOAD s8, 10*REGBYTES(a1)
    LOAD s9, 11*REGBYTES(a1)
    LOAD s10, 12*REGBYTES(a1)
    LOAD s11, 13*REGBYTES(a1)

    ret
```

##### Question ：在本实验的执行过程中，创建且运行了几个内核线程？

有两个内核线程: 

- **1） 创建第0个内核线程idleproc**。在 init.c::kern_init 函数调用了 proc.c::proc_init 函数。 proc_init 函数启动了创建内核线程的步骤。首先当前的执行上下文（从 kern_init 启动至今）就可以看成是 uCore 内核（也可看做是内核进程）中的一个内核线程的上下文。为此，uCore 通过给当前执行的上下文分配一个进程控制块以及对它进行相应初始化，将其打造成第 0 个内核线程 – idleproc。

- **2） 创建第 1 个内核线程 initproc**。第 0 个内核线程主要工作是完成内核中各个子系统的初始化，然后就通过执行 cpu_idle 函数开始过退休生活了。所以 uCore 接下来还需创建其他进程来完成各种工作，但 idleproc 内核子线程自己不想做，于是就通过调用 kernel_thread 函数创建了一个内核线程 init_main。在Lab4中，这个子内核线程的工作就是输出一些字符串，然后就返回了（参看 init_main 函数）。但在后续的实验中，init_main 的工作就是创建特定的其他内核线程或用户进程。

```c
// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
    cprintf("To U: \"%s\".\n", (const char *)arg);
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
    return 0;
}
```

----

### 扩展练习 Challenge：

- 说明语句`local_intr_save(intr_flag);....local_intr_restore(intr_flag);`是如何实现开关中断的？

这两个函数实现的意义就是**避免在进程切换过程中处理中断**。因为有些过程是互斥的，只允许一个线程进入，因此需要关闭中断来处理临界区；如果此时在切换过程中又一次中断的话，那么该进程保存的值就很可能出bug并且丢失难寻回了。

实现代码如下：

```c
static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
    {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
    {
        intr_enable();
    }
}

#define local_intr_save(x) \
    do                     \
    {                      \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);
```

简单来说，local_intr_save(intr_flag)会禁用中断，并将intr_flag设为true（如果调用了intr_disable()）。后续local_intr_restore(intr_flag)会根据flag值使能中断。

首先，让我们逐步分析一下这段代码的主要部分：

1. `__intr_save` 函数：
   
   - `read_csr(sstatus)` 用于读取 sstatus 寄存器的值，该寄存器包含了中断相关的状态信息。
   - `SSTATUS_SIE` 是一个宏，表示 Supervisor Interrupt Enable，即允许中断。
   - 如果当前中断被允许（sstatus 寄存器的 SIE 位为 1），则通过 `intr_disable()` 关闭中断，并返回 1 表示中断状态已保存。
   - 如果当前中断被禁止（sstatus 寄存器的 SIE 位为 0），则直接返回 0，表示中断状态未保存。

2. `__intr_restore` 函数：
   
   - 如果 `flag` 参数为真，表示在调用 `__intr_save` 时中断状态已保存，那么通过 `intr_enable()` 恢复中断。

3. 宏 `local_intr_save`：
   
   - 这个宏的作用是将中断状态保存到变量 `x` 中。在宏展开时，调用了 `__intr_save` 函数，将返回值保存到 `x` 中。

4. 宏 `local_intr_restore`：
   
   - 这个宏的作用是根据保存的中断状态进行中断的恢复操作。在宏展开时，调用了 `__intr_restore` 函数，并传入保存的中断状态 `x`。

`local_intr_save` 用于保存当前中断状态，并在需要时通过 `local_intr_restore` 恢复之前保存的中断状态。这种方式通常用于在一段代码执行期间禁用中断，执行一些临界区代码，然后恢复中断状态，以确保在临界区代码执行期间不被中断打断。
