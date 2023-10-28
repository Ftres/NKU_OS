
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	00006517          	auipc	a0,0x6
ffffffffc020003a:	fda50513          	addi	a0,a0,-38 # ffffffffc0206010 <edata>
ffffffffc020003e:	001ef617          	auipc	a2,0x1ef
ffffffffc0200042:	8ba60613          	addi	a2,a2,-1862 # ffffffffc03ee8f8 <end>
int kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	01f010ef          	jal	ra,ffffffffc020186c <memset>
    cons_init();  // init the console
ffffffffc0200052:	3fe000ef          	jal	ra,ffffffffc0200450 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200056:	00002517          	auipc	a0,0x2
ffffffffc020005a:	82a50513          	addi	a0,a0,-2006 # ffffffffc0201880 <etext+0x2>
ffffffffc020005e:	090000ef          	jal	ra,ffffffffc02000ee <cputs>

    print_kerninfo();
ffffffffc0200062:	0dc000ef          	jal	ra,ffffffffc020013e <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200066:	404000ef          	jal	ra,ffffffffc020046a <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020006a:	0d8010ef          	jal	ra,ffffffffc0201142 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006e:	3fc000ef          	jal	ra,ffffffffc020046a <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200072:	39a000ef          	jal	ra,ffffffffc020040c <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200076:	3e8000ef          	jal	ra,ffffffffc020045e <intr_enable>



    /* do nothing */
    while (1)
        ;
ffffffffc020007a:	a001                	j	ffffffffc020007a <kern_init+0x44>

ffffffffc020007c <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020007c:	1141                	addi	sp,sp,-16
ffffffffc020007e:	e022                	sd	s0,0(sp)
ffffffffc0200080:	e406                	sd	ra,8(sp)
ffffffffc0200082:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200084:	3ce000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200088:	401c                	lw	a5,0(s0)
}
ffffffffc020008a:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc020008c:	2785                	addiw	a5,a5,1
ffffffffc020008e:	c01c                	sw	a5,0(s0)
}
ffffffffc0200090:	6402                	ld	s0,0(sp)
ffffffffc0200092:	0141                	addi	sp,sp,16
ffffffffc0200094:	8082                	ret

ffffffffc0200096 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200096:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	86ae                	mv	a3,a1
ffffffffc020009a:	862a                	mv	a2,a0
ffffffffc020009c:	006c                	addi	a1,sp,12
ffffffffc020009e:	00000517          	auipc	a0,0x0
ffffffffc02000a2:	fde50513          	addi	a0,a0,-34 # ffffffffc020007c <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a6:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a8:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000aa:	2b2010ef          	jal	ra,ffffffffc020135c <vprintfmt>
    return cnt;
}
ffffffffc02000ae:	60e2                	ld	ra,24(sp)
ffffffffc02000b0:	4532                	lw	a0,12(sp)
ffffffffc02000b2:	6105                	addi	sp,sp,32
ffffffffc02000b4:	8082                	ret

ffffffffc02000b6 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b6:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b8:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000bc:	f42e                	sd	a1,40(sp)
ffffffffc02000be:	f832                	sd	a2,48(sp)
ffffffffc02000c0:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c2:	862a                	mv	a2,a0
ffffffffc02000c4:	004c                	addi	a1,sp,4
ffffffffc02000c6:	00000517          	auipc	a0,0x0
ffffffffc02000ca:	fb650513          	addi	a0,a0,-74 # ffffffffc020007c <cputch>
ffffffffc02000ce:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d0:	ec06                	sd	ra,24(sp)
ffffffffc02000d2:	e0ba                	sd	a4,64(sp)
ffffffffc02000d4:	e4be                	sd	a5,72(sp)
ffffffffc02000d6:	e8c2                	sd	a6,80(sp)
ffffffffc02000d8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000da:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000dc:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000de:	27e010ef          	jal	ra,ffffffffc020135c <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e2:	60e2                	ld	ra,24(sp)
ffffffffc02000e4:	4512                	lw	a0,4(sp)
ffffffffc02000e6:	6125                	addi	sp,sp,96
ffffffffc02000e8:	8082                	ret

ffffffffc02000ea <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000ea:	3680006f          	j	ffffffffc0200452 <cons_putc>

ffffffffc02000ee <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ee:	1101                	addi	sp,sp,-32
ffffffffc02000f0:	e822                	sd	s0,16(sp)
ffffffffc02000f2:	ec06                	sd	ra,24(sp)
ffffffffc02000f4:	e426                	sd	s1,8(sp)
ffffffffc02000f6:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f8:	00054503          	lbu	a0,0(a0)
ffffffffc02000fc:	c51d                	beqz	a0,ffffffffc020012a <cputs+0x3c>
ffffffffc02000fe:	0405                	addi	s0,s0,1
ffffffffc0200100:	4485                	li	s1,1
ffffffffc0200102:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200104:	34e000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0200112:	f96d                	bnez	a0,ffffffffc0200104 <cputs+0x16>
ffffffffc0200114:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200118:	4529                	li	a0,10
ffffffffc020011a:	338000ef          	jal	ra,ffffffffc0200452 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011e:	8522                	mv	a0,s0
ffffffffc0200120:	60e2                	ld	ra,24(sp)
ffffffffc0200122:	6442                	ld	s0,16(sp)
ffffffffc0200124:	64a2                	ld	s1,8(sp)
ffffffffc0200126:	6105                	addi	sp,sp,32
ffffffffc0200128:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	4405                	li	s0,1
ffffffffc020012c:	b7f5                	j	ffffffffc0200118 <cputs+0x2a>

ffffffffc020012e <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012e:	1141                	addi	sp,sp,-16
ffffffffc0200130:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200132:	328000ef          	jal	ra,ffffffffc020045a <cons_getc>
ffffffffc0200136:	dd75                	beqz	a0,ffffffffc0200132 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200138:	60a2                	ld	ra,8(sp)
ffffffffc020013a:	0141                	addi	sp,sp,16
ffffffffc020013c:	8082                	ret

ffffffffc020013e <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013e:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200140:	00001517          	auipc	a0,0x1
ffffffffc0200144:	79050513          	addi	a0,a0,1936 # ffffffffc02018d0 <etext+0x52>
void print_kerninfo(void) {
ffffffffc0200148:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020014a:	f6dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014e:	00000597          	auipc	a1,0x0
ffffffffc0200152:	ee858593          	addi	a1,a1,-280 # ffffffffc0200036 <kern_init>
ffffffffc0200156:	00001517          	auipc	a0,0x1
ffffffffc020015a:	79a50513          	addi	a0,a0,1946 # ffffffffc02018f0 <etext+0x72>
ffffffffc020015e:	f59ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200162:	00001597          	auipc	a1,0x1
ffffffffc0200166:	71c58593          	addi	a1,a1,1820 # ffffffffc020187e <etext>
ffffffffc020016a:	00001517          	auipc	a0,0x1
ffffffffc020016e:	7a650513          	addi	a0,a0,1958 # ffffffffc0201910 <etext+0x92>
ffffffffc0200172:	f45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200176:	00006597          	auipc	a1,0x6
ffffffffc020017a:	e9a58593          	addi	a1,a1,-358 # ffffffffc0206010 <edata>
ffffffffc020017e:	00001517          	auipc	a0,0x1
ffffffffc0200182:	7b250513          	addi	a0,a0,1970 # ffffffffc0201930 <etext+0xb2>
ffffffffc0200186:	f31ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020018a:	001ee597          	auipc	a1,0x1ee
ffffffffc020018e:	76e58593          	addi	a1,a1,1902 # ffffffffc03ee8f8 <end>
ffffffffc0200192:	00001517          	auipc	a0,0x1
ffffffffc0200196:	7be50513          	addi	a0,a0,1982 # ffffffffc0201950 <etext+0xd2>
ffffffffc020019a:	f1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019e:	001ef597          	auipc	a1,0x1ef
ffffffffc02001a2:	b5958593          	addi	a1,a1,-1191 # ffffffffc03eecf7 <end+0x3ff>
ffffffffc02001a6:	00000797          	auipc	a5,0x0
ffffffffc02001aa:	e9078793          	addi	a5,a5,-368 # ffffffffc0200036 <kern_init>
ffffffffc02001ae:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b2:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b6:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b8:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001bc:	95be                	add	a1,a1,a5
ffffffffc02001be:	85a9                	srai	a1,a1,0xa
ffffffffc02001c0:	00001517          	auipc	a0,0x1
ffffffffc02001c4:	7b050513          	addi	a0,a0,1968 # ffffffffc0201970 <etext+0xf2>
}
ffffffffc02001c8:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ca:	eedff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02001ce <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ce:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001d0:	00001617          	auipc	a2,0x1
ffffffffc02001d4:	6d060613          	addi	a2,a2,1744 # ffffffffc02018a0 <etext+0x22>
ffffffffc02001d8:	04e00593          	li	a1,78
ffffffffc02001dc:	00001517          	auipc	a0,0x1
ffffffffc02001e0:	6dc50513          	addi	a0,a0,1756 # ffffffffc02018b8 <etext+0x3a>
void print_stackframe(void) {
ffffffffc02001e4:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e6:	1c6000ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02001ea <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001ea:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001ec:	00002617          	auipc	a2,0x2
ffffffffc02001f0:	89460613          	addi	a2,a2,-1900 # ffffffffc0201a80 <commands+0xe0>
ffffffffc02001f4:	00002597          	auipc	a1,0x2
ffffffffc02001f8:	8ac58593          	addi	a1,a1,-1876 # ffffffffc0201aa0 <commands+0x100>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0201aa8 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200206:	eb1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020020a:	00002617          	auipc	a2,0x2
ffffffffc020020e:	8ae60613          	addi	a2,a2,-1874 # ffffffffc0201ab8 <commands+0x118>
ffffffffc0200212:	00002597          	auipc	a1,0x2
ffffffffc0200216:	8ce58593          	addi	a1,a1,-1842 # ffffffffc0201ae0 <commands+0x140>
ffffffffc020021a:	00002517          	auipc	a0,0x2
ffffffffc020021e:	88e50513          	addi	a0,a0,-1906 # ffffffffc0201aa8 <commands+0x108>
ffffffffc0200222:	e95ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200226:	00002617          	auipc	a2,0x2
ffffffffc020022a:	8ca60613          	addi	a2,a2,-1846 # ffffffffc0201af0 <commands+0x150>
ffffffffc020022e:	00002597          	auipc	a1,0x2
ffffffffc0200232:	8e258593          	addi	a1,a1,-1822 # ffffffffc0201b10 <commands+0x170>
ffffffffc0200236:	00002517          	auipc	a0,0x2
ffffffffc020023a:	87250513          	addi	a0,a0,-1934 # ffffffffc0201aa8 <commands+0x108>
ffffffffc020023e:	e79ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    }
    return 0;
}
ffffffffc0200242:	60a2                	ld	ra,8(sp)
ffffffffc0200244:	4501                	li	a0,0
ffffffffc0200246:	0141                	addi	sp,sp,16
ffffffffc0200248:	8082                	ret

ffffffffc020024a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024a:	1141                	addi	sp,sp,-16
ffffffffc020024c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020024e:	ef1ff0ef          	jal	ra,ffffffffc020013e <print_kerninfo>
    return 0;
}
ffffffffc0200252:	60a2                	ld	ra,8(sp)
ffffffffc0200254:	4501                	li	a0,0
ffffffffc0200256:	0141                	addi	sp,sp,16
ffffffffc0200258:	8082                	ret

ffffffffc020025a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025a:	1141                	addi	sp,sp,-16
ffffffffc020025c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020025e:	f71ff0ef          	jal	ra,ffffffffc02001ce <print_stackframe>
    return 0;
}
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020026a:	7115                	addi	sp,sp,-224
ffffffffc020026c:	e962                	sd	s8,144(sp)
ffffffffc020026e:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200270:	00001517          	auipc	a0,0x1
ffffffffc0200274:	77850513          	addi	a0,a0,1912 # ffffffffc02019e8 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200278:	ed86                	sd	ra,216(sp)
ffffffffc020027a:	e9a2                	sd	s0,208(sp)
ffffffffc020027c:	e5a6                	sd	s1,200(sp)
ffffffffc020027e:	e1ca                	sd	s2,192(sp)
ffffffffc0200280:	fd4e                	sd	s3,184(sp)
ffffffffc0200282:	f952                	sd	s4,176(sp)
ffffffffc0200284:	f556                	sd	s5,168(sp)
ffffffffc0200286:	f15a                	sd	s6,160(sp)
ffffffffc0200288:	ed5e                	sd	s7,152(sp)
ffffffffc020028a:	e566                	sd	s9,136(sp)
ffffffffc020028c:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020028e:	e29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200292:	00001517          	auipc	a0,0x1
ffffffffc0200296:	77e50513          	addi	a0,a0,1918 # ffffffffc0201a10 <commands+0x70>
ffffffffc020029a:	e1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (tf != NULL) {
ffffffffc020029e:	000c0563          	beqz	s8,ffffffffc02002a8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a2:	8562                	mv	a0,s8
ffffffffc02002a4:	3a6000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc02002a8:	00001c97          	auipc	s9,0x1
ffffffffc02002ac:	6f8c8c93          	addi	s9,s9,1784 # ffffffffc02019a0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b0:	00001997          	auipc	s3,0x1
ffffffffc02002b4:	78898993          	addi	s3,s3,1928 # ffffffffc0201a38 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b8:	00001917          	auipc	s2,0x1
ffffffffc02002bc:	78890913          	addi	s2,s2,1928 # ffffffffc0201a40 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002c0:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c2:	00001b17          	auipc	s6,0x1
ffffffffc02002c6:	786b0b13          	addi	s6,s6,1926 # ffffffffc0201a48 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002ca:	00001a97          	auipc	s5,0x1
ffffffffc02002ce:	7d6a8a93          	addi	s5,s5,2006 # ffffffffc0201aa0 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d2:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d4:	854e                	mv	a0,s3
ffffffffc02002d6:	412010ef          	jal	ra,ffffffffc02016e8 <readline>
ffffffffc02002da:	842a                	mv	s0,a0
ffffffffc02002dc:	dd65                	beqz	a0,ffffffffc02002d4 <kmonitor+0x6a>
ffffffffc02002de:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e2:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e4:	c999                	beqz	a1,ffffffffc02002fa <kmonitor+0x90>
ffffffffc02002e6:	854a                	mv	a0,s2
ffffffffc02002e8:	566010ef          	jal	ra,ffffffffc020184e <strchr>
ffffffffc02002ec:	c925                	beqz	a0,ffffffffc020035c <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02002ee:	00144583          	lbu	a1,1(s0)
ffffffffc02002f2:	00040023          	sb	zero,0(s0)
ffffffffc02002f6:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002f8:	f5fd                	bnez	a1,ffffffffc02002e6 <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02002fa:	dce9                	beqz	s1,ffffffffc02002d4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002fc:	6582                	ld	a1,0(sp)
ffffffffc02002fe:	00001d17          	auipc	s10,0x1
ffffffffc0200302:	6a2d0d13          	addi	s10,s10,1698 # ffffffffc02019a0 <commands>
    if (argc == 0) {
ffffffffc0200306:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200308:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	0d61                	addi	s10,s10,24
ffffffffc020030c:	518010ef          	jal	ra,ffffffffc0201824 <strcmp>
ffffffffc0200310:	c919                	beqz	a0,ffffffffc0200326 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200312:	2405                	addiw	s0,s0,1
ffffffffc0200314:	09740463          	beq	s0,s7,ffffffffc020039c <kmonitor+0x132>
ffffffffc0200318:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031c:	6582                	ld	a1,0(sp)
ffffffffc020031e:	0d61                	addi	s10,s10,24
ffffffffc0200320:	504010ef          	jal	ra,ffffffffc0201824 <strcmp>
ffffffffc0200324:	f57d                	bnez	a0,ffffffffc0200312 <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200326:	00141793          	slli	a5,s0,0x1
ffffffffc020032a:	97a2                	add	a5,a5,s0
ffffffffc020032c:	078e                	slli	a5,a5,0x3
ffffffffc020032e:	97e6                	add	a5,a5,s9
ffffffffc0200330:	6b9c                	ld	a5,16(a5)
ffffffffc0200332:	8662                	mv	a2,s8
ffffffffc0200334:	002c                	addi	a1,sp,8
ffffffffc0200336:	fff4851b          	addiw	a0,s1,-1
ffffffffc020033a:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020033c:	f8055ce3          	bgez	a0,ffffffffc02002d4 <kmonitor+0x6a>
}
ffffffffc0200340:	60ee                	ld	ra,216(sp)
ffffffffc0200342:	644e                	ld	s0,208(sp)
ffffffffc0200344:	64ae                	ld	s1,200(sp)
ffffffffc0200346:	690e                	ld	s2,192(sp)
ffffffffc0200348:	79ea                	ld	s3,184(sp)
ffffffffc020034a:	7a4a                	ld	s4,176(sp)
ffffffffc020034c:	7aaa                	ld	s5,168(sp)
ffffffffc020034e:	7b0a                	ld	s6,160(sp)
ffffffffc0200350:	6bea                	ld	s7,152(sp)
ffffffffc0200352:	6c4a                	ld	s8,144(sp)
ffffffffc0200354:	6caa                	ld	s9,136(sp)
ffffffffc0200356:	6d0a                	ld	s10,128(sp)
ffffffffc0200358:	612d                	addi	sp,sp,224
ffffffffc020035a:	8082                	ret
        if (*buf == '\0') {
ffffffffc020035c:	00044783          	lbu	a5,0(s0)
ffffffffc0200360:	dfc9                	beqz	a5,ffffffffc02002fa <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc0200362:	03448863          	beq	s1,s4,ffffffffc0200392 <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc0200366:	00349793          	slli	a5,s1,0x3
ffffffffc020036a:	0118                	addi	a4,sp,128
ffffffffc020036c:	97ba                	add	a5,a5,a4
ffffffffc020036e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200372:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200376:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200378:	e591                	bnez	a1,ffffffffc0200384 <kmonitor+0x11a>
ffffffffc020037a:	b749                	j	ffffffffc02002fc <kmonitor+0x92>
            buf ++;
ffffffffc020037c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020037e:	00044583          	lbu	a1,0(s0)
ffffffffc0200382:	ddad                	beqz	a1,ffffffffc02002fc <kmonitor+0x92>
ffffffffc0200384:	854a                	mv	a0,s2
ffffffffc0200386:	4c8010ef          	jal	ra,ffffffffc020184e <strchr>
ffffffffc020038a:	d96d                	beqz	a0,ffffffffc020037c <kmonitor+0x112>
ffffffffc020038c:	00044583          	lbu	a1,0(s0)
ffffffffc0200390:	bf91                	j	ffffffffc02002e4 <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	855a                	mv	a0,s6
ffffffffc0200396:	d21ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020039a:	b7f1                	j	ffffffffc0200366 <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039c:	6582                	ld	a1,0(sp)
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	6ca50513          	addi	a0,a0,1738 # ffffffffc0201a68 <commands+0xc8>
ffffffffc02003a6:	d11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    return 0;
ffffffffc02003aa:	b72d                	j	ffffffffc02002d4 <kmonitor+0x6a>

ffffffffc02003ac <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ac:	00006317          	auipc	t1,0x6
ffffffffc02003b0:	06430313          	addi	t1,t1,100 # ffffffffc0206410 <is_panic>
ffffffffc02003b4:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b8:	715d                	addi	sp,sp,-80
ffffffffc02003ba:	ec06                	sd	ra,24(sp)
ffffffffc02003bc:	e822                	sd	s0,16(sp)
ffffffffc02003be:	f436                	sd	a3,40(sp)
ffffffffc02003c0:	f83a                	sd	a4,48(sp)
ffffffffc02003c2:	fc3e                	sd	a5,56(sp)
ffffffffc02003c4:	e0c2                	sd	a6,64(sp)
ffffffffc02003c6:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c8:	02031c63          	bnez	t1,ffffffffc0200400 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003cc:	4785                	li	a5,1
ffffffffc02003ce:	8432                	mv	s0,a2
ffffffffc02003d0:	00006717          	auipc	a4,0x6
ffffffffc02003d4:	04f72023          	sw	a5,64(a4) # ffffffffc0206410 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d8:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02003da:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003dc:	85aa                	mv	a1,a0
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	74250513          	addi	a0,a0,1858 # ffffffffc0201b20 <commands+0x180>
    va_start(ap, fmt);
ffffffffc02003e6:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e8:	ccfff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003ec:	65a2                	ld	a1,8(sp)
ffffffffc02003ee:	8522                	mv	a0,s0
ffffffffc02003f0:	ca7ff0ef          	jal	ra,ffffffffc0200096 <vcprintf>
    cprintf("\n");
ffffffffc02003f4:	00002517          	auipc	a0,0x2
ffffffffc02003f8:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0201ff0 <commands+0x650>
ffffffffc02003fc:	cbbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200400:	064000ef          	jal	ra,ffffffffc0200464 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200404:	4501                	li	a0,0
ffffffffc0200406:	e65ff0ef          	jal	ra,ffffffffc020026a <kmonitor>
ffffffffc020040a:	bfed                	j	ffffffffc0200404 <__panic+0x58>

ffffffffc020040c <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020040c:	1141                	addi	sp,sp,-16
ffffffffc020040e:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200410:	02000793          	li	a5,32
ffffffffc0200414:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200418:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020041c:	67e1                	lui	a5,0x18
ffffffffc020041e:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc0200422:	953e                	add	a0,a0,a5
ffffffffc0200424:	3a0010ef          	jal	ra,ffffffffc02017c4 <sbi_set_timer>
}
ffffffffc0200428:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042a:	00006797          	auipc	a5,0x6
ffffffffc020042e:	0007b323          	sd	zero,6(a5) # ffffffffc0206430 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200432:	00001517          	auipc	a0,0x1
ffffffffc0200436:	70e50513          	addi	a0,a0,1806 # ffffffffc0201b40 <commands+0x1a0>
}
ffffffffc020043a:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020043c:	c7bff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc0200440 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200440:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200444:	67e1                	lui	a5,0x18
ffffffffc0200446:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc020044a:	953e                	add	a0,a0,a5
ffffffffc020044c:	3780106f          	j	ffffffffc02017c4 <sbi_set_timer>

ffffffffc0200450 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200450:	8082                	ret

ffffffffc0200452 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200452:	0ff57513          	andi	a0,a0,255
ffffffffc0200456:	3520106f          	j	ffffffffc02017a8 <sbi_console_putchar>

ffffffffc020045a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045a:	3860106f          	j	ffffffffc02017e0 <sbi_console_getchar>

ffffffffc020045e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200464:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200468:	8082                	ret

ffffffffc020046a <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020046a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020046e:	00000797          	auipc	a5,0x0
ffffffffc0200472:	30678793          	addi	a5,a5,774 # ffffffffc0200774 <__alltraps>
ffffffffc0200476:	10579073          	csrw	stvec,a5
}
ffffffffc020047a:	8082                	ret

ffffffffc020047c <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020047e:	1141                	addi	sp,sp,-16
ffffffffc0200480:	e022                	sd	s0,0(sp)
ffffffffc0200482:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200484:	00001517          	auipc	a0,0x1
ffffffffc0200488:	7d450513          	addi	a0,a0,2004 # ffffffffc0201c58 <commands+0x2b8>
void print_regs(struct pushregs *gpr) {
ffffffffc020048c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020048e:	c29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200492:	640c                	ld	a1,8(s0)
ffffffffc0200494:	00001517          	auipc	a0,0x1
ffffffffc0200498:	7dc50513          	addi	a0,a0,2012 # ffffffffc0201c70 <commands+0x2d0>
ffffffffc020049c:	c1bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a0:	680c                	ld	a1,16(s0)
ffffffffc02004a2:	00001517          	auipc	a0,0x1
ffffffffc02004a6:	7e650513          	addi	a0,a0,2022 # ffffffffc0201c88 <commands+0x2e8>
ffffffffc02004aa:	c0dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004ae:	6c0c                	ld	a1,24(s0)
ffffffffc02004b0:	00001517          	auipc	a0,0x1
ffffffffc02004b4:	7f050513          	addi	a0,a0,2032 # ffffffffc0201ca0 <commands+0x300>
ffffffffc02004b8:	bffff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004bc:	700c                	ld	a1,32(s0)
ffffffffc02004be:	00001517          	auipc	a0,0x1
ffffffffc02004c2:	7fa50513          	addi	a0,a0,2042 # ffffffffc0201cb8 <commands+0x318>
ffffffffc02004c6:	bf1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004ca:	740c                	ld	a1,40(s0)
ffffffffc02004cc:	00002517          	auipc	a0,0x2
ffffffffc02004d0:	80450513          	addi	a0,a0,-2044 # ffffffffc0201cd0 <commands+0x330>
ffffffffc02004d4:	be3ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d8:	780c                	ld	a1,48(s0)
ffffffffc02004da:	00002517          	auipc	a0,0x2
ffffffffc02004de:	80e50513          	addi	a0,a0,-2034 # ffffffffc0201ce8 <commands+0x348>
ffffffffc02004e2:	bd5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e6:	7c0c                	ld	a1,56(s0)
ffffffffc02004e8:	00002517          	auipc	a0,0x2
ffffffffc02004ec:	81850513          	addi	a0,a0,-2024 # ffffffffc0201d00 <commands+0x360>
ffffffffc02004f0:	bc7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f4:	602c                	ld	a1,64(s0)
ffffffffc02004f6:	00002517          	auipc	a0,0x2
ffffffffc02004fa:	82250513          	addi	a0,a0,-2014 # ffffffffc0201d18 <commands+0x378>
ffffffffc02004fe:	bb9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200502:	642c                	ld	a1,72(s0)
ffffffffc0200504:	00002517          	auipc	a0,0x2
ffffffffc0200508:	82c50513          	addi	a0,a0,-2004 # ffffffffc0201d30 <commands+0x390>
ffffffffc020050c:	babff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200510:	682c                	ld	a1,80(s0)
ffffffffc0200512:	00002517          	auipc	a0,0x2
ffffffffc0200516:	83650513          	addi	a0,a0,-1994 # ffffffffc0201d48 <commands+0x3a8>
ffffffffc020051a:	b9dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020051e:	6c2c                	ld	a1,88(s0)
ffffffffc0200520:	00002517          	auipc	a0,0x2
ffffffffc0200524:	84050513          	addi	a0,a0,-1984 # ffffffffc0201d60 <commands+0x3c0>
ffffffffc0200528:	b8fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052c:	702c                	ld	a1,96(s0)
ffffffffc020052e:	00002517          	auipc	a0,0x2
ffffffffc0200532:	84a50513          	addi	a0,a0,-1974 # ffffffffc0201d78 <commands+0x3d8>
ffffffffc0200536:	b81ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053a:	742c                	ld	a1,104(s0)
ffffffffc020053c:	00002517          	auipc	a0,0x2
ffffffffc0200540:	85450513          	addi	a0,a0,-1964 # ffffffffc0201d90 <commands+0x3f0>
ffffffffc0200544:	b73ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200548:	782c                	ld	a1,112(s0)
ffffffffc020054a:	00002517          	auipc	a0,0x2
ffffffffc020054e:	85e50513          	addi	a0,a0,-1954 # ffffffffc0201da8 <commands+0x408>
ffffffffc0200552:	b65ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200556:	7c2c                	ld	a1,120(s0)
ffffffffc0200558:	00002517          	auipc	a0,0x2
ffffffffc020055c:	86850513          	addi	a0,a0,-1944 # ffffffffc0201dc0 <commands+0x420>
ffffffffc0200560:	b57ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200564:	604c                	ld	a1,128(s0)
ffffffffc0200566:	00002517          	auipc	a0,0x2
ffffffffc020056a:	87250513          	addi	a0,a0,-1934 # ffffffffc0201dd8 <commands+0x438>
ffffffffc020056e:	b49ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200572:	644c                	ld	a1,136(s0)
ffffffffc0200574:	00002517          	auipc	a0,0x2
ffffffffc0200578:	87c50513          	addi	a0,a0,-1924 # ffffffffc0201df0 <commands+0x450>
ffffffffc020057c:	b3bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200580:	684c                	ld	a1,144(s0)
ffffffffc0200582:	00002517          	auipc	a0,0x2
ffffffffc0200586:	88650513          	addi	a0,a0,-1914 # ffffffffc0201e08 <commands+0x468>
ffffffffc020058a:	b2dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020058e:	6c4c                	ld	a1,152(s0)
ffffffffc0200590:	00002517          	auipc	a0,0x2
ffffffffc0200594:	89050513          	addi	a0,a0,-1904 # ffffffffc0201e20 <commands+0x480>
ffffffffc0200598:	b1fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059c:	704c                	ld	a1,160(s0)
ffffffffc020059e:	00002517          	auipc	a0,0x2
ffffffffc02005a2:	89a50513          	addi	a0,a0,-1894 # ffffffffc0201e38 <commands+0x498>
ffffffffc02005a6:	b11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005aa:	744c                	ld	a1,168(s0)
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	8a450513          	addi	a0,a0,-1884 # ffffffffc0201e50 <commands+0x4b0>
ffffffffc02005b4:	b03ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b8:	784c                	ld	a1,176(s0)
ffffffffc02005ba:	00002517          	auipc	a0,0x2
ffffffffc02005be:	8ae50513          	addi	a0,a0,-1874 # ffffffffc0201e68 <commands+0x4c8>
ffffffffc02005c2:	af5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c6:	7c4c                	ld	a1,184(s0)
ffffffffc02005c8:	00002517          	auipc	a0,0x2
ffffffffc02005cc:	8b850513          	addi	a0,a0,-1864 # ffffffffc0201e80 <commands+0x4e0>
ffffffffc02005d0:	ae7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d4:	606c                	ld	a1,192(s0)
ffffffffc02005d6:	00002517          	auipc	a0,0x2
ffffffffc02005da:	8c250513          	addi	a0,a0,-1854 # ffffffffc0201e98 <commands+0x4f8>
ffffffffc02005de:	ad9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e2:	646c                	ld	a1,200(s0)
ffffffffc02005e4:	00002517          	auipc	a0,0x2
ffffffffc02005e8:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0201eb0 <commands+0x510>
ffffffffc02005ec:	acbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f0:	686c                	ld	a1,208(s0)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	8d650513          	addi	a0,a0,-1834 # ffffffffc0201ec8 <commands+0x528>
ffffffffc02005fa:	abdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200600:	00002517          	auipc	a0,0x2
ffffffffc0200604:	8e050513          	addi	a0,a0,-1824 # ffffffffc0201ee0 <commands+0x540>
ffffffffc0200608:	aafff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060c:	706c                	ld	a1,224(s0)
ffffffffc020060e:	00002517          	auipc	a0,0x2
ffffffffc0200612:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0201ef8 <commands+0x558>
ffffffffc0200616:	aa1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061a:	746c                	ld	a1,232(s0)
ffffffffc020061c:	00002517          	auipc	a0,0x2
ffffffffc0200620:	8f450513          	addi	a0,a0,-1804 # ffffffffc0201f10 <commands+0x570>
ffffffffc0200624:	a93ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200628:	786c                	ld	a1,240(s0)
ffffffffc020062a:	00002517          	auipc	a0,0x2
ffffffffc020062e:	8fe50513          	addi	a0,a0,-1794 # ffffffffc0201f28 <commands+0x588>
ffffffffc0200632:	a85ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200638:	6402                	ld	s0,0(sp)
ffffffffc020063a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	90450513          	addi	a0,a0,-1788 # ffffffffc0201f40 <commands+0x5a0>
}
ffffffffc0200644:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200646:	a71ff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc020064a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020064a:	1141                	addi	sp,sp,-16
ffffffffc020064c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020064e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200650:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200652:	00002517          	auipc	a0,0x2
ffffffffc0200656:	90650513          	addi	a0,a0,-1786 # ffffffffc0201f58 <commands+0x5b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc020065a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020065c:	a5bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200660:	8522                	mv	a0,s0
ffffffffc0200662:	e1bff0ef          	jal	ra,ffffffffc020047c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200666:	10043583          	ld	a1,256(s0)
ffffffffc020066a:	00002517          	auipc	a0,0x2
ffffffffc020066e:	90650513          	addi	a0,a0,-1786 # ffffffffc0201f70 <commands+0x5d0>
ffffffffc0200672:	a45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00002517          	auipc	a0,0x2
ffffffffc020067e:	90e50513          	addi	a0,a0,-1778 # ffffffffc0201f88 <commands+0x5e8>
ffffffffc0200682:	a35ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00002517          	auipc	a0,0x2
ffffffffc020068e:	91650513          	addi	a0,a0,-1770 # ffffffffc0201fa0 <commands+0x600>
ffffffffc0200692:	a25ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	91a50513          	addi	a0,a0,-1766 # ffffffffc0201fb8 <commands+0x618>
}
ffffffffc02006a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a8:	a0fff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02006ac <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006ac:	11853783          	ld	a5,280(a0)
ffffffffc02006b0:	577d                	li	a4,-1
ffffffffc02006b2:	8305                	srli	a4,a4,0x1
ffffffffc02006b4:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02006b6:	472d                	li	a4,11
ffffffffc02006b8:	08f76563          	bltu	a4,a5,ffffffffc0200742 <interrupt_handler+0x96>
ffffffffc02006bc:	00001717          	auipc	a4,0x1
ffffffffc02006c0:	4a070713          	addi	a4,a4,1184 # ffffffffc0201b5c <commands+0x1bc>
ffffffffc02006c4:	078a                	slli	a5,a5,0x2
ffffffffc02006c6:	97ba                	add	a5,a5,a4
ffffffffc02006c8:	439c                	lw	a5,0(a5)
ffffffffc02006ca:	97ba                	add	a5,a5,a4
ffffffffc02006cc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006ce:	00001517          	auipc	a0,0x1
ffffffffc02006d2:	52250513          	addi	a0,a0,1314 # ffffffffc0201bf0 <commands+0x250>
ffffffffc02006d6:	9e1ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006da:	00001517          	auipc	a0,0x1
ffffffffc02006de:	4f650513          	addi	a0,a0,1270 # ffffffffc0201bd0 <commands+0x230>
ffffffffc02006e2:	9d5ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006e6:	00001517          	auipc	a0,0x1
ffffffffc02006ea:	4aa50513          	addi	a0,a0,1194 # ffffffffc0201b90 <commands+0x1f0>
ffffffffc02006ee:	9c9ff06f          	j	ffffffffc02000b6 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006f2:	00001517          	auipc	a0,0x1
ffffffffc02006f6:	51e50513          	addi	a0,a0,1310 # ffffffffc0201c10 <commands+0x270>
ffffffffc02006fa:	9bdff06f          	j	ffffffffc02000b6 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006fe:	1141                	addi	sp,sp,-16
ffffffffc0200700:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc0200702:	d3fff0ef          	jal	ra,ffffffffc0200440 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200706:	00006797          	auipc	a5,0x6
ffffffffc020070a:	d2a78793          	addi	a5,a5,-726 # ffffffffc0206430 <ticks>
ffffffffc020070e:	639c                	ld	a5,0(a5)
ffffffffc0200710:	06400713          	li	a4,100
ffffffffc0200714:	0785                	addi	a5,a5,1
ffffffffc0200716:	02e7f733          	remu	a4,a5,a4
ffffffffc020071a:	00006697          	auipc	a3,0x6
ffffffffc020071e:	d0f6bb23          	sd	a5,-746(a3) # ffffffffc0206430 <ticks>
ffffffffc0200722:	c315                	beqz	a4,ffffffffc0200746 <interrupt_handler+0x9a>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200724:	60a2                	ld	ra,8(sp)
ffffffffc0200726:	0141                	addi	sp,sp,16
ffffffffc0200728:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc020072a:	00001517          	auipc	a0,0x1
ffffffffc020072e:	50e50513          	addi	a0,a0,1294 # ffffffffc0201c38 <commands+0x298>
ffffffffc0200732:	985ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200736:	00001517          	auipc	a0,0x1
ffffffffc020073a:	47a50513          	addi	a0,a0,1146 # ffffffffc0201bb0 <commands+0x210>
ffffffffc020073e:	979ff06f          	j	ffffffffc02000b6 <cprintf>
            print_trapframe(tf);
ffffffffc0200742:	f09ff06f          	j	ffffffffc020064a <print_trapframe>
}
ffffffffc0200746:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200748:	06400593          	li	a1,100
ffffffffc020074c:	00001517          	auipc	a0,0x1
ffffffffc0200750:	4dc50513          	addi	a0,a0,1244 # ffffffffc0201c28 <commands+0x288>
}
ffffffffc0200754:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200756:	961ff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc020075a <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc020075a:	11853783          	ld	a5,280(a0)
ffffffffc020075e:	0007c863          	bltz	a5,ffffffffc020076e <trap+0x14>
    switch (tf->cause) {
ffffffffc0200762:	472d                	li	a4,11
ffffffffc0200764:	00f76363          	bltu	a4,a5,ffffffffc020076a <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200768:	8082                	ret
            print_trapframe(tf);
ffffffffc020076a:	ee1ff06f          	j	ffffffffc020064a <print_trapframe>
        interrupt_handler(tf);
ffffffffc020076e:	f3fff06f          	j	ffffffffc02006ac <interrupt_handler>
	...

ffffffffc0200774 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200774:	14011073          	csrw	sscratch,sp
ffffffffc0200778:	712d                	addi	sp,sp,-288
ffffffffc020077a:	e002                	sd	zero,0(sp)
ffffffffc020077c:	e406                	sd	ra,8(sp)
ffffffffc020077e:	ec0e                	sd	gp,24(sp)
ffffffffc0200780:	f012                	sd	tp,32(sp)
ffffffffc0200782:	f416                	sd	t0,40(sp)
ffffffffc0200784:	f81a                	sd	t1,48(sp)
ffffffffc0200786:	fc1e                	sd	t2,56(sp)
ffffffffc0200788:	e0a2                	sd	s0,64(sp)
ffffffffc020078a:	e4a6                	sd	s1,72(sp)
ffffffffc020078c:	e8aa                	sd	a0,80(sp)
ffffffffc020078e:	ecae                	sd	a1,88(sp)
ffffffffc0200790:	f0b2                	sd	a2,96(sp)
ffffffffc0200792:	f4b6                	sd	a3,104(sp)
ffffffffc0200794:	f8ba                	sd	a4,112(sp)
ffffffffc0200796:	fcbe                	sd	a5,120(sp)
ffffffffc0200798:	e142                	sd	a6,128(sp)
ffffffffc020079a:	e546                	sd	a7,136(sp)
ffffffffc020079c:	e94a                	sd	s2,144(sp)
ffffffffc020079e:	ed4e                	sd	s3,152(sp)
ffffffffc02007a0:	f152                	sd	s4,160(sp)
ffffffffc02007a2:	f556                	sd	s5,168(sp)
ffffffffc02007a4:	f95a                	sd	s6,176(sp)
ffffffffc02007a6:	fd5e                	sd	s7,184(sp)
ffffffffc02007a8:	e1e2                	sd	s8,192(sp)
ffffffffc02007aa:	e5e6                	sd	s9,200(sp)
ffffffffc02007ac:	e9ea                	sd	s10,208(sp)
ffffffffc02007ae:	edee                	sd	s11,216(sp)
ffffffffc02007b0:	f1f2                	sd	t3,224(sp)
ffffffffc02007b2:	f5f6                	sd	t4,232(sp)
ffffffffc02007b4:	f9fa                	sd	t5,240(sp)
ffffffffc02007b6:	fdfe                	sd	t6,248(sp)
ffffffffc02007b8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc02007bc:	100024f3          	csrr	s1,sstatus
ffffffffc02007c0:	14102973          	csrr	s2,sepc
ffffffffc02007c4:	143029f3          	csrr	s3,stval
ffffffffc02007c8:	14202a73          	csrr	s4,scause
ffffffffc02007cc:	e822                	sd	s0,16(sp)
ffffffffc02007ce:	e226                	sd	s1,256(sp)
ffffffffc02007d0:	e64a                	sd	s2,264(sp)
ffffffffc02007d2:	ea4e                	sd	s3,272(sp)
ffffffffc02007d4:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007d6:	850a                	mv	a0,sp
    jal trap
ffffffffc02007d8:	f83ff0ef          	jal	ra,ffffffffc020075a <trap>

ffffffffc02007dc <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007dc:	6492                	ld	s1,256(sp)
ffffffffc02007de:	6932                	ld	s2,264(sp)
ffffffffc02007e0:	10049073          	csrw	sstatus,s1
ffffffffc02007e4:	14191073          	csrw	sepc,s2
ffffffffc02007e8:	60a2                	ld	ra,8(sp)
ffffffffc02007ea:	61e2                	ld	gp,24(sp)
ffffffffc02007ec:	7202                	ld	tp,32(sp)
ffffffffc02007ee:	72a2                	ld	t0,40(sp)
ffffffffc02007f0:	7342                	ld	t1,48(sp)
ffffffffc02007f2:	73e2                	ld	t2,56(sp)
ffffffffc02007f4:	6406                	ld	s0,64(sp)
ffffffffc02007f6:	64a6                	ld	s1,72(sp)
ffffffffc02007f8:	6546                	ld	a0,80(sp)
ffffffffc02007fa:	65e6                	ld	a1,88(sp)
ffffffffc02007fc:	7606                	ld	a2,96(sp)
ffffffffc02007fe:	76a6                	ld	a3,104(sp)
ffffffffc0200800:	7746                	ld	a4,112(sp)
ffffffffc0200802:	77e6                	ld	a5,120(sp)
ffffffffc0200804:	680a                	ld	a6,128(sp)
ffffffffc0200806:	68aa                	ld	a7,136(sp)
ffffffffc0200808:	694a                	ld	s2,144(sp)
ffffffffc020080a:	69ea                	ld	s3,152(sp)
ffffffffc020080c:	7a0a                	ld	s4,160(sp)
ffffffffc020080e:	7aaa                	ld	s5,168(sp)
ffffffffc0200810:	7b4a                	ld	s6,176(sp)
ffffffffc0200812:	7bea                	ld	s7,184(sp)
ffffffffc0200814:	6c0e                	ld	s8,192(sp)
ffffffffc0200816:	6cae                	ld	s9,200(sp)
ffffffffc0200818:	6d4e                	ld	s10,208(sp)
ffffffffc020081a:	6dee                	ld	s11,216(sp)
ffffffffc020081c:	7e0e                	ld	t3,224(sp)
ffffffffc020081e:	7eae                	ld	t4,232(sp)
ffffffffc0200820:	7f4e                	ld	t5,240(sp)
ffffffffc0200822:	7fee                	ld	t6,248(sp)
ffffffffc0200824:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200826:	10200073          	sret

ffffffffc020082a <buddy_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020082a:	00006797          	auipc	a5,0x6
ffffffffc020082e:	c0e78793          	addi	a5,a5,-1010 # ffffffffc0206438 <free_area>
ffffffffc0200832:	e79c                	sd	a5,8(a5)
ffffffffc0200834:	e39c                	sd	a5,0(a5)

// 初始化全局的 free_list和 nr_free
static void buddy_init()
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200836:	0007a823          	sw	zero,16(a5)
}
ffffffffc020083a:	8082                	ret

ffffffffc020083c <buddy_nr_free_pages>:
// 返回当前可用的空闲页数
static size_t
buddy_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc020083c:	00006517          	auipc	a0,0x6
ffffffffc0200840:	c0c56503          	lwu	a0,-1012(a0) # ffffffffc0206448 <free_area+0x10>
ffffffffc0200844:	8082                	ret

ffffffffc0200846 <buddy_free_pages>:
    for (i = 0; i < nr_block; i++) // nr_block是已分配的块数
ffffffffc0200846:	00006317          	auipc	t1,0x6
ffffffffc020084a:	c0a30313          	addi	t1,t1,-1014 # ffffffffc0206450 <nr_block>
ffffffffc020084e:	00032883          	lw	a7,0(t1)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200852:	00006e97          	auipc	t4,0x6
ffffffffc0200856:	be6e8e93          	addi	t4,t4,-1050 # ffffffffc0206438 <free_area>
ffffffffc020085a:	008eb683          	ld	a3,8(t4)
ffffffffc020085e:	1b105963          	blez	a7,ffffffffc0200a10 <buddy_free_pages+0x1ca>
        if (rec[i].base == base)
ffffffffc0200862:	00019817          	auipc	a6,0x19
ffffffffc0200866:	47680813          	addi	a6,a6,1142 # ffffffffc0219cd8 <rec>
ffffffffc020086a:	00083783          	ld	a5,0(a6)
ffffffffc020086e:	1af50763          	beq	a0,a5,ffffffffc0200a1c <buddy_free_pages+0x1d6>
ffffffffc0200872:	00019717          	auipc	a4,0x19
ffffffffc0200876:	47e70713          	addi	a4,a4,1150 # ffffffffc0219cf0 <rec+0x18>
    for (i = 0; i < nr_block; i++) // nr_block是已分配的块数
ffffffffc020087a:	4781                	li	a5,0
ffffffffc020087c:	a031                	j	ffffffffc0200888 <buddy_free_pages+0x42>
        if (rec[i].base == base)
ffffffffc020087e:	0761                	addi	a4,a4,24
ffffffffc0200880:	fe873603          	ld	a2,-24(a4)
ffffffffc0200884:	18a60163          	beq	a2,a0,ffffffffc0200a06 <buddy_free_pages+0x1c0>
    for (i = 0; i < nr_block; i++) // nr_block是已分配的块数
ffffffffc0200888:	2785                	addiw	a5,a5,1
ffffffffc020088a:	ff179ae3          	bne	a5,a7,ffffffffc020087e <buddy_free_pages+0x38>
    int offset = rec[i].offset;
ffffffffc020088e:	00189e13          	slli	t3,a7,0x1
ffffffffc0200892:	011e07b3          	add	a5,t3,a7
ffffffffc0200896:	078e                	slli	a5,a5,0x3
ffffffffc0200898:	97c2                	add	a5,a5,a6
ffffffffc020089a:	4798                	lw	a4,8(a5)
    while (i < offset)
ffffffffc020089c:	00e05763          	blez	a4,ffffffffc02008aa <buddy_free_pages+0x64>
    i = 0;
ffffffffc02008a0:	4781                	li	a5,0
        i++; // 根据该分配块的记录信息，可以找到双链表中对应的page
ffffffffc02008a2:	2785                	addiw	a5,a5,1
ffffffffc02008a4:	6694                	ld	a3,8(a3)
    while (i < offset)
ffffffffc02008a6:	fef71ee3          	bne	a4,a5,ffffffffc02008a2 <buddy_free_pages+0x5c>
    if (!IS_POWER_OF_2(n))
ffffffffc02008aa:	fff58793          	addi	a5,a1,-1
ffffffffc02008ae:	8fed                	and	a5,a5,a1
        allocpages = fixsize(n);
ffffffffc02008b0:	2581                	sext.w	a1,a1
    if (!IS_POWER_OF_2(n))
ffffffffc02008b2:	c78d                	beqz	a5,ffffffffc02008dc <buddy_free_pages+0x96>
    size |= size >> 1;
ffffffffc02008b4:	0015d79b          	srliw	a5,a1,0x1
ffffffffc02008b8:	8ddd                	or	a1,a1,a5
ffffffffc02008ba:	2581                	sext.w	a1,a1
    size |= size >> 2;
ffffffffc02008bc:	0025d79b          	srliw	a5,a1,0x2
ffffffffc02008c0:	8ddd                	or	a1,a1,a5
ffffffffc02008c2:	2581                	sext.w	a1,a1
    size |= size >> 4;
ffffffffc02008c4:	0045d79b          	srliw	a5,a1,0x4
ffffffffc02008c8:	8ddd                	or	a1,a1,a5
ffffffffc02008ca:	2581                	sext.w	a1,a1
    size |= size >> 8;
ffffffffc02008cc:	0085d79b          	srliw	a5,a1,0x8
ffffffffc02008d0:	8ddd                	or	a1,a1,a5
ffffffffc02008d2:	2581                	sext.w	a1,a1
    size |= size >> 16;
ffffffffc02008d4:	0105d79b          	srliw	a5,a1,0x10
ffffffffc02008d8:	8ddd                	or	a1,a1,a5
        allocpages = fixsize(n);
ffffffffc02008da:	2585                	addiw	a1,a1,1
    assert(self && offset >= 0 && offset < self->size); // 是否合法
ffffffffc02008dc:	14074263          	bltz	a4,ffffffffc0200a20 <buddy_free_pages+0x1da>
ffffffffc02008e0:	00006517          	auipc	a0,0x6
ffffffffc02008e4:	b7850513          	addi	a0,a0,-1160 # ffffffffc0206458 <root>
ffffffffc02008e8:	411c                	lw	a5,0(a0)
ffffffffc02008ea:	2701                	sext.w	a4,a4
ffffffffc02008ec:	12f77a63          	bleu	a5,a4,ffffffffc0200a20 <buddy_free_pages+0x1da>
    nr_free += allocpages;                              // 更新空闲页的数量
ffffffffc02008f0:	010ea603          	lw	a2,16(t4)
ffffffffc02008f4:	9e2d                	addw	a2,a2,a1
ffffffffc02008f6:	00006e97          	auipc	t4,0x6
ffffffffc02008fa:	b4cea923          	sw	a2,-1198(t4) # ffffffffc0206448 <free_area+0x10>
    for (i = 0; i < allocpages; i++) // 遍历页链表，回收已分配的页
ffffffffc02008fe:	02b05263          	blez	a1,ffffffffc0200922 <buddy_free_pages+0xdc>
ffffffffc0200902:	4781                	li	a5,0
        p->property = 1;
ffffffffc0200904:	4e85                	li	t4,1
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200906:	4609                	li	a2,2
        p->flags = 0;
ffffffffc0200908:	fe06b823          	sd	zero,-16(a3)
        p->property = 1;
ffffffffc020090c:	ffd6ac23          	sw	t4,-8(a3)
ffffffffc0200910:	ff068f13          	addi	t5,a3,-16
ffffffffc0200914:	40cf302f          	amoor.d	zero,a2,(t5)
    for (i = 0; i < allocpages; i++) // 遍历页链表，回收已分配的页
ffffffffc0200918:	2785                	addiw	a5,a5,1
ffffffffc020091a:	6694                	ld	a3,8(a3)
ffffffffc020091c:	fef596e3          	bne	a1,a5,ffffffffc0200908 <buddy_free_pages+0xc2>
ffffffffc0200920:	411c                	lw	a5,0(a0)
    index = offset + self->size - 1; // 从原始的分配节点的最底节点开始改变longest
ffffffffc0200922:	377d                	addiw	a4,a4,-1
ffffffffc0200924:	9fb9                	addw	a5,a5,a4
    for (; self[index].longest; index = PARENT(index))
ffffffffc0200926:	02079713          	slli	a4,a5,0x20
ffffffffc020092a:	8375                	srli	a4,a4,0x1d
ffffffffc020092c:	972a                	add	a4,a4,a0
ffffffffc020092e:	4354                	lw	a3,4(a4)
ffffffffc0200930:	cee9                	beqz	a3,ffffffffc0200a0a <buddy_free_pages+0x1c4>
        if (index == 0)
ffffffffc0200932:	cbe9                	beqz	a5,ffffffffc0200a04 <buddy_free_pages+0x1be>
        node_size *= 2;
ffffffffc0200934:	4689                	li	a3,2
ffffffffc0200936:	a021                	j	ffffffffc020093e <buddy_free_pages+0xf8>
ffffffffc0200938:	0016969b          	slliw	a3,a3,0x1
        if (index == 0)
ffffffffc020093c:	c7e1                	beqz	a5,ffffffffc0200a04 <buddy_free_pages+0x1be>
    for (; self[index].longest; index = PARENT(index))
ffffffffc020093e:	2785                	addiw	a5,a5,1
ffffffffc0200940:	0017d79b          	srliw	a5,a5,0x1
ffffffffc0200944:	37fd                	addiw	a5,a5,-1
ffffffffc0200946:	02079713          	slli	a4,a5,0x20
ffffffffc020094a:	8375                	srli	a4,a4,0x1d
ffffffffc020094c:	972a                	add	a4,a4,a0
ffffffffc020094e:	4350                	lw	a2,4(a4)
ffffffffc0200950:	f665                	bnez	a2,ffffffffc0200938 <buddy_free_pages+0xf2>
    self[index].longest = node_size; // 这里应该是node_size，也就是从1那层开始改变
ffffffffc0200952:	c354                	sw	a3,4(a4)
    while (index)
ffffffffc0200954:	c7b9                	beqz	a5,ffffffffc02009a2 <buddy_free_pages+0x15c>
        index = PARENT(index);
ffffffffc0200956:	2785                	addiw	a5,a5,1
ffffffffc0200958:	0017d59b          	srliw	a1,a5,0x1
ffffffffc020095c:	35fd                	addiw	a1,a1,-1
        left_longest = self[LEFT_LEAF(index)].longest;
ffffffffc020095e:	0015961b          	slliw	a2,a1,0x1
        right_longest = self[RIGHT_LEAF(index)].longest;
ffffffffc0200962:	ffe7f713          	andi	a4,a5,-2
        left_longest = self[LEFT_LEAF(index)].longest;
ffffffffc0200966:	2605                	addiw	a2,a2,1
ffffffffc0200968:	1602                	slli	a2,a2,0x20
        right_longest = self[RIGHT_LEAF(index)].longest;
ffffffffc020096a:	1702                	slli	a4,a4,0x20
        left_longest = self[LEFT_LEAF(index)].longest;
ffffffffc020096c:	9201                	srli	a2,a2,0x20
        right_longest = self[RIGHT_LEAF(index)].longest;
ffffffffc020096e:	9301                	srli	a4,a4,0x20
        left_longest = self[LEFT_LEAF(index)].longest;
ffffffffc0200970:	060e                	slli	a2,a2,0x3
        right_longest = self[RIGHT_LEAF(index)].longest;
ffffffffc0200972:	070e                	slli	a4,a4,0x3
ffffffffc0200974:	972a                	add	a4,a4,a0
        left_longest = self[LEFT_LEAF(index)].longest;
ffffffffc0200976:	962a                	add	a2,a2,a0
        right_longest = self[RIGHT_LEAF(index)].longest;
ffffffffc0200978:	00472e83          	lw	t4,4(a4)
        left_longest = self[LEFT_LEAF(index)].longest;
ffffffffc020097c:	4250                	lw	a2,4(a2)
ffffffffc020097e:	02059713          	slli	a4,a1,0x20
ffffffffc0200982:	8375                	srli	a4,a4,0x1d
        node_size *= 2;
ffffffffc0200984:	0016969b          	slliw	a3,a3,0x1
        if (left_longest + right_longest == node_size)
ffffffffc0200988:	01d60fbb          	addw	t6,a2,t4
        index = PARENT(index);
ffffffffc020098c:	0005879b          	sext.w	a5,a1
        if (left_longest + right_longest == node_size)
ffffffffc0200990:	972a                	add	a4,a4,a0
ffffffffc0200992:	06df8763          	beq	t6,a3,ffffffffc0200a00 <buddy_free_pages+0x1ba>
            self[index].longest = MAX(left_longest, right_longest);
ffffffffc0200996:	85b2                	mv	a1,a2
ffffffffc0200998:	01d67363          	bleu	t4,a2,ffffffffc020099e <buddy_free_pages+0x158>
ffffffffc020099c:	85f6                	mv	a1,t4
ffffffffc020099e:	c34c                	sw	a1,4(a4)
    while (index)
ffffffffc02009a0:	fbdd                	bnez	a5,ffffffffc0200956 <buddy_free_pages+0x110>
    for (i = pos; i < nr_block - 1; i++) // 清除此次的分配记录，即从分配数组里面把后面的数据往前挪
ffffffffc02009a2:	00032783          	lw	a5,0(t1)
ffffffffc02009a6:	fff7871b          	addiw	a4,a5,-1
ffffffffc02009aa:	85ba                	mv	a1,a4
ffffffffc02009ac:	04e8d563          	ble	a4,a7,ffffffffc02009f6 <buddy_free_pages+0x1b0>
ffffffffc02009b0:	37f9                	addiw	a5,a5,-2
ffffffffc02009b2:	411787bb          	subw	a5,a5,a7
ffffffffc02009b6:	02079613          	slli	a2,a5,0x20
ffffffffc02009ba:	9201                	srli	a2,a2,0x20
ffffffffc02009bc:	011607b3          	add	a5,a2,a7
ffffffffc02009c0:	00179613          	slli	a2,a5,0x1
ffffffffc02009c4:	963e                	add	a2,a2,a5
ffffffffc02009c6:	98f2                	add	a7,a7,t3
ffffffffc02009c8:	088e                	slli	a7,a7,0x3
ffffffffc02009ca:	060e                	slli	a2,a2,0x3
ffffffffc02009cc:	00019797          	auipc	a5,0x19
ffffffffc02009d0:	32478793          	addi	a5,a5,804 # ffffffffc0219cf0 <rec+0x18>
ffffffffc02009d4:	9846                	add	a6,a6,a7
ffffffffc02009d6:	963e                	add	a2,a2,a5
        rec[i] = rec[i + 1];
ffffffffc02009d8:	01883683          	ld	a3,24(a6)
ffffffffc02009dc:	02083703          	ld	a4,32(a6)
ffffffffc02009e0:	02883783          	ld	a5,40(a6)
ffffffffc02009e4:	00d83023          	sd	a3,0(a6)
ffffffffc02009e8:	00e83423          	sd	a4,8(a6)
ffffffffc02009ec:	00f83823          	sd	a5,16(a6)
ffffffffc02009f0:	0861                	addi	a6,a6,24
    for (i = pos; i < nr_block - 1; i++) // 清除此次的分配记录，即从分配数组里面把后面的数据往前挪
ffffffffc02009f2:	ff0613e3          	bne	a2,a6,ffffffffc02009d8 <buddy_free_pages+0x192>
    nr_block--; // 更新分配块数的值
ffffffffc02009f6:	00006797          	auipc	a5,0x6
ffffffffc02009fa:	a4b7ad23          	sw	a1,-1446(a5) # ffffffffc0206450 <nr_block>
ffffffffc02009fe:	8082                	ret
            self[index].longest = node_size;
ffffffffc0200a00:	c354                	sw	a3,4(a4)
ffffffffc0200a02:	bf89                	j	ffffffffc0200954 <buddy_free_pages+0x10e>
ffffffffc0200a04:	8082                	ret
    for (i = 0; i < nr_block; i++) // nr_block是已分配的块数
ffffffffc0200a06:	88be                	mv	a7,a5
ffffffffc0200a08:	b559                	j	ffffffffc020088e <buddy_free_pages+0x48>
    node_size = 1;
ffffffffc0200a0a:	4685                	li	a3,1
    self[index].longest = node_size; // 这里应该是node_size，也就是从1那层开始改变
ffffffffc0200a0c:	c354                	sw	a3,4(a4)
ffffffffc0200a0e:	b799                	j	ffffffffc0200954 <buddy_free_pages+0x10e>
    for (i = 0; i < nr_block; i++) // nr_block是已分配的块数
ffffffffc0200a10:	4881                	li	a7,0
ffffffffc0200a12:	00019817          	auipc	a6,0x19
ffffffffc0200a16:	2c680813          	addi	a6,a6,710 # ffffffffc0219cd8 <rec>
ffffffffc0200a1a:	bd95                	j	ffffffffc020088e <buddy_free_pages+0x48>
ffffffffc0200a1c:	4881                	li	a7,0
ffffffffc0200a1e:	bd85                	j	ffffffffc020088e <buddy_free_pages+0x48>
{
ffffffffc0200a20:	1141                	addi	sp,sp,-16
    assert(self && offset >= 0 && offset < self->size); // 是否合法
ffffffffc0200a22:	00001697          	auipc	a3,0x1
ffffffffc0200a26:	75668693          	addi	a3,a3,1878 # ffffffffc0202178 <commands+0x7d8>
ffffffffc0200a2a:	00001617          	auipc	a2,0x1
ffffffffc0200a2e:	77e60613          	addi	a2,a2,1918 # ffffffffc02021a8 <commands+0x808>
ffffffffc0200a32:	0e800593          	li	a1,232
ffffffffc0200a36:	00001517          	auipc	a0,0x1
ffffffffc0200a3a:	78a50513          	addi	a0,a0,1930 # ffffffffc02021c0 <commands+0x820>
{
ffffffffc0200a3e:	e406                	sd	ra,8(sp)
    assert(self && offset >= 0 && offset < self->size); // 是否合法
ffffffffc0200a40:	96dff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200a44 <buddy_check>:


static void
buddy_check(void) {
ffffffffc0200a44:	7179                	addi	sp,sp,-48
    cprintf("=============Stage 1============\n");
ffffffffc0200a46:	00001517          	auipc	a0,0x1
ffffffffc0200a4a:	58a50513          	addi	a0,a0,1418 # ffffffffc0201fd0 <commands+0x630>
buddy_check(void) {
ffffffffc0200a4e:	f406                	sd	ra,40(sp)
ffffffffc0200a50:	f022                	sd	s0,32(sp)
ffffffffc0200a52:	ec26                	sd	s1,24(sp)
ffffffffc0200a54:	e84a                	sd	s2,16(sp)
ffffffffc0200a56:	e44e                	sd	s3,8(sp)
    cprintf("=============Stage 1============\n");
ffffffffc0200a58:	e5eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    struct Page *p0, *A, *B,*C,*D;
    p0 = A = B = C = D =NULL;
    
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a5c:	4505                	li	a0,1
ffffffffc0200a5e:	65a000ef          	jal	ra,ffffffffc02010b8 <alloc_pages>
ffffffffc0200a62:	24050d63          	beqz	a0,ffffffffc0200cbc <buddy_check+0x278>
ffffffffc0200a66:	842a                	mv	s0,a0
    assert((A = alloc_page()) != NULL);
ffffffffc0200a68:	4505                	li	a0,1
ffffffffc0200a6a:	64e000ef          	jal	ra,ffffffffc02010b8 <alloc_pages>
ffffffffc0200a6e:	84aa                	mv	s1,a0
ffffffffc0200a70:	22050663          	beqz	a0,ffffffffc0200c9c <buddy_check+0x258>
    assert((B = alloc_page()) != NULL);
ffffffffc0200a74:	4505                	li	a0,1
ffffffffc0200a76:	642000ef          	jal	ra,ffffffffc02010b8 <alloc_pages>
ffffffffc0200a7a:	892a                	mv	s2,a0
ffffffffc0200a7c:	20050063          	beqz	a0,ffffffffc0200c7c <buddy_check+0x238>

    assert(p0 != A && p0 != B && A != B);
ffffffffc0200a80:	1a940e63          	beq	s0,s1,ffffffffc0200c3c <buddy_check+0x1f8>
ffffffffc0200a84:	1aa40c63          	beq	s0,a0,ffffffffc0200c3c <buddy_check+0x1f8>
ffffffffc0200a88:	1aa48a63          	beq	s1,a0,ffffffffc0200c3c <buddy_check+0x1f8>
    assert(page_ref(p0) == 0 && page_ref(A) == 0 && page_ref(B) == 0);
ffffffffc0200a8c:	401c                	lw	a5,0(s0)
ffffffffc0200a8e:	1c079763          	bnez	a5,ffffffffc0200c5c <buddy_check+0x218>
ffffffffc0200a92:	409c                	lw	a5,0(s1)
ffffffffc0200a94:	1c079463          	bnez	a5,ffffffffc0200c5c <buddy_check+0x218>
ffffffffc0200a98:	411c                	lw	a5,0(a0)
ffffffffc0200a9a:	1c079163          	bnez	a5,ffffffffc0200c5c <buddy_check+0x218>
    free_page(p0);
ffffffffc0200a9e:	4585                	li	a1,1
ffffffffc0200aa0:	8522                	mv	a0,s0
ffffffffc0200aa2:	65a000ef          	jal	ra,ffffffffc02010fc <free_pages>
    free_page(A);
ffffffffc0200aa6:	8526                	mv	a0,s1
ffffffffc0200aa8:	4585                	li	a1,1
ffffffffc0200aaa:	652000ef          	jal	ra,ffffffffc02010fc <free_pages>
    free_page(B);
ffffffffc0200aae:	4585                	li	a1,1
ffffffffc0200ab0:	854a                	mv	a0,s2
ffffffffc0200ab2:	64a000ef          	jal	ra,ffffffffc02010fc <free_pages>
    
    
    cprintf("=============Stage 2============\n");
ffffffffc0200ab6:	00001517          	auipc	a0,0x1
ffffffffc0200aba:	60250513          	addi	a0,a0,1538 # ffffffffc02020b8 <commands+0x718>
ffffffffc0200abe:	df8ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    A=alloc_pages(500);
ffffffffc0200ac2:	1f400513          	li	a0,500
ffffffffc0200ac6:	5f2000ef          	jal	ra,ffffffffc02010b8 <alloc_pages>
ffffffffc0200aca:	84aa                	mv	s1,a0
    B=alloc_pages(500);
ffffffffc0200acc:	1f400513          	li	a0,500
ffffffffc0200ad0:	5e8000ef          	jal	ra,ffffffffc02010b8 <alloc_pages>
ffffffffc0200ad4:	892a                	mv	s2,a0
    cprintf("A %p\n",A);
ffffffffc0200ad6:	85a6                	mv	a1,s1
ffffffffc0200ad8:	00001517          	auipc	a0,0x1
ffffffffc0200adc:	60850513          	addi	a0,a0,1544 # ffffffffc02020e0 <commands+0x740>
ffffffffc0200ae0:	dd6ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("B %p\n",B);
ffffffffc0200ae4:	85ca                	mv	a1,s2
ffffffffc0200ae6:	00001517          	auipc	a0,0x1
ffffffffc0200aea:	60250513          	addi	a0,a0,1538 # ffffffffc02020e8 <commands+0x748>
ffffffffc0200aee:	dc8ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(A,250);
ffffffffc0200af2:	8526                	mv	a0,s1
ffffffffc0200af4:	0fa00593          	li	a1,250
ffffffffc0200af8:	604000ef          	jal	ra,ffffffffc02010fc <free_pages>
    free_pages(B,500);
ffffffffc0200afc:	854a                	mv	a0,s2
ffffffffc0200afe:	1f400593          	li	a1,500
ffffffffc0200b02:	5fa000ef          	jal	ra,ffffffffc02010fc <free_pages>
    free_pages(A+250,250);
ffffffffc0200b06:	6509                	lui	a0,0x2
ffffffffc0200b08:	71050513          	addi	a0,a0,1808 # 2710 <BASE_ADDRESS-0xffffffffc01fd8f0>
ffffffffc0200b0c:	0fa00593          	li	a1,250
ffffffffc0200b10:	9526                	add	a0,a0,s1
ffffffffc0200b12:	5ea000ef          	jal	ra,ffffffffc02010fc <free_pages>
    A=alloc_pages(500);
ffffffffc0200b16:	1f400513          	li	a0,500
ffffffffc0200b1a:	59e000ef          	jal	ra,ffffffffc02010b8 <alloc_pages>
ffffffffc0200b1e:	84aa                	mv	s1,a0
    cprintf("A %p\n",A);
ffffffffc0200b20:	85aa                	mv	a1,a0
ffffffffc0200b22:	00001517          	auipc	a0,0x1
ffffffffc0200b26:	5be50513          	addi	a0,a0,1470 # ffffffffc02020e0 <commands+0x740>
ffffffffc0200b2a:	d8cff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(A,500);
ffffffffc0200b2e:	1f400593          	li	a1,500
ffffffffc0200b32:	8526                	mv	a0,s1
ffffffffc0200b34:	5c8000ef          	jal	ra,ffffffffc02010fc <free_pages>
    
    
    cprintf("=============Stage 3============\n");
ffffffffc0200b38:	00001517          	auipc	a0,0x1
ffffffffc0200b3c:	5b850513          	addi	a0,a0,1464 # ffffffffc02020f0 <commands+0x750>
ffffffffc0200b40:	d76ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    //以下是根据链接中的样例测试编写的
    A=alloc_pages(65);  
ffffffffc0200b44:	04100513          	li	a0,65
ffffffffc0200b48:	570000ef          	jal	ra,ffffffffc02010b8 <alloc_pages>
ffffffffc0200b4c:	892a                	mv	s2,a0
    B=alloc_pages(33);
ffffffffc0200b4e:	02100513          	li	a0,33
ffffffffc0200b52:	566000ef          	jal	ra,ffffffffc02010b8 <alloc_pages>
    assert(A+128==B);//检查是否相邻
ffffffffc0200b56:	6785                	lui	a5,0x1
ffffffffc0200b58:	40078793          	addi	a5,a5,1024 # 1400 <BASE_ADDRESS-0xffffffffc01fec00>
ffffffffc0200b5c:	97ca                	add	a5,a5,s2
    B=alloc_pages(33);
ffffffffc0200b5e:	84aa                	mv	s1,a0
    assert(A+128==B);//检查是否相邻
ffffffffc0200b60:	1af51e63          	bne	a0,a5,ffffffffc0200d1c <buddy_check+0x2d8>
    cprintf("A %p\n",A);
ffffffffc0200b64:	85ca                	mv	a1,s2
ffffffffc0200b66:	00001517          	auipc	a0,0x1
ffffffffc0200b6a:	57a50513          	addi	a0,a0,1402 # ffffffffc02020e0 <commands+0x740>
ffffffffc0200b6e:	d48ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("B %p\n",B);
ffffffffc0200b72:	85a6                	mv	a1,s1
ffffffffc0200b74:	00001517          	auipc	a0,0x1
ffffffffc0200b78:	57450513          	addi	a0,a0,1396 # ffffffffc02020e8 <commands+0x748>
ffffffffc0200b7c:	d3aff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    

    cprintf("=============Stage 4============\n");
ffffffffc0200b80:	00001517          	auipc	a0,0x1
ffffffffc0200b84:	5a850513          	addi	a0,a0,1448 # ffffffffc0202128 <commands+0x788>
ffffffffc0200b88:	d2eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    C=alloc_pages(80);
ffffffffc0200b8c:	05000513          	li	a0,80
ffffffffc0200b90:	528000ef          	jal	ra,ffffffffc02010b8 <alloc_pages>
    assert(A+256==C);//检查C有没有和A重叠
ffffffffc0200b94:	678d                	lui	a5,0x3
ffffffffc0200b96:	80078793          	addi	a5,a5,-2048 # 2800 <BASE_ADDRESS-0xffffffffc01fd800>
ffffffffc0200b9a:	97ca                	add	a5,a5,s2
    C=alloc_pages(80);
ffffffffc0200b9c:	89aa                	mv	s3,a0
    assert(A+256==C);//检查C有没有和A重叠
ffffffffc0200b9e:	14f51f63          	bne	a0,a5,ffffffffc0200cfc <buddy_check+0x2b8>
    cprintf("C %p\n",C);
ffffffffc0200ba2:	85aa                	mv	a1,a0
ffffffffc0200ba4:	00001517          	auipc	a0,0x1
ffffffffc0200ba8:	5bc50513          	addi	a0,a0,1468 # ffffffffc0202160 <commands+0x7c0>
ffffffffc0200bac:	d0aff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(A,70);//释放A
ffffffffc0200bb0:	854a                	mv	a0,s2
ffffffffc0200bb2:	04600593          	li	a1,70
ffffffffc0200bb6:	546000ef          	jal	ra,ffffffffc02010fc <free_pages>
    cprintf("B %p\n",B);
ffffffffc0200bba:	85a6                	mv	a1,s1
ffffffffc0200bbc:	00001517          	auipc	a0,0x1
ffffffffc0200bc0:	52c50513          	addi	a0,a0,1324 # ffffffffc02020e8 <commands+0x748>
ffffffffc0200bc4:	cf2ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    D=alloc_pages(60);
ffffffffc0200bc8:	03c00513          	li	a0,60
ffffffffc0200bcc:	4ec000ef          	jal	ra,ffffffffc02010b8 <alloc_pages>
    cprintf("D %p\n",D);
ffffffffc0200bd0:	85aa                	mv	a1,a0
    D=alloc_pages(60);
ffffffffc0200bd2:	892a                	mv	s2,a0
    cprintf("D %p\n",D);
ffffffffc0200bd4:	00001517          	auipc	a0,0x1
ffffffffc0200bd8:	59450513          	addi	a0,a0,1428 # ffffffffc0202168 <commands+0x7c8>
ffffffffc0200bdc:	cdaff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    assert(B+64==D);//检查B，D是否相邻
ffffffffc0200be0:	6785                	lui	a5,0x1
ffffffffc0200be2:	a0078793          	addi	a5,a5,-1536 # a00 <BASE_ADDRESS-0xffffffffc01ff600>
ffffffffc0200be6:	97a6                	add	a5,a5,s1
ffffffffc0200be8:	0ef91a63          	bne	s2,a5,ffffffffc0200cdc <buddy_check+0x298>
    free_pages(B,35);
ffffffffc0200bec:	8526                	mv	a0,s1
ffffffffc0200bee:	02300593          	li	a1,35
ffffffffc0200bf2:	50a000ef          	jal	ra,ffffffffc02010fc <free_pages>
    cprintf("D %p\n",D);
ffffffffc0200bf6:	85ca                	mv	a1,s2
ffffffffc0200bf8:	00001517          	auipc	a0,0x1
ffffffffc0200bfc:	57050513          	addi	a0,a0,1392 # ffffffffc0202168 <commands+0x7c8>
ffffffffc0200c00:	cb6ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(D,60);
ffffffffc0200c04:	854a                	mv	a0,s2
ffffffffc0200c06:	03c00593          	li	a1,60
ffffffffc0200c0a:	4f2000ef          	jal	ra,ffffffffc02010fc <free_pages>
    cprintf("C %p\n",C);
ffffffffc0200c0e:	85ce                	mv	a1,s3
ffffffffc0200c10:	00001517          	auipc	a0,0x1
ffffffffc0200c14:	55050513          	addi	a0,a0,1360 # ffffffffc0202160 <commands+0x7c0>
ffffffffc0200c18:	c9eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(C,80);
ffffffffc0200c1c:	854e                	mv	a0,s3
ffffffffc0200c1e:	05000593          	li	a1,80
ffffffffc0200c22:	4da000ef          	jal	ra,ffffffffc02010fc <free_pages>
    free_pages(p0,1000);//全部释放
ffffffffc0200c26:	8522                	mv	a0,s0
}
ffffffffc0200c28:	7402                	ld	s0,32(sp)
ffffffffc0200c2a:	70a2                	ld	ra,40(sp)
ffffffffc0200c2c:	64e2                	ld	s1,24(sp)
ffffffffc0200c2e:	6942                	ld	s2,16(sp)
ffffffffc0200c30:	69a2                	ld	s3,8(sp)
    free_pages(p0,1000);//全部释放
ffffffffc0200c32:	3e800593          	li	a1,1000
}
ffffffffc0200c36:	6145                	addi	sp,sp,48
    free_pages(p0,1000);//全部释放
ffffffffc0200c38:	4c40006f          	j	ffffffffc02010fc <free_pages>
    assert(p0 != A && p0 != B && A != B);
ffffffffc0200c3c:	00001697          	auipc	a3,0x1
ffffffffc0200c40:	41c68693          	addi	a3,a3,1052 # ffffffffc0202058 <commands+0x6b8>
ffffffffc0200c44:	00001617          	auipc	a2,0x1
ffffffffc0200c48:	56460613          	addi	a2,a2,1380 # ffffffffc02021a8 <commands+0x808>
ffffffffc0200c4c:	12500593          	li	a1,293
ffffffffc0200c50:	00001517          	auipc	a0,0x1
ffffffffc0200c54:	57050513          	addi	a0,a0,1392 # ffffffffc02021c0 <commands+0x820>
ffffffffc0200c58:	f54ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(A) == 0 && page_ref(B) == 0);
ffffffffc0200c5c:	00001697          	auipc	a3,0x1
ffffffffc0200c60:	41c68693          	addi	a3,a3,1052 # ffffffffc0202078 <commands+0x6d8>
ffffffffc0200c64:	00001617          	auipc	a2,0x1
ffffffffc0200c68:	54460613          	addi	a2,a2,1348 # ffffffffc02021a8 <commands+0x808>
ffffffffc0200c6c:	12600593          	li	a1,294
ffffffffc0200c70:	00001517          	auipc	a0,0x1
ffffffffc0200c74:	55050513          	addi	a0,a0,1360 # ffffffffc02021c0 <commands+0x820>
ffffffffc0200c78:	f34ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((B = alloc_page()) != NULL);
ffffffffc0200c7c:	00001697          	auipc	a3,0x1
ffffffffc0200c80:	3bc68693          	addi	a3,a3,956 # ffffffffc0202038 <commands+0x698>
ffffffffc0200c84:	00001617          	auipc	a2,0x1
ffffffffc0200c88:	52460613          	addi	a2,a2,1316 # ffffffffc02021a8 <commands+0x808>
ffffffffc0200c8c:	12300593          	li	a1,291
ffffffffc0200c90:	00001517          	auipc	a0,0x1
ffffffffc0200c94:	53050513          	addi	a0,a0,1328 # ffffffffc02021c0 <commands+0x820>
ffffffffc0200c98:	f14ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((A = alloc_page()) != NULL);
ffffffffc0200c9c:	00001697          	auipc	a3,0x1
ffffffffc0200ca0:	37c68693          	addi	a3,a3,892 # ffffffffc0202018 <commands+0x678>
ffffffffc0200ca4:	00001617          	auipc	a2,0x1
ffffffffc0200ca8:	50460613          	addi	a2,a2,1284 # ffffffffc02021a8 <commands+0x808>
ffffffffc0200cac:	12200593          	li	a1,290
ffffffffc0200cb0:	00001517          	auipc	a0,0x1
ffffffffc0200cb4:	51050513          	addi	a0,a0,1296 # ffffffffc02021c0 <commands+0x820>
ffffffffc0200cb8:	ef4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200cbc:	00001697          	auipc	a3,0x1
ffffffffc0200cc0:	33c68693          	addi	a3,a3,828 # ffffffffc0201ff8 <commands+0x658>
ffffffffc0200cc4:	00001617          	auipc	a2,0x1
ffffffffc0200cc8:	4e460613          	addi	a2,a2,1252 # ffffffffc02021a8 <commands+0x808>
ffffffffc0200ccc:	12100593          	li	a1,289
ffffffffc0200cd0:	00001517          	auipc	a0,0x1
ffffffffc0200cd4:	4f050513          	addi	a0,a0,1264 # ffffffffc02021c0 <commands+0x820>
ffffffffc0200cd8:	ed4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(B+64==D);//检查B，D是否相邻
ffffffffc0200cdc:	00001697          	auipc	a3,0x1
ffffffffc0200ce0:	49468693          	addi	a3,a3,1172 # ffffffffc0202170 <commands+0x7d0>
ffffffffc0200ce4:	00001617          	auipc	a2,0x1
ffffffffc0200ce8:	4c460613          	addi	a2,a2,1220 # ffffffffc02021a8 <commands+0x808>
ffffffffc0200cec:	14a00593          	li	a1,330
ffffffffc0200cf0:	00001517          	auipc	a0,0x1
ffffffffc0200cf4:	4d050513          	addi	a0,a0,1232 # ffffffffc02021c0 <commands+0x820>
ffffffffc0200cf8:	eb4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(A+256==C);//检查C有没有和A重叠
ffffffffc0200cfc:	00001697          	auipc	a3,0x1
ffffffffc0200d00:	45468693          	addi	a3,a3,1108 # ffffffffc0202150 <commands+0x7b0>
ffffffffc0200d04:	00001617          	auipc	a2,0x1
ffffffffc0200d08:	4a460613          	addi	a2,a2,1188 # ffffffffc02021a8 <commands+0x808>
ffffffffc0200d0c:	14400593          	li	a1,324
ffffffffc0200d10:	00001517          	auipc	a0,0x1
ffffffffc0200d14:	4b050513          	addi	a0,a0,1200 # ffffffffc02021c0 <commands+0x820>
ffffffffc0200d18:	e94ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(A+128==B);//检查是否相邻
ffffffffc0200d1c:	00001697          	auipc	a3,0x1
ffffffffc0200d20:	3fc68693          	addi	a3,a3,1020 # ffffffffc0202118 <commands+0x778>
ffffffffc0200d24:	00001617          	auipc	a2,0x1
ffffffffc0200d28:	48460613          	addi	a2,a2,1156 # ffffffffc02021a8 <commands+0x808>
ffffffffc0200d2c:	13d00593          	li	a1,317
ffffffffc0200d30:	00001517          	auipc	a0,0x1
ffffffffc0200d34:	49050513          	addi	a0,a0,1168 # ffffffffc02021c0 <commands+0x820>
ffffffffc0200d38:	e74ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200d3c <buddy_new.part.2>:
    root[0].size = size;
ffffffffc0200d3c:	00005717          	auipc	a4,0x5
ffffffffc0200d40:	70a72e23          	sw	a0,1820(a4) # ffffffffc0206458 <root>
    node_size = size * 2; // 认为总结点数是size*2
ffffffffc0200d44:	0015161b          	slliw	a2,a0,0x1
    for (i = 0; i < 2 * size - 1; ++i)
ffffffffc0200d48:	4705                	li	a4,1
ffffffffc0200d4a:	02c75563          	ble	a2,a4,ffffffffc0200d74 <buddy_new.part.2+0x38>
ffffffffc0200d4e:	00005717          	auipc	a4,0x5
ffffffffc0200d52:	70e70713          	addi	a4,a4,1806 # ffffffffc020645c <root+0x4>
ffffffffc0200d56:	fff6051b          	addiw	a0,a2,-1
ffffffffc0200d5a:	4781                	li	a5,0
        if (IS_POWER_OF_2(i + 1)) // 如果i+1是2的倍数，那么该节点所表示的二叉树就要到下一层了
ffffffffc0200d5c:	0017869b          	addiw	a3,a5,1
ffffffffc0200d60:	00f6f5b3          	and	a1,a3,a5
ffffffffc0200d64:	87b6                	mv	a5,a3
ffffffffc0200d66:	e199                	bnez	a1,ffffffffc0200d6c <buddy_new.part.2+0x30>
            node_size /= 2;
ffffffffc0200d68:	0016561b          	srliw	a2,a2,0x1
        root[i].longest = node_size; // longest是该节点所表示的初始空闲空间块数
ffffffffc0200d6c:	c310                	sw	a2,0(a4)
ffffffffc0200d6e:	0721                	addi	a4,a4,8
    for (i = 0; i < 2 * size - 1; ++i)
ffffffffc0200d70:	fea796e3          	bne	a5,a0,ffffffffc0200d5c <buddy_new.part.2+0x20>
}
ffffffffc0200d74:	8082                	ret

ffffffffc0200d76 <buddy_init_memmap>:
{
ffffffffc0200d76:	1141                	addi	sp,sp,-16
ffffffffc0200d78:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d7a:	c5f5                	beqz	a1,ffffffffc0200e66 <buddy_init_memmap+0xf0>
    for (; p != base + n; p++)
ffffffffc0200d7c:	00259613          	slli	a2,a1,0x2
ffffffffc0200d80:	962e                	add	a2,a2,a1
ffffffffc0200d82:	060e                	slli	a2,a2,0x3
ffffffffc0200d84:	962a                	add	a2,a2,a0
ffffffffc0200d86:	0aa60b63          	beq	a2,a0,ffffffffc0200e3c <buddy_init_memmap+0xc6>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d8a:	651c                	ld	a5,8(a0)
        assert(PageReserved(p));
ffffffffc0200d8c:	8b85                	andi	a5,a5,1
ffffffffc0200d8e:	cfc5                	beqz	a5,ffffffffc0200e46 <buddy_init_memmap+0xd0>
ffffffffc0200d90:	00005697          	auipc	a3,0x5
ffffffffc0200d94:	6a868693          	addi	a3,a3,1704 # ffffffffc0206438 <free_area>
        p->property = 1;
ffffffffc0200d98:	4885                	li	a7,1
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200d9a:	4809                	li	a6,2
ffffffffc0200d9c:	a021                	j	ffffffffc0200da4 <buddy_init_memmap+0x2e>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d9e:	651c                	ld	a5,8(a0)
        assert(PageReserved(p));
ffffffffc0200da0:	8b85                	andi	a5,a5,1
ffffffffc0200da2:	c3d5                	beqz	a5,ffffffffc0200e46 <buddy_init_memmap+0xd0>
        p->flags = 0;
ffffffffc0200da4:	00053423          	sd	zero,8(a0)
        p->property = 1;
ffffffffc0200da8:	01152823          	sw	a7,16(a0)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200dac:	00052023          	sw	zero,0(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200db0:	00850793          	addi	a5,a0,8
ffffffffc0200db4:	4107b02f          	amoor.d	zero,a6,(a5)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200db8:	629c                	ld	a5,0(a3)
ffffffffc0200dba:	01850713          	addi	a4,a0,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0200dbe:	00005317          	auipc	t1,0x5
ffffffffc0200dc2:	66e33d23          	sd	a4,1658(t1) # ffffffffc0206438 <free_area>
ffffffffc0200dc6:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200dc8:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc0200dca:	ed1c                	sd	a5,24(a0)
    for (; p != base + n; p++)
ffffffffc0200dcc:	02850513          	addi	a0,a0,40
ffffffffc0200dd0:	fca617e3          	bne	a2,a0,ffffffffc0200d9e <buddy_init_memmap+0x28>
    int allocpages = UINT32_ROUND_DOWN(n);
ffffffffc0200dd4:	0015d793          	srli	a5,a1,0x1
ffffffffc0200dd8:	8fcd                	or	a5,a5,a1
ffffffffc0200dda:	0027d713          	srli	a4,a5,0x2
ffffffffc0200dde:	8fd9                	or	a5,a5,a4
ffffffffc0200de0:	0047d713          	srli	a4,a5,0x4
ffffffffc0200de4:	8f5d                	or	a4,a4,a5
ffffffffc0200de6:	00875793          	srli	a5,a4,0x8
ffffffffc0200dea:	8f5d                	or	a4,a4,a5
    nr_free += n;
ffffffffc0200dec:	4a94                	lw	a3,16(a3)
    int allocpages = UINT32_ROUND_DOWN(n);
ffffffffc0200dee:	01075793          	srli	a5,a4,0x10
    nr_free += n;
ffffffffc0200df2:	0005851b          	sext.w	a0,a1
    int allocpages = UINT32_ROUND_DOWN(n);
ffffffffc0200df6:	8fd9                	or	a5,a5,a4
ffffffffc0200df8:	8385                	srli	a5,a5,0x1
    nr_free += n;
ffffffffc0200dfa:	00a6873b          	addw	a4,a3,a0
ffffffffc0200dfe:	00005697          	auipc	a3,0x5
ffffffffc0200e02:	64e6a523          	sw	a4,1610(a3) # ffffffffc0206448 <free_area+0x10>
    int allocpages = UINT32_ROUND_DOWN(n);
ffffffffc0200e06:	8dfd                	and	a1,a1,a5
ffffffffc0200e08:	e19d                	bnez	a1,ffffffffc0200e2e <buddy_init_memmap+0xb8>
    nr_block = 0;
ffffffffc0200e0a:	00005797          	auipc	a5,0x5
ffffffffc0200e0e:	6407a323          	sw	zero,1606(a5) # ffffffffc0206450 <nr_block>
    if (size < 1 || !IS_POWER_OF_2(size))
ffffffffc0200e12:	00a05b63          	blez	a0,ffffffffc0200e28 <buddy_init_memmap+0xb2>
ffffffffc0200e16:	fff5079b          	addiw	a5,a0,-1
ffffffffc0200e1a:	8fe9                	and	a5,a5,a0
ffffffffc0200e1c:	2781                	sext.w	a5,a5
ffffffffc0200e1e:	e789                	bnez	a5,ffffffffc0200e28 <buddy_init_memmap+0xb2>
}
ffffffffc0200e20:	60a2                	ld	ra,8(sp)
ffffffffc0200e22:	0141                	addi	sp,sp,16
ffffffffc0200e24:	f19ff06f          	j	ffffffffc0200d3c <buddy_new.part.2>
ffffffffc0200e28:	60a2                	ld	ra,8(sp)
ffffffffc0200e2a:	0141                	addi	sp,sp,16
ffffffffc0200e2c:	8082                	ret
    int allocpages = UINT32_ROUND_DOWN(n);
ffffffffc0200e2e:	fff7c713          	not	a4,a5
ffffffffc0200e32:	00a777b3          	and	a5,a4,a0
ffffffffc0200e36:	0007851b          	sext.w	a0,a5
ffffffffc0200e3a:	bfc1                	j	ffffffffc0200e0a <buddy_init_memmap+0x94>
ffffffffc0200e3c:	00005697          	auipc	a3,0x5
ffffffffc0200e40:	5fc68693          	addi	a3,a3,1532 # ffffffffc0206438 <free_area>
ffffffffc0200e44:	bf41                	j	ffffffffc0200dd4 <buddy_init_memmap+0x5e>
        assert(PageReserved(p));
ffffffffc0200e46:	00001697          	auipc	a3,0x1
ffffffffc0200e4a:	3a268693          	addi	a3,a3,930 # ffffffffc02021e8 <commands+0x848>
ffffffffc0200e4e:	00001617          	auipc	a2,0x1
ffffffffc0200e52:	35a60613          	addi	a2,a2,858 # ffffffffc02021a8 <commands+0x808>
ffffffffc0200e56:	05e00593          	li	a1,94
ffffffffc0200e5a:	00001517          	auipc	a0,0x1
ffffffffc0200e5e:	36650513          	addi	a0,a0,870 # ffffffffc02021c0 <commands+0x820>
ffffffffc0200e62:	d4aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc0200e66:	00001697          	auipc	a3,0x1
ffffffffc0200e6a:	37a68693          	addi	a3,a3,890 # ffffffffc02021e0 <commands+0x840>
ffffffffc0200e6e:	00001617          	auipc	a2,0x1
ffffffffc0200e72:	33a60613          	addi	a2,a2,826 # ffffffffc02021a8 <commands+0x808>
ffffffffc0200e76:	05a00593          	li	a1,90
ffffffffc0200e7a:	00001517          	auipc	a0,0x1
ffffffffc0200e7e:	34650513          	addi	a0,a0,838 # ffffffffc02021c0 <commands+0x820>
ffffffffc0200e82:	d2aff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200e86 <buddy2_alloc>:
{                       // size就是这次要分配的物理页大小
ffffffffc0200e86:	882a                	mv	a6,a0
    if (self == NULL) // 无法分配
ffffffffc0200e88:	c169                	beqz	a0,ffffffffc0200f4a <buddy2_alloc+0xc4>
    if (size <= 0) // 分配不合理
ffffffffc0200e8a:	4605                	li	a2,1
ffffffffc0200e8c:	00b05963          	blez	a1,ffffffffc0200e9e <buddy2_alloc+0x18>
    else if (!IS_POWER_OF_2(size)) // 不为2的幂时，取比size更大的2的n次幂
ffffffffc0200e90:	fff5879b          	addiw	a5,a1,-1
ffffffffc0200e94:	8fed                	and	a5,a5,a1
ffffffffc0200e96:	2781                	sext.w	a5,a5
ffffffffc0200e98:	0005861b          	sext.w	a2,a1
ffffffffc0200e9c:	ebcd                	bnez	a5,ffffffffc0200f4e <buddy2_alloc+0xc8>
    if (self[index].longest < size) // 根据根节点的longest，发现可分配内存不足，也返回
ffffffffc0200e9e:	00482783          	lw	a5,4(a6)
ffffffffc0200ea2:	0ac7e463          	bltu	a5,a2,ffffffffc0200f4a <buddy2_alloc+0xc4>
    for (node_size = self->size; node_size != size; node_size /= 2)
ffffffffc0200ea6:	00082503          	lw	a0,0(a6)
ffffffffc0200eaa:	0cc50763          	beq	a0,a2,ffffffffc0200f78 <buddy2_alloc+0xf2>
ffffffffc0200eae:	85aa                	mv	a1,a0
    unsigned index = 0; // 节点的标号
ffffffffc0200eb0:	4781                	li	a5,0
        if (self[LEFT_LEAF(index)].longest >= size)
ffffffffc0200eb2:	0017989b          	slliw	a7,a5,0x1
ffffffffc0200eb6:	0018879b          	addiw	a5,a7,1
ffffffffc0200eba:	02079713          	slli	a4,a5,0x20
ffffffffc0200ebe:	8375                	srli	a4,a4,0x1d
ffffffffc0200ec0:	9742                	add	a4,a4,a6
ffffffffc0200ec2:	00472303          	lw	t1,4(a4)
ffffffffc0200ec6:	0028869b          	addiw	a3,a7,2
            if (self[RIGHT_LEAF(index)].longest >= size)
ffffffffc0200eca:	02069713          	slli	a4,a3,0x20
ffffffffc0200ece:	8375                	srli	a4,a4,0x1d
ffffffffc0200ed0:	9742                	add	a4,a4,a6
        if (self[LEFT_LEAF(index)].longest >= size)
ffffffffc0200ed2:	00c36763          	bltu	t1,a2,ffffffffc0200ee0 <buddy2_alloc+0x5a>
            if (self[RIGHT_LEAF(index)].longest >= size)
ffffffffc0200ed6:	4358                	lw	a4,4(a4)
ffffffffc0200ed8:	00c76763          	bltu	a4,a2,ffffffffc0200ee6 <buddy2_alloc+0x60>
                index = self[LEFT_LEAF(index)].longest <= self[RIGHT_LEAF(index)].longest ? LEFT_LEAF(index) : RIGHT_LEAF(index);
ffffffffc0200edc:	00677563          	bleu	t1,a4,ffffffffc0200ee6 <buddy2_alloc+0x60>
            index = RIGHT_LEAF(index);
ffffffffc0200ee0:	87b6                	mv	a5,a3
        if (self[LEFT_LEAF(index)].longest >= size)
ffffffffc0200ee2:	0038869b          	addiw	a3,a7,3
    for (node_size = self->size; node_size != size; node_size /= 2)
ffffffffc0200ee6:	0015d59b          	srliw	a1,a1,0x1
ffffffffc0200eea:	fcc594e3          	bne	a1,a2,ffffffffc0200eb2 <buddy2_alloc+0x2c>
    offset = (index + 1) * node_size - self->size; // offset得到的是该物理页在双向链表中距离“根节点”的偏移
ffffffffc0200eee:	02d586bb          	mulw	a3,a1,a3
    self[index].longest = 0;                       // 标记节点为已使用
ffffffffc0200ef2:	02079713          	slli	a4,a5,0x20
ffffffffc0200ef6:	8375                	srli	a4,a4,0x1d
ffffffffc0200ef8:	9742                	add	a4,a4,a6
ffffffffc0200efa:	00072223          	sw	zero,4(a4)
    while (index)
ffffffffc0200efe:	40a6853b          	subw	a0,a3,a0
ffffffffc0200f02:	c7a9                	beqz	a5,ffffffffc0200f4c <buddy2_alloc+0xc6>
        index = PARENT(index);
ffffffffc0200f04:	2785                	addiw	a5,a5,1
ffffffffc0200f06:	0017d61b          	srliw	a2,a5,0x1
ffffffffc0200f0a:	367d                	addiw	a2,a2,-1
            MAX(self[LEFT_LEAF(index)].longest, self[RIGHT_LEAF(index)].longest);
ffffffffc0200f0c:	0016169b          	slliw	a3,a2,0x1
ffffffffc0200f10:	ffe7f713          	andi	a4,a5,-2
ffffffffc0200f14:	2685                	addiw	a3,a3,1
ffffffffc0200f16:	1682                	slli	a3,a3,0x20
ffffffffc0200f18:	1702                	slli	a4,a4,0x20
ffffffffc0200f1a:	9281                	srli	a3,a3,0x20
ffffffffc0200f1c:	9301                	srli	a4,a4,0x20
ffffffffc0200f1e:	068e                	slli	a3,a3,0x3
ffffffffc0200f20:	070e                	slli	a4,a4,0x3
ffffffffc0200f22:	9742                	add	a4,a4,a6
ffffffffc0200f24:	96c2                	add	a3,a3,a6
ffffffffc0200f26:	434c                	lw	a1,4(a4)
ffffffffc0200f28:	42d4                	lw	a3,4(a3)
        self[index].longest =
ffffffffc0200f2a:	02061713          	slli	a4,a2,0x20
ffffffffc0200f2e:	8375                	srli	a4,a4,0x1d
            MAX(self[LEFT_LEAF(index)].longest, self[RIGHT_LEAF(index)].longest);
ffffffffc0200f30:	0006831b          	sext.w	t1,a3
ffffffffc0200f34:	0005889b          	sext.w	a7,a1
        index = PARENT(index);
ffffffffc0200f38:	0006079b          	sext.w	a5,a2
        self[index].longest =
ffffffffc0200f3c:	9742                	add	a4,a4,a6
            MAX(self[LEFT_LEAF(index)].longest, self[RIGHT_LEAF(index)].longest);
ffffffffc0200f3e:	01137363          	bleu	a7,t1,ffffffffc0200f44 <buddy2_alloc+0xbe>
ffffffffc0200f42:	86ae                	mv	a3,a1
        self[index].longest =
ffffffffc0200f44:	c354                	sw	a3,4(a4)
    while (index)
ffffffffc0200f46:	ffdd                	bnez	a5,ffffffffc0200f04 <buddy2_alloc+0x7e>
ffffffffc0200f48:	8082                	ret
        return -1;
ffffffffc0200f4a:	557d                	li	a0,-1
}
ffffffffc0200f4c:	8082                	ret
    size |= size >> 1;
ffffffffc0200f4e:	0016579b          	srliw	a5,a2,0x1
ffffffffc0200f52:	8e5d                	or	a2,a2,a5
ffffffffc0200f54:	2601                	sext.w	a2,a2
    size |= size >> 2;
ffffffffc0200f56:	0026579b          	srliw	a5,a2,0x2
ffffffffc0200f5a:	8e5d                	or	a2,a2,a5
ffffffffc0200f5c:	2601                	sext.w	a2,a2
    size |= size >> 4;
ffffffffc0200f5e:	0046579b          	srliw	a5,a2,0x4
ffffffffc0200f62:	8e5d                	or	a2,a2,a5
ffffffffc0200f64:	2601                	sext.w	a2,a2
    size |= size >> 8;
ffffffffc0200f66:	0086579b          	srliw	a5,a2,0x8
ffffffffc0200f6a:	8e5d                	or	a2,a2,a5
ffffffffc0200f6c:	2601                	sext.w	a2,a2
    size |= size >> 16;
ffffffffc0200f6e:	0106579b          	srliw	a5,a2,0x10
ffffffffc0200f72:	8e5d                	or	a2,a2,a5
    return size + 1;
ffffffffc0200f74:	2605                	addiw	a2,a2,1
ffffffffc0200f76:	b725                	j	ffffffffc0200e9e <buddy2_alloc+0x18>
    self[index].longest = 0;                       // 标记节点为已使用
ffffffffc0200f78:	00082223          	sw	zero,4(a6)
ffffffffc0200f7c:	4501                	li	a0,0
ffffffffc0200f7e:	8082                	ret

ffffffffc0200f80 <buddy_alloc_pages>:
{
ffffffffc0200f80:	7179                	addi	sp,sp,-48
ffffffffc0200f82:	f406                	sd	ra,40(sp)
ffffffffc0200f84:	f022                	sd	s0,32(sp)
ffffffffc0200f86:	ec26                	sd	s1,24(sp)
ffffffffc0200f88:	e84a                	sd	s2,16(sp)
ffffffffc0200f8a:	e44e                	sd	s3,8(sp)
ffffffffc0200f8c:	e052                	sd	s4,0(sp)
    assert(n > 0);
ffffffffc0200f8e:	10050563          	beqz	a0,ffffffffc0201098 <buddy_alloc_pages+0x118>
ffffffffc0200f92:	892a                	mv	s2,a0
    if (n > nr_free)
ffffffffc0200f94:	00005797          	auipc	a5,0x5
ffffffffc0200f98:	4b47e783          	lwu	a5,1204(a5) # ffffffffc0206448 <free_area+0x10>
ffffffffc0200f9c:	00005497          	auipc	s1,0x5
ffffffffc0200fa0:	49c48493          	addi	s1,s1,1180 # ffffffffc0206438 <free_area>
        return NULL;
ffffffffc0200fa4:	4501                	li	a0,0
    if (n > nr_free)
ffffffffc0200fa6:	0b27e963          	bltu	a5,s2,ffffffffc0201058 <buddy_alloc_pages+0xd8>
    rec[nr_block].offset = buddy2_alloc(root, n); // 记录偏移量
ffffffffc0200faa:	0009041b          	sext.w	s0,s2
ffffffffc0200fae:	00005a17          	auipc	s4,0x5
ffffffffc0200fb2:	4a2a0a13          	addi	s4,s4,1186 # ffffffffc0206450 <nr_block>
ffffffffc0200fb6:	85a2                	mv	a1,s0
ffffffffc0200fb8:	00005517          	auipc	a0,0x5
ffffffffc0200fbc:	4a050513          	addi	a0,a0,1184 # ffffffffc0206458 <root>
ffffffffc0200fc0:	000a2983          	lw	s3,0(s4)
ffffffffc0200fc4:	ec3ff0ef          	jal	ra,ffffffffc0200e86 <buddy2_alloc>
    for (i = 0; i < rec[nr_block].offset + 1; i++)
ffffffffc0200fc8:	000a2583          	lw	a1,0(s4)
    rec[nr_block].offset = buddy2_alloc(root, n); // 记录偏移量
ffffffffc0200fcc:	00199793          	slli	a5,s3,0x1
ffffffffc0200fd0:	97ce                	add	a5,a5,s3
    for (i = 0; i < rec[nr_block].offset + 1; i++)
ffffffffc0200fd2:	00159893          	slli	a7,a1,0x1
    rec[nr_block].offset = buddy2_alloc(root, n); // 记录偏移量
ffffffffc0200fd6:	00019817          	auipc	a6,0x19
ffffffffc0200fda:	d0280813          	addi	a6,a6,-766 # ffffffffc0219cd8 <rec>
ffffffffc0200fde:	078e                	slli	a5,a5,0x3
    for (i = 0; i < rec[nr_block].offset + 1; i++)
ffffffffc0200fe0:	00b88733          	add	a4,a7,a1
    rec[nr_block].offset = buddy2_alloc(root, n); // 记录偏移量
ffffffffc0200fe4:	97c2                	add	a5,a5,a6
    for (i = 0; i < rec[nr_block].offset + 1; i++)
ffffffffc0200fe6:	070e                	slli	a4,a4,0x3
    rec[nr_block].offset = buddy2_alloc(root, n); // 记录偏移量
ffffffffc0200fe8:	c788                	sw	a0,8(a5)
    for (i = 0; i < rec[nr_block].offset + 1; i++)
ffffffffc0200fea:	9742                	add	a4,a4,a6
ffffffffc0200fec:	4718                	lw	a4,8(a4)
    rec[nr_block].offset = buddy2_alloc(root, n); // 记录偏移量
ffffffffc0200fee:	86a2                	mv	a3,s0
    for (i = 0; i < rec[nr_block].offset + 1; i++)
ffffffffc0200ff0:	0a074263          	bltz	a4,ffffffffc0201094 <buddy_alloc_pages+0x114>
ffffffffc0200ff4:	2705                	addiw	a4,a4,1
ffffffffc0200ff6:	4781                	li	a5,0
    list_entry_t *le = &free_list, *len;
ffffffffc0200ff8:	8626                	mv	a2,s1
    for (i = 0; i < rec[nr_block].offset + 1; i++)
ffffffffc0200ffa:	2785                	addiw	a5,a5,1
    return listelm->next;
ffffffffc0200ffc:	6610                	ld	a2,8(a2)
ffffffffc0200ffe:	fef71ee3          	bne	a4,a5,ffffffffc0200ffa <buddy_alloc_pages+0x7a>
    if (!IS_POWER_OF_2(n))
ffffffffc0201002:	fff90793          	addi	a5,s2,-1
ffffffffc0201006:	0127f933          	and	s2,a5,s2
    page = le2page(le, page_link);
ffffffffc020100a:	fe860513          	addi	a0,a2,-24
    if (!IS_POWER_OF_2(n))
ffffffffc020100e:	8322                	mv	t1,s0
ffffffffc0201010:	04091c63          	bnez	s2,ffffffffc0201068 <buddy_alloc_pages+0xe8>
    rec[nr_block].base = page;     // 记录分配块首页
ffffffffc0201014:	98ae                	add	a7,a7,a1
ffffffffc0201016:	088e                	slli	a7,a7,0x3
ffffffffc0201018:	9846                	add	a6,a6,a7
    nr_block++;
ffffffffc020101a:	2585                	addiw	a1,a1,1
    rec[nr_block].base = page;     // 记录分配块首页
ffffffffc020101c:	00a83023          	sd	a0,0(a6)
    rec[nr_block].nr = allocpages; // 记录分配的页数
ffffffffc0201020:	00d83823          	sd	a3,16(a6)
    nr_block++;
ffffffffc0201024:	00005797          	auipc	a5,0x5
ffffffffc0201028:	42b7a623          	sw	a1,1068(a5) # ffffffffc0206450 <nr_block>
    for (i = 0; i < allocpages; i++)
ffffffffc020102c:	87b2                	mv	a5,a2
ffffffffc020102e:	4701                	li	a4,0
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201030:	5875                	li	a6,-3
ffffffffc0201032:	00d05a63          	blez	a3,ffffffffc0201046 <buddy_alloc_pages+0xc6>
ffffffffc0201036:	678c                	ld	a1,8(a5)
ffffffffc0201038:	17c1                	addi	a5,a5,-16
ffffffffc020103a:	6107b02f          	amoand.d	zero,a6,(a5)
ffffffffc020103e:	2705                	addiw	a4,a4,1
        le = len;
ffffffffc0201040:	87ae                	mv	a5,a1
    for (i = 0; i < allocpages; i++)
ffffffffc0201042:	fee69ae3          	bne	a3,a4,ffffffffc0201036 <buddy_alloc_pages+0xb6>
    nr_free -= allocpages; // 减去已被分配的页数
ffffffffc0201046:	489c                	lw	a5,16(s1)
ffffffffc0201048:	406787bb          	subw	a5,a5,t1
ffffffffc020104c:	00005717          	auipc	a4,0x5
ffffffffc0201050:	3ef72e23          	sw	a5,1020(a4) # ffffffffc0206448 <free_area+0x10>
    page->property = n;
ffffffffc0201054:	fe862c23          	sw	s0,-8(a2)
}
ffffffffc0201058:	70a2                	ld	ra,40(sp)
ffffffffc020105a:	7402                	ld	s0,32(sp)
ffffffffc020105c:	64e2                	ld	s1,24(sp)
ffffffffc020105e:	6942                	ld	s2,16(sp)
ffffffffc0201060:	69a2                	ld	s3,8(sp)
ffffffffc0201062:	6a02                	ld	s4,0(sp)
ffffffffc0201064:	6145                	addi	sp,sp,48
ffffffffc0201066:	8082                	ret
    size |= size >> 1;
ffffffffc0201068:	0014569b          	srliw	a3,s0,0x1
ffffffffc020106c:	8ec1                	or	a3,a3,s0
ffffffffc020106e:	2681                	sext.w	a3,a3
    size |= size >> 2;
ffffffffc0201070:	0026d79b          	srliw	a5,a3,0x2
ffffffffc0201074:	8edd                	or	a3,a3,a5
ffffffffc0201076:	2681                	sext.w	a3,a3
    size |= size >> 4;
ffffffffc0201078:	0046d79b          	srliw	a5,a3,0x4
ffffffffc020107c:	8edd                	or	a3,a3,a5
ffffffffc020107e:	2681                	sext.w	a3,a3
    size |= size >> 8;
ffffffffc0201080:	0086d79b          	srliw	a5,a3,0x8
ffffffffc0201084:	8edd                	or	a3,a3,a5
ffffffffc0201086:	2681                	sext.w	a3,a3
    size |= size >> 16;
ffffffffc0201088:	0106d79b          	srliw	a5,a3,0x10
ffffffffc020108c:	8edd                	or	a3,a3,a5
    return size + 1;
ffffffffc020108e:	2685                	addiw	a3,a3,1
        allocpages = fixsize(n);
ffffffffc0201090:	8336                	mv	t1,a3
ffffffffc0201092:	b749                	j	ffffffffc0201014 <buddy_alloc_pages+0x94>
    list_entry_t *le = &free_list, *len;
ffffffffc0201094:	8626                	mv	a2,s1
ffffffffc0201096:	b7b5                	j	ffffffffc0201002 <buddy_alloc_pages+0x82>
    assert(n > 0);
ffffffffc0201098:	00001697          	auipc	a3,0x1
ffffffffc020109c:	14868693          	addi	a3,a3,328 # ffffffffc02021e0 <commands+0x840>
ffffffffc02010a0:	00001617          	auipc	a2,0x1
ffffffffc02010a4:	10860613          	addi	a2,a2,264 # ffffffffc02021a8 <commands+0x808>
ffffffffc02010a8:	0a700593          	li	a1,167
ffffffffc02010ac:	00001517          	auipc	a0,0x1
ffffffffc02010b0:	11450513          	addi	a0,a0,276 # ffffffffc02021c0 <commands+0x820>
ffffffffc02010b4:	af8ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02010b8 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02010b8:	100027f3          	csrr	a5,sstatus
ffffffffc02010bc:	8b89                	andi	a5,a5,2
ffffffffc02010be:	eb89                	bnez	a5,ffffffffc02010d0 <alloc_pages+0x18>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02010c0:	001ee797          	auipc	a5,0x1ee
ffffffffc02010c4:	82078793          	addi	a5,a5,-2016 # ffffffffc03ee8e0 <pmm_manager>
ffffffffc02010c8:	639c                	ld	a5,0(a5)
ffffffffc02010ca:	0187b303          	ld	t1,24(a5)
ffffffffc02010ce:	8302                	jr	t1
struct Page *alloc_pages(size_t n) {
ffffffffc02010d0:	1141                	addi	sp,sp,-16
ffffffffc02010d2:	e406                	sd	ra,8(sp)
ffffffffc02010d4:	e022                	sd	s0,0(sp)
ffffffffc02010d6:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02010d8:	b8cff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02010dc:	001ee797          	auipc	a5,0x1ee
ffffffffc02010e0:	80478793          	addi	a5,a5,-2044 # ffffffffc03ee8e0 <pmm_manager>
ffffffffc02010e4:	639c                	ld	a5,0(a5)
ffffffffc02010e6:	8522                	mv	a0,s0
ffffffffc02010e8:	6f9c                	ld	a5,24(a5)
ffffffffc02010ea:	9782                	jalr	a5
ffffffffc02010ec:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02010ee:	b70ff0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02010f2:	8522                	mv	a0,s0
ffffffffc02010f4:	60a2                	ld	ra,8(sp)
ffffffffc02010f6:	6402                	ld	s0,0(sp)
ffffffffc02010f8:	0141                	addi	sp,sp,16
ffffffffc02010fa:	8082                	ret

ffffffffc02010fc <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02010fc:	100027f3          	csrr	a5,sstatus
ffffffffc0201100:	8b89                	andi	a5,a5,2
ffffffffc0201102:	eb89                	bnez	a5,ffffffffc0201114 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201104:	001ed797          	auipc	a5,0x1ed
ffffffffc0201108:	7dc78793          	addi	a5,a5,2012 # ffffffffc03ee8e0 <pmm_manager>
ffffffffc020110c:	639c                	ld	a5,0(a5)
ffffffffc020110e:	0207b303          	ld	t1,32(a5)
ffffffffc0201112:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc0201114:	1101                	addi	sp,sp,-32
ffffffffc0201116:	ec06                	sd	ra,24(sp)
ffffffffc0201118:	e822                	sd	s0,16(sp)
ffffffffc020111a:	e426                	sd	s1,8(sp)
ffffffffc020111c:	842a                	mv	s0,a0
ffffffffc020111e:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201120:	b44ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201124:	001ed797          	auipc	a5,0x1ed
ffffffffc0201128:	7bc78793          	addi	a5,a5,1980 # ffffffffc03ee8e0 <pmm_manager>
ffffffffc020112c:	639c                	ld	a5,0(a5)
ffffffffc020112e:	85a6                	mv	a1,s1
ffffffffc0201130:	8522                	mv	a0,s0
ffffffffc0201132:	739c                	ld	a5,32(a5)
ffffffffc0201134:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201136:	6442                	ld	s0,16(sp)
ffffffffc0201138:	60e2                	ld	ra,24(sp)
ffffffffc020113a:	64a2                	ld	s1,8(sp)
ffffffffc020113c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020113e:	b20ff06f          	j	ffffffffc020045e <intr_enable>

ffffffffc0201142 <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc0201142:	00001797          	auipc	a5,0x1
ffffffffc0201146:	0b678793          	addi	a5,a5,182 # ffffffffc02021f8 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020114a:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc020114c:	1101                	addi	sp,sp,-32
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020114e:	00001517          	auipc	a0,0x1
ffffffffc0201152:	0fa50513          	addi	a0,a0,250 # ffffffffc0202248 <buddy_pmm_manager+0x50>
void pmm_init(void) {
ffffffffc0201156:	ec06                	sd	ra,24(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0201158:	001ed717          	auipc	a4,0x1ed
ffffffffc020115c:	78f73423          	sd	a5,1928(a4) # ffffffffc03ee8e0 <pmm_manager>
void pmm_init(void) {
ffffffffc0201160:	e822                	sd	s0,16(sp)
ffffffffc0201162:	e426                	sd	s1,8(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0201164:	001ed417          	auipc	s0,0x1ed
ffffffffc0201168:	77c40413          	addi	s0,s0,1916 # ffffffffc03ee8e0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020116c:	f4bfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pmm_manager->init();
ffffffffc0201170:	601c                	ld	a5,0(s0)
ffffffffc0201172:	679c                	ld	a5,8(a5)
ffffffffc0201174:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201176:	57f5                	li	a5,-3
ffffffffc0201178:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc020117a:	00001517          	auipc	a0,0x1
ffffffffc020117e:	0e650513          	addi	a0,a0,230 # ffffffffc0202260 <buddy_pmm_manager+0x68>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201182:	001ed717          	auipc	a4,0x1ed
ffffffffc0201186:	76f73323          	sd	a5,1894(a4) # ffffffffc03ee8e8 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc020118a:	f2dfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020118e:	46c5                	li	a3,17
ffffffffc0201190:	06ee                	slli	a3,a3,0x1b
ffffffffc0201192:	40100613          	li	a2,1025
ffffffffc0201196:	16fd                	addi	a3,a3,-1
ffffffffc0201198:	0656                	slli	a2,a2,0x15
ffffffffc020119a:	07e005b7          	lui	a1,0x7e00
ffffffffc020119e:	00001517          	auipc	a0,0x1
ffffffffc02011a2:	0da50513          	addi	a0,a0,218 # ffffffffc0202278 <buddy_pmm_manager+0x80>
ffffffffc02011a6:	f11fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02011aa:	777d                	lui	a4,0xfffff
ffffffffc02011ac:	001ee797          	auipc	a5,0x1ee
ffffffffc02011b0:	74b78793          	addi	a5,a5,1867 # ffffffffc03ef8f7 <end+0xfff>
ffffffffc02011b4:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc02011b6:	00088737          	lui	a4,0x88
ffffffffc02011ba:	00005697          	auipc	a3,0x5
ffffffffc02011be:	24e6bf23          	sd	a4,606(a3) # ffffffffc0206418 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02011c2:	4601                	li	a2,0
ffffffffc02011c4:	001ed717          	auipc	a4,0x1ed
ffffffffc02011c8:	72f73623          	sd	a5,1836(a4) # ffffffffc03ee8f0 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02011cc:	4681                	li	a3,0
ffffffffc02011ce:	00005897          	auipc	a7,0x5
ffffffffc02011d2:	24a88893          	addi	a7,a7,586 # ffffffffc0206418 <npage>
ffffffffc02011d6:	001ed597          	auipc	a1,0x1ed
ffffffffc02011da:	71a58593          	addi	a1,a1,1818 # ffffffffc03ee8f0 <pages>
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02011de:	4805                	li	a6,1
ffffffffc02011e0:	fff80537          	lui	a0,0xfff80
ffffffffc02011e4:	a011                	j	ffffffffc02011e8 <pmm_init+0xa6>
ffffffffc02011e6:	619c                	ld	a5,0(a1)
        SetPageReserved(pages + i);
ffffffffc02011e8:	97b2                	add	a5,a5,a2
ffffffffc02011ea:	07a1                	addi	a5,a5,8
ffffffffc02011ec:	4107b02f          	amoor.d	zero,a6,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02011f0:	0008b703          	ld	a4,0(a7)
ffffffffc02011f4:	0685                	addi	a3,a3,1
ffffffffc02011f6:	02860613          	addi	a2,a2,40
ffffffffc02011fa:	00a707b3          	add	a5,a4,a0
ffffffffc02011fe:	fef6e4e3          	bltu	a3,a5,ffffffffc02011e6 <pmm_init+0xa4>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201202:	6190                	ld	a2,0(a1)
ffffffffc0201204:	00271793          	slli	a5,a4,0x2
ffffffffc0201208:	97ba                	add	a5,a5,a4
ffffffffc020120a:	fec006b7          	lui	a3,0xfec00
ffffffffc020120e:	078e                	slli	a5,a5,0x3
ffffffffc0201210:	96b2                	add	a3,a3,a2
ffffffffc0201212:	96be                	add	a3,a3,a5
ffffffffc0201214:	c02007b7          	lui	a5,0xc0200
ffffffffc0201218:	08f6e863          	bltu	a3,a5,ffffffffc02012a8 <pmm_init+0x166>
ffffffffc020121c:	001ed497          	auipc	s1,0x1ed
ffffffffc0201220:	6cc48493          	addi	s1,s1,1740 # ffffffffc03ee8e8 <va_pa_offset>
ffffffffc0201224:	609c                	ld	a5,0(s1)
    if (freemem < mem_end) {
ffffffffc0201226:	45c5                	li	a1,17
ffffffffc0201228:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020122a:	8e9d                	sub	a3,a3,a5
    if (freemem < mem_end) {
ffffffffc020122c:	04b6e963          	bltu	a3,a1,ffffffffc020127e <pmm_init+0x13c>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201230:	601c                	ld	a5,0(s0)
ffffffffc0201232:	7b9c                	ld	a5,48(a5)
ffffffffc0201234:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201236:	00001517          	auipc	a0,0x1
ffffffffc020123a:	0da50513          	addi	a0,a0,218 # ffffffffc0202310 <buddy_pmm_manager+0x118>
ffffffffc020123e:	e79fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201242:	00004697          	auipc	a3,0x4
ffffffffc0201246:	dbe68693          	addi	a3,a3,-578 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020124a:	00005797          	auipc	a5,0x5
ffffffffc020124e:	1cd7bb23          	sd	a3,470(a5) # ffffffffc0206420 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201252:	c02007b7          	lui	a5,0xc0200
ffffffffc0201256:	06f6e563          	bltu	a3,a5,ffffffffc02012c0 <pmm_init+0x17e>
ffffffffc020125a:	609c                	ld	a5,0(s1)
}
ffffffffc020125c:	6442                	ld	s0,16(sp)
ffffffffc020125e:	60e2                	ld	ra,24(sp)
ffffffffc0201260:	64a2                	ld	s1,8(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201262:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc0201264:	8e9d                	sub	a3,a3,a5
ffffffffc0201266:	001ed797          	auipc	a5,0x1ed
ffffffffc020126a:	66d7b923          	sd	a3,1650(a5) # ffffffffc03ee8d8 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020126e:	00001517          	auipc	a0,0x1
ffffffffc0201272:	0c250513          	addi	a0,a0,194 # ffffffffc0202330 <buddy_pmm_manager+0x138>
ffffffffc0201276:	8636                	mv	a2,a3
}
ffffffffc0201278:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020127a:	e3dfe06f          	j	ffffffffc02000b6 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020127e:	6785                	lui	a5,0x1
ffffffffc0201280:	17fd                	addi	a5,a5,-1
ffffffffc0201282:	96be                	add	a3,a3,a5
ffffffffc0201284:	77fd                	lui	a5,0xfffff
ffffffffc0201286:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201288:	00c6d793          	srli	a5,a3,0xc
ffffffffc020128c:	04e7f663          	bleu	a4,a5,ffffffffc02012d8 <pmm_init+0x196>
    pmm_manager->init_memmap(base, n);
ffffffffc0201290:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201292:	97aa                	add	a5,a5,a0
ffffffffc0201294:	00279513          	slli	a0,a5,0x2
ffffffffc0201298:	953e                	add	a0,a0,a5
ffffffffc020129a:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020129c:	8d95                	sub	a1,a1,a3
ffffffffc020129e:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02012a0:	81b1                	srli	a1,a1,0xc
ffffffffc02012a2:	9532                	add	a0,a0,a2
ffffffffc02012a4:	9782                	jalr	a5
ffffffffc02012a6:	b769                	j	ffffffffc0201230 <pmm_init+0xee>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02012a8:	00001617          	auipc	a2,0x1
ffffffffc02012ac:	00060613          	mv	a2,a2
ffffffffc02012b0:	07200593          	li	a1,114
ffffffffc02012b4:	00001517          	auipc	a0,0x1
ffffffffc02012b8:	01c50513          	addi	a0,a0,28 # ffffffffc02022d0 <buddy_pmm_manager+0xd8>
ffffffffc02012bc:	8f0ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02012c0:	00001617          	auipc	a2,0x1
ffffffffc02012c4:	fe860613          	addi	a2,a2,-24 # ffffffffc02022a8 <buddy_pmm_manager+0xb0>
ffffffffc02012c8:	08d00593          	li	a1,141
ffffffffc02012cc:	00001517          	auipc	a0,0x1
ffffffffc02012d0:	00450513          	addi	a0,a0,4 # ffffffffc02022d0 <buddy_pmm_manager+0xd8>
ffffffffc02012d4:	8d8ff0ef          	jal	ra,ffffffffc02003ac <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02012d8:	00001617          	auipc	a2,0x1
ffffffffc02012dc:	00860613          	addi	a2,a2,8 # ffffffffc02022e0 <buddy_pmm_manager+0xe8>
ffffffffc02012e0:	06400593          	li	a1,100
ffffffffc02012e4:	00001517          	auipc	a0,0x1
ffffffffc02012e8:	01c50513          	addi	a0,a0,28 # ffffffffc0202300 <buddy_pmm_manager+0x108>
ffffffffc02012ec:	8c0ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02012f0 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02012f0:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012f4:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02012f6:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012fa:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02012fc:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201300:	f022                	sd	s0,32(sp)
ffffffffc0201302:	ec26                	sd	s1,24(sp)
ffffffffc0201304:	e84a                	sd	s2,16(sp)
ffffffffc0201306:	f406                	sd	ra,40(sp)
ffffffffc0201308:	e44e                	sd	s3,8(sp)
ffffffffc020130a:	84aa                	mv	s1,a0
ffffffffc020130c:	892e                	mv	s2,a1
ffffffffc020130e:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201312:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0201314:	03067e63          	bleu	a6,a2,ffffffffc0201350 <printnum+0x60>
ffffffffc0201318:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020131a:	00805763          	blez	s0,ffffffffc0201328 <printnum+0x38>
ffffffffc020131e:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201320:	85ca                	mv	a1,s2
ffffffffc0201322:	854e                	mv	a0,s3
ffffffffc0201324:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201326:	fc65                	bnez	s0,ffffffffc020131e <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201328:	1a02                	slli	s4,s4,0x20
ffffffffc020132a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020132e:	00001797          	auipc	a5,0x1
ffffffffc0201332:	1d278793          	addi	a5,a5,466 # ffffffffc0202500 <error_string+0x38>
ffffffffc0201336:	9a3e                	add	s4,s4,a5
}
ffffffffc0201338:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020133a:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020133e:	70a2                	ld	ra,40(sp)
ffffffffc0201340:	69a2                	ld	s3,8(sp)
ffffffffc0201342:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201344:	85ca                	mv	a1,s2
ffffffffc0201346:	8326                	mv	t1,s1
}
ffffffffc0201348:	6942                	ld	s2,16(sp)
ffffffffc020134a:	64e2                	ld	s1,24(sp)
ffffffffc020134c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020134e:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201350:	03065633          	divu	a2,a2,a6
ffffffffc0201354:	8722                	mv	a4,s0
ffffffffc0201356:	f9bff0ef          	jal	ra,ffffffffc02012f0 <printnum>
ffffffffc020135a:	b7f9                	j	ffffffffc0201328 <printnum+0x38>

ffffffffc020135c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020135c:	7119                	addi	sp,sp,-128
ffffffffc020135e:	f4a6                	sd	s1,104(sp)
ffffffffc0201360:	f0ca                	sd	s2,96(sp)
ffffffffc0201362:	e8d2                	sd	s4,80(sp)
ffffffffc0201364:	e4d6                	sd	s5,72(sp)
ffffffffc0201366:	e0da                	sd	s6,64(sp)
ffffffffc0201368:	fc5e                	sd	s7,56(sp)
ffffffffc020136a:	f862                	sd	s8,48(sp)
ffffffffc020136c:	f06a                	sd	s10,32(sp)
ffffffffc020136e:	fc86                	sd	ra,120(sp)
ffffffffc0201370:	f8a2                	sd	s0,112(sp)
ffffffffc0201372:	ecce                	sd	s3,88(sp)
ffffffffc0201374:	f466                	sd	s9,40(sp)
ffffffffc0201376:	ec6e                	sd	s11,24(sp)
ffffffffc0201378:	892a                	mv	s2,a0
ffffffffc020137a:	84ae                	mv	s1,a1
ffffffffc020137c:	8d32                	mv	s10,a2
ffffffffc020137e:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201380:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201382:	00001a17          	auipc	s4,0x1
ffffffffc0201386:	feea0a13          	addi	s4,s4,-18 # ffffffffc0202370 <buddy_pmm_manager+0x178>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020138a:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020138e:	00001c17          	auipc	s8,0x1
ffffffffc0201392:	13ac0c13          	addi	s8,s8,314 # ffffffffc02024c8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201396:	000d4503          	lbu	a0,0(s10)
ffffffffc020139a:	02500793          	li	a5,37
ffffffffc020139e:	001d0413          	addi	s0,s10,1
ffffffffc02013a2:	00f50e63          	beq	a0,a5,ffffffffc02013be <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc02013a6:	c521                	beqz	a0,ffffffffc02013ee <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02013a8:	02500993          	li	s3,37
ffffffffc02013ac:	a011                	j	ffffffffc02013b0 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc02013ae:	c121                	beqz	a0,ffffffffc02013ee <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc02013b0:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02013b2:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02013b4:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02013b6:	fff44503          	lbu	a0,-1(s0)
ffffffffc02013ba:	ff351ae3          	bne	a0,s3,ffffffffc02013ae <vprintfmt+0x52>
ffffffffc02013be:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02013c2:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02013c6:	4981                	li	s3,0
ffffffffc02013c8:	4801                	li	a6,0
        width = precision = -1;
ffffffffc02013ca:	5cfd                	li	s9,-1
ffffffffc02013cc:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013ce:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc02013d2:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013d4:	fdd6069b          	addiw	a3,a2,-35
ffffffffc02013d8:	0ff6f693          	andi	a3,a3,255
ffffffffc02013dc:	00140d13          	addi	s10,s0,1
ffffffffc02013e0:	20d5e563          	bltu	a1,a3,ffffffffc02015ea <vprintfmt+0x28e>
ffffffffc02013e4:	068a                	slli	a3,a3,0x2
ffffffffc02013e6:	96d2                	add	a3,a3,s4
ffffffffc02013e8:	4294                	lw	a3,0(a3)
ffffffffc02013ea:	96d2                	add	a3,a3,s4
ffffffffc02013ec:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02013ee:	70e6                	ld	ra,120(sp)
ffffffffc02013f0:	7446                	ld	s0,112(sp)
ffffffffc02013f2:	74a6                	ld	s1,104(sp)
ffffffffc02013f4:	7906                	ld	s2,96(sp)
ffffffffc02013f6:	69e6                	ld	s3,88(sp)
ffffffffc02013f8:	6a46                	ld	s4,80(sp)
ffffffffc02013fa:	6aa6                	ld	s5,72(sp)
ffffffffc02013fc:	6b06                	ld	s6,64(sp)
ffffffffc02013fe:	7be2                	ld	s7,56(sp)
ffffffffc0201400:	7c42                	ld	s8,48(sp)
ffffffffc0201402:	7ca2                	ld	s9,40(sp)
ffffffffc0201404:	7d02                	ld	s10,32(sp)
ffffffffc0201406:	6de2                	ld	s11,24(sp)
ffffffffc0201408:	6109                	addi	sp,sp,128
ffffffffc020140a:	8082                	ret
    if (lflag >= 2) {
ffffffffc020140c:	4705                	li	a4,1
ffffffffc020140e:	008a8593          	addi	a1,s5,8
ffffffffc0201412:	01074463          	blt	a4,a6,ffffffffc020141a <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc0201416:	26080363          	beqz	a6,ffffffffc020167c <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc020141a:	000ab603          	ld	a2,0(s5)
ffffffffc020141e:	46c1                	li	a3,16
ffffffffc0201420:	8aae                	mv	s5,a1
ffffffffc0201422:	a06d                	j	ffffffffc02014cc <vprintfmt+0x170>
            goto reswitch;
ffffffffc0201424:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201428:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020142a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020142c:	b765                	j	ffffffffc02013d4 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc020142e:	000aa503          	lw	a0,0(s5)
ffffffffc0201432:	85a6                	mv	a1,s1
ffffffffc0201434:	0aa1                	addi	s5,s5,8
ffffffffc0201436:	9902                	jalr	s2
            break;
ffffffffc0201438:	bfb9                	j	ffffffffc0201396 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020143a:	4705                	li	a4,1
ffffffffc020143c:	008a8993          	addi	s3,s5,8
ffffffffc0201440:	01074463          	blt	a4,a6,ffffffffc0201448 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0201444:	22080463          	beqz	a6,ffffffffc020166c <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc0201448:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc020144c:	24044463          	bltz	s0,ffffffffc0201694 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0201450:	8622                	mv	a2,s0
ffffffffc0201452:	8ace                	mv	s5,s3
ffffffffc0201454:	46a9                	li	a3,10
ffffffffc0201456:	a89d                	j	ffffffffc02014cc <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc0201458:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020145c:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc020145e:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0201460:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201464:	8fb5                	xor	a5,a5,a3
ffffffffc0201466:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020146a:	1ad74363          	blt	a4,a3,ffffffffc0201610 <vprintfmt+0x2b4>
ffffffffc020146e:	00369793          	slli	a5,a3,0x3
ffffffffc0201472:	97e2                	add	a5,a5,s8
ffffffffc0201474:	639c                	ld	a5,0(a5)
ffffffffc0201476:	18078d63          	beqz	a5,ffffffffc0201610 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc020147a:	86be                	mv	a3,a5
ffffffffc020147c:	00001617          	auipc	a2,0x1
ffffffffc0201480:	13460613          	addi	a2,a2,308 # ffffffffc02025b0 <error_string+0xe8>
ffffffffc0201484:	85a6                	mv	a1,s1
ffffffffc0201486:	854a                	mv	a0,s2
ffffffffc0201488:	240000ef          	jal	ra,ffffffffc02016c8 <printfmt>
ffffffffc020148c:	b729                	j	ffffffffc0201396 <vprintfmt+0x3a>
            lflag ++;
ffffffffc020148e:	00144603          	lbu	a2,1(s0)
ffffffffc0201492:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201494:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201496:	bf3d                	j	ffffffffc02013d4 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0201498:	4705                	li	a4,1
ffffffffc020149a:	008a8593          	addi	a1,s5,8
ffffffffc020149e:	01074463          	blt	a4,a6,ffffffffc02014a6 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02014a2:	1e080263          	beqz	a6,ffffffffc0201686 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc02014a6:	000ab603          	ld	a2,0(s5)
ffffffffc02014aa:	46a1                	li	a3,8
ffffffffc02014ac:	8aae                	mv	s5,a1
ffffffffc02014ae:	a839                	j	ffffffffc02014cc <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc02014b0:	03000513          	li	a0,48
ffffffffc02014b4:	85a6                	mv	a1,s1
ffffffffc02014b6:	e03e                	sd	a5,0(sp)
ffffffffc02014b8:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02014ba:	85a6                	mv	a1,s1
ffffffffc02014bc:	07800513          	li	a0,120
ffffffffc02014c0:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02014c2:	0aa1                	addi	s5,s5,8
ffffffffc02014c4:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc02014c8:	6782                	ld	a5,0(sp)
ffffffffc02014ca:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02014cc:	876e                	mv	a4,s11
ffffffffc02014ce:	85a6                	mv	a1,s1
ffffffffc02014d0:	854a                	mv	a0,s2
ffffffffc02014d2:	e1fff0ef          	jal	ra,ffffffffc02012f0 <printnum>
            break;
ffffffffc02014d6:	b5c1                	j	ffffffffc0201396 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02014d8:	000ab603          	ld	a2,0(s5)
ffffffffc02014dc:	0aa1                	addi	s5,s5,8
ffffffffc02014de:	1c060663          	beqz	a2,ffffffffc02016aa <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc02014e2:	00160413          	addi	s0,a2,1
ffffffffc02014e6:	17b05c63          	blez	s11,ffffffffc020165e <vprintfmt+0x302>
ffffffffc02014ea:	02d00593          	li	a1,45
ffffffffc02014ee:	14b79263          	bne	a5,a1,ffffffffc0201632 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014f2:	00064783          	lbu	a5,0(a2)
ffffffffc02014f6:	0007851b          	sext.w	a0,a5
ffffffffc02014fa:	c905                	beqz	a0,ffffffffc020152a <vprintfmt+0x1ce>
ffffffffc02014fc:	000cc563          	bltz	s9,ffffffffc0201506 <vprintfmt+0x1aa>
ffffffffc0201500:	3cfd                	addiw	s9,s9,-1
ffffffffc0201502:	036c8263          	beq	s9,s6,ffffffffc0201526 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0201506:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201508:	18098463          	beqz	s3,ffffffffc0201690 <vprintfmt+0x334>
ffffffffc020150c:	3781                	addiw	a5,a5,-32
ffffffffc020150e:	18fbf163          	bleu	a5,s7,ffffffffc0201690 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0201512:	03f00513          	li	a0,63
ffffffffc0201516:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201518:	0405                	addi	s0,s0,1
ffffffffc020151a:	fff44783          	lbu	a5,-1(s0)
ffffffffc020151e:	3dfd                	addiw	s11,s11,-1
ffffffffc0201520:	0007851b          	sext.w	a0,a5
ffffffffc0201524:	fd61                	bnez	a0,ffffffffc02014fc <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc0201526:	e7b058e3          	blez	s11,ffffffffc0201396 <vprintfmt+0x3a>
ffffffffc020152a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020152c:	85a6                	mv	a1,s1
ffffffffc020152e:	02000513          	li	a0,32
ffffffffc0201532:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201534:	e60d81e3          	beqz	s11,ffffffffc0201396 <vprintfmt+0x3a>
ffffffffc0201538:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020153a:	85a6                	mv	a1,s1
ffffffffc020153c:	02000513          	li	a0,32
ffffffffc0201540:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201542:	fe0d94e3          	bnez	s11,ffffffffc020152a <vprintfmt+0x1ce>
ffffffffc0201546:	bd81                	j	ffffffffc0201396 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201548:	4705                	li	a4,1
ffffffffc020154a:	008a8593          	addi	a1,s5,8
ffffffffc020154e:	01074463          	blt	a4,a6,ffffffffc0201556 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0201552:	12080063          	beqz	a6,ffffffffc0201672 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc0201556:	000ab603          	ld	a2,0(s5)
ffffffffc020155a:	46a9                	li	a3,10
ffffffffc020155c:	8aae                	mv	s5,a1
ffffffffc020155e:	b7bd                	j	ffffffffc02014cc <vprintfmt+0x170>
ffffffffc0201560:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc0201564:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201568:	846a                	mv	s0,s10
ffffffffc020156a:	b5ad                	j	ffffffffc02013d4 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc020156c:	85a6                	mv	a1,s1
ffffffffc020156e:	02500513          	li	a0,37
ffffffffc0201572:	9902                	jalr	s2
            break;
ffffffffc0201574:	b50d                	j	ffffffffc0201396 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc0201576:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc020157a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020157e:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201580:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0201582:	e40dd9e3          	bgez	s11,ffffffffc02013d4 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0201586:	8de6                	mv	s11,s9
ffffffffc0201588:	5cfd                	li	s9,-1
ffffffffc020158a:	b5a9                	j	ffffffffc02013d4 <vprintfmt+0x78>
            goto reswitch;
ffffffffc020158c:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc0201590:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201594:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201596:	bd3d                	j	ffffffffc02013d4 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc0201598:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc020159c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015a0:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02015a2:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02015a6:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02015aa:	fcd56ce3          	bltu	a0,a3,ffffffffc0201582 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc02015ae:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02015b0:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc02015b4:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02015b8:	0196873b          	addw	a4,a3,s9
ffffffffc02015bc:	0017171b          	slliw	a4,a4,0x1
ffffffffc02015c0:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc02015c4:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc02015c8:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02015cc:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02015d0:	fcd57fe3          	bleu	a3,a0,ffffffffc02015ae <vprintfmt+0x252>
ffffffffc02015d4:	b77d                	j	ffffffffc0201582 <vprintfmt+0x226>
            if (width < 0)
ffffffffc02015d6:	fffdc693          	not	a3,s11
ffffffffc02015da:	96fd                	srai	a3,a3,0x3f
ffffffffc02015dc:	00ddfdb3          	and	s11,s11,a3
ffffffffc02015e0:	00144603          	lbu	a2,1(s0)
ffffffffc02015e4:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015e6:	846a                	mv	s0,s10
ffffffffc02015e8:	b3f5                	j	ffffffffc02013d4 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc02015ea:	85a6                	mv	a1,s1
ffffffffc02015ec:	02500513          	li	a0,37
ffffffffc02015f0:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02015f2:	fff44703          	lbu	a4,-1(s0)
ffffffffc02015f6:	02500793          	li	a5,37
ffffffffc02015fa:	8d22                	mv	s10,s0
ffffffffc02015fc:	d8f70de3          	beq	a4,a5,ffffffffc0201396 <vprintfmt+0x3a>
ffffffffc0201600:	02500713          	li	a4,37
ffffffffc0201604:	1d7d                	addi	s10,s10,-1
ffffffffc0201606:	fffd4783          	lbu	a5,-1(s10)
ffffffffc020160a:	fee79de3          	bne	a5,a4,ffffffffc0201604 <vprintfmt+0x2a8>
ffffffffc020160e:	b361                	j	ffffffffc0201396 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201610:	00001617          	auipc	a2,0x1
ffffffffc0201614:	f9060613          	addi	a2,a2,-112 # ffffffffc02025a0 <error_string+0xd8>
ffffffffc0201618:	85a6                	mv	a1,s1
ffffffffc020161a:	854a                	mv	a0,s2
ffffffffc020161c:	0ac000ef          	jal	ra,ffffffffc02016c8 <printfmt>
ffffffffc0201620:	bb9d                	j	ffffffffc0201396 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201622:	00001617          	auipc	a2,0x1
ffffffffc0201626:	f7660613          	addi	a2,a2,-138 # ffffffffc0202598 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc020162a:	00001417          	auipc	s0,0x1
ffffffffc020162e:	f6f40413          	addi	s0,s0,-145 # ffffffffc0202599 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201632:	8532                	mv	a0,a2
ffffffffc0201634:	85e6                	mv	a1,s9
ffffffffc0201636:	e032                	sd	a2,0(sp)
ffffffffc0201638:	e43e                	sd	a5,8(sp)
ffffffffc020163a:	1c4000ef          	jal	ra,ffffffffc02017fe <strnlen>
ffffffffc020163e:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201642:	6602                	ld	a2,0(sp)
ffffffffc0201644:	01b05d63          	blez	s11,ffffffffc020165e <vprintfmt+0x302>
ffffffffc0201648:	67a2                	ld	a5,8(sp)
ffffffffc020164a:	2781                	sext.w	a5,a5
ffffffffc020164c:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc020164e:	6522                	ld	a0,8(sp)
ffffffffc0201650:	85a6                	mv	a1,s1
ffffffffc0201652:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201654:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201656:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201658:	6602                	ld	a2,0(sp)
ffffffffc020165a:	fe0d9ae3          	bnez	s11,ffffffffc020164e <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020165e:	00064783          	lbu	a5,0(a2)
ffffffffc0201662:	0007851b          	sext.w	a0,a5
ffffffffc0201666:	e8051be3          	bnez	a0,ffffffffc02014fc <vprintfmt+0x1a0>
ffffffffc020166a:	b335                	j	ffffffffc0201396 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc020166c:	000aa403          	lw	s0,0(s5)
ffffffffc0201670:	bbf1                	j	ffffffffc020144c <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc0201672:	000ae603          	lwu	a2,0(s5)
ffffffffc0201676:	46a9                	li	a3,10
ffffffffc0201678:	8aae                	mv	s5,a1
ffffffffc020167a:	bd89                	j	ffffffffc02014cc <vprintfmt+0x170>
ffffffffc020167c:	000ae603          	lwu	a2,0(s5)
ffffffffc0201680:	46c1                	li	a3,16
ffffffffc0201682:	8aae                	mv	s5,a1
ffffffffc0201684:	b5a1                	j	ffffffffc02014cc <vprintfmt+0x170>
ffffffffc0201686:	000ae603          	lwu	a2,0(s5)
ffffffffc020168a:	46a1                	li	a3,8
ffffffffc020168c:	8aae                	mv	s5,a1
ffffffffc020168e:	bd3d                	j	ffffffffc02014cc <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc0201690:	9902                	jalr	s2
ffffffffc0201692:	b559                	j	ffffffffc0201518 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc0201694:	85a6                	mv	a1,s1
ffffffffc0201696:	02d00513          	li	a0,45
ffffffffc020169a:	e03e                	sd	a5,0(sp)
ffffffffc020169c:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020169e:	8ace                	mv	s5,s3
ffffffffc02016a0:	40800633          	neg	a2,s0
ffffffffc02016a4:	46a9                	li	a3,10
ffffffffc02016a6:	6782                	ld	a5,0(sp)
ffffffffc02016a8:	b515                	j	ffffffffc02014cc <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc02016aa:	01b05663          	blez	s11,ffffffffc02016b6 <vprintfmt+0x35a>
ffffffffc02016ae:	02d00693          	li	a3,45
ffffffffc02016b2:	f6d798e3          	bne	a5,a3,ffffffffc0201622 <vprintfmt+0x2c6>
ffffffffc02016b6:	00001417          	auipc	s0,0x1
ffffffffc02016ba:	ee340413          	addi	s0,s0,-285 # ffffffffc0202599 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016be:	02800513          	li	a0,40
ffffffffc02016c2:	02800793          	li	a5,40
ffffffffc02016c6:	bd1d                	j	ffffffffc02014fc <vprintfmt+0x1a0>

ffffffffc02016c8 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02016c8:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02016ca:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02016ce:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02016d0:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02016d2:	ec06                	sd	ra,24(sp)
ffffffffc02016d4:	f83a                	sd	a4,48(sp)
ffffffffc02016d6:	fc3e                	sd	a5,56(sp)
ffffffffc02016d8:	e0c2                	sd	a6,64(sp)
ffffffffc02016da:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02016dc:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02016de:	c7fff0ef          	jal	ra,ffffffffc020135c <vprintfmt>
}
ffffffffc02016e2:	60e2                	ld	ra,24(sp)
ffffffffc02016e4:	6161                	addi	sp,sp,80
ffffffffc02016e6:	8082                	ret

ffffffffc02016e8 <readline>:
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt)
{
ffffffffc02016e8:	715d                	addi	sp,sp,-80
ffffffffc02016ea:	e486                	sd	ra,72(sp)
ffffffffc02016ec:	e0a2                	sd	s0,64(sp)
ffffffffc02016ee:	fc26                	sd	s1,56(sp)
ffffffffc02016f0:	f84a                	sd	s2,48(sp)
ffffffffc02016f2:	f44e                	sd	s3,40(sp)
ffffffffc02016f4:	f052                	sd	s4,32(sp)
ffffffffc02016f6:	ec56                	sd	s5,24(sp)
ffffffffc02016f8:	e85a                	sd	s6,16(sp)
ffffffffc02016fa:	e45e                	sd	s7,8(sp)
    if (prompt != NULL)
ffffffffc02016fc:	c901                	beqz	a0,ffffffffc020170c <readline+0x24>
    {
        cprintf("%s", prompt);
ffffffffc02016fe:	85aa                	mv	a1,a0
ffffffffc0201700:	00001517          	auipc	a0,0x1
ffffffffc0201704:	eb050513          	addi	a0,a0,-336 # ffffffffc02025b0 <error_string+0xe8>
ffffffffc0201708:	9affe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1)
        {
            cputchar(c);
            buf[i++] = c;
ffffffffc020170c:	4481                	li	s1,0
ffffffffc020170e:	00005a97          	auipc	s5,0x5
ffffffffc0201712:	902a8a93          	addi	s5,s5,-1790 # ffffffffc0206010 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1)
ffffffffc0201716:	497d                	li	s2,31
        }
        else if (c == '\b' && i > 0)
ffffffffc0201718:	49a1                	li	s3,8
        {
            cputchar(c);
            i--;
        }
        else if (c == '\n' || c == '\r')
ffffffffc020171a:	4b29                	li	s6,10
ffffffffc020171c:	4bb5                	li	s7,13
        else if (c >= ' ' && i < BUFSIZE - 1)
ffffffffc020171e:	3fe00a13          	li	s4,1022
        while ((c = getchar()) < 0)
ffffffffc0201722:	a0dfe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201726:	842a                	mv	s0,a0
ffffffffc0201728:	fe054de3          	bltz	a0,ffffffffc0201722 <readline+0x3a>
        else if (c >= ' ' && i < BUFSIZE - 1)
ffffffffc020172c:	00a95d63          	ble	a0,s2,ffffffffc0201746 <readline+0x5e>
ffffffffc0201730:	fe9a49e3          	blt	s4,s1,ffffffffc0201722 <readline+0x3a>
            cputchar(c);
ffffffffc0201734:	8522                	mv	a0,s0
ffffffffc0201736:	9b5fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i++] = c;
ffffffffc020173a:	009a87b3          	add	a5,s5,s1
ffffffffc020173e:	00878023          	sb	s0,0(a5)
ffffffffc0201742:	2485                	addiw	s1,s1,1
ffffffffc0201744:	bff9                	j	ffffffffc0201722 <readline+0x3a>
        else if (c == '\b' && i > 0)
ffffffffc0201746:	03341363          	bne	s0,s3,ffffffffc020176c <readline+0x84>
ffffffffc020174a:	e8b1                	bnez	s1,ffffffffc020179e <readline+0xb6>
        while ((c = getchar()) < 0)
ffffffffc020174c:	9e3fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201750:	842a                	mv	s0,a0
ffffffffc0201752:	fc0548e3          	bltz	a0,ffffffffc0201722 <readline+0x3a>
        else if (c >= ' ' && i < BUFSIZE - 1)
ffffffffc0201756:	fea958e3          	ble	a0,s2,ffffffffc0201746 <readline+0x5e>
            cputchar(c);
ffffffffc020175a:	8522                	mv	a0,s0
ffffffffc020175c:	98ffe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i++] = c;
ffffffffc0201760:	009a87b3          	add	a5,s5,s1
ffffffffc0201764:	00878023          	sb	s0,0(a5)
ffffffffc0201768:	2485                	addiw	s1,s1,1
ffffffffc020176a:	bf65                	j	ffffffffc0201722 <readline+0x3a>
        else if (c == '\n' || c == '\r')
ffffffffc020176c:	01640463          	beq	s0,s6,ffffffffc0201774 <readline+0x8c>
ffffffffc0201770:	fb7419e3          	bne	s0,s7,ffffffffc0201722 <readline+0x3a>
        {
            cputchar(c);
ffffffffc0201774:	8522                	mv	a0,s0
            buf[i] = '\0';
ffffffffc0201776:	94d6                	add	s1,s1,s5
            cputchar(c);
ffffffffc0201778:	973fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i] = '\0';
ffffffffc020177c:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201780:	60a6                	ld	ra,72(sp)
ffffffffc0201782:	6406                	ld	s0,64(sp)
ffffffffc0201784:	74e2                	ld	s1,56(sp)
ffffffffc0201786:	7942                	ld	s2,48(sp)
ffffffffc0201788:	79a2                	ld	s3,40(sp)
ffffffffc020178a:	7a02                	ld	s4,32(sp)
ffffffffc020178c:	6ae2                	ld	s5,24(sp)
ffffffffc020178e:	6b42                	ld	s6,16(sp)
ffffffffc0201790:	6ba2                	ld	s7,8(sp)
ffffffffc0201792:	00005517          	auipc	a0,0x5
ffffffffc0201796:	87e50513          	addi	a0,a0,-1922 # ffffffffc0206010 <edata>
ffffffffc020179a:	6161                	addi	sp,sp,80
ffffffffc020179c:	8082                	ret
            cputchar(c);
ffffffffc020179e:	4521                	li	a0,8
ffffffffc02017a0:	94bfe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            i--;
ffffffffc02017a4:	34fd                	addiw	s1,s1,-1
ffffffffc02017a6:	bfb5                	j	ffffffffc0201722 <readline+0x3a>

ffffffffc02017a8 <sbi_console_putchar>:
    );
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc02017a8:	00005797          	auipc	a5,0x5
ffffffffc02017ac:	86078793          	addi	a5,a5,-1952 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile (
ffffffffc02017b0:	6398                	ld	a4,0(a5)
ffffffffc02017b2:	4781                	li	a5,0
ffffffffc02017b4:	88ba                	mv	a7,a4
ffffffffc02017b6:	852a                	mv	a0,a0
ffffffffc02017b8:	85be                	mv	a1,a5
ffffffffc02017ba:	863e                	mv	a2,a5
ffffffffc02017bc:	00000073          	ecall
ffffffffc02017c0:	87aa                	mv	a5,a0
}
ffffffffc02017c2:	8082                	ret

ffffffffc02017c4 <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc02017c4:	00005797          	auipc	a5,0x5
ffffffffc02017c8:	c6478793          	addi	a5,a5,-924 # ffffffffc0206428 <SBI_SET_TIMER>
    __asm__ volatile (
ffffffffc02017cc:	6398                	ld	a4,0(a5)
ffffffffc02017ce:	4781                	li	a5,0
ffffffffc02017d0:	88ba                	mv	a7,a4
ffffffffc02017d2:	852a                	mv	a0,a0
ffffffffc02017d4:	85be                	mv	a1,a5
ffffffffc02017d6:	863e                	mv	a2,a5
ffffffffc02017d8:	00000073          	ecall
ffffffffc02017dc:	87aa                	mv	a5,a0
}
ffffffffc02017de:	8082                	ret

ffffffffc02017e0 <sbi_console_getchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc02017e0:	00005797          	auipc	a5,0x5
ffffffffc02017e4:	82078793          	addi	a5,a5,-2016 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile (
ffffffffc02017e8:	639c                	ld	a5,0(a5)
ffffffffc02017ea:	4501                	li	a0,0
ffffffffc02017ec:	88be                	mv	a7,a5
ffffffffc02017ee:	852a                	mv	a0,a0
ffffffffc02017f0:	85aa                	mv	a1,a0
ffffffffc02017f2:	862a                	mv	a2,a0
ffffffffc02017f4:	00000073          	ecall
ffffffffc02017f8:	852a                	mv	a0,a0
ffffffffc02017fa:	2501                	sext.w	a0,a0
ffffffffc02017fc:	8082                	ret

ffffffffc02017fe <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc02017fe:	c185                	beqz	a1,ffffffffc020181e <strnlen+0x20>
ffffffffc0201800:	00054783          	lbu	a5,0(a0)
ffffffffc0201804:	cf89                	beqz	a5,ffffffffc020181e <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0201806:	4781                	li	a5,0
ffffffffc0201808:	a021                	j	ffffffffc0201810 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc020180a:	00074703          	lbu	a4,0(a4)
ffffffffc020180e:	c711                	beqz	a4,ffffffffc020181a <strnlen+0x1c>
        cnt ++;
ffffffffc0201810:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201812:	00f50733          	add	a4,a0,a5
ffffffffc0201816:	fef59ae3          	bne	a1,a5,ffffffffc020180a <strnlen+0xc>
    }
    return cnt;
}
ffffffffc020181a:	853e                	mv	a0,a5
ffffffffc020181c:	8082                	ret
    size_t cnt = 0;
ffffffffc020181e:	4781                	li	a5,0
}
ffffffffc0201820:	853e                	mv	a0,a5
ffffffffc0201822:	8082                	ret

ffffffffc0201824 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201824:	00054783          	lbu	a5,0(a0)
ffffffffc0201828:	0005c703          	lbu	a4,0(a1)
ffffffffc020182c:	cb91                	beqz	a5,ffffffffc0201840 <strcmp+0x1c>
ffffffffc020182e:	00e79c63          	bne	a5,a4,ffffffffc0201846 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0201832:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201834:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0201838:	0585                	addi	a1,a1,1
ffffffffc020183a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020183e:	fbe5                	bnez	a5,ffffffffc020182e <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201840:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201842:	9d19                	subw	a0,a0,a4
ffffffffc0201844:	8082                	ret
ffffffffc0201846:	0007851b          	sext.w	a0,a5
ffffffffc020184a:	9d19                	subw	a0,a0,a4
ffffffffc020184c:	8082                	ret

ffffffffc020184e <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020184e:	00054783          	lbu	a5,0(a0)
ffffffffc0201852:	cb91                	beqz	a5,ffffffffc0201866 <strchr+0x18>
        if (*s == c) {
ffffffffc0201854:	00b79563          	bne	a5,a1,ffffffffc020185e <strchr+0x10>
ffffffffc0201858:	a809                	j	ffffffffc020186a <strchr+0x1c>
ffffffffc020185a:	00b78763          	beq	a5,a1,ffffffffc0201868 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc020185e:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201860:	00054783          	lbu	a5,0(a0)
ffffffffc0201864:	fbfd                	bnez	a5,ffffffffc020185a <strchr+0xc>
    }
    return NULL;
ffffffffc0201866:	4501                	li	a0,0
}
ffffffffc0201868:	8082                	ret
ffffffffc020186a:	8082                	ret

ffffffffc020186c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020186c:	ca01                	beqz	a2,ffffffffc020187c <memset+0x10>
ffffffffc020186e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201870:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201872:	0785                	addi	a5,a5,1
ffffffffc0201874:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201878:	fec79de3          	bne	a5,a2,ffffffffc0201872 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020187c:	8082                	ret
