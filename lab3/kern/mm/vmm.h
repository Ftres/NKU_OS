#ifndef __KERN_MM_VMM_H__
#define __KERN_MM_VMM_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <sync.h>

// 预定义
struct mm_struct;

// 虚拟连续内存区域（vma），[vm_start，vm_end），

// 属于vma的地址表示 vma.vm_start <= addr < vma.vm_end
struct vma_struct {
    struct mm_struct *vm_mm; // 使用相同PDT的vma集合
    uintptr_t vm_start;      // vma的起始地址
    uintptr_t vm_end;        // vma的结束地址，不包括vm_end本身
    uint_t vm_flags;       // vma的标志
    list_entry_t list_link;  // 通过vma的起始地址排序的线性链表链接
};

#define le2vma(le, member)                  \
    to_struct((le), struct vma_struct, member)

#define VM_READ                 0x00000001
#define VM_WRITE                0x00000002
#define VM_EXEC                 0x00000004

// 控制一组使用相同PDT的vma的结构
struct mm_struct {
    list_entry_t mmap_list;        // 通过vma的起始地址排序的线性链表链接
    struct vma_struct *mmap_cache; // 当前访问的vma，用于提高速度
    pde_t *pgdir;                  // 这些vma的PDT
    int map_count;                 // 这些vma的计数
    void *sm_priv;                 // 用于交换管理器的私有数据
};

struct vma_struct *find_vma(struct mm_struct *mm, uintptr_t addr);
struct vma_struct *vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags);
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma);

struct mm_struct *mm_create(void);
void mm_destroy(struct mm_struct *mm);

void vmm_init(void);

int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr);

extern volatile unsigned int pgfault_num;
extern struct mm_struct *check_mm_struct;

#endif /* !__KERN_MM_VMM_H__ */
