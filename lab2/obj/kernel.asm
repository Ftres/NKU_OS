
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
ffffffffc020003e:	00006617          	auipc	a2,0x6
ffffffffc0200042:	43260613          	addi	a2,a2,1074 # ffffffffc0206470 <end>
int kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	273010ef          	jal	ra,ffffffffc0201ac0 <memset>
    cons_init();  // init the console
ffffffffc0200052:	3fe000ef          	jal	ra,ffffffffc0200450 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200056:	00002517          	auipc	a0,0x2
ffffffffc020005a:	a8250513          	addi	a0,a0,-1406 # ffffffffc0201ad8 <etext+0x6>
ffffffffc020005e:	090000ef          	jal	ra,ffffffffc02000ee <cputs>

    print_kerninfo();
ffffffffc0200062:	0dc000ef          	jal	ra,ffffffffc020013e <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200066:	404000ef          	jal	ra,ffffffffc020046a <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020006a:	32c010ef          	jal	ra,ffffffffc0201396 <pmm_init>

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
ffffffffc02000aa:	506010ef          	jal	ra,ffffffffc02015b0 <vprintfmt>
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
ffffffffc02000de:	4d2010ef          	jal	ra,ffffffffc02015b0 <vprintfmt>
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
ffffffffc0200140:	00002517          	auipc	a0,0x2
ffffffffc0200144:	9e850513          	addi	a0,a0,-1560 # ffffffffc0201b28 <etext+0x56>
void print_kerninfo(void) {
ffffffffc0200148:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020014a:	f6dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014e:	00000597          	auipc	a1,0x0
ffffffffc0200152:	ee858593          	addi	a1,a1,-280 # ffffffffc0200036 <kern_init>
ffffffffc0200156:	00002517          	auipc	a0,0x2
ffffffffc020015a:	9f250513          	addi	a0,a0,-1550 # ffffffffc0201b48 <etext+0x76>
ffffffffc020015e:	f59ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200162:	00002597          	auipc	a1,0x2
ffffffffc0200166:	97058593          	addi	a1,a1,-1680 # ffffffffc0201ad2 <etext>
ffffffffc020016a:	00002517          	auipc	a0,0x2
ffffffffc020016e:	9fe50513          	addi	a0,a0,-1538 # ffffffffc0201b68 <etext+0x96>
ffffffffc0200172:	f45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200176:	00006597          	auipc	a1,0x6
ffffffffc020017a:	e9a58593          	addi	a1,a1,-358 # ffffffffc0206010 <edata>
ffffffffc020017e:	00002517          	auipc	a0,0x2
ffffffffc0200182:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0201b88 <etext+0xb6>
ffffffffc0200186:	f31ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020018a:	00006597          	auipc	a1,0x6
ffffffffc020018e:	2e658593          	addi	a1,a1,742 # ffffffffc0206470 <end>
ffffffffc0200192:	00002517          	auipc	a0,0x2
ffffffffc0200196:	a1650513          	addi	a0,a0,-1514 # ffffffffc0201ba8 <etext+0xd6>
ffffffffc020019a:	f1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019e:	00006597          	auipc	a1,0x6
ffffffffc02001a2:	6d158593          	addi	a1,a1,1745 # ffffffffc020686f <end+0x3ff>
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
ffffffffc02001c0:	00002517          	auipc	a0,0x2
ffffffffc02001c4:	a0850513          	addi	a0,a0,-1528 # ffffffffc0201bc8 <etext+0xf6>
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
ffffffffc02001d0:	00002617          	auipc	a2,0x2
ffffffffc02001d4:	92860613          	addi	a2,a2,-1752 # ffffffffc0201af8 <etext+0x26>
ffffffffc02001d8:	04e00593          	li	a1,78
ffffffffc02001dc:	00002517          	auipc	a0,0x2
ffffffffc02001e0:	93450513          	addi	a0,a0,-1740 # ffffffffc0201b10 <etext+0x3e>
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
ffffffffc02001f0:	aec60613          	addi	a2,a2,-1300 # ffffffffc0201cd8 <commands+0xe0>
ffffffffc02001f4:	00002597          	auipc	a1,0x2
ffffffffc02001f8:	b0458593          	addi	a1,a1,-1276 # ffffffffc0201cf8 <commands+0x100>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	b0450513          	addi	a0,a0,-1276 # ffffffffc0201d00 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200206:	eb1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020020a:	00002617          	auipc	a2,0x2
ffffffffc020020e:	b0660613          	addi	a2,a2,-1274 # ffffffffc0201d10 <commands+0x118>
ffffffffc0200212:	00002597          	auipc	a1,0x2
ffffffffc0200216:	b2658593          	addi	a1,a1,-1242 # ffffffffc0201d38 <commands+0x140>
ffffffffc020021a:	00002517          	auipc	a0,0x2
ffffffffc020021e:	ae650513          	addi	a0,a0,-1306 # ffffffffc0201d00 <commands+0x108>
ffffffffc0200222:	e95ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200226:	00002617          	auipc	a2,0x2
ffffffffc020022a:	b2260613          	addi	a2,a2,-1246 # ffffffffc0201d48 <commands+0x150>
ffffffffc020022e:	00002597          	auipc	a1,0x2
ffffffffc0200232:	b3a58593          	addi	a1,a1,-1222 # ffffffffc0201d68 <commands+0x170>
ffffffffc0200236:	00002517          	auipc	a0,0x2
ffffffffc020023a:	aca50513          	addi	a0,a0,-1334 # ffffffffc0201d00 <commands+0x108>
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
ffffffffc0200270:	00002517          	auipc	a0,0x2
ffffffffc0200274:	9d050513          	addi	a0,a0,-1584 # ffffffffc0201c40 <commands+0x48>
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
ffffffffc0200292:	00002517          	auipc	a0,0x2
ffffffffc0200296:	9d650513          	addi	a0,a0,-1578 # ffffffffc0201c68 <commands+0x70>
ffffffffc020029a:	e1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (tf != NULL) {
ffffffffc020029e:	000c0563          	beqz	s8,ffffffffc02002a8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a2:	8562                	mv	a0,s8
ffffffffc02002a4:	3a6000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc02002a8:	00002c97          	auipc	s9,0x2
ffffffffc02002ac:	950c8c93          	addi	s9,s9,-1712 # ffffffffc0201bf8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b0:	00002997          	auipc	s3,0x2
ffffffffc02002b4:	9e098993          	addi	s3,s3,-1568 # ffffffffc0201c90 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b8:	00002917          	auipc	s2,0x2
ffffffffc02002bc:	9e090913          	addi	s2,s2,-1568 # ffffffffc0201c98 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002c0:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c2:	00002b17          	auipc	s6,0x2
ffffffffc02002c6:	9deb0b13          	addi	s6,s6,-1570 # ffffffffc0201ca0 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002ca:	00002a97          	auipc	s5,0x2
ffffffffc02002ce:	a2ea8a93          	addi	s5,s5,-1490 # ffffffffc0201cf8 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d2:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d4:	854e                	mv	a0,s3
ffffffffc02002d6:	666010ef          	jal	ra,ffffffffc020193c <readline>
ffffffffc02002da:	842a                	mv	s0,a0
ffffffffc02002dc:	dd65                	beqz	a0,ffffffffc02002d4 <kmonitor+0x6a>
ffffffffc02002de:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e2:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e4:	c999                	beqz	a1,ffffffffc02002fa <kmonitor+0x90>
ffffffffc02002e6:	854a                	mv	a0,s2
ffffffffc02002e8:	7ba010ef          	jal	ra,ffffffffc0201aa2 <strchr>
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
ffffffffc02002fe:	00002d17          	auipc	s10,0x2
ffffffffc0200302:	8fad0d13          	addi	s10,s10,-1798 # ffffffffc0201bf8 <commands>
    if (argc == 0) {
ffffffffc0200306:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200308:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	0d61                	addi	s10,s10,24
ffffffffc020030c:	76c010ef          	jal	ra,ffffffffc0201a78 <strcmp>
ffffffffc0200310:	c919                	beqz	a0,ffffffffc0200326 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200312:	2405                	addiw	s0,s0,1
ffffffffc0200314:	09740463          	beq	s0,s7,ffffffffc020039c <kmonitor+0x132>
ffffffffc0200318:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031c:	6582                	ld	a1,0(sp)
ffffffffc020031e:	0d61                	addi	s10,s10,24
ffffffffc0200320:	758010ef          	jal	ra,ffffffffc0201a78 <strcmp>
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
ffffffffc0200386:	71c010ef          	jal	ra,ffffffffc0201aa2 <strchr>
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
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	92250513          	addi	a0,a0,-1758 # ffffffffc0201cc0 <commands+0xc8>
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
ffffffffc02003de:	00002517          	auipc	a0,0x2
ffffffffc02003e2:	99a50513          	addi	a0,a0,-1638 # ffffffffc0201d78 <commands+0x180>
    va_start(ap, fmt);
ffffffffc02003e6:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e8:	ccfff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003ec:	65a2                	ld	a1,8(sp)
ffffffffc02003ee:	8522                	mv	a0,s0
ffffffffc02003f0:	ca7ff0ef          	jal	ra,ffffffffc0200096 <vcprintf>
    cprintf("\n");
ffffffffc02003f4:	00001517          	auipc	a0,0x1
ffffffffc02003f8:	7fc50513          	addi	a0,a0,2044 # ffffffffc0201bf0 <etext+0x11e>
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
ffffffffc0200424:	5f4010ef          	jal	ra,ffffffffc0201a18 <sbi_set_timer>
}
ffffffffc0200428:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042a:	00006797          	auipc	a5,0x6
ffffffffc020042e:	0007b323          	sd	zero,6(a5) # ffffffffc0206430 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200432:	00002517          	auipc	a0,0x2
ffffffffc0200436:	96650513          	addi	a0,a0,-1690 # ffffffffc0201d98 <commands+0x1a0>
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
ffffffffc020044c:	5cc0106f          	j	ffffffffc0201a18 <sbi_set_timer>

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
ffffffffc0200456:	5a60106f          	j	ffffffffc02019fc <sbi_console_putchar>

ffffffffc020045a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045a:	5da0106f          	j	ffffffffc0201a34 <sbi_console_getchar>

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
ffffffffc0200484:	00002517          	auipc	a0,0x2
ffffffffc0200488:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0201eb0 <commands+0x2b8>
void print_regs(struct pushregs *gpr) {
ffffffffc020048c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020048e:	c29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200492:	640c                	ld	a1,8(s0)
ffffffffc0200494:	00002517          	auipc	a0,0x2
ffffffffc0200498:	a3450513          	addi	a0,a0,-1484 # ffffffffc0201ec8 <commands+0x2d0>
ffffffffc020049c:	c1bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a0:	680c                	ld	a1,16(s0)
ffffffffc02004a2:	00002517          	auipc	a0,0x2
ffffffffc02004a6:	a3e50513          	addi	a0,a0,-1474 # ffffffffc0201ee0 <commands+0x2e8>
ffffffffc02004aa:	c0dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004ae:	6c0c                	ld	a1,24(s0)
ffffffffc02004b0:	00002517          	auipc	a0,0x2
ffffffffc02004b4:	a4850513          	addi	a0,a0,-1464 # ffffffffc0201ef8 <commands+0x300>
ffffffffc02004b8:	bffff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004bc:	700c                	ld	a1,32(s0)
ffffffffc02004be:	00002517          	auipc	a0,0x2
ffffffffc02004c2:	a5250513          	addi	a0,a0,-1454 # ffffffffc0201f10 <commands+0x318>
ffffffffc02004c6:	bf1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004ca:	740c                	ld	a1,40(s0)
ffffffffc02004cc:	00002517          	auipc	a0,0x2
ffffffffc02004d0:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0201f28 <commands+0x330>
ffffffffc02004d4:	be3ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d8:	780c                	ld	a1,48(s0)
ffffffffc02004da:	00002517          	auipc	a0,0x2
ffffffffc02004de:	a6650513          	addi	a0,a0,-1434 # ffffffffc0201f40 <commands+0x348>
ffffffffc02004e2:	bd5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e6:	7c0c                	ld	a1,56(s0)
ffffffffc02004e8:	00002517          	auipc	a0,0x2
ffffffffc02004ec:	a7050513          	addi	a0,a0,-1424 # ffffffffc0201f58 <commands+0x360>
ffffffffc02004f0:	bc7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f4:	602c                	ld	a1,64(s0)
ffffffffc02004f6:	00002517          	auipc	a0,0x2
ffffffffc02004fa:	a7a50513          	addi	a0,a0,-1414 # ffffffffc0201f70 <commands+0x378>
ffffffffc02004fe:	bb9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200502:	642c                	ld	a1,72(s0)
ffffffffc0200504:	00002517          	auipc	a0,0x2
ffffffffc0200508:	a8450513          	addi	a0,a0,-1404 # ffffffffc0201f88 <commands+0x390>
ffffffffc020050c:	babff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200510:	682c                	ld	a1,80(s0)
ffffffffc0200512:	00002517          	auipc	a0,0x2
ffffffffc0200516:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0201fa0 <commands+0x3a8>
ffffffffc020051a:	b9dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020051e:	6c2c                	ld	a1,88(s0)
ffffffffc0200520:	00002517          	auipc	a0,0x2
ffffffffc0200524:	a9850513          	addi	a0,a0,-1384 # ffffffffc0201fb8 <commands+0x3c0>
ffffffffc0200528:	b8fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052c:	702c                	ld	a1,96(s0)
ffffffffc020052e:	00002517          	auipc	a0,0x2
ffffffffc0200532:	aa250513          	addi	a0,a0,-1374 # ffffffffc0201fd0 <commands+0x3d8>
ffffffffc0200536:	b81ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053a:	742c                	ld	a1,104(s0)
ffffffffc020053c:	00002517          	auipc	a0,0x2
ffffffffc0200540:	aac50513          	addi	a0,a0,-1364 # ffffffffc0201fe8 <commands+0x3f0>
ffffffffc0200544:	b73ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200548:	782c                	ld	a1,112(s0)
ffffffffc020054a:	00002517          	auipc	a0,0x2
ffffffffc020054e:	ab650513          	addi	a0,a0,-1354 # ffffffffc0202000 <commands+0x408>
ffffffffc0200552:	b65ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200556:	7c2c                	ld	a1,120(s0)
ffffffffc0200558:	00002517          	auipc	a0,0x2
ffffffffc020055c:	ac050513          	addi	a0,a0,-1344 # ffffffffc0202018 <commands+0x420>
ffffffffc0200560:	b57ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200564:	604c                	ld	a1,128(s0)
ffffffffc0200566:	00002517          	auipc	a0,0x2
ffffffffc020056a:	aca50513          	addi	a0,a0,-1334 # ffffffffc0202030 <commands+0x438>
ffffffffc020056e:	b49ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200572:	644c                	ld	a1,136(s0)
ffffffffc0200574:	00002517          	auipc	a0,0x2
ffffffffc0200578:	ad450513          	addi	a0,a0,-1324 # ffffffffc0202048 <commands+0x450>
ffffffffc020057c:	b3bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200580:	684c                	ld	a1,144(s0)
ffffffffc0200582:	00002517          	auipc	a0,0x2
ffffffffc0200586:	ade50513          	addi	a0,a0,-1314 # ffffffffc0202060 <commands+0x468>
ffffffffc020058a:	b2dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020058e:	6c4c                	ld	a1,152(s0)
ffffffffc0200590:	00002517          	auipc	a0,0x2
ffffffffc0200594:	ae850513          	addi	a0,a0,-1304 # ffffffffc0202078 <commands+0x480>
ffffffffc0200598:	b1fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059c:	704c                	ld	a1,160(s0)
ffffffffc020059e:	00002517          	auipc	a0,0x2
ffffffffc02005a2:	af250513          	addi	a0,a0,-1294 # ffffffffc0202090 <commands+0x498>
ffffffffc02005a6:	b11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005aa:	744c                	ld	a1,168(s0)
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	afc50513          	addi	a0,a0,-1284 # ffffffffc02020a8 <commands+0x4b0>
ffffffffc02005b4:	b03ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b8:	784c                	ld	a1,176(s0)
ffffffffc02005ba:	00002517          	auipc	a0,0x2
ffffffffc02005be:	b0650513          	addi	a0,a0,-1274 # ffffffffc02020c0 <commands+0x4c8>
ffffffffc02005c2:	af5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c6:	7c4c                	ld	a1,184(s0)
ffffffffc02005c8:	00002517          	auipc	a0,0x2
ffffffffc02005cc:	b1050513          	addi	a0,a0,-1264 # ffffffffc02020d8 <commands+0x4e0>
ffffffffc02005d0:	ae7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d4:	606c                	ld	a1,192(s0)
ffffffffc02005d6:	00002517          	auipc	a0,0x2
ffffffffc02005da:	b1a50513          	addi	a0,a0,-1254 # ffffffffc02020f0 <commands+0x4f8>
ffffffffc02005de:	ad9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e2:	646c                	ld	a1,200(s0)
ffffffffc02005e4:	00002517          	auipc	a0,0x2
ffffffffc02005e8:	b2450513          	addi	a0,a0,-1244 # ffffffffc0202108 <commands+0x510>
ffffffffc02005ec:	acbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f0:	686c                	ld	a1,208(s0)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	b2e50513          	addi	a0,a0,-1234 # ffffffffc0202120 <commands+0x528>
ffffffffc02005fa:	abdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200600:	00002517          	auipc	a0,0x2
ffffffffc0200604:	b3850513          	addi	a0,a0,-1224 # ffffffffc0202138 <commands+0x540>
ffffffffc0200608:	aafff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060c:	706c                	ld	a1,224(s0)
ffffffffc020060e:	00002517          	auipc	a0,0x2
ffffffffc0200612:	b4250513          	addi	a0,a0,-1214 # ffffffffc0202150 <commands+0x558>
ffffffffc0200616:	aa1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061a:	746c                	ld	a1,232(s0)
ffffffffc020061c:	00002517          	auipc	a0,0x2
ffffffffc0200620:	b4c50513          	addi	a0,a0,-1204 # ffffffffc0202168 <commands+0x570>
ffffffffc0200624:	a93ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200628:	786c                	ld	a1,240(s0)
ffffffffc020062a:	00002517          	auipc	a0,0x2
ffffffffc020062e:	b5650513          	addi	a0,a0,-1194 # ffffffffc0202180 <commands+0x588>
ffffffffc0200632:	a85ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200638:	6402                	ld	s0,0(sp)
ffffffffc020063a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0202198 <commands+0x5a0>
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
ffffffffc0200656:	b5e50513          	addi	a0,a0,-1186 # ffffffffc02021b0 <commands+0x5b8>
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
ffffffffc020066e:	b5e50513          	addi	a0,a0,-1186 # ffffffffc02021c8 <commands+0x5d0>
ffffffffc0200672:	a45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00002517          	auipc	a0,0x2
ffffffffc020067e:	b6650513          	addi	a0,a0,-1178 # ffffffffc02021e0 <commands+0x5e8>
ffffffffc0200682:	a35ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00002517          	auipc	a0,0x2
ffffffffc020068e:	b6e50513          	addi	a0,a0,-1170 # ffffffffc02021f8 <commands+0x600>
ffffffffc0200692:	a25ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	b7250513          	addi	a0,a0,-1166 # ffffffffc0202210 <commands+0x618>
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
ffffffffc02006c0:	6f870713          	addi	a4,a4,1784 # ffffffffc0201db4 <commands+0x1bc>
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
ffffffffc02006d2:	77a50513          	addi	a0,a0,1914 # ffffffffc0201e48 <commands+0x250>
ffffffffc02006d6:	9e1ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006da:	00001517          	auipc	a0,0x1
ffffffffc02006de:	74e50513          	addi	a0,a0,1870 # ffffffffc0201e28 <commands+0x230>
ffffffffc02006e2:	9d5ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006e6:	00001517          	auipc	a0,0x1
ffffffffc02006ea:	70250513          	addi	a0,a0,1794 # ffffffffc0201de8 <commands+0x1f0>
ffffffffc02006ee:	9c9ff06f          	j	ffffffffc02000b6 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006f2:	00001517          	auipc	a0,0x1
ffffffffc02006f6:	77650513          	addi	a0,a0,1910 # ffffffffc0201e68 <commands+0x270>
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
ffffffffc020072e:	76650513          	addi	a0,a0,1894 # ffffffffc0201e90 <commands+0x298>
ffffffffc0200732:	985ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200736:	00001517          	auipc	a0,0x1
ffffffffc020073a:	6d250513          	addi	a0,a0,1746 # ffffffffc0201e08 <commands+0x210>
ffffffffc020073e:	979ff06f          	j	ffffffffc02000b6 <cprintf>
            print_trapframe(tf);
ffffffffc0200742:	f09ff06f          	j	ffffffffc020064a <print_trapframe>
}
ffffffffc0200746:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200748:	06400593          	li	a1,100
ffffffffc020074c:	00001517          	auipc	a0,0x1
ffffffffc0200750:	73450513          	addi	a0,a0,1844 # ffffffffc0201e80 <commands+0x288>
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

ffffffffc020082a <best_fit_init>:
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

static void
best_fit_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200836:	0007a823          	sw	zero,16(a5)
}
ffffffffc020083a:	8082                	ret

ffffffffc020083c <best_fit_nr_free_pages>:

static size_t
best_fit_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc020083c:	00006517          	auipc	a0,0x6
ffffffffc0200840:	c0c56503          	lwu	a0,-1012(a0) # ffffffffc0206448 <free_area+0x10>
ffffffffc0200844:	8082                	ret

ffffffffc0200846 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200846:	c545                	beqz	a0,ffffffffc02008ee <best_fit_alloc_pages+0xa8>
    if (n > nr_free)
ffffffffc0200848:	00006617          	auipc	a2,0x6
ffffffffc020084c:	bf060613          	addi	a2,a2,-1040 # ffffffffc0206438 <free_area>
ffffffffc0200850:	01062803          	lw	a6,16(a2)
ffffffffc0200854:	86aa                	mv	a3,a0
ffffffffc0200856:	02081793          	slli	a5,a6,0x20
ffffffffc020085a:	9381                	srli	a5,a5,0x20
ffffffffc020085c:	08a7e763          	bltu	a5,a0,ffffffffc02008ea <best_fit_alloc_pages+0xa4>
    size_t min_size = nr_free + 1;
ffffffffc0200860:	0018059b          	addiw	a1,a6,1
ffffffffc0200864:	1582                	slli	a1,a1,0x20
ffffffffc0200866:	9181                	srli	a1,a1,0x20
    list_entry_t *le = &free_list;
ffffffffc0200868:	87b2                	mv	a5,a2
    struct Page *page = NULL;
ffffffffc020086a:	4501                	li	a0,0
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020086c:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc020086e:	00c78f63          	beq	a5,a2,ffffffffc020088c <best_fit_alloc_pages+0x46>
        if (p->property >= n)
ffffffffc0200872:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200876:	fed76be3          	bltu	a4,a3,ffffffffc020086c <best_fit_alloc_pages+0x26>
            if((p->property-n) < min_size)
ffffffffc020087a:	8f15                	sub	a4,a4,a3
ffffffffc020087c:	feb778e3          	bleu	a1,a4,ffffffffc020086c <best_fit_alloc_pages+0x26>
        struct Page *p = le2page(le, page_link);
ffffffffc0200880:	fe878513          	addi	a0,a5,-24
ffffffffc0200884:	679c                	ld	a5,8(a5)
ffffffffc0200886:	85ba                	mv	a1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200888:	fec795e3          	bne	a5,a2,ffffffffc0200872 <best_fit_alloc_pages+0x2c>
    if (page != NULL)
ffffffffc020088c:	c125                	beqz	a0,ffffffffc02008ec <best_fit_alloc_pages+0xa6>
    __list_del(listelm->prev, listelm->next);
ffffffffc020088e:	7118                	ld	a4,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200890:	6d10                	ld	a2,24(a0)
        if (page->property > n)
ffffffffc0200892:	490c                	lw	a1,16(a0)
ffffffffc0200894:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200898:	e618                	sd	a4,8(a2)
    next->prev = prev;
ffffffffc020089a:	e310                	sd	a2,0(a4)
ffffffffc020089c:	02059713          	slli	a4,a1,0x20
ffffffffc02008a0:	9301                	srli	a4,a4,0x20
ffffffffc02008a2:	02e6f863          	bleu	a4,a3,ffffffffc02008d2 <best_fit_alloc_pages+0x8c>
            struct Page *p = page + n;
ffffffffc02008a6:	00269713          	slli	a4,a3,0x2
ffffffffc02008aa:	9736                	add	a4,a4,a3
ffffffffc02008ac:	070e                	slli	a4,a4,0x3
ffffffffc02008ae:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02008b0:	411585bb          	subw	a1,a1,a7
ffffffffc02008b4:	cb0c                	sw	a1,16(a4)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02008b6:	4689                	li	a3,2
ffffffffc02008b8:	00870593          	addi	a1,a4,8
ffffffffc02008bc:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02008c0:	6614                	ld	a3,8(a2)
            list_add(prev, &(p->page_link));
ffffffffc02008c2:	01870593          	addi	a1,a4,24
    prev->next = next->prev = elm;
ffffffffc02008c6:	0107a803          	lw	a6,16(a5)
ffffffffc02008ca:	e28c                	sd	a1,0(a3)
ffffffffc02008cc:	e60c                	sd	a1,8(a2)
    elm->next = next;
ffffffffc02008ce:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02008d0:	ef10                	sd	a2,24(a4)
        nr_free -= n;
ffffffffc02008d2:	4118083b          	subw	a6,a6,a7
ffffffffc02008d6:	00006797          	auipc	a5,0x6
ffffffffc02008da:	b707a923          	sw	a6,-1166(a5) # ffffffffc0206448 <free_area+0x10>
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02008de:	57f5                	li	a5,-3
ffffffffc02008e0:	00850713          	addi	a4,a0,8
ffffffffc02008e4:	60f7302f          	amoand.d	zero,a5,(a4)
ffffffffc02008e8:	8082                	ret
        return NULL;
ffffffffc02008ea:	4501                	li	a0,0
}
ffffffffc02008ec:	8082                	ret
{
ffffffffc02008ee:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02008f0:	00002697          	auipc	a3,0x2
ffffffffc02008f4:	93868693          	addi	a3,a3,-1736 # ffffffffc0202228 <commands+0x630>
ffffffffc02008f8:	00002617          	auipc	a2,0x2
ffffffffc02008fc:	93860613          	addi	a2,a2,-1736 # ffffffffc0202230 <commands+0x638>
ffffffffc0200900:	05400593          	li	a1,84
ffffffffc0200904:	00002517          	auipc	a0,0x2
ffffffffc0200908:	94450513          	addi	a0,a0,-1724 # ffffffffc0202248 <commands+0x650>
{
ffffffffc020090c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020090e:	a9fff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200912 <best_fit_check>:

// LAB2: below code is used to check the best fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void)
{
ffffffffc0200912:	715d                	addi	sp,sp,-80
ffffffffc0200914:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc0200916:	00006917          	auipc	s2,0x6
ffffffffc020091a:	b2290913          	addi	s2,s2,-1246 # ffffffffc0206438 <free_area>
ffffffffc020091e:	00893783          	ld	a5,8(s2)
ffffffffc0200922:	e486                	sd	ra,72(sp)
ffffffffc0200924:	e0a2                	sd	s0,64(sp)
ffffffffc0200926:	fc26                	sd	s1,56(sp)
ffffffffc0200928:	f44e                	sd	s3,40(sp)
ffffffffc020092a:	f052                	sd	s4,32(sp)
ffffffffc020092c:	ec56                	sd	s5,24(sp)
ffffffffc020092e:	e85a                	sd	s6,16(sp)
ffffffffc0200930:	e45e                	sd	s7,8(sp)
ffffffffc0200932:	e062                	sd	s8,0(sp)
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200934:	2d278363          	beq	a5,s2,ffffffffc0200bfa <best_fit_check+0x2e8>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200938:	ff07b703          	ld	a4,-16(a5)
ffffffffc020093c:	8305                	srli	a4,a4,0x1
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020093e:	8b05                	andi	a4,a4,1
ffffffffc0200940:	2c070163          	beqz	a4,ffffffffc0200c02 <best_fit_check+0x2f0>
    int count = 0, total = 0;
ffffffffc0200944:	4401                	li	s0,0
ffffffffc0200946:	4481                	li	s1,0
ffffffffc0200948:	a031                	j	ffffffffc0200954 <best_fit_check+0x42>
ffffffffc020094a:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc020094e:	8b09                	andi	a4,a4,2
ffffffffc0200950:	2a070963          	beqz	a4,ffffffffc0200c02 <best_fit_check+0x2f0>
        count++, total += p->property;
ffffffffc0200954:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200958:	679c                	ld	a5,8(a5)
ffffffffc020095a:	2485                	addiw	s1,s1,1
ffffffffc020095c:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020095e:	ff2796e3          	bne	a5,s2,ffffffffc020094a <best_fit_check+0x38>
ffffffffc0200962:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0200964:	1f3000ef          	jal	ra,ffffffffc0201356 <nr_free_pages>
ffffffffc0200968:	37351d63          	bne	a0,s3,ffffffffc0200ce2 <best_fit_check+0x3d0>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020096c:	4505                	li	a0,1
ffffffffc020096e:	15f000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200972:	8a2a                	mv	s4,a0
ffffffffc0200974:	3a050763          	beqz	a0,ffffffffc0200d22 <best_fit_check+0x410>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200978:	4505                	li	a0,1
ffffffffc020097a:	153000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc020097e:	89aa                	mv	s3,a0
ffffffffc0200980:	38050163          	beqz	a0,ffffffffc0200d02 <best_fit_check+0x3f0>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200984:	4505                	li	a0,1
ffffffffc0200986:	147000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc020098a:	8aaa                	mv	s5,a0
ffffffffc020098c:	30050b63          	beqz	a0,ffffffffc0200ca2 <best_fit_check+0x390>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200990:	293a0963          	beq	s4,s3,ffffffffc0200c22 <best_fit_check+0x310>
ffffffffc0200994:	28aa0763          	beq	s4,a0,ffffffffc0200c22 <best_fit_check+0x310>
ffffffffc0200998:	28a98563          	beq	s3,a0,ffffffffc0200c22 <best_fit_check+0x310>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020099c:	000a2783          	lw	a5,0(s4)
ffffffffc02009a0:	2a079163          	bnez	a5,ffffffffc0200c42 <best_fit_check+0x330>
ffffffffc02009a4:	0009a783          	lw	a5,0(s3)
ffffffffc02009a8:	28079d63          	bnez	a5,ffffffffc0200c42 <best_fit_check+0x330>
ffffffffc02009ac:	411c                	lw	a5,0(a0)
ffffffffc02009ae:	28079a63          	bnez	a5,ffffffffc0200c42 <best_fit_check+0x330>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009b2:	00006797          	auipc	a5,0x6
ffffffffc02009b6:	ab678793          	addi	a5,a5,-1354 # ffffffffc0206468 <pages>
ffffffffc02009ba:	639c                	ld	a5,0(a5)
ffffffffc02009bc:	00002717          	auipc	a4,0x2
ffffffffc02009c0:	8a470713          	addi	a4,a4,-1884 # ffffffffc0202260 <commands+0x668>
ffffffffc02009c4:	630c                	ld	a1,0(a4)
ffffffffc02009c6:	40fa0733          	sub	a4,s4,a5
ffffffffc02009ca:	870d                	srai	a4,a4,0x3
ffffffffc02009cc:	02b70733          	mul	a4,a4,a1
ffffffffc02009d0:	00002697          	auipc	a3,0x2
ffffffffc02009d4:	f5068693          	addi	a3,a3,-176 # ffffffffc0202920 <nbase>
ffffffffc02009d8:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009da:	00006697          	auipc	a3,0x6
ffffffffc02009de:	a3e68693          	addi	a3,a3,-1474 # ffffffffc0206418 <npage>
ffffffffc02009e2:	6294                	ld	a3,0(a3)
ffffffffc02009e4:	06b2                	slli	a3,a3,0xc
ffffffffc02009e6:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc02009e8:	0732                	slli	a4,a4,0xc
ffffffffc02009ea:	26d77c63          	bleu	a3,a4,ffffffffc0200c62 <best_fit_check+0x350>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009ee:	40f98733          	sub	a4,s3,a5
ffffffffc02009f2:	870d                	srai	a4,a4,0x3
ffffffffc02009f4:	02b70733          	mul	a4,a4,a1
ffffffffc02009f8:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02009fa:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02009fc:	42d77363          	bleu	a3,a4,ffffffffc0200e22 <best_fit_check+0x510>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200a00:	40f507b3          	sub	a5,a0,a5
ffffffffc0200a04:	878d                	srai	a5,a5,0x3
ffffffffc0200a06:	02b787b3          	mul	a5,a5,a1
ffffffffc0200a0a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a0c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200a0e:	3ed7fa63          	bleu	a3,a5,ffffffffc0200e02 <best_fit_check+0x4f0>
    assert(alloc_page() == NULL);
ffffffffc0200a12:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200a14:	00093c03          	ld	s8,0(s2)
ffffffffc0200a18:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200a1c:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200a20:	00006797          	auipc	a5,0x6
ffffffffc0200a24:	a327b023          	sd	s2,-1504(a5) # ffffffffc0206440 <free_area+0x8>
ffffffffc0200a28:	00006797          	auipc	a5,0x6
ffffffffc0200a2c:	a127b823          	sd	s2,-1520(a5) # ffffffffc0206438 <free_area>
    nr_free = 0;
ffffffffc0200a30:	00006797          	auipc	a5,0x6
ffffffffc0200a34:	a007ac23          	sw	zero,-1512(a5) # ffffffffc0206448 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200a38:	095000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200a3c:	3a051363          	bnez	a0,ffffffffc0200de2 <best_fit_check+0x4d0>
    free_page(p0);
ffffffffc0200a40:	4585                	li	a1,1
ffffffffc0200a42:	8552                	mv	a0,s4
ffffffffc0200a44:	0cd000ef          	jal	ra,ffffffffc0201310 <free_pages>
    free_page(p1);
ffffffffc0200a48:	4585                	li	a1,1
ffffffffc0200a4a:	854e                	mv	a0,s3
ffffffffc0200a4c:	0c5000ef          	jal	ra,ffffffffc0201310 <free_pages>
    free_page(p2);
ffffffffc0200a50:	4585                	li	a1,1
ffffffffc0200a52:	8556                	mv	a0,s5
ffffffffc0200a54:	0bd000ef          	jal	ra,ffffffffc0201310 <free_pages>
    assert(nr_free == 3);
ffffffffc0200a58:	01092703          	lw	a4,16(s2)
ffffffffc0200a5c:	478d                	li	a5,3
ffffffffc0200a5e:	36f71263          	bne	a4,a5,ffffffffc0200dc2 <best_fit_check+0x4b0>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a62:	4505                	li	a0,1
ffffffffc0200a64:	069000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200a68:	89aa                	mv	s3,a0
ffffffffc0200a6a:	32050c63          	beqz	a0,ffffffffc0200da2 <best_fit_check+0x490>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a6e:	4505                	li	a0,1
ffffffffc0200a70:	05d000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200a74:	8aaa                	mv	s5,a0
ffffffffc0200a76:	30050663          	beqz	a0,ffffffffc0200d82 <best_fit_check+0x470>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a7a:	4505                	li	a0,1
ffffffffc0200a7c:	051000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200a80:	8a2a                	mv	s4,a0
ffffffffc0200a82:	2e050063          	beqz	a0,ffffffffc0200d62 <best_fit_check+0x450>
    assert(alloc_page() == NULL);
ffffffffc0200a86:	4505                	li	a0,1
ffffffffc0200a88:	045000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200a8c:	2a051b63          	bnez	a0,ffffffffc0200d42 <best_fit_check+0x430>
    free_page(p0);
ffffffffc0200a90:	4585                	li	a1,1
ffffffffc0200a92:	854e                	mv	a0,s3
ffffffffc0200a94:	07d000ef          	jal	ra,ffffffffc0201310 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200a98:	00893783          	ld	a5,8(s2)
ffffffffc0200a9c:	1f278363          	beq	a5,s2,ffffffffc0200c82 <best_fit_check+0x370>
    assert((p = alloc_page()) == p0);
ffffffffc0200aa0:	4505                	li	a0,1
ffffffffc0200aa2:	02b000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200aa6:	54a99e63          	bne	s3,a0,ffffffffc0201002 <best_fit_check+0x6f0>
    assert(alloc_page() == NULL);
ffffffffc0200aaa:	4505                	li	a0,1
ffffffffc0200aac:	021000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200ab0:	52051963          	bnez	a0,ffffffffc0200fe2 <best_fit_check+0x6d0>
    assert(nr_free == 0);
ffffffffc0200ab4:	01092783          	lw	a5,16(s2)
ffffffffc0200ab8:	50079563          	bnez	a5,ffffffffc0200fc2 <best_fit_check+0x6b0>
    free_page(p);
ffffffffc0200abc:	854e                	mv	a0,s3
ffffffffc0200abe:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200ac0:	00006797          	auipc	a5,0x6
ffffffffc0200ac4:	9787bc23          	sd	s8,-1672(a5) # ffffffffc0206438 <free_area>
ffffffffc0200ac8:	00006797          	auipc	a5,0x6
ffffffffc0200acc:	9777bc23          	sd	s7,-1672(a5) # ffffffffc0206440 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0200ad0:	00006797          	auipc	a5,0x6
ffffffffc0200ad4:	9767ac23          	sw	s6,-1672(a5) # ffffffffc0206448 <free_area+0x10>
    free_page(p);
ffffffffc0200ad8:	039000ef          	jal	ra,ffffffffc0201310 <free_pages>
    free_page(p1);
ffffffffc0200adc:	4585                	li	a1,1
ffffffffc0200ade:	8556                	mv	a0,s5
ffffffffc0200ae0:	031000ef          	jal	ra,ffffffffc0201310 <free_pages>
    free_page(p2);
ffffffffc0200ae4:	4585                	li	a1,1
ffffffffc0200ae6:	8552                	mv	a0,s4
ffffffffc0200ae8:	029000ef          	jal	ra,ffffffffc0201310 <free_pages>

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200aec:	4515                	li	a0,5
ffffffffc0200aee:	7de000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200af2:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200af4:	4a050763          	beqz	a0,ffffffffc0200fa2 <best_fit_check+0x690>
ffffffffc0200af8:	651c                	ld	a5,8(a0)
ffffffffc0200afa:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200afc:	8b85                	andi	a5,a5,1
ffffffffc0200afe:	48079263          	bnez	a5,ffffffffc0200f82 <best_fit_check+0x670>
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200b02:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200b04:	00093b03          	ld	s6,0(s2)
ffffffffc0200b08:	00893a83          	ld	s5,8(s2)
ffffffffc0200b0c:	00006797          	auipc	a5,0x6
ffffffffc0200b10:	9327b623          	sd	s2,-1748(a5) # ffffffffc0206438 <free_area>
ffffffffc0200b14:	00006797          	auipc	a5,0x6
ffffffffc0200b18:	9327b623          	sd	s2,-1748(a5) # ffffffffc0206440 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0200b1c:	7b0000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200b20:	44051163          	bnez	a0,ffffffffc0200f62 <best_fit_check+0x650>
#endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200b24:	4589                	li	a1,2
ffffffffc0200b26:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200b2a:	01092b83          	lw	s7,16(s2)
    free_pages(p0 + 4, 1);
ffffffffc0200b2e:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200b32:	00006797          	auipc	a5,0x6
ffffffffc0200b36:	9007ab23          	sw	zero,-1770(a5) # ffffffffc0206448 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200b3a:	7d6000ef          	jal	ra,ffffffffc0201310 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200b3e:	8562                	mv	a0,s8
ffffffffc0200b40:	4585                	li	a1,1
ffffffffc0200b42:	7ce000ef          	jal	ra,ffffffffc0201310 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200b46:	4511                	li	a0,4
ffffffffc0200b48:	784000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200b4c:	3e051b63          	bnez	a0,ffffffffc0200f42 <best_fit_check+0x630>
ffffffffc0200b50:	0309b783          	ld	a5,48(s3)
ffffffffc0200b54:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200b56:	8b85                	andi	a5,a5,1
ffffffffc0200b58:	3c078563          	beqz	a5,ffffffffc0200f22 <best_fit_check+0x610>
ffffffffc0200b5c:	0389a703          	lw	a4,56(s3)
ffffffffc0200b60:	4789                	li	a5,2
ffffffffc0200b62:	3cf71063          	bne	a4,a5,ffffffffc0200f22 <best_fit_check+0x610>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200b66:	4505                	li	a0,1
ffffffffc0200b68:	764000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200b6c:	8a2a                	mv	s4,a0
ffffffffc0200b6e:	38050a63          	beqz	a0,ffffffffc0200f02 <best_fit_check+0x5f0>
    assert(alloc_pages(2) != NULL); // best fit feature
ffffffffc0200b72:	4509                	li	a0,2
ffffffffc0200b74:	758000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200b78:	36050563          	beqz	a0,ffffffffc0200ee2 <best_fit_check+0x5d0>
    assert(p0 + 4 == p1);
ffffffffc0200b7c:	354c1363          	bne	s8,s4,ffffffffc0200ec2 <best_fit_check+0x5b0>
#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200b80:	854e                	mv	a0,s3
ffffffffc0200b82:	4595                	li	a1,5
ffffffffc0200b84:	78c000ef          	jal	ra,ffffffffc0201310 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200b88:	4515                	li	a0,5
ffffffffc0200b8a:	742000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200b8e:	89aa                	mv	s3,a0
ffffffffc0200b90:	30050963          	beqz	a0,ffffffffc0200ea2 <best_fit_check+0x590>
    assert(alloc_page() == NULL);
ffffffffc0200b94:	4505                	li	a0,1
ffffffffc0200b96:	736000ef          	jal	ra,ffffffffc02012cc <alloc_pages>
ffffffffc0200b9a:	2e051463          	bnez	a0,ffffffffc0200e82 <best_fit_check+0x570>

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    assert(nr_free == 0);
ffffffffc0200b9e:	01092783          	lw	a5,16(s2)
ffffffffc0200ba2:	2c079063          	bnez	a5,ffffffffc0200e62 <best_fit_check+0x550>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200ba6:	4595                	li	a1,5
ffffffffc0200ba8:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200baa:	00006797          	auipc	a5,0x6
ffffffffc0200bae:	8977af23          	sw	s7,-1890(a5) # ffffffffc0206448 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0200bb2:	00006797          	auipc	a5,0x6
ffffffffc0200bb6:	8967b323          	sd	s6,-1914(a5) # ffffffffc0206438 <free_area>
ffffffffc0200bba:	00006797          	auipc	a5,0x6
ffffffffc0200bbe:	8957b323          	sd	s5,-1914(a5) # ffffffffc0206440 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0200bc2:	74e000ef          	jal	ra,ffffffffc0201310 <free_pages>
    return listelm->next;
ffffffffc0200bc6:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200bca:	01278963          	beq	a5,s2,ffffffffc0200bdc <best_fit_check+0x2ca>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0200bce:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200bd2:	679c                	ld	a5,8(a5)
ffffffffc0200bd4:	34fd                	addiw	s1,s1,-1
ffffffffc0200bd6:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200bd8:	ff279be3          	bne	a5,s2,ffffffffc0200bce <best_fit_check+0x2bc>
    }
    assert(count == 0);
ffffffffc0200bdc:	26049363          	bnez	s1,ffffffffc0200e42 <best_fit_check+0x530>
    assert(total == 0);
ffffffffc0200be0:	e06d                	bnez	s0,ffffffffc0200cc2 <best_fit_check+0x3b0>

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
}
ffffffffc0200be2:	60a6                	ld	ra,72(sp)
ffffffffc0200be4:	6406                	ld	s0,64(sp)
ffffffffc0200be6:	74e2                	ld	s1,56(sp)
ffffffffc0200be8:	7942                	ld	s2,48(sp)
ffffffffc0200bea:	79a2                	ld	s3,40(sp)
ffffffffc0200bec:	7a02                	ld	s4,32(sp)
ffffffffc0200bee:	6ae2                	ld	s5,24(sp)
ffffffffc0200bf0:	6b42                	ld	s6,16(sp)
ffffffffc0200bf2:	6ba2                	ld	s7,8(sp)
ffffffffc0200bf4:	6c02                	ld	s8,0(sp)
ffffffffc0200bf6:	6161                	addi	sp,sp,80
ffffffffc0200bf8:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0200bfa:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200bfc:	4401                	li	s0,0
ffffffffc0200bfe:	4481                	li	s1,0
ffffffffc0200c00:	b395                	j	ffffffffc0200964 <best_fit_check+0x52>
        assert(PageProperty(p));
ffffffffc0200c02:	00001697          	auipc	a3,0x1
ffffffffc0200c06:	66668693          	addi	a3,a3,1638 # ffffffffc0202268 <commands+0x670>
ffffffffc0200c0a:	00001617          	auipc	a2,0x1
ffffffffc0200c0e:	62660613          	addi	a2,a2,1574 # ffffffffc0202230 <commands+0x638>
ffffffffc0200c12:	13100593          	li	a1,305
ffffffffc0200c16:	00001517          	auipc	a0,0x1
ffffffffc0200c1a:	63250513          	addi	a0,a0,1586 # ffffffffc0202248 <commands+0x650>
ffffffffc0200c1e:	f8eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c22:	00001697          	auipc	a3,0x1
ffffffffc0200c26:	6d668693          	addi	a3,a3,1750 # ffffffffc02022f8 <commands+0x700>
ffffffffc0200c2a:	00001617          	auipc	a2,0x1
ffffffffc0200c2e:	60660613          	addi	a2,a2,1542 # ffffffffc0202230 <commands+0x638>
ffffffffc0200c32:	0f900593          	li	a1,249
ffffffffc0200c36:	00001517          	auipc	a0,0x1
ffffffffc0200c3a:	61250513          	addi	a0,a0,1554 # ffffffffc0202248 <commands+0x650>
ffffffffc0200c3e:	f6eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c42:	00001697          	auipc	a3,0x1
ffffffffc0200c46:	6de68693          	addi	a3,a3,1758 # ffffffffc0202320 <commands+0x728>
ffffffffc0200c4a:	00001617          	auipc	a2,0x1
ffffffffc0200c4e:	5e660613          	addi	a2,a2,1510 # ffffffffc0202230 <commands+0x638>
ffffffffc0200c52:	0fa00593          	li	a1,250
ffffffffc0200c56:	00001517          	auipc	a0,0x1
ffffffffc0200c5a:	5f250513          	addi	a0,a0,1522 # ffffffffc0202248 <commands+0x650>
ffffffffc0200c5e:	f4eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200c62:	00001697          	auipc	a3,0x1
ffffffffc0200c66:	6fe68693          	addi	a3,a3,1790 # ffffffffc0202360 <commands+0x768>
ffffffffc0200c6a:	00001617          	auipc	a2,0x1
ffffffffc0200c6e:	5c660613          	addi	a2,a2,1478 # ffffffffc0202230 <commands+0x638>
ffffffffc0200c72:	0fc00593          	li	a1,252
ffffffffc0200c76:	00001517          	auipc	a0,0x1
ffffffffc0200c7a:	5d250513          	addi	a0,a0,1490 # ffffffffc0202248 <commands+0x650>
ffffffffc0200c7e:	f2eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200c82:	00001697          	auipc	a3,0x1
ffffffffc0200c86:	76668693          	addi	a3,a3,1894 # ffffffffc02023e8 <commands+0x7f0>
ffffffffc0200c8a:	00001617          	auipc	a2,0x1
ffffffffc0200c8e:	5a660613          	addi	a2,a2,1446 # ffffffffc0202230 <commands+0x638>
ffffffffc0200c92:	11500593          	li	a1,277
ffffffffc0200c96:	00001517          	auipc	a0,0x1
ffffffffc0200c9a:	5b250513          	addi	a0,a0,1458 # ffffffffc0202248 <commands+0x650>
ffffffffc0200c9e:	f0eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ca2:	00001697          	auipc	a3,0x1
ffffffffc0200ca6:	63668693          	addi	a3,a3,1590 # ffffffffc02022d8 <commands+0x6e0>
ffffffffc0200caa:	00001617          	auipc	a2,0x1
ffffffffc0200cae:	58660613          	addi	a2,a2,1414 # ffffffffc0202230 <commands+0x638>
ffffffffc0200cb2:	0f700593          	li	a1,247
ffffffffc0200cb6:	00001517          	auipc	a0,0x1
ffffffffc0200cba:	59250513          	addi	a0,a0,1426 # ffffffffc0202248 <commands+0x650>
ffffffffc0200cbe:	eeeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total == 0);
ffffffffc0200cc2:	00002697          	auipc	a3,0x2
ffffffffc0200cc6:	85668693          	addi	a3,a3,-1962 # ffffffffc0202518 <commands+0x920>
ffffffffc0200cca:	00001617          	auipc	a2,0x1
ffffffffc0200cce:	56660613          	addi	a2,a2,1382 # ffffffffc0202230 <commands+0x638>
ffffffffc0200cd2:	17f00593          	li	a1,383
ffffffffc0200cd6:	00001517          	auipc	a0,0x1
ffffffffc0200cda:	57250513          	addi	a0,a0,1394 # ffffffffc0202248 <commands+0x650>
ffffffffc0200cde:	eceff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total == nr_free_pages());
ffffffffc0200ce2:	00001697          	auipc	a3,0x1
ffffffffc0200ce6:	59668693          	addi	a3,a3,1430 # ffffffffc0202278 <commands+0x680>
ffffffffc0200cea:	00001617          	auipc	a2,0x1
ffffffffc0200cee:	54660613          	addi	a2,a2,1350 # ffffffffc0202230 <commands+0x638>
ffffffffc0200cf2:	13400593          	li	a1,308
ffffffffc0200cf6:	00001517          	auipc	a0,0x1
ffffffffc0200cfa:	55250513          	addi	a0,a0,1362 # ffffffffc0202248 <commands+0x650>
ffffffffc0200cfe:	eaeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d02:	00001697          	auipc	a3,0x1
ffffffffc0200d06:	5b668693          	addi	a3,a3,1462 # ffffffffc02022b8 <commands+0x6c0>
ffffffffc0200d0a:	00001617          	auipc	a2,0x1
ffffffffc0200d0e:	52660613          	addi	a2,a2,1318 # ffffffffc0202230 <commands+0x638>
ffffffffc0200d12:	0f600593          	li	a1,246
ffffffffc0200d16:	00001517          	auipc	a0,0x1
ffffffffc0200d1a:	53250513          	addi	a0,a0,1330 # ffffffffc0202248 <commands+0x650>
ffffffffc0200d1e:	e8eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d22:	00001697          	auipc	a3,0x1
ffffffffc0200d26:	57668693          	addi	a3,a3,1398 # ffffffffc0202298 <commands+0x6a0>
ffffffffc0200d2a:	00001617          	auipc	a2,0x1
ffffffffc0200d2e:	50660613          	addi	a2,a2,1286 # ffffffffc0202230 <commands+0x638>
ffffffffc0200d32:	0f500593          	li	a1,245
ffffffffc0200d36:	00001517          	auipc	a0,0x1
ffffffffc0200d3a:	51250513          	addi	a0,a0,1298 # ffffffffc0202248 <commands+0x650>
ffffffffc0200d3e:	e6eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d42:	00001697          	auipc	a3,0x1
ffffffffc0200d46:	67e68693          	addi	a3,a3,1662 # ffffffffc02023c0 <commands+0x7c8>
ffffffffc0200d4a:	00001617          	auipc	a2,0x1
ffffffffc0200d4e:	4e660613          	addi	a2,a2,1254 # ffffffffc0202230 <commands+0x638>
ffffffffc0200d52:	11200593          	li	a1,274
ffffffffc0200d56:	00001517          	auipc	a0,0x1
ffffffffc0200d5a:	4f250513          	addi	a0,a0,1266 # ffffffffc0202248 <commands+0x650>
ffffffffc0200d5e:	e4eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d62:	00001697          	auipc	a3,0x1
ffffffffc0200d66:	57668693          	addi	a3,a3,1398 # ffffffffc02022d8 <commands+0x6e0>
ffffffffc0200d6a:	00001617          	auipc	a2,0x1
ffffffffc0200d6e:	4c660613          	addi	a2,a2,1222 # ffffffffc0202230 <commands+0x638>
ffffffffc0200d72:	11000593          	li	a1,272
ffffffffc0200d76:	00001517          	auipc	a0,0x1
ffffffffc0200d7a:	4d250513          	addi	a0,a0,1234 # ffffffffc0202248 <commands+0x650>
ffffffffc0200d7e:	e2eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d82:	00001697          	auipc	a3,0x1
ffffffffc0200d86:	53668693          	addi	a3,a3,1334 # ffffffffc02022b8 <commands+0x6c0>
ffffffffc0200d8a:	00001617          	auipc	a2,0x1
ffffffffc0200d8e:	4a660613          	addi	a2,a2,1190 # ffffffffc0202230 <commands+0x638>
ffffffffc0200d92:	10f00593          	li	a1,271
ffffffffc0200d96:	00001517          	auipc	a0,0x1
ffffffffc0200d9a:	4b250513          	addi	a0,a0,1202 # ffffffffc0202248 <commands+0x650>
ffffffffc0200d9e:	e0eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200da2:	00001697          	auipc	a3,0x1
ffffffffc0200da6:	4f668693          	addi	a3,a3,1270 # ffffffffc0202298 <commands+0x6a0>
ffffffffc0200daa:	00001617          	auipc	a2,0x1
ffffffffc0200dae:	48660613          	addi	a2,a2,1158 # ffffffffc0202230 <commands+0x638>
ffffffffc0200db2:	10e00593          	li	a1,270
ffffffffc0200db6:	00001517          	auipc	a0,0x1
ffffffffc0200dba:	49250513          	addi	a0,a0,1170 # ffffffffc0202248 <commands+0x650>
ffffffffc0200dbe:	deeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 3);
ffffffffc0200dc2:	00001697          	auipc	a3,0x1
ffffffffc0200dc6:	61668693          	addi	a3,a3,1558 # ffffffffc02023d8 <commands+0x7e0>
ffffffffc0200dca:	00001617          	auipc	a2,0x1
ffffffffc0200dce:	46660613          	addi	a2,a2,1126 # ffffffffc0202230 <commands+0x638>
ffffffffc0200dd2:	10c00593          	li	a1,268
ffffffffc0200dd6:	00001517          	auipc	a0,0x1
ffffffffc0200dda:	47250513          	addi	a0,a0,1138 # ffffffffc0202248 <commands+0x650>
ffffffffc0200dde:	dceff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200de2:	00001697          	auipc	a3,0x1
ffffffffc0200de6:	5de68693          	addi	a3,a3,1502 # ffffffffc02023c0 <commands+0x7c8>
ffffffffc0200dea:	00001617          	auipc	a2,0x1
ffffffffc0200dee:	44660613          	addi	a2,a2,1094 # ffffffffc0202230 <commands+0x638>
ffffffffc0200df2:	10700593          	li	a1,263
ffffffffc0200df6:	00001517          	auipc	a0,0x1
ffffffffc0200dfa:	45250513          	addi	a0,a0,1106 # ffffffffc0202248 <commands+0x650>
ffffffffc0200dfe:	daeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e02:	00001697          	auipc	a3,0x1
ffffffffc0200e06:	59e68693          	addi	a3,a3,1438 # ffffffffc02023a0 <commands+0x7a8>
ffffffffc0200e0a:	00001617          	auipc	a2,0x1
ffffffffc0200e0e:	42660613          	addi	a2,a2,1062 # ffffffffc0202230 <commands+0x638>
ffffffffc0200e12:	0fe00593          	li	a1,254
ffffffffc0200e16:	00001517          	auipc	a0,0x1
ffffffffc0200e1a:	43250513          	addi	a0,a0,1074 # ffffffffc0202248 <commands+0x650>
ffffffffc0200e1e:	d8eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e22:	00001697          	auipc	a3,0x1
ffffffffc0200e26:	55e68693          	addi	a3,a3,1374 # ffffffffc0202380 <commands+0x788>
ffffffffc0200e2a:	00001617          	auipc	a2,0x1
ffffffffc0200e2e:	40660613          	addi	a2,a2,1030 # ffffffffc0202230 <commands+0x638>
ffffffffc0200e32:	0fd00593          	li	a1,253
ffffffffc0200e36:	00001517          	auipc	a0,0x1
ffffffffc0200e3a:	41250513          	addi	a0,a0,1042 # ffffffffc0202248 <commands+0x650>
ffffffffc0200e3e:	d6eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(count == 0);
ffffffffc0200e42:	00001697          	auipc	a3,0x1
ffffffffc0200e46:	6c668693          	addi	a3,a3,1734 # ffffffffc0202508 <commands+0x910>
ffffffffc0200e4a:	00001617          	auipc	a2,0x1
ffffffffc0200e4e:	3e660613          	addi	a2,a2,998 # ffffffffc0202230 <commands+0x638>
ffffffffc0200e52:	17e00593          	li	a1,382
ffffffffc0200e56:	00001517          	auipc	a0,0x1
ffffffffc0200e5a:	3f250513          	addi	a0,a0,1010 # ffffffffc0202248 <commands+0x650>
ffffffffc0200e5e:	d4eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 0);
ffffffffc0200e62:	00001697          	auipc	a3,0x1
ffffffffc0200e66:	5be68693          	addi	a3,a3,1470 # ffffffffc0202420 <commands+0x828>
ffffffffc0200e6a:	00001617          	auipc	a2,0x1
ffffffffc0200e6e:	3c660613          	addi	a2,a2,966 # ffffffffc0202230 <commands+0x638>
ffffffffc0200e72:	17200593          	li	a1,370
ffffffffc0200e76:	00001517          	auipc	a0,0x1
ffffffffc0200e7a:	3d250513          	addi	a0,a0,978 # ffffffffc0202248 <commands+0x650>
ffffffffc0200e7e:	d2eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e82:	00001697          	auipc	a3,0x1
ffffffffc0200e86:	53e68693          	addi	a3,a3,1342 # ffffffffc02023c0 <commands+0x7c8>
ffffffffc0200e8a:	00001617          	auipc	a2,0x1
ffffffffc0200e8e:	3a660613          	addi	a2,a2,934 # ffffffffc0202230 <commands+0x638>
ffffffffc0200e92:	16a00593          	li	a1,362
ffffffffc0200e96:	00001517          	auipc	a0,0x1
ffffffffc0200e9a:	3b250513          	addi	a0,a0,946 # ffffffffc0202248 <commands+0x650>
ffffffffc0200e9e:	d0eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200ea2:	00001697          	auipc	a3,0x1
ffffffffc0200ea6:	64668693          	addi	a3,a3,1606 # ffffffffc02024e8 <commands+0x8f0>
ffffffffc0200eaa:	00001617          	auipc	a2,0x1
ffffffffc0200eae:	38660613          	addi	a2,a2,902 # ffffffffc0202230 <commands+0x638>
ffffffffc0200eb2:	16900593          	li	a1,361
ffffffffc0200eb6:	00001517          	auipc	a0,0x1
ffffffffc0200eba:	39250513          	addi	a0,a0,914 # ffffffffc0202248 <commands+0x650>
ffffffffc0200ebe:	ceeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200ec2:	00001697          	auipc	a3,0x1
ffffffffc0200ec6:	61668693          	addi	a3,a3,1558 # ffffffffc02024d8 <commands+0x8e0>
ffffffffc0200eca:	00001617          	auipc	a2,0x1
ffffffffc0200ece:	36660613          	addi	a2,a2,870 # ffffffffc0202230 <commands+0x638>
ffffffffc0200ed2:	15f00593          	li	a1,351
ffffffffc0200ed6:	00001517          	auipc	a0,0x1
ffffffffc0200eda:	37250513          	addi	a0,a0,882 # ffffffffc0202248 <commands+0x650>
ffffffffc0200ede:	cceff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_pages(2) != NULL); // best fit feature
ffffffffc0200ee2:	00001697          	auipc	a3,0x1
ffffffffc0200ee6:	5de68693          	addi	a3,a3,1502 # ffffffffc02024c0 <commands+0x8c8>
ffffffffc0200eea:	00001617          	auipc	a2,0x1
ffffffffc0200eee:	34660613          	addi	a2,a2,838 # ffffffffc0202230 <commands+0x638>
ffffffffc0200ef2:	15e00593          	li	a1,350
ffffffffc0200ef6:	00001517          	auipc	a0,0x1
ffffffffc0200efa:	35250513          	addi	a0,a0,850 # ffffffffc0202248 <commands+0x650>
ffffffffc0200efe:	caeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200f02:	00001697          	auipc	a3,0x1
ffffffffc0200f06:	59e68693          	addi	a3,a3,1438 # ffffffffc02024a0 <commands+0x8a8>
ffffffffc0200f0a:	00001617          	auipc	a2,0x1
ffffffffc0200f0e:	32660613          	addi	a2,a2,806 # ffffffffc0202230 <commands+0x638>
ffffffffc0200f12:	15d00593          	li	a1,349
ffffffffc0200f16:	00001517          	auipc	a0,0x1
ffffffffc0200f1a:	33250513          	addi	a0,a0,818 # ffffffffc0202248 <commands+0x650>
ffffffffc0200f1e:	c8eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200f22:	00001697          	auipc	a3,0x1
ffffffffc0200f26:	54e68693          	addi	a3,a3,1358 # ffffffffc0202470 <commands+0x878>
ffffffffc0200f2a:	00001617          	auipc	a2,0x1
ffffffffc0200f2e:	30660613          	addi	a2,a2,774 # ffffffffc0202230 <commands+0x638>
ffffffffc0200f32:	15b00593          	li	a1,347
ffffffffc0200f36:	00001517          	auipc	a0,0x1
ffffffffc0200f3a:	31250513          	addi	a0,a0,786 # ffffffffc0202248 <commands+0x650>
ffffffffc0200f3e:	c6eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f42:	00001697          	auipc	a3,0x1
ffffffffc0200f46:	51668693          	addi	a3,a3,1302 # ffffffffc0202458 <commands+0x860>
ffffffffc0200f4a:	00001617          	auipc	a2,0x1
ffffffffc0200f4e:	2e660613          	addi	a2,a2,742 # ffffffffc0202230 <commands+0x638>
ffffffffc0200f52:	15a00593          	li	a1,346
ffffffffc0200f56:	00001517          	auipc	a0,0x1
ffffffffc0200f5a:	2f250513          	addi	a0,a0,754 # ffffffffc0202248 <commands+0x650>
ffffffffc0200f5e:	c4eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f62:	00001697          	auipc	a3,0x1
ffffffffc0200f66:	45e68693          	addi	a3,a3,1118 # ffffffffc02023c0 <commands+0x7c8>
ffffffffc0200f6a:	00001617          	auipc	a2,0x1
ffffffffc0200f6e:	2c660613          	addi	a2,a2,710 # ffffffffc0202230 <commands+0x638>
ffffffffc0200f72:	14c00593          	li	a1,332
ffffffffc0200f76:	00001517          	auipc	a0,0x1
ffffffffc0200f7a:	2d250513          	addi	a0,a0,722 # ffffffffc0202248 <commands+0x650>
ffffffffc0200f7e:	c2eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageProperty(p0));
ffffffffc0200f82:	00001697          	auipc	a3,0x1
ffffffffc0200f86:	4be68693          	addi	a3,a3,1214 # ffffffffc0202440 <commands+0x848>
ffffffffc0200f8a:	00001617          	auipc	a2,0x1
ffffffffc0200f8e:	2a660613          	addi	a2,a2,678 # ffffffffc0202230 <commands+0x638>
ffffffffc0200f92:	14100593          	li	a1,321
ffffffffc0200f96:	00001517          	auipc	a0,0x1
ffffffffc0200f9a:	2b250513          	addi	a0,a0,690 # ffffffffc0202248 <commands+0x650>
ffffffffc0200f9e:	c0eff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != NULL);
ffffffffc0200fa2:	00001697          	auipc	a3,0x1
ffffffffc0200fa6:	48e68693          	addi	a3,a3,1166 # ffffffffc0202430 <commands+0x838>
ffffffffc0200faa:	00001617          	auipc	a2,0x1
ffffffffc0200fae:	28660613          	addi	a2,a2,646 # ffffffffc0202230 <commands+0x638>
ffffffffc0200fb2:	14000593          	li	a1,320
ffffffffc0200fb6:	00001517          	auipc	a0,0x1
ffffffffc0200fba:	29250513          	addi	a0,a0,658 # ffffffffc0202248 <commands+0x650>
ffffffffc0200fbe:	beeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 0);
ffffffffc0200fc2:	00001697          	auipc	a3,0x1
ffffffffc0200fc6:	45e68693          	addi	a3,a3,1118 # ffffffffc0202420 <commands+0x828>
ffffffffc0200fca:	00001617          	auipc	a2,0x1
ffffffffc0200fce:	26660613          	addi	a2,a2,614 # ffffffffc0202230 <commands+0x638>
ffffffffc0200fd2:	11b00593          	li	a1,283
ffffffffc0200fd6:	00001517          	auipc	a0,0x1
ffffffffc0200fda:	27250513          	addi	a0,a0,626 # ffffffffc0202248 <commands+0x650>
ffffffffc0200fde:	bceff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200fe2:	00001697          	auipc	a3,0x1
ffffffffc0200fe6:	3de68693          	addi	a3,a3,990 # ffffffffc02023c0 <commands+0x7c8>
ffffffffc0200fea:	00001617          	auipc	a2,0x1
ffffffffc0200fee:	24660613          	addi	a2,a2,582 # ffffffffc0202230 <commands+0x638>
ffffffffc0200ff2:	11900593          	li	a1,281
ffffffffc0200ff6:	00001517          	auipc	a0,0x1
ffffffffc0200ffa:	25250513          	addi	a0,a0,594 # ffffffffc0202248 <commands+0x650>
ffffffffc0200ffe:	baeff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201002:	00001697          	auipc	a3,0x1
ffffffffc0201006:	3fe68693          	addi	a3,a3,1022 # ffffffffc0202400 <commands+0x808>
ffffffffc020100a:	00001617          	auipc	a2,0x1
ffffffffc020100e:	22660613          	addi	a2,a2,550 # ffffffffc0202230 <commands+0x638>
ffffffffc0201012:	11800593          	li	a1,280
ffffffffc0201016:	00001517          	auipc	a0,0x1
ffffffffc020101a:	23250513          	addi	a0,a0,562 # ffffffffc0202248 <commands+0x650>
ffffffffc020101e:	b8eff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201022 <best_fit_free_pages>:
{
ffffffffc0201022:	1141                	addi	sp,sp,-16
ffffffffc0201024:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201026:	18058063          	beqz	a1,ffffffffc02011a6 <best_fit_free_pages+0x184>
    for (; p != base + n; p++)
ffffffffc020102a:	00259693          	slli	a3,a1,0x2
ffffffffc020102e:	96ae                	add	a3,a3,a1
ffffffffc0201030:	068e                	slli	a3,a3,0x3
ffffffffc0201032:	96aa                	add	a3,a3,a0
ffffffffc0201034:	02d50d63          	beq	a0,a3,ffffffffc020106e <best_fit_free_pages+0x4c>
ffffffffc0201038:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020103a:	8b85                	andi	a5,a5,1
ffffffffc020103c:	14079563          	bnez	a5,ffffffffc0201186 <best_fit_free_pages+0x164>
ffffffffc0201040:	651c                	ld	a5,8(a0)
ffffffffc0201042:	8385                	srli	a5,a5,0x1
ffffffffc0201044:	8b85                	andi	a5,a5,1
ffffffffc0201046:	14079063          	bnez	a5,ffffffffc0201186 <best_fit_free_pages+0x164>
ffffffffc020104a:	87aa                	mv	a5,a0
ffffffffc020104c:	a809                	j	ffffffffc020105e <best_fit_free_pages+0x3c>
ffffffffc020104e:	6798                	ld	a4,8(a5)
ffffffffc0201050:	8b05                	andi	a4,a4,1
ffffffffc0201052:	12071a63          	bnez	a4,ffffffffc0201186 <best_fit_free_pages+0x164>
ffffffffc0201056:	6798                	ld	a4,8(a5)
ffffffffc0201058:	8b09                	andi	a4,a4,2
ffffffffc020105a:	12071663          	bnez	a4,ffffffffc0201186 <best_fit_free_pages+0x164>
        p->flags = 0;
ffffffffc020105e:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201062:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201066:	02878793          	addi	a5,a5,40
ffffffffc020106a:	fed792e3          	bne	a5,a3,ffffffffc020104e <best_fit_free_pages+0x2c>
    base->property = n;      // 设置基地址页的属性为释放的总页数
ffffffffc020106e:	2581                	sext.w	a1,a1
ffffffffc0201070:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);   // 设置基地址页为保留页
ffffffffc0201072:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201076:	4789                	li	a5,2
ffffffffc0201078:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;            // 增加空闲页数
ffffffffc020107c:	00005697          	auipc	a3,0x5
ffffffffc0201080:	3bc68693          	addi	a3,a3,956 # ffffffffc0206438 <free_area>
ffffffffc0201084:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201086:	669c                	ld	a5,8(a3)
ffffffffc0201088:	9db9                	addw	a1,a1,a4
ffffffffc020108a:	00005717          	auipc	a4,0x5
ffffffffc020108e:	3ab72f23          	sw	a1,958(a4) # ffffffffc0206448 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc0201092:	08d78f63          	beq	a5,a3,ffffffffc0201130 <best_fit_free_pages+0x10e>
            struct Page *page = le2page(le, page_link);
ffffffffc0201096:	fe878713          	addi	a4,a5,-24
ffffffffc020109a:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list))
ffffffffc020109c:	4801                	li	a6,0
ffffffffc020109e:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02010a2:	00e56a63          	bltu	a0,a4,ffffffffc02010b6 <best_fit_free_pages+0x94>
    return listelm->next;
ffffffffc02010a6:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02010a8:	02d70563          	beq	a4,a3,ffffffffc02010d2 <best_fit_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list)
ffffffffc02010ac:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02010ae:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02010b2:	fee57ae3          	bleu	a4,a0,ffffffffc02010a6 <best_fit_free_pages+0x84>
ffffffffc02010b6:	00080663          	beqz	a6,ffffffffc02010c2 <best_fit_free_pages+0xa0>
ffffffffc02010ba:	00005817          	auipc	a6,0x5
ffffffffc02010be:	36b83f23          	sd	a1,894(a6) # ffffffffc0206438 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02010c2:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc02010c4:	e390                	sd	a2,0(a5)
ffffffffc02010c6:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc02010c8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02010ca:	ed0c                	sd	a1,24(a0)
    if (le != &free_list)
ffffffffc02010cc:	02d59163          	bne	a1,a3,ffffffffc02010ee <best_fit_free_pages+0xcc>
ffffffffc02010d0:	a091                	j	ffffffffc0201114 <best_fit_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc02010d2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02010d4:	f114                	sd	a3,32(a0)
ffffffffc02010d6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02010d8:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02010da:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc02010dc:	00d70563          	beq	a4,a3,ffffffffc02010e6 <best_fit_free_pages+0xc4>
ffffffffc02010e0:	4805                	li	a6,1
ffffffffc02010e2:	87ba                	mv	a5,a4
ffffffffc02010e4:	b7e9                	j	ffffffffc02010ae <best_fit_free_pages+0x8c>
ffffffffc02010e6:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02010e8:	85be                	mv	a1,a5
    if (le != &free_list)
ffffffffc02010ea:	02d78163          	beq	a5,a3,ffffffffc020110c <best_fit_free_pages+0xea>
        if (p + p->property == base)
ffffffffc02010ee:	ff85a803          	lw	a6,-8(a1)
        p = le2page(le, page_link);
ffffffffc02010f2:	fe858613          	addi	a2,a1,-24
        if (p + p->property == base)
ffffffffc02010f6:	02081713          	slli	a4,a6,0x20
ffffffffc02010fa:	9301                	srli	a4,a4,0x20
ffffffffc02010fc:	00271793          	slli	a5,a4,0x2
ffffffffc0201100:	97ba                	add	a5,a5,a4
ffffffffc0201102:	078e                	slli	a5,a5,0x3
ffffffffc0201104:	97b2                	add	a5,a5,a2
ffffffffc0201106:	02f50e63          	beq	a0,a5,ffffffffc0201142 <best_fit_free_pages+0x120>
ffffffffc020110a:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc020110c:	fe878713          	addi	a4,a5,-24
ffffffffc0201110:	00d78d63          	beq	a5,a3,ffffffffc020112a <best_fit_free_pages+0x108>
        if (base + base->property == p)
ffffffffc0201114:	490c                	lw	a1,16(a0)
ffffffffc0201116:	02059613          	slli	a2,a1,0x20
ffffffffc020111a:	9201                	srli	a2,a2,0x20
ffffffffc020111c:	00261693          	slli	a3,a2,0x2
ffffffffc0201120:	96b2                	add	a3,a3,a2
ffffffffc0201122:	068e                	slli	a3,a3,0x3
ffffffffc0201124:	96aa                	add	a3,a3,a0
ffffffffc0201126:	04d70063          	beq	a4,a3,ffffffffc0201166 <best_fit_free_pages+0x144>
}
ffffffffc020112a:	60a2                	ld	ra,8(sp)
ffffffffc020112c:	0141                	addi	sp,sp,16
ffffffffc020112e:	8082                	ret
ffffffffc0201130:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201132:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201136:	e398                	sd	a4,0(a5)
ffffffffc0201138:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020113a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020113c:	ed1c                	sd	a5,24(a0)
}
ffffffffc020113e:	0141                	addi	sp,sp,16
ffffffffc0201140:	8082                	ret
            p->property += base->property;
ffffffffc0201142:	491c                	lw	a5,16(a0)
ffffffffc0201144:	0107883b          	addw	a6,a5,a6
ffffffffc0201148:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020114c:	57f5                	li	a5,-3
ffffffffc020114e:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201152:	01853803          	ld	a6,24(a0)
ffffffffc0201156:	7118                	ld	a4,32(a0)
            base = p;
ffffffffc0201158:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc020115a:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc020115e:	659c                	ld	a5,8(a1)
ffffffffc0201160:	01073023          	sd	a6,0(a4)
ffffffffc0201164:	b765                	j	ffffffffc020110c <best_fit_free_pages+0xea>
            base->property += p->property;
ffffffffc0201166:	ff87a703          	lw	a4,-8(a5)
ffffffffc020116a:	ff078693          	addi	a3,a5,-16
ffffffffc020116e:	9db9                	addw	a1,a1,a4
ffffffffc0201170:	c90c                	sw	a1,16(a0)
ffffffffc0201172:	5775                	li	a4,-3
ffffffffc0201174:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201178:	6398                	ld	a4,0(a5)
ffffffffc020117a:	679c                	ld	a5,8(a5)
}
ffffffffc020117c:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020117e:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201180:	e398                	sd	a4,0(a5)
ffffffffc0201182:	0141                	addi	sp,sp,16
ffffffffc0201184:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201186:	00001697          	auipc	a3,0x1
ffffffffc020118a:	3a268693          	addi	a3,a3,930 # ffffffffc0202528 <commands+0x930>
ffffffffc020118e:	00001617          	auipc	a2,0x1
ffffffffc0201192:	0a260613          	addi	a2,a2,162 # ffffffffc0202230 <commands+0x638>
ffffffffc0201196:	0a300593          	li	a1,163
ffffffffc020119a:	00001517          	auipc	a0,0x1
ffffffffc020119e:	0ae50513          	addi	a0,a0,174 # ffffffffc0202248 <commands+0x650>
ffffffffc02011a2:	a0aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc02011a6:	00001697          	auipc	a3,0x1
ffffffffc02011aa:	08268693          	addi	a3,a3,130 # ffffffffc0202228 <commands+0x630>
ffffffffc02011ae:	00001617          	auipc	a2,0x1
ffffffffc02011b2:	08260613          	addi	a2,a2,130 # ffffffffc0202230 <commands+0x638>
ffffffffc02011b6:	09d00593          	li	a1,157
ffffffffc02011ba:	00001517          	auipc	a0,0x1
ffffffffc02011be:	08e50513          	addi	a0,a0,142 # ffffffffc0202248 <commands+0x650>
ffffffffc02011c2:	9eaff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02011c6 <best_fit_init_memmap>:
{
ffffffffc02011c6:	1141                	addi	sp,sp,-16
ffffffffc02011c8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02011ca:	c1f5                	beqz	a1,ffffffffc02012ae <best_fit_init_memmap+0xe8>
    for (; p != base + n; p++)
ffffffffc02011cc:	00259693          	slli	a3,a1,0x2
ffffffffc02011d0:	96ae                	add	a3,a3,a1
ffffffffc02011d2:	068e                	slli	a3,a3,0x3
ffffffffc02011d4:	96aa                	add	a3,a3,a0
ffffffffc02011d6:	02d50463          	beq	a0,a3,ffffffffc02011fe <best_fit_init_memmap+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02011da:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc02011dc:	87aa                	mv	a5,a0
ffffffffc02011de:	8b05                	andi	a4,a4,1
ffffffffc02011e0:	e709                	bnez	a4,ffffffffc02011ea <best_fit_init_memmap+0x24>
ffffffffc02011e2:	a07d                	j	ffffffffc0201290 <best_fit_init_memmap+0xca>
ffffffffc02011e4:	6798                	ld	a4,8(a5)
ffffffffc02011e6:	8b05                	andi	a4,a4,1
ffffffffc02011e8:	c745                	beqz	a4,ffffffffc0201290 <best_fit_init_memmap+0xca>
        p->flags = p->property = 0;
ffffffffc02011ea:	0007a823          	sw	zero,16(a5)
ffffffffc02011ee:	0007b423          	sd	zero,8(a5)
ffffffffc02011f2:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02011f6:	02878793          	addi	a5,a5,40
ffffffffc02011fa:	fed795e3          	bne	a5,a3,ffffffffc02011e4 <best_fit_init_memmap+0x1e>
    base->property = n;          // 设置基地址页的属性为总页数
ffffffffc02011fe:	2581                	sext.w	a1,a1
ffffffffc0201200:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201202:	4789                	li	a5,2
ffffffffc0201204:	00850713          	addi	a4,a0,8
ffffffffc0201208:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;                // 增加空闲页数
ffffffffc020120c:	00005697          	auipc	a3,0x5
ffffffffc0201210:	22c68693          	addi	a3,a3,556 # ffffffffc0206438 <free_area>
ffffffffc0201214:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201216:	669c                	ld	a5,8(a3)
ffffffffc0201218:	9db9                	addw	a1,a1,a4
ffffffffc020121a:	00005717          	auipc	a4,0x5
ffffffffc020121e:	22b72723          	sw	a1,558(a4) # ffffffffc0206448 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc0201222:	04d78a63          	beq	a5,a3,ffffffffc0201276 <best_fit_init_memmap+0xb0>
            struct Page *page = le2page(le, page_link);
ffffffffc0201226:	fe878713          	addi	a4,a5,-24
ffffffffc020122a:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list))
ffffffffc020122c:	4801                	li	a6,0
ffffffffc020122e:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc0201232:	00e56a63          	bltu	a0,a4,ffffffffc0201246 <best_fit_init_memmap+0x80>
    return listelm->next;
ffffffffc0201236:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201238:	02d70563          	beq	a4,a3,ffffffffc0201262 <best_fit_init_memmap+0x9c>
        while ((le = list_next(le)) != &free_list)
ffffffffc020123c:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc020123e:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201242:	fee57ae3          	bleu	a4,a0,ffffffffc0201236 <best_fit_init_memmap+0x70>
ffffffffc0201246:	00080663          	beqz	a6,ffffffffc0201252 <best_fit_init_memmap+0x8c>
ffffffffc020124a:	00005717          	auipc	a4,0x5
ffffffffc020124e:	1eb73723          	sd	a1,494(a4) # ffffffffc0206438 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201252:	6398                	ld	a4,0(a5)
}
ffffffffc0201254:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201256:	e390                	sd	a2,0(a5)
ffffffffc0201258:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020125a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020125c:	ed18                	sd	a4,24(a0)
ffffffffc020125e:	0141                	addi	sp,sp,16
ffffffffc0201260:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201262:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201264:	f114                	sd	a3,32(a0)
ffffffffc0201266:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201268:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020126a:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc020126c:	00d70e63          	beq	a4,a3,ffffffffc0201288 <best_fit_init_memmap+0xc2>
ffffffffc0201270:	4805                	li	a6,1
ffffffffc0201272:	87ba                	mv	a5,a4
ffffffffc0201274:	b7e9                	j	ffffffffc020123e <best_fit_init_memmap+0x78>
}
ffffffffc0201276:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201278:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020127c:	e398                	sd	a4,0(a5)
ffffffffc020127e:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201280:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201282:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201284:	0141                	addi	sp,sp,16
ffffffffc0201286:	8082                	ret
ffffffffc0201288:	60a2                	ld	ra,8(sp)
ffffffffc020128a:	e290                	sd	a2,0(a3)
ffffffffc020128c:	0141                	addi	sp,sp,16
ffffffffc020128e:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201290:	00001697          	auipc	a3,0x1
ffffffffc0201294:	2c068693          	addi	a3,a3,704 # ffffffffc0202550 <commands+0x958>
ffffffffc0201298:	00001617          	auipc	a2,0x1
ffffffffc020129c:	f9860613          	addi	a2,a2,-104 # ffffffffc0202230 <commands+0x638>
ffffffffc02012a0:	45e9                	li	a1,26
ffffffffc02012a2:	00001517          	auipc	a0,0x1
ffffffffc02012a6:	fa650513          	addi	a0,a0,-90 # ffffffffc0202248 <commands+0x650>
ffffffffc02012aa:	902ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc02012ae:	00001697          	auipc	a3,0x1
ffffffffc02012b2:	f7a68693          	addi	a3,a3,-134 # ffffffffc0202228 <commands+0x630>
ffffffffc02012b6:	00001617          	auipc	a2,0x1
ffffffffc02012ba:	f7a60613          	addi	a2,a2,-134 # ffffffffc0202230 <commands+0x638>
ffffffffc02012be:	45d9                	li	a1,22
ffffffffc02012c0:	00001517          	auipc	a0,0x1
ffffffffc02012c4:	f8850513          	addi	a0,a0,-120 # ffffffffc0202248 <commands+0x650>
ffffffffc02012c8:	8e4ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02012cc <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02012cc:	100027f3          	csrr	a5,sstatus
ffffffffc02012d0:	8b89                	andi	a5,a5,2
ffffffffc02012d2:	eb89                	bnez	a5,ffffffffc02012e4 <alloc_pages+0x18>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02012d4:	00005797          	auipc	a5,0x5
ffffffffc02012d8:	18478793          	addi	a5,a5,388 # ffffffffc0206458 <pmm_manager>
ffffffffc02012dc:	639c                	ld	a5,0(a5)
ffffffffc02012de:	0187b303          	ld	t1,24(a5)
ffffffffc02012e2:	8302                	jr	t1
struct Page *alloc_pages(size_t n) {
ffffffffc02012e4:	1141                	addi	sp,sp,-16
ffffffffc02012e6:	e406                	sd	ra,8(sp)
ffffffffc02012e8:	e022                	sd	s0,0(sp)
ffffffffc02012ea:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02012ec:	978ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02012f0:	00005797          	auipc	a5,0x5
ffffffffc02012f4:	16878793          	addi	a5,a5,360 # ffffffffc0206458 <pmm_manager>
ffffffffc02012f8:	639c                	ld	a5,0(a5)
ffffffffc02012fa:	8522                	mv	a0,s0
ffffffffc02012fc:	6f9c                	ld	a5,24(a5)
ffffffffc02012fe:	9782                	jalr	a5
ffffffffc0201300:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201302:	95cff0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201306:	8522                	mv	a0,s0
ffffffffc0201308:	60a2                	ld	ra,8(sp)
ffffffffc020130a:	6402                	ld	s0,0(sp)
ffffffffc020130c:	0141                	addi	sp,sp,16
ffffffffc020130e:	8082                	ret

ffffffffc0201310 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201310:	100027f3          	csrr	a5,sstatus
ffffffffc0201314:	8b89                	andi	a5,a5,2
ffffffffc0201316:	eb89                	bnez	a5,ffffffffc0201328 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201318:	00005797          	auipc	a5,0x5
ffffffffc020131c:	14078793          	addi	a5,a5,320 # ffffffffc0206458 <pmm_manager>
ffffffffc0201320:	639c                	ld	a5,0(a5)
ffffffffc0201322:	0207b303          	ld	t1,32(a5)
ffffffffc0201326:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc0201328:	1101                	addi	sp,sp,-32
ffffffffc020132a:	ec06                	sd	ra,24(sp)
ffffffffc020132c:	e822                	sd	s0,16(sp)
ffffffffc020132e:	e426                	sd	s1,8(sp)
ffffffffc0201330:	842a                	mv	s0,a0
ffffffffc0201332:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201334:	930ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201338:	00005797          	auipc	a5,0x5
ffffffffc020133c:	12078793          	addi	a5,a5,288 # ffffffffc0206458 <pmm_manager>
ffffffffc0201340:	639c                	ld	a5,0(a5)
ffffffffc0201342:	85a6                	mv	a1,s1
ffffffffc0201344:	8522                	mv	a0,s0
ffffffffc0201346:	739c                	ld	a5,32(a5)
ffffffffc0201348:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc020134a:	6442                	ld	s0,16(sp)
ffffffffc020134c:	60e2                	ld	ra,24(sp)
ffffffffc020134e:	64a2                	ld	s1,8(sp)
ffffffffc0201350:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201352:	90cff06f          	j	ffffffffc020045e <intr_enable>

ffffffffc0201356 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201356:	100027f3          	csrr	a5,sstatus
ffffffffc020135a:	8b89                	andi	a5,a5,2
ffffffffc020135c:	eb89                	bnez	a5,ffffffffc020136e <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020135e:	00005797          	auipc	a5,0x5
ffffffffc0201362:	0fa78793          	addi	a5,a5,250 # ffffffffc0206458 <pmm_manager>
ffffffffc0201366:	639c                	ld	a5,0(a5)
ffffffffc0201368:	0287b303          	ld	t1,40(a5)
ffffffffc020136c:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc020136e:	1141                	addi	sp,sp,-16
ffffffffc0201370:	e406                	sd	ra,8(sp)
ffffffffc0201372:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201374:	8f0ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201378:	00005797          	auipc	a5,0x5
ffffffffc020137c:	0e078793          	addi	a5,a5,224 # ffffffffc0206458 <pmm_manager>
ffffffffc0201380:	639c                	ld	a5,0(a5)
ffffffffc0201382:	779c                	ld	a5,40(a5)
ffffffffc0201384:	9782                	jalr	a5
ffffffffc0201386:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201388:	8d6ff0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020138c:	8522                	mv	a0,s0
ffffffffc020138e:	60a2                	ld	ra,8(sp)
ffffffffc0201390:	6402                	ld	s0,0(sp)
ffffffffc0201392:	0141                	addi	sp,sp,16
ffffffffc0201394:	8082                	ret

ffffffffc0201396 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201396:	00001797          	auipc	a5,0x1
ffffffffc020139a:	1ca78793          	addi	a5,a5,458 # ffffffffc0202560 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020139e:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02013a0:	1101                	addi	sp,sp,-32
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02013a2:	00001517          	auipc	a0,0x1
ffffffffc02013a6:	20e50513          	addi	a0,a0,526 # ffffffffc02025b0 <best_fit_pmm_manager+0x50>
void pmm_init(void) {
ffffffffc02013aa:	ec06                	sd	ra,24(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02013ac:	00005717          	auipc	a4,0x5
ffffffffc02013b0:	0af73623          	sd	a5,172(a4) # ffffffffc0206458 <pmm_manager>
void pmm_init(void) {
ffffffffc02013b4:	e822                	sd	s0,16(sp)
ffffffffc02013b6:	e426                	sd	s1,8(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02013b8:	00005417          	auipc	s0,0x5
ffffffffc02013bc:	0a040413          	addi	s0,s0,160 # ffffffffc0206458 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02013c0:	cf7fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pmm_manager->init();
ffffffffc02013c4:	601c                	ld	a5,0(s0)
ffffffffc02013c6:	679c                	ld	a5,8(a5)
ffffffffc02013c8:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02013ca:	57f5                	li	a5,-3
ffffffffc02013cc:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02013ce:	00001517          	auipc	a0,0x1
ffffffffc02013d2:	1fa50513          	addi	a0,a0,506 # ffffffffc02025c8 <best_fit_pmm_manager+0x68>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02013d6:	00005717          	auipc	a4,0x5
ffffffffc02013da:	08f73523          	sd	a5,138(a4) # ffffffffc0206460 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc02013de:	cd9fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02013e2:	46c5                	li	a3,17
ffffffffc02013e4:	06ee                	slli	a3,a3,0x1b
ffffffffc02013e6:	40100613          	li	a2,1025
ffffffffc02013ea:	16fd                	addi	a3,a3,-1
ffffffffc02013ec:	0656                	slli	a2,a2,0x15
ffffffffc02013ee:	07e005b7          	lui	a1,0x7e00
ffffffffc02013f2:	00001517          	auipc	a0,0x1
ffffffffc02013f6:	1ee50513          	addi	a0,a0,494 # ffffffffc02025e0 <best_fit_pmm_manager+0x80>
ffffffffc02013fa:	cbdfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02013fe:	777d                	lui	a4,0xfffff
ffffffffc0201400:	00006797          	auipc	a5,0x6
ffffffffc0201404:	06f78793          	addi	a5,a5,111 # ffffffffc020746f <end+0xfff>
ffffffffc0201408:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020140a:	00088737          	lui	a4,0x88
ffffffffc020140e:	00005697          	auipc	a3,0x5
ffffffffc0201412:	00e6b523          	sd	a4,10(a3) # ffffffffc0206418 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201416:	4601                	li	a2,0
ffffffffc0201418:	00005717          	auipc	a4,0x5
ffffffffc020141c:	04f73823          	sd	a5,80(a4) # ffffffffc0206468 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201420:	4681                	li	a3,0
ffffffffc0201422:	00005897          	auipc	a7,0x5
ffffffffc0201426:	ff688893          	addi	a7,a7,-10 # ffffffffc0206418 <npage>
ffffffffc020142a:	00005597          	auipc	a1,0x5
ffffffffc020142e:	03e58593          	addi	a1,a1,62 # ffffffffc0206468 <pages>
ffffffffc0201432:	4805                	li	a6,1
ffffffffc0201434:	fff80537          	lui	a0,0xfff80
ffffffffc0201438:	a011                	j	ffffffffc020143c <pmm_init+0xa6>
ffffffffc020143a:	619c                	ld	a5,0(a1)
        SetPageReserved(pages + i);
ffffffffc020143c:	97b2                	add	a5,a5,a2
ffffffffc020143e:	07a1                	addi	a5,a5,8
ffffffffc0201440:	4107b02f          	amoor.d	zero,a6,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201444:	0008b703          	ld	a4,0(a7)
ffffffffc0201448:	0685                	addi	a3,a3,1
ffffffffc020144a:	02860613          	addi	a2,a2,40
ffffffffc020144e:	00a707b3          	add	a5,a4,a0
ffffffffc0201452:	fef6e4e3          	bltu	a3,a5,ffffffffc020143a <pmm_init+0xa4>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201456:	6190                	ld	a2,0(a1)
ffffffffc0201458:	00271793          	slli	a5,a4,0x2
ffffffffc020145c:	97ba                	add	a5,a5,a4
ffffffffc020145e:	fec006b7          	lui	a3,0xfec00
ffffffffc0201462:	078e                	slli	a5,a5,0x3
ffffffffc0201464:	96b2                	add	a3,a3,a2
ffffffffc0201466:	96be                	add	a3,a3,a5
ffffffffc0201468:	c02007b7          	lui	a5,0xc0200
ffffffffc020146c:	08f6e863          	bltu	a3,a5,ffffffffc02014fc <pmm_init+0x166>
ffffffffc0201470:	00005497          	auipc	s1,0x5
ffffffffc0201474:	ff048493          	addi	s1,s1,-16 # ffffffffc0206460 <va_pa_offset>
ffffffffc0201478:	609c                	ld	a5,0(s1)
    if (freemem < mem_end) {
ffffffffc020147a:	45c5                	li	a1,17
ffffffffc020147c:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020147e:	8e9d                	sub	a3,a3,a5
    if (freemem < mem_end) {
ffffffffc0201480:	04b6e963          	bltu	a3,a1,ffffffffc02014d2 <pmm_init+0x13c>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201484:	601c                	ld	a5,0(s0)
ffffffffc0201486:	7b9c                	ld	a5,48(a5)
ffffffffc0201488:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020148a:	00001517          	auipc	a0,0x1
ffffffffc020148e:	1ee50513          	addi	a0,a0,494 # ffffffffc0202678 <best_fit_pmm_manager+0x118>
ffffffffc0201492:	c25fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201496:	00004697          	auipc	a3,0x4
ffffffffc020149a:	b6a68693          	addi	a3,a3,-1174 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020149e:	00005797          	auipc	a5,0x5
ffffffffc02014a2:	f8d7b123          	sd	a3,-126(a5) # ffffffffc0206420 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02014a6:	c02007b7          	lui	a5,0xc0200
ffffffffc02014aa:	06f6e563          	bltu	a3,a5,ffffffffc0201514 <pmm_init+0x17e>
ffffffffc02014ae:	609c                	ld	a5,0(s1)
}
ffffffffc02014b0:	6442                	ld	s0,16(sp)
ffffffffc02014b2:	60e2                	ld	ra,24(sp)
ffffffffc02014b4:	64a2                	ld	s1,8(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02014b6:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc02014b8:	8e9d                	sub	a3,a3,a5
ffffffffc02014ba:	00005797          	auipc	a5,0x5
ffffffffc02014be:	f8d7bb23          	sd	a3,-106(a5) # ffffffffc0206450 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02014c2:	00001517          	auipc	a0,0x1
ffffffffc02014c6:	1d650513          	addi	a0,a0,470 # ffffffffc0202698 <best_fit_pmm_manager+0x138>
ffffffffc02014ca:	8636                	mv	a2,a3
}
ffffffffc02014cc:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02014ce:	be9fe06f          	j	ffffffffc02000b6 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02014d2:	6785                	lui	a5,0x1
ffffffffc02014d4:	17fd                	addi	a5,a5,-1
ffffffffc02014d6:	96be                	add	a3,a3,a5
ffffffffc02014d8:	77fd                	lui	a5,0xfffff
ffffffffc02014da:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02014dc:	00c6d793          	srli	a5,a3,0xc
ffffffffc02014e0:	04e7f663          	bleu	a4,a5,ffffffffc020152c <pmm_init+0x196>
    pmm_manager->init_memmap(base, n);
ffffffffc02014e4:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02014e6:	97aa                	add	a5,a5,a0
ffffffffc02014e8:	00279513          	slli	a0,a5,0x2
ffffffffc02014ec:	953e                	add	a0,a0,a5
ffffffffc02014ee:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02014f0:	8d95                	sub	a1,a1,a3
ffffffffc02014f2:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02014f4:	81b1                	srli	a1,a1,0xc
ffffffffc02014f6:	9532                	add	a0,a0,a2
ffffffffc02014f8:	9782                	jalr	a5
ffffffffc02014fa:	b769                	j	ffffffffc0201484 <pmm_init+0xee>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02014fc:	00001617          	auipc	a2,0x1
ffffffffc0201500:	11460613          	addi	a2,a2,276 # ffffffffc0202610 <best_fit_pmm_manager+0xb0>
ffffffffc0201504:	07200593          	li	a1,114
ffffffffc0201508:	00001517          	auipc	a0,0x1
ffffffffc020150c:	13050513          	addi	a0,a0,304 # ffffffffc0202638 <best_fit_pmm_manager+0xd8>
ffffffffc0201510:	e9dfe0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201514:	00001617          	auipc	a2,0x1
ffffffffc0201518:	0fc60613          	addi	a2,a2,252 # ffffffffc0202610 <best_fit_pmm_manager+0xb0>
ffffffffc020151c:	08d00593          	li	a1,141
ffffffffc0201520:	00001517          	auipc	a0,0x1
ffffffffc0201524:	11850513          	addi	a0,a0,280 # ffffffffc0202638 <best_fit_pmm_manager+0xd8>
ffffffffc0201528:	e85fe0ef          	jal	ra,ffffffffc02003ac <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020152c:	00001617          	auipc	a2,0x1
ffffffffc0201530:	11c60613          	addi	a2,a2,284 # ffffffffc0202648 <best_fit_pmm_manager+0xe8>
ffffffffc0201534:	06400593          	li	a1,100
ffffffffc0201538:	00001517          	auipc	a0,0x1
ffffffffc020153c:	13050513          	addi	a0,a0,304 # ffffffffc0202668 <best_fit_pmm_manager+0x108>
ffffffffc0201540:	e6dfe0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201544 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201544:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201548:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020154a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020154e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201550:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201554:	f022                	sd	s0,32(sp)
ffffffffc0201556:	ec26                	sd	s1,24(sp)
ffffffffc0201558:	e84a                	sd	s2,16(sp)
ffffffffc020155a:	f406                	sd	ra,40(sp)
ffffffffc020155c:	e44e                	sd	s3,8(sp)
ffffffffc020155e:	84aa                	mv	s1,a0
ffffffffc0201560:	892e                	mv	s2,a1
ffffffffc0201562:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201566:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0201568:	03067e63          	bleu	a6,a2,ffffffffc02015a4 <printnum+0x60>
ffffffffc020156c:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020156e:	00805763          	blez	s0,ffffffffc020157c <printnum+0x38>
ffffffffc0201572:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201574:	85ca                	mv	a1,s2
ffffffffc0201576:	854e                	mv	a0,s3
ffffffffc0201578:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020157a:	fc65                	bnez	s0,ffffffffc0201572 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020157c:	1a02                	slli	s4,s4,0x20
ffffffffc020157e:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201582:	00001797          	auipc	a5,0x1
ffffffffc0201586:	2e678793          	addi	a5,a5,742 # ffffffffc0202868 <error_string+0x38>
ffffffffc020158a:	9a3e                	add	s4,s4,a5
}
ffffffffc020158c:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020158e:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201592:	70a2                	ld	ra,40(sp)
ffffffffc0201594:	69a2                	ld	s3,8(sp)
ffffffffc0201596:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201598:	85ca                	mv	a1,s2
ffffffffc020159a:	8326                	mv	t1,s1
}
ffffffffc020159c:	6942                	ld	s2,16(sp)
ffffffffc020159e:	64e2                	ld	s1,24(sp)
ffffffffc02015a0:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02015a2:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02015a4:	03065633          	divu	a2,a2,a6
ffffffffc02015a8:	8722                	mv	a4,s0
ffffffffc02015aa:	f9bff0ef          	jal	ra,ffffffffc0201544 <printnum>
ffffffffc02015ae:	b7f9                	j	ffffffffc020157c <printnum+0x38>

ffffffffc02015b0 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02015b0:	7119                	addi	sp,sp,-128
ffffffffc02015b2:	f4a6                	sd	s1,104(sp)
ffffffffc02015b4:	f0ca                	sd	s2,96(sp)
ffffffffc02015b6:	e8d2                	sd	s4,80(sp)
ffffffffc02015b8:	e4d6                	sd	s5,72(sp)
ffffffffc02015ba:	e0da                	sd	s6,64(sp)
ffffffffc02015bc:	fc5e                	sd	s7,56(sp)
ffffffffc02015be:	f862                	sd	s8,48(sp)
ffffffffc02015c0:	f06a                	sd	s10,32(sp)
ffffffffc02015c2:	fc86                	sd	ra,120(sp)
ffffffffc02015c4:	f8a2                	sd	s0,112(sp)
ffffffffc02015c6:	ecce                	sd	s3,88(sp)
ffffffffc02015c8:	f466                	sd	s9,40(sp)
ffffffffc02015ca:	ec6e                	sd	s11,24(sp)
ffffffffc02015cc:	892a                	mv	s2,a0
ffffffffc02015ce:	84ae                	mv	s1,a1
ffffffffc02015d0:	8d32                	mv	s10,a2
ffffffffc02015d2:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02015d4:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015d6:	00001a17          	auipc	s4,0x1
ffffffffc02015da:	102a0a13          	addi	s4,s4,258 # ffffffffc02026d8 <best_fit_pmm_manager+0x178>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02015de:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02015e2:	00001c17          	auipc	s8,0x1
ffffffffc02015e6:	24ec0c13          	addi	s8,s8,590 # ffffffffc0202830 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015ea:	000d4503          	lbu	a0,0(s10)
ffffffffc02015ee:	02500793          	li	a5,37
ffffffffc02015f2:	001d0413          	addi	s0,s10,1
ffffffffc02015f6:	00f50e63          	beq	a0,a5,ffffffffc0201612 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc02015fa:	c521                	beqz	a0,ffffffffc0201642 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015fc:	02500993          	li	s3,37
ffffffffc0201600:	a011                	j	ffffffffc0201604 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0201602:	c121                	beqz	a0,ffffffffc0201642 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0201604:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201606:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201608:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020160a:	fff44503          	lbu	a0,-1(s0)
ffffffffc020160e:	ff351ae3          	bne	a0,s3,ffffffffc0201602 <vprintfmt+0x52>
ffffffffc0201612:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201616:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020161a:	4981                	li	s3,0
ffffffffc020161c:	4801                	li	a6,0
        width = precision = -1;
ffffffffc020161e:	5cfd                	li	s9,-1
ffffffffc0201620:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201622:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0201626:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201628:	fdd6069b          	addiw	a3,a2,-35
ffffffffc020162c:	0ff6f693          	andi	a3,a3,255
ffffffffc0201630:	00140d13          	addi	s10,s0,1
ffffffffc0201634:	20d5e563          	bltu	a1,a3,ffffffffc020183e <vprintfmt+0x28e>
ffffffffc0201638:	068a                	slli	a3,a3,0x2
ffffffffc020163a:	96d2                	add	a3,a3,s4
ffffffffc020163c:	4294                	lw	a3,0(a3)
ffffffffc020163e:	96d2                	add	a3,a3,s4
ffffffffc0201640:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201642:	70e6                	ld	ra,120(sp)
ffffffffc0201644:	7446                	ld	s0,112(sp)
ffffffffc0201646:	74a6                	ld	s1,104(sp)
ffffffffc0201648:	7906                	ld	s2,96(sp)
ffffffffc020164a:	69e6                	ld	s3,88(sp)
ffffffffc020164c:	6a46                	ld	s4,80(sp)
ffffffffc020164e:	6aa6                	ld	s5,72(sp)
ffffffffc0201650:	6b06                	ld	s6,64(sp)
ffffffffc0201652:	7be2                	ld	s7,56(sp)
ffffffffc0201654:	7c42                	ld	s8,48(sp)
ffffffffc0201656:	7ca2                	ld	s9,40(sp)
ffffffffc0201658:	7d02                	ld	s10,32(sp)
ffffffffc020165a:	6de2                	ld	s11,24(sp)
ffffffffc020165c:	6109                	addi	sp,sp,128
ffffffffc020165e:	8082                	ret
    if (lflag >= 2) {
ffffffffc0201660:	4705                	li	a4,1
ffffffffc0201662:	008a8593          	addi	a1,s5,8
ffffffffc0201666:	01074463          	blt	a4,a6,ffffffffc020166e <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc020166a:	26080363          	beqz	a6,ffffffffc02018d0 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc020166e:	000ab603          	ld	a2,0(s5)
ffffffffc0201672:	46c1                	li	a3,16
ffffffffc0201674:	8aae                	mv	s5,a1
ffffffffc0201676:	a06d                	j	ffffffffc0201720 <vprintfmt+0x170>
            goto reswitch;
ffffffffc0201678:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020167c:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020167e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201680:	b765                	j	ffffffffc0201628 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0201682:	000aa503          	lw	a0,0(s5)
ffffffffc0201686:	85a6                	mv	a1,s1
ffffffffc0201688:	0aa1                	addi	s5,s5,8
ffffffffc020168a:	9902                	jalr	s2
            break;
ffffffffc020168c:	bfb9                	j	ffffffffc02015ea <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020168e:	4705                	li	a4,1
ffffffffc0201690:	008a8993          	addi	s3,s5,8
ffffffffc0201694:	01074463          	blt	a4,a6,ffffffffc020169c <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0201698:	22080463          	beqz	a6,ffffffffc02018c0 <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc020169c:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc02016a0:	24044463          	bltz	s0,ffffffffc02018e8 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc02016a4:	8622                	mv	a2,s0
ffffffffc02016a6:	8ace                	mv	s5,s3
ffffffffc02016a8:	46a9                	li	a3,10
ffffffffc02016aa:	a89d                	j	ffffffffc0201720 <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc02016ac:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02016b0:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02016b2:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc02016b4:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02016b8:	8fb5                	xor	a5,a5,a3
ffffffffc02016ba:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02016be:	1ad74363          	blt	a4,a3,ffffffffc0201864 <vprintfmt+0x2b4>
ffffffffc02016c2:	00369793          	slli	a5,a3,0x3
ffffffffc02016c6:	97e2                	add	a5,a5,s8
ffffffffc02016c8:	639c                	ld	a5,0(a5)
ffffffffc02016ca:	18078d63          	beqz	a5,ffffffffc0201864 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc02016ce:	86be                	mv	a3,a5
ffffffffc02016d0:	00001617          	auipc	a2,0x1
ffffffffc02016d4:	24860613          	addi	a2,a2,584 # ffffffffc0202918 <error_string+0xe8>
ffffffffc02016d8:	85a6                	mv	a1,s1
ffffffffc02016da:	854a                	mv	a0,s2
ffffffffc02016dc:	240000ef          	jal	ra,ffffffffc020191c <printfmt>
ffffffffc02016e0:	b729                	j	ffffffffc02015ea <vprintfmt+0x3a>
            lflag ++;
ffffffffc02016e2:	00144603          	lbu	a2,1(s0)
ffffffffc02016e6:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016e8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02016ea:	bf3d                	j	ffffffffc0201628 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc02016ec:	4705                	li	a4,1
ffffffffc02016ee:	008a8593          	addi	a1,s5,8
ffffffffc02016f2:	01074463          	blt	a4,a6,ffffffffc02016fa <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02016f6:	1e080263          	beqz	a6,ffffffffc02018da <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc02016fa:	000ab603          	ld	a2,0(s5)
ffffffffc02016fe:	46a1                	li	a3,8
ffffffffc0201700:	8aae                	mv	s5,a1
ffffffffc0201702:	a839                	j	ffffffffc0201720 <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc0201704:	03000513          	li	a0,48
ffffffffc0201708:	85a6                	mv	a1,s1
ffffffffc020170a:	e03e                	sd	a5,0(sp)
ffffffffc020170c:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020170e:	85a6                	mv	a1,s1
ffffffffc0201710:	07800513          	li	a0,120
ffffffffc0201714:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201716:	0aa1                	addi	s5,s5,8
ffffffffc0201718:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc020171c:	6782                	ld	a5,0(sp)
ffffffffc020171e:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201720:	876e                	mv	a4,s11
ffffffffc0201722:	85a6                	mv	a1,s1
ffffffffc0201724:	854a                	mv	a0,s2
ffffffffc0201726:	e1fff0ef          	jal	ra,ffffffffc0201544 <printnum>
            break;
ffffffffc020172a:	b5c1                	j	ffffffffc02015ea <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020172c:	000ab603          	ld	a2,0(s5)
ffffffffc0201730:	0aa1                	addi	s5,s5,8
ffffffffc0201732:	1c060663          	beqz	a2,ffffffffc02018fe <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0201736:	00160413          	addi	s0,a2,1
ffffffffc020173a:	17b05c63          	blez	s11,ffffffffc02018b2 <vprintfmt+0x302>
ffffffffc020173e:	02d00593          	li	a1,45
ffffffffc0201742:	14b79263          	bne	a5,a1,ffffffffc0201886 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201746:	00064783          	lbu	a5,0(a2)
ffffffffc020174a:	0007851b          	sext.w	a0,a5
ffffffffc020174e:	c905                	beqz	a0,ffffffffc020177e <vprintfmt+0x1ce>
ffffffffc0201750:	000cc563          	bltz	s9,ffffffffc020175a <vprintfmt+0x1aa>
ffffffffc0201754:	3cfd                	addiw	s9,s9,-1
ffffffffc0201756:	036c8263          	beq	s9,s6,ffffffffc020177a <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc020175a:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020175c:	18098463          	beqz	s3,ffffffffc02018e4 <vprintfmt+0x334>
ffffffffc0201760:	3781                	addiw	a5,a5,-32
ffffffffc0201762:	18fbf163          	bleu	a5,s7,ffffffffc02018e4 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0201766:	03f00513          	li	a0,63
ffffffffc020176a:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020176c:	0405                	addi	s0,s0,1
ffffffffc020176e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201772:	3dfd                	addiw	s11,s11,-1
ffffffffc0201774:	0007851b          	sext.w	a0,a5
ffffffffc0201778:	fd61                	bnez	a0,ffffffffc0201750 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc020177a:	e7b058e3          	blez	s11,ffffffffc02015ea <vprintfmt+0x3a>
ffffffffc020177e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201780:	85a6                	mv	a1,s1
ffffffffc0201782:	02000513          	li	a0,32
ffffffffc0201786:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201788:	e60d81e3          	beqz	s11,ffffffffc02015ea <vprintfmt+0x3a>
ffffffffc020178c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020178e:	85a6                	mv	a1,s1
ffffffffc0201790:	02000513          	li	a0,32
ffffffffc0201794:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201796:	fe0d94e3          	bnez	s11,ffffffffc020177e <vprintfmt+0x1ce>
ffffffffc020179a:	bd81                	j	ffffffffc02015ea <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020179c:	4705                	li	a4,1
ffffffffc020179e:	008a8593          	addi	a1,s5,8
ffffffffc02017a2:	01074463          	blt	a4,a6,ffffffffc02017aa <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc02017a6:	12080063          	beqz	a6,ffffffffc02018c6 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc02017aa:	000ab603          	ld	a2,0(s5)
ffffffffc02017ae:	46a9                	li	a3,10
ffffffffc02017b0:	8aae                	mv	s5,a1
ffffffffc02017b2:	b7bd                	j	ffffffffc0201720 <vprintfmt+0x170>
ffffffffc02017b4:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc02017b8:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017bc:	846a                	mv	s0,s10
ffffffffc02017be:	b5ad                	j	ffffffffc0201628 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc02017c0:	85a6                	mv	a1,s1
ffffffffc02017c2:	02500513          	li	a0,37
ffffffffc02017c6:	9902                	jalr	s2
            break;
ffffffffc02017c8:	b50d                	j	ffffffffc02015ea <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc02017ca:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc02017ce:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02017d2:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017d4:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc02017d6:	e40dd9e3          	bgez	s11,ffffffffc0201628 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc02017da:	8de6                	mv	s11,s9
ffffffffc02017dc:	5cfd                	li	s9,-1
ffffffffc02017de:	b5a9                	j	ffffffffc0201628 <vprintfmt+0x78>
            goto reswitch;
ffffffffc02017e0:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc02017e4:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017e8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02017ea:	bd3d                	j	ffffffffc0201628 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc02017ec:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc02017f0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017f4:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02017f6:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02017fa:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02017fe:	fcd56ce3          	bltu	a0,a3,ffffffffc02017d6 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc0201802:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201804:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0201808:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020180c:	0196873b          	addw	a4,a3,s9
ffffffffc0201810:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201814:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0201818:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc020181c:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201820:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201824:	fcd57fe3          	bleu	a3,a0,ffffffffc0201802 <vprintfmt+0x252>
ffffffffc0201828:	b77d                	j	ffffffffc02017d6 <vprintfmt+0x226>
            if (width < 0)
ffffffffc020182a:	fffdc693          	not	a3,s11
ffffffffc020182e:	96fd                	srai	a3,a3,0x3f
ffffffffc0201830:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201834:	00144603          	lbu	a2,1(s0)
ffffffffc0201838:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020183a:	846a                	mv	s0,s10
ffffffffc020183c:	b3f5                	j	ffffffffc0201628 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc020183e:	85a6                	mv	a1,s1
ffffffffc0201840:	02500513          	li	a0,37
ffffffffc0201844:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201846:	fff44703          	lbu	a4,-1(s0)
ffffffffc020184a:	02500793          	li	a5,37
ffffffffc020184e:	8d22                	mv	s10,s0
ffffffffc0201850:	d8f70de3          	beq	a4,a5,ffffffffc02015ea <vprintfmt+0x3a>
ffffffffc0201854:	02500713          	li	a4,37
ffffffffc0201858:	1d7d                	addi	s10,s10,-1
ffffffffc020185a:	fffd4783          	lbu	a5,-1(s10)
ffffffffc020185e:	fee79de3          	bne	a5,a4,ffffffffc0201858 <vprintfmt+0x2a8>
ffffffffc0201862:	b361                	j	ffffffffc02015ea <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201864:	00001617          	auipc	a2,0x1
ffffffffc0201868:	0a460613          	addi	a2,a2,164 # ffffffffc0202908 <error_string+0xd8>
ffffffffc020186c:	85a6                	mv	a1,s1
ffffffffc020186e:	854a                	mv	a0,s2
ffffffffc0201870:	0ac000ef          	jal	ra,ffffffffc020191c <printfmt>
ffffffffc0201874:	bb9d                	j	ffffffffc02015ea <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201876:	00001617          	auipc	a2,0x1
ffffffffc020187a:	08a60613          	addi	a2,a2,138 # ffffffffc0202900 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc020187e:	00001417          	auipc	s0,0x1
ffffffffc0201882:	08340413          	addi	s0,s0,131 # ffffffffc0202901 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201886:	8532                	mv	a0,a2
ffffffffc0201888:	85e6                	mv	a1,s9
ffffffffc020188a:	e032                	sd	a2,0(sp)
ffffffffc020188c:	e43e                	sd	a5,8(sp)
ffffffffc020188e:	1c4000ef          	jal	ra,ffffffffc0201a52 <strnlen>
ffffffffc0201892:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201896:	6602                	ld	a2,0(sp)
ffffffffc0201898:	01b05d63          	blez	s11,ffffffffc02018b2 <vprintfmt+0x302>
ffffffffc020189c:	67a2                	ld	a5,8(sp)
ffffffffc020189e:	2781                	sext.w	a5,a5
ffffffffc02018a0:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc02018a2:	6522                	ld	a0,8(sp)
ffffffffc02018a4:	85a6                	mv	a1,s1
ffffffffc02018a6:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02018a8:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02018aa:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02018ac:	6602                	ld	a2,0(sp)
ffffffffc02018ae:	fe0d9ae3          	bnez	s11,ffffffffc02018a2 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02018b2:	00064783          	lbu	a5,0(a2)
ffffffffc02018b6:	0007851b          	sext.w	a0,a5
ffffffffc02018ba:	e8051be3          	bnez	a0,ffffffffc0201750 <vprintfmt+0x1a0>
ffffffffc02018be:	b335                	j	ffffffffc02015ea <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc02018c0:	000aa403          	lw	s0,0(s5)
ffffffffc02018c4:	bbf1                	j	ffffffffc02016a0 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc02018c6:	000ae603          	lwu	a2,0(s5)
ffffffffc02018ca:	46a9                	li	a3,10
ffffffffc02018cc:	8aae                	mv	s5,a1
ffffffffc02018ce:	bd89                	j	ffffffffc0201720 <vprintfmt+0x170>
ffffffffc02018d0:	000ae603          	lwu	a2,0(s5)
ffffffffc02018d4:	46c1                	li	a3,16
ffffffffc02018d6:	8aae                	mv	s5,a1
ffffffffc02018d8:	b5a1                	j	ffffffffc0201720 <vprintfmt+0x170>
ffffffffc02018da:	000ae603          	lwu	a2,0(s5)
ffffffffc02018de:	46a1                	li	a3,8
ffffffffc02018e0:	8aae                	mv	s5,a1
ffffffffc02018e2:	bd3d                	j	ffffffffc0201720 <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc02018e4:	9902                	jalr	s2
ffffffffc02018e6:	b559                	j	ffffffffc020176c <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc02018e8:	85a6                	mv	a1,s1
ffffffffc02018ea:	02d00513          	li	a0,45
ffffffffc02018ee:	e03e                	sd	a5,0(sp)
ffffffffc02018f0:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02018f2:	8ace                	mv	s5,s3
ffffffffc02018f4:	40800633          	neg	a2,s0
ffffffffc02018f8:	46a9                	li	a3,10
ffffffffc02018fa:	6782                	ld	a5,0(sp)
ffffffffc02018fc:	b515                	j	ffffffffc0201720 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc02018fe:	01b05663          	blez	s11,ffffffffc020190a <vprintfmt+0x35a>
ffffffffc0201902:	02d00693          	li	a3,45
ffffffffc0201906:	f6d798e3          	bne	a5,a3,ffffffffc0201876 <vprintfmt+0x2c6>
ffffffffc020190a:	00001417          	auipc	s0,0x1
ffffffffc020190e:	ff740413          	addi	s0,s0,-9 # ffffffffc0202901 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201912:	02800513          	li	a0,40
ffffffffc0201916:	02800793          	li	a5,40
ffffffffc020191a:	bd1d                	j	ffffffffc0201750 <vprintfmt+0x1a0>

ffffffffc020191c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020191c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020191e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201922:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201924:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201926:	ec06                	sd	ra,24(sp)
ffffffffc0201928:	f83a                	sd	a4,48(sp)
ffffffffc020192a:	fc3e                	sd	a5,56(sp)
ffffffffc020192c:	e0c2                	sd	a6,64(sp)
ffffffffc020192e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201930:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201932:	c7fff0ef          	jal	ra,ffffffffc02015b0 <vprintfmt>
}
ffffffffc0201936:	60e2                	ld	ra,24(sp)
ffffffffc0201938:	6161                	addi	sp,sp,80
ffffffffc020193a:	8082                	ret

ffffffffc020193c <readline>:
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt)
{
ffffffffc020193c:	715d                	addi	sp,sp,-80
ffffffffc020193e:	e486                	sd	ra,72(sp)
ffffffffc0201940:	e0a2                	sd	s0,64(sp)
ffffffffc0201942:	fc26                	sd	s1,56(sp)
ffffffffc0201944:	f84a                	sd	s2,48(sp)
ffffffffc0201946:	f44e                	sd	s3,40(sp)
ffffffffc0201948:	f052                	sd	s4,32(sp)
ffffffffc020194a:	ec56                	sd	s5,24(sp)
ffffffffc020194c:	e85a                	sd	s6,16(sp)
ffffffffc020194e:	e45e                	sd	s7,8(sp)
    if (prompt != NULL)
ffffffffc0201950:	c901                	beqz	a0,ffffffffc0201960 <readline+0x24>
    {
        cprintf("%s", prompt);
ffffffffc0201952:	85aa                	mv	a1,a0
ffffffffc0201954:	00001517          	auipc	a0,0x1
ffffffffc0201958:	fc450513          	addi	a0,a0,-60 # ffffffffc0202918 <error_string+0xe8>
ffffffffc020195c:	f5afe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1)
        {
            cputchar(c);
            buf[i++] = c;
ffffffffc0201960:	4481                	li	s1,0
ffffffffc0201962:	00004a97          	auipc	s5,0x4
ffffffffc0201966:	6aea8a93          	addi	s5,s5,1710 # ffffffffc0206010 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1)
ffffffffc020196a:	497d                	li	s2,31
        }
        else if (c == '\b' && i > 0)
ffffffffc020196c:	49a1                	li	s3,8
        {
            cputchar(c);
            i--;
        }
        else if (c == '\n' || c == '\r')
ffffffffc020196e:	4b29                	li	s6,10
ffffffffc0201970:	4bb5                	li	s7,13
        else if (c >= ' ' && i < BUFSIZE - 1)
ffffffffc0201972:	3fe00a13          	li	s4,1022
        while ((c = getchar()) < 0)
ffffffffc0201976:	fb8fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc020197a:	842a                	mv	s0,a0
ffffffffc020197c:	fe054de3          	bltz	a0,ffffffffc0201976 <readline+0x3a>
        else if (c >= ' ' && i < BUFSIZE - 1)
ffffffffc0201980:	00a95d63          	ble	a0,s2,ffffffffc020199a <readline+0x5e>
ffffffffc0201984:	fe9a49e3          	blt	s4,s1,ffffffffc0201976 <readline+0x3a>
            cputchar(c);
ffffffffc0201988:	8522                	mv	a0,s0
ffffffffc020198a:	f60fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i++] = c;
ffffffffc020198e:	009a87b3          	add	a5,s5,s1
ffffffffc0201992:	00878023          	sb	s0,0(a5)
ffffffffc0201996:	2485                	addiw	s1,s1,1
ffffffffc0201998:	bff9                	j	ffffffffc0201976 <readline+0x3a>
        else if (c == '\b' && i > 0)
ffffffffc020199a:	03341363          	bne	s0,s3,ffffffffc02019c0 <readline+0x84>
ffffffffc020199e:	e8b1                	bnez	s1,ffffffffc02019f2 <readline+0xb6>
        while ((c = getchar()) < 0)
ffffffffc02019a0:	f8efe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc02019a4:	842a                	mv	s0,a0
ffffffffc02019a6:	fc0548e3          	bltz	a0,ffffffffc0201976 <readline+0x3a>
        else if (c >= ' ' && i < BUFSIZE - 1)
ffffffffc02019aa:	fea958e3          	ble	a0,s2,ffffffffc020199a <readline+0x5e>
            cputchar(c);
ffffffffc02019ae:	8522                	mv	a0,s0
ffffffffc02019b0:	f3afe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i++] = c;
ffffffffc02019b4:	009a87b3          	add	a5,s5,s1
ffffffffc02019b8:	00878023          	sb	s0,0(a5)
ffffffffc02019bc:	2485                	addiw	s1,s1,1
ffffffffc02019be:	bf65                	j	ffffffffc0201976 <readline+0x3a>
        else if (c == '\n' || c == '\r')
ffffffffc02019c0:	01640463          	beq	s0,s6,ffffffffc02019c8 <readline+0x8c>
ffffffffc02019c4:	fb7419e3          	bne	s0,s7,ffffffffc0201976 <readline+0x3a>
        {
            cputchar(c);
ffffffffc02019c8:	8522                	mv	a0,s0
            buf[i] = '\0';
ffffffffc02019ca:	94d6                	add	s1,s1,s5
            cputchar(c);
ffffffffc02019cc:	f1efe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i] = '\0';
ffffffffc02019d0:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02019d4:	60a6                	ld	ra,72(sp)
ffffffffc02019d6:	6406                	ld	s0,64(sp)
ffffffffc02019d8:	74e2                	ld	s1,56(sp)
ffffffffc02019da:	7942                	ld	s2,48(sp)
ffffffffc02019dc:	79a2                	ld	s3,40(sp)
ffffffffc02019de:	7a02                	ld	s4,32(sp)
ffffffffc02019e0:	6ae2                	ld	s5,24(sp)
ffffffffc02019e2:	6b42                	ld	s6,16(sp)
ffffffffc02019e4:	6ba2                	ld	s7,8(sp)
ffffffffc02019e6:	00004517          	auipc	a0,0x4
ffffffffc02019ea:	62a50513          	addi	a0,a0,1578 # ffffffffc0206010 <edata>
ffffffffc02019ee:	6161                	addi	sp,sp,80
ffffffffc02019f0:	8082                	ret
            cputchar(c);
ffffffffc02019f2:	4521                	li	a0,8
ffffffffc02019f4:	ef6fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            i--;
ffffffffc02019f8:	34fd                	addiw	s1,s1,-1
ffffffffc02019fa:	bfb5                	j	ffffffffc0201976 <readline+0x3a>

ffffffffc02019fc <sbi_console_putchar>:
    );
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc02019fc:	00004797          	auipc	a5,0x4
ffffffffc0201a00:	60c78793          	addi	a5,a5,1548 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile (
ffffffffc0201a04:	6398                	ld	a4,0(a5)
ffffffffc0201a06:	4781                	li	a5,0
ffffffffc0201a08:	88ba                	mv	a7,a4
ffffffffc0201a0a:	852a                	mv	a0,a0
ffffffffc0201a0c:	85be                	mv	a1,a5
ffffffffc0201a0e:	863e                	mv	a2,a5
ffffffffc0201a10:	00000073          	ecall
ffffffffc0201a14:	87aa                	mv	a5,a0
}
ffffffffc0201a16:	8082                	ret

ffffffffc0201a18 <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc0201a18:	00005797          	auipc	a5,0x5
ffffffffc0201a1c:	a1078793          	addi	a5,a5,-1520 # ffffffffc0206428 <SBI_SET_TIMER>
    __asm__ volatile (
ffffffffc0201a20:	6398                	ld	a4,0(a5)
ffffffffc0201a22:	4781                	li	a5,0
ffffffffc0201a24:	88ba                	mv	a7,a4
ffffffffc0201a26:	852a                	mv	a0,a0
ffffffffc0201a28:	85be                	mv	a1,a5
ffffffffc0201a2a:	863e                	mv	a2,a5
ffffffffc0201a2c:	00000073          	ecall
ffffffffc0201a30:	87aa                	mv	a5,a0
}
ffffffffc0201a32:	8082                	ret

ffffffffc0201a34 <sbi_console_getchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201a34:	00004797          	auipc	a5,0x4
ffffffffc0201a38:	5cc78793          	addi	a5,a5,1484 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile (
ffffffffc0201a3c:	639c                	ld	a5,0(a5)
ffffffffc0201a3e:	4501                	li	a0,0
ffffffffc0201a40:	88be                	mv	a7,a5
ffffffffc0201a42:	852a                	mv	a0,a0
ffffffffc0201a44:	85aa                	mv	a1,a0
ffffffffc0201a46:	862a                	mv	a2,a0
ffffffffc0201a48:	00000073          	ecall
ffffffffc0201a4c:	852a                	mv	a0,a0
ffffffffc0201a4e:	2501                	sext.w	a0,a0
ffffffffc0201a50:	8082                	ret

ffffffffc0201a52 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a52:	c185                	beqz	a1,ffffffffc0201a72 <strnlen+0x20>
ffffffffc0201a54:	00054783          	lbu	a5,0(a0)
ffffffffc0201a58:	cf89                	beqz	a5,ffffffffc0201a72 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0201a5a:	4781                	li	a5,0
ffffffffc0201a5c:	a021                	j	ffffffffc0201a64 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a5e:	00074703          	lbu	a4,0(a4)
ffffffffc0201a62:	c711                	beqz	a4,ffffffffc0201a6e <strnlen+0x1c>
        cnt ++;
ffffffffc0201a64:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a66:	00f50733          	add	a4,a0,a5
ffffffffc0201a6a:	fef59ae3          	bne	a1,a5,ffffffffc0201a5e <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0201a6e:	853e                	mv	a0,a5
ffffffffc0201a70:	8082                	ret
    size_t cnt = 0;
ffffffffc0201a72:	4781                	li	a5,0
}
ffffffffc0201a74:	853e                	mv	a0,a5
ffffffffc0201a76:	8082                	ret

ffffffffc0201a78 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a78:	00054783          	lbu	a5,0(a0)
ffffffffc0201a7c:	0005c703          	lbu	a4,0(a1)
ffffffffc0201a80:	cb91                	beqz	a5,ffffffffc0201a94 <strcmp+0x1c>
ffffffffc0201a82:	00e79c63          	bne	a5,a4,ffffffffc0201a9a <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0201a86:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a88:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0201a8c:	0585                	addi	a1,a1,1
ffffffffc0201a8e:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a92:	fbe5                	bnez	a5,ffffffffc0201a82 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a94:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201a96:	9d19                	subw	a0,a0,a4
ffffffffc0201a98:	8082                	ret
ffffffffc0201a9a:	0007851b          	sext.w	a0,a5
ffffffffc0201a9e:	9d19                	subw	a0,a0,a4
ffffffffc0201aa0:	8082                	ret

ffffffffc0201aa2 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201aa2:	00054783          	lbu	a5,0(a0)
ffffffffc0201aa6:	cb91                	beqz	a5,ffffffffc0201aba <strchr+0x18>
        if (*s == c) {
ffffffffc0201aa8:	00b79563          	bne	a5,a1,ffffffffc0201ab2 <strchr+0x10>
ffffffffc0201aac:	a809                	j	ffffffffc0201abe <strchr+0x1c>
ffffffffc0201aae:	00b78763          	beq	a5,a1,ffffffffc0201abc <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0201ab2:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201ab4:	00054783          	lbu	a5,0(a0)
ffffffffc0201ab8:	fbfd                	bnez	a5,ffffffffc0201aae <strchr+0xc>
    }
    return NULL;
ffffffffc0201aba:	4501                	li	a0,0
}
ffffffffc0201abc:	8082                	ret
ffffffffc0201abe:	8082                	ret

ffffffffc0201ac0 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201ac0:	ca01                	beqz	a2,ffffffffc0201ad0 <memset+0x10>
ffffffffc0201ac2:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201ac4:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201ac6:	0785                	addi	a5,a5,1
ffffffffc0201ac8:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201acc:	fec79de3          	bne	a5,a2,ffffffffc0201ac6 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201ad0:	8082                	ret
