#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_fifo.h>
#include <list.h>

/* [维基百科] 最简单的页面置换算法（PRA）是FIFO算法。先进先出
 * 页面置换算法是一种低开销算法，需要操作系统进行少量簿记。
 * 这个想法从名称就很明显 - 操作系统跟踪内存中的所有页面，以队列的形式排列，最近到达的在后面，
 * 最早到达的在前面。当需要替换页面时，选择队列前端的页面（最早的页面）。
 * 尽管FIFO廉价且直观，但在实际应用中性能表现不佳。
 * 因此，它很少以未经修改的形式使用。该算法遇到了Belady的异常现象。
 *
 * FIFO PRA的详细信息
 * （1）准备：为了实现FIFO PRA，我们应该管理所有可交换的页面，以便
 *              可以根据时间顺序将这些页面链接到pra_list_head。
 *              首先，您应该熟悉list.h中的结构列表。struct list是一个简单的双向链表实现。
 *              您应该知道如何使用：list_init、list_add（list_add_after）、
 *              list_add_before、list_del、list_next、list_prev。
 *              另一个棘手的方法是将一般的列表结构转换为特殊结构（例如struct page）。
 *              您可以找到一些宏：le2page（在memlayout.h中），
 *              （在将来的实验中：le2vma（在vmm.h中）、le2proc（在proc.h中）等。
 */

list_entry_t pra_list_head;
/*
 * （2）_fifo_init_mm：初始化pra_list_head并使mm->sm_priv指向pra_list_head的地址。
 *              现在，从内存控制结构mm_struct中，我们可以访问FIFO PRA。
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{
    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
    // cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
    return 0;
}
/*
 * （3）_fifo_map_swappable：根据FIFO PRA，我们应该将最近到达的页面链接到pra_list_head队列的后面。
 */
static int
_fifo_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
    list_entry_t *entry = &(page->pra_page_link);

    assert(entry != NULL && head != NULL);
    // 记录页面访问情况

    //(1) 将最近到达的页面链接到pra_list_head队列的后面。
    list_add(head, entry);
    return 0;
}
/*
 * （4）_fifo_swap_out_victim：根据FIFO PRA，我们应该取消pra_list_head队列前面最早到达的页面的链接，
 * 然后将该页面的地址设置为ptr_page。
 */
static int
_fifo_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
{
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
    assert(head != NULL);
    assert(in_tick == 0);
    /* 选择牺牲品 */
    //(1) 取消pra_list_head队列前面最早到达的页面的链接
    //(2) 将该页面的地址设置为ptr_page
    list_entry_t *entry = list_prev(head);
    if (entry != head)
    {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    }
    else
    {
        *ptr_page = NULL;
    }
    return 0;
}

static int
_fifo_check_swap(void)
{
    cprintf("write Virt Page c in fifo_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 4);
    cprintf("write Virt Page a in fifo_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 4);
    cprintf("write Virt Page d in fifo_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 4);
    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 4);
    cprintf("write Virt Page e in fifo_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 5);
    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 5);
    cprintf("write Virt Page a in fifo_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 6);
    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 7);
    cprintf("write Virt Page c in fifo_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 8);
    cprintf("write Virt Page d in fifo_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 9);
    cprintf("write Virt Page e in fifo_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 10);
    cprintf("write Virt Page a in fifo_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 11);
    return 0;
}

static int
_fifo_init(void)
{
    return 0;
}

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_fifo_tick_event(struct mm_struct *mm)
{
    return 0;
}

struct swap_manager swap_manager_fifo =
    {
        .name = "fifo swap manager",
        .init = &_fifo_init,
        .init_mm = &_fifo_init_mm,
        .tick_event = &_fifo_tick_event,
        .map_swappable = &_fifo_map_swappable,
        .set_unswappable = &_fifo_set_unswappable,
        .swap_out_victim = &_fifo_swap_out_victim,
        .check_swap = &_fifo_check_swap,
};
