#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>
#include <buddy_system_pmm.h>
#include <stdio.h>

// 来自参考链接的一些宏定义
#define LEFT_LEAF(index) ((index) * 2 + 1)
#define RIGHT_LEAF(index) ((index) * 2 + 2)
#define PARENT(index) (((index) + 1) / 2 - 1)

// offset=(index+1)*node_size – size。
// 式中索引的下标均从0开始，size为内存总大小，node_size为内存块对应大小。

#define IS_POWER_OF_2(x) (!((x) & ((x)-1)))      // 检查x是否是2的幂
#define MAX(a, b) ((a) > (b) ? (a) : (b))        // 返回a,b中的最大值
#define UINT32_SHR_OR(a, n) ((a) | ((a) >> (n))) // 右移n位

#define UINT32_MASK(a) (UINT32_SHR_OR(UINT32_SHR_OR(UINT32_SHR_OR(UINT32_SHR_OR(UINT32_SHR_OR(a, 1), 2), 4), 8), 16))
#define UINT32_REMAINDER(a) ((a) & (UINT32_MASK(a) >> 1))                            // 大于a的一个最小的2^k
#define UINT32_ROUND_DOWN(a) (UINT32_REMAINDER(a) ? ((a)-UINT32_REMAINDER(a)) : (a)) // 小于a的最大的2^k

static unsigned fixsize(unsigned size)
{
    size |= size >> 1;
    size |= size >> 2;
    size |= size >> 4;
    size |= size >> 8;
    size |= size >> 16;
    return size + 1;
} // return一个大于size的二的幂

struct buddy2
{
    unsigned size;    // 表明管理内存
    unsigned longest; // 其两个子节点中最大的连续空间大小
};
// 存放二叉树的数组，用于内存分配
struct buddy2 root[10000];

//先初始化双链表
free_area_t free_area;
#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

struct allocRecord // 记录分配块的信息
{
    struct Page *base;
    int offset;
    size_t nr; // 块大小，即包含了多少页
};

struct allocRecord rec[80000]; // 存放偏移量的数组
int nr_block;                  // 已分配的块数

// 初始化全局的 free_list和 nr_free
static void buddy_init()
{
    list_init(&free_list);
    nr_free = 0;
}

// 再初始化buddy system的数组
void buddy_new(int size)
{
    unsigned node_size; // 传入的size是这个buddy system表示的总空闲空间；node_size是对应节点所表示的空闲空间的块数
    int i;
    nr_block = 0;
    if (size < 1 || !IS_POWER_OF_2(size))
        return;

    root[0].size = size;
    node_size = size * 2; // 认为总结点数是size*2

    for (i = 0; i < 2 * size - 1; ++i)
    {
        if (IS_POWER_OF_2(i + 1)) // 如果i+1是2的倍数，那么该节点所表示的二叉树就要到下一层了
            node_size /= 2;
        root[i].longest = node_size; // longest是该节点所表示的初始空闲空间块数
    }
    return;
}

// 初始化内存映射关系
// 添加每一页到 free_list中
static void
buddy_init_memmap(struct Page *base, size_t n)
{
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++)
    {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 1;
        set_page_ref(p, 0); // 表明空闲可用
        SetPageProperty(p);
        // 向双链表中加入页的管理部分
        list_add_before(&free_list, &(p->page_link));
    }
    nr_free += n;
    int allocpages = UINT32_ROUND_DOWN(n);
    // 初始化二叉树
    // 传入所需要表示的总内存页大小，让buddy system的数组得以初始化
    buddy_new(allocpages);
}

// 内存分配
// 二叉树中找到一个合适的块，将其标记为已使用，并返回偏移量。
// 分配的逻辑是：首先在buddy的“二叉树”结构中找到应该分配的物理页在整个实际双向链表中的位置
// 而后把相应的page进行标识表明该物理页已经分出去了
int buddy2_alloc(struct buddy2 *self, int size)
{                       // size就是这次要分配的物理页大小
    unsigned index = 0; // 节点的标号
    unsigned node_size; // 用于后续循环寻找合适的节点
    unsigned offset = 0;

    if (self == NULL) // 无法分配
        return -1;

    if (size <= 0) // 分配不合理
        size = 1;
    else if (!IS_POWER_OF_2(size)) // 不为2的幂时，取比size更大的2的n次幂
        size = fixsize(size);

    if (self[index].longest < size) // 根据根节点的longest，发现可分配内存不足，也返回
        return -1;

    // 从根节点开始，向下寻找左右子树里面找到最合适的节点
    for (node_size = self->size; node_size != size; node_size /= 2)
    {
        if (self[LEFT_LEAF(index)].longest >= size)
        {
            if (self[RIGHT_LEAF(index)].longest >= size)
            {
                index = self[LEFT_LEAF(index)].longest <= self[RIGHT_LEAF(index)].longest ? LEFT_LEAF(index) : RIGHT_LEAF(index);
                // 找到两个相符合的节点中内存较小的结点
            }
            else
            {
                index = LEFT_LEAF(index);
            }
        }
        else
            index = RIGHT_LEAF(index);
    }

    self[index].longest = 0;                       // 标记节点为已使用
    offset = (index + 1) * node_size - self->size; // offset得到的是该物理页在双向链表中距离“根节点”的偏移
    // 这个节点被标记使用后，要层层向上回溯，改变父节点的longest值
    while (index)
    {
        index = PARENT(index);
        self[index].longest =
            MAX(self[LEFT_LEAF(index)].longest, self[RIGHT_LEAF(index)].longest);
    }
    return offset;
}

// 对 alloc_pages 的一个封装
// 调用 buddy2_alloc 分配内存块，并更新相应的信息
// 分配的逻辑是：首先在buddy的“二叉树”结构中找到应该分配的物理页在整个实际双向链表中的位置，而后把相应的page进行标识表明该物理页已经分出去了。
static struct Page *
buddy_alloc_pages(size_t n)
{
    assert(n > 0);
    if (n > nr_free)
        return NULL;

    struct Page *page = NULL;
    struct Page *p;
    list_entry_t *le = &free_list, *len;
    rec[nr_block].offset = buddy2_alloc(root, n); // 记录偏移量

    // 找到分配的块的base
    int i;
    for (i = 0; i < rec[nr_block].offset + 1; i++)
        le = list_next(le);
    page = le2page(le, page_link);

    int allocpages = n;
    if (!IS_POWER_OF_2(n))
        allocpages = fixsize(n);

    // 根据需求n得到块大小
    rec[nr_block].base = page;     // 记录分配块首页
    rec[nr_block].nr = allocpages; // 记录分配的页数
    nr_block++;

    for (i = 0; i < allocpages; i++)
    {
        len = list_next(le);
        p = le2page(le, page_link);
        ClearPageProperty(p);
        le = len;
    }                      // 修改每一页的状态
    nr_free -= allocpages; // 减去已被分配的页数
    page->property = n;
    return page;
}

// 释放内存
// 将被释放的内存块重新加入到 free_list 中，并更新伙伴系统的信息。
void buddy_free_pages(struct Page *base, size_t n)
{
    unsigned node_size, index = 0;
    unsigned left_longest, right_longest;
    struct buddy2 *self = root;

    list_entry_t *le = list_next(&free_list);
    int i = 0;
    for (i = 0; i < nr_block; i++) // nr_block是已分配的块数
    {
        if (rec[i].base == base)
            break;
    } // 找到释放块的偏移量
    int offset = rec[i].offset;
    int pos = i; // 暂存i

    i = 0;
    while (i < offset)
    {
        le = list_next(le);
        i++; // 根据该分配块的记录信息，可以找到双链表中对应的page
    }        // 在页链表中找到对应页

    int allocpages = n;
    if (!IS_POWER_OF_2(n))
        allocpages = fixsize(n);

    assert(self && offset >= 0 && offset < self->size); // 是否合法
    nr_free += allocpages;                              // 更新空闲页的数量
    struct Page *p;
    for (i = 0; i < allocpages; i++) // 遍历页链表，回收已分配的页
    {
        p = le2page(le, page_link);
        p->flags = 0;
        p->property = 1;
        SetPageProperty(p);
        le = list_next(le);
    }

    // 实际的双链表信息复原后，还要对二叉树里面的节点信息进行更新
    node_size = 1;
    index = offset + self->size - 1; // 从原始的分配节点的最底节点开始改变longest
    for (; self[index].longest; index = PARENT(index))
    {
        node_size *= 2;
        if (index == 0)
            return;
    }

    self[index].longest = node_size; // 这里应该是node_size，也就是从1那层开始改变
    while (index)
    { // 向上合并，修改父节点的记录值
        index = PARENT(index);
        node_size *= 2;
        left_longest = self[LEFT_LEAF(index)].longest;
        right_longest = self[RIGHT_LEAF(index)].longest;

        if (left_longest + right_longest == node_size)
            self[index].longest = node_size;
        else
            self[index].longest = MAX(left_longest, right_longest);
    }

    for (i = pos; i < nr_block - 1; i++) // 清除此次的分配记录，即从分配数组里面把后面的数据往前挪
    {
        rec[i] = rec[i + 1];
    }
    nr_block--; // 更新分配块数的值
}

// 返回当前可用的空闲页数
static size_t
buddy_nr_free_pages(void)
{
    return nr_free;
}


static void
buddy_check(void) {
    cprintf("=============Stage 1============\n");
    struct Page *p0, *A, *B,*C,*D;
    p0 = A = B = C = D =NULL;
    
    assert((p0 = alloc_page()) != NULL);
    assert((A = alloc_page()) != NULL);
    assert((B = alloc_page()) != NULL);

    assert(p0 != A && p0 != B && A != B);
    assert(page_ref(p0) == 0 && page_ref(A) == 0 && page_ref(B) == 0);
    free_page(p0);
    free_page(A);
    free_page(B);
    
    
    cprintf("=============Stage 2============\n");
    A=alloc_pages(500);
    B=alloc_pages(500);
    cprintf("A %p\n",A);
    cprintf("B %p\n",B);
    free_pages(A,250);
    free_pages(B,500);
    free_pages(A+250,250);
    A=alloc_pages(500);
    cprintf("A %p\n",A);
    free_pages(A,500);
    
    
    cprintf("=============Stage 3============\n");
    //以下是根据链接中的样例测试编写的
    A=alloc_pages(65);  
    B=alloc_pages(33);
    assert(A+128==B);//检查是否相邻
    cprintf("A %p\n",A);
    cprintf("B %p\n",B);
    

    cprintf("=============Stage 4============\n");
    C=alloc_pages(80);
    assert(A+256==C);//检查C有没有和A重叠
    cprintf("C %p\n",C);
    free_pages(A,70);//释放A
    cprintf("B %p\n",B);
    D=alloc_pages(60);
    cprintf("D %p\n",D);
    assert(B+64==D);//检查B，D是否相邻
    free_pages(B,35);
    cprintf("D %p\n",D);
    free_pages(D,60);
    cprintf("C %p\n",C);
    free_pages(C,80);
    free_pages(p0,1000);//全部释放
}


const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",          // 管理器的名称
    .init = buddy_init,                   // 初始化管理器
    .init_memmap = buddy_init_memmap,     // 设置可管理的内存,初始化可分配的物理内存空间
    .alloc_pages = buddy_alloc_pages,     // 分配>=N个连续物理页,返回分配块首地址指针
    .free_pages = buddy_free_pages,       // 释放包括自Base基址在内的，起始的>=N个连续物理内存页
    .nr_free_pages = buddy_nr_free_pages, // 返回全局的空闲物理页数量
    .check = buddy_check,                 // 举例检测这个pmm_manager的正确性
};