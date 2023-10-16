#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_system_pmm.h>
#include <stdio.h>
// 初始化一个页首，方便计算offset,init的时候赋值
struct Page *pageshead = NULL;
unsigned size = 0;        // 表示包含的空间大小，也就是页数
unsigned longest[32768];  // 存放孩子中最大的连续空间大小,longest[i]表示标号为i的节点下包含的最大连续空间大小 页数为31897
                          // 没办法，没有stdlib所以无法动态申请空间，只能一次性申请出来
unsigned nr_free;         // 用来表示目前空闲的页数
unsigned *self = longest; // 指向最前面的

#define LEFT_LEAF(index) ((index) * 2 + 1)
#define RIGHT_LEAF(index) ((index) * 2 + 2)
#define PARENT(index) (((index) + 1) / 2 - 1)

#define IS_POWER_OF_2(x) (!((x) & ((x)-1)))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

static unsigned fixsize(unsigned size)
{
    size |= size >> 1;
    size |= size >> 2;
    size |= size >> 4;
    size |= size >> 8;
    size |= size >> 16;
    return size + 1;
}
static unsigned fixsize_down(unsigned size)
{
    size |= size >> 1;
    size |= size >> 2;
    size |= size >> 4;
    size |= size >> 8;
    size |= size >> 16;
    return (size + 1) >> 1;
}

static void
buddy_init(void)
{
}

static void
buddy_init_memmap(struct Page *base, size_t n)
{
    // 在base地址处创建一个大小为n的空闲区域
    assert(n > 0); // 判断输入是否合理，申请空间应该大于0
    // assert(IS_POWER_OF_2(n)); // 是2的幂
    if (!IS_POWER_OF_2(n))
    {
        n = fixsize_down(n);
    }
    struct Page *p = base;
    for (; p != base + n; p++)
    {
        assert(PageReserved(p));    // 判断是否需要保留
        p->flags = p->property = 0; // 设置flag为合法，property为0（free and not the first page）
        set_page_ref(p, 0);         // free, 暂时没有ref
    }
    base->property = n;    // 然后把first property设置为n
    SetPageProperty(base); // 设置成页首
    // 以上设置page相关，接下来考虑buddy_system相关设置
    unsigned node_size; // 节点空间大小
    int i;
    pageshead = base;               // 捕获页表地址
    size = n;                       // 空间为n
    nr_free = n;                    // 空闲空间为n
    node_size = n * 2;              // 节点大小为2*n
    for (i = 0; i < 2 * n - 1; ++i) // 为longest数组分配数值
    {
        if (IS_POWER_OF_2(i + 1))
            node_size /= 2;
        self[i] = node_size;
    }
    // cprintf("初始化空间大小为%dpages，成功\n", n);
}

static struct Page *
buddy_alloc_pages(size_t n)
{
    // 申请大小为n的空间
    assert(n > 0);
    // 判断空间够不够
    if (n > nr_free || size == 0)
    {
        // cprintf("too large n");
        return NULL;
    }
    else if (!IS_POWER_OF_2(n)) // 如果申请的不是2的次幂，把它变成2的次幂
        n = fixsize(n);
    struct Page *page = NULL;
    unsigned index = 0;
    unsigned node_size;
    unsigned offset = 0;
    for (node_size = size; node_size != n; node_size /= 2) // 具体分配过程，最终得到一个index，就是要分配的页
    {
        if (self[LEFT_LEAF(index)] >= n && self[LEFT_LEAF(index)] <= self[RIGHT_LEAF(index)])
            index = LEFT_LEAF(index);
        else
            index = RIGHT_LEAF(index);
    }
    self[index] = 0;       // 对应longest设置为0表示已经被分配
    nr_free = nr_free - n; // 空闲空间中减去allocated pages
    offset = (index + 1) * node_size - size;
    page = pageshead + offset; // 直接把原来的offset换成page
    while (index)              // 反向更新self中的longest，
    {
        index = PARENT(index);
        self[index] =
            MAX(self[LEFT_LEAF(index)], self[RIGHT_LEAF(index)]);
    }
    // cprintf("申请了大小为%d的空间，分配出了了offset为%d处的页\n", n, offset);
    //  维护一下page，实际上用不上，可能是无用功
    ClearPageProperty(page);
    return page;
}

static void
buddy_free_pages(struct Page *base, size_t n)
{
    // 释放之前被使用的page块，基址base,大小为n,wuwinbin的代码貌似是默认为释放的块大小为1,也许需要进行n次相同操作？
    // 但是同时要求释放的空间必须和之前对应的上。二叉树的节点且大小为2的2次幂
    // 仍然是首先调整页属性，然后修改self即可,关键是如何把base转化为offset，减去真正的页首,使用之前定义的pageshead
    assert(n > 0);
    struct Page *p = base;
    unsigned offset = base - pageshead; // 获取offset
    assert(size && offset >= 0 && offset < size);
    unsigned node_size = 1; // node_size是实际要释放的块的大小
    unsigned index = offset;
    index = offset + size - 1;                 // offser就是base块在longest中的位置
    for (; self[index]; index = PARENT(index)) // 直到到达了当初分配的时候的块，找到了具体要分配的node_size和index
    {
        node_size *= 2;
        if (index == 0)
            return;
    }
    // 开始更新pages的属性
    for (; p != base + node_size; p++)
    {
        assert(!PageReserved(p)); // 不是保留
        // 设置为合法
        p->flags = 0;
        // ref设为0
        set_page_ref(p, 0);
    }
    // free页初始化
    base->property = node_size;
    SetPageProperty(base);

    // 开始更新分配器的值
    self[index] = node_size; // 更新
    nr_free = nr_free + node_size;
    unsigned left_longest, right_longest;

    // cprintf("成功释放index为%d处的空间大小为%d\n", offset, node_size);
    while (index) // 更新被释放节点的父节点
    {
        index = PARENT(index);
        node_size *= 2;

        left_longest = self[LEFT_LEAF(index)];
        right_longest = self[RIGHT_LEAF(index)];

        if (left_longest + right_longest == node_size)
            self[index] = node_size;
        else
            self[index] = MAX(left_longest, right_longest);
    }
}

static size_t
buddy_nr_free_pages(void)
{ // 返回目前free的页数
    return nr_free;
}
// 展示一下当前的pages状态
static void
show_buddy_array(void)
{
    cprintf("---------------------------\n");
    cprintf("Printing buddy array:\n");
    if (self[0] == size)
    {
        cprintf("\n现在是完全没分配，太长了，我就不输出了,你知道就行");
        cprintf("\n\n");
        cprintf("---------------------------\n");
        return;
    }
    int node_size = size * 2;
    int layer = 1;
    int flag = -1;                         // 判断是否应该停止
    for (int i = 0; i < 2 * size - 1; i++) // 为self的longest数组分配数值
    {

        if (IS_POWER_OF_2(i + 1))
        {
            if (flag == 1)
                break;
            if (flag == 0)
                flag = 1;
            node_size /= 2;
            cprintf("\n");
        }
        if (self[i] != node_size)
            flag = 0;
        cprintf("%d ", self[i]);
    }
    cprintf("\n\n");
    cprintf("---------------------------\n");
    return;
}

static void
basic_check(void)
{
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    // 申请3个大小为1的空间
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);
    // 不是同一个位置
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    // 三个的ref都是0
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
    // 三个的位置都没有超过页表区域
    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);
    //
    // list_entry_t free_list_store = free_list;
    // list_init(&free_list);
    // assert(list_empty(&free_list));
    // 复制一下当前的分配器
    // struct buddy2 *newself = (struct buddy2 *)malloc(2 * size * sizeof(unsigned));
    unsigned newself[32768];
    memcpy(newself, self, size * sizeof(unsigned));
    // 存一下当前的nr_free
    unsigned int nr_free_store = nr_free;
    nr_free = 0;
    // 判断当nr_free=0时，无法申请page
    assert(alloc_page() == NULL);

    // 释放三个pages判断是否恢复了3个nr_free
    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    // assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    memcpy(self, newself, size * sizeof(unsigned));
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
buddy_check(void)
{
    cprintf(
        "-----------------------------------------------------"
        "\n\n整个测试过程如下:\n"
        "首先申请 p0 p1 p2 三个单页表\n"
        "然后依次释放\n"
        "然后申请   p0 p1 p2  p3\n"
        "大小分别是 65 40 257 63\n"
        "此时的buddy块:    |64+64|64|64|128+128|512|\n"
        "对应的页块:       |p0   |p1|p3|empty  |p2 |\n"
        "然后释放. p0 p1 p3\n"
        "现在前512个页已经空了\n"
        "然后申请:     p4  p5\n"
        "大小为:      129 255\n"
        "内存布局如下:\n"
        "|256|256|512|\n"
        "|p4 |p5 |p2 |\n"
        "最后释放所有的块.\n\n"
        "------------------------------------------------------\n");

    struct Page *p0, *p1, *p2;
    p0 = p1 = NULL;
    p2 = NULL;
    struct Page *p3, *p4, *p5;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);
    cprintf("首先申请3个页,");
    cprintf("这时内存管理器布局\n");
    show_buddy_array();
    free_page(p0);
    free_page(p1);
    free_page(p2);
    cprintf("然后释放这3个页,");
    cprintf("这时内存管理器布局\n");
    show_buddy_array();

    p0 = alloc_pages(65);
    p1 = alloc_pages(40);
    // 注意，一个结构体指针是20个字节，有3个int,3*4，还有一个双向链表,两个指针是8。加载一起是20。

    cprintf("然后申请两个65和40页块,");
    cprintf("这时内存管理器布局\n");
    show_buddy_array();

    cprintf("p0 %p\n", p0);
    cprintf("p1 %p\n", p1);
    cprintf("p1-p0 equal %d ?=128\n", p1 - p0); // 应该差128

    p2 = alloc_pages(257);

    cprintf("然后申请一个257的页块,");
    cprintf("这时内存管理器布局\n");
    show_buddy_array();

    cprintf("p2 %p\n", p2);
    cprintf("p2-p1 equal %d ?=128+256\n", p2 - p1); // 应该差384

    p3 = alloc_pages(63);
    cprintf("p3 %p\n", p3);
    cprintf("p3-p1 equal %d ?=64\n", p3 - p1); // 应该差64

    free_pages(p0, 65);
    cprintf("free p0!\n");
    free_pages(p1, 40);
    cprintf("free p1!\n");
    free_pages(p3, 63);
    cprintf("free p3!\n");

    cprintf("释放三个小块，现在应该还剩一个512的大块，");
    cprintf("这时内存管理器布局\n");
    show_buddy_array();

    p4 = alloc_pages(129);
    cprintf("p4 %p\n", p4);
    cprintf("p2-p4 equal %d ?=512\n", p2 - p4); // 应该差512

    p5 = alloc_pages(255);
    cprintf("p5 %p\n", p5);
    cprintf("p5-p4 equal %d ?=256\n", p5 - p4); // 应该差256

    cprintf("然后分配一个129，255，");
    cprintf("这时内存管理器布局\n");
    show_buddy_array();

    free_pages(p2, 257);
    cprintf("free p2!\n");
    free_pages(p4, 129);
    cprintf("free p4!\n");
    free_pages(p5, 255);
    cprintf("free p5!\n");

    cprintf("最后释放所有，");
    cprintf("这时内存管理器布局\n");
    show_buddy_array();

    cprintf("CHECK DONE!\n");
}
// 这个结构体在
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
