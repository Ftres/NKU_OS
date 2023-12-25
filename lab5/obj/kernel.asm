
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020b2b7          	lui	t0,0xc020b
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
ffffffffc0200028:	c020b137          	lui	sp,0xc020b

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

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	000a1517          	auipc	a0,0xa1
ffffffffc020003a:	04250513          	addi	a0,a0,66 # ffffffffc02a1078 <edata>
ffffffffc020003e:	000ac617          	auipc	a2,0xac
ffffffffc0200042:	5c260613          	addi	a2,a2,1474 # ffffffffc02ac600 <end>
kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	57a060ef          	jal	ra,ffffffffc02065c8 <memset>
    cons_init();                // init the console
ffffffffc0200052:	536000ef          	jal	ra,ffffffffc0200588 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200056:	00006597          	auipc	a1,0x6
ffffffffc020005a:	5a258593          	addi	a1,a1,1442 # ffffffffc02065f8 <etext+0x6>
ffffffffc020005e:	00006517          	auipc	a0,0x6
ffffffffc0200062:	5ba50513          	addi	a0,a0,1466 # ffffffffc0206618 <etext+0x26>
ffffffffc0200066:	128000ef          	jal	ra,ffffffffc020018e <cprintf>

    print_kerninfo();
ffffffffc020006a:	1ac000ef          	jal	ra,ffffffffc0200216 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006e:	5be020ef          	jal	ra,ffffffffc020262c <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc0200072:	5ee000ef          	jal	ra,ffffffffc0200660 <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200076:	5ec000ef          	jal	ra,ffffffffc0200662 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc020007a:	3e0040ef          	jal	ra,ffffffffc020445a <vmm_init>
    proc_init();                // init process table
ffffffffc020007e:	4db050ef          	jal	ra,ffffffffc0205d58 <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc0200082:	57a000ef          	jal	ra,ffffffffc02005fc <ide_init>
    swap_init();                // init swap
ffffffffc0200086:	2fe030ef          	jal	ra,ffffffffc0203384 <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020008a:	4a8000ef          	jal	ra,ffffffffc0200532 <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008e:	5c6000ef          	jal	ra,ffffffffc0200654 <intr_enable>
    
    cpu_idle();                 // run idle process
ffffffffc0200092:	613050ef          	jal	ra,ffffffffc0205ea4 <cpu_idle>

ffffffffc0200096 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200096:	715d                	addi	sp,sp,-80
ffffffffc0200098:	e486                	sd	ra,72(sp)
ffffffffc020009a:	e0a2                	sd	s0,64(sp)
ffffffffc020009c:	fc26                	sd	s1,56(sp)
ffffffffc020009e:	f84a                	sd	s2,48(sp)
ffffffffc02000a0:	f44e                	sd	s3,40(sp)
ffffffffc02000a2:	f052                	sd	s4,32(sp)
ffffffffc02000a4:	ec56                	sd	s5,24(sp)
ffffffffc02000a6:	e85a                	sd	s6,16(sp)
ffffffffc02000a8:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc02000aa:	c901                	beqz	a0,ffffffffc02000ba <readline+0x24>
        cprintf("%s", prompt);
ffffffffc02000ac:	85aa                	mv	a1,a0
ffffffffc02000ae:	00006517          	auipc	a0,0x6
ffffffffc02000b2:	57250513          	addi	a0,a0,1394 # ffffffffc0206620 <etext+0x2e>
ffffffffc02000b6:	0d8000ef          	jal	ra,ffffffffc020018e <cprintf>
readline(const char *prompt) {
ffffffffc02000ba:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000bc:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000be:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000c0:	4aa9                	li	s5,10
ffffffffc02000c2:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000c4:	000a1b97          	auipc	s7,0xa1
ffffffffc02000c8:	fb4b8b93          	addi	s7,s7,-76 # ffffffffc02a1078 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000cc:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000d0:	136000ef          	jal	ra,ffffffffc0200206 <getchar>
ffffffffc02000d4:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000d6:	00054b63          	bltz	a0,ffffffffc02000ec <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	00a95b63          	ble	a0,s2,ffffffffc02000f0 <readline+0x5a>
ffffffffc02000de:	029a5463          	ble	s1,s4,ffffffffc0200106 <readline+0x70>
        c = getchar();
ffffffffc02000e2:	124000ef          	jal	ra,ffffffffc0200206 <getchar>
ffffffffc02000e6:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000e8:	fe0559e3          	bgez	a0,ffffffffc02000da <readline+0x44>
            return NULL;
ffffffffc02000ec:	4501                	li	a0,0
ffffffffc02000ee:	a099                	j	ffffffffc0200134 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc02000f0:	03341463          	bne	s0,s3,ffffffffc0200118 <readline+0x82>
ffffffffc02000f4:	e8b9                	bnez	s1,ffffffffc020014a <readline+0xb4>
        c = getchar();
ffffffffc02000f6:	110000ef          	jal	ra,ffffffffc0200206 <getchar>
ffffffffc02000fa:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000fc:	fe0548e3          	bltz	a0,ffffffffc02000ec <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200100:	fea958e3          	ble	a0,s2,ffffffffc02000f0 <readline+0x5a>
ffffffffc0200104:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200106:	8522                	mv	a0,s0
ffffffffc0200108:	0ba000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            buf[i ++] = c;
ffffffffc020010c:	009b87b3          	add	a5,s7,s1
ffffffffc0200110:	00878023          	sb	s0,0(a5)
ffffffffc0200114:	2485                	addiw	s1,s1,1
ffffffffc0200116:	bf6d                	j	ffffffffc02000d0 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0200118:	01540463          	beq	s0,s5,ffffffffc0200120 <readline+0x8a>
ffffffffc020011c:	fb641ae3          	bne	s0,s6,ffffffffc02000d0 <readline+0x3a>
            cputchar(c);
ffffffffc0200120:	8522                	mv	a0,s0
ffffffffc0200122:	0a0000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            buf[i] = '\0';
ffffffffc0200126:	000a1517          	auipc	a0,0xa1
ffffffffc020012a:	f5250513          	addi	a0,a0,-174 # ffffffffc02a1078 <edata>
ffffffffc020012e:	94aa                	add	s1,s1,a0
ffffffffc0200130:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200134:	60a6                	ld	ra,72(sp)
ffffffffc0200136:	6406                	ld	s0,64(sp)
ffffffffc0200138:	74e2                	ld	s1,56(sp)
ffffffffc020013a:	7942                	ld	s2,48(sp)
ffffffffc020013c:	79a2                	ld	s3,40(sp)
ffffffffc020013e:	7a02                	ld	s4,32(sp)
ffffffffc0200140:	6ae2                	ld	s5,24(sp)
ffffffffc0200142:	6b42                	ld	s6,16(sp)
ffffffffc0200144:	6ba2                	ld	s7,8(sp)
ffffffffc0200146:	6161                	addi	sp,sp,80
ffffffffc0200148:	8082                	ret
            cputchar(c);
ffffffffc020014a:	4521                	li	a0,8
ffffffffc020014c:	076000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            i --;
ffffffffc0200150:	34fd                	addiw	s1,s1,-1
ffffffffc0200152:	bfbd                	j	ffffffffc02000d0 <readline+0x3a>

ffffffffc0200154 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200154:	1141                	addi	sp,sp,-16
ffffffffc0200156:	e022                	sd	s0,0(sp)
ffffffffc0200158:	e406                	sd	ra,8(sp)
ffffffffc020015a:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020015c:	42e000ef          	jal	ra,ffffffffc020058a <cons_putc>
    (*cnt) ++;
ffffffffc0200160:	401c                	lw	a5,0(s0)
}
ffffffffc0200162:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200164:	2785                	addiw	a5,a5,1
ffffffffc0200166:	c01c                	sw	a5,0(s0)
}
ffffffffc0200168:	6402                	ld	s0,0(sp)
ffffffffc020016a:	0141                	addi	sp,sp,16
ffffffffc020016c:	8082                	ret

ffffffffc020016e <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020016e:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200170:	86ae                	mv	a3,a1
ffffffffc0200172:	862a                	mv	a2,a0
ffffffffc0200174:	006c                	addi	a1,sp,12
ffffffffc0200176:	00000517          	auipc	a0,0x0
ffffffffc020017a:	fde50513          	addi	a0,a0,-34 # ffffffffc0200154 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc020017e:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200180:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200182:	01c060ef          	jal	ra,ffffffffc020619e <vprintfmt>
    return cnt;
}
ffffffffc0200186:	60e2                	ld	ra,24(sp)
ffffffffc0200188:	4532                	lw	a0,12(sp)
ffffffffc020018a:	6105                	addi	sp,sp,32
ffffffffc020018c:	8082                	ret

ffffffffc020018e <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020018e:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200190:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200194:	f42e                	sd	a1,40(sp)
ffffffffc0200196:	f832                	sd	a2,48(sp)
ffffffffc0200198:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020019a:	862a                	mv	a2,a0
ffffffffc020019c:	004c                	addi	a1,sp,4
ffffffffc020019e:	00000517          	auipc	a0,0x0
ffffffffc02001a2:	fb650513          	addi	a0,a0,-74 # ffffffffc0200154 <cputch>
ffffffffc02001a6:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02001a8:	ec06                	sd	ra,24(sp)
ffffffffc02001aa:	e0ba                	sd	a4,64(sp)
ffffffffc02001ac:	e4be                	sd	a5,72(sp)
ffffffffc02001ae:	e8c2                	sd	a6,80(sp)
ffffffffc02001b0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001b2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001b4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02001b6:	7e9050ef          	jal	ra,ffffffffc020619e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001ba:	60e2                	ld	ra,24(sp)
ffffffffc02001bc:	4512                	lw	a0,4(sp)
ffffffffc02001be:	6125                	addi	sp,sp,96
ffffffffc02001c0:	8082                	ret

ffffffffc02001c2 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02001c2:	3c80006f          	j	ffffffffc020058a <cons_putc>

ffffffffc02001c6 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02001c6:	1101                	addi	sp,sp,-32
ffffffffc02001c8:	e822                	sd	s0,16(sp)
ffffffffc02001ca:	ec06                	sd	ra,24(sp)
ffffffffc02001cc:	e426                	sd	s1,8(sp)
ffffffffc02001ce:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02001d0:	00054503          	lbu	a0,0(a0)
ffffffffc02001d4:	c51d                	beqz	a0,ffffffffc0200202 <cputs+0x3c>
ffffffffc02001d6:	0405                	addi	s0,s0,1
ffffffffc02001d8:	4485                	li	s1,1
ffffffffc02001da:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001dc:	3ae000ef          	jal	ra,ffffffffc020058a <cons_putc>
    (*cnt) ++;
ffffffffc02001e0:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc02001e4:	0405                	addi	s0,s0,1
ffffffffc02001e6:	fff44503          	lbu	a0,-1(s0)
ffffffffc02001ea:	f96d                	bnez	a0,ffffffffc02001dc <cputs+0x16>
ffffffffc02001ec:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f0:	4529                	li	a0,10
ffffffffc02001f2:	398000ef          	jal	ra,ffffffffc020058a <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001f6:	8522                	mv	a0,s0
ffffffffc02001f8:	60e2                	ld	ra,24(sp)
ffffffffc02001fa:	6442                	ld	s0,16(sp)
ffffffffc02001fc:	64a2                	ld	s1,8(sp)
ffffffffc02001fe:	6105                	addi	sp,sp,32
ffffffffc0200200:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200202:	4405                	li	s0,1
ffffffffc0200204:	b7f5                	j	ffffffffc02001f0 <cputs+0x2a>

ffffffffc0200206 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200206:	1141                	addi	sp,sp,-16
ffffffffc0200208:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020020a:	3b6000ef          	jal	ra,ffffffffc02005c0 <cons_getc>
ffffffffc020020e:	dd75                	beqz	a0,ffffffffc020020a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200210:	60a2                	ld	ra,8(sp)
ffffffffc0200212:	0141                	addi	sp,sp,16
ffffffffc0200214:	8082                	ret

ffffffffc0200216 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200216:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200218:	00006517          	auipc	a0,0x6
ffffffffc020021c:	44050513          	addi	a0,a0,1088 # ffffffffc0206658 <etext+0x66>
void print_kerninfo(void) {
ffffffffc0200220:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200222:	f6dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200226:	00000597          	auipc	a1,0x0
ffffffffc020022a:	e1058593          	addi	a1,a1,-496 # ffffffffc0200036 <kern_init>
ffffffffc020022e:	00006517          	auipc	a0,0x6
ffffffffc0200232:	44a50513          	addi	a0,a0,1098 # ffffffffc0206678 <etext+0x86>
ffffffffc0200236:	f59ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020023a:	00006597          	auipc	a1,0x6
ffffffffc020023e:	3b858593          	addi	a1,a1,952 # ffffffffc02065f2 <etext>
ffffffffc0200242:	00006517          	auipc	a0,0x6
ffffffffc0200246:	45650513          	addi	a0,a0,1110 # ffffffffc0206698 <etext+0xa6>
ffffffffc020024a:	f45ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020024e:	000a1597          	auipc	a1,0xa1
ffffffffc0200252:	e2a58593          	addi	a1,a1,-470 # ffffffffc02a1078 <edata>
ffffffffc0200256:	00006517          	auipc	a0,0x6
ffffffffc020025a:	46250513          	addi	a0,a0,1122 # ffffffffc02066b8 <etext+0xc6>
ffffffffc020025e:	f31ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200262:	000ac597          	auipc	a1,0xac
ffffffffc0200266:	39e58593          	addi	a1,a1,926 # ffffffffc02ac600 <end>
ffffffffc020026a:	00006517          	auipc	a0,0x6
ffffffffc020026e:	46e50513          	addi	a0,a0,1134 # ffffffffc02066d8 <etext+0xe6>
ffffffffc0200272:	f1dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200276:	000ac597          	auipc	a1,0xac
ffffffffc020027a:	78958593          	addi	a1,a1,1929 # ffffffffc02ac9ff <end+0x3ff>
ffffffffc020027e:	00000797          	auipc	a5,0x0
ffffffffc0200282:	db878793          	addi	a5,a5,-584 # ffffffffc0200036 <kern_init>
ffffffffc0200286:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020028a:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020028e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200294:	95be                	add	a1,a1,a5
ffffffffc0200296:	85a9                	srai	a1,a1,0xa
ffffffffc0200298:	00006517          	auipc	a0,0x6
ffffffffc020029c:	46050513          	addi	a0,a0,1120 # ffffffffc02066f8 <etext+0x106>
}
ffffffffc02002a0:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a2:	eedff06f          	j	ffffffffc020018e <cprintf>

ffffffffc02002a6 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002a6:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002a8:	00006617          	auipc	a2,0x6
ffffffffc02002ac:	38060613          	addi	a2,a2,896 # ffffffffc0206628 <etext+0x36>
ffffffffc02002b0:	04d00593          	li	a1,77
ffffffffc02002b4:	00006517          	auipc	a0,0x6
ffffffffc02002b8:	38c50513          	addi	a0,a0,908 # ffffffffc0206640 <etext+0x4e>
void print_stackframe(void) {
ffffffffc02002bc:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002be:	1c6000ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02002c2 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002c2:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c4:	00006617          	auipc	a2,0x6
ffffffffc02002c8:	54460613          	addi	a2,a2,1348 # ffffffffc0206808 <commands+0xe0>
ffffffffc02002cc:	00006597          	auipc	a1,0x6
ffffffffc02002d0:	55c58593          	addi	a1,a1,1372 # ffffffffc0206828 <commands+0x100>
ffffffffc02002d4:	00006517          	auipc	a0,0x6
ffffffffc02002d8:	55c50513          	addi	a0,a0,1372 # ffffffffc0206830 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002dc:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002de:	eb1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc02002e2:	00006617          	auipc	a2,0x6
ffffffffc02002e6:	55e60613          	addi	a2,a2,1374 # ffffffffc0206840 <commands+0x118>
ffffffffc02002ea:	00006597          	auipc	a1,0x6
ffffffffc02002ee:	57e58593          	addi	a1,a1,1406 # ffffffffc0206868 <commands+0x140>
ffffffffc02002f2:	00006517          	auipc	a0,0x6
ffffffffc02002f6:	53e50513          	addi	a0,a0,1342 # ffffffffc0206830 <commands+0x108>
ffffffffc02002fa:	e95ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc02002fe:	00006617          	auipc	a2,0x6
ffffffffc0200302:	57a60613          	addi	a2,a2,1402 # ffffffffc0206878 <commands+0x150>
ffffffffc0200306:	00006597          	auipc	a1,0x6
ffffffffc020030a:	59258593          	addi	a1,a1,1426 # ffffffffc0206898 <commands+0x170>
ffffffffc020030e:	00006517          	auipc	a0,0x6
ffffffffc0200312:	52250513          	addi	a0,a0,1314 # ffffffffc0206830 <commands+0x108>
ffffffffc0200316:	e79ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    }
    return 0;
}
ffffffffc020031a:	60a2                	ld	ra,8(sp)
ffffffffc020031c:	4501                	li	a0,0
ffffffffc020031e:	0141                	addi	sp,sp,16
ffffffffc0200320:	8082                	ret

ffffffffc0200322 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200322:	1141                	addi	sp,sp,-16
ffffffffc0200324:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200326:	ef1ff0ef          	jal	ra,ffffffffc0200216 <print_kerninfo>
    return 0;
}
ffffffffc020032a:	60a2                	ld	ra,8(sp)
ffffffffc020032c:	4501                	li	a0,0
ffffffffc020032e:	0141                	addi	sp,sp,16
ffffffffc0200330:	8082                	ret

ffffffffc0200332 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200332:	1141                	addi	sp,sp,-16
ffffffffc0200334:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200336:	f71ff0ef          	jal	ra,ffffffffc02002a6 <print_stackframe>
    return 0;
}
ffffffffc020033a:	60a2                	ld	ra,8(sp)
ffffffffc020033c:	4501                	li	a0,0
ffffffffc020033e:	0141                	addi	sp,sp,16
ffffffffc0200340:	8082                	ret

ffffffffc0200342 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200342:	7115                	addi	sp,sp,-224
ffffffffc0200344:	e962                	sd	s8,144(sp)
ffffffffc0200346:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200348:	00006517          	auipc	a0,0x6
ffffffffc020034c:	42850513          	addi	a0,a0,1064 # ffffffffc0206770 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200350:	ed86                	sd	ra,216(sp)
ffffffffc0200352:	e9a2                	sd	s0,208(sp)
ffffffffc0200354:	e5a6                	sd	s1,200(sp)
ffffffffc0200356:	e1ca                	sd	s2,192(sp)
ffffffffc0200358:	fd4e                	sd	s3,184(sp)
ffffffffc020035a:	f952                	sd	s4,176(sp)
ffffffffc020035c:	f556                	sd	s5,168(sp)
ffffffffc020035e:	f15a                	sd	s6,160(sp)
ffffffffc0200360:	ed5e                	sd	s7,152(sp)
ffffffffc0200362:	e566                	sd	s9,136(sp)
ffffffffc0200364:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200366:	e29ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036a:	00006517          	auipc	a0,0x6
ffffffffc020036e:	42e50513          	addi	a0,a0,1070 # ffffffffc0206798 <commands+0x70>
ffffffffc0200372:	e1dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    if (tf != NULL) {
ffffffffc0200376:	000c0563          	beqz	s8,ffffffffc0200380 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037a:	8562                	mv	a0,s8
ffffffffc020037c:	4ce000ef          	jal	ra,ffffffffc020084a <print_trapframe>
ffffffffc0200380:	00006c97          	auipc	s9,0x6
ffffffffc0200384:	3a8c8c93          	addi	s9,s9,936 # ffffffffc0206728 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200388:	00006997          	auipc	s3,0x6
ffffffffc020038c:	43898993          	addi	s3,s3,1080 # ffffffffc02067c0 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200390:	00006917          	auipc	s2,0x6
ffffffffc0200394:	43890913          	addi	s2,s2,1080 # ffffffffc02067c8 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc0200398:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039a:	00006b17          	auipc	s6,0x6
ffffffffc020039e:	436b0b13          	addi	s6,s6,1078 # ffffffffc02067d0 <commands+0xa8>
    if (argc == 0) {
ffffffffc02003a2:	00006a97          	auipc	s5,0x6
ffffffffc02003a6:	486a8a93          	addi	s5,s5,1158 # ffffffffc0206828 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003aa:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003ac:	854e                	mv	a0,s3
ffffffffc02003ae:	ce9ff0ef          	jal	ra,ffffffffc0200096 <readline>
ffffffffc02003b2:	842a                	mv	s0,a0
ffffffffc02003b4:	dd65                	beqz	a0,ffffffffc02003ac <kmonitor+0x6a>
ffffffffc02003b6:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003ba:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003bc:	c999                	beqz	a1,ffffffffc02003d2 <kmonitor+0x90>
ffffffffc02003be:	854a                	mv	a0,s2
ffffffffc02003c0:	1ea060ef          	jal	ra,ffffffffc02065aa <strchr>
ffffffffc02003c4:	c925                	beqz	a0,ffffffffc0200434 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02003c6:	00144583          	lbu	a1,1(s0)
ffffffffc02003ca:	00040023          	sb	zero,0(s0)
ffffffffc02003ce:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003d0:	f5fd                	bnez	a1,ffffffffc02003be <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02003d2:	dce9                	beqz	s1,ffffffffc02003ac <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003d4:	6582                	ld	a1,0(sp)
ffffffffc02003d6:	00006d17          	auipc	s10,0x6
ffffffffc02003da:	352d0d13          	addi	s10,s10,850 # ffffffffc0206728 <commands>
    if (argc == 0) {
ffffffffc02003de:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e0:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003e2:	0d61                	addi	s10,s10,24
ffffffffc02003e4:	19c060ef          	jal	ra,ffffffffc0206580 <strcmp>
ffffffffc02003e8:	c919                	beqz	a0,ffffffffc02003fe <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003ea:	2405                	addiw	s0,s0,1
ffffffffc02003ec:	09740463          	beq	s0,s7,ffffffffc0200474 <kmonitor+0x132>
ffffffffc02003f0:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003f4:	6582                	ld	a1,0(sp)
ffffffffc02003f6:	0d61                	addi	s10,s10,24
ffffffffc02003f8:	188060ef          	jal	ra,ffffffffc0206580 <strcmp>
ffffffffc02003fc:	f57d                	bnez	a0,ffffffffc02003ea <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003fe:	00141793          	slli	a5,s0,0x1
ffffffffc0200402:	97a2                	add	a5,a5,s0
ffffffffc0200404:	078e                	slli	a5,a5,0x3
ffffffffc0200406:	97e6                	add	a5,a5,s9
ffffffffc0200408:	6b9c                	ld	a5,16(a5)
ffffffffc020040a:	8662                	mv	a2,s8
ffffffffc020040c:	002c                	addi	a1,sp,8
ffffffffc020040e:	fff4851b          	addiw	a0,s1,-1
ffffffffc0200412:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200414:	f8055ce3          	bgez	a0,ffffffffc02003ac <kmonitor+0x6a>
}
ffffffffc0200418:	60ee                	ld	ra,216(sp)
ffffffffc020041a:	644e                	ld	s0,208(sp)
ffffffffc020041c:	64ae                	ld	s1,200(sp)
ffffffffc020041e:	690e                	ld	s2,192(sp)
ffffffffc0200420:	79ea                	ld	s3,184(sp)
ffffffffc0200422:	7a4a                	ld	s4,176(sp)
ffffffffc0200424:	7aaa                	ld	s5,168(sp)
ffffffffc0200426:	7b0a                	ld	s6,160(sp)
ffffffffc0200428:	6bea                	ld	s7,152(sp)
ffffffffc020042a:	6c4a                	ld	s8,144(sp)
ffffffffc020042c:	6caa                	ld	s9,136(sp)
ffffffffc020042e:	6d0a                	ld	s10,128(sp)
ffffffffc0200430:	612d                	addi	sp,sp,224
ffffffffc0200432:	8082                	ret
        if (*buf == '\0') {
ffffffffc0200434:	00044783          	lbu	a5,0(s0)
ffffffffc0200438:	dfc9                	beqz	a5,ffffffffc02003d2 <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc020043a:	03448863          	beq	s1,s4,ffffffffc020046a <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc020043e:	00349793          	slli	a5,s1,0x3
ffffffffc0200442:	0118                	addi	a4,sp,128
ffffffffc0200444:	97ba                	add	a5,a5,a4
ffffffffc0200446:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020044a:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020044e:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200450:	e591                	bnez	a1,ffffffffc020045c <kmonitor+0x11a>
ffffffffc0200452:	b749                	j	ffffffffc02003d4 <kmonitor+0x92>
            buf ++;
ffffffffc0200454:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200456:	00044583          	lbu	a1,0(s0)
ffffffffc020045a:	ddad                	beqz	a1,ffffffffc02003d4 <kmonitor+0x92>
ffffffffc020045c:	854a                	mv	a0,s2
ffffffffc020045e:	14c060ef          	jal	ra,ffffffffc02065aa <strchr>
ffffffffc0200462:	d96d                	beqz	a0,ffffffffc0200454 <kmonitor+0x112>
ffffffffc0200464:	00044583          	lbu	a1,0(s0)
ffffffffc0200468:	bf91                	j	ffffffffc02003bc <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020046a:	45c1                	li	a1,16
ffffffffc020046c:	855a                	mv	a0,s6
ffffffffc020046e:	d21ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc0200472:	b7f1                	j	ffffffffc020043e <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200474:	6582                	ld	a1,0(sp)
ffffffffc0200476:	00006517          	auipc	a0,0x6
ffffffffc020047a:	37a50513          	addi	a0,a0,890 # ffffffffc02067f0 <commands+0xc8>
ffffffffc020047e:	d11ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    return 0;
ffffffffc0200482:	b72d                	j	ffffffffc02003ac <kmonitor+0x6a>

ffffffffc0200484 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200484:	000ac317          	auipc	t1,0xac
ffffffffc0200488:	ff430313          	addi	t1,t1,-12 # ffffffffc02ac478 <is_panic>
ffffffffc020048c:	00033303          	ld	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200490:	715d                	addi	sp,sp,-80
ffffffffc0200492:	ec06                	sd	ra,24(sp)
ffffffffc0200494:	e822                	sd	s0,16(sp)
ffffffffc0200496:	f436                	sd	a3,40(sp)
ffffffffc0200498:	f83a                	sd	a4,48(sp)
ffffffffc020049a:	fc3e                	sd	a5,56(sp)
ffffffffc020049c:	e0c2                	sd	a6,64(sp)
ffffffffc020049e:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02004a0:	02031c63          	bnez	t1,ffffffffc02004d8 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004a4:	4785                	li	a5,1
ffffffffc02004a6:	8432                	mv	s0,a2
ffffffffc02004a8:	000ac717          	auipc	a4,0xac
ffffffffc02004ac:	fcf73823          	sd	a5,-48(a4) # ffffffffc02ac478 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b0:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02004b2:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b4:	85aa                	mv	a1,a0
ffffffffc02004b6:	00006517          	auipc	a0,0x6
ffffffffc02004ba:	3f250513          	addi	a0,a0,1010 # ffffffffc02068a8 <commands+0x180>
    va_start(ap, fmt);
ffffffffc02004be:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c0:	ccfff0ef          	jal	ra,ffffffffc020018e <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004c4:	65a2                	ld	a1,8(sp)
ffffffffc02004c6:	8522                	mv	a0,s0
ffffffffc02004c8:	ca7ff0ef          	jal	ra,ffffffffc020016e <vcprintf>
    cprintf("\n");
ffffffffc02004cc:	00007517          	auipc	a0,0x7
ffffffffc02004d0:	38450513          	addi	a0,a0,900 # ffffffffc0207850 <default_pmm_manager+0x538>
ffffffffc02004d4:	cbbff0ef          	jal	ra,ffffffffc020018e <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004d8:	4501                	li	a0,0
ffffffffc02004da:	4581                	li	a1,0
ffffffffc02004dc:	4601                	li	a2,0
ffffffffc02004de:	48a1                	li	a7,8
ffffffffc02004e0:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004e4:	176000ef          	jal	ra,ffffffffc020065a <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004e8:	4501                	li	a0,0
ffffffffc02004ea:	e59ff0ef          	jal	ra,ffffffffc0200342 <kmonitor>
ffffffffc02004ee:	bfed                	j	ffffffffc02004e8 <__panic+0x64>

ffffffffc02004f0 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004f0:	715d                	addi	sp,sp,-80
ffffffffc02004f2:	e822                	sd	s0,16(sp)
ffffffffc02004f4:	fc3e                	sd	a5,56(sp)
ffffffffc02004f6:	8432                	mv	s0,a2
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004f8:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fa:	862e                	mv	a2,a1
ffffffffc02004fc:	85aa                	mv	a1,a0
ffffffffc02004fe:	00006517          	auipc	a0,0x6
ffffffffc0200502:	3ca50513          	addi	a0,a0,970 # ffffffffc02068c8 <commands+0x1a0>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200506:	ec06                	sd	ra,24(sp)
ffffffffc0200508:	f436                	sd	a3,40(sp)
ffffffffc020050a:	f83a                	sd	a4,48(sp)
ffffffffc020050c:	e0c2                	sd	a6,64(sp)
ffffffffc020050e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200510:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200512:	c7dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200516:	65a2                	ld	a1,8(sp)
ffffffffc0200518:	8522                	mv	a0,s0
ffffffffc020051a:	c55ff0ef          	jal	ra,ffffffffc020016e <vcprintf>
    cprintf("\n");
ffffffffc020051e:	00007517          	auipc	a0,0x7
ffffffffc0200522:	33250513          	addi	a0,a0,818 # ffffffffc0207850 <default_pmm_manager+0x538>
ffffffffc0200526:	c69ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    va_end(ap);
}
ffffffffc020052a:	60e2                	ld	ra,24(sp)
ffffffffc020052c:	6442                	ld	s0,16(sp)
ffffffffc020052e:	6161                	addi	sp,sp,80
ffffffffc0200530:	8082                	ret

ffffffffc0200532 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200532:	67e1                	lui	a5,0x18
ffffffffc0200534:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xdc20>
ffffffffc0200538:	000ac717          	auipc	a4,0xac
ffffffffc020053c:	f4f73423          	sd	a5,-184(a4) # ffffffffc02ac480 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200540:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200544:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200546:	953e                	add	a0,a0,a5
ffffffffc0200548:	4601                	li	a2,0
ffffffffc020054a:	4881                	li	a7,0
ffffffffc020054c:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200550:	02000793          	li	a5,32
ffffffffc0200554:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200558:	00006517          	auipc	a0,0x6
ffffffffc020055c:	39050513          	addi	a0,a0,912 # ffffffffc02068e8 <commands+0x1c0>
    ticks = 0;
ffffffffc0200560:	000ac797          	auipc	a5,0xac
ffffffffc0200564:	f607b823          	sd	zero,-144(a5) # ffffffffc02ac4d0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200568:	c27ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc020056c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020056c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200570:	000ac797          	auipc	a5,0xac
ffffffffc0200574:	f1078793          	addi	a5,a5,-240 # ffffffffc02ac480 <timebase>
ffffffffc0200578:	639c                	ld	a5,0(a5)
ffffffffc020057a:	4581                	li	a1,0
ffffffffc020057c:	4601                	li	a2,0
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4881                	li	a7,0
ffffffffc0200582:	00000073          	ecall
ffffffffc0200586:	8082                	ret

ffffffffc0200588 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200588:	8082                	ret

ffffffffc020058a <cons_putc>:
#include <sched.h>
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020058a:	100027f3          	csrr	a5,sstatus
ffffffffc020058e:	8b89                	andi	a5,a5,2
ffffffffc0200590:	0ff57513          	andi	a0,a0,255
ffffffffc0200594:	e799                	bnez	a5,ffffffffc02005a2 <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200596:	4581                	li	a1,0
ffffffffc0200598:	4601                	li	a2,0
ffffffffc020059a:	4885                	li	a7,1
ffffffffc020059c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02005a0:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a2:	1101                	addi	sp,sp,-32
ffffffffc02005a4:	ec06                	sd	ra,24(sp)
ffffffffc02005a6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005a8:	0b2000ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc02005ac:	6522                	ld	a0,8(sp)
ffffffffc02005ae:	4581                	li	a1,0
ffffffffc02005b0:	4601                	li	a2,0
ffffffffc02005b2:	4885                	li	a7,1
ffffffffc02005b4:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005b8:	60e2                	ld	ra,24(sp)
ffffffffc02005ba:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02005bc:	0980006f          	j	ffffffffc0200654 <intr_enable>

ffffffffc02005c0 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005c0:	100027f3          	csrr	a5,sstatus
ffffffffc02005c4:	8b89                	andi	a5,a5,2
ffffffffc02005c6:	eb89                	bnez	a5,ffffffffc02005d8 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005c8:	4501                	li	a0,0
ffffffffc02005ca:	4581                	li	a1,0
ffffffffc02005cc:	4601                	li	a2,0
ffffffffc02005ce:	4889                	li	a7,2
ffffffffc02005d0:	00000073          	ecall
ffffffffc02005d4:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d6:	8082                	ret
int cons_getc(void) {
ffffffffc02005d8:	1101                	addi	sp,sp,-32
ffffffffc02005da:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005dc:	07e000ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc02005e0:	4501                	li	a0,0
ffffffffc02005e2:	4581                	li	a1,0
ffffffffc02005e4:	4601                	li	a2,0
ffffffffc02005e6:	4889                	li	a7,2
ffffffffc02005e8:	00000073          	ecall
ffffffffc02005ec:	2501                	sext.w	a0,a0
ffffffffc02005ee:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f0:	064000ef          	jal	ra,ffffffffc0200654 <intr_enable>
}
ffffffffc02005f4:	60e2                	ld	ra,24(sp)
ffffffffc02005f6:	6522                	ld	a0,8(sp)
ffffffffc02005f8:	6105                	addi	sp,sp,32
ffffffffc02005fa:	8082                	ret

ffffffffc02005fc <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02005fe:	00253513          	sltiu	a0,a0,2
ffffffffc0200602:	8082                	ret

ffffffffc0200604 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc0200604:	03800513          	li	a0,56
ffffffffc0200608:	8082                	ret

ffffffffc020060a <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020060a:	000a1797          	auipc	a5,0xa1
ffffffffc020060e:	e6e78793          	addi	a5,a5,-402 # ffffffffc02a1478 <ide>
ffffffffc0200612:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc0200616:	1141                	addi	sp,sp,-16
ffffffffc0200618:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020061a:	95be                	add	a1,a1,a5
ffffffffc020061c:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc0200620:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200622:	7b9050ef          	jal	ra,ffffffffc02065da <memcpy>
    return 0;
}
ffffffffc0200626:	60a2                	ld	ra,8(sp)
ffffffffc0200628:	4501                	li	a0,0
ffffffffc020062a:	0141                	addi	sp,sp,16
ffffffffc020062c:	8082                	ret

ffffffffc020062e <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
ffffffffc020062e:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200630:	0095979b          	slliw	a5,a1,0x9
ffffffffc0200634:	000a1517          	auipc	a0,0xa1
ffffffffc0200638:	e4450513          	addi	a0,a0,-444 # ffffffffc02a1478 <ide>
                   size_t nsecs) {
ffffffffc020063c:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020063e:	00969613          	slli	a2,a3,0x9
ffffffffc0200642:	85ba                	mv	a1,a4
ffffffffc0200644:	953e                	add	a0,a0,a5
                   size_t nsecs) {
ffffffffc0200646:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200648:	793050ef          	jal	ra,ffffffffc02065da <memcpy>
    return 0;
}
ffffffffc020064c:	60a2                	ld	ra,8(sp)
ffffffffc020064e:	4501                	li	a0,0
ffffffffc0200650:	0141                	addi	sp,sp,16
ffffffffc0200652:	8082                	ret

ffffffffc0200654 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200654:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200658:	8082                	ret

ffffffffc020065a <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020065a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020065e:	8082                	ret

ffffffffc0200660 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200660:	8082                	ret

ffffffffc0200662 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200662:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200666:	00000797          	auipc	a5,0x0
ffffffffc020066a:	67278793          	addi	a5,a5,1650 # ffffffffc0200cd8 <__alltraps>
ffffffffc020066e:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200672:	000407b7          	lui	a5,0x40
ffffffffc0200676:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020067a:	8082                	ret

ffffffffc020067c <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020067c:	610c                	ld	a1,0(a0)
{
ffffffffc020067e:	1141                	addi	sp,sp,-16
ffffffffc0200680:	e022                	sd	s0,0(sp)
ffffffffc0200682:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200684:	00006517          	auipc	a0,0x6
ffffffffc0200688:	59450513          	addi	a0,a0,1428 # ffffffffc0206c18 <commands+0x4f0>
{
ffffffffc020068c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020068e:	b01ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200692:	640c                	ld	a1,8(s0)
ffffffffc0200694:	00006517          	auipc	a0,0x6
ffffffffc0200698:	59c50513          	addi	a0,a0,1436 # ffffffffc0206c30 <commands+0x508>
ffffffffc020069c:	af3ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02006a0:	680c                	ld	a1,16(s0)
ffffffffc02006a2:	00006517          	auipc	a0,0x6
ffffffffc02006a6:	5a650513          	addi	a0,a0,1446 # ffffffffc0206c48 <commands+0x520>
ffffffffc02006aa:	ae5ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02006ae:	6c0c                	ld	a1,24(s0)
ffffffffc02006b0:	00006517          	auipc	a0,0x6
ffffffffc02006b4:	5b050513          	addi	a0,a0,1456 # ffffffffc0206c60 <commands+0x538>
ffffffffc02006b8:	ad7ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006bc:	700c                	ld	a1,32(s0)
ffffffffc02006be:	00006517          	auipc	a0,0x6
ffffffffc02006c2:	5ba50513          	addi	a0,a0,1466 # ffffffffc0206c78 <commands+0x550>
ffffffffc02006c6:	ac9ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006ca:	740c                	ld	a1,40(s0)
ffffffffc02006cc:	00006517          	auipc	a0,0x6
ffffffffc02006d0:	5c450513          	addi	a0,a0,1476 # ffffffffc0206c90 <commands+0x568>
ffffffffc02006d4:	abbff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006d8:	780c                	ld	a1,48(s0)
ffffffffc02006da:	00006517          	auipc	a0,0x6
ffffffffc02006de:	5ce50513          	addi	a0,a0,1486 # ffffffffc0206ca8 <commands+0x580>
ffffffffc02006e2:	aadff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006e6:	7c0c                	ld	a1,56(s0)
ffffffffc02006e8:	00006517          	auipc	a0,0x6
ffffffffc02006ec:	5d850513          	addi	a0,a0,1496 # ffffffffc0206cc0 <commands+0x598>
ffffffffc02006f0:	a9fff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006f4:	602c                	ld	a1,64(s0)
ffffffffc02006f6:	00006517          	auipc	a0,0x6
ffffffffc02006fa:	5e250513          	addi	a0,a0,1506 # ffffffffc0206cd8 <commands+0x5b0>
ffffffffc02006fe:	a91ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200702:	642c                	ld	a1,72(s0)
ffffffffc0200704:	00006517          	auipc	a0,0x6
ffffffffc0200708:	5ec50513          	addi	a0,a0,1516 # ffffffffc0206cf0 <commands+0x5c8>
ffffffffc020070c:	a83ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200710:	682c                	ld	a1,80(s0)
ffffffffc0200712:	00006517          	auipc	a0,0x6
ffffffffc0200716:	5f650513          	addi	a0,a0,1526 # ffffffffc0206d08 <commands+0x5e0>
ffffffffc020071a:	a75ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020071e:	6c2c                	ld	a1,88(s0)
ffffffffc0200720:	00006517          	auipc	a0,0x6
ffffffffc0200724:	60050513          	addi	a0,a0,1536 # ffffffffc0206d20 <commands+0x5f8>
ffffffffc0200728:	a67ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020072c:	702c                	ld	a1,96(s0)
ffffffffc020072e:	00006517          	auipc	a0,0x6
ffffffffc0200732:	60a50513          	addi	a0,a0,1546 # ffffffffc0206d38 <commands+0x610>
ffffffffc0200736:	a59ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020073a:	742c                	ld	a1,104(s0)
ffffffffc020073c:	00006517          	auipc	a0,0x6
ffffffffc0200740:	61450513          	addi	a0,a0,1556 # ffffffffc0206d50 <commands+0x628>
ffffffffc0200744:	a4bff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200748:	782c                	ld	a1,112(s0)
ffffffffc020074a:	00006517          	auipc	a0,0x6
ffffffffc020074e:	61e50513          	addi	a0,a0,1566 # ffffffffc0206d68 <commands+0x640>
ffffffffc0200752:	a3dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200756:	7c2c                	ld	a1,120(s0)
ffffffffc0200758:	00006517          	auipc	a0,0x6
ffffffffc020075c:	62850513          	addi	a0,a0,1576 # ffffffffc0206d80 <commands+0x658>
ffffffffc0200760:	a2fff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200764:	604c                	ld	a1,128(s0)
ffffffffc0200766:	00006517          	auipc	a0,0x6
ffffffffc020076a:	63250513          	addi	a0,a0,1586 # ffffffffc0206d98 <commands+0x670>
ffffffffc020076e:	a21ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200772:	644c                	ld	a1,136(s0)
ffffffffc0200774:	00006517          	auipc	a0,0x6
ffffffffc0200778:	63c50513          	addi	a0,a0,1596 # ffffffffc0206db0 <commands+0x688>
ffffffffc020077c:	a13ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200780:	684c                	ld	a1,144(s0)
ffffffffc0200782:	00006517          	auipc	a0,0x6
ffffffffc0200786:	64650513          	addi	a0,a0,1606 # ffffffffc0206dc8 <commands+0x6a0>
ffffffffc020078a:	a05ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020078e:	6c4c                	ld	a1,152(s0)
ffffffffc0200790:	00006517          	auipc	a0,0x6
ffffffffc0200794:	65050513          	addi	a0,a0,1616 # ffffffffc0206de0 <commands+0x6b8>
ffffffffc0200798:	9f7ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020079c:	704c                	ld	a1,160(s0)
ffffffffc020079e:	00006517          	auipc	a0,0x6
ffffffffc02007a2:	65a50513          	addi	a0,a0,1626 # ffffffffc0206df8 <commands+0x6d0>
ffffffffc02007a6:	9e9ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02007aa:	744c                	ld	a1,168(s0)
ffffffffc02007ac:	00006517          	auipc	a0,0x6
ffffffffc02007b0:	66450513          	addi	a0,a0,1636 # ffffffffc0206e10 <commands+0x6e8>
ffffffffc02007b4:	9dbff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02007b8:	784c                	ld	a1,176(s0)
ffffffffc02007ba:	00006517          	auipc	a0,0x6
ffffffffc02007be:	66e50513          	addi	a0,a0,1646 # ffffffffc0206e28 <commands+0x700>
ffffffffc02007c2:	9cdff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007c6:	7c4c                	ld	a1,184(s0)
ffffffffc02007c8:	00006517          	auipc	a0,0x6
ffffffffc02007cc:	67850513          	addi	a0,a0,1656 # ffffffffc0206e40 <commands+0x718>
ffffffffc02007d0:	9bfff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007d4:	606c                	ld	a1,192(s0)
ffffffffc02007d6:	00006517          	auipc	a0,0x6
ffffffffc02007da:	68250513          	addi	a0,a0,1666 # ffffffffc0206e58 <commands+0x730>
ffffffffc02007de:	9b1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007e2:	646c                	ld	a1,200(s0)
ffffffffc02007e4:	00006517          	auipc	a0,0x6
ffffffffc02007e8:	68c50513          	addi	a0,a0,1676 # ffffffffc0206e70 <commands+0x748>
ffffffffc02007ec:	9a3ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007f0:	686c                	ld	a1,208(s0)
ffffffffc02007f2:	00006517          	auipc	a0,0x6
ffffffffc02007f6:	69650513          	addi	a0,a0,1686 # ffffffffc0206e88 <commands+0x760>
ffffffffc02007fa:	995ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200800:	00006517          	auipc	a0,0x6
ffffffffc0200804:	6a050513          	addi	a0,a0,1696 # ffffffffc0206ea0 <commands+0x778>
ffffffffc0200808:	987ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020080c:	706c                	ld	a1,224(s0)
ffffffffc020080e:	00006517          	auipc	a0,0x6
ffffffffc0200812:	6aa50513          	addi	a0,a0,1706 # ffffffffc0206eb8 <commands+0x790>
ffffffffc0200816:	979ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020081a:	746c                	ld	a1,232(s0)
ffffffffc020081c:	00006517          	auipc	a0,0x6
ffffffffc0200820:	6b450513          	addi	a0,a0,1716 # ffffffffc0206ed0 <commands+0x7a8>
ffffffffc0200824:	96bff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200828:	786c                	ld	a1,240(s0)
ffffffffc020082a:	00006517          	auipc	a0,0x6
ffffffffc020082e:	6be50513          	addi	a0,a0,1726 # ffffffffc0206ee8 <commands+0x7c0>
ffffffffc0200832:	95dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200836:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200838:	6402                	ld	s0,0(sp)
ffffffffc020083a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020083c:	00006517          	auipc	a0,0x6
ffffffffc0200840:	6c450513          	addi	a0,a0,1732 # ffffffffc0206f00 <commands+0x7d8>
}
ffffffffc0200844:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200846:	949ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc020084a <print_trapframe>:
{
ffffffffc020084a:	1141                	addi	sp,sp,-16
ffffffffc020084c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020084e:	85aa                	mv	a1,a0
{
ffffffffc0200850:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200852:	00006517          	auipc	a0,0x6
ffffffffc0200856:	6c650513          	addi	a0,a0,1734 # ffffffffc0206f18 <commands+0x7f0>
{
ffffffffc020085a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020085c:	933ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200860:	8522                	mv	a0,s0
ffffffffc0200862:	e1bff0ef          	jal	ra,ffffffffc020067c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200866:	10043583          	ld	a1,256(s0)
ffffffffc020086a:	00006517          	auipc	a0,0x6
ffffffffc020086e:	6c650513          	addi	a0,a0,1734 # ffffffffc0206f30 <commands+0x808>
ffffffffc0200872:	91dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200876:	10843583          	ld	a1,264(s0)
ffffffffc020087a:	00006517          	auipc	a0,0x6
ffffffffc020087e:	6ce50513          	addi	a0,a0,1742 # ffffffffc0206f48 <commands+0x820>
ffffffffc0200882:	90dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200886:	11043583          	ld	a1,272(s0)
ffffffffc020088a:	00006517          	auipc	a0,0x6
ffffffffc020088e:	6d650513          	addi	a0,a0,1750 # ffffffffc0206f60 <commands+0x838>
ffffffffc0200892:	8fdff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200896:	11843583          	ld	a1,280(s0)
}
ffffffffc020089a:	6402                	ld	s0,0(sp)
ffffffffc020089c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020089e:	00006517          	auipc	a0,0x6
ffffffffc02008a2:	6d250513          	addi	a0,a0,1746 # ffffffffc0206f70 <commands+0x848>
}
ffffffffc02008a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02008a8:	8e7ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc02008ac <pgfault_handler>:
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int
pgfault_handler(struct trapframe *tf)
{
ffffffffc02008ac:	1101                	addi	sp,sp,-32
ffffffffc02008ae:	e426                	sd	s1,8(sp)
    extern struct mm_struct *check_mm_struct;
    if (check_mm_struct != NULL)
ffffffffc02008b0:	000ac497          	auipc	s1,0xac
ffffffffc02008b4:	d3848493          	addi	s1,s1,-712 # ffffffffc02ac5e8 <check_mm_struct>
ffffffffc02008b8:	609c                	ld	a5,0(s1)
{
ffffffffc02008ba:	e822                	sd	s0,16(sp)
ffffffffc02008bc:	ec06                	sd	ra,24(sp)
ffffffffc02008be:	842a                	mv	s0,a0
    if (check_mm_struct != NULL)
ffffffffc02008c0:	cbbd                	beqz	a5,ffffffffc0200936 <pgfault_handler+0x8a>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008c2:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008c6:	11053583          	ld	a1,272(a0)
ffffffffc02008ca:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ce:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008d2:	cba1                	beqz	a5,ffffffffc0200922 <pgfault_handler+0x76>
ffffffffc02008d4:	11843703          	ld	a4,280(s0)
ffffffffc02008d8:	47bd                	li	a5,15
ffffffffc02008da:	05700693          	li	a3,87
ffffffffc02008de:	00f70463          	beq	a4,a5,ffffffffc02008e6 <pgfault_handler+0x3a>
ffffffffc02008e2:	05200693          	li	a3,82
ffffffffc02008e6:	00006517          	auipc	a0,0x6
ffffffffc02008ea:	2b250513          	addi	a0,a0,690 # ffffffffc0206b98 <commands+0x470>
ffffffffc02008ee:	8a1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    { // used for test check_swap
        print_pgfault(tf);
    }
    struct mm_struct *mm;
    if (check_mm_struct != NULL)
ffffffffc02008f2:	6088                	ld	a0,0(s1)
ffffffffc02008f4:	c129                	beqz	a0,ffffffffc0200936 <pgfault_handler+0x8a>
    {
        assert(current == idleproc);
ffffffffc02008f6:	000ac797          	auipc	a5,0xac
ffffffffc02008fa:	bba78793          	addi	a5,a5,-1094 # ffffffffc02ac4b0 <current>
ffffffffc02008fe:	6398                	ld	a4,0(a5)
ffffffffc0200900:	000ac797          	auipc	a5,0xac
ffffffffc0200904:	bb878793          	addi	a5,a5,-1096 # ffffffffc02ac4b8 <idleproc>
ffffffffc0200908:	639c                	ld	a5,0(a5)
ffffffffc020090a:	04f71763          	bne	a4,a5,ffffffffc0200958 <pgfault_handler+0xac>
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        mm = current->mm;
    }
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020090e:	11043603          	ld	a2,272(s0)
ffffffffc0200912:	11843583          	ld	a1,280(s0)
}
ffffffffc0200916:	6442                	ld	s0,16(sp)
ffffffffc0200918:	60e2                	ld	ra,24(sp)
ffffffffc020091a:	64a2                	ld	s1,8(sp)
ffffffffc020091c:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020091e:	0820406f          	j	ffffffffc02049a0 <do_pgfault>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200922:	11843703          	ld	a4,280(s0)
ffffffffc0200926:	47bd                	li	a5,15
ffffffffc0200928:	05500613          	li	a2,85
ffffffffc020092c:	05700693          	li	a3,87
ffffffffc0200930:	faf719e3          	bne	a4,a5,ffffffffc02008e2 <pgfault_handler+0x36>
ffffffffc0200934:	bf4d                	j	ffffffffc02008e6 <pgfault_handler+0x3a>
        if (current == NULL)
ffffffffc0200936:	000ac797          	auipc	a5,0xac
ffffffffc020093a:	b7a78793          	addi	a5,a5,-1158 # ffffffffc02ac4b0 <current>
ffffffffc020093e:	639c                	ld	a5,0(a5)
ffffffffc0200940:	cf85                	beqz	a5,ffffffffc0200978 <pgfault_handler+0xcc>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200942:	11043603          	ld	a2,272(s0)
ffffffffc0200946:	11843583          	ld	a1,280(s0)
}
ffffffffc020094a:	6442                	ld	s0,16(sp)
ffffffffc020094c:	60e2                	ld	ra,24(sp)
ffffffffc020094e:	64a2                	ld	s1,8(sp)
        mm = current->mm;
ffffffffc0200950:	7788                	ld	a0,40(a5)
}
ffffffffc0200952:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200954:	04c0406f          	j	ffffffffc02049a0 <do_pgfault>
        assert(current == idleproc);
ffffffffc0200958:	00006697          	auipc	a3,0x6
ffffffffc020095c:	26068693          	addi	a3,a3,608 # ffffffffc0206bb8 <commands+0x490>
ffffffffc0200960:	00006617          	auipc	a2,0x6
ffffffffc0200964:	27060613          	addi	a2,a2,624 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0200968:	07200593          	li	a1,114
ffffffffc020096c:	00006517          	auipc	a0,0x6
ffffffffc0200970:	27c50513          	addi	a0,a0,636 # ffffffffc0206be8 <commands+0x4c0>
ffffffffc0200974:	b11ff0ef          	jal	ra,ffffffffc0200484 <__panic>
            print_trapframe(tf);
ffffffffc0200978:	8522                	mv	a0,s0
ffffffffc020097a:	ed1ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020097e:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200982:	11043583          	ld	a1,272(s0)
ffffffffc0200986:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020098a:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc020098e:	e399                	bnez	a5,ffffffffc0200994 <pgfault_handler+0xe8>
ffffffffc0200990:	05500613          	li	a2,85
ffffffffc0200994:	11843703          	ld	a4,280(s0)
ffffffffc0200998:	47bd                	li	a5,15
ffffffffc020099a:	02f70663          	beq	a4,a5,ffffffffc02009c6 <pgfault_handler+0x11a>
ffffffffc020099e:	05200693          	li	a3,82
ffffffffc02009a2:	00006517          	auipc	a0,0x6
ffffffffc02009a6:	1f650513          	addi	a0,a0,502 # ffffffffc0206b98 <commands+0x470>
ffffffffc02009aa:	fe4ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            panic("unhandled page fault.\n");
ffffffffc02009ae:	00006617          	auipc	a2,0x6
ffffffffc02009b2:	25260613          	addi	a2,a2,594 # ffffffffc0206c00 <commands+0x4d8>
ffffffffc02009b6:	07b00593          	li	a1,123
ffffffffc02009ba:	00006517          	auipc	a0,0x6
ffffffffc02009be:	22e50513          	addi	a0,a0,558 # ffffffffc0206be8 <commands+0x4c0>
ffffffffc02009c2:	ac3ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02009c6:	05700693          	li	a3,87
ffffffffc02009ca:	bfe1                	j	ffffffffc02009a2 <pgfault_handler+0xf6>

ffffffffc02009cc <interrupt_handler>:
static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02009cc:	11853783          	ld	a5,280(a0)
ffffffffc02009d0:	577d                	li	a4,-1
ffffffffc02009d2:	8305                	srli	a4,a4,0x1
ffffffffc02009d4:	8ff9                	and	a5,a5,a4
    switch (cause)
ffffffffc02009d6:	472d                	li	a4,11
ffffffffc02009d8:	08f76763          	bltu	a4,a5,ffffffffc0200a66 <interrupt_handler+0x9a>
ffffffffc02009dc:	00006717          	auipc	a4,0x6
ffffffffc02009e0:	f2870713          	addi	a4,a4,-216 # ffffffffc0206904 <commands+0x1dc>
ffffffffc02009e4:	078a                	slli	a5,a5,0x2
ffffffffc02009e6:	97ba                	add	a5,a5,a4
ffffffffc02009e8:	439c                	lw	a5,0(a5)
ffffffffc02009ea:	97ba                	add	a5,a5,a4
ffffffffc02009ec:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc02009ee:	00006517          	auipc	a0,0x6
ffffffffc02009f2:	16a50513          	addi	a0,a0,362 # ffffffffc0206b58 <commands+0x430>
ffffffffc02009f6:	f98ff06f          	j	ffffffffc020018e <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc02009fa:	00006517          	auipc	a0,0x6
ffffffffc02009fe:	13e50513          	addi	a0,a0,318 # ffffffffc0206b38 <commands+0x410>
ffffffffc0200a02:	f8cff06f          	j	ffffffffc020018e <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200a06:	00006517          	auipc	a0,0x6
ffffffffc0200a0a:	0f250513          	addi	a0,a0,242 # ffffffffc0206af8 <commands+0x3d0>
ffffffffc0200a0e:	f80ff06f          	j	ffffffffc020018e <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200a12:	00006517          	auipc	a0,0x6
ffffffffc0200a16:	10650513          	addi	a0,a0,262 # ffffffffc0206b18 <commands+0x3f0>
ffffffffc0200a1a:	f74ff06f          	j	ffffffffc020018e <cprintf>
        break;
    case IRQ_U_EXT:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_EXT:
        cprintf("Supervisor external interrupt\n");
ffffffffc0200a1e:	00006517          	auipc	a0,0x6
ffffffffc0200a22:	15a50513          	addi	a0,a0,346 # ffffffffc0206b78 <commands+0x450>
ffffffffc0200a26:	f68ff06f          	j	ffffffffc020018e <cprintf>
{
ffffffffc0200a2a:	1141                	addi	sp,sp,-16
ffffffffc0200a2c:	e406                	sd	ra,8(sp)
        clock_set_next_event();
ffffffffc0200a2e:	b3fff0ef          	jal	ra,ffffffffc020056c <clock_set_next_event>
        if (++ticks % TICK_NUM == 0 && current)
ffffffffc0200a32:	000ac797          	auipc	a5,0xac
ffffffffc0200a36:	a9e78793          	addi	a5,a5,-1378 # ffffffffc02ac4d0 <ticks>
ffffffffc0200a3a:	639c                	ld	a5,0(a5)
ffffffffc0200a3c:	06400713          	li	a4,100
ffffffffc0200a40:	0785                	addi	a5,a5,1
ffffffffc0200a42:	02e7f733          	remu	a4,a5,a4
ffffffffc0200a46:	000ac697          	auipc	a3,0xac
ffffffffc0200a4a:	a8f6b523          	sd	a5,-1398(a3) # ffffffffc02ac4d0 <ticks>
ffffffffc0200a4e:	eb09                	bnez	a4,ffffffffc0200a60 <interrupt_handler+0x94>
ffffffffc0200a50:	000ac797          	auipc	a5,0xac
ffffffffc0200a54:	a6078793          	addi	a5,a5,-1440 # ffffffffc02ac4b0 <current>
ffffffffc0200a58:	639c                	ld	a5,0(a5)
ffffffffc0200a5a:	c399                	beqz	a5,ffffffffc0200a60 <interrupt_handler+0x94>
            current->need_resched = 1;
ffffffffc0200a5c:	4705                	li	a4,1
ffffffffc0200a5e:	ef98                	sd	a4,24(a5)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200a60:	60a2                	ld	ra,8(sp)
ffffffffc0200a62:	0141                	addi	sp,sp,16
ffffffffc0200a64:	8082                	ret
        print_trapframe(tf);
ffffffffc0200a66:	de5ff06f          	j	ffffffffc020084a <print_trapframe>

ffffffffc0200a6a <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200a6a:	11853783          	ld	a5,280(a0)
ffffffffc0200a6e:	473d                	li	a4,15
ffffffffc0200a70:	1af76a63          	bltu	a4,a5,ffffffffc0200c24 <exception_handler+0x1ba>
ffffffffc0200a74:	00006717          	auipc	a4,0x6
ffffffffc0200a78:	ec070713          	addi	a4,a4,-320 # ffffffffc0206934 <commands+0x20c>
ffffffffc0200a7c:	078a                	slli	a5,a5,0x2
ffffffffc0200a7e:	97ba                	add	a5,a5,a4
ffffffffc0200a80:	439c                	lw	a5,0(a5)
{
ffffffffc0200a82:	1101                	addi	sp,sp,-32
ffffffffc0200a84:	e822                	sd	s0,16(sp)
ffffffffc0200a86:	ec06                	sd	ra,24(sp)
ffffffffc0200a88:	e426                	sd	s1,8(sp)
    switch (tf->cause)
ffffffffc0200a8a:	97ba                	add	a5,a5,a4
ffffffffc0200a8c:	842a                	mv	s0,a0
ffffffffc0200a8e:	8782                	jr	a5
            print_trapframe(tf);
            panic("handle pgfault failed. %e\n", ret);
        }
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200a90:	00006517          	auipc	a0,0x6
ffffffffc0200a94:	05050513          	addi	a0,a0,80 # ffffffffc0206ae0 <commands+0x3b8>
ffffffffc0200a98:	ef6ff0ef          	jal	ra,ffffffffc020018e <cprintf>
        if ((ret = pgfault_handler(tf)) != 0)
ffffffffc0200a9c:	8522                	mv	a0,s0
ffffffffc0200a9e:	e0fff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200aa2:	84aa                	mv	s1,a0
ffffffffc0200aa4:	18051263          	bnez	a0,ffffffffc0200c28 <exception_handler+0x1be>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200aa8:	60e2                	ld	ra,24(sp)
ffffffffc0200aaa:	6442                	ld	s0,16(sp)
ffffffffc0200aac:	64a2                	ld	s1,8(sp)
ffffffffc0200aae:	6105                	addi	sp,sp,32
ffffffffc0200ab0:	8082                	ret
        cprintf("Environment call from S-mode\n");
ffffffffc0200ab2:	00006517          	auipc	a0,0x6
ffffffffc0200ab6:	fb650513          	addi	a0,a0,-74 # ffffffffc0206a68 <commands+0x340>
ffffffffc0200aba:	ed4ff0ef          	jal	ra,ffffffffc020018e <cprintf>
        tf->epc += 4;
ffffffffc0200abe:	10843783          	ld	a5,264(s0)
}
ffffffffc0200ac2:	60e2                	ld	ra,24(sp)
ffffffffc0200ac4:	64a2                	ld	s1,8(sp)
        tf->epc += 4;
ffffffffc0200ac6:	0791                	addi	a5,a5,4
ffffffffc0200ac8:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200acc:	6442                	ld	s0,16(sp)
ffffffffc0200ace:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200ad0:	5ca0506f          	j	ffffffffc020609a <syscall>
        cprintf("Load page fault\n");
ffffffffc0200ad4:	00006517          	auipc	a0,0x6
ffffffffc0200ad8:	ff450513          	addi	a0,a0,-12 # ffffffffc0206ac8 <commands+0x3a0>
ffffffffc0200adc:	eb2ff0ef          	jal	ra,ffffffffc020018e <cprintf>
        if ((ret = pgfault_handler(tf)) != 0)
ffffffffc0200ae0:	8522                	mv	a0,s0
ffffffffc0200ae2:	dcbff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200ae6:	84aa                	mv	s1,a0
ffffffffc0200ae8:	d161                	beqz	a0,ffffffffc0200aa8 <exception_handler+0x3e>
            print_trapframe(tf);
ffffffffc0200aea:	8522                	mv	a0,s0
ffffffffc0200aec:	d5fff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
ffffffffc0200af0:	86a6                	mv	a3,s1
ffffffffc0200af2:	00006617          	auipc	a2,0x6
ffffffffc0200af6:	f2660613          	addi	a2,a2,-218 # ffffffffc0206a18 <commands+0x2f0>
ffffffffc0200afa:	10400593          	li	a1,260
ffffffffc0200afe:	00006517          	auipc	a0,0x6
ffffffffc0200b02:	0ea50513          	addi	a0,a0,234 # ffffffffc0206be8 <commands+0x4c0>
ffffffffc0200b06:	97fff0ef          	jal	ra,ffffffffc0200484 <__panic>
        cprintf("Instruction address misaligned\n");
ffffffffc0200b0a:	00006517          	auipc	a0,0x6
ffffffffc0200b0e:	e6e50513          	addi	a0,a0,-402 # ffffffffc0206978 <commands+0x250>
}
ffffffffc0200b12:	6442                	ld	s0,16(sp)
ffffffffc0200b14:	60e2                	ld	ra,24(sp)
ffffffffc0200b16:	64a2                	ld	s1,8(sp)
ffffffffc0200b18:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200b1a:	e74ff06f          	j	ffffffffc020018e <cprintf>
ffffffffc0200b1e:	00006517          	auipc	a0,0x6
ffffffffc0200b22:	e7a50513          	addi	a0,a0,-390 # ffffffffc0206998 <commands+0x270>
ffffffffc0200b26:	b7f5                	j	ffffffffc0200b12 <exception_handler+0xa8>
        cprintf("Illegal instruction\n");
ffffffffc0200b28:	00006517          	auipc	a0,0x6
ffffffffc0200b2c:	e9050513          	addi	a0,a0,-368 # ffffffffc02069b8 <commands+0x290>
ffffffffc0200b30:	b7cd                	j	ffffffffc0200b12 <exception_handler+0xa8>
        cprintf("Breakpoint\n");
ffffffffc0200b32:	00006517          	auipc	a0,0x6
ffffffffc0200b36:	e9e50513          	addi	a0,a0,-354 # ffffffffc02069d0 <commands+0x2a8>
ffffffffc0200b3a:	e54ff0ef          	jal	ra,ffffffffc020018e <cprintf>
        if (tf->gpr.a7 == 10) // kernel_execve处的ebreak前a7置10
ffffffffc0200b3e:	6458                	ld	a4,136(s0)
ffffffffc0200b40:	47a9                	li	a5,10
ffffffffc0200b42:	f6f713e3          	bne	a4,a5,ffffffffc0200aa8 <exception_handler+0x3e>
            tf->epc += 4; // 返回时执行ebreak的下一条指令
ffffffffc0200b46:	10843783          	ld	a5,264(s0)
ffffffffc0200b4a:	0791                	addi	a5,a5,4
ffffffffc0200b4c:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200b50:	54a050ef          	jal	ra,ffffffffc020609a <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200b54:	000ac797          	auipc	a5,0xac
ffffffffc0200b58:	95c78793          	addi	a5,a5,-1700 # ffffffffc02ac4b0 <current>
ffffffffc0200b5c:	639c                	ld	a5,0(a5)
ffffffffc0200b5e:	8522                	mv	a0,s0
}
ffffffffc0200b60:	6442                	ld	s0,16(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200b62:	6b9c                	ld	a5,16(a5)
}
ffffffffc0200b64:	60e2                	ld	ra,24(sp)
ffffffffc0200b66:	64a2                	ld	s1,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200b68:	6589                	lui	a1,0x2
ffffffffc0200b6a:	95be                	add	a1,a1,a5
}
ffffffffc0200b6c:	6105                	addi	sp,sp,32
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200b6e:	2380006f          	j	ffffffffc0200da6 <kernel_execve_ret>
        cprintf("Load address misaligned\n");
ffffffffc0200b72:	00006517          	auipc	a0,0x6
ffffffffc0200b76:	e6e50513          	addi	a0,a0,-402 # ffffffffc02069e0 <commands+0x2b8>
ffffffffc0200b7a:	bf61                	j	ffffffffc0200b12 <exception_handler+0xa8>
        cprintf("Load access fault\n");
ffffffffc0200b7c:	00006517          	auipc	a0,0x6
ffffffffc0200b80:	e8450513          	addi	a0,a0,-380 # ffffffffc0206a00 <commands+0x2d8>
ffffffffc0200b84:	e0aff0ef          	jal	ra,ffffffffc020018e <cprintf>
        if ((ret = pgfault_handler(tf)) != 0)
ffffffffc0200b88:	8522                	mv	a0,s0
ffffffffc0200b8a:	d23ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200b8e:	84aa                	mv	s1,a0
ffffffffc0200b90:	f0050ce3          	beqz	a0,ffffffffc0200aa8 <exception_handler+0x3e>
            print_trapframe(tf);
ffffffffc0200b94:	8522                	mv	a0,s0
ffffffffc0200b96:	cb5ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b9a:	86a6                	mv	a3,s1
ffffffffc0200b9c:	00006617          	auipc	a2,0x6
ffffffffc0200ba0:	e7c60613          	addi	a2,a2,-388 # ffffffffc0206a18 <commands+0x2f0>
ffffffffc0200ba4:	0dd00593          	li	a1,221
ffffffffc0200ba8:	00006517          	auipc	a0,0x6
ffffffffc0200bac:	04050513          	addi	a0,a0,64 # ffffffffc0206be8 <commands+0x4c0>
ffffffffc0200bb0:	8d5ff0ef          	jal	ra,ffffffffc0200484 <__panic>
        cprintf("Store/AMO access fault\n");
ffffffffc0200bb4:	00006517          	auipc	a0,0x6
ffffffffc0200bb8:	e9c50513          	addi	a0,a0,-356 # ffffffffc0206a50 <commands+0x328>
ffffffffc0200bbc:	dd2ff0ef          	jal	ra,ffffffffc020018e <cprintf>
        if ((ret = pgfault_handler(tf)) != 0)
ffffffffc0200bc0:	8522                	mv	a0,s0
ffffffffc0200bc2:	cebff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200bc6:	84aa                	mv	s1,a0
ffffffffc0200bc8:	ee0500e3          	beqz	a0,ffffffffc0200aa8 <exception_handler+0x3e>
            print_trapframe(tf);
ffffffffc0200bcc:	8522                	mv	a0,s0
ffffffffc0200bce:	c7dff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bd2:	86a6                	mv	a3,s1
ffffffffc0200bd4:	00006617          	auipc	a2,0x6
ffffffffc0200bd8:	e4460613          	addi	a2,a2,-444 # ffffffffc0206a18 <commands+0x2f0>
ffffffffc0200bdc:	0e800593          	li	a1,232
ffffffffc0200be0:	00006517          	auipc	a0,0x6
ffffffffc0200be4:	00850513          	addi	a0,a0,8 # ffffffffc0206be8 <commands+0x4c0>
ffffffffc0200be8:	89dff0ef          	jal	ra,ffffffffc0200484 <__panic>
        cprintf("Environment call from H-mode\n");
ffffffffc0200bec:	00006517          	auipc	a0,0x6
ffffffffc0200bf0:	e9c50513          	addi	a0,a0,-356 # ffffffffc0206a88 <commands+0x360>
ffffffffc0200bf4:	bf39                	j	ffffffffc0200b12 <exception_handler+0xa8>
        cprintf("Environment call from M-mode\n");
ffffffffc0200bf6:	00006517          	auipc	a0,0x6
ffffffffc0200bfa:	eb250513          	addi	a0,a0,-334 # ffffffffc0206aa8 <commands+0x380>
ffffffffc0200bfe:	bf11                	j	ffffffffc0200b12 <exception_handler+0xa8>
}
ffffffffc0200c00:	6442                	ld	s0,16(sp)
ffffffffc0200c02:	60e2                	ld	ra,24(sp)
ffffffffc0200c04:	64a2                	ld	s1,8(sp)
ffffffffc0200c06:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200c08:	c43ff06f          	j	ffffffffc020084a <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200c0c:	00006617          	auipc	a2,0x6
ffffffffc0200c10:	e2c60613          	addi	a2,a2,-468 # ffffffffc0206a38 <commands+0x310>
ffffffffc0200c14:	0e100593          	li	a1,225
ffffffffc0200c18:	00006517          	auipc	a0,0x6
ffffffffc0200c1c:	fd050513          	addi	a0,a0,-48 # ffffffffc0206be8 <commands+0x4c0>
ffffffffc0200c20:	865ff0ef          	jal	ra,ffffffffc0200484 <__panic>
        print_trapframe(tf);
ffffffffc0200c24:	c27ff06f          	j	ffffffffc020084a <print_trapframe>
            print_trapframe(tf);
ffffffffc0200c28:	8522                	mv	a0,s0
ffffffffc0200c2a:	c21ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
ffffffffc0200c2e:	86a6                	mv	a3,s1
ffffffffc0200c30:	00006617          	auipc	a2,0x6
ffffffffc0200c34:	de860613          	addi	a2,a2,-536 # ffffffffc0206a18 <commands+0x2f0>
ffffffffc0200c38:	10c00593          	li	a1,268
ffffffffc0200c3c:	00006517          	auipc	a0,0x6
ffffffffc0200c40:	fac50513          	addi	a0,a0,-84 # ffffffffc0206be8 <commands+0x4c0>
ffffffffc0200c44:	841ff0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0200c48 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200c48:	1101                	addi	sp,sp,-32
ffffffffc0200c4a:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200c4c:	000ac417          	auipc	s0,0xac
ffffffffc0200c50:	86440413          	addi	s0,s0,-1948 # ffffffffc02ac4b0 <current>
ffffffffc0200c54:	6018                	ld	a4,0(s0)
{
ffffffffc0200c56:	ec06                	sd	ra,24(sp)
ffffffffc0200c58:	e426                	sd	s1,8(sp)
ffffffffc0200c5a:	e04a                	sd	s2,0(sp)
ffffffffc0200c5c:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200c60:	cf1d                	beqz	a4,ffffffffc0200c9e <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c62:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200c66:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200c6a:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c6c:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200c70:	0206c463          	bltz	a3,ffffffffc0200c98 <trap+0x50>
        exception_handler(tf);
ffffffffc0200c74:	df7ff0ef          	jal	ra,ffffffffc0200a6a <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200c78:	601c                	ld	a5,0(s0)
ffffffffc0200c7a:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200c7e:	e499                	bnez	s1,ffffffffc0200c8c <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200c80:	0b07a703          	lw	a4,176(a5)
ffffffffc0200c84:	8b05                	andi	a4,a4,1
ffffffffc0200c86:	e339                	bnez	a4,ffffffffc0200ccc <trap+0x84>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200c88:	6f9c                	ld	a5,24(a5)
ffffffffc0200c8a:	eb95                	bnez	a5,ffffffffc0200cbe <trap+0x76>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200c8c:	60e2                	ld	ra,24(sp)
ffffffffc0200c8e:	6442                	ld	s0,16(sp)
ffffffffc0200c90:	64a2                	ld	s1,8(sp)
ffffffffc0200c92:	6902                	ld	s2,0(sp)
ffffffffc0200c94:	6105                	addi	sp,sp,32
ffffffffc0200c96:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200c98:	d35ff0ef          	jal	ra,ffffffffc02009cc <interrupt_handler>
ffffffffc0200c9c:	bff1                	j	ffffffffc0200c78 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200c9e:	0006c963          	bltz	a3,ffffffffc0200cb0 <trap+0x68>
}
ffffffffc0200ca2:	6442                	ld	s0,16(sp)
ffffffffc0200ca4:	60e2                	ld	ra,24(sp)
ffffffffc0200ca6:	64a2                	ld	s1,8(sp)
ffffffffc0200ca8:	6902                	ld	s2,0(sp)
ffffffffc0200caa:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200cac:	dbfff06f          	j	ffffffffc0200a6a <exception_handler>
}
ffffffffc0200cb0:	6442                	ld	s0,16(sp)
ffffffffc0200cb2:	60e2                	ld	ra,24(sp)
ffffffffc0200cb4:	64a2                	ld	s1,8(sp)
ffffffffc0200cb6:	6902                	ld	s2,0(sp)
ffffffffc0200cb8:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200cba:	d13ff06f          	j	ffffffffc02009cc <interrupt_handler>
}
ffffffffc0200cbe:	6442                	ld	s0,16(sp)
ffffffffc0200cc0:	60e2                	ld	ra,24(sp)
ffffffffc0200cc2:	64a2                	ld	s1,8(sp)
ffffffffc0200cc4:	6902                	ld	s2,0(sp)
ffffffffc0200cc6:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200cc8:	2dc0506f          	j	ffffffffc0205fa4 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200ccc:	555d                	li	a0,-9
ffffffffc0200cce:	6d0040ef          	jal	ra,ffffffffc020539e <do_exit>
ffffffffc0200cd2:	601c                	ld	a5,0(s0)
ffffffffc0200cd4:	bf55                	j	ffffffffc0200c88 <trap+0x40>
	...

ffffffffc0200cd8 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200cd8:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200cdc:	00011463          	bnez	sp,ffffffffc0200ce4 <__alltraps+0xc>
ffffffffc0200ce0:	14002173          	csrr	sp,sscratch
ffffffffc0200ce4:	712d                	addi	sp,sp,-288
ffffffffc0200ce6:	e002                	sd	zero,0(sp)
ffffffffc0200ce8:	e406                	sd	ra,8(sp)
ffffffffc0200cea:	ec0e                	sd	gp,24(sp)
ffffffffc0200cec:	f012                	sd	tp,32(sp)
ffffffffc0200cee:	f416                	sd	t0,40(sp)
ffffffffc0200cf0:	f81a                	sd	t1,48(sp)
ffffffffc0200cf2:	fc1e                	sd	t2,56(sp)
ffffffffc0200cf4:	e0a2                	sd	s0,64(sp)
ffffffffc0200cf6:	e4a6                	sd	s1,72(sp)
ffffffffc0200cf8:	e8aa                	sd	a0,80(sp)
ffffffffc0200cfa:	ecae                	sd	a1,88(sp)
ffffffffc0200cfc:	f0b2                	sd	a2,96(sp)
ffffffffc0200cfe:	f4b6                	sd	a3,104(sp)
ffffffffc0200d00:	f8ba                	sd	a4,112(sp)
ffffffffc0200d02:	fcbe                	sd	a5,120(sp)
ffffffffc0200d04:	e142                	sd	a6,128(sp)
ffffffffc0200d06:	e546                	sd	a7,136(sp)
ffffffffc0200d08:	e94a                	sd	s2,144(sp)
ffffffffc0200d0a:	ed4e                	sd	s3,152(sp)
ffffffffc0200d0c:	f152                	sd	s4,160(sp)
ffffffffc0200d0e:	f556                	sd	s5,168(sp)
ffffffffc0200d10:	f95a                	sd	s6,176(sp)
ffffffffc0200d12:	fd5e                	sd	s7,184(sp)
ffffffffc0200d14:	e1e2                	sd	s8,192(sp)
ffffffffc0200d16:	e5e6                	sd	s9,200(sp)
ffffffffc0200d18:	e9ea                	sd	s10,208(sp)
ffffffffc0200d1a:	edee                	sd	s11,216(sp)
ffffffffc0200d1c:	f1f2                	sd	t3,224(sp)
ffffffffc0200d1e:	f5f6                	sd	t4,232(sp)
ffffffffc0200d20:	f9fa                	sd	t5,240(sp)
ffffffffc0200d22:	fdfe                	sd	t6,248(sp)
ffffffffc0200d24:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200d28:	100024f3          	csrr	s1,sstatus
ffffffffc0200d2c:	14102973          	csrr	s2,sepc
ffffffffc0200d30:	143029f3          	csrr	s3,stval
ffffffffc0200d34:	14202a73          	csrr	s4,scause
ffffffffc0200d38:	e822                	sd	s0,16(sp)
ffffffffc0200d3a:	e226                	sd	s1,256(sp)
ffffffffc0200d3c:	e64a                	sd	s2,264(sp)
ffffffffc0200d3e:	ea4e                	sd	s3,272(sp)
ffffffffc0200d40:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d42:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d44:	f05ff0ef          	jal	ra,ffffffffc0200c48 <trap>

ffffffffc0200d48 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d48:	6492                	ld	s1,256(sp)
ffffffffc0200d4a:	6932                	ld	s2,264(sp)
ffffffffc0200d4c:	1004f413          	andi	s0,s1,256
ffffffffc0200d50:	e401                	bnez	s0,ffffffffc0200d58 <__trapret+0x10>
ffffffffc0200d52:	1200                	addi	s0,sp,288
ffffffffc0200d54:	14041073          	csrw	sscratch,s0
ffffffffc0200d58:	10049073          	csrw	sstatus,s1
ffffffffc0200d5c:	14191073          	csrw	sepc,s2
ffffffffc0200d60:	60a2                	ld	ra,8(sp)
ffffffffc0200d62:	61e2                	ld	gp,24(sp)
ffffffffc0200d64:	7202                	ld	tp,32(sp)
ffffffffc0200d66:	72a2                	ld	t0,40(sp)
ffffffffc0200d68:	7342                	ld	t1,48(sp)
ffffffffc0200d6a:	73e2                	ld	t2,56(sp)
ffffffffc0200d6c:	6406                	ld	s0,64(sp)
ffffffffc0200d6e:	64a6                	ld	s1,72(sp)
ffffffffc0200d70:	6546                	ld	a0,80(sp)
ffffffffc0200d72:	65e6                	ld	a1,88(sp)
ffffffffc0200d74:	7606                	ld	a2,96(sp)
ffffffffc0200d76:	76a6                	ld	a3,104(sp)
ffffffffc0200d78:	7746                	ld	a4,112(sp)
ffffffffc0200d7a:	77e6                	ld	a5,120(sp)
ffffffffc0200d7c:	680a                	ld	a6,128(sp)
ffffffffc0200d7e:	68aa                	ld	a7,136(sp)
ffffffffc0200d80:	694a                	ld	s2,144(sp)
ffffffffc0200d82:	69ea                	ld	s3,152(sp)
ffffffffc0200d84:	7a0a                	ld	s4,160(sp)
ffffffffc0200d86:	7aaa                	ld	s5,168(sp)
ffffffffc0200d88:	7b4a                	ld	s6,176(sp)
ffffffffc0200d8a:	7bea                	ld	s7,184(sp)
ffffffffc0200d8c:	6c0e                	ld	s8,192(sp)
ffffffffc0200d8e:	6cae                	ld	s9,200(sp)
ffffffffc0200d90:	6d4e                	ld	s10,208(sp)
ffffffffc0200d92:	6dee                	ld	s11,216(sp)
ffffffffc0200d94:	7e0e                	ld	t3,224(sp)
ffffffffc0200d96:	7eae                	ld	t4,232(sp)
ffffffffc0200d98:	7f4e                	ld	t5,240(sp)
ffffffffc0200d9a:	7fee                	ld	t6,248(sp)
ffffffffc0200d9c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200d9e:	10200073          	sret

ffffffffc0200da2 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200da2:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200da4:	b755                	j	ffffffffc0200d48 <__trapret>

ffffffffc0200da6 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200da6:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x76a0>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200daa:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200dae:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200db2:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200db6:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200dba:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200dbe:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200dc2:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200dc6:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200dca:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200dcc:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200dce:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200dd0:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200dd2:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200dd4:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200dd6:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200dd8:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200dda:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200ddc:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200dde:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200de0:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200de2:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200de4:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200de6:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200de8:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200dea:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200dec:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200dee:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200df0:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200df2:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200df4:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200df6:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200df8:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200dfa:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200dfc:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200dfe:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200e00:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200e02:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200e04:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200e06:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200e08:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200e0a:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200e0c:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200e0e:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200e10:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200e12:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200e14:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200e16:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200e18:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200e1a:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200e1c:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200e1e:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200e20:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200e22:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200e24:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200e26:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200e28:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200e2a:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200e2c:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200e2e:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200e30:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200e32:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200e34:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200e36:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200e38:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200e3a:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200e3c:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200e3e:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200e40:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200e42:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200e44:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200e46:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200e48:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200e4a:	812e                	mv	sp,a1
ffffffffc0200e4c:	bdf5                	j	ffffffffc0200d48 <__trapret>

ffffffffc0200e4e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e4e:	000ab797          	auipc	a5,0xab
ffffffffc0200e52:	68a78793          	addi	a5,a5,1674 # ffffffffc02ac4d8 <free_area>
ffffffffc0200e56:	e79c                	sd	a5,8(a5)
ffffffffc0200e58:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e5a:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e5e:	8082                	ret

ffffffffc0200e60 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200e60:	000ab517          	auipc	a0,0xab
ffffffffc0200e64:	68856503          	lwu	a0,1672(a0) # ffffffffc02ac4e8 <free_area+0x10>
ffffffffc0200e68:	8082                	ret

ffffffffc0200e6a <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200e6a:	715d                	addi	sp,sp,-80
ffffffffc0200e6c:	f84a                	sd	s2,48(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e6e:	000ab917          	auipc	s2,0xab
ffffffffc0200e72:	66a90913          	addi	s2,s2,1642 # ffffffffc02ac4d8 <free_area>
ffffffffc0200e76:	00893783          	ld	a5,8(s2)
ffffffffc0200e7a:	e486                	sd	ra,72(sp)
ffffffffc0200e7c:	e0a2                	sd	s0,64(sp)
ffffffffc0200e7e:	fc26                	sd	s1,56(sp)
ffffffffc0200e80:	f44e                	sd	s3,40(sp)
ffffffffc0200e82:	f052                	sd	s4,32(sp)
ffffffffc0200e84:	ec56                	sd	s5,24(sp)
ffffffffc0200e86:	e85a                	sd	s6,16(sp)
ffffffffc0200e88:	e45e                	sd	s7,8(sp)
ffffffffc0200e8a:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200e8c:	31278463          	beq	a5,s2,ffffffffc0201194 <default_check+0x32a>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e90:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200e94:	8305                	srli	a4,a4,0x1
ffffffffc0200e96:	8b05                	andi	a4,a4,1
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200e98:	30070263          	beqz	a4,ffffffffc020119c <default_check+0x332>
    int count = 0, total = 0;
ffffffffc0200e9c:	4401                	li	s0,0
ffffffffc0200e9e:	4481                	li	s1,0
ffffffffc0200ea0:	a031                	j	ffffffffc0200eac <default_check+0x42>
ffffffffc0200ea2:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0200ea6:	8b09                	andi	a4,a4,2
ffffffffc0200ea8:	2e070a63          	beqz	a4,ffffffffc020119c <default_check+0x332>
        count++, total += p->property;
ffffffffc0200eac:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200eb0:	679c                	ld	a5,8(a5)
ffffffffc0200eb2:	2485                	addiw	s1,s1,1
ffffffffc0200eb4:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200eb6:	ff2796e3          	bne	a5,s2,ffffffffc0200ea2 <default_check+0x38>
ffffffffc0200eba:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0200ebc:	05c010ef          	jal	ra,ffffffffc0201f18 <nr_free_pages>
ffffffffc0200ec0:	73351e63          	bne	a0,s3,ffffffffc02015fc <default_check+0x792>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ec4:	4505                	li	a0,1
ffffffffc0200ec6:	785000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0200eca:	8a2a                	mv	s4,a0
ffffffffc0200ecc:	46050863          	beqz	a0,ffffffffc020133c <default_check+0x4d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ed0:	4505                	li	a0,1
ffffffffc0200ed2:	779000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0200ed6:	89aa                	mv	s3,a0
ffffffffc0200ed8:	74050263          	beqz	a0,ffffffffc020161c <default_check+0x7b2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200edc:	4505                	li	a0,1
ffffffffc0200ede:	76d000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0200ee2:	8aaa                	mv	s5,a0
ffffffffc0200ee4:	4c050c63          	beqz	a0,ffffffffc02013bc <default_check+0x552>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ee8:	2d3a0a63          	beq	s4,s3,ffffffffc02011bc <default_check+0x352>
ffffffffc0200eec:	2caa0863          	beq	s4,a0,ffffffffc02011bc <default_check+0x352>
ffffffffc0200ef0:	2ca98663          	beq	s3,a0,ffffffffc02011bc <default_check+0x352>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ef4:	000a2783          	lw	a5,0(s4)
ffffffffc0200ef8:	2e079263          	bnez	a5,ffffffffc02011dc <default_check+0x372>
ffffffffc0200efc:	0009a783          	lw	a5,0(s3)
ffffffffc0200f00:	2c079e63          	bnez	a5,ffffffffc02011dc <default_check+0x372>
ffffffffc0200f04:	411c                	lw	a5,0(a0)
ffffffffc0200f06:	2c079b63          	bnez	a5,ffffffffc02011dc <default_check+0x372>
extern size_t npage;
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page) {
    return page - pages + nbase;
ffffffffc0200f0a:	000ab797          	auipc	a5,0xab
ffffffffc0200f0e:	5fe78793          	addi	a5,a5,1534 # ffffffffc02ac508 <pages>
ffffffffc0200f12:	639c                	ld	a5,0(a5)
ffffffffc0200f14:	00008717          	auipc	a4,0x8
ffffffffc0200f18:	e1c70713          	addi	a4,a4,-484 # ffffffffc0208d30 <nbase>
ffffffffc0200f1c:	6310                	ld	a2,0(a4)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f1e:	000ab717          	auipc	a4,0xab
ffffffffc0200f22:	57a70713          	addi	a4,a4,1402 # ffffffffc02ac498 <npage>
ffffffffc0200f26:	6314                	ld	a3,0(a4)
ffffffffc0200f28:	40fa0733          	sub	a4,s4,a5
ffffffffc0200f2c:	8719                	srai	a4,a4,0x6
ffffffffc0200f2e:	9732                	add	a4,a4,a2
ffffffffc0200f30:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f32:	0732                	slli	a4,a4,0xc
ffffffffc0200f34:	2cd77463          	bleu	a3,a4,ffffffffc02011fc <default_check+0x392>
    return page - pages + nbase;
ffffffffc0200f38:	40f98733          	sub	a4,s3,a5
ffffffffc0200f3c:	8719                	srai	a4,a4,0x6
ffffffffc0200f3e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f40:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f42:	4ed77d63          	bleu	a3,a4,ffffffffc020143c <default_check+0x5d2>
    return page - pages + nbase;
ffffffffc0200f46:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f4a:	8799                	srai	a5,a5,0x6
ffffffffc0200f4c:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f4e:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f50:	34d7f663          	bleu	a3,a5,ffffffffc020129c <default_check+0x432>
    assert(alloc_page() == NULL);
ffffffffc0200f54:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f56:	00093c03          	ld	s8,0(s2)
ffffffffc0200f5a:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f5e:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200f62:	000ab797          	auipc	a5,0xab
ffffffffc0200f66:	5727bf23          	sd	s2,1406(a5) # ffffffffc02ac4e0 <free_area+0x8>
ffffffffc0200f6a:	000ab797          	auipc	a5,0xab
ffffffffc0200f6e:	5727b723          	sd	s2,1390(a5) # ffffffffc02ac4d8 <free_area>
    nr_free = 0;
ffffffffc0200f72:	000ab797          	auipc	a5,0xab
ffffffffc0200f76:	5607ab23          	sw	zero,1398(a5) # ffffffffc02ac4e8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f7a:	6d1000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0200f7e:	2e051f63          	bnez	a0,ffffffffc020127c <default_check+0x412>
    free_page(p0);
ffffffffc0200f82:	4585                	li	a1,1
ffffffffc0200f84:	8552                	mv	a0,s4
ffffffffc0200f86:	74d000ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    free_page(p1);
ffffffffc0200f8a:	4585                	li	a1,1
ffffffffc0200f8c:	854e                	mv	a0,s3
ffffffffc0200f8e:	745000ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    free_page(p2);
ffffffffc0200f92:	4585                	li	a1,1
ffffffffc0200f94:	8556                	mv	a0,s5
ffffffffc0200f96:	73d000ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    assert(nr_free == 3);
ffffffffc0200f9a:	01092703          	lw	a4,16(s2)
ffffffffc0200f9e:	478d                	li	a5,3
ffffffffc0200fa0:	2af71e63          	bne	a4,a5,ffffffffc020125c <default_check+0x3f2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fa4:	4505                	li	a0,1
ffffffffc0200fa6:	6a5000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0200faa:	89aa                	mv	s3,a0
ffffffffc0200fac:	28050863          	beqz	a0,ffffffffc020123c <default_check+0x3d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fb0:	4505                	li	a0,1
ffffffffc0200fb2:	699000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0200fb6:	8aaa                	mv	s5,a0
ffffffffc0200fb8:	3e050263          	beqz	a0,ffffffffc020139c <default_check+0x532>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fbc:	4505                	li	a0,1
ffffffffc0200fbe:	68d000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0200fc2:	8a2a                	mv	s4,a0
ffffffffc0200fc4:	3a050c63          	beqz	a0,ffffffffc020137c <default_check+0x512>
    assert(alloc_page() == NULL);
ffffffffc0200fc8:	4505                	li	a0,1
ffffffffc0200fca:	681000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0200fce:	38051763          	bnez	a0,ffffffffc020135c <default_check+0x4f2>
    free_page(p0);
ffffffffc0200fd2:	4585                	li	a1,1
ffffffffc0200fd4:	854e                	mv	a0,s3
ffffffffc0200fd6:	6fd000ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200fda:	00893783          	ld	a5,8(s2)
ffffffffc0200fde:	23278f63          	beq	a5,s2,ffffffffc020121c <default_check+0x3b2>
    assert((p = alloc_page()) == p0);
ffffffffc0200fe2:	4505                	li	a0,1
ffffffffc0200fe4:	667000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0200fe8:	32a99a63          	bne	s3,a0,ffffffffc020131c <default_check+0x4b2>
    assert(alloc_page() == NULL);
ffffffffc0200fec:	4505                	li	a0,1
ffffffffc0200fee:	65d000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0200ff2:	30051563          	bnez	a0,ffffffffc02012fc <default_check+0x492>
    assert(nr_free == 0);
ffffffffc0200ff6:	01092783          	lw	a5,16(s2)
ffffffffc0200ffa:	2e079163          	bnez	a5,ffffffffc02012dc <default_check+0x472>
    free_page(p);
ffffffffc0200ffe:	854e                	mv	a0,s3
ffffffffc0201000:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201002:	000ab797          	auipc	a5,0xab
ffffffffc0201006:	4d87bb23          	sd	s8,1238(a5) # ffffffffc02ac4d8 <free_area>
ffffffffc020100a:	000ab797          	auipc	a5,0xab
ffffffffc020100e:	4d77bb23          	sd	s7,1238(a5) # ffffffffc02ac4e0 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0201012:	000ab797          	auipc	a5,0xab
ffffffffc0201016:	4d67ab23          	sw	s6,1238(a5) # ffffffffc02ac4e8 <free_area+0x10>
    free_page(p);
ffffffffc020101a:	6b9000ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    free_page(p1);
ffffffffc020101e:	4585                	li	a1,1
ffffffffc0201020:	8556                	mv	a0,s5
ffffffffc0201022:	6b1000ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    free_page(p2);
ffffffffc0201026:	4585                	li	a1,1
ffffffffc0201028:	8552                	mv	a0,s4
ffffffffc020102a:	6a9000ef          	jal	ra,ffffffffc0201ed2 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020102e:	4515                	li	a0,5
ffffffffc0201030:	61b000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0201034:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201036:	28050363          	beqz	a0,ffffffffc02012bc <default_check+0x452>
ffffffffc020103a:	651c                	ld	a5,8(a0)
ffffffffc020103c:	8385                	srli	a5,a5,0x1
ffffffffc020103e:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201040:	54079e63          	bnez	a5,ffffffffc020159c <default_check+0x732>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201044:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201046:	00093b03          	ld	s6,0(s2)
ffffffffc020104a:	00893a83          	ld	s5,8(s2)
ffffffffc020104e:	000ab797          	auipc	a5,0xab
ffffffffc0201052:	4927b523          	sd	s2,1162(a5) # ffffffffc02ac4d8 <free_area>
ffffffffc0201056:	000ab797          	auipc	a5,0xab
ffffffffc020105a:	4927b523          	sd	s2,1162(a5) # ffffffffc02ac4e0 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc020105e:	5ed000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0201062:	50051d63          	bnez	a0,ffffffffc020157c <default_check+0x712>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201066:	08098a13          	addi	s4,s3,128
ffffffffc020106a:	8552                	mv	a0,s4
ffffffffc020106c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020106e:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc0201072:	000ab797          	auipc	a5,0xab
ffffffffc0201076:	4607ab23          	sw	zero,1142(a5) # ffffffffc02ac4e8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020107a:	659000ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020107e:	4511                	li	a0,4
ffffffffc0201080:	5cb000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0201084:	4c051c63          	bnez	a0,ffffffffc020155c <default_check+0x6f2>
ffffffffc0201088:	0889b783          	ld	a5,136(s3)
ffffffffc020108c:	8385                	srli	a5,a5,0x1
ffffffffc020108e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201090:	4a078663          	beqz	a5,ffffffffc020153c <default_check+0x6d2>
ffffffffc0201094:	0909a703          	lw	a4,144(s3)
ffffffffc0201098:	478d                	li	a5,3
ffffffffc020109a:	4af71163          	bne	a4,a5,ffffffffc020153c <default_check+0x6d2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020109e:	450d                	li	a0,3
ffffffffc02010a0:	5ab000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc02010a4:	8c2a                	mv	s8,a0
ffffffffc02010a6:	46050b63          	beqz	a0,ffffffffc020151c <default_check+0x6b2>
    assert(alloc_page() == NULL);
ffffffffc02010aa:	4505                	li	a0,1
ffffffffc02010ac:	59f000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc02010b0:	44051663          	bnez	a0,ffffffffc02014fc <default_check+0x692>
    assert(p0 + 2 == p1);
ffffffffc02010b4:	438a1463          	bne	s4,s8,ffffffffc02014dc <default_check+0x672>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010b8:	4585                	li	a1,1
ffffffffc02010ba:	854e                	mv	a0,s3
ffffffffc02010bc:	617000ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    free_pages(p1, 3);
ffffffffc02010c0:	458d                	li	a1,3
ffffffffc02010c2:	8552                	mv	a0,s4
ffffffffc02010c4:	60f000ef          	jal	ra,ffffffffc0201ed2 <free_pages>
ffffffffc02010c8:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02010cc:	04098c13          	addi	s8,s3,64
ffffffffc02010d0:	8385                	srli	a5,a5,0x1
ffffffffc02010d2:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010d4:	3e078463          	beqz	a5,ffffffffc02014bc <default_check+0x652>
ffffffffc02010d8:	0109a703          	lw	a4,16(s3)
ffffffffc02010dc:	4785                	li	a5,1
ffffffffc02010de:	3cf71f63          	bne	a4,a5,ffffffffc02014bc <default_check+0x652>
ffffffffc02010e2:	008a3783          	ld	a5,8(s4)
ffffffffc02010e6:	8385                	srli	a5,a5,0x1
ffffffffc02010e8:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02010ea:	3a078963          	beqz	a5,ffffffffc020149c <default_check+0x632>
ffffffffc02010ee:	010a2703          	lw	a4,16(s4)
ffffffffc02010f2:	478d                	li	a5,3
ffffffffc02010f4:	3af71463          	bne	a4,a5,ffffffffc020149c <default_check+0x632>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02010f8:	4505                	li	a0,1
ffffffffc02010fa:	551000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc02010fe:	36a99f63          	bne	s3,a0,ffffffffc020147c <default_check+0x612>
    free_page(p0);
ffffffffc0201102:	4585                	li	a1,1
ffffffffc0201104:	5cf000ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201108:	4509                	li	a0,2
ffffffffc020110a:	541000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc020110e:	34aa1763          	bne	s4,a0,ffffffffc020145c <default_check+0x5f2>

    free_pages(p0, 2);
ffffffffc0201112:	4589                	li	a1,2
ffffffffc0201114:	5bf000ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    free_page(p2);
ffffffffc0201118:	4585                	li	a1,1
ffffffffc020111a:	8562                	mv	a0,s8
ffffffffc020111c:	5b7000ef          	jal	ra,ffffffffc0201ed2 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201120:	4515                	li	a0,5
ffffffffc0201122:	529000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0201126:	89aa                	mv	s3,a0
ffffffffc0201128:	48050a63          	beqz	a0,ffffffffc02015bc <default_check+0x752>
    assert(alloc_page() == NULL);
ffffffffc020112c:	4505                	li	a0,1
ffffffffc020112e:	51d000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0201132:	2e051563          	bnez	a0,ffffffffc020141c <default_check+0x5b2>

    assert(nr_free == 0);
ffffffffc0201136:	01092783          	lw	a5,16(s2)
ffffffffc020113a:	2c079163          	bnez	a5,ffffffffc02013fc <default_check+0x592>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020113e:	4595                	li	a1,5
ffffffffc0201140:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201142:	000ab797          	auipc	a5,0xab
ffffffffc0201146:	3b77a323          	sw	s7,934(a5) # ffffffffc02ac4e8 <free_area+0x10>
    free_list = free_list_store;
ffffffffc020114a:	000ab797          	auipc	a5,0xab
ffffffffc020114e:	3967b723          	sd	s6,910(a5) # ffffffffc02ac4d8 <free_area>
ffffffffc0201152:	000ab797          	auipc	a5,0xab
ffffffffc0201156:	3957b723          	sd	s5,910(a5) # ffffffffc02ac4e0 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc020115a:	579000ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    return listelm->next;
ffffffffc020115e:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201162:	01278963          	beq	a5,s2,ffffffffc0201174 <default_check+0x30a>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201166:	ff87a703          	lw	a4,-8(a5)
ffffffffc020116a:	679c                	ld	a5,8(a5)
ffffffffc020116c:	34fd                	addiw	s1,s1,-1
ffffffffc020116e:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201170:	ff279be3          	bne	a5,s2,ffffffffc0201166 <default_check+0x2fc>
    }
    assert(count == 0);
ffffffffc0201174:	26049463          	bnez	s1,ffffffffc02013dc <default_check+0x572>
    assert(total == 0);
ffffffffc0201178:	46041263          	bnez	s0,ffffffffc02015dc <default_check+0x772>
}
ffffffffc020117c:	60a6                	ld	ra,72(sp)
ffffffffc020117e:	6406                	ld	s0,64(sp)
ffffffffc0201180:	74e2                	ld	s1,56(sp)
ffffffffc0201182:	7942                	ld	s2,48(sp)
ffffffffc0201184:	79a2                	ld	s3,40(sp)
ffffffffc0201186:	7a02                	ld	s4,32(sp)
ffffffffc0201188:	6ae2                	ld	s5,24(sp)
ffffffffc020118a:	6b42                	ld	s6,16(sp)
ffffffffc020118c:	6ba2                	ld	s7,8(sp)
ffffffffc020118e:	6c02                	ld	s8,0(sp)
ffffffffc0201190:	6161                	addi	sp,sp,80
ffffffffc0201192:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201194:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201196:	4401                	li	s0,0
ffffffffc0201198:	4481                	li	s1,0
ffffffffc020119a:	b30d                	j	ffffffffc0200ebc <default_check+0x52>
        assert(PageProperty(p));
ffffffffc020119c:	00006697          	auipc	a3,0x6
ffffffffc02011a0:	dec68693          	addi	a3,a3,-532 # ffffffffc0206f88 <commands+0x860>
ffffffffc02011a4:	00006617          	auipc	a2,0x6
ffffffffc02011a8:	a2c60613          	addi	a2,a2,-1492 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02011ac:	11100593          	li	a1,273
ffffffffc02011b0:	00006517          	auipc	a0,0x6
ffffffffc02011b4:	de850513          	addi	a0,a0,-536 # ffffffffc0206f98 <commands+0x870>
ffffffffc02011b8:	accff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02011bc:	00006697          	auipc	a3,0x6
ffffffffc02011c0:	e7468693          	addi	a3,a3,-396 # ffffffffc0207030 <commands+0x908>
ffffffffc02011c4:	00006617          	auipc	a2,0x6
ffffffffc02011c8:	a0c60613          	addi	a2,a2,-1524 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02011cc:	0dc00593          	li	a1,220
ffffffffc02011d0:	00006517          	auipc	a0,0x6
ffffffffc02011d4:	dc850513          	addi	a0,a0,-568 # ffffffffc0206f98 <commands+0x870>
ffffffffc02011d8:	aacff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011dc:	00006697          	auipc	a3,0x6
ffffffffc02011e0:	e7c68693          	addi	a3,a3,-388 # ffffffffc0207058 <commands+0x930>
ffffffffc02011e4:	00006617          	auipc	a2,0x6
ffffffffc02011e8:	9ec60613          	addi	a2,a2,-1556 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02011ec:	0dd00593          	li	a1,221
ffffffffc02011f0:	00006517          	auipc	a0,0x6
ffffffffc02011f4:	da850513          	addi	a0,a0,-600 # ffffffffc0206f98 <commands+0x870>
ffffffffc02011f8:	a8cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02011fc:	00006697          	auipc	a3,0x6
ffffffffc0201200:	e9c68693          	addi	a3,a3,-356 # ffffffffc0207098 <commands+0x970>
ffffffffc0201204:	00006617          	auipc	a2,0x6
ffffffffc0201208:	9cc60613          	addi	a2,a2,-1588 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020120c:	0df00593          	li	a1,223
ffffffffc0201210:	00006517          	auipc	a0,0x6
ffffffffc0201214:	d8850513          	addi	a0,a0,-632 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201218:	a6cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(!list_empty(&free_list));
ffffffffc020121c:	00006697          	auipc	a3,0x6
ffffffffc0201220:	f0468693          	addi	a3,a3,-252 # ffffffffc0207120 <commands+0x9f8>
ffffffffc0201224:	00006617          	auipc	a2,0x6
ffffffffc0201228:	9ac60613          	addi	a2,a2,-1620 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020122c:	0f800593          	li	a1,248
ffffffffc0201230:	00006517          	auipc	a0,0x6
ffffffffc0201234:	d6850513          	addi	a0,a0,-664 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201238:	a4cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020123c:	00006697          	auipc	a3,0x6
ffffffffc0201240:	d9468693          	addi	a3,a3,-620 # ffffffffc0206fd0 <commands+0x8a8>
ffffffffc0201244:	00006617          	auipc	a2,0x6
ffffffffc0201248:	98c60613          	addi	a2,a2,-1652 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020124c:	0f100593          	li	a1,241
ffffffffc0201250:	00006517          	auipc	a0,0x6
ffffffffc0201254:	d4850513          	addi	a0,a0,-696 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201258:	a2cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free == 3);
ffffffffc020125c:	00006697          	auipc	a3,0x6
ffffffffc0201260:	eb468693          	addi	a3,a3,-332 # ffffffffc0207110 <commands+0x9e8>
ffffffffc0201264:	00006617          	auipc	a2,0x6
ffffffffc0201268:	96c60613          	addi	a2,a2,-1684 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020126c:	0ef00593          	li	a1,239
ffffffffc0201270:	00006517          	auipc	a0,0x6
ffffffffc0201274:	d2850513          	addi	a0,a0,-728 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201278:	a0cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020127c:	00006697          	auipc	a3,0x6
ffffffffc0201280:	e7c68693          	addi	a3,a3,-388 # ffffffffc02070f8 <commands+0x9d0>
ffffffffc0201284:	00006617          	auipc	a2,0x6
ffffffffc0201288:	94c60613          	addi	a2,a2,-1716 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020128c:	0ea00593          	li	a1,234
ffffffffc0201290:	00006517          	auipc	a0,0x6
ffffffffc0201294:	d0850513          	addi	a0,a0,-760 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201298:	9ecff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020129c:	00006697          	auipc	a3,0x6
ffffffffc02012a0:	e3c68693          	addi	a3,a3,-452 # ffffffffc02070d8 <commands+0x9b0>
ffffffffc02012a4:	00006617          	auipc	a2,0x6
ffffffffc02012a8:	92c60613          	addi	a2,a2,-1748 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02012ac:	0e100593          	li	a1,225
ffffffffc02012b0:	00006517          	auipc	a0,0x6
ffffffffc02012b4:	ce850513          	addi	a0,a0,-792 # ffffffffc0206f98 <commands+0x870>
ffffffffc02012b8:	9ccff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(p0 != NULL);
ffffffffc02012bc:	00006697          	auipc	a3,0x6
ffffffffc02012c0:	eac68693          	addi	a3,a3,-340 # ffffffffc0207168 <commands+0xa40>
ffffffffc02012c4:	00006617          	auipc	a2,0x6
ffffffffc02012c8:	90c60613          	addi	a2,a2,-1780 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02012cc:	11900593          	li	a1,281
ffffffffc02012d0:	00006517          	auipc	a0,0x6
ffffffffc02012d4:	cc850513          	addi	a0,a0,-824 # ffffffffc0206f98 <commands+0x870>
ffffffffc02012d8:	9acff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free == 0);
ffffffffc02012dc:	00006697          	auipc	a3,0x6
ffffffffc02012e0:	e7c68693          	addi	a3,a3,-388 # ffffffffc0207158 <commands+0xa30>
ffffffffc02012e4:	00006617          	auipc	a2,0x6
ffffffffc02012e8:	8ec60613          	addi	a2,a2,-1812 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02012ec:	0fe00593          	li	a1,254
ffffffffc02012f0:	00006517          	auipc	a0,0x6
ffffffffc02012f4:	ca850513          	addi	a0,a0,-856 # ffffffffc0206f98 <commands+0x870>
ffffffffc02012f8:	98cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012fc:	00006697          	auipc	a3,0x6
ffffffffc0201300:	dfc68693          	addi	a3,a3,-516 # ffffffffc02070f8 <commands+0x9d0>
ffffffffc0201304:	00006617          	auipc	a2,0x6
ffffffffc0201308:	8cc60613          	addi	a2,a2,-1844 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020130c:	0fc00593          	li	a1,252
ffffffffc0201310:	00006517          	auipc	a0,0x6
ffffffffc0201314:	c8850513          	addi	a0,a0,-888 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201318:	96cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020131c:	00006697          	auipc	a3,0x6
ffffffffc0201320:	e1c68693          	addi	a3,a3,-484 # ffffffffc0207138 <commands+0xa10>
ffffffffc0201324:	00006617          	auipc	a2,0x6
ffffffffc0201328:	8ac60613          	addi	a2,a2,-1876 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020132c:	0fb00593          	li	a1,251
ffffffffc0201330:	00006517          	auipc	a0,0x6
ffffffffc0201334:	c6850513          	addi	a0,a0,-920 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201338:	94cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020133c:	00006697          	auipc	a3,0x6
ffffffffc0201340:	c9468693          	addi	a3,a3,-876 # ffffffffc0206fd0 <commands+0x8a8>
ffffffffc0201344:	00006617          	auipc	a2,0x6
ffffffffc0201348:	88c60613          	addi	a2,a2,-1908 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020134c:	0d800593          	li	a1,216
ffffffffc0201350:	00006517          	auipc	a0,0x6
ffffffffc0201354:	c4850513          	addi	a0,a0,-952 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201358:	92cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020135c:	00006697          	auipc	a3,0x6
ffffffffc0201360:	d9c68693          	addi	a3,a3,-612 # ffffffffc02070f8 <commands+0x9d0>
ffffffffc0201364:	00006617          	auipc	a2,0x6
ffffffffc0201368:	86c60613          	addi	a2,a2,-1940 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020136c:	0f500593          	li	a1,245
ffffffffc0201370:	00006517          	auipc	a0,0x6
ffffffffc0201374:	c2850513          	addi	a0,a0,-984 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201378:	90cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020137c:	00006697          	auipc	a3,0x6
ffffffffc0201380:	c9468693          	addi	a3,a3,-876 # ffffffffc0207010 <commands+0x8e8>
ffffffffc0201384:	00006617          	auipc	a2,0x6
ffffffffc0201388:	84c60613          	addi	a2,a2,-1972 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020138c:	0f300593          	li	a1,243
ffffffffc0201390:	00006517          	auipc	a0,0x6
ffffffffc0201394:	c0850513          	addi	a0,a0,-1016 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201398:	8ecff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020139c:	00006697          	auipc	a3,0x6
ffffffffc02013a0:	c5468693          	addi	a3,a3,-940 # ffffffffc0206ff0 <commands+0x8c8>
ffffffffc02013a4:	00006617          	auipc	a2,0x6
ffffffffc02013a8:	82c60613          	addi	a2,a2,-2004 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02013ac:	0f200593          	li	a1,242
ffffffffc02013b0:	00006517          	auipc	a0,0x6
ffffffffc02013b4:	be850513          	addi	a0,a0,-1048 # ffffffffc0206f98 <commands+0x870>
ffffffffc02013b8:	8ccff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013bc:	00006697          	auipc	a3,0x6
ffffffffc02013c0:	c5468693          	addi	a3,a3,-940 # ffffffffc0207010 <commands+0x8e8>
ffffffffc02013c4:	00006617          	auipc	a2,0x6
ffffffffc02013c8:	80c60613          	addi	a2,a2,-2036 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02013cc:	0da00593          	li	a1,218
ffffffffc02013d0:	00006517          	auipc	a0,0x6
ffffffffc02013d4:	bc850513          	addi	a0,a0,-1080 # ffffffffc0206f98 <commands+0x870>
ffffffffc02013d8:	8acff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(count == 0);
ffffffffc02013dc:	00006697          	auipc	a3,0x6
ffffffffc02013e0:	edc68693          	addi	a3,a3,-292 # ffffffffc02072b8 <commands+0xb90>
ffffffffc02013e4:	00005617          	auipc	a2,0x5
ffffffffc02013e8:	7ec60613          	addi	a2,a2,2028 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02013ec:	14700593          	li	a1,327
ffffffffc02013f0:	00006517          	auipc	a0,0x6
ffffffffc02013f4:	ba850513          	addi	a0,a0,-1112 # ffffffffc0206f98 <commands+0x870>
ffffffffc02013f8:	88cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free == 0);
ffffffffc02013fc:	00006697          	auipc	a3,0x6
ffffffffc0201400:	d5c68693          	addi	a3,a3,-676 # ffffffffc0207158 <commands+0xa30>
ffffffffc0201404:	00005617          	auipc	a2,0x5
ffffffffc0201408:	7cc60613          	addi	a2,a2,1996 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020140c:	13b00593          	li	a1,315
ffffffffc0201410:	00006517          	auipc	a0,0x6
ffffffffc0201414:	b8850513          	addi	a0,a0,-1144 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201418:	86cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020141c:	00006697          	auipc	a3,0x6
ffffffffc0201420:	cdc68693          	addi	a3,a3,-804 # ffffffffc02070f8 <commands+0x9d0>
ffffffffc0201424:	00005617          	auipc	a2,0x5
ffffffffc0201428:	7ac60613          	addi	a2,a2,1964 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020142c:	13900593          	li	a1,313
ffffffffc0201430:	00006517          	auipc	a0,0x6
ffffffffc0201434:	b6850513          	addi	a0,a0,-1176 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201438:	84cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020143c:	00006697          	auipc	a3,0x6
ffffffffc0201440:	c7c68693          	addi	a3,a3,-900 # ffffffffc02070b8 <commands+0x990>
ffffffffc0201444:	00005617          	auipc	a2,0x5
ffffffffc0201448:	78c60613          	addi	a2,a2,1932 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020144c:	0e000593          	li	a1,224
ffffffffc0201450:	00006517          	auipc	a0,0x6
ffffffffc0201454:	b4850513          	addi	a0,a0,-1208 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201458:	82cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020145c:	00006697          	auipc	a3,0x6
ffffffffc0201460:	e1c68693          	addi	a3,a3,-484 # ffffffffc0207278 <commands+0xb50>
ffffffffc0201464:	00005617          	auipc	a2,0x5
ffffffffc0201468:	76c60613          	addi	a2,a2,1900 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020146c:	13300593          	li	a1,307
ffffffffc0201470:	00006517          	auipc	a0,0x6
ffffffffc0201474:	b2850513          	addi	a0,a0,-1240 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201478:	80cff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020147c:	00006697          	auipc	a3,0x6
ffffffffc0201480:	ddc68693          	addi	a3,a3,-548 # ffffffffc0207258 <commands+0xb30>
ffffffffc0201484:	00005617          	auipc	a2,0x5
ffffffffc0201488:	74c60613          	addi	a2,a2,1868 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020148c:	13100593          	li	a1,305
ffffffffc0201490:	00006517          	auipc	a0,0x6
ffffffffc0201494:	b0850513          	addi	a0,a0,-1272 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201498:	fedfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020149c:	00006697          	auipc	a3,0x6
ffffffffc02014a0:	d9468693          	addi	a3,a3,-620 # ffffffffc0207230 <commands+0xb08>
ffffffffc02014a4:	00005617          	auipc	a2,0x5
ffffffffc02014a8:	72c60613          	addi	a2,a2,1836 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02014ac:	12f00593          	li	a1,303
ffffffffc02014b0:	00006517          	auipc	a0,0x6
ffffffffc02014b4:	ae850513          	addi	a0,a0,-1304 # ffffffffc0206f98 <commands+0x870>
ffffffffc02014b8:	fcdfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014bc:	00006697          	auipc	a3,0x6
ffffffffc02014c0:	d4c68693          	addi	a3,a3,-692 # ffffffffc0207208 <commands+0xae0>
ffffffffc02014c4:	00005617          	auipc	a2,0x5
ffffffffc02014c8:	70c60613          	addi	a2,a2,1804 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02014cc:	12e00593          	li	a1,302
ffffffffc02014d0:	00006517          	auipc	a0,0x6
ffffffffc02014d4:	ac850513          	addi	a0,a0,-1336 # ffffffffc0206f98 <commands+0x870>
ffffffffc02014d8:	fadfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02014dc:	00006697          	auipc	a3,0x6
ffffffffc02014e0:	d1c68693          	addi	a3,a3,-740 # ffffffffc02071f8 <commands+0xad0>
ffffffffc02014e4:	00005617          	auipc	a2,0x5
ffffffffc02014e8:	6ec60613          	addi	a2,a2,1772 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02014ec:	12900593          	li	a1,297
ffffffffc02014f0:	00006517          	auipc	a0,0x6
ffffffffc02014f4:	aa850513          	addi	a0,a0,-1368 # ffffffffc0206f98 <commands+0x870>
ffffffffc02014f8:	f8dfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014fc:	00006697          	auipc	a3,0x6
ffffffffc0201500:	bfc68693          	addi	a3,a3,-1028 # ffffffffc02070f8 <commands+0x9d0>
ffffffffc0201504:	00005617          	auipc	a2,0x5
ffffffffc0201508:	6cc60613          	addi	a2,a2,1740 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020150c:	12800593          	li	a1,296
ffffffffc0201510:	00006517          	auipc	a0,0x6
ffffffffc0201514:	a8850513          	addi	a0,a0,-1400 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201518:	f6dfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020151c:	00006697          	auipc	a3,0x6
ffffffffc0201520:	cbc68693          	addi	a3,a3,-836 # ffffffffc02071d8 <commands+0xab0>
ffffffffc0201524:	00005617          	auipc	a2,0x5
ffffffffc0201528:	6ac60613          	addi	a2,a2,1708 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020152c:	12700593          	li	a1,295
ffffffffc0201530:	00006517          	auipc	a0,0x6
ffffffffc0201534:	a6850513          	addi	a0,a0,-1432 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201538:	f4dfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020153c:	00006697          	auipc	a3,0x6
ffffffffc0201540:	c6c68693          	addi	a3,a3,-916 # ffffffffc02071a8 <commands+0xa80>
ffffffffc0201544:	00005617          	auipc	a2,0x5
ffffffffc0201548:	68c60613          	addi	a2,a2,1676 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020154c:	12600593          	li	a1,294
ffffffffc0201550:	00006517          	auipc	a0,0x6
ffffffffc0201554:	a4850513          	addi	a0,a0,-1464 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201558:	f2dfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020155c:	00006697          	auipc	a3,0x6
ffffffffc0201560:	c3468693          	addi	a3,a3,-972 # ffffffffc0207190 <commands+0xa68>
ffffffffc0201564:	00005617          	auipc	a2,0x5
ffffffffc0201568:	66c60613          	addi	a2,a2,1644 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020156c:	12500593          	li	a1,293
ffffffffc0201570:	00006517          	auipc	a0,0x6
ffffffffc0201574:	a2850513          	addi	a0,a0,-1496 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201578:	f0dfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020157c:	00006697          	auipc	a3,0x6
ffffffffc0201580:	b7c68693          	addi	a3,a3,-1156 # ffffffffc02070f8 <commands+0x9d0>
ffffffffc0201584:	00005617          	auipc	a2,0x5
ffffffffc0201588:	64c60613          	addi	a2,a2,1612 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020158c:	11f00593          	li	a1,287
ffffffffc0201590:	00006517          	auipc	a0,0x6
ffffffffc0201594:	a0850513          	addi	a0,a0,-1528 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201598:	eedfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(!PageProperty(p0));
ffffffffc020159c:	00006697          	auipc	a3,0x6
ffffffffc02015a0:	bdc68693          	addi	a3,a3,-1060 # ffffffffc0207178 <commands+0xa50>
ffffffffc02015a4:	00005617          	auipc	a2,0x5
ffffffffc02015a8:	62c60613          	addi	a2,a2,1580 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02015ac:	11a00593          	li	a1,282
ffffffffc02015b0:	00006517          	auipc	a0,0x6
ffffffffc02015b4:	9e850513          	addi	a0,a0,-1560 # ffffffffc0206f98 <commands+0x870>
ffffffffc02015b8:	ecdfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015bc:	00006697          	auipc	a3,0x6
ffffffffc02015c0:	cdc68693          	addi	a3,a3,-804 # ffffffffc0207298 <commands+0xb70>
ffffffffc02015c4:	00005617          	auipc	a2,0x5
ffffffffc02015c8:	60c60613          	addi	a2,a2,1548 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02015cc:	13800593          	li	a1,312
ffffffffc02015d0:	00006517          	auipc	a0,0x6
ffffffffc02015d4:	9c850513          	addi	a0,a0,-1592 # ffffffffc0206f98 <commands+0x870>
ffffffffc02015d8:	eadfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(total == 0);
ffffffffc02015dc:	00006697          	auipc	a3,0x6
ffffffffc02015e0:	cec68693          	addi	a3,a3,-788 # ffffffffc02072c8 <commands+0xba0>
ffffffffc02015e4:	00005617          	auipc	a2,0x5
ffffffffc02015e8:	5ec60613          	addi	a2,a2,1516 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02015ec:	14800593          	li	a1,328
ffffffffc02015f0:	00006517          	auipc	a0,0x6
ffffffffc02015f4:	9a850513          	addi	a0,a0,-1624 # ffffffffc0206f98 <commands+0x870>
ffffffffc02015f8:	e8dfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(total == nr_free_pages());
ffffffffc02015fc:	00006697          	auipc	a3,0x6
ffffffffc0201600:	9b468693          	addi	a3,a3,-1612 # ffffffffc0206fb0 <commands+0x888>
ffffffffc0201604:	00005617          	auipc	a2,0x5
ffffffffc0201608:	5cc60613          	addi	a2,a2,1484 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020160c:	11400593          	li	a1,276
ffffffffc0201610:	00006517          	auipc	a0,0x6
ffffffffc0201614:	98850513          	addi	a0,a0,-1656 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201618:	e6dfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020161c:	00006697          	auipc	a3,0x6
ffffffffc0201620:	9d468693          	addi	a3,a3,-1580 # ffffffffc0206ff0 <commands+0x8c8>
ffffffffc0201624:	00005617          	auipc	a2,0x5
ffffffffc0201628:	5ac60613          	addi	a2,a2,1452 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020162c:	0d900593          	li	a1,217
ffffffffc0201630:	00006517          	auipc	a0,0x6
ffffffffc0201634:	96850513          	addi	a0,a0,-1688 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201638:	e4dfe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020163c <default_free_pages>:
{
ffffffffc020163c:	1141                	addi	sp,sp,-16
ffffffffc020163e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201640:	16058e63          	beqz	a1,ffffffffc02017bc <default_free_pages+0x180>
    for (; p != base + n; p++)
ffffffffc0201644:	00659693          	slli	a3,a1,0x6
ffffffffc0201648:	96aa                	add	a3,a3,a0
ffffffffc020164a:	02d50d63          	beq	a0,a3,ffffffffc0201684 <default_free_pages+0x48>
ffffffffc020164e:	651c                	ld	a5,8(a0)
ffffffffc0201650:	8b85                	andi	a5,a5,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201652:	14079563          	bnez	a5,ffffffffc020179c <default_free_pages+0x160>
ffffffffc0201656:	651c                	ld	a5,8(a0)
ffffffffc0201658:	8385                	srli	a5,a5,0x1
ffffffffc020165a:	8b85                	andi	a5,a5,1
ffffffffc020165c:	14079063          	bnez	a5,ffffffffc020179c <default_free_pages+0x160>
ffffffffc0201660:	87aa                	mv	a5,a0
ffffffffc0201662:	a809                	j	ffffffffc0201674 <default_free_pages+0x38>
ffffffffc0201664:	6798                	ld	a4,8(a5)
ffffffffc0201666:	8b05                	andi	a4,a4,1
ffffffffc0201668:	12071a63          	bnez	a4,ffffffffc020179c <default_free_pages+0x160>
ffffffffc020166c:	6798                	ld	a4,8(a5)
ffffffffc020166e:	8b09                	andi	a4,a4,2
ffffffffc0201670:	12071663          	bnez	a4,ffffffffc020179c <default_free_pages+0x160>
        p->flags = 0;
ffffffffc0201674:	0007b423          	sd	zero,8(a5)
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc0201678:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc020167c:	04078793          	addi	a5,a5,64
ffffffffc0201680:	fed792e3          	bne	a5,a3,ffffffffc0201664 <default_free_pages+0x28>
    base->property = n;
ffffffffc0201684:	2581                	sext.w	a1,a1
ffffffffc0201686:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201688:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020168c:	4789                	li	a5,2
ffffffffc020168e:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201692:	000ab697          	auipc	a3,0xab
ffffffffc0201696:	e4668693          	addi	a3,a3,-442 # ffffffffc02ac4d8 <free_area>
ffffffffc020169a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020169c:	669c                	ld	a5,8(a3)
ffffffffc020169e:	9db9                	addw	a1,a1,a4
ffffffffc02016a0:	000ab717          	auipc	a4,0xab
ffffffffc02016a4:	e4b72423          	sw	a1,-440(a4) # ffffffffc02ac4e8 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc02016a8:	0cd78163          	beq	a5,a3,ffffffffc020176a <default_free_pages+0x12e>
            struct Page *page = le2page(le, page_link);
ffffffffc02016ac:	fe878713          	addi	a4,a5,-24
ffffffffc02016b0:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list))
ffffffffc02016b2:	4801                	li	a6,0
ffffffffc02016b4:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02016b8:	00e56a63          	bltu	a0,a4,ffffffffc02016cc <default_free_pages+0x90>
    return listelm->next;
ffffffffc02016bc:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02016be:	04d70f63          	beq	a4,a3,ffffffffc020171c <default_free_pages+0xe0>
        while ((le = list_next(le)) != &free_list)
ffffffffc02016c2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02016c4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02016c8:	fee57ae3          	bleu	a4,a0,ffffffffc02016bc <default_free_pages+0x80>
ffffffffc02016cc:	00080663          	beqz	a6,ffffffffc02016d8 <default_free_pages+0x9c>
ffffffffc02016d0:	000ab817          	auipc	a6,0xab
ffffffffc02016d4:	e0b83423          	sd	a1,-504(a6) # ffffffffc02ac4d8 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016d8:	638c                	ld	a1,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016da:	e390                	sd	a2,0(a5)
ffffffffc02016dc:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc02016de:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016e0:	ed0c                	sd	a1,24(a0)
    if (le != &free_list)
ffffffffc02016e2:	06d58a63          	beq	a1,a3,ffffffffc0201756 <default_free_pages+0x11a>
        if (p + p->property == base)
ffffffffc02016e6:	ff85a603          	lw	a2,-8(a1)
        p = le2page(le, page_link);
ffffffffc02016ea:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base)
ffffffffc02016ee:	02061793          	slli	a5,a2,0x20
ffffffffc02016f2:	83e9                	srli	a5,a5,0x1a
ffffffffc02016f4:	97ba                	add	a5,a5,a4
ffffffffc02016f6:	04f51b63          	bne	a0,a5,ffffffffc020174c <default_free_pages+0x110>
            p->property += base->property;
ffffffffc02016fa:	491c                	lw	a5,16(a0)
ffffffffc02016fc:	9e3d                	addw	a2,a2,a5
ffffffffc02016fe:	fec5ac23          	sw	a2,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201702:	57f5                	li	a5,-3
ffffffffc0201704:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201708:	01853803          	ld	a6,24(a0)
ffffffffc020170c:	7110                	ld	a2,32(a0)
            base = p;
ffffffffc020170e:	853a                	mv	a0,a4
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201710:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0201714:	659c                	ld	a5,8(a1)
ffffffffc0201716:	01063023          	sd	a6,0(a2)
ffffffffc020171a:	a815                	j	ffffffffc020174e <default_free_pages+0x112>
    prev->next = next->prev = elm;
ffffffffc020171c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020171e:	f114                	sd	a3,32(a0)
ffffffffc0201720:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201722:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201724:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201726:	00d70563          	beq	a4,a3,ffffffffc0201730 <default_free_pages+0xf4>
ffffffffc020172a:	4805                	li	a6,1
ffffffffc020172c:	87ba                	mv	a5,a4
ffffffffc020172e:	bf59                	j	ffffffffc02016c4 <default_free_pages+0x88>
ffffffffc0201730:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201732:	85be                	mv	a1,a5
    if (le != &free_list)
ffffffffc0201734:	00d78d63          	beq	a5,a3,ffffffffc020174e <default_free_pages+0x112>
        if (p + p->property == base)
ffffffffc0201738:	ff85a603          	lw	a2,-8(a1)
        p = le2page(le, page_link);
ffffffffc020173c:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base)
ffffffffc0201740:	02061793          	slli	a5,a2,0x20
ffffffffc0201744:	83e9                	srli	a5,a5,0x1a
ffffffffc0201746:	97ba                	add	a5,a5,a4
ffffffffc0201748:	faf509e3          	beq	a0,a5,ffffffffc02016fa <default_free_pages+0xbe>
ffffffffc020174c:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc020174e:	fe878713          	addi	a4,a5,-24
ffffffffc0201752:	00d78963          	beq	a5,a3,ffffffffc0201764 <default_free_pages+0x128>
        if (base + base->property == p)
ffffffffc0201756:	4910                	lw	a2,16(a0)
ffffffffc0201758:	02061693          	slli	a3,a2,0x20
ffffffffc020175c:	82e9                	srli	a3,a3,0x1a
ffffffffc020175e:	96aa                	add	a3,a3,a0
ffffffffc0201760:	00d70e63          	beq	a4,a3,ffffffffc020177c <default_free_pages+0x140>
}
ffffffffc0201764:	60a2                	ld	ra,8(sp)
ffffffffc0201766:	0141                	addi	sp,sp,16
ffffffffc0201768:	8082                	ret
ffffffffc020176a:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020176c:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201770:	e398                	sd	a4,0(a5)
ffffffffc0201772:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201774:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201776:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201778:	0141                	addi	sp,sp,16
ffffffffc020177a:	8082                	ret
            base->property += p->property;
ffffffffc020177c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201780:	ff078693          	addi	a3,a5,-16
ffffffffc0201784:	9e39                	addw	a2,a2,a4
ffffffffc0201786:	c910                	sw	a2,16(a0)
ffffffffc0201788:	5775                	li	a4,-3
ffffffffc020178a:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020178e:	6398                	ld	a4,0(a5)
ffffffffc0201790:	679c                	ld	a5,8(a5)
}
ffffffffc0201792:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201794:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201796:	e398                	sd	a4,0(a5)
ffffffffc0201798:	0141                	addi	sp,sp,16
ffffffffc020179a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020179c:	00006697          	auipc	a3,0x6
ffffffffc02017a0:	b3c68693          	addi	a3,a3,-1220 # ffffffffc02072d8 <commands+0xbb0>
ffffffffc02017a4:	00005617          	auipc	a2,0x5
ffffffffc02017a8:	42c60613          	addi	a2,a2,1068 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02017ac:	09500593          	li	a1,149
ffffffffc02017b0:	00005517          	auipc	a0,0x5
ffffffffc02017b4:	7e850513          	addi	a0,a0,2024 # ffffffffc0206f98 <commands+0x870>
ffffffffc02017b8:	ccdfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(n > 0);
ffffffffc02017bc:	00006697          	auipc	a3,0x6
ffffffffc02017c0:	b4468693          	addi	a3,a3,-1212 # ffffffffc0207300 <commands+0xbd8>
ffffffffc02017c4:	00005617          	auipc	a2,0x5
ffffffffc02017c8:	40c60613          	addi	a2,a2,1036 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02017cc:	09100593          	li	a1,145
ffffffffc02017d0:	00005517          	auipc	a0,0x5
ffffffffc02017d4:	7c850513          	addi	a0,a0,1992 # ffffffffc0206f98 <commands+0x870>
ffffffffc02017d8:	cadfe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02017dc <default_alloc_pages>:
    assert(n > 0);
ffffffffc02017dc:	c959                	beqz	a0,ffffffffc0201872 <default_alloc_pages+0x96>
    if (n > nr_free)
ffffffffc02017de:	000ab597          	auipc	a1,0xab
ffffffffc02017e2:	cfa58593          	addi	a1,a1,-774 # ffffffffc02ac4d8 <free_area>
ffffffffc02017e6:	0105a803          	lw	a6,16(a1)
ffffffffc02017ea:	862a                	mv	a2,a0
ffffffffc02017ec:	02081793          	slli	a5,a6,0x20
ffffffffc02017f0:	9381                	srli	a5,a5,0x20
ffffffffc02017f2:	00a7ee63          	bltu	a5,a0,ffffffffc020180e <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02017f6:	87ae                	mv	a5,a1
ffffffffc02017f8:	a801                	j	ffffffffc0201808 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02017fa:	ff87a703          	lw	a4,-8(a5)
ffffffffc02017fe:	02071693          	slli	a3,a4,0x20
ffffffffc0201802:	9281                	srli	a3,a3,0x20
ffffffffc0201804:	00c6f763          	bleu	a2,a3,ffffffffc0201812 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201808:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc020180a:	feb798e3          	bne	a5,a1,ffffffffc02017fa <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020180e:	4501                	li	a0,0
}
ffffffffc0201810:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc0201812:	fe878513          	addi	a0,a5,-24
    if (page != NULL)
ffffffffc0201816:	dd6d                	beqz	a0,ffffffffc0201810 <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc0201818:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020181c:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc0201820:	00060e1b          	sext.w	t3,a2
ffffffffc0201824:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201828:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc020182c:	02d67863          	bleu	a3,a2,ffffffffc020185c <default_alloc_pages+0x80>
            struct Page *p = page + n;
ffffffffc0201830:	061a                	slli	a2,a2,0x6
ffffffffc0201832:	962a                	add	a2,a2,a0
            p->property = page->property - n;
ffffffffc0201834:	41c7073b          	subw	a4,a4,t3
ffffffffc0201838:	ca18                	sw	a4,16(a2)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020183a:	00860693          	addi	a3,a2,8
ffffffffc020183e:	4709                	li	a4,2
ffffffffc0201840:	40e6b02f          	amoor.d	zero,a4,(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201844:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201848:	01860693          	addi	a3,a2,24
    prev->next = next->prev = elm;
ffffffffc020184c:	0105a803          	lw	a6,16(a1)
ffffffffc0201850:	e314                	sd	a3,0(a4)
ffffffffc0201852:	00d8b423          	sd	a3,8(a7)
    elm->next = next;
ffffffffc0201856:	f218                	sd	a4,32(a2)
    elm->prev = prev;
ffffffffc0201858:	01163c23          	sd	a7,24(a2)
        nr_free -= n;
ffffffffc020185c:	41c8083b          	subw	a6,a6,t3
ffffffffc0201860:	000ab717          	auipc	a4,0xab
ffffffffc0201864:	c9072423          	sw	a6,-888(a4) # ffffffffc02ac4e8 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201868:	5775                	li	a4,-3
ffffffffc020186a:	17c1                	addi	a5,a5,-16
ffffffffc020186c:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0201870:	8082                	ret
{
ffffffffc0201872:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201874:	00006697          	auipc	a3,0x6
ffffffffc0201878:	a8c68693          	addi	a3,a3,-1396 # ffffffffc0207300 <commands+0xbd8>
ffffffffc020187c:	00005617          	auipc	a2,0x5
ffffffffc0201880:	35460613          	addi	a2,a2,852 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0201884:	06d00593          	li	a1,109
ffffffffc0201888:	00005517          	auipc	a0,0x5
ffffffffc020188c:	71050513          	addi	a0,a0,1808 # ffffffffc0206f98 <commands+0x870>
{
ffffffffc0201890:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201892:	bf3fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201896 <default_init_memmap>:
{
ffffffffc0201896:	1141                	addi	sp,sp,-16
ffffffffc0201898:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020189a:	c1ed                	beqz	a1,ffffffffc020197c <default_init_memmap+0xe6>
    for (; p != base + n; p++)
ffffffffc020189c:	00659693          	slli	a3,a1,0x6
ffffffffc02018a0:	96aa                	add	a3,a3,a0
ffffffffc02018a2:	02d50463          	beq	a0,a3,ffffffffc02018ca <default_init_memmap+0x34>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02018a6:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc02018a8:	87aa                	mv	a5,a0
ffffffffc02018aa:	8b05                	andi	a4,a4,1
ffffffffc02018ac:	e709                	bnez	a4,ffffffffc02018b6 <default_init_memmap+0x20>
ffffffffc02018ae:	a07d                	j	ffffffffc020195c <default_init_memmap+0xc6>
ffffffffc02018b0:	6798                	ld	a4,8(a5)
ffffffffc02018b2:	8b05                	andi	a4,a4,1
ffffffffc02018b4:	c745                	beqz	a4,ffffffffc020195c <default_init_memmap+0xc6>
        p->flags = p->property = 0;
ffffffffc02018b6:	0007a823          	sw	zero,16(a5)
ffffffffc02018ba:	0007b423          	sd	zero,8(a5)
ffffffffc02018be:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02018c2:	04078793          	addi	a5,a5,64
ffffffffc02018c6:	fed795e3          	bne	a5,a3,ffffffffc02018b0 <default_init_memmap+0x1a>
    base->property = n;
ffffffffc02018ca:	2581                	sext.w	a1,a1
ffffffffc02018cc:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018ce:	4789                	li	a5,2
ffffffffc02018d0:	00850713          	addi	a4,a0,8
ffffffffc02018d4:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02018d8:	000ab697          	auipc	a3,0xab
ffffffffc02018dc:	c0068693          	addi	a3,a3,-1024 # ffffffffc02ac4d8 <free_area>
ffffffffc02018e0:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02018e2:	669c                	ld	a5,8(a3)
ffffffffc02018e4:	9db9                	addw	a1,a1,a4
ffffffffc02018e6:	000ab717          	auipc	a4,0xab
ffffffffc02018ea:	c0b72123          	sw	a1,-1022(a4) # ffffffffc02ac4e8 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc02018ee:	04d78a63          	beq	a5,a3,ffffffffc0201942 <default_init_memmap+0xac>
            struct Page *page = le2page(le, page_link);
ffffffffc02018f2:	fe878713          	addi	a4,a5,-24
ffffffffc02018f6:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list))
ffffffffc02018f8:	4801                	li	a6,0
ffffffffc02018fa:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02018fe:	00e56a63          	bltu	a0,a4,ffffffffc0201912 <default_init_memmap+0x7c>
    return listelm->next;
ffffffffc0201902:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201904:	02d70563          	beq	a4,a3,ffffffffc020192e <default_init_memmap+0x98>
        while ((le = list_next(le)) != &free_list)
ffffffffc0201908:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc020190a:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc020190e:	fee57ae3          	bleu	a4,a0,ffffffffc0201902 <default_init_memmap+0x6c>
ffffffffc0201912:	00080663          	beqz	a6,ffffffffc020191e <default_init_memmap+0x88>
ffffffffc0201916:	000ab717          	auipc	a4,0xab
ffffffffc020191a:	bcb73123          	sd	a1,-1086(a4) # ffffffffc02ac4d8 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc020191e:	6398                	ld	a4,0(a5)
}
ffffffffc0201920:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201922:	e390                	sd	a2,0(a5)
ffffffffc0201924:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201926:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201928:	ed18                	sd	a4,24(a0)
ffffffffc020192a:	0141                	addi	sp,sp,16
ffffffffc020192c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020192e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201930:	f114                	sd	a3,32(a0)
ffffffffc0201932:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201934:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201936:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201938:	00d70e63          	beq	a4,a3,ffffffffc0201954 <default_init_memmap+0xbe>
ffffffffc020193c:	4805                	li	a6,1
ffffffffc020193e:	87ba                	mv	a5,a4
ffffffffc0201940:	b7e9                	j	ffffffffc020190a <default_init_memmap+0x74>
}
ffffffffc0201942:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201944:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201948:	e398                	sd	a4,0(a5)
ffffffffc020194a:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020194c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020194e:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201950:	0141                	addi	sp,sp,16
ffffffffc0201952:	8082                	ret
ffffffffc0201954:	60a2                	ld	ra,8(sp)
ffffffffc0201956:	e290                	sd	a2,0(a3)
ffffffffc0201958:	0141                	addi	sp,sp,16
ffffffffc020195a:	8082                	ret
        assert(PageReserved(p));
ffffffffc020195c:	00006697          	auipc	a3,0x6
ffffffffc0201960:	9ac68693          	addi	a3,a3,-1620 # ffffffffc0207308 <commands+0xbe0>
ffffffffc0201964:	00005617          	auipc	a2,0x5
ffffffffc0201968:	26c60613          	addi	a2,a2,620 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020196c:	04c00593          	li	a1,76
ffffffffc0201970:	00005517          	auipc	a0,0x5
ffffffffc0201974:	62850513          	addi	a0,a0,1576 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201978:	b0dfe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(n > 0);
ffffffffc020197c:	00006697          	auipc	a3,0x6
ffffffffc0201980:	98468693          	addi	a3,a3,-1660 # ffffffffc0207300 <commands+0xbd8>
ffffffffc0201984:	00005617          	auipc	a2,0x5
ffffffffc0201988:	24c60613          	addi	a2,a2,588 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020198c:	04800593          	li	a1,72
ffffffffc0201990:	00005517          	auipc	a0,0x5
ffffffffc0201994:	60850513          	addi	a0,a0,1544 # ffffffffc0206f98 <commands+0x870>
ffffffffc0201998:	aedfe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020199c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc020199c:	c125                	beqz	a0,ffffffffc02019fc <slob_free+0x60>
		return;

	if (size)
ffffffffc020199e:	e1a5                	bnez	a1,ffffffffc02019fe <slob_free+0x62>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019a0:	100027f3          	csrr	a5,sstatus
ffffffffc02019a4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02019a6:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019a8:	e3bd                	bnez	a5,ffffffffc0201a0e <slob_free+0x72>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019aa:	0009f797          	auipc	a5,0x9f
ffffffffc02019ae:	6be78793          	addi	a5,a5,1726 # ffffffffc02a1068 <slobfree>
ffffffffc02019b2:	639c                	ld	a5,0(a5)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019b4:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019b6:	00a7fa63          	bleu	a0,a5,ffffffffc02019ca <slob_free+0x2e>
ffffffffc02019ba:	00e56c63          	bltu	a0,a4,ffffffffc02019d2 <slob_free+0x36>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019be:	00e7fa63          	bleu	a4,a5,ffffffffc02019d2 <slob_free+0x36>
    return 0;
ffffffffc02019c2:	87ba                	mv	a5,a4
ffffffffc02019c4:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019c6:	fea7eae3          	bltu	a5,a0,ffffffffc02019ba <slob_free+0x1e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019ca:	fee7ece3          	bltu	a5,a4,ffffffffc02019c2 <slob_free+0x26>
ffffffffc02019ce:	fee57ae3          	bleu	a4,a0,ffffffffc02019c2 <slob_free+0x26>
			break;

	if (b + b->units == cur->next) {
ffffffffc02019d2:	4110                	lw	a2,0(a0)
ffffffffc02019d4:	00461693          	slli	a3,a2,0x4
ffffffffc02019d8:	96aa                	add	a3,a3,a0
ffffffffc02019da:	08d70b63          	beq	a4,a3,ffffffffc0201a70 <slob_free+0xd4>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc02019de:	4394                	lw	a3,0(a5)
		b->next = cur->next;
ffffffffc02019e0:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc02019e2:	00469713          	slli	a4,a3,0x4
ffffffffc02019e6:	973e                	add	a4,a4,a5
ffffffffc02019e8:	08e50f63          	beq	a0,a4,ffffffffc0201a86 <slob_free+0xea>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc02019ec:	e788                	sd	a0,8(a5)

	slobfree = cur;
ffffffffc02019ee:	0009f717          	auipc	a4,0x9f
ffffffffc02019f2:	66f73d23          	sd	a5,1658(a4) # ffffffffc02a1068 <slobfree>
    if (flag) {
ffffffffc02019f6:	c199                	beqz	a1,ffffffffc02019fc <slob_free+0x60>
        intr_enable();
ffffffffc02019f8:	c5dfe06f          	j	ffffffffc0200654 <intr_enable>
ffffffffc02019fc:	8082                	ret
		b->units = SLOB_UNITS(size);
ffffffffc02019fe:	05bd                	addi	a1,a1,15
ffffffffc0201a00:	8191                	srli	a1,a1,0x4
ffffffffc0201a02:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a04:	100027f3          	csrr	a5,sstatus
ffffffffc0201a08:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a0a:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a0c:	dfd9                	beqz	a5,ffffffffc02019aa <slob_free+0xe>
{
ffffffffc0201a0e:	1101                	addi	sp,sp,-32
ffffffffc0201a10:	e42a                	sd	a0,8(sp)
ffffffffc0201a12:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201a14:	c47fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a18:	0009f797          	auipc	a5,0x9f
ffffffffc0201a1c:	65078793          	addi	a5,a5,1616 # ffffffffc02a1068 <slobfree>
ffffffffc0201a20:	639c                	ld	a5,0(a5)
        return 1;
ffffffffc0201a22:	6522                	ld	a0,8(sp)
ffffffffc0201a24:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a26:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a28:	00a7fa63          	bleu	a0,a5,ffffffffc0201a3c <slob_free+0xa0>
ffffffffc0201a2c:	00e56c63          	bltu	a0,a4,ffffffffc0201a44 <slob_free+0xa8>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a30:	00e7fa63          	bleu	a4,a5,ffffffffc0201a44 <slob_free+0xa8>
    return 0;
ffffffffc0201a34:	87ba                	mv	a5,a4
ffffffffc0201a36:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a38:	fea7eae3          	bltu	a5,a0,ffffffffc0201a2c <slob_free+0x90>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a3c:	fee7ece3          	bltu	a5,a4,ffffffffc0201a34 <slob_free+0x98>
ffffffffc0201a40:	fee57ae3          	bleu	a4,a0,ffffffffc0201a34 <slob_free+0x98>
	if (b + b->units == cur->next) {
ffffffffc0201a44:	4110                	lw	a2,0(a0)
ffffffffc0201a46:	00461693          	slli	a3,a2,0x4
ffffffffc0201a4a:	96aa                	add	a3,a3,a0
ffffffffc0201a4c:	04d70763          	beq	a4,a3,ffffffffc0201a9a <slob_free+0xfe>
		b->next = cur->next;
ffffffffc0201a50:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc0201a52:	4394                	lw	a3,0(a5)
ffffffffc0201a54:	00469713          	slli	a4,a3,0x4
ffffffffc0201a58:	973e                	add	a4,a4,a5
ffffffffc0201a5a:	04e50663          	beq	a0,a4,ffffffffc0201aa6 <slob_free+0x10a>
		cur->next = b;
ffffffffc0201a5e:	e788                	sd	a0,8(a5)
	slobfree = cur;
ffffffffc0201a60:	0009f717          	auipc	a4,0x9f
ffffffffc0201a64:	60f73423          	sd	a5,1544(a4) # ffffffffc02a1068 <slobfree>
    if (flag) {
ffffffffc0201a68:	e58d                	bnez	a1,ffffffffc0201a92 <slob_free+0xf6>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201a6a:	60e2                	ld	ra,24(sp)
ffffffffc0201a6c:	6105                	addi	sp,sp,32
ffffffffc0201a6e:	8082                	ret
		b->units += cur->next->units;
ffffffffc0201a70:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201a72:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc0201a74:	9e35                	addw	a2,a2,a3
ffffffffc0201a76:	c110                	sw	a2,0(a0)
	if (cur + cur->units == b) {
ffffffffc0201a78:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201a7a:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc0201a7c:	00469713          	slli	a4,a3,0x4
ffffffffc0201a80:	973e                	add	a4,a4,a5
ffffffffc0201a82:	f6e515e3          	bne	a0,a4,ffffffffc02019ec <slob_free+0x50>
		cur->units += b->units;
ffffffffc0201a86:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc0201a88:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc0201a8a:	9eb9                	addw	a3,a3,a4
ffffffffc0201a8c:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc0201a8e:	e790                	sd	a2,8(a5)
ffffffffc0201a90:	bfb9                	j	ffffffffc02019ee <slob_free+0x52>
}
ffffffffc0201a92:	60e2                	ld	ra,24(sp)
ffffffffc0201a94:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201a96:	bbffe06f          	j	ffffffffc0200654 <intr_enable>
		b->units += cur->next->units;
ffffffffc0201a9a:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201a9c:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc0201a9e:	9e35                	addw	a2,a2,a3
ffffffffc0201aa0:	c110                	sw	a2,0(a0)
		b->next = cur->next->next;
ffffffffc0201aa2:	e518                	sd	a4,8(a0)
ffffffffc0201aa4:	b77d                	j	ffffffffc0201a52 <slob_free+0xb6>
		cur->units += b->units;
ffffffffc0201aa6:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc0201aa8:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc0201aaa:	9eb9                	addw	a3,a3,a4
ffffffffc0201aac:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc0201aae:	e790                	sd	a2,8(a5)
ffffffffc0201ab0:	bf45                	j	ffffffffc0201a60 <slob_free+0xc4>

ffffffffc0201ab2 <__slob_get_free_pages.isra.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201ab2:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201ab4:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201ab6:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201aba:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201abc:	38e000ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
  if(!page)
ffffffffc0201ac0:	c139                	beqz	a0,ffffffffc0201b06 <__slob_get_free_pages.isra.0+0x54>
    return page - pages + nbase;
ffffffffc0201ac2:	000ab797          	auipc	a5,0xab
ffffffffc0201ac6:	a4678793          	addi	a5,a5,-1466 # ffffffffc02ac508 <pages>
ffffffffc0201aca:	6394                	ld	a3,0(a5)
ffffffffc0201acc:	00007797          	auipc	a5,0x7
ffffffffc0201ad0:	26478793          	addi	a5,a5,612 # ffffffffc0208d30 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201ad4:	000ab717          	auipc	a4,0xab
ffffffffc0201ad8:	9c470713          	addi	a4,a4,-1596 # ffffffffc02ac498 <npage>
    return page - pages + nbase;
ffffffffc0201adc:	40d506b3          	sub	a3,a0,a3
ffffffffc0201ae0:	6388                	ld	a0,0(a5)
ffffffffc0201ae2:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0201ae4:	57fd                	li	a5,-1
ffffffffc0201ae6:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc0201ae8:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc0201aea:	83b1                	srli	a5,a5,0xc
ffffffffc0201aec:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0201aee:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201af0:	00e7ff63          	bleu	a4,a5,ffffffffc0201b0e <__slob_get_free_pages.isra.0+0x5c>
ffffffffc0201af4:	000ab797          	auipc	a5,0xab
ffffffffc0201af8:	a0478793          	addi	a5,a5,-1532 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc0201afc:	6388                	ld	a0,0(a5)
}
ffffffffc0201afe:	60a2                	ld	ra,8(sp)
ffffffffc0201b00:	9536                	add	a0,a0,a3
ffffffffc0201b02:	0141                	addi	sp,sp,16
ffffffffc0201b04:	8082                	ret
ffffffffc0201b06:	60a2                	ld	ra,8(sp)
    return NULL;
ffffffffc0201b08:	4501                	li	a0,0
}
ffffffffc0201b0a:	0141                	addi	sp,sp,16
ffffffffc0201b0c:	8082                	ret
ffffffffc0201b0e:	00006617          	auipc	a2,0x6
ffffffffc0201b12:	85a60613          	addi	a2,a2,-1958 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc0201b16:	06900593          	li	a1,105
ffffffffc0201b1a:	00006517          	auipc	a0,0x6
ffffffffc0201b1e:	87650513          	addi	a0,a0,-1930 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0201b22:	963fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201b26 <slob_alloc.isra.1.constprop.3>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201b26:	7179                	addi	sp,sp,-48
ffffffffc0201b28:	f406                	sd	ra,40(sp)
ffffffffc0201b2a:	f022                	sd	s0,32(sp)
ffffffffc0201b2c:	ec26                	sd	s1,24(sp)
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201b2e:	01050713          	addi	a4,a0,16
ffffffffc0201b32:	6785                	lui	a5,0x1
ffffffffc0201b34:	0cf77b63          	bleu	a5,a4,ffffffffc0201c0a <slob_alloc.isra.1.constprop.3+0xe4>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201b38:	00f50413          	addi	s0,a0,15
ffffffffc0201b3c:	8011                	srli	s0,s0,0x4
ffffffffc0201b3e:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b40:	10002673          	csrr	a2,sstatus
ffffffffc0201b44:	8a09                	andi	a2,a2,2
ffffffffc0201b46:	ea5d                	bnez	a2,ffffffffc0201bfc <slob_alloc.isra.1.constprop.3+0xd6>
	prev = slobfree;
ffffffffc0201b48:	0009f497          	auipc	s1,0x9f
ffffffffc0201b4c:	52048493          	addi	s1,s1,1312 # ffffffffc02a1068 <slobfree>
ffffffffc0201b50:	6094                	ld	a3,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201b52:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201b54:	4398                	lw	a4,0(a5)
ffffffffc0201b56:	0a875763          	ble	s0,a4,ffffffffc0201c04 <slob_alloc.isra.1.constprop.3+0xde>
		if (cur == slobfree) {
ffffffffc0201b5a:	00f68a63          	beq	a3,a5,ffffffffc0201b6e <slob_alloc.isra.1.constprop.3+0x48>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201b5e:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201b60:	4118                	lw	a4,0(a0)
ffffffffc0201b62:	02875763          	ble	s0,a4,ffffffffc0201b90 <slob_alloc.isra.1.constprop.3+0x6a>
ffffffffc0201b66:	6094                	ld	a3,0(s1)
ffffffffc0201b68:	87aa                	mv	a5,a0
		if (cur == slobfree) {
ffffffffc0201b6a:	fef69ae3          	bne	a3,a5,ffffffffc0201b5e <slob_alloc.isra.1.constprop.3+0x38>
    if (flag) {
ffffffffc0201b6e:	ea39                	bnez	a2,ffffffffc0201bc4 <slob_alloc.isra.1.constprop.3+0x9e>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201b70:	4501                	li	a0,0
ffffffffc0201b72:	f41ff0ef          	jal	ra,ffffffffc0201ab2 <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc0201b76:	cd29                	beqz	a0,ffffffffc0201bd0 <slob_alloc.isra.1.constprop.3+0xaa>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201b78:	6585                	lui	a1,0x1
ffffffffc0201b7a:	e23ff0ef          	jal	ra,ffffffffc020199c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b7e:	10002673          	csrr	a2,sstatus
ffffffffc0201b82:	8a09                	andi	a2,a2,2
ffffffffc0201b84:	ea1d                	bnez	a2,ffffffffc0201bba <slob_alloc.isra.1.constprop.3+0x94>
			cur = slobfree;
ffffffffc0201b86:	609c                	ld	a5,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201b88:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201b8a:	4118                	lw	a4,0(a0)
ffffffffc0201b8c:	fc874de3          	blt	a4,s0,ffffffffc0201b66 <slob_alloc.isra.1.constprop.3+0x40>
			if (cur->units == units) /* exact fit? */
ffffffffc0201b90:	04e40663          	beq	s0,a4,ffffffffc0201bdc <slob_alloc.isra.1.constprop.3+0xb6>
				prev->next = cur + units;
ffffffffc0201b94:	00441693          	slli	a3,s0,0x4
ffffffffc0201b98:	96aa                	add	a3,a3,a0
ffffffffc0201b9a:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201b9c:	650c                	ld	a1,8(a0)
				prev->next->units = cur->units - units;
ffffffffc0201b9e:	9f01                	subw	a4,a4,s0
ffffffffc0201ba0:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201ba2:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201ba4:	c100                	sw	s0,0(a0)
			slobfree = prev;
ffffffffc0201ba6:	0009f717          	auipc	a4,0x9f
ffffffffc0201baa:	4cf73123          	sd	a5,1218(a4) # ffffffffc02a1068 <slobfree>
    if (flag) {
ffffffffc0201bae:	ee15                	bnez	a2,ffffffffc0201bea <slob_alloc.isra.1.constprop.3+0xc4>
}
ffffffffc0201bb0:	70a2                	ld	ra,40(sp)
ffffffffc0201bb2:	7402                	ld	s0,32(sp)
ffffffffc0201bb4:	64e2                	ld	s1,24(sp)
ffffffffc0201bb6:	6145                	addi	sp,sp,48
ffffffffc0201bb8:	8082                	ret
        intr_disable();
ffffffffc0201bba:	aa1fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc0201bbe:	4605                	li	a2,1
			cur = slobfree;
ffffffffc0201bc0:	609c                	ld	a5,0(s1)
ffffffffc0201bc2:	b7d9                	j	ffffffffc0201b88 <slob_alloc.isra.1.constprop.3+0x62>
        intr_enable();
ffffffffc0201bc4:	a91fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201bc8:	4501                	li	a0,0
ffffffffc0201bca:	ee9ff0ef          	jal	ra,ffffffffc0201ab2 <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc0201bce:	f54d                	bnez	a0,ffffffffc0201b78 <slob_alloc.isra.1.constprop.3+0x52>
}
ffffffffc0201bd0:	70a2                	ld	ra,40(sp)
ffffffffc0201bd2:	7402                	ld	s0,32(sp)
ffffffffc0201bd4:	64e2                	ld	s1,24(sp)
				return 0;
ffffffffc0201bd6:	4501                	li	a0,0
}
ffffffffc0201bd8:	6145                	addi	sp,sp,48
ffffffffc0201bda:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201bdc:	6518                	ld	a4,8(a0)
ffffffffc0201bde:	e798                	sd	a4,8(a5)
			slobfree = prev;
ffffffffc0201be0:	0009f717          	auipc	a4,0x9f
ffffffffc0201be4:	48f73423          	sd	a5,1160(a4) # ffffffffc02a1068 <slobfree>
    if (flag) {
ffffffffc0201be8:	d661                	beqz	a2,ffffffffc0201bb0 <slob_alloc.isra.1.constprop.3+0x8a>
ffffffffc0201bea:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201bec:	a69fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
}
ffffffffc0201bf0:	70a2                	ld	ra,40(sp)
ffffffffc0201bf2:	7402                	ld	s0,32(sp)
ffffffffc0201bf4:	6522                	ld	a0,8(sp)
ffffffffc0201bf6:	64e2                	ld	s1,24(sp)
ffffffffc0201bf8:	6145                	addi	sp,sp,48
ffffffffc0201bfa:	8082                	ret
        intr_disable();
ffffffffc0201bfc:	a5ffe0ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc0201c00:	4605                	li	a2,1
ffffffffc0201c02:	b799                	j	ffffffffc0201b48 <slob_alloc.isra.1.constprop.3+0x22>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201c04:	853e                	mv	a0,a5
ffffffffc0201c06:	87b6                	mv	a5,a3
ffffffffc0201c08:	b761                	j	ffffffffc0201b90 <slob_alloc.isra.1.constprop.3+0x6a>
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201c0a:	00005697          	auipc	a3,0x5
ffffffffc0201c0e:	7fe68693          	addi	a3,a3,2046 # ffffffffc0207408 <default_pmm_manager+0xf0>
ffffffffc0201c12:	00005617          	auipc	a2,0x5
ffffffffc0201c16:	fbe60613          	addi	a2,a2,-66 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0201c1a:	06400593          	li	a1,100
ffffffffc0201c1e:	00006517          	auipc	a0,0x6
ffffffffc0201c22:	80a50513          	addi	a0,a0,-2038 # ffffffffc0207428 <default_pmm_manager+0x110>
ffffffffc0201c26:	85ffe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201c2a <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0201c2a:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc0201c2c:	00006517          	auipc	a0,0x6
ffffffffc0201c30:	81450513          	addi	a0,a0,-2028 # ffffffffc0207440 <default_pmm_manager+0x128>
kmalloc_init(void) {
ffffffffc0201c34:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0201c36:	d58fe0ef          	jal	ra,ffffffffc020018e <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201c3a:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c3c:	00005517          	auipc	a0,0x5
ffffffffc0201c40:	7ac50513          	addi	a0,a0,1964 # ffffffffc02073e8 <default_pmm_manager+0xd0>
}
ffffffffc0201c44:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c46:	d48fe06f          	j	ffffffffc020018e <cprintf>

ffffffffc0201c4a <kallocated>:
}

size_t
kallocated(void) {
   return slob_allocated();
}
ffffffffc0201c4a:	4501                	li	a0,0
ffffffffc0201c4c:	8082                	ret

ffffffffc0201c4e <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201c4e:	1101                	addi	sp,sp,-32
ffffffffc0201c50:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201c52:	6905                	lui	s2,0x1
{
ffffffffc0201c54:	e822                	sd	s0,16(sp)
ffffffffc0201c56:	ec06                	sd	ra,24(sp)
ffffffffc0201c58:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201c5a:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8591>
{
ffffffffc0201c5e:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201c60:	04a7fc63          	bleu	a0,a5,ffffffffc0201cb8 <kmalloc+0x6a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201c64:	4561                	li	a0,24
ffffffffc0201c66:	ec1ff0ef          	jal	ra,ffffffffc0201b26 <slob_alloc.isra.1.constprop.3>
ffffffffc0201c6a:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201c6c:	cd21                	beqz	a0,ffffffffc0201cc4 <kmalloc+0x76>
	bb->order = find_order(size);
ffffffffc0201c6e:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201c72:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201c74:	00f95763          	ble	a5,s2,ffffffffc0201c82 <kmalloc+0x34>
ffffffffc0201c78:	6705                	lui	a4,0x1
ffffffffc0201c7a:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201c7c:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201c7e:	fef74ee3          	blt	a4,a5,ffffffffc0201c7a <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201c82:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201c84:	e2fff0ef          	jal	ra,ffffffffc0201ab2 <__slob_get_free_pages.isra.0>
ffffffffc0201c88:	e488                	sd	a0,8(s1)
ffffffffc0201c8a:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0201c8c:	c935                	beqz	a0,ffffffffc0201d00 <kmalloc+0xb2>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c8e:	100027f3          	csrr	a5,sstatus
ffffffffc0201c92:	8b89                	andi	a5,a5,2
ffffffffc0201c94:	e3a1                	bnez	a5,ffffffffc0201cd4 <kmalloc+0x86>
		bb->next = bigblocks;
ffffffffc0201c96:	000aa797          	auipc	a5,0xaa
ffffffffc0201c9a:	7f278793          	addi	a5,a5,2034 # ffffffffc02ac488 <bigblocks>
ffffffffc0201c9e:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0201ca0:	000aa717          	auipc	a4,0xaa
ffffffffc0201ca4:	7e973423          	sd	s1,2024(a4) # ffffffffc02ac488 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201ca8:	e89c                	sd	a5,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0201caa:	8522                	mv	a0,s0
ffffffffc0201cac:	60e2                	ld	ra,24(sp)
ffffffffc0201cae:	6442                	ld	s0,16(sp)
ffffffffc0201cb0:	64a2                	ld	s1,8(sp)
ffffffffc0201cb2:	6902                	ld	s2,0(sp)
ffffffffc0201cb4:	6105                	addi	sp,sp,32
ffffffffc0201cb6:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201cb8:	0541                	addi	a0,a0,16
ffffffffc0201cba:	e6dff0ef          	jal	ra,ffffffffc0201b26 <slob_alloc.isra.1.constprop.3>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201cbe:	01050413          	addi	s0,a0,16
ffffffffc0201cc2:	f565                	bnez	a0,ffffffffc0201caa <kmalloc+0x5c>
ffffffffc0201cc4:	4401                	li	s0,0
}
ffffffffc0201cc6:	8522                	mv	a0,s0
ffffffffc0201cc8:	60e2                	ld	ra,24(sp)
ffffffffc0201cca:	6442                	ld	s0,16(sp)
ffffffffc0201ccc:	64a2                	ld	s1,8(sp)
ffffffffc0201cce:	6902                	ld	s2,0(sp)
ffffffffc0201cd0:	6105                	addi	sp,sp,32
ffffffffc0201cd2:	8082                	ret
        intr_disable();
ffffffffc0201cd4:	987fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
		bb->next = bigblocks;
ffffffffc0201cd8:	000aa797          	auipc	a5,0xaa
ffffffffc0201cdc:	7b078793          	addi	a5,a5,1968 # ffffffffc02ac488 <bigblocks>
ffffffffc0201ce0:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0201ce2:	000aa717          	auipc	a4,0xaa
ffffffffc0201ce6:	7a973323          	sd	s1,1958(a4) # ffffffffc02ac488 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201cea:	e89c                	sd	a5,16(s1)
        intr_enable();
ffffffffc0201cec:	969fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201cf0:	6480                	ld	s0,8(s1)
}
ffffffffc0201cf2:	60e2                	ld	ra,24(sp)
ffffffffc0201cf4:	64a2                	ld	s1,8(sp)
ffffffffc0201cf6:	8522                	mv	a0,s0
ffffffffc0201cf8:	6442                	ld	s0,16(sp)
ffffffffc0201cfa:	6902                	ld	s2,0(sp)
ffffffffc0201cfc:	6105                	addi	sp,sp,32
ffffffffc0201cfe:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d00:	45e1                	li	a1,24
ffffffffc0201d02:	8526                	mv	a0,s1
ffffffffc0201d04:	c99ff0ef          	jal	ra,ffffffffc020199c <slob_free>
  return __kmalloc(size, 0);
ffffffffc0201d08:	b74d                	j	ffffffffc0201caa <kmalloc+0x5c>

ffffffffc0201d0a <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d0a:	c175                	beqz	a0,ffffffffc0201dee <kfree+0xe4>
{
ffffffffc0201d0c:	1101                	addi	sp,sp,-32
ffffffffc0201d0e:	e426                	sd	s1,8(sp)
ffffffffc0201d10:	ec06                	sd	ra,24(sp)
ffffffffc0201d12:	e822                	sd	s0,16(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0201d14:	03451793          	slli	a5,a0,0x34
ffffffffc0201d18:	84aa                	mv	s1,a0
ffffffffc0201d1a:	eb8d                	bnez	a5,ffffffffc0201d4c <kfree+0x42>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d1c:	100027f3          	csrr	a5,sstatus
ffffffffc0201d20:	8b89                	andi	a5,a5,2
ffffffffc0201d22:	efc9                	bnez	a5,ffffffffc0201dbc <kfree+0xb2>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201d24:	000aa797          	auipc	a5,0xaa
ffffffffc0201d28:	76478793          	addi	a5,a5,1892 # ffffffffc02ac488 <bigblocks>
ffffffffc0201d2c:	6394                	ld	a3,0(a5)
ffffffffc0201d2e:	ce99                	beqz	a3,ffffffffc0201d4c <kfree+0x42>
			if (bb->pages == block) {
ffffffffc0201d30:	669c                	ld	a5,8(a3)
ffffffffc0201d32:	6a80                	ld	s0,16(a3)
ffffffffc0201d34:	0af50e63          	beq	a0,a5,ffffffffc0201df0 <kfree+0xe6>
    return 0;
ffffffffc0201d38:	4601                	li	a2,0
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201d3a:	c801                	beqz	s0,ffffffffc0201d4a <kfree+0x40>
			if (bb->pages == block) {
ffffffffc0201d3c:	6418                	ld	a4,8(s0)
ffffffffc0201d3e:	681c                	ld	a5,16(s0)
ffffffffc0201d40:	00970f63          	beq	a4,s1,ffffffffc0201d5e <kfree+0x54>
ffffffffc0201d44:	86a2                	mv	a3,s0
ffffffffc0201d46:	843e                	mv	s0,a5
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201d48:	f875                	bnez	s0,ffffffffc0201d3c <kfree+0x32>
    if (flag) {
ffffffffc0201d4a:	e659                	bnez	a2,ffffffffc0201dd8 <kfree+0xce>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201d4c:	6442                	ld	s0,16(sp)
ffffffffc0201d4e:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d50:	ff048513          	addi	a0,s1,-16
}
ffffffffc0201d54:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d56:	4581                	li	a1,0
}
ffffffffc0201d58:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d5a:	c43ff06f          	j	ffffffffc020199c <slob_free>
				*last = bb->next;
ffffffffc0201d5e:	ea9c                	sd	a5,16(a3)
ffffffffc0201d60:	e641                	bnez	a2,ffffffffc0201de8 <kfree+0xde>
    return pa2page(PADDR(kva));
ffffffffc0201d62:	c02007b7          	lui	a5,0xc0200
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201d66:	4018                	lw	a4,0(s0)
ffffffffc0201d68:	08f4ea63          	bltu	s1,a5,ffffffffc0201dfc <kfree+0xf2>
ffffffffc0201d6c:	000aa797          	auipc	a5,0xaa
ffffffffc0201d70:	78c78793          	addi	a5,a5,1932 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc0201d74:	6394                	ld	a3,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0201d76:	000aa797          	auipc	a5,0xaa
ffffffffc0201d7a:	72278793          	addi	a5,a5,1826 # ffffffffc02ac498 <npage>
ffffffffc0201d7e:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0201d80:	8c95                	sub	s1,s1,a3
    if (PPN(pa) >= npage) {
ffffffffc0201d82:	80b1                	srli	s1,s1,0xc
ffffffffc0201d84:	08f4f963          	bleu	a5,s1,ffffffffc0201e16 <kfree+0x10c>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d88:	00007797          	auipc	a5,0x7
ffffffffc0201d8c:	fa878793          	addi	a5,a5,-88 # ffffffffc0208d30 <nbase>
ffffffffc0201d90:	639c                	ld	a5,0(a5)
ffffffffc0201d92:	000aa697          	auipc	a3,0xaa
ffffffffc0201d96:	77668693          	addi	a3,a3,1910 # ffffffffc02ac508 <pages>
ffffffffc0201d9a:	6288                	ld	a0,0(a3)
ffffffffc0201d9c:	8c9d                	sub	s1,s1,a5
ffffffffc0201d9e:	049a                	slli	s1,s1,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201da0:	4585                	li	a1,1
ffffffffc0201da2:	9526                	add	a0,a0,s1
ffffffffc0201da4:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201da8:	12a000ef          	jal	ra,ffffffffc0201ed2 <free_pages>
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dac:	8522                	mv	a0,s0
}
ffffffffc0201dae:	6442                	ld	s0,16(sp)
ffffffffc0201db0:	60e2                	ld	ra,24(sp)
ffffffffc0201db2:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201db4:	45e1                	li	a1,24
}
ffffffffc0201db6:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201db8:	be5ff06f          	j	ffffffffc020199c <slob_free>
        intr_disable();
ffffffffc0201dbc:	89ffe0ef          	jal	ra,ffffffffc020065a <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201dc0:	000aa797          	auipc	a5,0xaa
ffffffffc0201dc4:	6c878793          	addi	a5,a5,1736 # ffffffffc02ac488 <bigblocks>
ffffffffc0201dc8:	6394                	ld	a3,0(a5)
ffffffffc0201dca:	c699                	beqz	a3,ffffffffc0201dd8 <kfree+0xce>
			if (bb->pages == block) {
ffffffffc0201dcc:	669c                	ld	a5,8(a3)
ffffffffc0201dce:	6a80                	ld	s0,16(a3)
ffffffffc0201dd0:	00f48763          	beq	s1,a5,ffffffffc0201dde <kfree+0xd4>
        return 1;
ffffffffc0201dd4:	4605                	li	a2,1
ffffffffc0201dd6:	b795                	j	ffffffffc0201d3a <kfree+0x30>
        intr_enable();
ffffffffc0201dd8:	87dfe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201ddc:	bf85                	j	ffffffffc0201d4c <kfree+0x42>
				*last = bb->next;
ffffffffc0201dde:	000aa797          	auipc	a5,0xaa
ffffffffc0201de2:	6a87b523          	sd	s0,1706(a5) # ffffffffc02ac488 <bigblocks>
ffffffffc0201de6:	8436                	mv	s0,a3
ffffffffc0201de8:	86dfe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201dec:	bf9d                	j	ffffffffc0201d62 <kfree+0x58>
ffffffffc0201dee:	8082                	ret
ffffffffc0201df0:	000aa797          	auipc	a5,0xaa
ffffffffc0201df4:	6887bc23          	sd	s0,1688(a5) # ffffffffc02ac488 <bigblocks>
ffffffffc0201df8:	8436                	mv	s0,a3
ffffffffc0201dfa:	b7a5                	j	ffffffffc0201d62 <kfree+0x58>
    return pa2page(PADDR(kva));
ffffffffc0201dfc:	86a6                	mv	a3,s1
ffffffffc0201dfe:	00005617          	auipc	a2,0x5
ffffffffc0201e02:	5a260613          	addi	a2,a2,1442 # ffffffffc02073a0 <default_pmm_manager+0x88>
ffffffffc0201e06:	06e00593          	li	a1,110
ffffffffc0201e0a:	00005517          	auipc	a0,0x5
ffffffffc0201e0e:	58650513          	addi	a0,a0,1414 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0201e12:	e72fe0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201e16:	00005617          	auipc	a2,0x5
ffffffffc0201e1a:	5b260613          	addi	a2,a2,1458 # ffffffffc02073c8 <default_pmm_manager+0xb0>
ffffffffc0201e1e:	06200593          	li	a1,98
ffffffffc0201e22:	00005517          	auipc	a0,0x5
ffffffffc0201e26:	56e50513          	addi	a0,a0,1390 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0201e2a:	e5afe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201e2e <pa2page.part.4>:
pa2page(uintptr_t pa) {
ffffffffc0201e2e:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e30:	00005617          	auipc	a2,0x5
ffffffffc0201e34:	59860613          	addi	a2,a2,1432 # ffffffffc02073c8 <default_pmm_manager+0xb0>
ffffffffc0201e38:	06200593          	li	a1,98
ffffffffc0201e3c:	00005517          	auipc	a0,0x5
ffffffffc0201e40:	55450513          	addi	a0,a0,1364 # ffffffffc0207390 <default_pmm_manager+0x78>
pa2page(uintptr_t pa) {
ffffffffc0201e44:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e46:	e3efe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201e4a <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n)
{
ffffffffc0201e4a:	715d                	addi	sp,sp,-80
ffffffffc0201e4c:	e0a2                	sd	s0,64(sp)
ffffffffc0201e4e:	fc26                	sd	s1,56(sp)
ffffffffc0201e50:	f84a                	sd	s2,48(sp)
ffffffffc0201e52:	f44e                	sd	s3,40(sp)
ffffffffc0201e54:	f052                	sd	s4,32(sp)
ffffffffc0201e56:	ec56                	sd	s5,24(sp)
ffffffffc0201e58:	e486                	sd	ra,72(sp)
ffffffffc0201e5a:	842a                	mv	s0,a0
ffffffffc0201e5c:	000aa497          	auipc	s1,0xaa
ffffffffc0201e60:	69448493          	addi	s1,s1,1684 # ffffffffc02ac4f0 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0)
ffffffffc0201e64:	4985                	li	s3,1
ffffffffc0201e66:	000aaa17          	auipc	s4,0xaa
ffffffffc0201e6a:	642a0a13          	addi	s4,s4,1602 # ffffffffc02ac4a8 <swap_init_ok>
            break;

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0201e6e:	0005091b          	sext.w	s2,a0
ffffffffc0201e72:	000aaa97          	auipc	s5,0xaa
ffffffffc0201e76:	776a8a93          	addi	s5,s5,1910 # ffffffffc02ac5e8 <check_mm_struct>
ffffffffc0201e7a:	a00d                	j	ffffffffc0201e9c <alloc_pages+0x52>
            page = pmm_manager->alloc_pages(n);
ffffffffc0201e7c:	609c                	ld	a5,0(s1)
ffffffffc0201e7e:	6f9c                	ld	a5,24(a5)
ffffffffc0201e80:	9782                	jalr	a5
        swap_out(check_mm_struct, n, 0);
ffffffffc0201e82:	4601                	li	a2,0
ffffffffc0201e84:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0)
ffffffffc0201e86:	ed0d                	bnez	a0,ffffffffc0201ec0 <alloc_pages+0x76>
ffffffffc0201e88:	0289ec63          	bltu	s3,s0,ffffffffc0201ec0 <alloc_pages+0x76>
ffffffffc0201e8c:	000a2783          	lw	a5,0(s4)
ffffffffc0201e90:	2781                	sext.w	a5,a5
ffffffffc0201e92:	c79d                	beqz	a5,ffffffffc0201ec0 <alloc_pages+0x76>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201e94:	000ab503          	ld	a0,0(s5)
ffffffffc0201e98:	48d010ef          	jal	ra,ffffffffc0203b24 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201e9c:	100027f3          	csrr	a5,sstatus
ffffffffc0201ea0:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0201ea2:	8522                	mv	a0,s0
ffffffffc0201ea4:	dfe1                	beqz	a5,ffffffffc0201e7c <alloc_pages+0x32>
        intr_disable();
ffffffffc0201ea6:	fb4fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc0201eaa:	609c                	ld	a5,0(s1)
ffffffffc0201eac:	8522                	mv	a0,s0
ffffffffc0201eae:	6f9c                	ld	a5,24(a5)
ffffffffc0201eb0:	9782                	jalr	a5
ffffffffc0201eb2:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201eb4:	fa0fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201eb8:	6522                	ld	a0,8(sp)
        swap_out(check_mm_struct, n, 0);
ffffffffc0201eba:	4601                	li	a2,0
ffffffffc0201ebc:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0)
ffffffffc0201ebe:	d569                	beqz	a0,ffffffffc0201e88 <alloc_pages+0x3e>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0201ec0:	60a6                	ld	ra,72(sp)
ffffffffc0201ec2:	6406                	ld	s0,64(sp)
ffffffffc0201ec4:	74e2                	ld	s1,56(sp)
ffffffffc0201ec6:	7942                	ld	s2,48(sp)
ffffffffc0201ec8:	79a2                	ld	s3,40(sp)
ffffffffc0201eca:	7a02                	ld	s4,32(sp)
ffffffffc0201ecc:	6ae2                	ld	s5,24(sp)
ffffffffc0201ece:	6161                	addi	sp,sp,80
ffffffffc0201ed0:	8082                	ret

ffffffffc0201ed2 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ed2:	100027f3          	csrr	a5,sstatus
ffffffffc0201ed6:	8b89                	andi	a5,a5,2
ffffffffc0201ed8:	eb89                	bnez	a5,ffffffffc0201eea <free_pages+0x18>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201eda:	000aa797          	auipc	a5,0xaa
ffffffffc0201ede:	61678793          	addi	a5,a5,1558 # ffffffffc02ac4f0 <pmm_manager>
ffffffffc0201ee2:	639c                	ld	a5,0(a5)
ffffffffc0201ee4:	0207b303          	ld	t1,32(a5)
ffffffffc0201ee8:	8302                	jr	t1
{
ffffffffc0201eea:	1101                	addi	sp,sp,-32
ffffffffc0201eec:	ec06                	sd	ra,24(sp)
ffffffffc0201eee:	e822                	sd	s0,16(sp)
ffffffffc0201ef0:	e426                	sd	s1,8(sp)
ffffffffc0201ef2:	842a                	mv	s0,a0
ffffffffc0201ef4:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201ef6:	f64fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201efa:	000aa797          	auipc	a5,0xaa
ffffffffc0201efe:	5f678793          	addi	a5,a5,1526 # ffffffffc02ac4f0 <pmm_manager>
ffffffffc0201f02:	639c                	ld	a5,0(a5)
ffffffffc0201f04:	85a6                	mv	a1,s1
ffffffffc0201f06:	8522                	mv	a0,s0
ffffffffc0201f08:	739c                	ld	a5,32(a5)
ffffffffc0201f0a:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f0c:	6442                	ld	s0,16(sp)
ffffffffc0201f0e:	60e2                	ld	ra,24(sp)
ffffffffc0201f10:	64a2                	ld	s1,8(sp)
ffffffffc0201f12:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f14:	f40fe06f          	j	ffffffffc0200654 <intr_enable>

ffffffffc0201f18 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201f18:	100027f3          	csrr	a5,sstatus
ffffffffc0201f1c:	8b89                	andi	a5,a5,2
ffffffffc0201f1e:	eb89                	bnez	a5,ffffffffc0201f30 <nr_free_pages+0x18>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f20:	000aa797          	auipc	a5,0xaa
ffffffffc0201f24:	5d078793          	addi	a5,a5,1488 # ffffffffc02ac4f0 <pmm_manager>
ffffffffc0201f28:	639c                	ld	a5,0(a5)
ffffffffc0201f2a:	0287b303          	ld	t1,40(a5)
ffffffffc0201f2e:	8302                	jr	t1
{
ffffffffc0201f30:	1141                	addi	sp,sp,-16
ffffffffc0201f32:	e406                	sd	ra,8(sp)
ffffffffc0201f34:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201f36:	f24fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f3a:	000aa797          	auipc	a5,0xaa
ffffffffc0201f3e:	5b678793          	addi	a5,a5,1462 # ffffffffc02ac4f0 <pmm_manager>
ffffffffc0201f42:	639c                	ld	a5,0(a5)
ffffffffc0201f44:	779c                	ld	a5,40(a5)
ffffffffc0201f46:	9782                	jalr	a5
ffffffffc0201f48:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f4a:	f0afe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f4e:	8522                	mv	a0,s0
ffffffffc0201f50:	60a2                	ld	ra,8(sp)
ffffffffc0201f52:	6402                	ld	s0,0(sp)
ffffffffc0201f54:	0141                	addi	sp,sp,16
ffffffffc0201f56:	8082                	ret

ffffffffc0201f58 <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
ffffffffc0201f58:	7139                	addi	sp,sp,-64
ffffffffc0201f5a:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f5c:	01e5d493          	srli	s1,a1,0x1e
ffffffffc0201f60:	1ff4f493          	andi	s1,s1,511
ffffffffc0201f64:	048e                	slli	s1,s1,0x3
ffffffffc0201f66:	94aa                	add	s1,s1,a0
    if (!(*pdep1 & PTE_V))
ffffffffc0201f68:	6094                	ld	a3,0(s1)
{
ffffffffc0201f6a:	f04a                	sd	s2,32(sp)
ffffffffc0201f6c:	ec4e                	sd	s3,24(sp)
ffffffffc0201f6e:	e852                	sd	s4,16(sp)
ffffffffc0201f70:	fc06                	sd	ra,56(sp)
ffffffffc0201f72:	f822                	sd	s0,48(sp)
ffffffffc0201f74:	e456                	sd	s5,8(sp)
ffffffffc0201f76:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201f78:	0016f793          	andi	a5,a3,1
{
ffffffffc0201f7c:	892e                	mv	s2,a1
ffffffffc0201f7e:	8a32                	mv	s4,a2
ffffffffc0201f80:	000aa997          	auipc	s3,0xaa
ffffffffc0201f84:	51898993          	addi	s3,s3,1304 # ffffffffc02ac498 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201f88:	e7bd                	bnez	a5,ffffffffc0201ff6 <get_pte+0x9e>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f8a:	12060c63          	beqz	a2,ffffffffc02020c2 <get_pte+0x16a>
ffffffffc0201f8e:	4505                	li	a0,1
ffffffffc0201f90:	ebbff0ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0201f94:	842a                	mv	s0,a0
ffffffffc0201f96:	12050663          	beqz	a0,ffffffffc02020c2 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201f9a:	000aab17          	auipc	s6,0xaa
ffffffffc0201f9e:	56eb0b13          	addi	s6,s6,1390 # ffffffffc02ac508 <pages>
ffffffffc0201fa2:	000b3503          	ld	a0,0(s6)
    page->ref = val;
ffffffffc0201fa6:	4785                	li	a5,1
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fa8:	000aa997          	auipc	s3,0xaa
ffffffffc0201fac:	4f098993          	addi	s3,s3,1264 # ffffffffc02ac498 <npage>
    return page - pages + nbase;
ffffffffc0201fb0:	40a40533          	sub	a0,s0,a0
ffffffffc0201fb4:	00080ab7          	lui	s5,0x80
ffffffffc0201fb8:	8519                	srai	a0,a0,0x6
ffffffffc0201fba:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc0201fbe:	c01c                	sw	a5,0(s0)
ffffffffc0201fc0:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc0201fc2:	9556                	add	a0,a0,s5
ffffffffc0201fc4:	83b1                	srli	a5,a5,0xc
ffffffffc0201fc6:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fc8:	0532                	slli	a0,a0,0xc
ffffffffc0201fca:	14e7f363          	bleu	a4,a5,ffffffffc0202110 <get_pte+0x1b8>
ffffffffc0201fce:	000aa797          	auipc	a5,0xaa
ffffffffc0201fd2:	52a78793          	addi	a5,a5,1322 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc0201fd6:	639c                	ld	a5,0(a5)
ffffffffc0201fd8:	6605                	lui	a2,0x1
ffffffffc0201fda:	4581                	li	a1,0
ffffffffc0201fdc:	953e                	add	a0,a0,a5
ffffffffc0201fde:	5ea040ef          	jal	ra,ffffffffc02065c8 <memset>
    return page - pages + nbase;
ffffffffc0201fe2:	000b3683          	ld	a3,0(s6)
ffffffffc0201fe6:	40d406b3          	sub	a3,s0,a3
ffffffffc0201fea:	8699                	srai	a3,a3,0x6
ffffffffc0201fec:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201fee:	06aa                	slli	a3,a3,0xa
ffffffffc0201ff0:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ff4:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ff6:	77fd                	lui	a5,0xfffff
ffffffffc0201ff8:	068a                	slli	a3,a3,0x2
ffffffffc0201ffa:	0009b703          	ld	a4,0(s3)
ffffffffc0201ffe:	8efd                	and	a3,a3,a5
ffffffffc0202000:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202004:	0ce7f163          	bleu	a4,a5,ffffffffc02020c6 <get_pte+0x16e>
ffffffffc0202008:	000aaa97          	auipc	s5,0xaa
ffffffffc020200c:	4f0a8a93          	addi	s5,s5,1264 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc0202010:	000ab403          	ld	s0,0(s5)
ffffffffc0202014:	01595793          	srli	a5,s2,0x15
ffffffffc0202018:	1ff7f793          	andi	a5,a5,511
ffffffffc020201c:	96a2                	add	a3,a3,s0
ffffffffc020201e:	00379413          	slli	s0,a5,0x3
ffffffffc0202022:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0202024:	6014                	ld	a3,0(s0)
ffffffffc0202026:	0016f793          	andi	a5,a3,1
ffffffffc020202a:	e3ad                	bnez	a5,ffffffffc020208c <get_pte+0x134>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020202c:	080a0b63          	beqz	s4,ffffffffc02020c2 <get_pte+0x16a>
ffffffffc0202030:	4505                	li	a0,1
ffffffffc0202032:	e19ff0ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0202036:	84aa                	mv	s1,a0
ffffffffc0202038:	c549                	beqz	a0,ffffffffc02020c2 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc020203a:	000aab17          	auipc	s6,0xaa
ffffffffc020203e:	4ceb0b13          	addi	s6,s6,1230 # ffffffffc02ac508 <pages>
ffffffffc0202042:	000b3503          	ld	a0,0(s6)
    page->ref = val;
ffffffffc0202046:	4785                	li	a5,1
    return page - pages + nbase;
ffffffffc0202048:	00080a37          	lui	s4,0x80
ffffffffc020204c:	40a48533          	sub	a0,s1,a0
ffffffffc0202050:	8519                	srai	a0,a0,0x6
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202052:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc0202056:	c09c                	sw	a5,0(s1)
ffffffffc0202058:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc020205a:	9552                	add	a0,a0,s4
ffffffffc020205c:	83b1                	srli	a5,a5,0xc
ffffffffc020205e:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202060:	0532                	slli	a0,a0,0xc
ffffffffc0202062:	08e7fa63          	bleu	a4,a5,ffffffffc02020f6 <get_pte+0x19e>
ffffffffc0202066:	000ab783          	ld	a5,0(s5)
ffffffffc020206a:	6605                	lui	a2,0x1
ffffffffc020206c:	4581                	li	a1,0
ffffffffc020206e:	953e                	add	a0,a0,a5
ffffffffc0202070:	558040ef          	jal	ra,ffffffffc02065c8 <memset>
    return page - pages + nbase;
ffffffffc0202074:	000b3683          	ld	a3,0(s6)
ffffffffc0202078:	40d486b3          	sub	a3,s1,a3
ffffffffc020207c:	8699                	srai	a3,a3,0x6
ffffffffc020207e:	96d2                	add	a3,a3,s4
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202080:	06aa                	slli	a3,a3,0xa
ffffffffc0202082:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202086:	e014                	sd	a3,0(s0)
ffffffffc0202088:	0009b703          	ld	a4,0(s3)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020208c:	068a                	slli	a3,a3,0x2
ffffffffc020208e:	757d                	lui	a0,0xfffff
ffffffffc0202090:	8ee9                	and	a3,a3,a0
ffffffffc0202092:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202096:	04e7f463          	bleu	a4,a5,ffffffffc02020de <get_pte+0x186>
ffffffffc020209a:	000ab503          	ld	a0,0(s5)
ffffffffc020209e:	00c95793          	srli	a5,s2,0xc
ffffffffc02020a2:	1ff7f793          	andi	a5,a5,511
ffffffffc02020a6:	96aa                	add	a3,a3,a0
ffffffffc02020a8:	00379513          	slli	a0,a5,0x3
ffffffffc02020ac:	9536                	add	a0,a0,a3
}
ffffffffc02020ae:	70e2                	ld	ra,56(sp)
ffffffffc02020b0:	7442                	ld	s0,48(sp)
ffffffffc02020b2:	74a2                	ld	s1,40(sp)
ffffffffc02020b4:	7902                	ld	s2,32(sp)
ffffffffc02020b6:	69e2                	ld	s3,24(sp)
ffffffffc02020b8:	6a42                	ld	s4,16(sp)
ffffffffc02020ba:	6aa2                	ld	s5,8(sp)
ffffffffc02020bc:	6b02                	ld	s6,0(sp)
ffffffffc02020be:	6121                	addi	sp,sp,64
ffffffffc02020c0:	8082                	ret
            return NULL;
ffffffffc02020c2:	4501                	li	a0,0
ffffffffc02020c4:	b7ed                	j	ffffffffc02020ae <get_pte+0x156>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02020c6:	00005617          	auipc	a2,0x5
ffffffffc02020ca:	2a260613          	addi	a2,a2,674 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc02020ce:	0f500593          	li	a1,245
ffffffffc02020d2:	00005517          	auipc	a0,0x5
ffffffffc02020d6:	3b650513          	addi	a0,a0,950 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc02020da:	baafe0ef          	jal	ra,ffffffffc0200484 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020de:	00005617          	auipc	a2,0x5
ffffffffc02020e2:	28a60613          	addi	a2,a2,650 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc02020e6:	10200593          	li	a1,258
ffffffffc02020ea:	00005517          	auipc	a0,0x5
ffffffffc02020ee:	39e50513          	addi	a0,a0,926 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc02020f2:	b92fe0ef          	jal	ra,ffffffffc0200484 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020f6:	86aa                	mv	a3,a0
ffffffffc02020f8:	00005617          	auipc	a2,0x5
ffffffffc02020fc:	27060613          	addi	a2,a2,624 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc0202100:	0ff00593          	li	a1,255
ffffffffc0202104:	00005517          	auipc	a0,0x5
ffffffffc0202108:	38450513          	addi	a0,a0,900 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc020210c:	b78fe0ef          	jal	ra,ffffffffc0200484 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202110:	86aa                	mv	a3,a0
ffffffffc0202112:	00005617          	auipc	a2,0x5
ffffffffc0202116:	25660613          	addi	a2,a2,598 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc020211a:	0f100593          	li	a1,241
ffffffffc020211e:	00005517          	auipc	a0,0x5
ffffffffc0202122:	36a50513          	addi	a0,a0,874 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202126:	b5efe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020212a <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc020212a:	1141                	addi	sp,sp,-16
ffffffffc020212c:	e022                	sd	s0,0(sp)
ffffffffc020212e:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202130:	4601                	li	a2,0
{
ffffffffc0202132:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202134:	e25ff0ef          	jal	ra,ffffffffc0201f58 <get_pte>
    if (ptep_store != NULL)
ffffffffc0202138:	c011                	beqz	s0,ffffffffc020213c <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020213a:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020213c:	c129                	beqz	a0,ffffffffc020217e <get_page+0x54>
ffffffffc020213e:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202140:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202142:	0017f713          	andi	a4,a5,1
ffffffffc0202146:	e709                	bnez	a4,ffffffffc0202150 <get_page+0x26>
}
ffffffffc0202148:	60a2                	ld	ra,8(sp)
ffffffffc020214a:	6402                	ld	s0,0(sp)
ffffffffc020214c:	0141                	addi	sp,sp,16
ffffffffc020214e:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0202150:	000aa717          	auipc	a4,0xaa
ffffffffc0202154:	34870713          	addi	a4,a4,840 # ffffffffc02ac498 <npage>
ffffffffc0202158:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc020215a:	078a                	slli	a5,a5,0x2
ffffffffc020215c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020215e:	02e7f563          	bleu	a4,a5,ffffffffc0202188 <get_page+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202162:	000aa717          	auipc	a4,0xaa
ffffffffc0202166:	3a670713          	addi	a4,a4,934 # ffffffffc02ac508 <pages>
ffffffffc020216a:	6308                	ld	a0,0(a4)
ffffffffc020216c:	60a2                	ld	ra,8(sp)
ffffffffc020216e:	6402                	ld	s0,0(sp)
ffffffffc0202170:	fff80737          	lui	a4,0xfff80
ffffffffc0202174:	97ba                	add	a5,a5,a4
ffffffffc0202176:	079a                	slli	a5,a5,0x6
ffffffffc0202178:	953e                	add	a0,a0,a5
ffffffffc020217a:	0141                	addi	sp,sp,16
ffffffffc020217c:	8082                	ret
ffffffffc020217e:	60a2                	ld	ra,8(sp)
ffffffffc0202180:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc0202182:	4501                	li	a0,0
}
ffffffffc0202184:	0141                	addi	sp,sp,16
ffffffffc0202186:	8082                	ret
ffffffffc0202188:	ca7ff0ef          	jal	ra,ffffffffc0201e2e <pa2page.part.4>

ffffffffc020218c <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc020218c:	711d                	addi	sp,sp,-96
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020218e:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202192:	ec86                	sd	ra,88(sp)
ffffffffc0202194:	e8a2                	sd	s0,80(sp)
ffffffffc0202196:	e4a6                	sd	s1,72(sp)
ffffffffc0202198:	e0ca                	sd	s2,64(sp)
ffffffffc020219a:	fc4e                	sd	s3,56(sp)
ffffffffc020219c:	f852                	sd	s4,48(sp)
ffffffffc020219e:	f456                	sd	s5,40(sp)
ffffffffc02021a0:	f05a                	sd	s6,32(sp)
ffffffffc02021a2:	ec5e                	sd	s7,24(sp)
ffffffffc02021a4:	e862                	sd	s8,16(sp)
ffffffffc02021a6:	e466                	sd	s9,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021a8:	03479713          	slli	a4,a5,0x34
ffffffffc02021ac:	eb71                	bnez	a4,ffffffffc0202280 <unmap_range+0xf4>
    assert(USER_ACCESS(start, end));
ffffffffc02021ae:	002007b7          	lui	a5,0x200
ffffffffc02021b2:	842e                	mv	s0,a1
ffffffffc02021b4:	0af5e663          	bltu	a1,a5,ffffffffc0202260 <unmap_range+0xd4>
ffffffffc02021b8:	8932                	mv	s2,a2
ffffffffc02021ba:	0ac5f363          	bleu	a2,a1,ffffffffc0202260 <unmap_range+0xd4>
ffffffffc02021be:	4785                	li	a5,1
ffffffffc02021c0:	07fe                	slli	a5,a5,0x1f
ffffffffc02021c2:	08c7ef63          	bltu	a5,a2,ffffffffc0202260 <unmap_range+0xd4>
ffffffffc02021c6:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02021c8:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc02021ca:	000aac97          	auipc	s9,0xaa
ffffffffc02021ce:	2cec8c93          	addi	s9,s9,718 # ffffffffc02ac498 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02021d2:	000aac17          	auipc	s8,0xaa
ffffffffc02021d6:	336c0c13          	addi	s8,s8,822 # ffffffffc02ac508 <pages>
ffffffffc02021da:	fff80bb7          	lui	s7,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02021de:	00200b37          	lui	s6,0x200
ffffffffc02021e2:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02021e6:	4601                	li	a2,0
ffffffffc02021e8:	85a2                	mv	a1,s0
ffffffffc02021ea:	854e                	mv	a0,s3
ffffffffc02021ec:	d6dff0ef          	jal	ra,ffffffffc0201f58 <get_pte>
ffffffffc02021f0:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02021f2:	cd21                	beqz	a0,ffffffffc020224a <unmap_range+0xbe>
        if (*ptep != 0)
ffffffffc02021f4:	611c                	ld	a5,0(a0)
ffffffffc02021f6:	e38d                	bnez	a5,ffffffffc0202218 <unmap_range+0x8c>
        start += PGSIZE;
ffffffffc02021f8:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02021fa:	ff2466e3          	bltu	s0,s2,ffffffffc02021e6 <unmap_range+0x5a>
}
ffffffffc02021fe:	60e6                	ld	ra,88(sp)
ffffffffc0202200:	6446                	ld	s0,80(sp)
ffffffffc0202202:	64a6                	ld	s1,72(sp)
ffffffffc0202204:	6906                	ld	s2,64(sp)
ffffffffc0202206:	79e2                	ld	s3,56(sp)
ffffffffc0202208:	7a42                	ld	s4,48(sp)
ffffffffc020220a:	7aa2                	ld	s5,40(sp)
ffffffffc020220c:	7b02                	ld	s6,32(sp)
ffffffffc020220e:	6be2                	ld	s7,24(sp)
ffffffffc0202210:	6c42                	ld	s8,16(sp)
ffffffffc0202212:	6ca2                	ld	s9,8(sp)
ffffffffc0202214:	6125                	addi	sp,sp,96
ffffffffc0202216:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202218:	0017f713          	andi	a4,a5,1
ffffffffc020221c:	df71                	beqz	a4,ffffffffc02021f8 <unmap_range+0x6c>
    if (PPN(pa) >= npage) {
ffffffffc020221e:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202222:	078a                	slli	a5,a5,0x2
ffffffffc0202224:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202226:	06e7fd63          	bleu	a4,a5,ffffffffc02022a0 <unmap_range+0x114>
    return &pages[PPN(pa) - nbase];
ffffffffc020222a:	000c3503          	ld	a0,0(s8)
ffffffffc020222e:	97de                	add	a5,a5,s7
ffffffffc0202230:	079a                	slli	a5,a5,0x6
ffffffffc0202232:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202234:	411c                	lw	a5,0(a0)
ffffffffc0202236:	fff7871b          	addiw	a4,a5,-1
ffffffffc020223a:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020223c:	cf11                	beqz	a4,ffffffffc0202258 <unmap_range+0xcc>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc020223e:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202242:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202246:	9452                	add	s0,s0,s4
ffffffffc0202248:	bf4d                	j	ffffffffc02021fa <unmap_range+0x6e>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020224a:	945a                	add	s0,s0,s6
ffffffffc020224c:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0202250:	d45d                	beqz	s0,ffffffffc02021fe <unmap_range+0x72>
ffffffffc0202252:	f9246ae3          	bltu	s0,s2,ffffffffc02021e6 <unmap_range+0x5a>
ffffffffc0202256:	b765                	j	ffffffffc02021fe <unmap_range+0x72>
            free_page(page);
ffffffffc0202258:	4585                	li	a1,1
ffffffffc020225a:	c79ff0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
ffffffffc020225e:	b7c5                	j	ffffffffc020223e <unmap_range+0xb2>
    assert(USER_ACCESS(start, end));
ffffffffc0202260:	00005697          	auipc	a3,0x5
ffffffffc0202264:	7d868693          	addi	a3,a3,2008 # ffffffffc0207a38 <default_pmm_manager+0x720>
ffffffffc0202268:	00005617          	auipc	a2,0x5
ffffffffc020226c:	96860613          	addi	a2,a2,-1688 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202270:	12b00593          	li	a1,299
ffffffffc0202274:	00005517          	auipc	a0,0x5
ffffffffc0202278:	21450513          	addi	a0,a0,532 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc020227c:	a08fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202280:	00005697          	auipc	a3,0x5
ffffffffc0202284:	78868693          	addi	a3,a3,1928 # ffffffffc0207a08 <default_pmm_manager+0x6f0>
ffffffffc0202288:	00005617          	auipc	a2,0x5
ffffffffc020228c:	94860613          	addi	a2,a2,-1720 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202290:	12a00593          	li	a1,298
ffffffffc0202294:	00005517          	auipc	a0,0x5
ffffffffc0202298:	1f450513          	addi	a0,a0,500 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc020229c:	9e8fe0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc02022a0:	b8fff0ef          	jal	ra,ffffffffc0201e2e <pa2page.part.4>

ffffffffc02022a4 <exit_range>:
{
ffffffffc02022a4:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022a6:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02022aa:	fc86                	sd	ra,120(sp)
ffffffffc02022ac:	f8a2                	sd	s0,112(sp)
ffffffffc02022ae:	f4a6                	sd	s1,104(sp)
ffffffffc02022b0:	f0ca                	sd	s2,96(sp)
ffffffffc02022b2:	ecce                	sd	s3,88(sp)
ffffffffc02022b4:	e8d2                	sd	s4,80(sp)
ffffffffc02022b6:	e4d6                	sd	s5,72(sp)
ffffffffc02022b8:	e0da                	sd	s6,64(sp)
ffffffffc02022ba:	fc5e                	sd	s7,56(sp)
ffffffffc02022bc:	f862                	sd	s8,48(sp)
ffffffffc02022be:	f466                	sd	s9,40(sp)
ffffffffc02022c0:	f06a                	sd	s10,32(sp)
ffffffffc02022c2:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022c4:	03479713          	slli	a4,a5,0x34
ffffffffc02022c8:	1c071163          	bnez	a4,ffffffffc020248a <exit_range+0x1e6>
    assert(USER_ACCESS(start, end));
ffffffffc02022cc:	002007b7          	lui	a5,0x200
ffffffffc02022d0:	20f5e563          	bltu	a1,a5,ffffffffc02024da <exit_range+0x236>
ffffffffc02022d4:	8b32                	mv	s6,a2
ffffffffc02022d6:	20c5f263          	bleu	a2,a1,ffffffffc02024da <exit_range+0x236>
ffffffffc02022da:	4785                	li	a5,1
ffffffffc02022dc:	07fe                	slli	a5,a5,0x1f
ffffffffc02022de:	1ec7ee63          	bltu	a5,a2,ffffffffc02024da <exit_range+0x236>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02022e2:	c00009b7          	lui	s3,0xc0000
ffffffffc02022e6:	400007b7          	lui	a5,0x40000
ffffffffc02022ea:	0135f9b3          	and	s3,a1,s3
ffffffffc02022ee:	99be                	add	s3,s3,a5
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02022f0:	c0000337          	lui	t1,0xc0000
ffffffffc02022f4:	00698933          	add	s2,s3,t1
ffffffffc02022f8:	01e95913          	srli	s2,s2,0x1e
ffffffffc02022fc:	1ff97913          	andi	s2,s2,511
ffffffffc0202300:	8e2a                	mv	t3,a0
ffffffffc0202302:	090e                	slli	s2,s2,0x3
ffffffffc0202304:	9972                	add	s2,s2,t3
ffffffffc0202306:	00093b83          	ld	s7,0(s2)
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020230a:	ffe004b7          	lui	s1,0xffe00
    return KADDR(page2pa(page));
ffffffffc020230e:	5dfd                	li	s11,-1
        if (pde1 & PTE_V)
ffffffffc0202310:	001bf793          	andi	a5,s7,1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202314:	8ced                	and	s1,s1,a1
    if (PPN(pa) >= npage) {
ffffffffc0202316:	000aad17          	auipc	s10,0xaa
ffffffffc020231a:	182d0d13          	addi	s10,s10,386 # ffffffffc02ac498 <npage>
    return KADDR(page2pa(page));
ffffffffc020231e:	00cddd93          	srli	s11,s11,0xc
ffffffffc0202322:	000aa717          	auipc	a4,0xaa
ffffffffc0202326:	1d670713          	addi	a4,a4,470 # ffffffffc02ac4f8 <va_pa_offset>
    return &pages[PPN(pa) - nbase];
ffffffffc020232a:	000aae97          	auipc	t4,0xaa
ffffffffc020232e:	1dee8e93          	addi	t4,t4,478 # ffffffffc02ac508 <pages>
        if (pde1 & PTE_V)
ffffffffc0202332:	e79d                	bnez	a5,ffffffffc0202360 <exit_range+0xbc>
    } while (d1start != 0 && d1start < end);
ffffffffc0202334:	12098963          	beqz	s3,ffffffffc0202466 <exit_range+0x1c2>
ffffffffc0202338:	400007b7          	lui	a5,0x40000
ffffffffc020233c:	84ce                	mv	s1,s3
ffffffffc020233e:	97ce                	add	a5,a5,s3
ffffffffc0202340:	1369f363          	bleu	s6,s3,ffffffffc0202466 <exit_range+0x1c2>
ffffffffc0202344:	89be                	mv	s3,a5
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202346:	00698933          	add	s2,s3,t1
ffffffffc020234a:	01e95913          	srli	s2,s2,0x1e
ffffffffc020234e:	1ff97913          	andi	s2,s2,511
ffffffffc0202352:	090e                	slli	s2,s2,0x3
ffffffffc0202354:	9972                	add	s2,s2,t3
ffffffffc0202356:	00093b83          	ld	s7,0(s2)
        if (pde1 & PTE_V)
ffffffffc020235a:	001bf793          	andi	a5,s7,1
ffffffffc020235e:	dbf9                	beqz	a5,ffffffffc0202334 <exit_range+0x90>
    if (PPN(pa) >= npage) {
ffffffffc0202360:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202364:	0b8a                	slli	s7,s7,0x2
ffffffffc0202366:	00cbdb93          	srli	s7,s7,0xc
    if (PPN(pa) >= npage) {
ffffffffc020236a:	14fbfc63          	bleu	a5,s7,ffffffffc02024c2 <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc020236e:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202372:	9ade                	add	s5,s5,s7
    return page - pages + nbase;
ffffffffc0202374:	000806b7          	lui	a3,0x80
ffffffffc0202378:	96d6                	add	a3,a3,s5
ffffffffc020237a:	006a9593          	slli	a1,s5,0x6
    return KADDR(page2pa(page));
ffffffffc020237e:	01b6f633          	and	a2,a3,s11
    return page - pages + nbase;
ffffffffc0202382:	e42e                	sd	a1,8(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc0202384:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202386:	12f67263          	bleu	a5,a2,ffffffffc02024aa <exit_range+0x206>
ffffffffc020238a:	00073a03          	ld	s4,0(a4)
            free_pd0 = 1;
ffffffffc020238e:	4c85                	li	s9,1
    return &pages[PPN(pa) - nbase];
ffffffffc0202390:	fff808b7          	lui	a7,0xfff80
    return KADDR(page2pa(page));
ffffffffc0202394:	9a36                	add	s4,s4,a3
    return page - pages + nbase;
ffffffffc0202396:	00080837          	lui	a6,0x80
ffffffffc020239a:	6a85                	lui	s5,0x1
                d0start += PTSIZE;
ffffffffc020239c:	00200c37          	lui	s8,0x200
ffffffffc02023a0:	a801                	j	ffffffffc02023b0 <exit_range+0x10c>
                    free_pd0 = 0;
ffffffffc02023a2:	4c81                	li	s9,0
                d0start += PTSIZE;
ffffffffc02023a4:	94e2                	add	s1,s1,s8
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023a6:	c0d9                	beqz	s1,ffffffffc020242c <exit_range+0x188>
ffffffffc02023a8:	0934f263          	bleu	s3,s1,ffffffffc020242c <exit_range+0x188>
ffffffffc02023ac:	0d64fc63          	bleu	s6,s1,ffffffffc0202484 <exit_range+0x1e0>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023b0:	0154d413          	srli	s0,s1,0x15
ffffffffc02023b4:	1ff47413          	andi	s0,s0,511
ffffffffc02023b8:	040e                	slli	s0,s0,0x3
ffffffffc02023ba:	9452                	add	s0,s0,s4
ffffffffc02023bc:	601c                	ld	a5,0(s0)
                if (pde0 & PTE_V)
ffffffffc02023be:	0017f693          	andi	a3,a5,1
ffffffffc02023c2:	d2e5                	beqz	a3,ffffffffc02023a2 <exit_range+0xfe>
    if (PPN(pa) >= npage) {
ffffffffc02023c4:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023c8:	00279513          	slli	a0,a5,0x2
ffffffffc02023cc:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc02023ce:	0eb57a63          	bleu	a1,a0,ffffffffc02024c2 <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023d2:	9546                	add	a0,a0,a7
    return page - pages + nbase;
ffffffffc02023d4:	010506b3          	add	a3,a0,a6
    return KADDR(page2pa(page));
ffffffffc02023d8:	01b6f7b3          	and	a5,a3,s11
    return page - pages + nbase;
ffffffffc02023dc:	051a                	slli	a0,a0,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02023de:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02023e0:	0cb7f563          	bleu	a1,a5,ffffffffc02024aa <exit_range+0x206>
ffffffffc02023e4:	631c                	ld	a5,0(a4)
ffffffffc02023e6:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02023e8:	015685b3          	add	a1,a3,s5
                        if (pt[i] & PTE_V)
ffffffffc02023ec:	629c                	ld	a5,0(a3)
ffffffffc02023ee:	8b85                	andi	a5,a5,1
ffffffffc02023f0:	fbd5                	bnez	a5,ffffffffc02023a4 <exit_range+0x100>
ffffffffc02023f2:	06a1                	addi	a3,a3,8
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02023f4:	fed59ce3          	bne	a1,a3,ffffffffc02023ec <exit_range+0x148>
    return &pages[PPN(pa) - nbase];
ffffffffc02023f8:	000eb783          	ld	a5,0(t4)
                        free_page(pde2page(pde0));
ffffffffc02023fc:	4585                	li	a1,1
ffffffffc02023fe:	e072                	sd	t3,0(sp)
ffffffffc0202400:	953e                	add	a0,a0,a5
ffffffffc0202402:	ad1ff0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
                d0start += PTSIZE;
ffffffffc0202406:	94e2                	add	s1,s1,s8
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202408:	00043023          	sd	zero,0(s0)
ffffffffc020240c:	000aae97          	auipc	t4,0xaa
ffffffffc0202410:	0fce8e93          	addi	t4,t4,252 # ffffffffc02ac508 <pages>
ffffffffc0202414:	6e02                	ld	t3,0(sp)
ffffffffc0202416:	c0000337          	lui	t1,0xc0000
ffffffffc020241a:	fff808b7          	lui	a7,0xfff80
ffffffffc020241e:	00080837          	lui	a6,0x80
ffffffffc0202422:	000aa717          	auipc	a4,0xaa
ffffffffc0202426:	0d670713          	addi	a4,a4,214 # ffffffffc02ac4f8 <va_pa_offset>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020242a:	fcbd                	bnez	s1,ffffffffc02023a8 <exit_range+0x104>
            if (free_pd0)
ffffffffc020242c:	f00c84e3          	beqz	s9,ffffffffc0202334 <exit_range+0x90>
    if (PPN(pa) >= npage) {
ffffffffc0202430:	000d3783          	ld	a5,0(s10)
ffffffffc0202434:	e072                	sd	t3,0(sp)
ffffffffc0202436:	08fbf663          	bleu	a5,s7,ffffffffc02024c2 <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc020243a:	000eb503          	ld	a0,0(t4)
                free_page(pde2page(pde1));
ffffffffc020243e:	67a2                	ld	a5,8(sp)
ffffffffc0202440:	4585                	li	a1,1
ffffffffc0202442:	953e                	add	a0,a0,a5
ffffffffc0202444:	a8fff0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202448:	00093023          	sd	zero,0(s2)
ffffffffc020244c:	000aa717          	auipc	a4,0xaa
ffffffffc0202450:	0ac70713          	addi	a4,a4,172 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc0202454:	c0000337          	lui	t1,0xc0000
ffffffffc0202458:	6e02                	ld	t3,0(sp)
ffffffffc020245a:	000aae97          	auipc	t4,0xaa
ffffffffc020245e:	0aee8e93          	addi	t4,t4,174 # ffffffffc02ac508 <pages>
    } while (d1start != 0 && d1start < end);
ffffffffc0202462:	ec099be3          	bnez	s3,ffffffffc0202338 <exit_range+0x94>
}
ffffffffc0202466:	70e6                	ld	ra,120(sp)
ffffffffc0202468:	7446                	ld	s0,112(sp)
ffffffffc020246a:	74a6                	ld	s1,104(sp)
ffffffffc020246c:	7906                	ld	s2,96(sp)
ffffffffc020246e:	69e6                	ld	s3,88(sp)
ffffffffc0202470:	6a46                	ld	s4,80(sp)
ffffffffc0202472:	6aa6                	ld	s5,72(sp)
ffffffffc0202474:	6b06                	ld	s6,64(sp)
ffffffffc0202476:	7be2                	ld	s7,56(sp)
ffffffffc0202478:	7c42                	ld	s8,48(sp)
ffffffffc020247a:	7ca2                	ld	s9,40(sp)
ffffffffc020247c:	7d02                	ld	s10,32(sp)
ffffffffc020247e:	6de2                	ld	s11,24(sp)
ffffffffc0202480:	6109                	addi	sp,sp,128
ffffffffc0202482:	8082                	ret
            if (free_pd0)
ffffffffc0202484:	ea0c8ae3          	beqz	s9,ffffffffc0202338 <exit_range+0x94>
ffffffffc0202488:	b765                	j	ffffffffc0202430 <exit_range+0x18c>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020248a:	00005697          	auipc	a3,0x5
ffffffffc020248e:	57e68693          	addi	a3,a3,1406 # ffffffffc0207a08 <default_pmm_manager+0x6f0>
ffffffffc0202492:	00004617          	auipc	a2,0x4
ffffffffc0202496:	73e60613          	addi	a2,a2,1854 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020249a:	13f00593          	li	a1,319
ffffffffc020249e:	00005517          	auipc	a0,0x5
ffffffffc02024a2:	fea50513          	addi	a0,a0,-22 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc02024a6:	fdffd0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc02024aa:	00005617          	auipc	a2,0x5
ffffffffc02024ae:	ebe60613          	addi	a2,a2,-322 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc02024b2:	06900593          	li	a1,105
ffffffffc02024b6:	00005517          	auipc	a0,0x5
ffffffffc02024ba:	eda50513          	addi	a0,a0,-294 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc02024be:	fc7fd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02024c2:	00005617          	auipc	a2,0x5
ffffffffc02024c6:	f0660613          	addi	a2,a2,-250 # ffffffffc02073c8 <default_pmm_manager+0xb0>
ffffffffc02024ca:	06200593          	li	a1,98
ffffffffc02024ce:	00005517          	auipc	a0,0x5
ffffffffc02024d2:	ec250513          	addi	a0,a0,-318 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc02024d6:	faffd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02024da:	00005697          	auipc	a3,0x5
ffffffffc02024de:	55e68693          	addi	a3,a3,1374 # ffffffffc0207a38 <default_pmm_manager+0x720>
ffffffffc02024e2:	00004617          	auipc	a2,0x4
ffffffffc02024e6:	6ee60613          	addi	a2,a2,1774 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02024ea:	14000593          	li	a1,320
ffffffffc02024ee:	00005517          	auipc	a0,0x5
ffffffffc02024f2:	f9a50513          	addi	a0,a0,-102 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc02024f6:	f8ffd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02024fa <page_remove>:
{
ffffffffc02024fa:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02024fc:	4601                	li	a2,0
{
ffffffffc02024fe:	e426                	sd	s1,8(sp)
ffffffffc0202500:	ec06                	sd	ra,24(sp)
ffffffffc0202502:	e822                	sd	s0,16(sp)
ffffffffc0202504:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202506:	a53ff0ef          	jal	ra,ffffffffc0201f58 <get_pte>
    if (ptep != NULL)
ffffffffc020250a:	c511                	beqz	a0,ffffffffc0202516 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc020250c:	611c                	ld	a5,0(a0)
ffffffffc020250e:	842a                	mv	s0,a0
ffffffffc0202510:	0017f713          	andi	a4,a5,1
ffffffffc0202514:	e711                	bnez	a4,ffffffffc0202520 <page_remove+0x26>
}
ffffffffc0202516:	60e2                	ld	ra,24(sp)
ffffffffc0202518:	6442                	ld	s0,16(sp)
ffffffffc020251a:	64a2                	ld	s1,8(sp)
ffffffffc020251c:	6105                	addi	sp,sp,32
ffffffffc020251e:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0202520:	000aa717          	auipc	a4,0xaa
ffffffffc0202524:	f7870713          	addi	a4,a4,-136 # ffffffffc02ac498 <npage>
ffffffffc0202528:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc020252a:	078a                	slli	a5,a5,0x2
ffffffffc020252c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020252e:	02e7fe63          	bleu	a4,a5,ffffffffc020256a <page_remove+0x70>
    return &pages[PPN(pa) - nbase];
ffffffffc0202532:	000aa717          	auipc	a4,0xaa
ffffffffc0202536:	fd670713          	addi	a4,a4,-42 # ffffffffc02ac508 <pages>
ffffffffc020253a:	6308                	ld	a0,0(a4)
ffffffffc020253c:	fff80737          	lui	a4,0xfff80
ffffffffc0202540:	97ba                	add	a5,a5,a4
ffffffffc0202542:	079a                	slli	a5,a5,0x6
ffffffffc0202544:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202546:	411c                	lw	a5,0(a0)
ffffffffc0202548:	fff7871b          	addiw	a4,a5,-1
ffffffffc020254c:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020254e:	cb11                	beqz	a4,ffffffffc0202562 <page_remove+0x68>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202550:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202554:	12048073          	sfence.vma	s1
}
ffffffffc0202558:	60e2                	ld	ra,24(sp)
ffffffffc020255a:	6442                	ld	s0,16(sp)
ffffffffc020255c:	64a2                	ld	s1,8(sp)
ffffffffc020255e:	6105                	addi	sp,sp,32
ffffffffc0202560:	8082                	ret
            free_page(page);
ffffffffc0202562:	4585                	li	a1,1
ffffffffc0202564:	96fff0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
ffffffffc0202568:	b7e5                	j	ffffffffc0202550 <page_remove+0x56>
ffffffffc020256a:	8c5ff0ef          	jal	ra,ffffffffc0201e2e <pa2page.part.4>

ffffffffc020256e <page_insert>:
{
ffffffffc020256e:	7179                	addi	sp,sp,-48
ffffffffc0202570:	e44e                	sd	s3,8(sp)
ffffffffc0202572:	89b2                	mv	s3,a2
ffffffffc0202574:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202576:	4605                	li	a2,1
{
ffffffffc0202578:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020257a:	85ce                	mv	a1,s3
{
ffffffffc020257c:	ec26                	sd	s1,24(sp)
ffffffffc020257e:	f406                	sd	ra,40(sp)
ffffffffc0202580:	e84a                	sd	s2,16(sp)
ffffffffc0202582:	e052                	sd	s4,0(sp)
ffffffffc0202584:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202586:	9d3ff0ef          	jal	ra,ffffffffc0201f58 <get_pte>
    if (ptep == NULL)
ffffffffc020258a:	cd49                	beqz	a0,ffffffffc0202624 <page_insert+0xb6>
    page->ref += 1;
ffffffffc020258c:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc020258e:	611c                	ld	a5,0(a0)
ffffffffc0202590:	892a                	mv	s2,a0
ffffffffc0202592:	0016871b          	addiw	a4,a3,1
ffffffffc0202596:	c018                	sw	a4,0(s0)
ffffffffc0202598:	0017f713          	andi	a4,a5,1
ffffffffc020259c:	ef05                	bnez	a4,ffffffffc02025d4 <page_insert+0x66>
ffffffffc020259e:	000aa797          	auipc	a5,0xaa
ffffffffc02025a2:	f6a78793          	addi	a5,a5,-150 # ffffffffc02ac508 <pages>
ffffffffc02025a6:	6398                	ld	a4,0(a5)
    return page - pages + nbase;
ffffffffc02025a8:	8c19                	sub	s0,s0,a4
ffffffffc02025aa:	000806b7          	lui	a3,0x80
ffffffffc02025ae:	8419                	srai	s0,s0,0x6
ffffffffc02025b0:	9436                	add	s0,s0,a3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02025b2:	042a                	slli	s0,s0,0xa
ffffffffc02025b4:	8c45                	or	s0,s0,s1
ffffffffc02025b6:	00146413          	ori	s0,s0,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02025ba:	00893023          	sd	s0,0(s2)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025be:	12098073          	sfence.vma	s3
    return 0;
ffffffffc02025c2:	4501                	li	a0,0
}
ffffffffc02025c4:	70a2                	ld	ra,40(sp)
ffffffffc02025c6:	7402                	ld	s0,32(sp)
ffffffffc02025c8:	64e2                	ld	s1,24(sp)
ffffffffc02025ca:	6942                	ld	s2,16(sp)
ffffffffc02025cc:	69a2                	ld	s3,8(sp)
ffffffffc02025ce:	6a02                	ld	s4,0(sp)
ffffffffc02025d0:	6145                	addi	sp,sp,48
ffffffffc02025d2:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc02025d4:	000aa717          	auipc	a4,0xaa
ffffffffc02025d8:	ec470713          	addi	a4,a4,-316 # ffffffffc02ac498 <npage>
ffffffffc02025dc:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc02025de:	078a                	slli	a5,a5,0x2
ffffffffc02025e0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02025e2:	04e7f363          	bleu	a4,a5,ffffffffc0202628 <page_insert+0xba>
    return &pages[PPN(pa) - nbase];
ffffffffc02025e6:	000aaa17          	auipc	s4,0xaa
ffffffffc02025ea:	f22a0a13          	addi	s4,s4,-222 # ffffffffc02ac508 <pages>
ffffffffc02025ee:	000a3703          	ld	a4,0(s4)
ffffffffc02025f2:	fff80537          	lui	a0,0xfff80
ffffffffc02025f6:	953e                	add	a0,a0,a5
ffffffffc02025f8:	051a                	slli	a0,a0,0x6
ffffffffc02025fa:	953a                	add	a0,a0,a4
        if (p == page)
ffffffffc02025fc:	00a40a63          	beq	s0,a0,ffffffffc0202610 <page_insert+0xa2>
    page->ref -= 1;
ffffffffc0202600:	411c                	lw	a5,0(a0)
ffffffffc0202602:	fff7869b          	addiw	a3,a5,-1
ffffffffc0202606:	c114                	sw	a3,0(a0)
        if (page_ref(page) ==
ffffffffc0202608:	c691                	beqz	a3,ffffffffc0202614 <page_insert+0xa6>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020260a:	12098073          	sfence.vma	s3
ffffffffc020260e:	bf69                	j	ffffffffc02025a8 <page_insert+0x3a>
ffffffffc0202610:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202612:	bf59                	j	ffffffffc02025a8 <page_insert+0x3a>
            free_page(page);
ffffffffc0202614:	4585                	li	a1,1
ffffffffc0202616:	8bdff0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
ffffffffc020261a:	000a3703          	ld	a4,0(s4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020261e:	12098073          	sfence.vma	s3
ffffffffc0202622:	b759                	j	ffffffffc02025a8 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202624:	5571                	li	a0,-4
ffffffffc0202626:	bf79                	j	ffffffffc02025c4 <page_insert+0x56>
ffffffffc0202628:	807ff0ef          	jal	ra,ffffffffc0201e2e <pa2page.part.4>

ffffffffc020262c <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020262c:	00005797          	auipc	a5,0x5
ffffffffc0202630:	cec78793          	addi	a5,a5,-788 # ffffffffc0207318 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202634:	638c                	ld	a1,0(a5)
{
ffffffffc0202636:	715d                	addi	sp,sp,-80
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202638:	00005517          	auipc	a0,0x5
ffffffffc020263c:	e7850513          	addi	a0,a0,-392 # ffffffffc02074b0 <default_pmm_manager+0x198>
{
ffffffffc0202640:	e486                	sd	ra,72(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202642:	000aa717          	auipc	a4,0xaa
ffffffffc0202646:	eaf73723          	sd	a5,-338(a4) # ffffffffc02ac4f0 <pmm_manager>
{
ffffffffc020264a:	e0a2                	sd	s0,64(sp)
ffffffffc020264c:	fc26                	sd	s1,56(sp)
ffffffffc020264e:	f84a                	sd	s2,48(sp)
ffffffffc0202650:	f44e                	sd	s3,40(sp)
ffffffffc0202652:	f052                	sd	s4,32(sp)
ffffffffc0202654:	ec56                	sd	s5,24(sp)
ffffffffc0202656:	e85a                	sd	s6,16(sp)
ffffffffc0202658:	e45e                	sd	s7,8(sp)
ffffffffc020265a:	e062                	sd	s8,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020265c:	000aa417          	auipc	s0,0xaa
ffffffffc0202660:	e9440413          	addi	s0,s0,-364 # ffffffffc02ac4f0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202664:	b2bfd0ef          	jal	ra,ffffffffc020018e <cprintf>
    pmm_manager->init();
ffffffffc0202668:	601c                	ld	a5,0(s0)
ffffffffc020266a:	000aa497          	auipc	s1,0xaa
ffffffffc020266e:	e2e48493          	addi	s1,s1,-466 # ffffffffc02ac498 <npage>
ffffffffc0202672:	000aa917          	auipc	s2,0xaa
ffffffffc0202676:	e9690913          	addi	s2,s2,-362 # ffffffffc02ac508 <pages>
ffffffffc020267a:	679c                	ld	a5,8(a5)
ffffffffc020267c:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc020267e:	57f5                	li	a5,-3
ffffffffc0202680:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0202682:	00005517          	auipc	a0,0x5
ffffffffc0202686:	e4650513          	addi	a0,a0,-442 # ffffffffc02074c8 <default_pmm_manager+0x1b0>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc020268a:	000aa717          	auipc	a4,0xaa
ffffffffc020268e:	e6f73723          	sd	a5,-402(a4) # ffffffffc02ac4f8 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc0202692:	afdfd0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202696:	46c5                	li	a3,17
ffffffffc0202698:	06ee                	slli	a3,a3,0x1b
ffffffffc020269a:	40100613          	li	a2,1025
ffffffffc020269e:	16fd                	addi	a3,a3,-1
ffffffffc02026a0:	0656                	slli	a2,a2,0x15
ffffffffc02026a2:	07e005b7          	lui	a1,0x7e00
ffffffffc02026a6:	00005517          	auipc	a0,0x5
ffffffffc02026aa:	e3a50513          	addi	a0,a0,-454 # ffffffffc02074e0 <default_pmm_manager+0x1c8>
ffffffffc02026ae:	ae1fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026b2:	777d                	lui	a4,0xfffff
ffffffffc02026b4:	000ab797          	auipc	a5,0xab
ffffffffc02026b8:	f4b78793          	addi	a5,a5,-181 # ffffffffc02ad5ff <end+0xfff>
ffffffffc02026bc:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc02026be:	00088737          	lui	a4,0x88
ffffffffc02026c2:	000aa697          	auipc	a3,0xaa
ffffffffc02026c6:	dce6bb23          	sd	a4,-554(a3) # ffffffffc02ac498 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026ca:	000aa717          	auipc	a4,0xaa
ffffffffc02026ce:	e2f73f23          	sd	a5,-450(a4) # ffffffffc02ac508 <pages>
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02026d2:	4701                	li	a4,0
ffffffffc02026d4:	4685                	li	a3,1
ffffffffc02026d6:	fff80837          	lui	a6,0xfff80
ffffffffc02026da:	a019                	j	ffffffffc02026e0 <pmm_init+0xb4>
ffffffffc02026dc:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc02026e0:	00671613          	slli	a2,a4,0x6
ffffffffc02026e4:	97b2                	add	a5,a5,a2
ffffffffc02026e6:	07a1                	addi	a5,a5,8
ffffffffc02026e8:	40d7b02f          	amoor.d	zero,a3,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02026ec:	6090                	ld	a2,0(s1)
ffffffffc02026ee:	0705                	addi	a4,a4,1
ffffffffc02026f0:	010607b3          	add	a5,a2,a6
ffffffffc02026f4:	fef764e3          	bltu	a4,a5,ffffffffc02026dc <pmm_init+0xb0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02026f8:	00093503          	ld	a0,0(s2)
ffffffffc02026fc:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202700:	00661693          	slli	a3,a2,0x6
ffffffffc0202704:	97aa                	add	a5,a5,a0
ffffffffc0202706:	96be                	add	a3,a3,a5
ffffffffc0202708:	c02007b7          	lui	a5,0xc0200
ffffffffc020270c:	7af6ed63          	bltu	a3,a5,ffffffffc0202ec6 <pmm_init+0x89a>
ffffffffc0202710:	000aa997          	auipc	s3,0xaa
ffffffffc0202714:	de898993          	addi	s3,s3,-536 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc0202718:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end)
ffffffffc020271c:	47c5                	li	a5,17
ffffffffc020271e:	07ee                	slli	a5,a5,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202720:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202722:	02f6f763          	bleu	a5,a3,ffffffffc0202750 <pmm_init+0x124>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202726:	6585                	lui	a1,0x1
ffffffffc0202728:	15fd                	addi	a1,a1,-1
ffffffffc020272a:	96ae                	add	a3,a3,a1
    if (PPN(pa) >= npage) {
ffffffffc020272c:	00c6d713          	srli	a4,a3,0xc
ffffffffc0202730:	48c77a63          	bleu	a2,a4,ffffffffc0202bc4 <pmm_init+0x598>
    pmm_manager->init_memmap(base, n);
ffffffffc0202734:	6010                	ld	a2,0(s0)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202736:	75fd                	lui	a1,0xfffff
ffffffffc0202738:	8eed                	and	a3,a3,a1
    return &pages[PPN(pa) - nbase];
ffffffffc020273a:	9742                	add	a4,a4,a6
    pmm_manager->init_memmap(base, n);
ffffffffc020273c:	6a10                	ld	a2,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020273e:	40d786b3          	sub	a3,a5,a3
ffffffffc0202742:	071a                	slli	a4,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202744:	00c6d593          	srli	a1,a3,0xc
ffffffffc0202748:	953a                	add	a0,a0,a4
ffffffffc020274a:	9602                	jalr	a2
ffffffffc020274c:	0009b583          	ld	a1,0(s3)
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202750:	00005517          	auipc	a0,0x5
ffffffffc0202754:	db850513          	addi	a0,a0,-584 # ffffffffc0207508 <default_pmm_manager+0x1f0>
ffffffffc0202758:	a37fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc020275c:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t *)boot_page_table_sv39;
ffffffffc020275e:	000aa417          	auipc	s0,0xaa
ffffffffc0202762:	d3240413          	addi	s0,s0,-718 # ffffffffc02ac490 <boot_pgdir>
    pmm_manager->check();
ffffffffc0202766:	7b9c                	ld	a5,48(a5)
ffffffffc0202768:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020276a:	00005517          	auipc	a0,0x5
ffffffffc020276e:	db650513          	addi	a0,a0,-586 # ffffffffc0207520 <default_pmm_manager+0x208>
ffffffffc0202772:	a1dfd0ef          	jal	ra,ffffffffc020018e <cprintf>
    boot_pgdir = (pte_t *)boot_page_table_sv39;
ffffffffc0202776:	00009697          	auipc	a3,0x9
ffffffffc020277a:	88a68693          	addi	a3,a3,-1910 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc020277e:	000aa797          	auipc	a5,0xaa
ffffffffc0202782:	d0d7b923          	sd	a3,-750(a5) # ffffffffc02ac490 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0202786:	c02007b7          	lui	a5,0xc0200
ffffffffc020278a:	10f6eae3          	bltu	a3,a5,ffffffffc020309e <pmm_init+0xa72>
ffffffffc020278e:	0009b783          	ld	a5,0(s3)
ffffffffc0202792:	8e9d                	sub	a3,a3,a5
ffffffffc0202794:	000aa797          	auipc	a5,0xaa
ffffffffc0202798:	d6d7b623          	sd	a3,-660(a5) # ffffffffc02ac500 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();
ffffffffc020279c:	f7cff0ef          	jal	ra,ffffffffc0201f18 <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02027a0:	6098                	ld	a4,0(s1)
ffffffffc02027a2:	c80007b7          	lui	a5,0xc8000
ffffffffc02027a6:	83b1                	srli	a5,a5,0xc
    nr_free_store = nr_free_pages();
ffffffffc02027a8:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02027aa:	0ce7eae3          	bltu	a5,a4,ffffffffc020307e <pmm_init+0xa52>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02027ae:	6008                	ld	a0,0(s0)
ffffffffc02027b0:	44050463          	beqz	a0,ffffffffc0202bf8 <pmm_init+0x5cc>
ffffffffc02027b4:	6785                	lui	a5,0x1
ffffffffc02027b6:	17fd                	addi	a5,a5,-1
ffffffffc02027b8:	8fe9                	and	a5,a5,a0
ffffffffc02027ba:	2781                	sext.w	a5,a5
ffffffffc02027bc:	42079e63          	bnez	a5,ffffffffc0202bf8 <pmm_init+0x5cc>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02027c0:	4601                	li	a2,0
ffffffffc02027c2:	4581                	li	a1,0
ffffffffc02027c4:	967ff0ef          	jal	ra,ffffffffc020212a <get_page>
ffffffffc02027c8:	78051b63          	bnez	a0,ffffffffc0202f5e <pmm_init+0x932>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc02027cc:	4505                	li	a0,1
ffffffffc02027ce:	e7cff0ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc02027d2:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02027d4:	6008                	ld	a0,0(s0)
ffffffffc02027d6:	4681                	li	a3,0
ffffffffc02027d8:	4601                	li	a2,0
ffffffffc02027da:	85d6                	mv	a1,s5
ffffffffc02027dc:	d93ff0ef          	jal	ra,ffffffffc020256e <page_insert>
ffffffffc02027e0:	7a051f63          	bnez	a0,ffffffffc0202f9e <pmm_init+0x972>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc02027e4:	6008                	ld	a0,0(s0)
ffffffffc02027e6:	4601                	li	a2,0
ffffffffc02027e8:	4581                	li	a1,0
ffffffffc02027ea:	f6eff0ef          	jal	ra,ffffffffc0201f58 <get_pte>
ffffffffc02027ee:	78050863          	beqz	a0,ffffffffc0202f7e <pmm_init+0x952>
    assert(pte2page(*ptep) == p1);
ffffffffc02027f2:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02027f4:	0017f713          	andi	a4,a5,1
ffffffffc02027f8:	3e070463          	beqz	a4,ffffffffc0202be0 <pmm_init+0x5b4>
    if (PPN(pa) >= npage) {
ffffffffc02027fc:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02027fe:	078a                	slli	a5,a5,0x2
ffffffffc0202800:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202802:	3ce7f163          	bleu	a4,a5,ffffffffc0202bc4 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202806:	00093683          	ld	a3,0(s2)
ffffffffc020280a:	fff80637          	lui	a2,0xfff80
ffffffffc020280e:	97b2                	add	a5,a5,a2
ffffffffc0202810:	079a                	slli	a5,a5,0x6
ffffffffc0202812:	97b6                	add	a5,a5,a3
ffffffffc0202814:	72fa9563          	bne	s5,a5,ffffffffc0202f3e <pmm_init+0x912>
    assert(page_ref(p1) == 1);
ffffffffc0202818:	000aab83          	lw	s7,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
ffffffffc020281c:	4785                	li	a5,1
ffffffffc020281e:	70fb9063          	bne	s7,a5,ffffffffc0202f1e <pmm_init+0x8f2>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0202822:	6008                	ld	a0,0(s0)
ffffffffc0202824:	76fd                	lui	a3,0xfffff
ffffffffc0202826:	611c                	ld	a5,0(a0)
ffffffffc0202828:	078a                	slli	a5,a5,0x2
ffffffffc020282a:	8ff5                	and	a5,a5,a3
ffffffffc020282c:	00c7d613          	srli	a2,a5,0xc
ffffffffc0202830:	66e67e63          	bleu	a4,a2,ffffffffc0202eac <pmm_init+0x880>
ffffffffc0202834:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202838:	97e2                	add	a5,a5,s8
ffffffffc020283a:	0007bb03          	ld	s6,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
ffffffffc020283e:	0b0a                	slli	s6,s6,0x2
ffffffffc0202840:	00db7b33          	and	s6,s6,a3
ffffffffc0202844:	00cb5793          	srli	a5,s6,0xc
ffffffffc0202848:	56e7f863          	bleu	a4,a5,ffffffffc0202db8 <pmm_init+0x78c>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020284c:	4601                	li	a2,0
ffffffffc020284e:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202850:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202852:	f06ff0ef          	jal	ra,ffffffffc0201f58 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202856:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202858:	55651063          	bne	a0,s6,ffffffffc0202d98 <pmm_init+0x76c>

    p2 = alloc_page();
ffffffffc020285c:	4505                	li	a0,1
ffffffffc020285e:	decff0ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0202862:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202864:	6008                	ld	a0,0(s0)
ffffffffc0202866:	46d1                	li	a3,20
ffffffffc0202868:	6605                	lui	a2,0x1
ffffffffc020286a:	85da                	mv	a1,s6
ffffffffc020286c:	d03ff0ef          	jal	ra,ffffffffc020256e <page_insert>
ffffffffc0202870:	50051463          	bnez	a0,ffffffffc0202d78 <pmm_init+0x74c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202874:	6008                	ld	a0,0(s0)
ffffffffc0202876:	4601                	li	a2,0
ffffffffc0202878:	6585                	lui	a1,0x1
ffffffffc020287a:	edeff0ef          	jal	ra,ffffffffc0201f58 <get_pte>
ffffffffc020287e:	4c050d63          	beqz	a0,ffffffffc0202d58 <pmm_init+0x72c>
    assert(*ptep & PTE_U);
ffffffffc0202882:	611c                	ld	a5,0(a0)
ffffffffc0202884:	0107f713          	andi	a4,a5,16
ffffffffc0202888:	4a070863          	beqz	a4,ffffffffc0202d38 <pmm_init+0x70c>
    assert(*ptep & PTE_W);
ffffffffc020288c:	8b91                	andi	a5,a5,4
ffffffffc020288e:	48078563          	beqz	a5,ffffffffc0202d18 <pmm_init+0x6ec>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202892:	6008                	ld	a0,0(s0)
ffffffffc0202894:	611c                	ld	a5,0(a0)
ffffffffc0202896:	8bc1                	andi	a5,a5,16
ffffffffc0202898:	46078063          	beqz	a5,ffffffffc0202cf8 <pmm_init+0x6cc>
    assert(page_ref(p2) == 1);
ffffffffc020289c:	000b2783          	lw	a5,0(s6) # 200000 <_binary_obj___user_exit_out_size+0x1f5580>
ffffffffc02028a0:	43779c63          	bne	a5,s7,ffffffffc0202cd8 <pmm_init+0x6ac>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02028a4:	4681                	li	a3,0
ffffffffc02028a6:	6605                	lui	a2,0x1
ffffffffc02028a8:	85d6                	mv	a1,s5
ffffffffc02028aa:	cc5ff0ef          	jal	ra,ffffffffc020256e <page_insert>
ffffffffc02028ae:	40051563          	bnez	a0,ffffffffc0202cb8 <pmm_init+0x68c>
    assert(page_ref(p1) == 2);
ffffffffc02028b2:	000aa703          	lw	a4,0(s5)
ffffffffc02028b6:	4789                	li	a5,2
ffffffffc02028b8:	3ef71063          	bne	a4,a5,ffffffffc0202c98 <pmm_init+0x66c>
    assert(page_ref(p2) == 0);
ffffffffc02028bc:	000b2783          	lw	a5,0(s6)
ffffffffc02028c0:	3a079c63          	bnez	a5,ffffffffc0202c78 <pmm_init+0x64c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02028c4:	6008                	ld	a0,0(s0)
ffffffffc02028c6:	4601                	li	a2,0
ffffffffc02028c8:	6585                	lui	a1,0x1
ffffffffc02028ca:	e8eff0ef          	jal	ra,ffffffffc0201f58 <get_pte>
ffffffffc02028ce:	38050563          	beqz	a0,ffffffffc0202c58 <pmm_init+0x62c>
    assert(pte2page(*ptep) == p1);
ffffffffc02028d2:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02028d4:	00177793          	andi	a5,a4,1
ffffffffc02028d8:	30078463          	beqz	a5,ffffffffc0202be0 <pmm_init+0x5b4>
    if (PPN(pa) >= npage) {
ffffffffc02028dc:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028de:	00271793          	slli	a5,a4,0x2
ffffffffc02028e2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02028e4:	2ed7f063          	bleu	a3,a5,ffffffffc0202bc4 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc02028e8:	00093683          	ld	a3,0(s2)
ffffffffc02028ec:	fff80637          	lui	a2,0xfff80
ffffffffc02028f0:	97b2                	add	a5,a5,a2
ffffffffc02028f2:	079a                	slli	a5,a5,0x6
ffffffffc02028f4:	97b6                	add	a5,a5,a3
ffffffffc02028f6:	32fa9163          	bne	s5,a5,ffffffffc0202c18 <pmm_init+0x5ec>
    assert((*ptep & PTE_U) == 0);
ffffffffc02028fa:	8b41                	andi	a4,a4,16
ffffffffc02028fc:	70071163          	bnez	a4,ffffffffc0202ffe <pmm_init+0x9d2>

    page_remove(boot_pgdir, 0x0);
ffffffffc0202900:	6008                	ld	a0,0(s0)
ffffffffc0202902:	4581                	li	a1,0
ffffffffc0202904:	bf7ff0ef          	jal	ra,ffffffffc02024fa <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202908:	000aa703          	lw	a4,0(s5)
ffffffffc020290c:	4785                	li	a5,1
ffffffffc020290e:	6cf71863          	bne	a4,a5,ffffffffc0202fde <pmm_init+0x9b2>
    assert(page_ref(p2) == 0);
ffffffffc0202912:	000b2783          	lw	a5,0(s6)
ffffffffc0202916:	6a079463          	bnez	a5,ffffffffc0202fbe <pmm_init+0x992>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc020291a:	6008                	ld	a0,0(s0)
ffffffffc020291c:	6585                	lui	a1,0x1
ffffffffc020291e:	bddff0ef          	jal	ra,ffffffffc02024fa <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202922:	000aa783          	lw	a5,0(s5)
ffffffffc0202926:	50079363          	bnez	a5,ffffffffc0202e2c <pmm_init+0x800>
    assert(page_ref(p2) == 0);
ffffffffc020292a:	000b2783          	lw	a5,0(s6)
ffffffffc020292e:	4c079f63          	bnez	a5,ffffffffc0202e0c <pmm_init+0x7e0>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0202932:	00043a83          	ld	s5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202936:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202938:	000ab783          	ld	a5,0(s5)
ffffffffc020293c:	078a                	slli	a5,a5,0x2
ffffffffc020293e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202940:	28c7f263          	bleu	a2,a5,ffffffffc0202bc4 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202944:	fff80737          	lui	a4,0xfff80
ffffffffc0202948:	00093503          	ld	a0,0(s2)
ffffffffc020294c:	97ba                	add	a5,a5,a4
ffffffffc020294e:	079a                	slli	a5,a5,0x6
ffffffffc0202950:	00f50733          	add	a4,a0,a5
ffffffffc0202954:	4314                	lw	a3,0(a4)
ffffffffc0202956:	4705                	li	a4,1
ffffffffc0202958:	48e69a63          	bne	a3,a4,ffffffffc0202dec <pmm_init+0x7c0>
    return page - pages + nbase;
ffffffffc020295c:	8799                	srai	a5,a5,0x6
ffffffffc020295e:	00080b37          	lui	s6,0x80
    return KADDR(page2pa(page));
ffffffffc0202962:	577d                	li	a4,-1
    return page - pages + nbase;
ffffffffc0202964:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc0202966:	8331                	srli	a4,a4,0xc
ffffffffc0202968:	8f7d                	and	a4,a4,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc020296a:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020296c:	46c77363          	bleu	a2,a4,ffffffffc0202dd2 <pmm_init+0x7a6>

    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202970:	0009b683          	ld	a3,0(s3)
ffffffffc0202974:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202976:	639c                	ld	a5,0(a5)
ffffffffc0202978:	078a                	slli	a5,a5,0x2
ffffffffc020297a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020297c:	24c7f463          	bleu	a2,a5,ffffffffc0202bc4 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202980:	416787b3          	sub	a5,a5,s6
ffffffffc0202984:	079a                	slli	a5,a5,0x6
ffffffffc0202986:	953e                	add	a0,a0,a5
ffffffffc0202988:	4585                	li	a1,1
ffffffffc020298a:	d48ff0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020298e:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage) {
ffffffffc0202992:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202994:	078a                	slli	a5,a5,0x2
ffffffffc0202996:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202998:	22e7f663          	bleu	a4,a5,ffffffffc0202bc4 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc020299c:	00093503          	ld	a0,0(s2)
ffffffffc02029a0:	416787b3          	sub	a5,a5,s6
ffffffffc02029a4:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc02029a6:	953e                	add	a0,a0,a5
ffffffffc02029a8:	4585                	li	a1,1
ffffffffc02029aa:	d28ff0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc02029ae:	601c                	ld	a5,0(s0)
ffffffffc02029b0:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc02029b4:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02029b8:	d60ff0ef          	jal	ra,ffffffffc0201f18 <nr_free_pages>
ffffffffc02029bc:	68aa1163          	bne	s4,a0,ffffffffc020303e <pmm_init+0xa12>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02029c0:	00005517          	auipc	a0,0x5
ffffffffc02029c4:	e7850513          	addi	a0,a0,-392 # ffffffffc0207838 <default_pmm_manager+0x520>
ffffffffc02029c8:	fc6fd0ef          	jal	ra,ffffffffc020018e <cprintf>
{
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();
ffffffffc02029cc:	d4cff0ef          	jal	ra,ffffffffc0201f18 <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02029d0:	6098                	ld	a4,0(s1)
ffffffffc02029d2:	c02007b7          	lui	a5,0xc0200
    nr_free_store = nr_free_pages();
ffffffffc02029d6:	8a2a                	mv	s4,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02029d8:	00c71693          	slli	a3,a4,0xc
ffffffffc02029dc:	18d7f563          	bleu	a3,a5,ffffffffc0202b66 <pmm_init+0x53a>
    {
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02029e0:	83b1                	srli	a5,a5,0xc
ffffffffc02029e2:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02029e4:	c0200ab7          	lui	s5,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02029e8:	1ae7f163          	bleu	a4,a5,ffffffffc0202b8a <pmm_init+0x55e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02029ec:	7bfd                	lui	s7,0xfffff
ffffffffc02029ee:	6b05                	lui	s6,0x1
ffffffffc02029f0:	a029                	j	ffffffffc02029fa <pmm_init+0x3ce>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02029f2:	00cad713          	srli	a4,s5,0xc
ffffffffc02029f6:	18f77a63          	bleu	a5,a4,ffffffffc0202b8a <pmm_init+0x55e>
ffffffffc02029fa:	0009b583          	ld	a1,0(s3)
ffffffffc02029fe:	4601                	li	a2,0
ffffffffc0202a00:	95d6                	add	a1,a1,s5
ffffffffc0202a02:	d56ff0ef          	jal	ra,ffffffffc0201f58 <get_pte>
ffffffffc0202a06:	16050263          	beqz	a0,ffffffffc0202b6a <pmm_init+0x53e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a0a:	611c                	ld	a5,0(a0)
ffffffffc0202a0c:	078a                	slli	a5,a5,0x2
ffffffffc0202a0e:	0177f7b3          	and	a5,a5,s7
ffffffffc0202a12:	19579963          	bne	a5,s5,ffffffffc0202ba4 <pmm_init+0x578>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a16:	609c                	ld	a5,0(s1)
ffffffffc0202a18:	9ada                	add	s5,s5,s6
ffffffffc0202a1a:	6008                	ld	a0,0(s0)
ffffffffc0202a1c:	00c79713          	slli	a4,a5,0xc
ffffffffc0202a20:	fceae9e3          	bltu	s5,a4,ffffffffc02029f2 <pmm_init+0x3c6>
    }

    assert(boot_pgdir[0] == 0);
ffffffffc0202a24:	611c                	ld	a5,0(a0)
ffffffffc0202a26:	62079c63          	bnez	a5,ffffffffc020305e <pmm_init+0xa32>

    struct Page *p;
    p = alloc_page();
ffffffffc0202a2a:	4505                	li	a0,1
ffffffffc0202a2c:	c1eff0ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0202a30:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a32:	6008                	ld	a0,0(s0)
ffffffffc0202a34:	4699                	li	a3,6
ffffffffc0202a36:	10000613          	li	a2,256
ffffffffc0202a3a:	85d6                	mv	a1,s5
ffffffffc0202a3c:	b33ff0ef          	jal	ra,ffffffffc020256e <page_insert>
ffffffffc0202a40:	1e051c63          	bnez	a0,ffffffffc0202c38 <pmm_init+0x60c>
    assert(page_ref(p) == 1);
ffffffffc0202a44:	000aa703          	lw	a4,0(s5) # ffffffffc0200000 <kern_entry>
ffffffffc0202a48:	4785                	li	a5,1
ffffffffc0202a4a:	44f71163          	bne	a4,a5,ffffffffc0202e8c <pmm_init+0x860>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202a4e:	6008                	ld	a0,0(s0)
ffffffffc0202a50:	6b05                	lui	s6,0x1
ffffffffc0202a52:	4699                	li	a3,6
ffffffffc0202a54:	100b0613          	addi	a2,s6,256 # 1100 <_binary_obj___user_faultread_out_size-0x8480>
ffffffffc0202a58:	85d6                	mv	a1,s5
ffffffffc0202a5a:	b15ff0ef          	jal	ra,ffffffffc020256e <page_insert>
ffffffffc0202a5e:	40051763          	bnez	a0,ffffffffc0202e6c <pmm_init+0x840>
    assert(page_ref(p) == 2);
ffffffffc0202a62:	000aa703          	lw	a4,0(s5)
ffffffffc0202a66:	4789                	li	a5,2
ffffffffc0202a68:	3ef71263          	bne	a4,a5,ffffffffc0202e4c <pmm_init+0x820>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202a6c:	00005597          	auipc	a1,0x5
ffffffffc0202a70:	f0458593          	addi	a1,a1,-252 # ffffffffc0207970 <default_pmm_manager+0x658>
ffffffffc0202a74:	10000513          	li	a0,256
ffffffffc0202a78:	2f7030ef          	jal	ra,ffffffffc020656e <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202a7c:	100b0593          	addi	a1,s6,256
ffffffffc0202a80:	10000513          	li	a0,256
ffffffffc0202a84:	2fd030ef          	jal	ra,ffffffffc0206580 <strcmp>
ffffffffc0202a88:	44051b63          	bnez	a0,ffffffffc0202ede <pmm_init+0x8b2>
    return page - pages + nbase;
ffffffffc0202a8c:	00093683          	ld	a3,0(s2)
ffffffffc0202a90:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202a94:	5b7d                	li	s6,-1
    return page - pages + nbase;
ffffffffc0202a96:	40da86b3          	sub	a3,s5,a3
ffffffffc0202a9a:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202a9c:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202a9e:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202aa0:	00cb5b13          	srli	s6,s6,0xc
ffffffffc0202aa4:	0166f733          	and	a4,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202aa8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202aaa:	10f77f63          	bleu	a5,a4,ffffffffc0202bc8 <pmm_init+0x59c>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202aae:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ab2:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202ab6:	96be                	add	a3,a3,a5
ffffffffc0202ab8:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fd52b00>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202abc:	26f030ef          	jal	ra,ffffffffc020652a <strlen>
ffffffffc0202ac0:	54051f63          	bnez	a0,ffffffffc020301e <pmm_init+0x9f2>

    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202ac4:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202ac8:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aca:	000bb683          	ld	a3,0(s7) # fffffffffffff000 <end+0x3fd52a00>
ffffffffc0202ace:	068a                	slli	a3,a3,0x2
ffffffffc0202ad0:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202ad2:	0ef6f963          	bleu	a5,a3,ffffffffc0202bc4 <pmm_init+0x598>
    return KADDR(page2pa(page));
ffffffffc0202ad6:	0166fb33          	and	s6,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ada:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202adc:	0efb7663          	bleu	a5,s6,ffffffffc0202bc8 <pmm_init+0x59c>
ffffffffc0202ae0:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc0202ae4:	4585                	li	a1,1
ffffffffc0202ae6:	8556                	mv	a0,s5
ffffffffc0202ae8:	99b6                	add	s3,s3,a3
ffffffffc0202aea:	be8ff0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aee:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0202af2:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202af4:	078a                	slli	a5,a5,0x2
ffffffffc0202af6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202af8:	0ce7f663          	bleu	a4,a5,ffffffffc0202bc4 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202afc:	00093503          	ld	a0,0(s2)
ffffffffc0202b00:	fff809b7          	lui	s3,0xfff80
ffffffffc0202b04:	97ce                	add	a5,a5,s3
ffffffffc0202b06:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0202b08:	953e                	add	a0,a0,a5
ffffffffc0202b0a:	4585                	li	a1,1
ffffffffc0202b0c:	bc6ff0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b10:	000bb783          	ld	a5,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc0202b14:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b16:	078a                	slli	a5,a5,0x2
ffffffffc0202b18:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202b1a:	0ae7f563          	bleu	a4,a5,ffffffffc0202bc4 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b1e:	00093503          	ld	a0,0(s2)
ffffffffc0202b22:	97ce                	add	a5,a5,s3
ffffffffc0202b24:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0202b26:	953e                	add	a0,a0,a5
ffffffffc0202b28:	4585                	li	a1,1
ffffffffc0202b2a:	ba8ff0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc0202b2e:	601c                	ld	a5,0(s0)
ffffffffc0202b30:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>
  asm volatile("sfence.vma");
ffffffffc0202b34:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b38:	be0ff0ef          	jal	ra,ffffffffc0201f18 <nr_free_pages>
ffffffffc0202b3c:	3caa1163          	bne	s4,a0,ffffffffc0202efe <pmm_init+0x8d2>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202b40:	00005517          	auipc	a0,0x5
ffffffffc0202b44:	ea850513          	addi	a0,a0,-344 # ffffffffc02079e8 <default_pmm_manager+0x6d0>
ffffffffc0202b48:	e46fd0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0202b4c:	6406                	ld	s0,64(sp)
ffffffffc0202b4e:	60a6                	ld	ra,72(sp)
ffffffffc0202b50:	74e2                	ld	s1,56(sp)
ffffffffc0202b52:	7942                	ld	s2,48(sp)
ffffffffc0202b54:	79a2                	ld	s3,40(sp)
ffffffffc0202b56:	7a02                	ld	s4,32(sp)
ffffffffc0202b58:	6ae2                	ld	s5,24(sp)
ffffffffc0202b5a:	6b42                	ld	s6,16(sp)
ffffffffc0202b5c:	6ba2                	ld	s7,8(sp)
ffffffffc0202b5e:	6c02                	ld	s8,0(sp)
ffffffffc0202b60:	6161                	addi	sp,sp,80
    kmalloc_init();
ffffffffc0202b62:	8c8ff06f          	j	ffffffffc0201c2a <kmalloc_init>
ffffffffc0202b66:	6008                	ld	a0,0(s0)
ffffffffc0202b68:	bd75                	j	ffffffffc0202a24 <pmm_init+0x3f8>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b6a:	00005697          	auipc	a3,0x5
ffffffffc0202b6e:	cee68693          	addi	a3,a3,-786 # ffffffffc0207858 <default_pmm_manager+0x540>
ffffffffc0202b72:	00004617          	auipc	a2,0x4
ffffffffc0202b76:	05e60613          	addi	a2,a2,94 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202b7a:	26d00593          	li	a1,621
ffffffffc0202b7e:	00005517          	auipc	a0,0x5
ffffffffc0202b82:	90a50513          	addi	a0,a0,-1782 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202b86:	8fffd0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0202b8a:	86d6                	mv	a3,s5
ffffffffc0202b8c:	00004617          	auipc	a2,0x4
ffffffffc0202b90:	7dc60613          	addi	a2,a2,2012 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc0202b94:	26d00593          	li	a1,621
ffffffffc0202b98:	00005517          	auipc	a0,0x5
ffffffffc0202b9c:	8f050513          	addi	a0,a0,-1808 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202ba0:	8e5fd0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202ba4:	00005697          	auipc	a3,0x5
ffffffffc0202ba8:	cf468693          	addi	a3,a3,-780 # ffffffffc0207898 <default_pmm_manager+0x580>
ffffffffc0202bac:	00004617          	auipc	a2,0x4
ffffffffc0202bb0:	02460613          	addi	a2,a2,36 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202bb4:	26e00593          	li	a1,622
ffffffffc0202bb8:	00005517          	auipc	a0,0x5
ffffffffc0202bbc:	8d050513          	addi	a0,a0,-1840 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202bc0:	8c5fd0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0202bc4:	a6aff0ef          	jal	ra,ffffffffc0201e2e <pa2page.part.4>
    return KADDR(page2pa(page));
ffffffffc0202bc8:	00004617          	auipc	a2,0x4
ffffffffc0202bcc:	7a060613          	addi	a2,a2,1952 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc0202bd0:	06900593          	li	a1,105
ffffffffc0202bd4:	00004517          	auipc	a0,0x4
ffffffffc0202bd8:	7bc50513          	addi	a0,a0,1980 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0202bdc:	8a9fd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202be0:	00005617          	auipc	a2,0x5
ffffffffc0202be4:	a4060613          	addi	a2,a2,-1472 # ffffffffc0207620 <default_pmm_manager+0x308>
ffffffffc0202be8:	07400593          	li	a1,116
ffffffffc0202bec:	00004517          	auipc	a0,0x4
ffffffffc0202bf0:	7a450513          	addi	a0,a0,1956 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0202bf4:	891fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202bf8:	00005697          	auipc	a3,0x5
ffffffffc0202bfc:	96868693          	addi	a3,a3,-1688 # ffffffffc0207560 <default_pmm_manager+0x248>
ffffffffc0202c00:	00004617          	auipc	a2,0x4
ffffffffc0202c04:	fd060613          	addi	a2,a2,-48 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202c08:	22f00593          	li	a1,559
ffffffffc0202c0c:	00005517          	auipc	a0,0x5
ffffffffc0202c10:	87c50513          	addi	a0,a0,-1924 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202c14:	871fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c18:	00005697          	auipc	a3,0x5
ffffffffc0202c1c:	a3068693          	addi	a3,a3,-1488 # ffffffffc0207648 <default_pmm_manager+0x330>
ffffffffc0202c20:	00004617          	auipc	a2,0x4
ffffffffc0202c24:	fb060613          	addi	a2,a2,-80 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202c28:	24b00593          	li	a1,587
ffffffffc0202c2c:	00005517          	auipc	a0,0x5
ffffffffc0202c30:	85c50513          	addi	a0,a0,-1956 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202c34:	851fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202c38:	00005697          	auipc	a3,0x5
ffffffffc0202c3c:	c9068693          	addi	a3,a3,-880 # ffffffffc02078c8 <default_pmm_manager+0x5b0>
ffffffffc0202c40:	00004617          	auipc	a2,0x4
ffffffffc0202c44:	f9060613          	addi	a2,a2,-112 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202c48:	27500593          	li	a1,629
ffffffffc0202c4c:	00005517          	auipc	a0,0x5
ffffffffc0202c50:	83c50513          	addi	a0,a0,-1988 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202c54:	831fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202c58:	00005697          	auipc	a3,0x5
ffffffffc0202c5c:	a8068693          	addi	a3,a3,-1408 # ffffffffc02076d8 <default_pmm_manager+0x3c0>
ffffffffc0202c60:	00004617          	auipc	a2,0x4
ffffffffc0202c64:	f7060613          	addi	a2,a2,-144 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202c68:	24a00593          	li	a1,586
ffffffffc0202c6c:	00005517          	auipc	a0,0x5
ffffffffc0202c70:	81c50513          	addi	a0,a0,-2020 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202c74:	811fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202c78:	00005697          	auipc	a3,0x5
ffffffffc0202c7c:	b2868693          	addi	a3,a3,-1240 # ffffffffc02077a0 <default_pmm_manager+0x488>
ffffffffc0202c80:	00004617          	auipc	a2,0x4
ffffffffc0202c84:	f5060613          	addi	a2,a2,-176 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202c88:	24900593          	li	a1,585
ffffffffc0202c8c:	00004517          	auipc	a0,0x4
ffffffffc0202c90:	7fc50513          	addi	a0,a0,2044 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202c94:	ff0fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202c98:	00005697          	auipc	a3,0x5
ffffffffc0202c9c:	af068693          	addi	a3,a3,-1296 # ffffffffc0207788 <default_pmm_manager+0x470>
ffffffffc0202ca0:	00004617          	auipc	a2,0x4
ffffffffc0202ca4:	f3060613          	addi	a2,a2,-208 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202ca8:	24800593          	li	a1,584
ffffffffc0202cac:	00004517          	auipc	a0,0x4
ffffffffc0202cb0:	7dc50513          	addi	a0,a0,2012 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202cb4:	fd0fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202cb8:	00005697          	auipc	a3,0x5
ffffffffc0202cbc:	aa068693          	addi	a3,a3,-1376 # ffffffffc0207758 <default_pmm_manager+0x440>
ffffffffc0202cc0:	00004617          	auipc	a2,0x4
ffffffffc0202cc4:	f1060613          	addi	a2,a2,-240 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202cc8:	24700593          	li	a1,583
ffffffffc0202ccc:	00004517          	auipc	a0,0x4
ffffffffc0202cd0:	7bc50513          	addi	a0,a0,1980 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202cd4:	fb0fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202cd8:	00005697          	auipc	a3,0x5
ffffffffc0202cdc:	a6868693          	addi	a3,a3,-1432 # ffffffffc0207740 <default_pmm_manager+0x428>
ffffffffc0202ce0:	00004617          	auipc	a2,0x4
ffffffffc0202ce4:	ef060613          	addi	a2,a2,-272 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202ce8:	24500593          	li	a1,581
ffffffffc0202cec:	00004517          	auipc	a0,0x4
ffffffffc0202cf0:	79c50513          	addi	a0,a0,1948 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202cf4:	f90fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202cf8:	00005697          	auipc	a3,0x5
ffffffffc0202cfc:	a3068693          	addi	a3,a3,-1488 # ffffffffc0207728 <default_pmm_manager+0x410>
ffffffffc0202d00:	00004617          	auipc	a2,0x4
ffffffffc0202d04:	ed060613          	addi	a2,a2,-304 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202d08:	24400593          	li	a1,580
ffffffffc0202d0c:	00004517          	auipc	a0,0x4
ffffffffc0202d10:	77c50513          	addi	a0,a0,1916 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202d14:	f70fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202d18:	00005697          	auipc	a3,0x5
ffffffffc0202d1c:	a0068693          	addi	a3,a3,-1536 # ffffffffc0207718 <default_pmm_manager+0x400>
ffffffffc0202d20:	00004617          	auipc	a2,0x4
ffffffffc0202d24:	eb060613          	addi	a2,a2,-336 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202d28:	24300593          	li	a1,579
ffffffffc0202d2c:	00004517          	auipc	a0,0x4
ffffffffc0202d30:	75c50513          	addi	a0,a0,1884 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202d34:	f50fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202d38:	00005697          	auipc	a3,0x5
ffffffffc0202d3c:	9d068693          	addi	a3,a3,-1584 # ffffffffc0207708 <default_pmm_manager+0x3f0>
ffffffffc0202d40:	00004617          	auipc	a2,0x4
ffffffffc0202d44:	e9060613          	addi	a2,a2,-368 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202d48:	24200593          	li	a1,578
ffffffffc0202d4c:	00004517          	auipc	a0,0x4
ffffffffc0202d50:	73c50513          	addi	a0,a0,1852 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202d54:	f30fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202d58:	00005697          	auipc	a3,0x5
ffffffffc0202d5c:	98068693          	addi	a3,a3,-1664 # ffffffffc02076d8 <default_pmm_manager+0x3c0>
ffffffffc0202d60:	00004617          	auipc	a2,0x4
ffffffffc0202d64:	e7060613          	addi	a2,a2,-400 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202d68:	24100593          	li	a1,577
ffffffffc0202d6c:	00004517          	auipc	a0,0x4
ffffffffc0202d70:	71c50513          	addi	a0,a0,1820 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202d74:	f10fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202d78:	00005697          	auipc	a3,0x5
ffffffffc0202d7c:	92868693          	addi	a3,a3,-1752 # ffffffffc02076a0 <default_pmm_manager+0x388>
ffffffffc0202d80:	00004617          	auipc	a2,0x4
ffffffffc0202d84:	e5060613          	addi	a2,a2,-432 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202d88:	24000593          	li	a1,576
ffffffffc0202d8c:	00004517          	auipc	a0,0x4
ffffffffc0202d90:	6fc50513          	addi	a0,a0,1788 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202d94:	ef0fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202d98:	00005697          	auipc	a3,0x5
ffffffffc0202d9c:	8e068693          	addi	a3,a3,-1824 # ffffffffc0207678 <default_pmm_manager+0x360>
ffffffffc0202da0:	00004617          	auipc	a2,0x4
ffffffffc0202da4:	e3060613          	addi	a2,a2,-464 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202da8:	23d00593          	li	a1,573
ffffffffc0202dac:	00004517          	auipc	a0,0x4
ffffffffc0202db0:	6dc50513          	addi	a0,a0,1756 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202db4:	ed0fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202db8:	86da                	mv	a3,s6
ffffffffc0202dba:	00004617          	auipc	a2,0x4
ffffffffc0202dbe:	5ae60613          	addi	a2,a2,1454 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc0202dc2:	23c00593          	li	a1,572
ffffffffc0202dc6:	00004517          	auipc	a0,0x4
ffffffffc0202dca:	6c250513          	addi	a0,a0,1730 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202dce:	eb6fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202dd2:	86be                	mv	a3,a5
ffffffffc0202dd4:	00004617          	auipc	a2,0x4
ffffffffc0202dd8:	59460613          	addi	a2,a2,1428 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc0202ddc:	06900593          	li	a1,105
ffffffffc0202de0:	00004517          	auipc	a0,0x4
ffffffffc0202de4:	5b050513          	addi	a0,a0,1456 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0202de8:	e9cfd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0202dec:	00005697          	auipc	a3,0x5
ffffffffc0202df0:	9fc68693          	addi	a3,a3,-1540 # ffffffffc02077e8 <default_pmm_manager+0x4d0>
ffffffffc0202df4:	00004617          	auipc	a2,0x4
ffffffffc0202df8:	ddc60613          	addi	a2,a2,-548 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202dfc:	25600593          	li	a1,598
ffffffffc0202e00:	00004517          	auipc	a0,0x4
ffffffffc0202e04:	68850513          	addi	a0,a0,1672 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202e08:	e7cfd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202e0c:	00005697          	auipc	a3,0x5
ffffffffc0202e10:	99468693          	addi	a3,a3,-1644 # ffffffffc02077a0 <default_pmm_manager+0x488>
ffffffffc0202e14:	00004617          	auipc	a2,0x4
ffffffffc0202e18:	dbc60613          	addi	a2,a2,-580 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202e1c:	25400593          	li	a1,596
ffffffffc0202e20:	00004517          	auipc	a0,0x4
ffffffffc0202e24:	66850513          	addi	a0,a0,1640 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202e28:	e5cfd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202e2c:	00005697          	auipc	a3,0x5
ffffffffc0202e30:	9a468693          	addi	a3,a3,-1628 # ffffffffc02077d0 <default_pmm_manager+0x4b8>
ffffffffc0202e34:	00004617          	auipc	a2,0x4
ffffffffc0202e38:	d9c60613          	addi	a2,a2,-612 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202e3c:	25300593          	li	a1,595
ffffffffc0202e40:	00004517          	auipc	a0,0x4
ffffffffc0202e44:	64850513          	addi	a0,a0,1608 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202e48:	e3cfd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202e4c:	00005697          	auipc	a3,0x5
ffffffffc0202e50:	b0c68693          	addi	a3,a3,-1268 # ffffffffc0207958 <default_pmm_manager+0x640>
ffffffffc0202e54:	00004617          	auipc	a2,0x4
ffffffffc0202e58:	d7c60613          	addi	a2,a2,-644 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202e5c:	27800593          	li	a1,632
ffffffffc0202e60:	00004517          	auipc	a0,0x4
ffffffffc0202e64:	62850513          	addi	a0,a0,1576 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202e68:	e1cfd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202e6c:	00005697          	auipc	a3,0x5
ffffffffc0202e70:	aac68693          	addi	a3,a3,-1364 # ffffffffc0207918 <default_pmm_manager+0x600>
ffffffffc0202e74:	00004617          	auipc	a2,0x4
ffffffffc0202e78:	d5c60613          	addi	a2,a2,-676 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202e7c:	27700593          	li	a1,631
ffffffffc0202e80:	00004517          	auipc	a0,0x4
ffffffffc0202e84:	60850513          	addi	a0,a0,1544 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202e88:	dfcfd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202e8c:	00005697          	auipc	a3,0x5
ffffffffc0202e90:	a7468693          	addi	a3,a3,-1420 # ffffffffc0207900 <default_pmm_manager+0x5e8>
ffffffffc0202e94:	00004617          	auipc	a2,0x4
ffffffffc0202e98:	d3c60613          	addi	a2,a2,-708 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202e9c:	27600593          	li	a1,630
ffffffffc0202ea0:	00004517          	auipc	a0,0x4
ffffffffc0202ea4:	5e850513          	addi	a0,a0,1512 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202ea8:	ddcfd0ef          	jal	ra,ffffffffc0200484 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0202eac:	86be                	mv	a3,a5
ffffffffc0202eae:	00004617          	auipc	a2,0x4
ffffffffc0202eb2:	4ba60613          	addi	a2,a2,1210 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc0202eb6:	23b00593          	li	a1,571
ffffffffc0202eba:	00004517          	auipc	a0,0x4
ffffffffc0202ebe:	5ce50513          	addi	a0,a0,1486 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202ec2:	dc2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202ec6:	00004617          	auipc	a2,0x4
ffffffffc0202eca:	4da60613          	addi	a2,a2,1242 # ffffffffc02073a0 <default_pmm_manager+0x88>
ffffffffc0202ece:	08900593          	li	a1,137
ffffffffc0202ed2:	00004517          	auipc	a0,0x4
ffffffffc0202ed6:	5b650513          	addi	a0,a0,1462 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202eda:	daafd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202ede:	00005697          	auipc	a3,0x5
ffffffffc0202ee2:	aaa68693          	addi	a3,a3,-1366 # ffffffffc0207988 <default_pmm_manager+0x670>
ffffffffc0202ee6:	00004617          	auipc	a2,0x4
ffffffffc0202eea:	cea60613          	addi	a2,a2,-790 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202eee:	27c00593          	li	a1,636
ffffffffc0202ef2:	00004517          	auipc	a0,0x4
ffffffffc0202ef6:	59650513          	addi	a0,a0,1430 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202efa:	d8afd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202efe:	00005697          	auipc	a3,0x5
ffffffffc0202f02:	91268693          	addi	a3,a3,-1774 # ffffffffc0207810 <default_pmm_manager+0x4f8>
ffffffffc0202f06:	00004617          	auipc	a2,0x4
ffffffffc0202f0a:	cca60613          	addi	a2,a2,-822 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202f0e:	28800593          	li	a1,648
ffffffffc0202f12:	00004517          	auipc	a0,0x4
ffffffffc0202f16:	57650513          	addi	a0,a0,1398 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202f1a:	d6afd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202f1e:	00004697          	auipc	a3,0x4
ffffffffc0202f22:	74268693          	addi	a3,a3,1858 # ffffffffc0207660 <default_pmm_manager+0x348>
ffffffffc0202f26:	00004617          	auipc	a2,0x4
ffffffffc0202f2a:	caa60613          	addi	a2,a2,-854 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202f2e:	23900593          	li	a1,569
ffffffffc0202f32:	00004517          	auipc	a0,0x4
ffffffffc0202f36:	55650513          	addi	a0,a0,1366 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202f3a:	d4afd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202f3e:	00004697          	auipc	a3,0x4
ffffffffc0202f42:	70a68693          	addi	a3,a3,1802 # ffffffffc0207648 <default_pmm_manager+0x330>
ffffffffc0202f46:	00004617          	auipc	a2,0x4
ffffffffc0202f4a:	c8a60613          	addi	a2,a2,-886 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202f4e:	23800593          	li	a1,568
ffffffffc0202f52:	00004517          	auipc	a0,0x4
ffffffffc0202f56:	53650513          	addi	a0,a0,1334 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202f5a:	d2afd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202f5e:	00004697          	auipc	a3,0x4
ffffffffc0202f62:	63a68693          	addi	a3,a3,1594 # ffffffffc0207598 <default_pmm_manager+0x280>
ffffffffc0202f66:	00004617          	auipc	a2,0x4
ffffffffc0202f6a:	c6a60613          	addi	a2,a2,-918 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202f6e:	23000593          	li	a1,560
ffffffffc0202f72:	00004517          	auipc	a0,0x4
ffffffffc0202f76:	51650513          	addi	a0,a0,1302 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202f7a:	d0afd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202f7e:	00004697          	auipc	a3,0x4
ffffffffc0202f82:	67268693          	addi	a3,a3,1650 # ffffffffc02075f0 <default_pmm_manager+0x2d8>
ffffffffc0202f86:	00004617          	auipc	a2,0x4
ffffffffc0202f8a:	c4a60613          	addi	a2,a2,-950 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202f8e:	23700593          	li	a1,567
ffffffffc0202f92:	00004517          	auipc	a0,0x4
ffffffffc0202f96:	4f650513          	addi	a0,a0,1270 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202f9a:	ceafd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202f9e:	00004697          	auipc	a3,0x4
ffffffffc0202fa2:	62268693          	addi	a3,a3,1570 # ffffffffc02075c0 <default_pmm_manager+0x2a8>
ffffffffc0202fa6:	00004617          	auipc	a2,0x4
ffffffffc0202faa:	c2a60613          	addi	a2,a2,-982 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202fae:	23400593          	li	a1,564
ffffffffc0202fb2:	00004517          	auipc	a0,0x4
ffffffffc0202fb6:	4d650513          	addi	a0,a0,1238 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202fba:	ccafd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fbe:	00004697          	auipc	a3,0x4
ffffffffc0202fc2:	7e268693          	addi	a3,a3,2018 # ffffffffc02077a0 <default_pmm_manager+0x488>
ffffffffc0202fc6:	00004617          	auipc	a2,0x4
ffffffffc0202fca:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202fce:	25000593          	li	a1,592
ffffffffc0202fd2:	00004517          	auipc	a0,0x4
ffffffffc0202fd6:	4b650513          	addi	a0,a0,1206 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202fda:	caafd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202fde:	00004697          	auipc	a3,0x4
ffffffffc0202fe2:	68268693          	addi	a3,a3,1666 # ffffffffc0207660 <default_pmm_manager+0x348>
ffffffffc0202fe6:	00004617          	auipc	a2,0x4
ffffffffc0202fea:	bea60613          	addi	a2,a2,-1046 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0202fee:	24f00593          	li	a1,591
ffffffffc0202ff2:	00004517          	auipc	a0,0x4
ffffffffc0202ff6:	49650513          	addi	a0,a0,1174 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0202ffa:	c8afd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202ffe:	00004697          	auipc	a3,0x4
ffffffffc0203002:	7ba68693          	addi	a3,a3,1978 # ffffffffc02077b8 <default_pmm_manager+0x4a0>
ffffffffc0203006:	00004617          	auipc	a2,0x4
ffffffffc020300a:	bca60613          	addi	a2,a2,-1078 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020300e:	24c00593          	li	a1,588
ffffffffc0203012:	00004517          	auipc	a0,0x4
ffffffffc0203016:	47650513          	addi	a0,a0,1142 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc020301a:	c6afd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020301e:	00005697          	auipc	a3,0x5
ffffffffc0203022:	9a268693          	addi	a3,a3,-1630 # ffffffffc02079c0 <default_pmm_manager+0x6a8>
ffffffffc0203026:	00004617          	auipc	a2,0x4
ffffffffc020302a:	baa60613          	addi	a2,a2,-1110 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020302e:	27f00593          	li	a1,639
ffffffffc0203032:	00004517          	auipc	a0,0x4
ffffffffc0203036:	45650513          	addi	a0,a0,1110 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc020303a:	c4afd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020303e:	00004697          	auipc	a3,0x4
ffffffffc0203042:	7d268693          	addi	a3,a3,2002 # ffffffffc0207810 <default_pmm_manager+0x4f8>
ffffffffc0203046:	00004617          	auipc	a2,0x4
ffffffffc020304a:	b8a60613          	addi	a2,a2,-1142 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020304e:	25e00593          	li	a1,606
ffffffffc0203052:	00004517          	auipc	a0,0x4
ffffffffc0203056:	43650513          	addi	a0,a0,1078 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc020305a:	c2afd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc020305e:	00005697          	auipc	a3,0x5
ffffffffc0203062:	85268693          	addi	a3,a3,-1966 # ffffffffc02078b0 <default_pmm_manager+0x598>
ffffffffc0203066:	00004617          	auipc	a2,0x4
ffffffffc020306a:	b6a60613          	addi	a2,a2,-1174 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020306e:	27100593          	li	a1,625
ffffffffc0203072:	00004517          	auipc	a0,0x4
ffffffffc0203076:	41650513          	addi	a0,a0,1046 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc020307a:	c0afd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020307e:	00004697          	auipc	a3,0x4
ffffffffc0203082:	4c268693          	addi	a3,a3,1218 # ffffffffc0207540 <default_pmm_manager+0x228>
ffffffffc0203086:	00004617          	auipc	a2,0x4
ffffffffc020308a:	b4a60613          	addi	a2,a2,-1206 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020308e:	22e00593          	li	a1,558
ffffffffc0203092:	00004517          	auipc	a0,0x4
ffffffffc0203096:	3f650513          	addi	a0,a0,1014 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc020309a:	beafd0ef          	jal	ra,ffffffffc0200484 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc020309e:	00004617          	auipc	a2,0x4
ffffffffc02030a2:	30260613          	addi	a2,a2,770 # ffffffffc02073a0 <default_pmm_manager+0x88>
ffffffffc02030a6:	0d100593          	li	a1,209
ffffffffc02030aa:	00004517          	auipc	a0,0x4
ffffffffc02030ae:	3de50513          	addi	a0,a0,990 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc02030b2:	bd2fd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02030b6 <copy_range>:
{
ffffffffc02030b6:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02030b8:	00d667b3          	or	a5,a2,a3
{
ffffffffc02030bc:	f486                	sd	ra,104(sp)
ffffffffc02030be:	f0a2                	sd	s0,96(sp)
ffffffffc02030c0:	eca6                	sd	s1,88(sp)
ffffffffc02030c2:	e8ca                	sd	s2,80(sp)
ffffffffc02030c4:	e4ce                	sd	s3,72(sp)
ffffffffc02030c6:	e0d2                	sd	s4,64(sp)
ffffffffc02030c8:	fc56                	sd	s5,56(sp)
ffffffffc02030ca:	f85a                	sd	s6,48(sp)
ffffffffc02030cc:	f45e                	sd	s7,40(sp)
ffffffffc02030ce:	f062                	sd	s8,32(sp)
ffffffffc02030d0:	ec66                	sd	s9,24(sp)
ffffffffc02030d2:	e86a                	sd	s10,16(sp)
ffffffffc02030d4:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02030d6:	03479713          	slli	a4,a5,0x34
ffffffffc02030da:	1e071863          	bnez	a4,ffffffffc02032ca <copy_range+0x214>
    assert(USER_ACCESS(start, end));
ffffffffc02030de:	002007b7          	lui	a5,0x200
ffffffffc02030e2:	8432                	mv	s0,a2
ffffffffc02030e4:	16f66b63          	bltu	a2,a5,ffffffffc020325a <copy_range+0x1a4>
ffffffffc02030e8:	84b6                	mv	s1,a3
ffffffffc02030ea:	16d67863          	bleu	a3,a2,ffffffffc020325a <copy_range+0x1a4>
ffffffffc02030ee:	4785                	li	a5,1
ffffffffc02030f0:	07fe                	slli	a5,a5,0x1f
ffffffffc02030f2:	16d7e463          	bltu	a5,a3,ffffffffc020325a <copy_range+0x1a4>
ffffffffc02030f6:	5a7d                	li	s4,-1
ffffffffc02030f8:	8aaa                	mv	s5,a0
ffffffffc02030fa:	892e                	mv	s2,a1
        start += PGSIZE;
ffffffffc02030fc:	6985                	lui	s3,0x1
    if (PPN(pa) >= npage) {
ffffffffc02030fe:	000a9c17          	auipc	s8,0xa9
ffffffffc0203102:	39ac0c13          	addi	s8,s8,922 # ffffffffc02ac498 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203106:	000a9b97          	auipc	s7,0xa9
ffffffffc020310a:	402b8b93          	addi	s7,s7,1026 # ffffffffc02ac508 <pages>
    return page - pages + nbase;
ffffffffc020310e:	00080b37          	lui	s6,0x80
    return KADDR(page2pa(page));
ffffffffc0203112:	00ca5a13          	srli	s4,s4,0xc
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203116:	4601                	li	a2,0
ffffffffc0203118:	85a2                	mv	a1,s0
ffffffffc020311a:	854a                	mv	a0,s2
ffffffffc020311c:	e3dfe0ef          	jal	ra,ffffffffc0201f58 <get_pte>
ffffffffc0203120:	8caa                	mv	s9,a0
        if (ptep == NULL)
ffffffffc0203122:	c17d                	beqz	a0,ffffffffc0203208 <copy_range+0x152>
        if (*ptep & PTE_V) //PTE Valid
ffffffffc0203124:	611c                	ld	a5,0(a0)
ffffffffc0203126:	8b85                	andi	a5,a5,1
ffffffffc0203128:	e785                	bnez	a5,ffffffffc0203150 <copy_range+0x9a>
        start += PGSIZE;
ffffffffc020312a:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc020312c:	fe9465e3          	bltu	s0,s1,ffffffffc0203116 <copy_range+0x60>
    return 0;
ffffffffc0203130:	4501                	li	a0,0
}
ffffffffc0203132:	70a6                	ld	ra,104(sp)
ffffffffc0203134:	7406                	ld	s0,96(sp)
ffffffffc0203136:	64e6                	ld	s1,88(sp)
ffffffffc0203138:	6946                	ld	s2,80(sp)
ffffffffc020313a:	69a6                	ld	s3,72(sp)
ffffffffc020313c:	6a06                	ld	s4,64(sp)
ffffffffc020313e:	7ae2                	ld	s5,56(sp)
ffffffffc0203140:	7b42                	ld	s6,48(sp)
ffffffffc0203142:	7ba2                	ld	s7,40(sp)
ffffffffc0203144:	7c02                	ld	s8,32(sp)
ffffffffc0203146:	6ce2                	ld	s9,24(sp)
ffffffffc0203148:	6d42                	ld	s10,16(sp)
ffffffffc020314a:	6da2                	ld	s11,8(sp)
ffffffffc020314c:	6165                	addi	sp,sp,112
ffffffffc020314e:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203150:	4605                	li	a2,1
ffffffffc0203152:	85a2                	mv	a1,s0
ffffffffc0203154:	8556                	mv	a0,s5
ffffffffc0203156:	e03fe0ef          	jal	ra,ffffffffc0201f58 <get_pte>
ffffffffc020315a:	c169                	beqz	a0,ffffffffc020321c <copy_range+0x166>
            uint32_t perm = (*ptep & PTE_USER); //从源进程页表项中提取权限标志，用于在后续的page_insert调用中设置目标进程的页表项
ffffffffc020315c:	000cb783          	ld	a5,0(s9)
    if (!(pte & PTE_V)) {
ffffffffc0203160:	0017f713          	andi	a4,a5,1
ffffffffc0203164:	01f7fc93          	andi	s9,a5,31
ffffffffc0203168:	14070563          	beqz	a4,ffffffffc02032b2 <copy_range+0x1fc>
    if (PPN(pa) >= npage) {
ffffffffc020316c:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203170:	078a                	slli	a5,a5,0x2
ffffffffc0203172:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203176:	12d77263          	bleu	a3,a4,ffffffffc020329a <copy_range+0x1e4>
    return &pages[PPN(pa) - nbase];
ffffffffc020317a:	000bb783          	ld	a5,0(s7)
ffffffffc020317e:	fff806b7          	lui	a3,0xfff80
ffffffffc0203182:	9736                	add	a4,a4,a3
ffffffffc0203184:	071a                	slli	a4,a4,0x6
            struct Page *npage = alloc_page();
ffffffffc0203186:	4505                	li	a0,1
ffffffffc0203188:	00e78db3          	add	s11,a5,a4
ffffffffc020318c:	cbffe0ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0203190:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc0203192:	0a0d8463          	beqz	s11,ffffffffc020323a <copy_range+0x184>
            assert(npage != NULL);
ffffffffc0203196:	c175                	beqz	a0,ffffffffc020327a <copy_range+0x1c4>
    return page - pages + nbase;
ffffffffc0203198:	000bb703          	ld	a4,0(s7)
    return KADDR(page2pa(page));
ffffffffc020319c:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02031a0:	40ed86b3          	sub	a3,s11,a4
ffffffffc02031a4:	8699                	srai	a3,a3,0x6
ffffffffc02031a6:	96da                	add	a3,a3,s6
    return KADDR(page2pa(page));
ffffffffc02031a8:	0146f7b3          	and	a5,a3,s4
    return page2ppn(page) << PGSHIFT;
ffffffffc02031ac:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02031ae:	06c7fa63          	bleu	a2,a5,ffffffffc0203222 <copy_range+0x16c>
    return page - pages + nbase;
ffffffffc02031b2:	40e507b3          	sub	a5,a0,a4
    return KADDR(page2pa(page));
ffffffffc02031b6:	000a9717          	auipc	a4,0xa9
ffffffffc02031ba:	34270713          	addi	a4,a4,834 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc02031be:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc02031c0:	8799                	srai	a5,a5,0x6
ffffffffc02031c2:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc02031c4:	0147f733          	and	a4,a5,s4
ffffffffc02031c8:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02031cc:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02031ce:	04c77963          	bleu	a2,a4,ffffffffc0203220 <copy_range+0x16a>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE); // Copy the content of the source page to the destination page.
ffffffffc02031d2:	6605                	lui	a2,0x1
ffffffffc02031d4:	953e                	add	a0,a0,a5
ffffffffc02031d6:	404030ef          	jal	ra,ffffffffc02065da <memcpy>
            ret = page_insert(to, npage, start, perm); // Insert the destination page into the page table of the target process.
ffffffffc02031da:	86e6                	mv	a3,s9
ffffffffc02031dc:	8622                	mv	a2,s0
ffffffffc02031de:	85ea                	mv	a1,s10
ffffffffc02031e0:	8556                	mv	a0,s5
ffffffffc02031e2:	b8cff0ef          	jal	ra,ffffffffc020256e <page_insert>
            assert(ret == 0);
ffffffffc02031e6:	d131                	beqz	a0,ffffffffc020312a <copy_range+0x74>
ffffffffc02031e8:	00004697          	auipc	a3,0x4
ffffffffc02031ec:	29068693          	addi	a3,a3,656 # ffffffffc0207478 <default_pmm_manager+0x160>
ffffffffc02031f0:	00004617          	auipc	a2,0x4
ffffffffc02031f4:	9e060613          	addi	a2,a2,-1568 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02031f8:	1be00593          	li	a1,446
ffffffffc02031fc:	00004517          	auipc	a0,0x4
ffffffffc0203200:	28c50513          	addi	a0,a0,652 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0203204:	a80fd0ef          	jal	ra,ffffffffc0200484 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203208:	002007b7          	lui	a5,0x200
ffffffffc020320c:	943e                	add	s0,s0,a5
ffffffffc020320e:	ffe007b7          	lui	a5,0xffe00
ffffffffc0203212:	8c7d                	and	s0,s0,a5
    } while (start != 0 && start < end);
ffffffffc0203214:	dc11                	beqz	s0,ffffffffc0203130 <copy_range+0x7a>
ffffffffc0203216:	f09460e3          	bltu	s0,s1,ffffffffc0203116 <copy_range+0x60>
ffffffffc020321a:	bf19                	j	ffffffffc0203130 <copy_range+0x7a>
                return -E_NO_MEM;
ffffffffc020321c:	5571                	li	a0,-4
ffffffffc020321e:	bf11                	j	ffffffffc0203132 <copy_range+0x7c>
ffffffffc0203220:	86be                	mv	a3,a5
ffffffffc0203222:	00004617          	auipc	a2,0x4
ffffffffc0203226:	14660613          	addi	a2,a2,326 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc020322a:	06900593          	li	a1,105
ffffffffc020322e:	00004517          	auipc	a0,0x4
ffffffffc0203232:	16250513          	addi	a0,a0,354 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0203236:	a4efd0ef          	jal	ra,ffffffffc0200484 <__panic>
            assert(page != NULL);
ffffffffc020323a:	00004697          	auipc	a3,0x4
ffffffffc020323e:	21e68693          	addi	a3,a3,542 # ffffffffc0207458 <default_pmm_manager+0x140>
ffffffffc0203242:	00004617          	auipc	a2,0x4
ffffffffc0203246:	98e60613          	addi	a2,a2,-1650 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020324a:	1a000593          	li	a1,416
ffffffffc020324e:	00004517          	auipc	a0,0x4
ffffffffc0203252:	23a50513          	addi	a0,a0,570 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0203256:	a2efd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020325a:	00004697          	auipc	a3,0x4
ffffffffc020325e:	7de68693          	addi	a3,a3,2014 # ffffffffc0207a38 <default_pmm_manager+0x720>
ffffffffc0203262:	00004617          	auipc	a2,0x4
ffffffffc0203266:	96e60613          	addi	a2,a2,-1682 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020326a:	18500593          	li	a1,389
ffffffffc020326e:	00004517          	auipc	a0,0x4
ffffffffc0203272:	21a50513          	addi	a0,a0,538 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0203276:	a0efd0ef          	jal	ra,ffffffffc0200484 <__panic>
            assert(npage != NULL);
ffffffffc020327a:	00004697          	auipc	a3,0x4
ffffffffc020327e:	1ee68693          	addi	a3,a3,494 # ffffffffc0207468 <default_pmm_manager+0x150>
ffffffffc0203282:	00004617          	auipc	a2,0x4
ffffffffc0203286:	94e60613          	addi	a2,a2,-1714 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020328a:	1a100593          	li	a1,417
ffffffffc020328e:	00004517          	auipc	a0,0x4
ffffffffc0203292:	1fa50513          	addi	a0,a0,506 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0203296:	9eefd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020329a:	00004617          	auipc	a2,0x4
ffffffffc020329e:	12e60613          	addi	a2,a2,302 # ffffffffc02073c8 <default_pmm_manager+0xb0>
ffffffffc02032a2:	06200593          	li	a1,98
ffffffffc02032a6:	00004517          	auipc	a0,0x4
ffffffffc02032aa:	0ea50513          	addi	a0,a0,234 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc02032ae:	9d6fd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02032b2:	00004617          	auipc	a2,0x4
ffffffffc02032b6:	36e60613          	addi	a2,a2,878 # ffffffffc0207620 <default_pmm_manager+0x308>
ffffffffc02032ba:	07400593          	li	a1,116
ffffffffc02032be:	00004517          	auipc	a0,0x4
ffffffffc02032c2:	0d250513          	addi	a0,a0,210 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc02032c6:	9befd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02032ca:	00004697          	auipc	a3,0x4
ffffffffc02032ce:	73e68693          	addi	a3,a3,1854 # ffffffffc0207a08 <default_pmm_manager+0x6f0>
ffffffffc02032d2:	00004617          	auipc	a2,0x4
ffffffffc02032d6:	8fe60613          	addi	a2,a2,-1794 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02032da:	18400593          	li	a1,388
ffffffffc02032de:	00004517          	auipc	a0,0x4
ffffffffc02032e2:	1aa50513          	addi	a0,a0,426 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc02032e6:	99efd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02032ea <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02032ea:	12058073          	sfence.vma	a1
}
ffffffffc02032ee:	8082                	ret

ffffffffc02032f0 <pgdir_alloc_page>:
{
ffffffffc02032f0:	7179                	addi	sp,sp,-48
ffffffffc02032f2:	e84a                	sd	s2,16(sp)
ffffffffc02032f4:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc02032f6:	4505                	li	a0,1
{
ffffffffc02032f8:	f022                	sd	s0,32(sp)
ffffffffc02032fa:	ec26                	sd	s1,24(sp)
ffffffffc02032fc:	e44e                	sd	s3,8(sp)
ffffffffc02032fe:	f406                	sd	ra,40(sp)
ffffffffc0203300:	84ae                	mv	s1,a1
ffffffffc0203302:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0203304:	b47fe0ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0203308:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc020330a:	cd1d                	beqz	a0,ffffffffc0203348 <pgdir_alloc_page+0x58>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc020330c:	85aa                	mv	a1,a0
ffffffffc020330e:	86ce                	mv	a3,s3
ffffffffc0203310:	8626                	mv	a2,s1
ffffffffc0203312:	854a                	mv	a0,s2
ffffffffc0203314:	a5aff0ef          	jal	ra,ffffffffc020256e <page_insert>
ffffffffc0203318:	e121                	bnez	a0,ffffffffc0203358 <pgdir_alloc_page+0x68>
        if (swap_init_ok)
ffffffffc020331a:	000a9797          	auipc	a5,0xa9
ffffffffc020331e:	18e78793          	addi	a5,a5,398 # ffffffffc02ac4a8 <swap_init_ok>
ffffffffc0203322:	439c                	lw	a5,0(a5)
ffffffffc0203324:	2781                	sext.w	a5,a5
ffffffffc0203326:	c38d                	beqz	a5,ffffffffc0203348 <pgdir_alloc_page+0x58>
            if (check_mm_struct != NULL)
ffffffffc0203328:	000a9797          	auipc	a5,0xa9
ffffffffc020332c:	2c078793          	addi	a5,a5,704 # ffffffffc02ac5e8 <check_mm_struct>
ffffffffc0203330:	6388                	ld	a0,0(a5)
ffffffffc0203332:	c919                	beqz	a0,ffffffffc0203348 <pgdir_alloc_page+0x58>
                swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0203334:	4681                	li	a3,0
ffffffffc0203336:	8622                	mv	a2,s0
ffffffffc0203338:	85a6                	mv	a1,s1
ffffffffc020333a:	7da000ef          	jal	ra,ffffffffc0203b14 <swap_map_swappable>
                assert(page_ref(page) == 1);
ffffffffc020333e:	4018                	lw	a4,0(s0)
                page->pra_vaddr = la;
ffffffffc0203340:	fc04                	sd	s1,56(s0)
                assert(page_ref(page) == 1);
ffffffffc0203342:	4785                	li	a5,1
ffffffffc0203344:	02f71063          	bne	a4,a5,ffffffffc0203364 <pgdir_alloc_page+0x74>
}
ffffffffc0203348:	8522                	mv	a0,s0
ffffffffc020334a:	70a2                	ld	ra,40(sp)
ffffffffc020334c:	7402                	ld	s0,32(sp)
ffffffffc020334e:	64e2                	ld	s1,24(sp)
ffffffffc0203350:	6942                	ld	s2,16(sp)
ffffffffc0203352:	69a2                	ld	s3,8(sp)
ffffffffc0203354:	6145                	addi	sp,sp,48
ffffffffc0203356:	8082                	ret
            free_page(page);
ffffffffc0203358:	8522                	mv	a0,s0
ffffffffc020335a:	4585                	li	a1,1
ffffffffc020335c:	b77fe0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
            return NULL;
ffffffffc0203360:	4401                	li	s0,0
ffffffffc0203362:	b7dd                	j	ffffffffc0203348 <pgdir_alloc_page+0x58>
                assert(page_ref(page) == 1);
ffffffffc0203364:	00004697          	auipc	a3,0x4
ffffffffc0203368:	13468693          	addi	a3,a3,308 # ffffffffc0207498 <default_pmm_manager+0x180>
ffffffffc020336c:	00004617          	auipc	a2,0x4
ffffffffc0203370:	86460613          	addi	a2,a2,-1948 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203374:	20b00593          	li	a1,523
ffffffffc0203378:	00004517          	auipc	a0,0x4
ffffffffc020337c:	11050513          	addi	a0,a0,272 # ffffffffc0207488 <default_pmm_manager+0x170>
ffffffffc0203380:	904fd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203384 <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc0203384:	7135                	addi	sp,sp,-160
ffffffffc0203386:	ed06                	sd	ra,152(sp)
ffffffffc0203388:	e922                	sd	s0,144(sp)
ffffffffc020338a:	e526                	sd	s1,136(sp)
ffffffffc020338c:	e14a                	sd	s2,128(sp)
ffffffffc020338e:	fcce                	sd	s3,120(sp)
ffffffffc0203390:	f8d2                	sd	s4,112(sp)
ffffffffc0203392:	f4d6                	sd	s5,104(sp)
ffffffffc0203394:	f0da                	sd	s6,96(sp)
ffffffffc0203396:	ecde                	sd	s7,88(sp)
ffffffffc0203398:	e8e2                	sd	s8,80(sp)
ffffffffc020339a:	e4e6                	sd	s9,72(sp)
ffffffffc020339c:	e0ea                	sd	s10,64(sp)
ffffffffc020339e:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc02033a0:	79c010ef          	jal	ra,ffffffffc0204b3c <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc02033a4:	000a9797          	auipc	a5,0xa9
ffffffffc02033a8:	1f478793          	addi	a5,a5,500 # ffffffffc02ac598 <max_swap_offset>
ffffffffc02033ac:	6394                	ld	a3,0(a5)
ffffffffc02033ae:	010007b7          	lui	a5,0x1000
ffffffffc02033b2:	17e1                	addi	a5,a5,-8
ffffffffc02033b4:	ff968713          	addi	a4,a3,-7
ffffffffc02033b8:	4ae7ee63          	bltu	a5,a4,ffffffffc0203874 <swap_init+0x4f0>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     

     sm = &swap_manager_fifo;
ffffffffc02033bc:	0009e797          	auipc	a5,0x9e
ffffffffc02033c0:	c6c78793          	addi	a5,a5,-916 # ffffffffc02a1028 <swap_manager_fifo>
     int r = sm->init();
ffffffffc02033c4:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc02033c6:	000a9697          	auipc	a3,0xa9
ffffffffc02033ca:	0cf6bd23          	sd	a5,218(a3) # ffffffffc02ac4a0 <sm>
     int r = sm->init();
ffffffffc02033ce:	9702                	jalr	a4
ffffffffc02033d0:	8aaa                	mv	s5,a0
     
     if (r == 0)
ffffffffc02033d2:	c10d                	beqz	a0,ffffffffc02033f4 <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc02033d4:	60ea                	ld	ra,152(sp)
ffffffffc02033d6:	644a                	ld	s0,144(sp)
ffffffffc02033d8:	8556                	mv	a0,s5
ffffffffc02033da:	64aa                	ld	s1,136(sp)
ffffffffc02033dc:	690a                	ld	s2,128(sp)
ffffffffc02033de:	79e6                	ld	s3,120(sp)
ffffffffc02033e0:	7a46                	ld	s4,112(sp)
ffffffffc02033e2:	7aa6                	ld	s5,104(sp)
ffffffffc02033e4:	7b06                	ld	s6,96(sp)
ffffffffc02033e6:	6be6                	ld	s7,88(sp)
ffffffffc02033e8:	6c46                	ld	s8,80(sp)
ffffffffc02033ea:	6ca6                	ld	s9,72(sp)
ffffffffc02033ec:	6d06                	ld	s10,64(sp)
ffffffffc02033ee:	7de2                	ld	s11,56(sp)
ffffffffc02033f0:	610d                	addi	sp,sp,160
ffffffffc02033f2:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02033f4:	000a9797          	auipc	a5,0xa9
ffffffffc02033f8:	0ac78793          	addi	a5,a5,172 # ffffffffc02ac4a0 <sm>
ffffffffc02033fc:	639c                	ld	a5,0(a5)
ffffffffc02033fe:	00004517          	auipc	a0,0x4
ffffffffc0203402:	6d250513          	addi	a0,a0,1746 # ffffffffc0207ad0 <default_pmm_manager+0x7b8>
    return listelm->next;
ffffffffc0203406:	000a9417          	auipc	s0,0xa9
ffffffffc020340a:	0d240413          	addi	s0,s0,210 # ffffffffc02ac4d8 <free_area>
ffffffffc020340e:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0203410:	4785                	li	a5,1
ffffffffc0203412:	000a9717          	auipc	a4,0xa9
ffffffffc0203416:	08f72b23          	sw	a5,150(a4) # ffffffffc02ac4a8 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc020341a:	d75fc0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc020341e:	641c                	ld	a5,8(s0)
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203420:	36878e63          	beq	a5,s0,ffffffffc020379c <swap_init+0x418>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203424:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203428:	8305                	srli	a4,a4,0x1
ffffffffc020342a:	8b05                	andi	a4,a4,1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020342c:	36070c63          	beqz	a4,ffffffffc02037a4 <swap_init+0x420>
     int ret, count = 0, total = 0, i;
ffffffffc0203430:	4481                	li	s1,0
ffffffffc0203432:	4901                	li	s2,0
ffffffffc0203434:	a031                	j	ffffffffc0203440 <swap_init+0xbc>
ffffffffc0203436:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc020343a:	8b09                	andi	a4,a4,2
ffffffffc020343c:	36070463          	beqz	a4,ffffffffc02037a4 <swap_init+0x420>
        count ++, total += p->property;
ffffffffc0203440:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203444:	679c                	ld	a5,8(a5)
ffffffffc0203446:	2905                	addiw	s2,s2,1
ffffffffc0203448:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc020344a:	fe8796e3          	bne	a5,s0,ffffffffc0203436 <swap_init+0xb2>
ffffffffc020344e:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc0203450:	ac9fe0ef          	jal	ra,ffffffffc0201f18 <nr_free_pages>
ffffffffc0203454:	69351863          	bne	a0,s3,ffffffffc0203ae4 <swap_init+0x760>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0203458:	8626                	mv	a2,s1
ffffffffc020345a:	85ca                	mv	a1,s2
ffffffffc020345c:	00004517          	auipc	a0,0x4
ffffffffc0203460:	68c50513          	addi	a0,a0,1676 # ffffffffc0207ae8 <default_pmm_manager+0x7d0>
ffffffffc0203464:	d2bfc0ef          	jal	ra,ffffffffc020018e <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0203468:	457000ef          	jal	ra,ffffffffc02040be <mm_create>
ffffffffc020346c:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc020346e:	60050b63          	beqz	a0,ffffffffc0203a84 <swap_init+0x700>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0203472:	000a9797          	auipc	a5,0xa9
ffffffffc0203476:	17678793          	addi	a5,a5,374 # ffffffffc02ac5e8 <check_mm_struct>
ffffffffc020347a:	639c                	ld	a5,0(a5)
ffffffffc020347c:	62079463          	bnez	a5,ffffffffc0203aa4 <swap_init+0x720>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203480:	000a9797          	auipc	a5,0xa9
ffffffffc0203484:	01078793          	addi	a5,a5,16 # ffffffffc02ac490 <boot_pgdir>
ffffffffc0203488:	0007bb03          	ld	s6,0(a5)
     check_mm_struct = mm;
ffffffffc020348c:	000a9797          	auipc	a5,0xa9
ffffffffc0203490:	14a7be23          	sd	a0,348(a5) # ffffffffc02ac5e8 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc0203494:	000b3783          	ld	a5,0(s6) # 80000 <_binary_obj___user_exit_out_size+0x75580>
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203498:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc020349c:	4e079863          	bnez	a5,ffffffffc020398c <swap_init+0x608>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc02034a0:	6599                	lui	a1,0x6
ffffffffc02034a2:	460d                	li	a2,3
ffffffffc02034a4:	6505                	lui	a0,0x1
ffffffffc02034a6:	465000ef          	jal	ra,ffffffffc020410a <vma_create>
ffffffffc02034aa:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc02034ac:	50050063          	beqz	a0,ffffffffc02039ac <swap_init+0x628>

     insert_vma_struct(mm, vma);
ffffffffc02034b0:	855e                	mv	a0,s7
ffffffffc02034b2:	4c5000ef          	jal	ra,ffffffffc0204176 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc02034b6:	00004517          	auipc	a0,0x4
ffffffffc02034ba:	6a250513          	addi	a0,a0,1698 # ffffffffc0207b58 <default_pmm_manager+0x840>
ffffffffc02034be:	cd1fc0ef          	jal	ra,ffffffffc020018e <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc02034c2:	018bb503          	ld	a0,24(s7)
ffffffffc02034c6:	4605                	li	a2,1
ffffffffc02034c8:	6585                	lui	a1,0x1
ffffffffc02034ca:	a8ffe0ef          	jal	ra,ffffffffc0201f58 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc02034ce:	4e050f63          	beqz	a0,ffffffffc02039cc <swap_init+0x648>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02034d2:	00004517          	auipc	a0,0x4
ffffffffc02034d6:	6d650513          	addi	a0,a0,1750 # ffffffffc0207ba8 <default_pmm_manager+0x890>
ffffffffc02034da:	000a9997          	auipc	s3,0xa9
ffffffffc02034de:	03698993          	addi	s3,s3,54 # ffffffffc02ac510 <check_rp>
ffffffffc02034e2:	cadfc0ef          	jal	ra,ffffffffc020018e <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02034e6:	000a9a17          	auipc	s4,0xa9
ffffffffc02034ea:	04aa0a13          	addi	s4,s4,74 # ffffffffc02ac530 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02034ee:	8c4e                	mv	s8,s3
          check_rp[i] = alloc_page();
ffffffffc02034f0:	4505                	li	a0,1
ffffffffc02034f2:	959fe0ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc02034f6:	00ac3023          	sd	a0,0(s8)
          assert(check_rp[i] != NULL );
ffffffffc02034fa:	32050d63          	beqz	a0,ffffffffc0203834 <swap_init+0x4b0>
ffffffffc02034fe:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0203500:	8b89                	andi	a5,a5,2
ffffffffc0203502:	30079963          	bnez	a5,ffffffffc0203814 <swap_init+0x490>
ffffffffc0203506:	0c21                	addi	s8,s8,8
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203508:	ff4c14e3          	bne	s8,s4,ffffffffc02034f0 <swap_init+0x16c>
     }
     list_entry_t free_list_store = free_list;
ffffffffc020350c:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc020350e:	000a9c17          	auipc	s8,0xa9
ffffffffc0203512:	002c0c13          	addi	s8,s8,2 # ffffffffc02ac510 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc0203516:	ec3e                	sd	a5,24(sp)
ffffffffc0203518:	641c                	ld	a5,8(s0)
ffffffffc020351a:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc020351c:	481c                	lw	a5,16(s0)
ffffffffc020351e:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc0203520:	000a9797          	auipc	a5,0xa9
ffffffffc0203524:	fc87b023          	sd	s0,-64(a5) # ffffffffc02ac4e0 <free_area+0x8>
ffffffffc0203528:	000a9797          	auipc	a5,0xa9
ffffffffc020352c:	fa87b823          	sd	s0,-80(a5) # ffffffffc02ac4d8 <free_area>
     nr_free = 0;
ffffffffc0203530:	000a9797          	auipc	a5,0xa9
ffffffffc0203534:	fa07ac23          	sw	zero,-72(a5) # ffffffffc02ac4e8 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0203538:	000c3503          	ld	a0,0(s8)
ffffffffc020353c:	4585                	li	a1,1
ffffffffc020353e:	0c21                	addi	s8,s8,8
ffffffffc0203540:	993fe0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203544:	ff4c1ae3          	bne	s8,s4,ffffffffc0203538 <swap_init+0x1b4>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203548:	01042c03          	lw	s8,16(s0)
ffffffffc020354c:	4791                	li	a5,4
ffffffffc020354e:	50fc1b63          	bne	s8,a5,ffffffffc0203a64 <swap_init+0x6e0>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0203552:	00004517          	auipc	a0,0x4
ffffffffc0203556:	6de50513          	addi	a0,a0,1758 # ffffffffc0207c30 <default_pmm_manager+0x918>
ffffffffc020355a:	c35fc0ef          	jal	ra,ffffffffc020018e <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc020355e:	6685                	lui	a3,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0203560:	000a9797          	auipc	a5,0xa9
ffffffffc0203564:	f407a623          	sw	zero,-180(a5) # ffffffffc02ac4ac <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203568:	4629                	li	a2,10
     pgfault_num=0;
ffffffffc020356a:	000a9797          	auipc	a5,0xa9
ffffffffc020356e:	f4278793          	addi	a5,a5,-190 # ffffffffc02ac4ac <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203572:	00c68023          	sb	a2,0(a3) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
     assert(pgfault_num==1);
ffffffffc0203576:	4398                	lw	a4,0(a5)
ffffffffc0203578:	4585                	li	a1,1
ffffffffc020357a:	2701                	sext.w	a4,a4
ffffffffc020357c:	38b71863          	bne	a4,a1,ffffffffc020390c <swap_init+0x588>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0203580:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==1);
ffffffffc0203584:	4394                	lw	a3,0(a5)
ffffffffc0203586:	2681                	sext.w	a3,a3
ffffffffc0203588:	3ae69263          	bne	a3,a4,ffffffffc020392c <swap_init+0x5a8>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc020358c:	6689                	lui	a3,0x2
ffffffffc020358e:	462d                	li	a2,11
ffffffffc0203590:	00c68023          	sb	a2,0(a3) # 2000 <_binary_obj___user_faultread_out_size-0x7580>
     assert(pgfault_num==2);
ffffffffc0203594:	4398                	lw	a4,0(a5)
ffffffffc0203596:	4589                	li	a1,2
ffffffffc0203598:	2701                	sext.w	a4,a4
ffffffffc020359a:	2eb71963          	bne	a4,a1,ffffffffc020388c <swap_init+0x508>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc020359e:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc02035a2:	4394                	lw	a3,0(a5)
ffffffffc02035a4:	2681                	sext.w	a3,a3
ffffffffc02035a6:	30e69363          	bne	a3,a4,ffffffffc02038ac <swap_init+0x528>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc02035aa:	668d                	lui	a3,0x3
ffffffffc02035ac:	4631                	li	a2,12
ffffffffc02035ae:	00c68023          	sb	a2,0(a3) # 3000 <_binary_obj___user_faultread_out_size-0x6580>
     assert(pgfault_num==3);
ffffffffc02035b2:	4398                	lw	a4,0(a5)
ffffffffc02035b4:	458d                	li	a1,3
ffffffffc02035b6:	2701                	sext.w	a4,a4
ffffffffc02035b8:	30b71a63          	bne	a4,a1,ffffffffc02038cc <swap_init+0x548>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc02035bc:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc02035c0:	4394                	lw	a3,0(a5)
ffffffffc02035c2:	2681                	sext.w	a3,a3
ffffffffc02035c4:	32e69463          	bne	a3,a4,ffffffffc02038ec <swap_init+0x568>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc02035c8:	6691                	lui	a3,0x4
ffffffffc02035ca:	4635                	li	a2,13
ffffffffc02035cc:	00c68023          	sb	a2,0(a3) # 4000 <_binary_obj___user_faultread_out_size-0x5580>
     assert(pgfault_num==4);
ffffffffc02035d0:	4398                	lw	a4,0(a5)
ffffffffc02035d2:	2701                	sext.w	a4,a4
ffffffffc02035d4:	37871c63          	bne	a4,s8,ffffffffc020394c <swap_init+0x5c8>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc02035d8:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc02035dc:	439c                	lw	a5,0(a5)
ffffffffc02035de:	2781                	sext.w	a5,a5
ffffffffc02035e0:	38e79663          	bne	a5,a4,ffffffffc020396c <swap_init+0x5e8>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc02035e4:	481c                	lw	a5,16(s0)
ffffffffc02035e6:	40079363          	bnez	a5,ffffffffc02039ec <swap_init+0x668>
ffffffffc02035ea:	000a9797          	auipc	a5,0xa9
ffffffffc02035ee:	f4678793          	addi	a5,a5,-186 # ffffffffc02ac530 <swap_in_seq_no>
ffffffffc02035f2:	000a9717          	auipc	a4,0xa9
ffffffffc02035f6:	f6670713          	addi	a4,a4,-154 # ffffffffc02ac558 <swap_out_seq_no>
ffffffffc02035fa:	000a9617          	auipc	a2,0xa9
ffffffffc02035fe:	f5e60613          	addi	a2,a2,-162 # ffffffffc02ac558 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0203602:	56fd                	li	a3,-1
ffffffffc0203604:	c394                	sw	a3,0(a5)
ffffffffc0203606:	c314                	sw	a3,0(a4)
ffffffffc0203608:	0791                	addi	a5,a5,4
ffffffffc020360a:	0711                	addi	a4,a4,4
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc020360c:	fef61ce3          	bne	a2,a5,ffffffffc0203604 <swap_init+0x280>
ffffffffc0203610:	000a9697          	auipc	a3,0xa9
ffffffffc0203614:	fa868693          	addi	a3,a3,-88 # ffffffffc02ac5b8 <check_ptep>
ffffffffc0203618:	000a9817          	auipc	a6,0xa9
ffffffffc020361c:	ef880813          	addi	a6,a6,-264 # ffffffffc02ac510 <check_rp>
ffffffffc0203620:	6d05                	lui	s10,0x1
    if (PPN(pa) >= npage) {
ffffffffc0203622:	000a9c97          	auipc	s9,0xa9
ffffffffc0203626:	e76c8c93          	addi	s9,s9,-394 # ffffffffc02ac498 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020362a:	00005d97          	auipc	s11,0x5
ffffffffc020362e:	706d8d93          	addi	s11,s11,1798 # ffffffffc0208d30 <nbase>
ffffffffc0203632:	000a9c17          	auipc	s8,0xa9
ffffffffc0203636:	ed6c0c13          	addi	s8,s8,-298 # ffffffffc02ac508 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc020363a:	0006b023          	sd	zero,0(a3)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc020363e:	4601                	li	a2,0
ffffffffc0203640:	85ea                	mv	a1,s10
ffffffffc0203642:	855a                	mv	a0,s6
ffffffffc0203644:	e842                	sd	a6,16(sp)
         check_ptep[i]=0;
ffffffffc0203646:	e436                	sd	a3,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203648:	911fe0ef          	jal	ra,ffffffffc0201f58 <get_pte>
ffffffffc020364c:	66a2                	ld	a3,8(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc020364e:	6842                	ld	a6,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203650:	e288                	sd	a0,0(a3)
         assert(check_ptep[i] != NULL);
ffffffffc0203652:	20050163          	beqz	a0,ffffffffc0203854 <swap_init+0x4d0>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0203656:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0203658:	0017f613          	andi	a2,a5,1
ffffffffc020365c:	1a060063          	beqz	a2,ffffffffc02037fc <swap_init+0x478>
    if (PPN(pa) >= npage) {
ffffffffc0203660:	000cb603          	ld	a2,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203664:	078a                	slli	a5,a5,0x2
ffffffffc0203666:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203668:	14c7fe63          	bleu	a2,a5,ffffffffc02037c4 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc020366c:	000db703          	ld	a4,0(s11)
ffffffffc0203670:	000c3603          	ld	a2,0(s8)
ffffffffc0203674:	00083583          	ld	a1,0(a6)
ffffffffc0203678:	8f99                	sub	a5,a5,a4
ffffffffc020367a:	079a                	slli	a5,a5,0x6
ffffffffc020367c:	e43a                	sd	a4,8(sp)
ffffffffc020367e:	97b2                	add	a5,a5,a2
ffffffffc0203680:	14f59e63          	bne	a1,a5,ffffffffc02037dc <swap_init+0x458>
ffffffffc0203684:	6785                	lui	a5,0x1
ffffffffc0203686:	9d3e                	add	s10,s10,a5
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203688:	6795                	lui	a5,0x5
ffffffffc020368a:	06a1                	addi	a3,a3,8
ffffffffc020368c:	0821                	addi	a6,a6,8
ffffffffc020368e:	fafd16e3          	bne	s10,a5,ffffffffc020363a <swap_init+0x2b6>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0203692:	00004517          	auipc	a0,0x4
ffffffffc0203696:	64650513          	addi	a0,a0,1606 # ffffffffc0207cd8 <default_pmm_manager+0x9c0>
ffffffffc020369a:	af5fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    int ret = sm->check_swap();
ffffffffc020369e:	000a9797          	auipc	a5,0xa9
ffffffffc02036a2:	e0278793          	addi	a5,a5,-510 # ffffffffc02ac4a0 <sm>
ffffffffc02036a6:	639c                	ld	a5,0(a5)
ffffffffc02036a8:	7f9c                	ld	a5,56(a5)
ffffffffc02036aa:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc02036ac:	40051c63          	bnez	a0,ffffffffc0203ac4 <swap_init+0x740>

     nr_free = nr_free_store;
ffffffffc02036b0:	77a2                	ld	a5,40(sp)
ffffffffc02036b2:	000a9717          	auipc	a4,0xa9
ffffffffc02036b6:	e2f72b23          	sw	a5,-458(a4) # ffffffffc02ac4e8 <free_area+0x10>
     free_list = free_list_store;
ffffffffc02036ba:	67e2                	ld	a5,24(sp)
ffffffffc02036bc:	000a9717          	auipc	a4,0xa9
ffffffffc02036c0:	e0f73e23          	sd	a5,-484(a4) # ffffffffc02ac4d8 <free_area>
ffffffffc02036c4:	7782                	ld	a5,32(sp)
ffffffffc02036c6:	000a9717          	auipc	a4,0xa9
ffffffffc02036ca:	e0f73d23          	sd	a5,-486(a4) # ffffffffc02ac4e0 <free_area+0x8>

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc02036ce:	0009b503          	ld	a0,0(s3)
ffffffffc02036d2:	4585                	li	a1,1
ffffffffc02036d4:	09a1                	addi	s3,s3,8
ffffffffc02036d6:	ffcfe0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02036da:	ff499ae3          	bne	s3,s4,ffffffffc02036ce <swap_init+0x34a>
     } 

     //free_page(pte2page(*temp_ptep));

     mm->pgdir = NULL;
ffffffffc02036de:	000bbc23          	sd	zero,24(s7)
     mm_destroy(mm);
ffffffffc02036e2:	855e                	mv	a0,s7
ffffffffc02036e4:	361000ef          	jal	ra,ffffffffc0204244 <mm_destroy>
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc02036e8:	000a9797          	auipc	a5,0xa9
ffffffffc02036ec:	da878793          	addi	a5,a5,-600 # ffffffffc02ac490 <boot_pgdir>
ffffffffc02036f0:	639c                	ld	a5,0(a5)
     check_mm_struct = NULL;
ffffffffc02036f2:	000a9697          	auipc	a3,0xa9
ffffffffc02036f6:	ee06bb23          	sd	zero,-266(a3) # ffffffffc02ac5e8 <check_mm_struct>
    if (PPN(pa) >= npage) {
ffffffffc02036fa:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc02036fe:	6394                	ld	a3,0(a5)
ffffffffc0203700:	068a                	slli	a3,a3,0x2
ffffffffc0203702:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203704:	0ce6f063          	bleu	a4,a3,ffffffffc02037c4 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203708:	67a2                	ld	a5,8(sp)
ffffffffc020370a:	000c3503          	ld	a0,0(s8)
ffffffffc020370e:	8e9d                	sub	a3,a3,a5
ffffffffc0203710:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0203712:	8699                	srai	a3,a3,0x6
ffffffffc0203714:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0203716:	57fd                	li	a5,-1
ffffffffc0203718:	83b1                	srli	a5,a5,0xc
ffffffffc020371a:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020371c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020371e:	2ee7f763          	bleu	a4,a5,ffffffffc0203a0c <swap_init+0x688>
     free_page(pde2page(pd0[0]));
ffffffffc0203722:	000a9797          	auipc	a5,0xa9
ffffffffc0203726:	dd678793          	addi	a5,a5,-554 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc020372a:	639c                	ld	a5,0(a5)
ffffffffc020372c:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020372e:	629c                	ld	a5,0(a3)
ffffffffc0203730:	078a                	slli	a5,a5,0x2
ffffffffc0203732:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203734:	08e7f863          	bleu	a4,a5,ffffffffc02037c4 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203738:	69a2                	ld	s3,8(sp)
ffffffffc020373a:	4585                	li	a1,1
ffffffffc020373c:	413787b3          	sub	a5,a5,s3
ffffffffc0203740:	079a                	slli	a5,a5,0x6
ffffffffc0203742:	953e                	add	a0,a0,a5
ffffffffc0203744:	f8efe0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203748:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc020374c:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203750:	078a                	slli	a5,a5,0x2
ffffffffc0203752:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203754:	06e7f863          	bleu	a4,a5,ffffffffc02037c4 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203758:	000c3503          	ld	a0,0(s8)
ffffffffc020375c:	413787b3          	sub	a5,a5,s3
ffffffffc0203760:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc0203762:	4585                	li	a1,1
ffffffffc0203764:	953e                	add	a0,a0,a5
ffffffffc0203766:	f6cfe0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
     pgdir[0] = 0;
ffffffffc020376a:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc020376e:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0203772:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203774:	00878963          	beq	a5,s0,ffffffffc0203786 <swap_init+0x402>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0203778:	ff87a703          	lw	a4,-8(a5)
ffffffffc020377c:	679c                	ld	a5,8(a5)
ffffffffc020377e:	397d                	addiw	s2,s2,-1
ffffffffc0203780:	9c99                	subw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203782:	fe879be3          	bne	a5,s0,ffffffffc0203778 <swap_init+0x3f4>
     }
     assert(count==0);
ffffffffc0203786:	28091f63          	bnez	s2,ffffffffc0203a24 <swap_init+0x6a0>
     assert(total==0);
ffffffffc020378a:	2a049d63          	bnez	s1,ffffffffc0203a44 <swap_init+0x6c0>

     cprintf("check_swap() succeeded!\n");
ffffffffc020378e:	00004517          	auipc	a0,0x4
ffffffffc0203792:	59a50513          	addi	a0,a0,1434 # ffffffffc0207d28 <default_pmm_manager+0xa10>
ffffffffc0203796:	9f9fc0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc020379a:	b92d                	j	ffffffffc02033d4 <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc020379c:	4481                	li	s1,0
ffffffffc020379e:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list) {
ffffffffc02037a0:	4981                	li	s3,0
ffffffffc02037a2:	b17d                	j	ffffffffc0203450 <swap_init+0xcc>
        assert(PageProperty(p));
ffffffffc02037a4:	00003697          	auipc	a3,0x3
ffffffffc02037a8:	7e468693          	addi	a3,a3,2020 # ffffffffc0206f88 <commands+0x860>
ffffffffc02037ac:	00003617          	auipc	a2,0x3
ffffffffc02037b0:	42460613          	addi	a2,a2,1060 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02037b4:	0bc00593          	li	a1,188
ffffffffc02037b8:	00004517          	auipc	a0,0x4
ffffffffc02037bc:	30850513          	addi	a0,a0,776 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc02037c0:	cc5fc0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02037c4:	00004617          	auipc	a2,0x4
ffffffffc02037c8:	c0460613          	addi	a2,a2,-1020 # ffffffffc02073c8 <default_pmm_manager+0xb0>
ffffffffc02037cc:	06200593          	li	a1,98
ffffffffc02037d0:	00004517          	auipc	a0,0x4
ffffffffc02037d4:	bc050513          	addi	a0,a0,-1088 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc02037d8:	cadfc0ef          	jal	ra,ffffffffc0200484 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc02037dc:	00004697          	auipc	a3,0x4
ffffffffc02037e0:	4d468693          	addi	a3,a3,1236 # ffffffffc0207cb0 <default_pmm_manager+0x998>
ffffffffc02037e4:	00003617          	auipc	a2,0x3
ffffffffc02037e8:	3ec60613          	addi	a2,a2,1004 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02037ec:	0fc00593          	li	a1,252
ffffffffc02037f0:	00004517          	auipc	a0,0x4
ffffffffc02037f4:	2d050513          	addi	a0,a0,720 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc02037f8:	c8dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02037fc:	00004617          	auipc	a2,0x4
ffffffffc0203800:	e2460613          	addi	a2,a2,-476 # ffffffffc0207620 <default_pmm_manager+0x308>
ffffffffc0203804:	07400593          	li	a1,116
ffffffffc0203808:	00004517          	auipc	a0,0x4
ffffffffc020380c:	b8850513          	addi	a0,a0,-1144 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0203810:	c75fc0ef          	jal	ra,ffffffffc0200484 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0203814:	00004697          	auipc	a3,0x4
ffffffffc0203818:	3d468693          	addi	a3,a3,980 # ffffffffc0207be8 <default_pmm_manager+0x8d0>
ffffffffc020381c:	00003617          	auipc	a2,0x3
ffffffffc0203820:	3b460613          	addi	a2,a2,948 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203824:	0dd00593          	li	a1,221
ffffffffc0203828:	00004517          	auipc	a0,0x4
ffffffffc020382c:	29850513          	addi	a0,a0,664 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203830:	c55fc0ef          	jal	ra,ffffffffc0200484 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0203834:	00004697          	auipc	a3,0x4
ffffffffc0203838:	39c68693          	addi	a3,a3,924 # ffffffffc0207bd0 <default_pmm_manager+0x8b8>
ffffffffc020383c:	00003617          	auipc	a2,0x3
ffffffffc0203840:	39460613          	addi	a2,a2,916 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203844:	0dc00593          	li	a1,220
ffffffffc0203848:	00004517          	auipc	a0,0x4
ffffffffc020384c:	27850513          	addi	a0,a0,632 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203850:	c35fc0ef          	jal	ra,ffffffffc0200484 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0203854:	00004697          	auipc	a3,0x4
ffffffffc0203858:	44468693          	addi	a3,a3,1092 # ffffffffc0207c98 <default_pmm_manager+0x980>
ffffffffc020385c:	00003617          	auipc	a2,0x3
ffffffffc0203860:	37460613          	addi	a2,a2,884 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203864:	0fb00593          	li	a1,251
ffffffffc0203868:	00004517          	auipc	a0,0x4
ffffffffc020386c:	25850513          	addi	a0,a0,600 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203870:	c15fc0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0203874:	00004617          	auipc	a2,0x4
ffffffffc0203878:	22c60613          	addi	a2,a2,556 # ffffffffc0207aa0 <default_pmm_manager+0x788>
ffffffffc020387c:	02800593          	li	a1,40
ffffffffc0203880:	00004517          	auipc	a0,0x4
ffffffffc0203884:	24050513          	addi	a0,a0,576 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203888:	bfdfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==2);
ffffffffc020388c:	00004697          	auipc	a3,0x4
ffffffffc0203890:	3dc68693          	addi	a3,a3,988 # ffffffffc0207c68 <default_pmm_manager+0x950>
ffffffffc0203894:	00003617          	auipc	a2,0x3
ffffffffc0203898:	33c60613          	addi	a2,a2,828 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020389c:	09700593          	li	a1,151
ffffffffc02038a0:	00004517          	auipc	a0,0x4
ffffffffc02038a4:	22050513          	addi	a0,a0,544 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc02038a8:	bddfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==2);
ffffffffc02038ac:	00004697          	auipc	a3,0x4
ffffffffc02038b0:	3bc68693          	addi	a3,a3,956 # ffffffffc0207c68 <default_pmm_manager+0x950>
ffffffffc02038b4:	00003617          	auipc	a2,0x3
ffffffffc02038b8:	31c60613          	addi	a2,a2,796 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02038bc:	09900593          	li	a1,153
ffffffffc02038c0:	00004517          	auipc	a0,0x4
ffffffffc02038c4:	20050513          	addi	a0,a0,512 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc02038c8:	bbdfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==3);
ffffffffc02038cc:	00004697          	auipc	a3,0x4
ffffffffc02038d0:	3ac68693          	addi	a3,a3,940 # ffffffffc0207c78 <default_pmm_manager+0x960>
ffffffffc02038d4:	00003617          	auipc	a2,0x3
ffffffffc02038d8:	2fc60613          	addi	a2,a2,764 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02038dc:	09b00593          	li	a1,155
ffffffffc02038e0:	00004517          	auipc	a0,0x4
ffffffffc02038e4:	1e050513          	addi	a0,a0,480 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc02038e8:	b9dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==3);
ffffffffc02038ec:	00004697          	auipc	a3,0x4
ffffffffc02038f0:	38c68693          	addi	a3,a3,908 # ffffffffc0207c78 <default_pmm_manager+0x960>
ffffffffc02038f4:	00003617          	auipc	a2,0x3
ffffffffc02038f8:	2dc60613          	addi	a2,a2,732 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02038fc:	09d00593          	li	a1,157
ffffffffc0203900:	00004517          	auipc	a0,0x4
ffffffffc0203904:	1c050513          	addi	a0,a0,448 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203908:	b7dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==1);
ffffffffc020390c:	00004697          	auipc	a3,0x4
ffffffffc0203910:	34c68693          	addi	a3,a3,844 # ffffffffc0207c58 <default_pmm_manager+0x940>
ffffffffc0203914:	00003617          	auipc	a2,0x3
ffffffffc0203918:	2bc60613          	addi	a2,a2,700 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020391c:	09300593          	li	a1,147
ffffffffc0203920:	00004517          	auipc	a0,0x4
ffffffffc0203924:	1a050513          	addi	a0,a0,416 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203928:	b5dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==1);
ffffffffc020392c:	00004697          	auipc	a3,0x4
ffffffffc0203930:	32c68693          	addi	a3,a3,812 # ffffffffc0207c58 <default_pmm_manager+0x940>
ffffffffc0203934:	00003617          	auipc	a2,0x3
ffffffffc0203938:	29c60613          	addi	a2,a2,668 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020393c:	09500593          	li	a1,149
ffffffffc0203940:	00004517          	auipc	a0,0x4
ffffffffc0203944:	18050513          	addi	a0,a0,384 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203948:	b3dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==4);
ffffffffc020394c:	00004697          	auipc	a3,0x4
ffffffffc0203950:	33c68693          	addi	a3,a3,828 # ffffffffc0207c88 <default_pmm_manager+0x970>
ffffffffc0203954:	00003617          	auipc	a2,0x3
ffffffffc0203958:	27c60613          	addi	a2,a2,636 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020395c:	09f00593          	li	a1,159
ffffffffc0203960:	00004517          	auipc	a0,0x4
ffffffffc0203964:	16050513          	addi	a0,a0,352 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203968:	b1dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==4);
ffffffffc020396c:	00004697          	auipc	a3,0x4
ffffffffc0203970:	31c68693          	addi	a3,a3,796 # ffffffffc0207c88 <default_pmm_manager+0x970>
ffffffffc0203974:	00003617          	auipc	a2,0x3
ffffffffc0203978:	25c60613          	addi	a2,a2,604 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020397c:	0a100593          	li	a1,161
ffffffffc0203980:	00004517          	auipc	a0,0x4
ffffffffc0203984:	14050513          	addi	a0,a0,320 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203988:	afdfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgdir[0] == 0);
ffffffffc020398c:	00004697          	auipc	a3,0x4
ffffffffc0203990:	1ac68693          	addi	a3,a3,428 # ffffffffc0207b38 <default_pmm_manager+0x820>
ffffffffc0203994:	00003617          	auipc	a2,0x3
ffffffffc0203998:	23c60613          	addi	a2,a2,572 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020399c:	0cc00593          	li	a1,204
ffffffffc02039a0:	00004517          	auipc	a0,0x4
ffffffffc02039a4:	12050513          	addi	a0,a0,288 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc02039a8:	addfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(vma != NULL);
ffffffffc02039ac:	00004697          	auipc	a3,0x4
ffffffffc02039b0:	19c68693          	addi	a3,a3,412 # ffffffffc0207b48 <default_pmm_manager+0x830>
ffffffffc02039b4:	00003617          	auipc	a2,0x3
ffffffffc02039b8:	21c60613          	addi	a2,a2,540 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02039bc:	0cf00593          	li	a1,207
ffffffffc02039c0:	00004517          	auipc	a0,0x4
ffffffffc02039c4:	10050513          	addi	a0,a0,256 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc02039c8:	abdfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc02039cc:	00004697          	auipc	a3,0x4
ffffffffc02039d0:	1c468693          	addi	a3,a3,452 # ffffffffc0207b90 <default_pmm_manager+0x878>
ffffffffc02039d4:	00003617          	auipc	a2,0x3
ffffffffc02039d8:	1fc60613          	addi	a2,a2,508 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02039dc:	0d700593          	li	a1,215
ffffffffc02039e0:	00004517          	auipc	a0,0x4
ffffffffc02039e4:	0e050513          	addi	a0,a0,224 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc02039e8:	a9dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert( nr_free == 0);         
ffffffffc02039ec:	00003697          	auipc	a3,0x3
ffffffffc02039f0:	76c68693          	addi	a3,a3,1900 # ffffffffc0207158 <commands+0xa30>
ffffffffc02039f4:	00003617          	auipc	a2,0x3
ffffffffc02039f8:	1dc60613          	addi	a2,a2,476 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02039fc:	0f300593          	li	a1,243
ffffffffc0203a00:	00004517          	auipc	a0,0x4
ffffffffc0203a04:	0c050513          	addi	a0,a0,192 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203a08:	a7dfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203a0c:	00004617          	auipc	a2,0x4
ffffffffc0203a10:	95c60613          	addi	a2,a2,-1700 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc0203a14:	06900593          	li	a1,105
ffffffffc0203a18:	00004517          	auipc	a0,0x4
ffffffffc0203a1c:	97850513          	addi	a0,a0,-1672 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0203a20:	a65fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(count==0);
ffffffffc0203a24:	00004697          	auipc	a3,0x4
ffffffffc0203a28:	2e468693          	addi	a3,a3,740 # ffffffffc0207d08 <default_pmm_manager+0x9f0>
ffffffffc0203a2c:	00003617          	auipc	a2,0x3
ffffffffc0203a30:	1a460613          	addi	a2,a2,420 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203a34:	11d00593          	li	a1,285
ffffffffc0203a38:	00004517          	auipc	a0,0x4
ffffffffc0203a3c:	08850513          	addi	a0,a0,136 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203a40:	a45fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(total==0);
ffffffffc0203a44:	00004697          	auipc	a3,0x4
ffffffffc0203a48:	2d468693          	addi	a3,a3,724 # ffffffffc0207d18 <default_pmm_manager+0xa00>
ffffffffc0203a4c:	00003617          	auipc	a2,0x3
ffffffffc0203a50:	18460613          	addi	a2,a2,388 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203a54:	11e00593          	li	a1,286
ffffffffc0203a58:	00004517          	auipc	a0,0x4
ffffffffc0203a5c:	06850513          	addi	a0,a0,104 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203a60:	a25fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203a64:	00004697          	auipc	a3,0x4
ffffffffc0203a68:	1a468693          	addi	a3,a3,420 # ffffffffc0207c08 <default_pmm_manager+0x8f0>
ffffffffc0203a6c:	00003617          	auipc	a2,0x3
ffffffffc0203a70:	16460613          	addi	a2,a2,356 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203a74:	0ea00593          	li	a1,234
ffffffffc0203a78:	00004517          	auipc	a0,0x4
ffffffffc0203a7c:	04850513          	addi	a0,a0,72 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203a80:	a05fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(mm != NULL);
ffffffffc0203a84:	00004697          	auipc	a3,0x4
ffffffffc0203a88:	08c68693          	addi	a3,a3,140 # ffffffffc0207b10 <default_pmm_manager+0x7f8>
ffffffffc0203a8c:	00003617          	auipc	a2,0x3
ffffffffc0203a90:	14460613          	addi	a2,a2,324 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203a94:	0c400593          	li	a1,196
ffffffffc0203a98:	00004517          	auipc	a0,0x4
ffffffffc0203a9c:	02850513          	addi	a0,a0,40 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203aa0:	9e5fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0203aa4:	00004697          	auipc	a3,0x4
ffffffffc0203aa8:	07c68693          	addi	a3,a3,124 # ffffffffc0207b20 <default_pmm_manager+0x808>
ffffffffc0203aac:	00003617          	auipc	a2,0x3
ffffffffc0203ab0:	12460613          	addi	a2,a2,292 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203ab4:	0c700593          	li	a1,199
ffffffffc0203ab8:	00004517          	auipc	a0,0x4
ffffffffc0203abc:	00850513          	addi	a0,a0,8 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203ac0:	9c5fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(ret==0);
ffffffffc0203ac4:	00004697          	auipc	a3,0x4
ffffffffc0203ac8:	23c68693          	addi	a3,a3,572 # ffffffffc0207d00 <default_pmm_manager+0x9e8>
ffffffffc0203acc:	00003617          	auipc	a2,0x3
ffffffffc0203ad0:	10460613          	addi	a2,a2,260 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203ad4:	10200593          	li	a1,258
ffffffffc0203ad8:	00004517          	auipc	a0,0x4
ffffffffc0203adc:	fe850513          	addi	a0,a0,-24 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203ae0:	9a5fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(total == nr_free_pages());
ffffffffc0203ae4:	00003697          	auipc	a3,0x3
ffffffffc0203ae8:	4cc68693          	addi	a3,a3,1228 # ffffffffc0206fb0 <commands+0x888>
ffffffffc0203aec:	00003617          	auipc	a2,0x3
ffffffffc0203af0:	0e460613          	addi	a2,a2,228 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203af4:	0bf00593          	li	a1,191
ffffffffc0203af8:	00004517          	auipc	a0,0x4
ffffffffc0203afc:	fc850513          	addi	a0,a0,-56 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203b00:	985fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203b04 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0203b04:	000a9797          	auipc	a5,0xa9
ffffffffc0203b08:	99c78793          	addi	a5,a5,-1636 # ffffffffc02ac4a0 <sm>
ffffffffc0203b0c:	639c                	ld	a5,0(a5)
ffffffffc0203b0e:	0107b303          	ld	t1,16(a5)
ffffffffc0203b12:	8302                	jr	t1

ffffffffc0203b14 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0203b14:	000a9797          	auipc	a5,0xa9
ffffffffc0203b18:	98c78793          	addi	a5,a5,-1652 # ffffffffc02ac4a0 <sm>
ffffffffc0203b1c:	639c                	ld	a5,0(a5)
ffffffffc0203b1e:	0207b303          	ld	t1,32(a5)
ffffffffc0203b22:	8302                	jr	t1

ffffffffc0203b24 <swap_out>:
{
ffffffffc0203b24:	711d                	addi	sp,sp,-96
ffffffffc0203b26:	ec86                	sd	ra,88(sp)
ffffffffc0203b28:	e8a2                	sd	s0,80(sp)
ffffffffc0203b2a:	e4a6                	sd	s1,72(sp)
ffffffffc0203b2c:	e0ca                	sd	s2,64(sp)
ffffffffc0203b2e:	fc4e                	sd	s3,56(sp)
ffffffffc0203b30:	f852                	sd	s4,48(sp)
ffffffffc0203b32:	f456                	sd	s5,40(sp)
ffffffffc0203b34:	f05a                	sd	s6,32(sp)
ffffffffc0203b36:	ec5e                	sd	s7,24(sp)
ffffffffc0203b38:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0203b3a:	cde9                	beqz	a1,ffffffffc0203c14 <swap_out+0xf0>
ffffffffc0203b3c:	8ab2                	mv	s5,a2
ffffffffc0203b3e:	892a                	mv	s2,a0
ffffffffc0203b40:	8a2e                	mv	s4,a1
ffffffffc0203b42:	4401                	li	s0,0
ffffffffc0203b44:	000a9997          	auipc	s3,0xa9
ffffffffc0203b48:	95c98993          	addi	s3,s3,-1700 # ffffffffc02ac4a0 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203b4c:	00004b17          	auipc	s6,0x4
ffffffffc0203b50:	25cb0b13          	addi	s6,s6,604 # ffffffffc0207da8 <default_pmm_manager+0xa90>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203b54:	00004b97          	auipc	s7,0x4
ffffffffc0203b58:	23cb8b93          	addi	s7,s7,572 # ffffffffc0207d90 <default_pmm_manager+0xa78>
ffffffffc0203b5c:	a825                	j	ffffffffc0203b94 <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203b5e:	67a2                	ld	a5,8(sp)
ffffffffc0203b60:	8626                	mv	a2,s1
ffffffffc0203b62:	85a2                	mv	a1,s0
ffffffffc0203b64:	7f94                	ld	a3,56(a5)
ffffffffc0203b66:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0203b68:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203b6a:	82b1                	srli	a3,a3,0xc
ffffffffc0203b6c:	0685                	addi	a3,a3,1
ffffffffc0203b6e:	e20fc0ef          	jal	ra,ffffffffc020018e <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203b72:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203b74:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203b76:	7d1c                	ld	a5,56(a0)
ffffffffc0203b78:	83b1                	srli	a5,a5,0xc
ffffffffc0203b7a:	0785                	addi	a5,a5,1
ffffffffc0203b7c:	07a2                	slli	a5,a5,0x8
ffffffffc0203b7e:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203b82:	b50fe0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0203b86:	01893503          	ld	a0,24(s2)
ffffffffc0203b8a:	85a6                	mv	a1,s1
ffffffffc0203b8c:	f5eff0ef          	jal	ra,ffffffffc02032ea <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203b90:	048a0d63          	beq	s4,s0,ffffffffc0203bea <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0203b94:	0009b783          	ld	a5,0(s3)
ffffffffc0203b98:	8656                	mv	a2,s5
ffffffffc0203b9a:	002c                	addi	a1,sp,8
ffffffffc0203b9c:	7b9c                	ld	a5,48(a5)
ffffffffc0203b9e:	854a                	mv	a0,s2
ffffffffc0203ba0:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203ba2:	e12d                	bnez	a0,ffffffffc0203c04 <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc0203ba4:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203ba6:	01893503          	ld	a0,24(s2)
ffffffffc0203baa:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203bac:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203bae:	85a6                	mv	a1,s1
ffffffffc0203bb0:	ba8fe0ef          	jal	ra,ffffffffc0201f58 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203bb4:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203bb6:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0203bb8:	8b85                	andi	a5,a5,1
ffffffffc0203bba:	cfb9                	beqz	a5,ffffffffc0203c18 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203bbc:	65a2                	ld	a1,8(sp)
ffffffffc0203bbe:	7d9c                	ld	a5,56(a1)
ffffffffc0203bc0:	83b1                	srli	a5,a5,0xc
ffffffffc0203bc2:	00178513          	addi	a0,a5,1
ffffffffc0203bc6:	0522                	slli	a0,a0,0x8
ffffffffc0203bc8:	044010ef          	jal	ra,ffffffffc0204c0c <swapfs_write>
ffffffffc0203bcc:	d949                	beqz	a0,ffffffffc0203b5e <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203bce:	855e                	mv	a0,s7
ffffffffc0203bd0:	dbefc0ef          	jal	ra,ffffffffc020018e <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203bd4:	0009b783          	ld	a5,0(s3)
ffffffffc0203bd8:	6622                	ld	a2,8(sp)
ffffffffc0203bda:	4681                	li	a3,0
ffffffffc0203bdc:	739c                	ld	a5,32(a5)
ffffffffc0203bde:	85a6                	mv	a1,s1
ffffffffc0203be0:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203be2:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203be4:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0203be6:	fa8a17e3          	bne	s4,s0,ffffffffc0203b94 <swap_out+0x70>
}
ffffffffc0203bea:	8522                	mv	a0,s0
ffffffffc0203bec:	60e6                	ld	ra,88(sp)
ffffffffc0203bee:	6446                	ld	s0,80(sp)
ffffffffc0203bf0:	64a6                	ld	s1,72(sp)
ffffffffc0203bf2:	6906                	ld	s2,64(sp)
ffffffffc0203bf4:	79e2                	ld	s3,56(sp)
ffffffffc0203bf6:	7a42                	ld	s4,48(sp)
ffffffffc0203bf8:	7aa2                	ld	s5,40(sp)
ffffffffc0203bfa:	7b02                	ld	s6,32(sp)
ffffffffc0203bfc:	6be2                	ld	s7,24(sp)
ffffffffc0203bfe:	6c42                	ld	s8,16(sp)
ffffffffc0203c00:	6125                	addi	sp,sp,96
ffffffffc0203c02:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0203c04:	85a2                	mv	a1,s0
ffffffffc0203c06:	00004517          	auipc	a0,0x4
ffffffffc0203c0a:	14250513          	addi	a0,a0,322 # ffffffffc0207d48 <default_pmm_manager+0xa30>
ffffffffc0203c0e:	d80fc0ef          	jal	ra,ffffffffc020018e <cprintf>
                  break;
ffffffffc0203c12:	bfe1                	j	ffffffffc0203bea <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0203c14:	4401                	li	s0,0
ffffffffc0203c16:	bfd1                	j	ffffffffc0203bea <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203c18:	00004697          	auipc	a3,0x4
ffffffffc0203c1c:	16068693          	addi	a3,a3,352 # ffffffffc0207d78 <default_pmm_manager+0xa60>
ffffffffc0203c20:	00003617          	auipc	a2,0x3
ffffffffc0203c24:	fb060613          	addi	a2,a2,-80 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203c28:	06800593          	li	a1,104
ffffffffc0203c2c:	00004517          	auipc	a0,0x4
ffffffffc0203c30:	e9450513          	addi	a0,a0,-364 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203c34:	851fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203c38 <swap_in>:
{
ffffffffc0203c38:	7179                	addi	sp,sp,-48
ffffffffc0203c3a:	e84a                	sd	s2,16(sp)
ffffffffc0203c3c:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0203c3e:	4505                	li	a0,1
{
ffffffffc0203c40:	ec26                	sd	s1,24(sp)
ffffffffc0203c42:	e44e                	sd	s3,8(sp)
ffffffffc0203c44:	f406                	sd	ra,40(sp)
ffffffffc0203c46:	f022                	sd	s0,32(sp)
ffffffffc0203c48:	84ae                	mv	s1,a1
ffffffffc0203c4a:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0203c4c:	9fefe0ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
     assert(result!=NULL);
ffffffffc0203c50:	c129                	beqz	a0,ffffffffc0203c92 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203c52:	842a                	mv	s0,a0
ffffffffc0203c54:	01893503          	ld	a0,24(s2)
ffffffffc0203c58:	4601                	li	a2,0
ffffffffc0203c5a:	85a6                	mv	a1,s1
ffffffffc0203c5c:	afcfe0ef          	jal	ra,ffffffffc0201f58 <get_pte>
ffffffffc0203c60:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0203c62:	6108                	ld	a0,0(a0)
ffffffffc0203c64:	85a2                	mv	a1,s0
ffffffffc0203c66:	70f000ef          	jal	ra,ffffffffc0204b74 <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0203c6a:	00093583          	ld	a1,0(s2)
ffffffffc0203c6e:	8626                	mv	a2,s1
ffffffffc0203c70:	00004517          	auipc	a0,0x4
ffffffffc0203c74:	df050513          	addi	a0,a0,-528 # ffffffffc0207a60 <default_pmm_manager+0x748>
ffffffffc0203c78:	81a1                	srli	a1,a1,0x8
ffffffffc0203c7a:	d14fc0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0203c7e:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0203c80:	0089b023          	sd	s0,0(s3)
}
ffffffffc0203c84:	7402                	ld	s0,32(sp)
ffffffffc0203c86:	64e2                	ld	s1,24(sp)
ffffffffc0203c88:	6942                	ld	s2,16(sp)
ffffffffc0203c8a:	69a2                	ld	s3,8(sp)
ffffffffc0203c8c:	4501                	li	a0,0
ffffffffc0203c8e:	6145                	addi	sp,sp,48
ffffffffc0203c90:	8082                	ret
     assert(result!=NULL);
ffffffffc0203c92:	00004697          	auipc	a3,0x4
ffffffffc0203c96:	dbe68693          	addi	a3,a3,-578 # ffffffffc0207a50 <default_pmm_manager+0x738>
ffffffffc0203c9a:	00003617          	auipc	a2,0x3
ffffffffc0203c9e:	f3660613          	addi	a2,a2,-202 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203ca2:	07e00593          	li	a1,126
ffffffffc0203ca6:	00004517          	auipc	a0,0x4
ffffffffc0203caa:	e1a50513          	addi	a0,a0,-486 # ffffffffc0207ac0 <default_pmm_manager+0x7a8>
ffffffffc0203cae:	fd6fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203cb2 <_fifo_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203cb2:	000a9797          	auipc	a5,0xa9
ffffffffc0203cb6:	92678793          	addi	a5,a5,-1754 # ffffffffc02ac5d8 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{
    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
ffffffffc0203cba:	f51c                	sd	a5,40(a0)
ffffffffc0203cbc:	e79c                	sd	a5,8(a5)
ffffffffc0203cbe:	e39c                	sd	a5,0(a5)
    // cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
    return 0;
}
ffffffffc0203cc0:	4501                	li	a0,0
ffffffffc0203cc2:	8082                	ret

ffffffffc0203cc4 <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0203cc4:	4501                	li	a0,0
ffffffffc0203cc6:	8082                	ret

ffffffffc0203cc8 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0203cc8:	4501                	li	a0,0
ffffffffc0203cca:	8082                	ret

ffffffffc0203ccc <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{
    return 0;
}
ffffffffc0203ccc:	4501                	li	a0,0
ffffffffc0203cce:	8082                	ret

ffffffffc0203cd0 <_fifo_check_swap>:
{
ffffffffc0203cd0:	711d                	addi	sp,sp,-96
ffffffffc0203cd2:	fc4e                	sd	s3,56(sp)
ffffffffc0203cd4:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203cd6:	00004517          	auipc	a0,0x4
ffffffffc0203cda:	11250513          	addi	a0,a0,274 # ffffffffc0207de8 <default_pmm_manager+0xad0>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203cde:	698d                	lui	s3,0x3
ffffffffc0203ce0:	4a31                	li	s4,12
{
ffffffffc0203ce2:	e8a2                	sd	s0,80(sp)
ffffffffc0203ce4:	e4a6                	sd	s1,72(sp)
ffffffffc0203ce6:	ec86                	sd	ra,88(sp)
ffffffffc0203ce8:	e0ca                	sd	s2,64(sp)
ffffffffc0203cea:	f456                	sd	s5,40(sp)
ffffffffc0203cec:	f05a                	sd	s6,32(sp)
ffffffffc0203cee:	ec5e                	sd	s7,24(sp)
ffffffffc0203cf0:	e862                	sd	s8,16(sp)
ffffffffc0203cf2:	e466                	sd	s9,8(sp)
    assert(pgfault_num == 4);
ffffffffc0203cf4:	000a8417          	auipc	s0,0xa8
ffffffffc0203cf8:	7b840413          	addi	s0,s0,1976 # ffffffffc02ac4ac <pgfault_num>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203cfc:	c92fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203d00:	01498023          	sb	s4,0(s3) # 3000 <_binary_obj___user_faultread_out_size-0x6580>
    assert(pgfault_num == 4);
ffffffffc0203d04:	4004                	lw	s1,0(s0)
ffffffffc0203d06:	4791                	li	a5,4
ffffffffc0203d08:	2481                	sext.w	s1,s1
ffffffffc0203d0a:	14f49963          	bne	s1,a5,ffffffffc0203e5c <_fifo_check_swap+0x18c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d0e:	00004517          	auipc	a0,0x4
ffffffffc0203d12:	13250513          	addi	a0,a0,306 # ffffffffc0207e40 <default_pmm_manager+0xb28>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d16:	6a85                	lui	s5,0x1
ffffffffc0203d18:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d1a:	c74fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d1e:	016a8023          	sb	s6,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
    assert(pgfault_num == 4);
ffffffffc0203d22:	00042903          	lw	s2,0(s0)
ffffffffc0203d26:	2901                	sext.w	s2,s2
ffffffffc0203d28:	2a991a63          	bne	s2,s1,ffffffffc0203fdc <_fifo_check_swap+0x30c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203d2c:	00004517          	auipc	a0,0x4
ffffffffc0203d30:	13c50513          	addi	a0,a0,316 # ffffffffc0207e68 <default_pmm_manager+0xb50>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203d34:	6b91                	lui	s7,0x4
ffffffffc0203d36:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203d38:	c56fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203d3c:	018b8023          	sb	s8,0(s7) # 4000 <_binary_obj___user_faultread_out_size-0x5580>
    assert(pgfault_num == 4);
ffffffffc0203d40:	4004                	lw	s1,0(s0)
ffffffffc0203d42:	2481                	sext.w	s1,s1
ffffffffc0203d44:	27249c63          	bne	s1,s2,ffffffffc0203fbc <_fifo_check_swap+0x2ec>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d48:	00004517          	auipc	a0,0x4
ffffffffc0203d4c:	14850513          	addi	a0,a0,328 # ffffffffc0207e90 <default_pmm_manager+0xb78>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d50:	6909                	lui	s2,0x2
ffffffffc0203d52:	4cad                	li	s9,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d54:	c3afc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d58:	01990023          	sb	s9,0(s2) # 2000 <_binary_obj___user_faultread_out_size-0x7580>
    assert(pgfault_num == 4);
ffffffffc0203d5c:	401c                	lw	a5,0(s0)
ffffffffc0203d5e:	2781                	sext.w	a5,a5
ffffffffc0203d60:	22979e63          	bne	a5,s1,ffffffffc0203f9c <_fifo_check_swap+0x2cc>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203d64:	00004517          	auipc	a0,0x4
ffffffffc0203d68:	15450513          	addi	a0,a0,340 # ffffffffc0207eb8 <default_pmm_manager+0xba0>
ffffffffc0203d6c:	c22fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203d70:	6795                	lui	a5,0x5
ffffffffc0203d72:	4739                	li	a4,14
ffffffffc0203d74:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4580>
    assert(pgfault_num == 5);
ffffffffc0203d78:	4004                	lw	s1,0(s0)
ffffffffc0203d7a:	4795                	li	a5,5
ffffffffc0203d7c:	2481                	sext.w	s1,s1
ffffffffc0203d7e:	1ef49f63          	bne	s1,a5,ffffffffc0203f7c <_fifo_check_swap+0x2ac>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d82:	00004517          	auipc	a0,0x4
ffffffffc0203d86:	10e50513          	addi	a0,a0,270 # ffffffffc0207e90 <default_pmm_manager+0xb78>
ffffffffc0203d8a:	c04fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d8e:	01990023          	sb	s9,0(s2)
    assert(pgfault_num == 5);
ffffffffc0203d92:	401c                	lw	a5,0(s0)
ffffffffc0203d94:	2781                	sext.w	a5,a5
ffffffffc0203d96:	1c979363          	bne	a5,s1,ffffffffc0203f5c <_fifo_check_swap+0x28c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d9a:	00004517          	auipc	a0,0x4
ffffffffc0203d9e:	0a650513          	addi	a0,a0,166 # ffffffffc0207e40 <default_pmm_manager+0xb28>
ffffffffc0203da2:	becfc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203da6:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num == 6);
ffffffffc0203daa:	401c                	lw	a5,0(s0)
ffffffffc0203dac:	4719                	li	a4,6
ffffffffc0203dae:	2781                	sext.w	a5,a5
ffffffffc0203db0:	18e79663          	bne	a5,a4,ffffffffc0203f3c <_fifo_check_swap+0x26c>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203db4:	00004517          	auipc	a0,0x4
ffffffffc0203db8:	0dc50513          	addi	a0,a0,220 # ffffffffc0207e90 <default_pmm_manager+0xb78>
ffffffffc0203dbc:	bd2fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203dc0:	01990023          	sb	s9,0(s2)
    assert(pgfault_num == 7);
ffffffffc0203dc4:	401c                	lw	a5,0(s0)
ffffffffc0203dc6:	471d                	li	a4,7
ffffffffc0203dc8:	2781                	sext.w	a5,a5
ffffffffc0203dca:	14e79963          	bne	a5,a4,ffffffffc0203f1c <_fifo_check_swap+0x24c>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203dce:	00004517          	auipc	a0,0x4
ffffffffc0203dd2:	01a50513          	addi	a0,a0,26 # ffffffffc0207de8 <default_pmm_manager+0xad0>
ffffffffc0203dd6:	bb8fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203dda:	01498023          	sb	s4,0(s3)
    assert(pgfault_num == 8);
ffffffffc0203dde:	401c                	lw	a5,0(s0)
ffffffffc0203de0:	4721                	li	a4,8
ffffffffc0203de2:	2781                	sext.w	a5,a5
ffffffffc0203de4:	10e79c63          	bne	a5,a4,ffffffffc0203efc <_fifo_check_swap+0x22c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203de8:	00004517          	auipc	a0,0x4
ffffffffc0203dec:	08050513          	addi	a0,a0,128 # ffffffffc0207e68 <default_pmm_manager+0xb50>
ffffffffc0203df0:	b9efc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203df4:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num == 9);
ffffffffc0203df8:	401c                	lw	a5,0(s0)
ffffffffc0203dfa:	4725                	li	a4,9
ffffffffc0203dfc:	2781                	sext.w	a5,a5
ffffffffc0203dfe:	0ce79f63          	bne	a5,a4,ffffffffc0203edc <_fifo_check_swap+0x20c>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203e02:	00004517          	auipc	a0,0x4
ffffffffc0203e06:	0b650513          	addi	a0,a0,182 # ffffffffc0207eb8 <default_pmm_manager+0xba0>
ffffffffc0203e0a:	b84fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203e0e:	6795                	lui	a5,0x5
ffffffffc0203e10:	4739                	li	a4,14
ffffffffc0203e12:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4580>
    assert(pgfault_num == 10);
ffffffffc0203e16:	4004                	lw	s1,0(s0)
ffffffffc0203e18:	47a9                	li	a5,10
ffffffffc0203e1a:	2481                	sext.w	s1,s1
ffffffffc0203e1c:	0af49063          	bne	s1,a5,ffffffffc0203ebc <_fifo_check_swap+0x1ec>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203e20:	00004517          	auipc	a0,0x4
ffffffffc0203e24:	02050513          	addi	a0,a0,32 # ffffffffc0207e40 <default_pmm_manager+0xb28>
ffffffffc0203e28:	b66fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203e2c:	6785                	lui	a5,0x1
ffffffffc0203e2e:	0007c783          	lbu	a5,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
ffffffffc0203e32:	06979563          	bne	a5,s1,ffffffffc0203e9c <_fifo_check_swap+0x1cc>
    assert(pgfault_num == 11);
ffffffffc0203e36:	401c                	lw	a5,0(s0)
ffffffffc0203e38:	472d                	li	a4,11
ffffffffc0203e3a:	2781                	sext.w	a5,a5
ffffffffc0203e3c:	04e79063          	bne	a5,a4,ffffffffc0203e7c <_fifo_check_swap+0x1ac>
}
ffffffffc0203e40:	60e6                	ld	ra,88(sp)
ffffffffc0203e42:	6446                	ld	s0,80(sp)
ffffffffc0203e44:	64a6                	ld	s1,72(sp)
ffffffffc0203e46:	6906                	ld	s2,64(sp)
ffffffffc0203e48:	79e2                	ld	s3,56(sp)
ffffffffc0203e4a:	7a42                	ld	s4,48(sp)
ffffffffc0203e4c:	7aa2                	ld	s5,40(sp)
ffffffffc0203e4e:	7b02                	ld	s6,32(sp)
ffffffffc0203e50:	6be2                	ld	s7,24(sp)
ffffffffc0203e52:	6c42                	ld	s8,16(sp)
ffffffffc0203e54:	6ca2                	ld	s9,8(sp)
ffffffffc0203e56:	4501                	li	a0,0
ffffffffc0203e58:	6125                	addi	sp,sp,96
ffffffffc0203e5a:	8082                	ret
    assert(pgfault_num == 4);
ffffffffc0203e5c:	00004697          	auipc	a3,0x4
ffffffffc0203e60:	fb468693          	addi	a3,a3,-76 # ffffffffc0207e10 <default_pmm_manager+0xaf8>
ffffffffc0203e64:	00003617          	auipc	a2,0x3
ffffffffc0203e68:	d6c60613          	addi	a2,a2,-660 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203e6c:	05200593          	li	a1,82
ffffffffc0203e70:	00004517          	auipc	a0,0x4
ffffffffc0203e74:	fb850513          	addi	a0,a0,-72 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc0203e78:	e0cfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num == 11);
ffffffffc0203e7c:	00004697          	auipc	a3,0x4
ffffffffc0203e80:	11c68693          	addi	a3,a3,284 # ffffffffc0207f98 <default_pmm_manager+0xc80>
ffffffffc0203e84:	00003617          	auipc	a2,0x3
ffffffffc0203e88:	d4c60613          	addi	a2,a2,-692 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203e8c:	07400593          	li	a1,116
ffffffffc0203e90:	00004517          	auipc	a0,0x4
ffffffffc0203e94:	f9850513          	addi	a0,a0,-104 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc0203e98:	decfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203e9c:	00004697          	auipc	a3,0x4
ffffffffc0203ea0:	0d468693          	addi	a3,a3,212 # ffffffffc0207f70 <default_pmm_manager+0xc58>
ffffffffc0203ea4:	00003617          	auipc	a2,0x3
ffffffffc0203ea8:	d2c60613          	addi	a2,a2,-724 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203eac:	07200593          	li	a1,114
ffffffffc0203eb0:	00004517          	auipc	a0,0x4
ffffffffc0203eb4:	f7850513          	addi	a0,a0,-136 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc0203eb8:	dccfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num == 10);
ffffffffc0203ebc:	00004697          	auipc	a3,0x4
ffffffffc0203ec0:	09c68693          	addi	a3,a3,156 # ffffffffc0207f58 <default_pmm_manager+0xc40>
ffffffffc0203ec4:	00003617          	auipc	a2,0x3
ffffffffc0203ec8:	d0c60613          	addi	a2,a2,-756 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203ecc:	07000593          	li	a1,112
ffffffffc0203ed0:	00004517          	auipc	a0,0x4
ffffffffc0203ed4:	f5850513          	addi	a0,a0,-168 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc0203ed8:	dacfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num == 9);
ffffffffc0203edc:	00004697          	auipc	a3,0x4
ffffffffc0203ee0:	06468693          	addi	a3,a3,100 # ffffffffc0207f40 <default_pmm_manager+0xc28>
ffffffffc0203ee4:	00003617          	auipc	a2,0x3
ffffffffc0203ee8:	cec60613          	addi	a2,a2,-788 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203eec:	06d00593          	li	a1,109
ffffffffc0203ef0:	00004517          	auipc	a0,0x4
ffffffffc0203ef4:	f3850513          	addi	a0,a0,-200 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc0203ef8:	d8cfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num == 8);
ffffffffc0203efc:	00004697          	auipc	a3,0x4
ffffffffc0203f00:	02c68693          	addi	a3,a3,44 # ffffffffc0207f28 <default_pmm_manager+0xc10>
ffffffffc0203f04:	00003617          	auipc	a2,0x3
ffffffffc0203f08:	ccc60613          	addi	a2,a2,-820 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203f0c:	06a00593          	li	a1,106
ffffffffc0203f10:	00004517          	auipc	a0,0x4
ffffffffc0203f14:	f1850513          	addi	a0,a0,-232 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc0203f18:	d6cfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num == 7);
ffffffffc0203f1c:	00004697          	auipc	a3,0x4
ffffffffc0203f20:	ff468693          	addi	a3,a3,-12 # ffffffffc0207f10 <default_pmm_manager+0xbf8>
ffffffffc0203f24:	00003617          	auipc	a2,0x3
ffffffffc0203f28:	cac60613          	addi	a2,a2,-852 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203f2c:	06700593          	li	a1,103
ffffffffc0203f30:	00004517          	auipc	a0,0x4
ffffffffc0203f34:	ef850513          	addi	a0,a0,-264 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc0203f38:	d4cfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num == 6);
ffffffffc0203f3c:	00004697          	auipc	a3,0x4
ffffffffc0203f40:	fbc68693          	addi	a3,a3,-68 # ffffffffc0207ef8 <default_pmm_manager+0xbe0>
ffffffffc0203f44:	00003617          	auipc	a2,0x3
ffffffffc0203f48:	c8c60613          	addi	a2,a2,-884 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203f4c:	06400593          	li	a1,100
ffffffffc0203f50:	00004517          	auipc	a0,0x4
ffffffffc0203f54:	ed850513          	addi	a0,a0,-296 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc0203f58:	d2cfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num == 5);
ffffffffc0203f5c:	00004697          	auipc	a3,0x4
ffffffffc0203f60:	f8468693          	addi	a3,a3,-124 # ffffffffc0207ee0 <default_pmm_manager+0xbc8>
ffffffffc0203f64:	00003617          	auipc	a2,0x3
ffffffffc0203f68:	c6c60613          	addi	a2,a2,-916 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203f6c:	06100593          	li	a1,97
ffffffffc0203f70:	00004517          	auipc	a0,0x4
ffffffffc0203f74:	eb850513          	addi	a0,a0,-328 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc0203f78:	d0cfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num == 5);
ffffffffc0203f7c:	00004697          	auipc	a3,0x4
ffffffffc0203f80:	f6468693          	addi	a3,a3,-156 # ffffffffc0207ee0 <default_pmm_manager+0xbc8>
ffffffffc0203f84:	00003617          	auipc	a2,0x3
ffffffffc0203f88:	c4c60613          	addi	a2,a2,-948 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203f8c:	05e00593          	li	a1,94
ffffffffc0203f90:	00004517          	auipc	a0,0x4
ffffffffc0203f94:	e9850513          	addi	a0,a0,-360 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc0203f98:	cecfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num == 4);
ffffffffc0203f9c:	00004697          	auipc	a3,0x4
ffffffffc0203fa0:	e7468693          	addi	a3,a3,-396 # ffffffffc0207e10 <default_pmm_manager+0xaf8>
ffffffffc0203fa4:	00003617          	auipc	a2,0x3
ffffffffc0203fa8:	c2c60613          	addi	a2,a2,-980 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203fac:	05b00593          	li	a1,91
ffffffffc0203fb0:	00004517          	auipc	a0,0x4
ffffffffc0203fb4:	e7850513          	addi	a0,a0,-392 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc0203fb8:	cccfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num == 4);
ffffffffc0203fbc:	00004697          	auipc	a3,0x4
ffffffffc0203fc0:	e5468693          	addi	a3,a3,-428 # ffffffffc0207e10 <default_pmm_manager+0xaf8>
ffffffffc0203fc4:	00003617          	auipc	a2,0x3
ffffffffc0203fc8:	c0c60613          	addi	a2,a2,-1012 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203fcc:	05800593          	li	a1,88
ffffffffc0203fd0:	00004517          	auipc	a0,0x4
ffffffffc0203fd4:	e5850513          	addi	a0,a0,-424 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc0203fd8:	cacfc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num == 4);
ffffffffc0203fdc:	00004697          	auipc	a3,0x4
ffffffffc0203fe0:	e3468693          	addi	a3,a3,-460 # ffffffffc0207e10 <default_pmm_manager+0xaf8>
ffffffffc0203fe4:	00003617          	auipc	a2,0x3
ffffffffc0203fe8:	bec60613          	addi	a2,a2,-1044 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0203fec:	05500593          	li	a1,85
ffffffffc0203ff0:	00004517          	auipc	a0,0x4
ffffffffc0203ff4:	e3850513          	addi	a0,a0,-456 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc0203ff8:	c8cfc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203ffc <_fifo_swap_out_victim>:
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
ffffffffc0203ffc:	751c                	ld	a5,40(a0)
{
ffffffffc0203ffe:	1141                	addi	sp,sp,-16
ffffffffc0204000:	e406                	sd	ra,8(sp)
    assert(head != NULL);
ffffffffc0204002:	cf91                	beqz	a5,ffffffffc020401e <_fifo_swap_out_victim+0x22>
    assert(in_tick == 0);
ffffffffc0204004:	ee0d                	bnez	a2,ffffffffc020403e <_fifo_swap_out_victim+0x42>
    return listelm->next;
ffffffffc0204006:	679c                	ld	a5,8(a5)
}
ffffffffc0204008:	60a2                	ld	ra,8(sp)
ffffffffc020400a:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc020400c:	6394                	ld	a3,0(a5)
ffffffffc020400e:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc0204010:	fd878793          	addi	a5,a5,-40
    prev->next = next;
ffffffffc0204014:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204016:	e314                	sd	a3,0(a4)
ffffffffc0204018:	e19c                	sd	a5,0(a1)
}
ffffffffc020401a:	0141                	addi	sp,sp,16
ffffffffc020401c:	8082                	ret
    assert(head != NULL);
ffffffffc020401e:	00004697          	auipc	a3,0x4
ffffffffc0204022:	fb268693          	addi	a3,a3,-78 # ffffffffc0207fd0 <default_pmm_manager+0xcb8>
ffffffffc0204026:	00003617          	auipc	a2,0x3
ffffffffc020402a:	baa60613          	addi	a2,a2,-1110 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020402e:	04100593          	li	a1,65
ffffffffc0204032:	00004517          	auipc	a0,0x4
ffffffffc0204036:	df650513          	addi	a0,a0,-522 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc020403a:	c4afc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(in_tick == 0);
ffffffffc020403e:	00004697          	auipc	a3,0x4
ffffffffc0204042:	fa268693          	addi	a3,a3,-94 # ffffffffc0207fe0 <default_pmm_manager+0xcc8>
ffffffffc0204046:	00003617          	auipc	a2,0x3
ffffffffc020404a:	b8a60613          	addi	a2,a2,-1142 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020404e:	04200593          	li	a1,66
ffffffffc0204052:	00004517          	auipc	a0,0x4
ffffffffc0204056:	dd650513          	addi	a0,a0,-554 # ffffffffc0207e28 <default_pmm_manager+0xb10>
ffffffffc020405a:	c2afc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020405e <_fifo_map_swappable>:
    list_entry_t *entry = &(page->pra_page_link);
ffffffffc020405e:	02860713          	addi	a4,a2,40
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
ffffffffc0204062:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc0204064:	cb09                	beqz	a4,ffffffffc0204076 <_fifo_map_swappable+0x18>
ffffffffc0204066:	cb81                	beqz	a5,ffffffffc0204076 <_fifo_map_swappable+0x18>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0204068:	6394                	ld	a3,0(a5)
    prev->next = next->prev = elm;
ffffffffc020406a:	e398                	sd	a4,0(a5)
}
ffffffffc020406c:	4501                	li	a0,0
ffffffffc020406e:	e698                	sd	a4,8(a3)
    elm->next = next;
ffffffffc0204070:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc0204072:	f614                	sd	a3,40(a2)
ffffffffc0204074:	8082                	ret
{
ffffffffc0204076:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0204078:	00004697          	auipc	a3,0x4
ffffffffc020407c:	f3868693          	addi	a3,a3,-200 # ffffffffc0207fb0 <default_pmm_manager+0xc98>
ffffffffc0204080:	00003617          	auipc	a2,0x3
ffffffffc0204084:	b5060613          	addi	a2,a2,-1200 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204088:	03200593          	li	a1,50
ffffffffc020408c:	00004517          	auipc	a0,0x4
ffffffffc0204090:	d9c50513          	addi	a0,a0,-612 # ffffffffc0207e28 <default_pmm_manager+0xb10>
{
ffffffffc0204094:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0204096:	beefc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020409a <check_vma_overlap.isra.0.part.1>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020409a:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020409c:	00004697          	auipc	a3,0x4
ffffffffc02040a0:	f6c68693          	addi	a3,a3,-148 # ffffffffc0208008 <default_pmm_manager+0xcf0>
ffffffffc02040a4:	00003617          	auipc	a2,0x3
ffffffffc02040a8:	b2c60613          	addi	a2,a2,-1236 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02040ac:	07900593          	li	a1,121
ffffffffc02040b0:	00004517          	auipc	a0,0x4
ffffffffc02040b4:	f7850513          	addi	a0,a0,-136 # ffffffffc0208028 <default_pmm_manager+0xd10>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02040b8:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02040ba:	bcafc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02040be <mm_create>:
{
ffffffffc02040be:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02040c0:	04000513          	li	a0,64
{
ffffffffc02040c4:	e022                	sd	s0,0(sp)
ffffffffc02040c6:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02040c8:	b87fd0ef          	jal	ra,ffffffffc0201c4e <kmalloc>
ffffffffc02040cc:	842a                	mv	s0,a0
    if (mm != NULL)
ffffffffc02040ce:	c515                	beqz	a0,ffffffffc02040fa <mm_create+0x3c>
        if (swap_init_ok)
ffffffffc02040d0:	000a8797          	auipc	a5,0xa8
ffffffffc02040d4:	3d878793          	addi	a5,a5,984 # ffffffffc02ac4a8 <swap_init_ok>
ffffffffc02040d8:	439c                	lw	a5,0(a5)
    elm->prev = elm->next = elm;
ffffffffc02040da:	e408                	sd	a0,8(s0)
ffffffffc02040dc:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc02040de:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02040e2:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02040e6:	02052023          	sw	zero,32(a0)
        if (swap_init_ok)
ffffffffc02040ea:	2781                	sext.w	a5,a5
ffffffffc02040ec:	ef81                	bnez	a5,ffffffffc0204104 <mm_create+0x46>
            mm->sm_priv = NULL;
ffffffffc02040ee:	02053423          	sd	zero,40(a0)
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
ffffffffc02040f2:	02042823          	sw	zero,48(s0)

typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock) {
    *lock = 0;
ffffffffc02040f6:	02043c23          	sd	zero,56(s0)
}
ffffffffc02040fa:	8522                	mv	a0,s0
ffffffffc02040fc:	60a2                	ld	ra,8(sp)
ffffffffc02040fe:	6402                	ld	s0,0(sp)
ffffffffc0204100:	0141                	addi	sp,sp,16
ffffffffc0204102:	8082                	ret
            swap_init_mm(mm);
ffffffffc0204104:	a01ff0ef          	jal	ra,ffffffffc0203b04 <swap_init_mm>
ffffffffc0204108:	b7ed                	j	ffffffffc02040f2 <mm_create+0x34>

ffffffffc020410a <vma_create>:
{
ffffffffc020410a:	1101                	addi	sp,sp,-32
ffffffffc020410c:	e04a                	sd	s2,0(sp)
ffffffffc020410e:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204110:	03000513          	li	a0,48
{
ffffffffc0204114:	e822                	sd	s0,16(sp)
ffffffffc0204116:	e426                	sd	s1,8(sp)
ffffffffc0204118:	ec06                	sd	ra,24(sp)
ffffffffc020411a:	84ae                	mv	s1,a1
ffffffffc020411c:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020411e:	b31fd0ef          	jal	ra,ffffffffc0201c4e <kmalloc>
    if (vma != NULL)
ffffffffc0204122:	c509                	beqz	a0,ffffffffc020412c <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0204124:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0204128:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020412a:	cd00                	sw	s0,24(a0)
}
ffffffffc020412c:	60e2                	ld	ra,24(sp)
ffffffffc020412e:	6442                	ld	s0,16(sp)
ffffffffc0204130:	64a2                	ld	s1,8(sp)
ffffffffc0204132:	6902                	ld	s2,0(sp)
ffffffffc0204134:	6105                	addi	sp,sp,32
ffffffffc0204136:	8082                	ret

ffffffffc0204138 <find_vma>:
    if (mm != NULL)
ffffffffc0204138:	c51d                	beqz	a0,ffffffffc0204166 <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc020413a:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020413c:	c781                	beqz	a5,ffffffffc0204144 <find_vma+0xc>
ffffffffc020413e:	6798                	ld	a4,8(a5)
ffffffffc0204140:	02e5f663          	bleu	a4,a1,ffffffffc020416c <find_vma+0x34>
            list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc0204144:	87aa                	mv	a5,a0
    return listelm->next;
ffffffffc0204146:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0204148:	00f50f63          	beq	a0,a5,ffffffffc0204166 <find_vma+0x2e>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc020414c:	fe87b703          	ld	a4,-24(a5)
ffffffffc0204150:	fee5ebe3          	bltu	a1,a4,ffffffffc0204146 <find_vma+0xe>
ffffffffc0204154:	ff07b703          	ld	a4,-16(a5)
ffffffffc0204158:	fee5f7e3          	bleu	a4,a1,ffffffffc0204146 <find_vma+0xe>
                vma = le2vma(le, list_link);
ffffffffc020415c:	1781                	addi	a5,a5,-32
        if (vma != NULL)
ffffffffc020415e:	c781                	beqz	a5,ffffffffc0204166 <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc0204160:	e91c                	sd	a5,16(a0)
}
ffffffffc0204162:	853e                	mv	a0,a5
ffffffffc0204164:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc0204166:	4781                	li	a5,0
}
ffffffffc0204168:	853e                	mv	a0,a5
ffffffffc020416a:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020416c:	6b98                	ld	a4,16(a5)
ffffffffc020416e:	fce5fbe3          	bleu	a4,a1,ffffffffc0204144 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0204172:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc0204174:	b7fd                	j	ffffffffc0204162 <find_vma+0x2a>

ffffffffc0204176 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0204176:	6590                	ld	a2,8(a1)
ffffffffc0204178:	0105b803          	ld	a6,16(a1) # 1010 <_binary_obj___user_faultread_out_size-0x8570>
{
ffffffffc020417c:	1141                	addi	sp,sp,-16
ffffffffc020417e:	e406                	sd	ra,8(sp)
ffffffffc0204180:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0204182:	01066863          	bltu	a2,a6,ffffffffc0204192 <insert_vma_struct+0x1c>
ffffffffc0204186:	a8b9                	j	ffffffffc02041e4 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0204188:	fe87b683          	ld	a3,-24(a5)
ffffffffc020418c:	04d66763          	bltu	a2,a3,ffffffffc02041da <insert_vma_struct+0x64>
ffffffffc0204190:	873e                	mv	a4,a5
ffffffffc0204192:	671c                	ld	a5,8(a4)
    while ((le = list_next(le)) != list)
ffffffffc0204194:	fef51ae3          	bne	a0,a5,ffffffffc0204188 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0204198:	02a70463          	beq	a4,a0,ffffffffc02041c0 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020419c:	ff073683          	ld	a3,-16(a4)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02041a0:	fe873883          	ld	a7,-24(a4)
ffffffffc02041a4:	08d8f063          	bleu	a3,a7,ffffffffc0204224 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02041a8:	04d66e63          	bltu	a2,a3,ffffffffc0204204 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc02041ac:	00f50a63          	beq	a0,a5,ffffffffc02041c0 <insert_vma_struct+0x4a>
ffffffffc02041b0:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02041b4:	0506e863          	bltu	a3,a6,ffffffffc0204204 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02041b8:	ff07b603          	ld	a2,-16(a5)
ffffffffc02041bc:	02c6f263          	bleu	a2,a3,ffffffffc02041e0 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc02041c0:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc02041c2:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02041c4:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02041c8:	e390                	sd	a2,0(a5)
ffffffffc02041ca:	e710                	sd	a2,8(a4)
}
ffffffffc02041cc:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02041ce:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02041d0:	f198                	sd	a4,32(a1)
    mm->map_count++;
ffffffffc02041d2:	2685                	addiw	a3,a3,1
ffffffffc02041d4:	d114                	sw	a3,32(a0)
}
ffffffffc02041d6:	0141                	addi	sp,sp,16
ffffffffc02041d8:	8082                	ret
    if (le_prev != list)
ffffffffc02041da:	fca711e3          	bne	a4,a0,ffffffffc020419c <insert_vma_struct+0x26>
ffffffffc02041de:	bfd9                	j	ffffffffc02041b4 <insert_vma_struct+0x3e>
ffffffffc02041e0:	ebbff0ef          	jal	ra,ffffffffc020409a <check_vma_overlap.isra.0.part.1>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02041e4:	00004697          	auipc	a3,0x4
ffffffffc02041e8:	f5468693          	addi	a3,a3,-172 # ffffffffc0208138 <default_pmm_manager+0xe20>
ffffffffc02041ec:	00003617          	auipc	a2,0x3
ffffffffc02041f0:	9e460613          	addi	a2,a2,-1564 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02041f4:	07f00593          	li	a1,127
ffffffffc02041f8:	00004517          	auipc	a0,0x4
ffffffffc02041fc:	e3050513          	addi	a0,a0,-464 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc0204200:	a84fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0204204:	00004697          	auipc	a3,0x4
ffffffffc0204208:	f7468693          	addi	a3,a3,-140 # ffffffffc0208178 <default_pmm_manager+0xe60>
ffffffffc020420c:	00003617          	auipc	a2,0x3
ffffffffc0204210:	9c460613          	addi	a2,a2,-1596 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204214:	07800593          	li	a1,120
ffffffffc0204218:	00004517          	auipc	a0,0x4
ffffffffc020421c:	e1050513          	addi	a0,a0,-496 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc0204220:	a64fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0204224:	00004697          	auipc	a3,0x4
ffffffffc0204228:	f3468693          	addi	a3,a3,-204 # ffffffffc0208158 <default_pmm_manager+0xe40>
ffffffffc020422c:	00003617          	auipc	a2,0x3
ffffffffc0204230:	9a460613          	addi	a2,a2,-1628 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204234:	07700593          	li	a1,119
ffffffffc0204238:	00004517          	auipc	a0,0x4
ffffffffc020423c:	df050513          	addi	a0,a0,-528 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc0204240:	a44fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204244 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0204244:	591c                	lw	a5,48(a0)
{
ffffffffc0204246:	1141                	addi	sp,sp,-16
ffffffffc0204248:	e406                	sd	ra,8(sp)
ffffffffc020424a:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc020424c:	e78d                	bnez	a5,ffffffffc0204276 <mm_destroy+0x32>
ffffffffc020424e:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0204250:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0204252:	00a40c63          	beq	s0,a0,ffffffffc020426a <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204256:	6118                	ld	a4,0(a0)
ffffffffc0204258:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020425a:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc020425c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020425e:	e398                	sd	a4,0(a5)
ffffffffc0204260:	aabfd0ef          	jal	ra,ffffffffc0201d0a <kfree>
    return listelm->next;
ffffffffc0204264:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0204266:	fea418e3          	bne	s0,a0,ffffffffc0204256 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc020426a:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc020426c:	6402                	ld	s0,0(sp)
ffffffffc020426e:	60a2                	ld	ra,8(sp)
ffffffffc0204270:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0204272:	a99fd06f          	j	ffffffffc0201d0a <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0204276:	00004697          	auipc	a3,0x4
ffffffffc020427a:	f2268693          	addi	a3,a3,-222 # ffffffffc0208198 <default_pmm_manager+0xe80>
ffffffffc020427e:	00003617          	auipc	a2,0x3
ffffffffc0204282:	95260613          	addi	a2,a2,-1710 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204286:	0a300593          	li	a1,163
ffffffffc020428a:	00004517          	auipc	a0,0x4
ffffffffc020428e:	d9e50513          	addi	a0,a0,-610 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc0204292:	9f2fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204296 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0204296:	6785                	lui	a5,0x1
{
ffffffffc0204298:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020429a:	17fd                	addi	a5,a5,-1
ffffffffc020429c:	787d                	lui	a6,0xfffff
{
ffffffffc020429e:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02042a0:	00f60433          	add	s0,a2,a5
{
ffffffffc02042a4:	f426                	sd	s1,40(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02042a6:	942e                	add	s0,s0,a1
{
ffffffffc02042a8:	fc06                	sd	ra,56(sp)
ffffffffc02042aa:	f04a                	sd	s2,32(sp)
ffffffffc02042ac:	ec4e                	sd	s3,24(sp)
ffffffffc02042ae:	e852                	sd	s4,16(sp)
ffffffffc02042b0:	e456                	sd	s5,8(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02042b2:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc02042b6:	002007b7          	lui	a5,0x200
ffffffffc02042ba:	01047433          	and	s0,s0,a6
ffffffffc02042be:	06f4e363          	bltu	s1,a5,ffffffffc0204324 <mm_map+0x8e>
ffffffffc02042c2:	0684f163          	bleu	s0,s1,ffffffffc0204324 <mm_map+0x8e>
ffffffffc02042c6:	4785                	li	a5,1
ffffffffc02042c8:	07fe                	slli	a5,a5,0x1f
ffffffffc02042ca:	0487ed63          	bltu	a5,s0,ffffffffc0204324 <mm_map+0x8e>
ffffffffc02042ce:	89aa                	mv	s3,a0
ffffffffc02042d0:	8a3a                	mv	s4,a4
ffffffffc02042d2:	8ab6                	mv	s5,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc02042d4:	c931                	beqz	a0,ffffffffc0204328 <mm_map+0x92>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc02042d6:	85a6                	mv	a1,s1
ffffffffc02042d8:	e61ff0ef          	jal	ra,ffffffffc0204138 <find_vma>
ffffffffc02042dc:	c501                	beqz	a0,ffffffffc02042e4 <mm_map+0x4e>
ffffffffc02042de:	651c                	ld	a5,8(a0)
ffffffffc02042e0:	0487e263          	bltu	a5,s0,ffffffffc0204324 <mm_map+0x8e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02042e4:	03000513          	li	a0,48
ffffffffc02042e8:	967fd0ef          	jal	ra,ffffffffc0201c4e <kmalloc>
ffffffffc02042ec:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02042ee:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc02042f0:	02090163          	beqz	s2,ffffffffc0204312 <mm_map+0x7c>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02042f4:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02042f6:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc02042fa:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02042fe:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0204302:	85ca                	mv	a1,s2
ffffffffc0204304:	e73ff0ef          	jal	ra,ffffffffc0204176 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0204308:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc020430a:	000a0463          	beqz	s4,ffffffffc0204312 <mm_map+0x7c>
        *vma_store = vma;
ffffffffc020430e:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc0204312:	70e2                	ld	ra,56(sp)
ffffffffc0204314:	7442                	ld	s0,48(sp)
ffffffffc0204316:	74a2                	ld	s1,40(sp)
ffffffffc0204318:	7902                	ld	s2,32(sp)
ffffffffc020431a:	69e2                	ld	s3,24(sp)
ffffffffc020431c:	6a42                	ld	s4,16(sp)
ffffffffc020431e:	6aa2                	ld	s5,8(sp)
ffffffffc0204320:	6121                	addi	sp,sp,64
ffffffffc0204322:	8082                	ret
        return -E_INVAL;
ffffffffc0204324:	5575                	li	a0,-3
ffffffffc0204326:	b7f5                	j	ffffffffc0204312 <mm_map+0x7c>
    assert(mm != NULL);
ffffffffc0204328:	00003697          	auipc	a3,0x3
ffffffffc020432c:	7e868693          	addi	a3,a3,2024 # ffffffffc0207b10 <default_pmm_manager+0x7f8>
ffffffffc0204330:	00003617          	auipc	a2,0x3
ffffffffc0204334:	8a060613          	addi	a2,a2,-1888 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204338:	0b800593          	li	a1,184
ffffffffc020433c:	00004517          	auipc	a0,0x4
ffffffffc0204340:	cec50513          	addi	a0,a0,-788 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc0204344:	940fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204348 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0204348:	7139                	addi	sp,sp,-64
ffffffffc020434a:	fc06                	sd	ra,56(sp)
ffffffffc020434c:	f822                	sd	s0,48(sp)
ffffffffc020434e:	f426                	sd	s1,40(sp)
ffffffffc0204350:	f04a                	sd	s2,32(sp)
ffffffffc0204352:	ec4e                	sd	s3,24(sp)
ffffffffc0204354:	e852                	sd	s4,16(sp)
ffffffffc0204356:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0204358:	c535                	beqz	a0,ffffffffc02043c4 <dup_mmap+0x7c>
ffffffffc020435a:	892a                	mv	s2,a0
ffffffffc020435c:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list),
                 *le = list;
ffffffffc020435e:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0204360:	e59d                	bnez	a1,ffffffffc020438e <dup_mmap+0x46>
ffffffffc0204362:	a08d                	j	ffffffffc02043c4 <dup_mmap+0x7c>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma); //将vma添加到mm中
ffffffffc0204364:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0204366:	0157b423          	sd	s5,8(a5) # 200008 <_binary_obj___user_exit_out_size+0x1f5588>
        insert_vma_struct(to, nvma); //将vma添加到mm中
ffffffffc020436a:	854a                	mv	a0,s2
        vma->vm_end = vm_end;
ffffffffc020436c:	0147b823          	sd	s4,16(a5)
        vma->vm_flags = vm_flags;
ffffffffc0204370:	0137ac23          	sw	s3,24(a5)
        insert_vma_struct(to, nvma); //将vma添加到mm中
ffffffffc0204374:	e03ff0ef          	jal	ra,ffffffffc0204176 <insert_vma_struct>

        // 复制对应vma的内容
        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0204378:	ff043683          	ld	a3,-16(s0)
ffffffffc020437c:	fe843603          	ld	a2,-24(s0)
ffffffffc0204380:	6c8c                	ld	a1,24(s1)
ffffffffc0204382:	01893503          	ld	a0,24(s2)
ffffffffc0204386:	4701                	li	a4,0
ffffffffc0204388:	d2ffe0ef          	jal	ra,ffffffffc02030b6 <copy_range>
ffffffffc020438c:	e105                	bnez	a0,ffffffffc02043ac <dup_mmap+0x64>
    return listelm->prev;
ffffffffc020438e:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0204390:	02848863          	beq	s1,s0,ffffffffc02043c0 <dup_mmap+0x78>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204394:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0204398:	fe843a83          	ld	s5,-24(s0)
ffffffffc020439c:	ff043a03          	ld	s4,-16(s0)
ffffffffc02043a0:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02043a4:	8abfd0ef          	jal	ra,ffffffffc0201c4e <kmalloc>
ffffffffc02043a8:	87aa                	mv	a5,a0
    if (vma != NULL)
ffffffffc02043aa:	fd4d                	bnez	a0,ffffffffc0204364 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc02043ac:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc02043ae:	70e2                	ld	ra,56(sp)
ffffffffc02043b0:	7442                	ld	s0,48(sp)
ffffffffc02043b2:	74a2                	ld	s1,40(sp)
ffffffffc02043b4:	7902                	ld	s2,32(sp)
ffffffffc02043b6:	69e2                	ld	s3,24(sp)
ffffffffc02043b8:	6a42                	ld	s4,16(sp)
ffffffffc02043ba:	6aa2                	ld	s5,8(sp)
ffffffffc02043bc:	6121                	addi	sp,sp,64
ffffffffc02043be:	8082                	ret
    return 0;
ffffffffc02043c0:	4501                	li	a0,0
ffffffffc02043c2:	b7f5                	j	ffffffffc02043ae <dup_mmap+0x66>
    assert(to != NULL && from != NULL);
ffffffffc02043c4:	00004697          	auipc	a3,0x4
ffffffffc02043c8:	d3468693          	addi	a3,a3,-716 # ffffffffc02080f8 <default_pmm_manager+0xde0>
ffffffffc02043cc:	00003617          	auipc	a2,0x3
ffffffffc02043d0:	80460613          	addi	a2,a2,-2044 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02043d4:	0d400593          	li	a1,212
ffffffffc02043d8:	00004517          	auipc	a0,0x4
ffffffffc02043dc:	c5050513          	addi	a0,a0,-944 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc02043e0:	8a4fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02043e4 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc02043e4:	1101                	addi	sp,sp,-32
ffffffffc02043e6:	ec06                	sd	ra,24(sp)
ffffffffc02043e8:	e822                	sd	s0,16(sp)
ffffffffc02043ea:	e426                	sd	s1,8(sp)
ffffffffc02043ec:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02043ee:	c531                	beqz	a0,ffffffffc020443a <exit_mmap+0x56>
ffffffffc02043f0:	591c                	lw	a5,48(a0)
ffffffffc02043f2:	84aa                	mv	s1,a0
ffffffffc02043f4:	e3b9                	bnez	a5,ffffffffc020443a <exit_mmap+0x56>
    return listelm->next;
ffffffffc02043f6:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02043f8:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc02043fc:	02850663          	beq	a0,s0,ffffffffc0204428 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0204400:	ff043603          	ld	a2,-16(s0)
ffffffffc0204404:	fe843583          	ld	a1,-24(s0)
ffffffffc0204408:	854a                	mv	a0,s2
ffffffffc020440a:	d83fd0ef          	jal	ra,ffffffffc020218c <unmap_range>
ffffffffc020440e:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0204410:	fe8498e3          	bne	s1,s0,ffffffffc0204400 <exit_mmap+0x1c>
ffffffffc0204414:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0204416:	00848c63          	beq	s1,s0,ffffffffc020442e <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc020441a:	ff043603          	ld	a2,-16(s0)
ffffffffc020441e:	fe843583          	ld	a1,-24(s0)
ffffffffc0204422:	854a                	mv	a0,s2
ffffffffc0204424:	e81fd0ef          	jal	ra,ffffffffc02022a4 <exit_range>
ffffffffc0204428:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc020442a:	fe8498e3          	bne	s1,s0,ffffffffc020441a <exit_mmap+0x36>
    }
}
ffffffffc020442e:	60e2                	ld	ra,24(sp)
ffffffffc0204430:	6442                	ld	s0,16(sp)
ffffffffc0204432:	64a2                	ld	s1,8(sp)
ffffffffc0204434:	6902                	ld	s2,0(sp)
ffffffffc0204436:	6105                	addi	sp,sp,32
ffffffffc0204438:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc020443a:	00004697          	auipc	a3,0x4
ffffffffc020443e:	cde68693          	addi	a3,a3,-802 # ffffffffc0208118 <default_pmm_manager+0xe00>
ffffffffc0204442:	00002617          	auipc	a2,0x2
ffffffffc0204446:	78e60613          	addi	a2,a2,1934 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020444a:	0f100593          	li	a1,241
ffffffffc020444e:	00004517          	auipc	a0,0x4
ffffffffc0204452:	bda50513          	addi	a0,a0,-1062 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc0204456:	82efc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020445a <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc020445a:	7139                	addi	sp,sp,-64
ffffffffc020445c:	f822                	sd	s0,48(sp)
ffffffffc020445e:	f426                	sd	s1,40(sp)
ffffffffc0204460:	fc06                	sd	ra,56(sp)
ffffffffc0204462:	f04a                	sd	s2,32(sp)
ffffffffc0204464:	ec4e                	sd	s3,24(sp)
ffffffffc0204466:	e852                	sd	s4,16(sp)
ffffffffc0204468:	e456                	sd	s5,8(sp)
static void
check_vma_struct(void)
{
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
ffffffffc020446a:	c55ff0ef          	jal	ra,ffffffffc02040be <mm_create>
    assert(mm != NULL);
ffffffffc020446e:	842a                	mv	s0,a0
ffffffffc0204470:	03200493          	li	s1,50
ffffffffc0204474:	e919                	bnez	a0,ffffffffc020448a <vmm_init+0x30>
ffffffffc0204476:	a989                	j	ffffffffc02048c8 <vmm_init+0x46e>
        vma->vm_start = vm_start;
ffffffffc0204478:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc020447a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020447c:	00052c23          	sw	zero,24(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0204480:	14ed                	addi	s1,s1,-5
ffffffffc0204482:	8522                	mv	a0,s0
ffffffffc0204484:	cf3ff0ef          	jal	ra,ffffffffc0204176 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0204488:	c88d                	beqz	s1,ffffffffc02044ba <vmm_init+0x60>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020448a:	03000513          	li	a0,48
ffffffffc020448e:	fc0fd0ef          	jal	ra,ffffffffc0201c4e <kmalloc>
ffffffffc0204492:	85aa                	mv	a1,a0
ffffffffc0204494:	00248793          	addi	a5,s1,2
    if (vma != NULL)
ffffffffc0204498:	f165                	bnez	a0,ffffffffc0204478 <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc020449a:	00003697          	auipc	a3,0x3
ffffffffc020449e:	6ae68693          	addi	a3,a3,1710 # ffffffffc0207b48 <default_pmm_manager+0x830>
ffffffffc02044a2:	00002617          	auipc	a2,0x2
ffffffffc02044a6:	72e60613          	addi	a2,a2,1838 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02044aa:	13500593          	li	a1,309
ffffffffc02044ae:	00004517          	auipc	a0,0x4
ffffffffc02044b2:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc02044b6:	fcffb0ef          	jal	ra,ffffffffc0200484 <__panic>
    for (i = step1; i >= 1; i--)
ffffffffc02044ba:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc02044be:	1f900913          	li	s2,505
ffffffffc02044c2:	a819                	j	ffffffffc02044d8 <vmm_init+0x7e>
        vma->vm_start = vm_start;
ffffffffc02044c4:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc02044c6:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02044c8:	00052c23          	sw	zero,24(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02044cc:	0495                	addi	s1,s1,5
ffffffffc02044ce:	8522                	mv	a0,s0
ffffffffc02044d0:	ca7ff0ef          	jal	ra,ffffffffc0204176 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02044d4:	03248a63          	beq	s1,s2,ffffffffc0204508 <vmm_init+0xae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02044d8:	03000513          	li	a0,48
ffffffffc02044dc:	f72fd0ef          	jal	ra,ffffffffc0201c4e <kmalloc>
ffffffffc02044e0:	85aa                	mv	a1,a0
ffffffffc02044e2:	00248793          	addi	a5,s1,2
    if (vma != NULL)
ffffffffc02044e6:	fd79                	bnez	a0,ffffffffc02044c4 <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc02044e8:	00003697          	auipc	a3,0x3
ffffffffc02044ec:	66068693          	addi	a3,a3,1632 # ffffffffc0207b48 <default_pmm_manager+0x830>
ffffffffc02044f0:	00002617          	auipc	a2,0x2
ffffffffc02044f4:	6e060613          	addi	a2,a2,1760 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02044f8:	13c00593          	li	a1,316
ffffffffc02044fc:	00004517          	auipc	a0,0x4
ffffffffc0204500:	b2c50513          	addi	a0,a0,-1236 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc0204504:	f81fb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0204508:	6418                	ld	a4,8(s0)
ffffffffc020450a:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc020450c:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0204510:	2ee40063          	beq	s0,a4,ffffffffc02047f0 <vmm_init+0x396>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0204514:	fe873603          	ld	a2,-24(a4)
ffffffffc0204518:	ffe78693          	addi	a3,a5,-2
ffffffffc020451c:	24d61a63          	bne	a2,a3,ffffffffc0204770 <vmm_init+0x316>
ffffffffc0204520:	ff073683          	ld	a3,-16(a4)
ffffffffc0204524:	24f69663          	bne	a3,a5,ffffffffc0204770 <vmm_init+0x316>
ffffffffc0204528:	0795                	addi	a5,a5,5
ffffffffc020452a:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i++)
ffffffffc020452c:	feb792e3          	bne	a5,a1,ffffffffc0204510 <vmm_init+0xb6>
ffffffffc0204530:	491d                	li	s2,7
ffffffffc0204532:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0204534:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0204538:	85a6                	mv	a1,s1
ffffffffc020453a:	8522                	mv	a0,s0
ffffffffc020453c:	bfdff0ef          	jal	ra,ffffffffc0204138 <find_vma>
ffffffffc0204540:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0204542:	30050763          	beqz	a0,ffffffffc0204850 <vmm_init+0x3f6>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0204546:	00148593          	addi	a1,s1,1
ffffffffc020454a:	8522                	mv	a0,s0
ffffffffc020454c:	bedff0ef          	jal	ra,ffffffffc0204138 <find_vma>
ffffffffc0204550:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0204552:	2c050f63          	beqz	a0,ffffffffc0204830 <vmm_init+0x3d6>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0204556:	85ca                	mv	a1,s2
ffffffffc0204558:	8522                	mv	a0,s0
ffffffffc020455a:	bdfff0ef          	jal	ra,ffffffffc0204138 <find_vma>
        assert(vma3 == NULL);
ffffffffc020455e:	2a051963          	bnez	a0,ffffffffc0204810 <vmm_init+0x3b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0204562:	00348593          	addi	a1,s1,3
ffffffffc0204566:	8522                	mv	a0,s0
ffffffffc0204568:	bd1ff0ef          	jal	ra,ffffffffc0204138 <find_vma>
        assert(vma4 == NULL);
ffffffffc020456c:	32051263          	bnez	a0,ffffffffc0204890 <vmm_init+0x436>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0204570:	00448593          	addi	a1,s1,4
ffffffffc0204574:	8522                	mv	a0,s0
ffffffffc0204576:	bc3ff0ef          	jal	ra,ffffffffc0204138 <find_vma>
        assert(vma5 == NULL);
ffffffffc020457a:	2e051b63          	bnez	a0,ffffffffc0204870 <vmm_init+0x416>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc020457e:	008a3783          	ld	a5,8(s4)
ffffffffc0204582:	20979763          	bne	a5,s1,ffffffffc0204790 <vmm_init+0x336>
ffffffffc0204586:	010a3783          	ld	a5,16(s4)
ffffffffc020458a:	21279363          	bne	a5,s2,ffffffffc0204790 <vmm_init+0x336>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc020458e:	0089b783          	ld	a5,8(s3)
ffffffffc0204592:	20979f63          	bne	a5,s1,ffffffffc02047b0 <vmm_init+0x356>
ffffffffc0204596:	0109b783          	ld	a5,16(s3)
ffffffffc020459a:	21279b63          	bne	a5,s2,ffffffffc02047b0 <vmm_init+0x356>
ffffffffc020459e:	0495                	addi	s1,s1,5
ffffffffc02045a0:	0915                	addi	s2,s2,5
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc02045a2:	f9549be3          	bne	s1,s5,ffffffffc0204538 <vmm_init+0xde>
ffffffffc02045a6:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc02045a8:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc02045aa:	85a6                	mv	a1,s1
ffffffffc02045ac:	8522                	mv	a0,s0
ffffffffc02045ae:	b8bff0ef          	jal	ra,ffffffffc0204138 <find_vma>
ffffffffc02045b2:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL)
ffffffffc02045b6:	c90d                	beqz	a0,ffffffffc02045e8 <vmm_init+0x18e>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc02045b8:	6914                	ld	a3,16(a0)
ffffffffc02045ba:	6510                	ld	a2,8(a0)
ffffffffc02045bc:	00004517          	auipc	a0,0x4
ffffffffc02045c0:	cf450513          	addi	a0,a0,-780 # ffffffffc02082b0 <default_pmm_manager+0xf98>
ffffffffc02045c4:	bcbfb0ef          	jal	ra,ffffffffc020018e <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc02045c8:	00004697          	auipc	a3,0x4
ffffffffc02045cc:	d1068693          	addi	a3,a3,-752 # ffffffffc02082d8 <default_pmm_manager+0xfc0>
ffffffffc02045d0:	00002617          	auipc	a2,0x2
ffffffffc02045d4:	60060613          	addi	a2,a2,1536 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02045d8:	16200593          	li	a1,354
ffffffffc02045dc:	00004517          	auipc	a0,0x4
ffffffffc02045e0:	a4c50513          	addi	a0,a0,-1460 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc02045e4:	ea1fb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc02045e8:	14fd                	addi	s1,s1,-1
    for (i = 4; i >= 0; i--)
ffffffffc02045ea:	fd2490e3          	bne	s1,s2,ffffffffc02045aa <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc02045ee:	8522                	mv	a0,s0
ffffffffc02045f0:	c55ff0ef          	jal	ra,ffffffffc0204244 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02045f4:	00004517          	auipc	a0,0x4
ffffffffc02045f8:	cfc50513          	addi	a0,a0,-772 # ffffffffc02082f0 <default_pmm_manager+0xfd8>
ffffffffc02045fc:	b93fb0ef          	jal	ra,ffffffffc020018e <cprintf>

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void)
{
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204600:	919fd0ef          	jal	ra,ffffffffc0201f18 <nr_free_pages>
ffffffffc0204604:	89aa                	mv	s3,a0

    check_mm_struct = mm_create();
ffffffffc0204606:	ab9ff0ef          	jal	ra,ffffffffc02040be <mm_create>
ffffffffc020460a:	000a8797          	auipc	a5,0xa8
ffffffffc020460e:	fca7bf23          	sd	a0,-34(a5) # ffffffffc02ac5e8 <check_mm_struct>
ffffffffc0204612:	84aa                	mv	s1,a0
    assert(check_mm_struct != NULL);
ffffffffc0204614:	36050663          	beqz	a0,ffffffffc0204980 <vmm_init+0x526>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0204618:	000a8797          	auipc	a5,0xa8
ffffffffc020461c:	e7878793          	addi	a5,a5,-392 # ffffffffc02ac490 <boot_pgdir>
ffffffffc0204620:	0007b903          	ld	s2,0(a5)
    assert(pgdir[0] == 0);
ffffffffc0204624:	00093783          	ld	a5,0(s2)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0204628:	01253c23          	sd	s2,24(a0)
    assert(pgdir[0] == 0);
ffffffffc020462c:	2c079e63          	bnez	a5,ffffffffc0204908 <vmm_init+0x4ae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204630:	03000513          	li	a0,48
ffffffffc0204634:	e1afd0ef          	jal	ra,ffffffffc0201c4e <kmalloc>
ffffffffc0204638:	842a                	mv	s0,a0
    if (vma != NULL)
ffffffffc020463a:	18050b63          	beqz	a0,ffffffffc02047d0 <vmm_init+0x376>
        vma->vm_end = vm_end;
ffffffffc020463e:	002007b7          	lui	a5,0x200
ffffffffc0204642:	e81c                	sd	a5,16(s0)
        vma->vm_flags = vm_flags;
ffffffffc0204644:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0204646:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0204648:	cc1c                	sw	a5,24(s0)
    insert_vma_struct(mm, vma);
ffffffffc020464a:	8526                	mv	a0,s1
        vma->vm_start = vm_start;
ffffffffc020464c:	00043423          	sd	zero,8(s0)
    insert_vma_struct(mm, vma);
ffffffffc0204650:	b27ff0ef          	jal	ra,ffffffffc0204176 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0204654:	10000593          	li	a1,256
ffffffffc0204658:	8526                	mv	a0,s1
ffffffffc020465a:	adfff0ef          	jal	ra,ffffffffc0204138 <find_vma>
ffffffffc020465e:	10000793          	li	a5,256

    int i, sum = 0;

    for (i = 0; i < 100; i++)
ffffffffc0204662:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0204666:	2ca41163          	bne	s0,a0,ffffffffc0204928 <vmm_init+0x4ce>
    {
        *(char *)(addr + i) = i;
ffffffffc020466a:	00f78023          	sb	a5,0(a5) # 200000 <_binary_obj___user_exit_out_size+0x1f5580>
        sum += i;
ffffffffc020466e:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i++)
ffffffffc0204670:	fee79de3          	bne	a5,a4,ffffffffc020466a <vmm_init+0x210>
        sum += i;
ffffffffc0204674:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i++)
ffffffffc0204676:	10000793          	li	a5,256
        sum += i;
ffffffffc020467a:	35670713          	addi	a4,a4,854 # 1356 <_binary_obj___user_faultread_out_size-0x822a>
    }
    for (i = 0; i < 100; i++)
ffffffffc020467e:	16400613          	li	a2,356
    {
        sum -= *(char *)(addr + i);
ffffffffc0204682:	0007c683          	lbu	a3,0(a5)
ffffffffc0204686:	0785                	addi	a5,a5,1
ffffffffc0204688:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i++)
ffffffffc020468a:	fec79ce3          	bne	a5,a2,ffffffffc0204682 <vmm_init+0x228>
    }

    assert(sum == 0);
ffffffffc020468e:	2c071963          	bnez	a4,ffffffffc0204960 <vmm_init+0x506>
    return pa2page(PDE_ADDR(pde));
ffffffffc0204692:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0204696:	000a8a97          	auipc	s5,0xa8
ffffffffc020469a:	e02a8a93          	addi	s5,s5,-510 # ffffffffc02ac498 <npage>
ffffffffc020469e:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02046a2:	078a                	slli	a5,a5,0x2
ffffffffc02046a4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02046a6:	20e7f563          	bleu	a4,a5,ffffffffc02048b0 <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc02046aa:	00004697          	auipc	a3,0x4
ffffffffc02046ae:	68668693          	addi	a3,a3,1670 # ffffffffc0208d30 <nbase>
ffffffffc02046b2:	0006ba03          	ld	s4,0(a3)
ffffffffc02046b6:	414786b3          	sub	a3,a5,s4
ffffffffc02046ba:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc02046bc:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02046be:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc02046c0:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc02046c2:	83b1                	srli	a5,a5,0xc
ffffffffc02046c4:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02046c6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02046c8:	28e7f063          	bleu	a4,a5,ffffffffc0204948 <vmm_init+0x4ee>
ffffffffc02046cc:	000a8797          	auipc	a5,0xa8
ffffffffc02046d0:	e2c78793          	addi	a5,a5,-468 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc02046d4:	6380                	ld	s0,0(a5)

    pde_t *pd1 = pgdir, *pd0 = page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc02046d6:	4581                	li	a1,0
ffffffffc02046d8:	854a                	mv	a0,s2
ffffffffc02046da:	9436                	add	s0,s0,a3
ffffffffc02046dc:	e1ffd0ef          	jal	ra,ffffffffc02024fa <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc02046e0:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc02046e2:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02046e6:	078a                	slli	a5,a5,0x2
ffffffffc02046e8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02046ea:	1ce7f363          	bleu	a4,a5,ffffffffc02048b0 <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc02046ee:	000a8417          	auipc	s0,0xa8
ffffffffc02046f2:	e1a40413          	addi	s0,s0,-486 # ffffffffc02ac508 <pages>
ffffffffc02046f6:	6008                	ld	a0,0(s0)
ffffffffc02046f8:	414787b3          	sub	a5,a5,s4
ffffffffc02046fc:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc02046fe:	953e                	add	a0,a0,a5
ffffffffc0204700:	4585                	li	a1,1
ffffffffc0204702:	fd0fd0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0204706:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc020470a:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020470e:	078a                	slli	a5,a5,0x2
ffffffffc0204710:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0204712:	18e7ff63          	bleu	a4,a5,ffffffffc02048b0 <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc0204716:	6008                	ld	a0,0(s0)
ffffffffc0204718:	414787b3          	sub	a5,a5,s4
ffffffffc020471c:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc020471e:	4585                	li	a1,1
ffffffffc0204720:	953e                	add	a0,a0,a5
ffffffffc0204722:	fb0fd0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    pgdir[0] = 0;
ffffffffc0204726:	00093023          	sd	zero,0(s2)
  asm volatile("sfence.vma");
ffffffffc020472a:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
ffffffffc020472e:	0004bc23          	sd	zero,24(s1)
    mm_destroy(mm);
ffffffffc0204732:	8526                	mv	a0,s1
ffffffffc0204734:	b11ff0ef          	jal	ra,ffffffffc0204244 <mm_destroy>
    check_mm_struct = NULL;
ffffffffc0204738:	000a8797          	auipc	a5,0xa8
ffffffffc020473c:	ea07b823          	sd	zero,-336(a5) # ffffffffc02ac5e8 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0204740:	fd8fd0ef          	jal	ra,ffffffffc0201f18 <nr_free_pages>
ffffffffc0204744:	1aa99263          	bne	s3,a0,ffffffffc02048e8 <vmm_init+0x48e>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0204748:	00004517          	auipc	a0,0x4
ffffffffc020474c:	c3850513          	addi	a0,a0,-968 # ffffffffc0208380 <default_pmm_manager+0x1068>
ffffffffc0204750:	a3ffb0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0204754:	7442                	ld	s0,48(sp)
ffffffffc0204756:	70e2                	ld	ra,56(sp)
ffffffffc0204758:	74a2                	ld	s1,40(sp)
ffffffffc020475a:	7902                	ld	s2,32(sp)
ffffffffc020475c:	69e2                	ld	s3,24(sp)
ffffffffc020475e:	6a42                	ld	s4,16(sp)
ffffffffc0204760:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0204762:	00004517          	auipc	a0,0x4
ffffffffc0204766:	c3e50513          	addi	a0,a0,-962 # ffffffffc02083a0 <default_pmm_manager+0x1088>
}
ffffffffc020476a:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc020476c:	a23fb06f          	j	ffffffffc020018e <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0204770:	00004697          	auipc	a3,0x4
ffffffffc0204774:	a5868693          	addi	a3,a3,-1448 # ffffffffc02081c8 <default_pmm_manager+0xeb0>
ffffffffc0204778:	00002617          	auipc	a2,0x2
ffffffffc020477c:	45860613          	addi	a2,a2,1112 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204780:	14600593          	li	a1,326
ffffffffc0204784:	00004517          	auipc	a0,0x4
ffffffffc0204788:	8a450513          	addi	a0,a0,-1884 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc020478c:	cf9fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0204790:	00004697          	auipc	a3,0x4
ffffffffc0204794:	ac068693          	addi	a3,a3,-1344 # ffffffffc0208250 <default_pmm_manager+0xf38>
ffffffffc0204798:	00002617          	auipc	a2,0x2
ffffffffc020479c:	43860613          	addi	a2,a2,1080 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02047a0:	15700593          	li	a1,343
ffffffffc02047a4:	00004517          	auipc	a0,0x4
ffffffffc02047a8:	88450513          	addi	a0,a0,-1916 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc02047ac:	cd9fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc02047b0:	00004697          	auipc	a3,0x4
ffffffffc02047b4:	ad068693          	addi	a3,a3,-1328 # ffffffffc0208280 <default_pmm_manager+0xf68>
ffffffffc02047b8:	00002617          	auipc	a2,0x2
ffffffffc02047bc:	41860613          	addi	a2,a2,1048 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02047c0:	15800593          	li	a1,344
ffffffffc02047c4:	00004517          	auipc	a0,0x4
ffffffffc02047c8:	86450513          	addi	a0,a0,-1948 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc02047cc:	cb9fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(vma != NULL);
ffffffffc02047d0:	00003697          	auipc	a3,0x3
ffffffffc02047d4:	37868693          	addi	a3,a3,888 # ffffffffc0207b48 <default_pmm_manager+0x830>
ffffffffc02047d8:	00002617          	auipc	a2,0x2
ffffffffc02047dc:	3f860613          	addi	a2,a2,1016 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02047e0:	17a00593          	li	a1,378
ffffffffc02047e4:	00004517          	auipc	a0,0x4
ffffffffc02047e8:	84450513          	addi	a0,a0,-1980 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc02047ec:	c99fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02047f0:	00004697          	auipc	a3,0x4
ffffffffc02047f4:	9c068693          	addi	a3,a3,-1600 # ffffffffc02081b0 <default_pmm_manager+0xe98>
ffffffffc02047f8:	00002617          	auipc	a2,0x2
ffffffffc02047fc:	3d860613          	addi	a2,a2,984 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204800:	14400593          	li	a1,324
ffffffffc0204804:	00004517          	auipc	a0,0x4
ffffffffc0204808:	82450513          	addi	a0,a0,-2012 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc020480c:	c79fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma3 == NULL);
ffffffffc0204810:	00004697          	auipc	a3,0x4
ffffffffc0204814:	a1068693          	addi	a3,a3,-1520 # ffffffffc0208220 <default_pmm_manager+0xf08>
ffffffffc0204818:	00002617          	auipc	a2,0x2
ffffffffc020481c:	3b860613          	addi	a2,a2,952 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204820:	15100593          	li	a1,337
ffffffffc0204824:	00004517          	auipc	a0,0x4
ffffffffc0204828:	80450513          	addi	a0,a0,-2044 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc020482c:	c59fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma2 != NULL);
ffffffffc0204830:	00004697          	auipc	a3,0x4
ffffffffc0204834:	9e068693          	addi	a3,a3,-1568 # ffffffffc0208210 <default_pmm_manager+0xef8>
ffffffffc0204838:	00002617          	auipc	a2,0x2
ffffffffc020483c:	39860613          	addi	a2,a2,920 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204840:	14f00593          	li	a1,335
ffffffffc0204844:	00003517          	auipc	a0,0x3
ffffffffc0204848:	7e450513          	addi	a0,a0,2020 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc020484c:	c39fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma1 != NULL);
ffffffffc0204850:	00004697          	auipc	a3,0x4
ffffffffc0204854:	9b068693          	addi	a3,a3,-1616 # ffffffffc0208200 <default_pmm_manager+0xee8>
ffffffffc0204858:	00002617          	auipc	a2,0x2
ffffffffc020485c:	37860613          	addi	a2,a2,888 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204860:	14d00593          	li	a1,333
ffffffffc0204864:	00003517          	auipc	a0,0x3
ffffffffc0204868:	7c450513          	addi	a0,a0,1988 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc020486c:	c19fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma5 == NULL);
ffffffffc0204870:	00004697          	auipc	a3,0x4
ffffffffc0204874:	9d068693          	addi	a3,a3,-1584 # ffffffffc0208240 <default_pmm_manager+0xf28>
ffffffffc0204878:	00002617          	auipc	a2,0x2
ffffffffc020487c:	35860613          	addi	a2,a2,856 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204880:	15500593          	li	a1,341
ffffffffc0204884:	00003517          	auipc	a0,0x3
ffffffffc0204888:	7a450513          	addi	a0,a0,1956 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc020488c:	bf9fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma4 == NULL);
ffffffffc0204890:	00004697          	auipc	a3,0x4
ffffffffc0204894:	9a068693          	addi	a3,a3,-1632 # ffffffffc0208230 <default_pmm_manager+0xf18>
ffffffffc0204898:	00002617          	auipc	a2,0x2
ffffffffc020489c:	33860613          	addi	a2,a2,824 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02048a0:	15300593          	li	a1,339
ffffffffc02048a4:	00003517          	auipc	a0,0x3
ffffffffc02048a8:	78450513          	addi	a0,a0,1924 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc02048ac:	bd9fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02048b0:	00003617          	auipc	a2,0x3
ffffffffc02048b4:	b1860613          	addi	a2,a2,-1256 # ffffffffc02073c8 <default_pmm_manager+0xb0>
ffffffffc02048b8:	06200593          	li	a1,98
ffffffffc02048bc:	00003517          	auipc	a0,0x3
ffffffffc02048c0:	ad450513          	addi	a0,a0,-1324 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc02048c4:	bc1fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(mm != NULL);
ffffffffc02048c8:	00003697          	auipc	a3,0x3
ffffffffc02048cc:	24868693          	addi	a3,a3,584 # ffffffffc0207b10 <default_pmm_manager+0x7f8>
ffffffffc02048d0:	00002617          	auipc	a2,0x2
ffffffffc02048d4:	30060613          	addi	a2,a2,768 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02048d8:	12d00593          	li	a1,301
ffffffffc02048dc:	00003517          	auipc	a0,0x3
ffffffffc02048e0:	74c50513          	addi	a0,a0,1868 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc02048e4:	ba1fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02048e8:	00004697          	auipc	a3,0x4
ffffffffc02048ec:	a7068693          	addi	a3,a3,-1424 # ffffffffc0208358 <default_pmm_manager+0x1040>
ffffffffc02048f0:	00002617          	auipc	a2,0x2
ffffffffc02048f4:	2e060613          	addi	a2,a2,736 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02048f8:	19a00593          	li	a1,410
ffffffffc02048fc:	00003517          	auipc	a0,0x3
ffffffffc0204900:	72c50513          	addi	a0,a0,1836 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc0204904:	b81fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0204908:	00003697          	auipc	a3,0x3
ffffffffc020490c:	23068693          	addi	a3,a3,560 # ffffffffc0207b38 <default_pmm_manager+0x820>
ffffffffc0204910:	00002617          	auipc	a2,0x2
ffffffffc0204914:	2c060613          	addi	a2,a2,704 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204918:	17700593          	li	a1,375
ffffffffc020491c:	00003517          	auipc	a0,0x3
ffffffffc0204920:	70c50513          	addi	a0,a0,1804 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc0204924:	b61fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0204928:	00004697          	auipc	a3,0x4
ffffffffc020492c:	a0068693          	addi	a3,a3,-1536 # ffffffffc0208328 <default_pmm_manager+0x1010>
ffffffffc0204930:	00002617          	auipc	a2,0x2
ffffffffc0204934:	2a060613          	addi	a2,a2,672 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204938:	17f00593          	li	a1,383
ffffffffc020493c:	00003517          	auipc	a0,0x3
ffffffffc0204940:	6ec50513          	addi	a0,a0,1772 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc0204944:	b41fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc0204948:	00003617          	auipc	a2,0x3
ffffffffc020494c:	a2060613          	addi	a2,a2,-1504 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc0204950:	06900593          	li	a1,105
ffffffffc0204954:	00003517          	auipc	a0,0x3
ffffffffc0204958:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc020495c:	b29fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(sum == 0);
ffffffffc0204960:	00004697          	auipc	a3,0x4
ffffffffc0204964:	9e868693          	addi	a3,a3,-1560 # ffffffffc0208348 <default_pmm_manager+0x1030>
ffffffffc0204968:	00002617          	auipc	a2,0x2
ffffffffc020496c:	26860613          	addi	a2,a2,616 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204970:	18d00593          	li	a1,397
ffffffffc0204974:	00003517          	auipc	a0,0x3
ffffffffc0204978:	6b450513          	addi	a0,a0,1716 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc020497c:	b09fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0204980:	00004697          	auipc	a3,0x4
ffffffffc0204984:	99068693          	addi	a3,a3,-1648 # ffffffffc0208310 <default_pmm_manager+0xff8>
ffffffffc0204988:	00002617          	auipc	a2,0x2
ffffffffc020498c:	24860613          	addi	a2,a2,584 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0204990:	17300593          	li	a1,371
ffffffffc0204994:	00003517          	auipc	a0,0x3
ffffffffc0204998:	69450513          	addi	a0,a0,1684 # ffffffffc0208028 <default_pmm_manager+0xd10>
ffffffffc020499c:	ae9fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02049a0 <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr)
{
ffffffffc02049a0:	7139                	addi	sp,sp,-64
    int ret = -E_INVAL;
    // try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02049a2:	85b2                	mv	a1,a2
{
ffffffffc02049a4:	f822                	sd	s0,48(sp)
ffffffffc02049a6:	f426                	sd	s1,40(sp)
ffffffffc02049a8:	fc06                	sd	ra,56(sp)
ffffffffc02049aa:	f04a                	sd	s2,32(sp)
ffffffffc02049ac:	ec4e                	sd	s3,24(sp)
ffffffffc02049ae:	8432                	mv	s0,a2
ffffffffc02049b0:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02049b2:	f86ff0ef          	jal	ra,ffffffffc0204138 <find_vma>

    pgfault_num++;
ffffffffc02049b6:	000a8797          	auipc	a5,0xa8
ffffffffc02049ba:	af678793          	addi	a5,a5,-1290 # ffffffffc02ac4ac <pgfault_num>
ffffffffc02049be:	439c                	lw	a5,0(a5)
ffffffffc02049c0:	2785                	addiw	a5,a5,1
ffffffffc02049c2:	000a8717          	auipc	a4,0xa8
ffffffffc02049c6:	aef72523          	sw	a5,-1302(a4) # ffffffffc02ac4ac <pgfault_num>
    // If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr)
ffffffffc02049ca:	c555                	beqz	a0,ffffffffc0204a76 <do_pgfault+0xd6>
ffffffffc02049cc:	651c                	ld	a5,8(a0)
ffffffffc02049ce:	0af46463          	bltu	s0,a5,ffffffffc0204a76 <do_pgfault+0xd6>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE)
ffffffffc02049d2:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc02049d4:	49c1                	li	s3,16
    if (vma->vm_flags & VM_WRITE)
ffffffffc02049d6:	8b89                	andi	a5,a5,2
ffffffffc02049d8:	e3a5                	bnez	a5,ffffffffc0204a38 <do_pgfault+0x98>
    {
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02049da:	767d                	lui	a2,0xfffff

    pte_t *ptep = NULL;

    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL)
ffffffffc02049dc:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02049de:	8c71                	and	s0,s0,a2
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL)
ffffffffc02049e0:	85a2                	mv	a1,s0
ffffffffc02049e2:	4605                	li	a2,1
ffffffffc02049e4:	d74fd0ef          	jal	ra,ffffffffc0201f58 <get_pte>
ffffffffc02049e8:	c945                	beqz	a0,ffffffffc0204a98 <do_pgfault+0xf8>
    {
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }

    if (*ptep == 0)
ffffffffc02049ea:	610c                	ld	a1,0(a0)
ffffffffc02049ec:	c5b5                	beqz	a1,ffffffffc0204a58 <do_pgfault+0xb8>
         *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
         *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
         *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
         *    swap_map_swappable ： 设置页面可交换
         */
        if (swap_init_ok)
ffffffffc02049ee:	000a8797          	auipc	a5,0xa8
ffffffffc02049f2:	aba78793          	addi	a5,a5,-1350 # ffffffffc02ac4a8 <swap_init_ok>
ffffffffc02049f6:	439c                	lw	a5,0(a5)
ffffffffc02049f8:	2781                	sext.w	a5,a5
ffffffffc02049fa:	c7d9                	beqz	a5,ffffffffc0204a88 <do_pgfault+0xe8>
            //(2) According to the mm,
            // addr AND page, setup the
            // map of phy addr <--->
            // logical addr
            //(3) make the page swappable.
            if ((ret = swap_in(mm, addr, &page)) != 0)
ffffffffc02049fc:	0030                	addi	a2,sp,8
ffffffffc02049fe:	85a2                	mv	a1,s0
ffffffffc0204a00:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc0204a02:	e402                	sd	zero,8(sp)
            if ((ret = swap_in(mm, addr, &page)) != 0)
ffffffffc0204a04:	a34ff0ef          	jal	ra,ffffffffc0203c38 <swap_in>
ffffffffc0204a08:	892a                	mv	s2,a0
ffffffffc0204a0a:	e90d                	bnez	a0,ffffffffc0204a3c <do_pgfault+0x9c>
            {
                cprintf("swap_in in do_pgfault failed\n");
                goto failed;
            }
            page_insert(mm->pgdir, page, addr, perm); // 更新页表，插入新的页表项
ffffffffc0204a0c:	65a2                	ld	a1,8(sp)
ffffffffc0204a0e:	6c88                	ld	a0,24(s1)
ffffffffc0204a10:	86ce                	mv	a3,s3
ffffffffc0204a12:	8622                	mv	a2,s0
ffffffffc0204a14:	b5bfd0ef          	jal	ra,ffffffffc020256e <page_insert>
            swap_map_swappable(mm, addr, page, 1);    // 标记这个页面将来是可以再换出的
ffffffffc0204a18:	6622                	ld	a2,8(sp)
ffffffffc0204a1a:	4685                	li	a3,1
ffffffffc0204a1c:	85a2                	mv	a1,s0
ffffffffc0204a1e:	8526                	mv	a0,s1
ffffffffc0204a20:	8f4ff0ef          	jal	ra,ffffffffc0203b14 <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc0204a24:	67a2                	ld	a5,8(sp)
ffffffffc0204a26:	ff80                	sd	s0,56(a5)
    }

    ret = 0;
failed:
    return ret;
}
ffffffffc0204a28:	70e2                	ld	ra,56(sp)
ffffffffc0204a2a:	7442                	ld	s0,48(sp)
ffffffffc0204a2c:	854a                	mv	a0,s2
ffffffffc0204a2e:	74a2                	ld	s1,40(sp)
ffffffffc0204a30:	7902                	ld	s2,32(sp)
ffffffffc0204a32:	69e2                	ld	s3,24(sp)
ffffffffc0204a34:	6121                	addi	sp,sp,64
ffffffffc0204a36:	8082                	ret
        perm |= READ_WRITE;
ffffffffc0204a38:	49dd                	li	s3,23
ffffffffc0204a3a:	b745                	j	ffffffffc02049da <do_pgfault+0x3a>
                cprintf("swap_in in do_pgfault failed\n");
ffffffffc0204a3c:	00003517          	auipc	a0,0x3
ffffffffc0204a40:	67450513          	addi	a0,a0,1652 # ffffffffc02080b0 <default_pmm_manager+0xd98>
ffffffffc0204a44:	f4afb0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0204a48:	70e2                	ld	ra,56(sp)
ffffffffc0204a4a:	7442                	ld	s0,48(sp)
ffffffffc0204a4c:	854a                	mv	a0,s2
ffffffffc0204a4e:	74a2                	ld	s1,40(sp)
ffffffffc0204a50:	7902                	ld	s2,32(sp)
ffffffffc0204a52:	69e2                	ld	s3,24(sp)
ffffffffc0204a54:	6121                	addi	sp,sp,64
ffffffffc0204a56:	8082                	ret
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
ffffffffc0204a58:	6c88                	ld	a0,24(s1)
ffffffffc0204a5a:	864e                	mv	a2,s3
ffffffffc0204a5c:	85a2                	mv	a1,s0
ffffffffc0204a5e:	893fe0ef          	jal	ra,ffffffffc02032f0 <pgdir_alloc_page>
    ret = 0;
ffffffffc0204a62:	4901                	li	s2,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
ffffffffc0204a64:	f171                	bnez	a0,ffffffffc0204a28 <do_pgfault+0x88>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0204a66:	00003517          	auipc	a0,0x3
ffffffffc0204a6a:	62250513          	addi	a0,a0,1570 # ffffffffc0208088 <default_pmm_manager+0xd70>
ffffffffc0204a6e:	f20fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204a72:	5971                	li	s2,-4
            goto failed;
ffffffffc0204a74:	bf55                	j	ffffffffc0204a28 <do_pgfault+0x88>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0204a76:	85a2                	mv	a1,s0
ffffffffc0204a78:	00003517          	auipc	a0,0x3
ffffffffc0204a7c:	5c050513          	addi	a0,a0,1472 # ffffffffc0208038 <default_pmm_manager+0xd20>
ffffffffc0204a80:	f0efb0ef          	jal	ra,ffffffffc020018e <cprintf>
    int ret = -E_INVAL;
ffffffffc0204a84:	5975                	li	s2,-3
        goto failed;
ffffffffc0204a86:	b74d                	j	ffffffffc0204a28 <do_pgfault+0x88>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0204a88:	00003517          	auipc	a0,0x3
ffffffffc0204a8c:	64850513          	addi	a0,a0,1608 # ffffffffc02080d0 <default_pmm_manager+0xdb8>
ffffffffc0204a90:	efefb0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204a94:	5971                	li	s2,-4
            goto failed;
ffffffffc0204a96:	bf49                	j	ffffffffc0204a28 <do_pgfault+0x88>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc0204a98:	00003517          	auipc	a0,0x3
ffffffffc0204a9c:	5d050513          	addi	a0,a0,1488 # ffffffffc0208068 <default_pmm_manager+0xd50>
ffffffffc0204aa0:	eeefb0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204aa4:	5971                	li	s2,-4
        goto failed;
ffffffffc0204aa6:	b749                	j	ffffffffc0204a28 <do_pgfault+0x88>

ffffffffc0204aa8 <user_mem_check>:

bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0204aa8:	7179                	addi	sp,sp,-48
ffffffffc0204aaa:	f022                	sd	s0,32(sp)
ffffffffc0204aac:	f406                	sd	ra,40(sp)
ffffffffc0204aae:	ec26                	sd	s1,24(sp)
ffffffffc0204ab0:	e84a                	sd	s2,16(sp)
ffffffffc0204ab2:	e44e                	sd	s3,8(sp)
ffffffffc0204ab4:	e052                	sd	s4,0(sp)
ffffffffc0204ab6:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0204ab8:	c135                	beqz	a0,ffffffffc0204b1c <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0204aba:	002007b7          	lui	a5,0x200
ffffffffc0204abe:	04f5e663          	bltu	a1,a5,ffffffffc0204b0a <user_mem_check+0x62>
ffffffffc0204ac2:	00c584b3          	add	s1,a1,a2
ffffffffc0204ac6:	0495f263          	bleu	s1,a1,ffffffffc0204b0a <user_mem_check+0x62>
ffffffffc0204aca:	4785                	li	a5,1
ffffffffc0204acc:	07fe                	slli	a5,a5,0x1f
ffffffffc0204ace:	0297ee63          	bltu	a5,s1,ffffffffc0204b0a <user_mem_check+0x62>
ffffffffc0204ad2:	892a                	mv	s2,a0
ffffffffc0204ad4:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0204ad6:	6a05                	lui	s4,0x1
ffffffffc0204ad8:	a821                	j	ffffffffc0204af0 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0204ada:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0204ade:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0204ae0:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0204ae2:	c685                	beqz	a3,ffffffffc0204b0a <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0204ae4:	c399                	beqz	a5,ffffffffc0204aea <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0204ae6:	02e46263          	bltu	s0,a4,ffffffffc0204b0a <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0204aea:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0204aec:	04947663          	bleu	s1,s0,ffffffffc0204b38 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0204af0:	85a2                	mv	a1,s0
ffffffffc0204af2:	854a                	mv	a0,s2
ffffffffc0204af4:	e44ff0ef          	jal	ra,ffffffffc0204138 <find_vma>
ffffffffc0204af8:	c909                	beqz	a0,ffffffffc0204b0a <user_mem_check+0x62>
ffffffffc0204afa:	6518                	ld	a4,8(a0)
ffffffffc0204afc:	00e46763          	bltu	s0,a4,ffffffffc0204b0a <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0204b00:	4d1c                	lw	a5,24(a0)
ffffffffc0204b02:	fc099ce3          	bnez	s3,ffffffffc0204ada <user_mem_check+0x32>
ffffffffc0204b06:	8b85                	andi	a5,a5,1
ffffffffc0204b08:	f3ed                	bnez	a5,ffffffffc0204aea <user_mem_check+0x42>
            return 0;
ffffffffc0204b0a:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0204b0c:	70a2                	ld	ra,40(sp)
ffffffffc0204b0e:	7402                	ld	s0,32(sp)
ffffffffc0204b10:	64e2                	ld	s1,24(sp)
ffffffffc0204b12:	6942                	ld	s2,16(sp)
ffffffffc0204b14:	69a2                	ld	s3,8(sp)
ffffffffc0204b16:	6a02                	ld	s4,0(sp)
ffffffffc0204b18:	6145                	addi	sp,sp,48
ffffffffc0204b1a:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204b1c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b20:	4501                	li	a0,0
ffffffffc0204b22:	fef5e5e3          	bltu	a1,a5,ffffffffc0204b0c <user_mem_check+0x64>
ffffffffc0204b26:	962e                	add	a2,a2,a1
ffffffffc0204b28:	fec5f2e3          	bleu	a2,a1,ffffffffc0204b0c <user_mem_check+0x64>
ffffffffc0204b2c:	c8000537          	lui	a0,0xc8000
ffffffffc0204b30:	0505                	addi	a0,a0,1
ffffffffc0204b32:	00a63533          	sltu	a0,a2,a0
ffffffffc0204b36:	bfd9                	j	ffffffffc0204b0c <user_mem_check+0x64>
        return 1;
ffffffffc0204b38:	4505                	li	a0,1
ffffffffc0204b3a:	bfc9                	j	ffffffffc0204b0c <user_mem_check+0x64>

ffffffffc0204b3c <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204b3c:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204b3e:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204b40:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204b42:	abdfb0ef          	jal	ra,ffffffffc02005fe <ide_device_valid>
ffffffffc0204b46:	cd01                	beqz	a0,ffffffffc0204b5e <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204b48:	4505                	li	a0,1
ffffffffc0204b4a:	abbfb0ef          	jal	ra,ffffffffc0200604 <ide_device_size>
}
ffffffffc0204b4e:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204b50:	810d                	srli	a0,a0,0x3
ffffffffc0204b52:	000a8797          	auipc	a5,0xa8
ffffffffc0204b56:	a4a7b323          	sd	a0,-1466(a5) # ffffffffc02ac598 <max_swap_offset>
}
ffffffffc0204b5a:	0141                	addi	sp,sp,16
ffffffffc0204b5c:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204b5e:	00004617          	auipc	a2,0x4
ffffffffc0204b62:	85a60613          	addi	a2,a2,-1958 # ffffffffc02083b8 <default_pmm_manager+0x10a0>
ffffffffc0204b66:	45b5                	li	a1,13
ffffffffc0204b68:	00004517          	auipc	a0,0x4
ffffffffc0204b6c:	87050513          	addi	a0,a0,-1936 # ffffffffc02083d8 <default_pmm_manager+0x10c0>
ffffffffc0204b70:	915fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204b74 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204b74:	1141                	addi	sp,sp,-16
ffffffffc0204b76:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204b78:	00855793          	srli	a5,a0,0x8
ffffffffc0204b7c:	cfb9                	beqz	a5,ffffffffc0204bda <swapfs_read+0x66>
ffffffffc0204b7e:	000a8717          	auipc	a4,0xa8
ffffffffc0204b82:	a1a70713          	addi	a4,a4,-1510 # ffffffffc02ac598 <max_swap_offset>
ffffffffc0204b86:	6318                	ld	a4,0(a4)
ffffffffc0204b88:	04e7f963          	bleu	a4,a5,ffffffffc0204bda <swapfs_read+0x66>
    return page - pages + nbase;
ffffffffc0204b8c:	000a8717          	auipc	a4,0xa8
ffffffffc0204b90:	97c70713          	addi	a4,a4,-1668 # ffffffffc02ac508 <pages>
ffffffffc0204b94:	6310                	ld	a2,0(a4)
ffffffffc0204b96:	00004717          	auipc	a4,0x4
ffffffffc0204b9a:	19a70713          	addi	a4,a4,410 # ffffffffc0208d30 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204b9e:	000a8697          	auipc	a3,0xa8
ffffffffc0204ba2:	8fa68693          	addi	a3,a3,-1798 # ffffffffc02ac498 <npage>
    return page - pages + nbase;
ffffffffc0204ba6:	40c58633          	sub	a2,a1,a2
ffffffffc0204baa:	630c                	ld	a1,0(a4)
ffffffffc0204bac:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc0204bae:	577d                	li	a4,-1
ffffffffc0204bb0:	6294                	ld	a3,0(a3)
    return page - pages + nbase;
ffffffffc0204bb2:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc0204bb4:	8331                	srli	a4,a4,0xc
ffffffffc0204bb6:	8f71                	and	a4,a4,a2
ffffffffc0204bb8:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204bbc:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204bbe:	02d77a63          	bleu	a3,a4,ffffffffc0204bf2 <swapfs_read+0x7e>
ffffffffc0204bc2:	000a8797          	auipc	a5,0xa8
ffffffffc0204bc6:	93678793          	addi	a5,a5,-1738 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc0204bca:	639c                	ld	a5,0(a5)
}
ffffffffc0204bcc:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204bce:	46a1                	li	a3,8
ffffffffc0204bd0:	963e                	add	a2,a2,a5
ffffffffc0204bd2:	4505                	li	a0,1
}
ffffffffc0204bd4:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204bd6:	a35fb06f          	j	ffffffffc020060a <ide_read_secs>
ffffffffc0204bda:	86aa                	mv	a3,a0
ffffffffc0204bdc:	00004617          	auipc	a2,0x4
ffffffffc0204be0:	81460613          	addi	a2,a2,-2028 # ffffffffc02083f0 <default_pmm_manager+0x10d8>
ffffffffc0204be4:	45d1                	li	a1,20
ffffffffc0204be6:	00003517          	auipc	a0,0x3
ffffffffc0204bea:	7f250513          	addi	a0,a0,2034 # ffffffffc02083d8 <default_pmm_manager+0x10c0>
ffffffffc0204bee:	897fb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0204bf2:	86b2                	mv	a3,a2
ffffffffc0204bf4:	06900593          	li	a1,105
ffffffffc0204bf8:	00002617          	auipc	a2,0x2
ffffffffc0204bfc:	77060613          	addi	a2,a2,1904 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc0204c00:	00002517          	auipc	a0,0x2
ffffffffc0204c04:	79050513          	addi	a0,a0,1936 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0204c08:	87dfb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204c0c <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204c0c:	1141                	addi	sp,sp,-16
ffffffffc0204c0e:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c10:	00855793          	srli	a5,a0,0x8
ffffffffc0204c14:	cfb9                	beqz	a5,ffffffffc0204c72 <swapfs_write+0x66>
ffffffffc0204c16:	000a8717          	auipc	a4,0xa8
ffffffffc0204c1a:	98270713          	addi	a4,a4,-1662 # ffffffffc02ac598 <max_swap_offset>
ffffffffc0204c1e:	6318                	ld	a4,0(a4)
ffffffffc0204c20:	04e7f963          	bleu	a4,a5,ffffffffc0204c72 <swapfs_write+0x66>
    return page - pages + nbase;
ffffffffc0204c24:	000a8717          	auipc	a4,0xa8
ffffffffc0204c28:	8e470713          	addi	a4,a4,-1820 # ffffffffc02ac508 <pages>
ffffffffc0204c2c:	6310                	ld	a2,0(a4)
ffffffffc0204c2e:	00004717          	auipc	a4,0x4
ffffffffc0204c32:	10270713          	addi	a4,a4,258 # ffffffffc0208d30 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204c36:	000a8697          	auipc	a3,0xa8
ffffffffc0204c3a:	86268693          	addi	a3,a3,-1950 # ffffffffc02ac498 <npage>
    return page - pages + nbase;
ffffffffc0204c3e:	40c58633          	sub	a2,a1,a2
ffffffffc0204c42:	630c                	ld	a1,0(a4)
ffffffffc0204c44:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc0204c46:	577d                	li	a4,-1
ffffffffc0204c48:	6294                	ld	a3,0(a3)
    return page - pages + nbase;
ffffffffc0204c4a:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc0204c4c:	8331                	srli	a4,a4,0xc
ffffffffc0204c4e:	8f71                	and	a4,a4,a2
ffffffffc0204c50:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c54:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204c56:	02d77a63          	bleu	a3,a4,ffffffffc0204c8a <swapfs_write+0x7e>
ffffffffc0204c5a:	000a8797          	auipc	a5,0xa8
ffffffffc0204c5e:	89e78793          	addi	a5,a5,-1890 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc0204c62:	639c                	ld	a5,0(a5)
}
ffffffffc0204c64:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c66:	46a1                	li	a3,8
ffffffffc0204c68:	963e                	add	a2,a2,a5
ffffffffc0204c6a:	4505                	li	a0,1
}
ffffffffc0204c6c:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c6e:	9c1fb06f          	j	ffffffffc020062e <ide_write_secs>
ffffffffc0204c72:	86aa                	mv	a3,a0
ffffffffc0204c74:	00003617          	auipc	a2,0x3
ffffffffc0204c78:	77c60613          	addi	a2,a2,1916 # ffffffffc02083f0 <default_pmm_manager+0x10d8>
ffffffffc0204c7c:	45e5                	li	a1,25
ffffffffc0204c7e:	00003517          	auipc	a0,0x3
ffffffffc0204c82:	75a50513          	addi	a0,a0,1882 # ffffffffc02083d8 <default_pmm_manager+0x10c0>
ffffffffc0204c86:	ffefb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0204c8a:	86b2                	mv	a3,a2
ffffffffc0204c8c:	06900593          	li	a1,105
ffffffffc0204c90:	00002617          	auipc	a2,0x2
ffffffffc0204c94:	6d860613          	addi	a2,a2,1752 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc0204c98:	00002517          	auipc	a0,0x2
ffffffffc0204c9c:	6f850513          	addi	a0,a0,1784 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0204ca0:	fe4fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204ca4 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204ca4:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204ca6:	9402                	jalr	s0

	jal do_exit
ffffffffc0204ca8:	6f6000ef          	jal	ra,ffffffffc020539e <do_exit>

ffffffffc0204cac <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0204cac:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204cae:	10800513          	li	a0,264
{
ffffffffc0204cb2:	e022                	sd	s0,0(sp)
ffffffffc0204cb4:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204cb6:	f99fc0ef          	jal	ra,ffffffffc0201c4e <kmalloc>
ffffffffc0204cba:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0204cbc:	cd19                	beqz	a0,ffffffffc0204cda <alloc_proc+0x2e>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        memset(proc, 0, sizeof(struct proc_struct)); // 结构体中的大多数成员变量在初始化时置 0 即可
ffffffffc0204cbe:	10800613          	li	a2,264
ffffffffc0204cc2:	4581                	li	a1,0
ffffffffc0204cc4:	105010ef          	jal	ra,ffffffffc02065c8 <memset>
        proc->state = PROC_UNINIT;                   // 设置进程为“初始”态,进程状态设置为 PROC_UNINIT(其实这个值本来就是 0，这句不写也行)
ffffffffc0204cc8:	57fd                	li	a5,-1
ffffffffc0204cca:	1782                	slli	a5,a5,0x20
ffffffffc0204ccc:	e01c                	sd	a5,0(s0)
        proc->pid = -1;                              // 设置进程pid的未初始化值,pid 赋值为 -1，表示进程尚不存在
        proc->cr3 = boot_cr3;                        // 内核态进程的公用页目录表,使用内核页目录表的基址
ffffffffc0204cce:	000a8797          	auipc	a5,0xa8
ffffffffc0204cd2:	83278793          	addi	a5,a5,-1998 # ffffffffc02ac500 <boot_cr3>
ffffffffc0204cd6:	639c                	ld	a5,0(a5)
ffffffffc0204cd8:	f45c                	sd	a5,168(s0)
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        // wait_state = 0; *cptr, *yptr, *optr = NULL;
    }
    return proc;
}
ffffffffc0204cda:	8522                	mv	a0,s0
ffffffffc0204cdc:	60a2                	ld	ra,8(sp)
ffffffffc0204cde:	6402                	ld	s0,0(sp)
ffffffffc0204ce0:	0141                	addi	sp,sp,16
ffffffffc0204ce2:	8082                	ret

ffffffffc0204ce4 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0204ce4:	000a7797          	auipc	a5,0xa7
ffffffffc0204ce8:	7cc78793          	addi	a5,a5,1996 # ffffffffc02ac4b0 <current>
ffffffffc0204cec:	639c                	ld	a5,0(a5)
ffffffffc0204cee:	73c8                	ld	a0,160(a5)
ffffffffc0204cf0:	8b2fc06f          	j	ffffffffc0200da2 <forkrets>

ffffffffc0204cf4 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204cf4:	000a7797          	auipc	a5,0xa7
ffffffffc0204cf8:	7bc78793          	addi	a5,a5,1980 # ffffffffc02ac4b0 <current>
ffffffffc0204cfc:	639c                	ld	a5,0(a5)
{
ffffffffc0204cfe:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204d00:	00004617          	auipc	a2,0x4
ffffffffc0204d04:	b0060613          	addi	a2,a2,-1280 # ffffffffc0208800 <default_pmm_manager+0x14e8>
ffffffffc0204d08:	43cc                	lw	a1,4(a5)
ffffffffc0204d0a:	00004517          	auipc	a0,0x4
ffffffffc0204d0e:	b0650513          	addi	a0,a0,-1274 # ffffffffc0208810 <default_pmm_manager+0x14f8>
{
ffffffffc0204d12:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204d14:	c7afb0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc0204d18:	00004797          	auipc	a5,0x4
ffffffffc0204d1c:	ae878793          	addi	a5,a5,-1304 # ffffffffc0208800 <default_pmm_manager+0x14e8>
ffffffffc0204d20:	3fe05717          	auipc	a4,0x3fe05
ffffffffc0204d24:	5c070713          	addi	a4,a4,1472 # a2e0 <_binary_obj___user_forktest_out_size>
ffffffffc0204d28:	e43a                	sd	a4,8(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0204d2a:	853e                	mv	a0,a5
ffffffffc0204d2c:	00043717          	auipc	a4,0x43
ffffffffc0204d30:	32470713          	addi	a4,a4,804 # ffffffffc0248050 <_binary_obj___user_forktest_out_start>
ffffffffc0204d34:	f03a                	sd	a4,32(sp)
ffffffffc0204d36:	f43e                	sd	a5,40(sp)
ffffffffc0204d38:	e802                	sd	zero,16(sp)
ffffffffc0204d3a:	7f0010ef          	jal	ra,ffffffffc020652a <strlen>
ffffffffc0204d3e:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204d40:	4511                	li	a0,4
ffffffffc0204d42:	55a2                	lw	a1,40(sp)
ffffffffc0204d44:	4662                	lw	a2,24(sp)
ffffffffc0204d46:	5682                	lw	a3,32(sp)
ffffffffc0204d48:	4722                	lw	a4,8(sp)
ffffffffc0204d4a:	48a9                	li	a7,10
ffffffffc0204d4c:	9002                	ebreak
ffffffffc0204d4e:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204d50:	65c2                	ld	a1,16(sp)
ffffffffc0204d52:	00004517          	auipc	a0,0x4
ffffffffc0204d56:	ae650513          	addi	a0,a0,-1306 # ffffffffc0208838 <default_pmm_manager+0x1520>
ffffffffc0204d5a:	c34fb0ef          	jal	ra,ffffffffc020018e <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204d5e:	00004617          	auipc	a2,0x4
ffffffffc0204d62:	aea60613          	addi	a2,a2,-1302 # ffffffffc0208848 <default_pmm_manager+0x1530>
ffffffffc0204d66:	42b00593          	li	a1,1067
ffffffffc0204d6a:	00004517          	auipc	a0,0x4
ffffffffc0204d6e:	afe50513          	addi	a0,a0,-1282 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0204d72:	f12fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204d76 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204d76:	6d14                	ld	a3,24(a0)
{
ffffffffc0204d78:	1141                	addi	sp,sp,-16
ffffffffc0204d7a:	e406                	sd	ra,8(sp)
ffffffffc0204d7c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204d80:	04f6e263          	bltu	a3,a5,ffffffffc0204dc4 <put_pgdir+0x4e>
ffffffffc0204d84:	000a7797          	auipc	a5,0xa7
ffffffffc0204d88:	77478793          	addi	a5,a5,1908 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc0204d8c:	6388                	ld	a0,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0204d8e:	000a7797          	auipc	a5,0xa7
ffffffffc0204d92:	70a78793          	addi	a5,a5,1802 # ffffffffc02ac498 <npage>
ffffffffc0204d96:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0204d98:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage) {
ffffffffc0204d9a:	82b1                	srli	a3,a3,0xc
ffffffffc0204d9c:	04f6f063          	bleu	a5,a3,ffffffffc0204ddc <put_pgdir+0x66>
    return &pages[PPN(pa) - nbase];
ffffffffc0204da0:	00004797          	auipc	a5,0x4
ffffffffc0204da4:	f9078793          	addi	a5,a5,-112 # ffffffffc0208d30 <nbase>
ffffffffc0204da8:	639c                	ld	a5,0(a5)
ffffffffc0204daa:	000a7717          	auipc	a4,0xa7
ffffffffc0204dae:	75e70713          	addi	a4,a4,1886 # ffffffffc02ac508 <pages>
ffffffffc0204db2:	6308                	ld	a0,0(a4)
}
ffffffffc0204db4:	60a2                	ld	ra,8(sp)
ffffffffc0204db6:	8e9d                	sub	a3,a3,a5
ffffffffc0204db8:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204dba:	4585                	li	a1,1
ffffffffc0204dbc:	9536                	add	a0,a0,a3
}
ffffffffc0204dbe:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204dc0:	912fd06f          	j	ffffffffc0201ed2 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204dc4:	00002617          	auipc	a2,0x2
ffffffffc0204dc8:	5dc60613          	addi	a2,a2,1500 # ffffffffc02073a0 <default_pmm_manager+0x88>
ffffffffc0204dcc:	06e00593          	li	a1,110
ffffffffc0204dd0:	00002517          	auipc	a0,0x2
ffffffffc0204dd4:	5c050513          	addi	a0,a0,1472 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0204dd8:	eacfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204ddc:	00002617          	auipc	a2,0x2
ffffffffc0204de0:	5ec60613          	addi	a2,a2,1516 # ffffffffc02073c8 <default_pmm_manager+0xb0>
ffffffffc0204de4:	06200593          	li	a1,98
ffffffffc0204de8:	00002517          	auipc	a0,0x2
ffffffffc0204dec:	5a850513          	addi	a0,a0,1448 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0204df0:	e94fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204df4 <setup_pgdir>:
{
ffffffffc0204df4:	1101                	addi	sp,sp,-32
ffffffffc0204df6:	e426                	sd	s1,8(sp)
ffffffffc0204df8:	84aa                	mv	s1,a0
    if ((page = alloc_page()) == NULL)
ffffffffc0204dfa:	4505                	li	a0,1
{
ffffffffc0204dfc:	ec06                	sd	ra,24(sp)
ffffffffc0204dfe:	e822                	sd	s0,16(sp)
    if ((page = alloc_page()) == NULL)
ffffffffc0204e00:	84afd0ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
ffffffffc0204e04:	c125                	beqz	a0,ffffffffc0204e64 <setup_pgdir+0x70>
    return page - pages + nbase;
ffffffffc0204e06:	000a7797          	auipc	a5,0xa7
ffffffffc0204e0a:	70278793          	addi	a5,a5,1794 # ffffffffc02ac508 <pages>
ffffffffc0204e0e:	6394                	ld	a3,0(a5)
ffffffffc0204e10:	00004797          	auipc	a5,0x4
ffffffffc0204e14:	f2078793          	addi	a5,a5,-224 # ffffffffc0208d30 <nbase>
ffffffffc0204e18:	6380                	ld	s0,0(a5)
ffffffffc0204e1a:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204e1e:	000a7717          	auipc	a4,0xa7
ffffffffc0204e22:	67a70713          	addi	a4,a4,1658 # ffffffffc02ac498 <npage>
    return page - pages + nbase;
ffffffffc0204e26:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204e28:	57fd                	li	a5,-1
ffffffffc0204e2a:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc0204e2c:	96a2                	add	a3,a3,s0
    return KADDR(page2pa(page));
ffffffffc0204e2e:	83b1                	srli	a5,a5,0xc
ffffffffc0204e30:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e32:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204e34:	02e7fa63          	bleu	a4,a5,ffffffffc0204e68 <setup_pgdir+0x74>
ffffffffc0204e38:	000a7797          	auipc	a5,0xa7
ffffffffc0204e3c:	6c078793          	addi	a5,a5,1728 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc0204e40:	6380                	ld	s0,0(a5)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc0204e42:	000a7797          	auipc	a5,0xa7
ffffffffc0204e46:	64e78793          	addi	a5,a5,1614 # ffffffffc02ac490 <boot_pgdir>
ffffffffc0204e4a:	638c                	ld	a1,0(a5)
ffffffffc0204e4c:	9436                	add	s0,s0,a3
ffffffffc0204e4e:	6605                	lui	a2,0x1
ffffffffc0204e50:	8522                	mv	a0,s0
ffffffffc0204e52:	788010ef          	jal	ra,ffffffffc02065da <memcpy>
    return 0;
ffffffffc0204e56:	4501                	li	a0,0
    mm->pgdir = pgdir;
ffffffffc0204e58:	ec80                	sd	s0,24(s1)
}
ffffffffc0204e5a:	60e2                	ld	ra,24(sp)
ffffffffc0204e5c:	6442                	ld	s0,16(sp)
ffffffffc0204e5e:	64a2                	ld	s1,8(sp)
ffffffffc0204e60:	6105                	addi	sp,sp,32
ffffffffc0204e62:	8082                	ret
        return -E_NO_MEM;
ffffffffc0204e64:	5571                	li	a0,-4
ffffffffc0204e66:	bfd5                	j	ffffffffc0204e5a <setup_pgdir+0x66>
ffffffffc0204e68:	00002617          	auipc	a2,0x2
ffffffffc0204e6c:	50060613          	addi	a2,a2,1280 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc0204e70:	06900593          	li	a1,105
ffffffffc0204e74:	00002517          	auipc	a0,0x2
ffffffffc0204e78:	51c50513          	addi	a0,a0,1308 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0204e7c:	e08fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204e80 <set_proc_name>:
{
ffffffffc0204e80:	1101                	addi	sp,sp,-32
ffffffffc0204e82:	e822                	sd	s0,16(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e84:	0b450413          	addi	s0,a0,180
{
ffffffffc0204e88:	e426                	sd	s1,8(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e8a:	4641                	li	a2,16
{
ffffffffc0204e8c:	84ae                	mv	s1,a1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e8e:	8522                	mv	a0,s0
ffffffffc0204e90:	4581                	li	a1,0
{
ffffffffc0204e92:	ec06                	sd	ra,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e94:	734010ef          	jal	ra,ffffffffc02065c8 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e98:	8522                	mv	a0,s0
}
ffffffffc0204e9a:	6442                	ld	s0,16(sp)
ffffffffc0204e9c:	60e2                	ld	ra,24(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e9e:	85a6                	mv	a1,s1
}
ffffffffc0204ea0:	64a2                	ld	s1,8(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204ea2:	463d                	li	a2,15
}
ffffffffc0204ea4:	6105                	addi	sp,sp,32
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204ea6:	7340106f          	j	ffffffffc02065da <memcpy>

ffffffffc0204eaa <proc_run>:
{
ffffffffc0204eaa:	1101                	addi	sp,sp,-32
    if (proc != current)
ffffffffc0204eac:	000a7797          	auipc	a5,0xa7
ffffffffc0204eb0:	60478793          	addi	a5,a5,1540 # ffffffffc02ac4b0 <current>
{
ffffffffc0204eb4:	e426                	sd	s1,8(sp)
    if (proc != current)
ffffffffc0204eb6:	6384                	ld	s1,0(a5)
{
ffffffffc0204eb8:	ec06                	sd	ra,24(sp)
ffffffffc0204eba:	e822                	sd	s0,16(sp)
ffffffffc0204ebc:	e04a                	sd	s2,0(sp)
    if (proc != current)
ffffffffc0204ebe:	02a48b63          	beq	s1,a0,ffffffffc0204ef4 <proc_run+0x4a>
ffffffffc0204ec2:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204ec4:	100027f3          	csrr	a5,sstatus
ffffffffc0204ec8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204eca:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204ecc:	e3a9                	bnez	a5,ffffffffc0204f0e <proc_run+0x64>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned long cr3) {
    write_csr(satp, 0x8000000000000000 | (cr3 >> RISCV_PGSHIFT));
ffffffffc0204ece:	745c                	ld	a5,168(s0)
            current = proc;
ffffffffc0204ed0:	000a7717          	auipc	a4,0xa7
ffffffffc0204ed4:	5e873023          	sd	s0,1504(a4) # ffffffffc02ac4b0 <current>
ffffffffc0204ed8:	577d                	li	a4,-1
ffffffffc0204eda:	177e                	slli	a4,a4,0x3f
ffffffffc0204edc:	83b1                	srli	a5,a5,0xc
ffffffffc0204ede:	8fd9                	or	a5,a5,a4
ffffffffc0204ee0:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0204ee4:	03040593          	addi	a1,s0,48
ffffffffc0204ee8:	03048513          	addi	a0,s1,48
ffffffffc0204eec:	7d3000ef          	jal	ra,ffffffffc0205ebe <switch_to>
    if (flag) {
ffffffffc0204ef0:	00091863          	bnez	s2,ffffffffc0204f00 <proc_run+0x56>
}
ffffffffc0204ef4:	60e2                	ld	ra,24(sp)
ffffffffc0204ef6:	6442                	ld	s0,16(sp)
ffffffffc0204ef8:	64a2                	ld	s1,8(sp)
ffffffffc0204efa:	6902                	ld	s2,0(sp)
ffffffffc0204efc:	6105                	addi	sp,sp,32
ffffffffc0204efe:	8082                	ret
ffffffffc0204f00:	6442                	ld	s0,16(sp)
ffffffffc0204f02:	60e2                	ld	ra,24(sp)
ffffffffc0204f04:	64a2                	ld	s1,8(sp)
ffffffffc0204f06:	6902                	ld	s2,0(sp)
ffffffffc0204f08:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0204f0a:	f4afb06f          	j	ffffffffc0200654 <intr_enable>
        intr_disable();
ffffffffc0204f0e:	f4cfb0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc0204f12:	4905                	li	s2,1
ffffffffc0204f14:	bf6d                	j	ffffffffc0204ece <proc_run+0x24>

ffffffffc0204f16 <find_proc>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f16:	0005071b          	sext.w	a4,a0
ffffffffc0204f1a:	6789                	lui	a5,0x2
ffffffffc0204f1c:	fff7069b          	addiw	a3,a4,-1
ffffffffc0204f20:	17f9                	addi	a5,a5,-2
ffffffffc0204f22:	04d7e063          	bltu	a5,a3,ffffffffc0204f62 <find_proc+0x4c>
{
ffffffffc0204f26:	1141                	addi	sp,sp,-16
ffffffffc0204f28:	e022                	sd	s0,0(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f2a:	45a9                	li	a1,10
ffffffffc0204f2c:	842a                	mv	s0,a0
ffffffffc0204f2e:	853a                	mv	a0,a4
{
ffffffffc0204f30:	e406                	sd	ra,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f32:	1e8010ef          	jal	ra,ffffffffc020611a <hash32>
ffffffffc0204f36:	02051693          	slli	a3,a0,0x20
ffffffffc0204f3a:	82f1                	srli	a3,a3,0x1c
ffffffffc0204f3c:	000a3517          	auipc	a0,0xa3
ffffffffc0204f40:	53c50513          	addi	a0,a0,1340 # ffffffffc02a8478 <hash_list>
ffffffffc0204f44:	96aa                	add	a3,a3,a0
ffffffffc0204f46:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204f48:	a029                	j	ffffffffc0204f52 <find_proc+0x3c>
            if (proc->pid == pid)
ffffffffc0204f4a:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7654>
ffffffffc0204f4e:	00870c63          	beq	a4,s0,ffffffffc0204f66 <find_proc+0x50>
ffffffffc0204f52:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204f54:	fef69be3          	bne	a3,a5,ffffffffc0204f4a <find_proc+0x34>
}
ffffffffc0204f58:	60a2                	ld	ra,8(sp)
ffffffffc0204f5a:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc0204f5c:	4501                	li	a0,0
}
ffffffffc0204f5e:	0141                	addi	sp,sp,16
ffffffffc0204f60:	8082                	ret
    return NULL;
ffffffffc0204f62:	4501                	li	a0,0
}
ffffffffc0204f64:	8082                	ret
ffffffffc0204f66:	60a2                	ld	ra,8(sp)
ffffffffc0204f68:	6402                	ld	s0,0(sp)
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204f6a:	f2878513          	addi	a0,a5,-216
}
ffffffffc0204f6e:	0141                	addi	sp,sp,16
ffffffffc0204f70:	8082                	ret

ffffffffc0204f72 <do_fork>:
{
ffffffffc0204f72:	7159                	addi	sp,sp,-112
ffffffffc0204f74:	e0d2                	sd	s4,64(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204f76:	000a7a17          	auipc	s4,0xa7
ffffffffc0204f7a:	552a0a13          	addi	s4,s4,1362 # ffffffffc02ac4c8 <nr_process>
ffffffffc0204f7e:	000a2703          	lw	a4,0(s4)
{
ffffffffc0204f82:	f486                	sd	ra,104(sp)
ffffffffc0204f84:	f0a2                	sd	s0,96(sp)
ffffffffc0204f86:	eca6                	sd	s1,88(sp)
ffffffffc0204f88:	e8ca                	sd	s2,80(sp)
ffffffffc0204f8a:	e4ce                	sd	s3,72(sp)
ffffffffc0204f8c:	fc56                	sd	s5,56(sp)
ffffffffc0204f8e:	f85a                	sd	s6,48(sp)
ffffffffc0204f90:	f45e                	sd	s7,40(sp)
ffffffffc0204f92:	f062                	sd	s8,32(sp)
ffffffffc0204f94:	ec66                	sd	s9,24(sp)
ffffffffc0204f96:	e86a                	sd	s10,16(sp)
ffffffffc0204f98:	e46e                	sd	s11,8(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204f9a:	6785                	lui	a5,0x1
ffffffffc0204f9c:	30f75a63          	ble	a5,a4,ffffffffc02052b0 <do_fork+0x33e>
ffffffffc0204fa0:	89aa                	mv	s3,a0
ffffffffc0204fa2:	892e                	mv	s2,a1
ffffffffc0204fa4:	84b2                	mv	s1,a2
    if ((proc = alloc_proc()) == NULL)
ffffffffc0204fa6:	d07ff0ef          	jal	ra,ffffffffc0204cac <alloc_proc>
ffffffffc0204faa:	842a                	mv	s0,a0
ffffffffc0204fac:	2e050463          	beqz	a0,ffffffffc0205294 <do_fork+0x322>
    proc->parent = current; // 设置父进程
ffffffffc0204fb0:	000a7c17          	auipc	s8,0xa7
ffffffffc0204fb4:	500c0c13          	addi	s8,s8,1280 # ffffffffc02ac4b0 <current>
ffffffffc0204fb8:	000c3783          	ld	a5,0(s8)
    assert(current->wait_state == 0);
ffffffffc0204fbc:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8494>
    proc->parent = current; // 设置父进程
ffffffffc0204fc0:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0204fc2:	30071563          	bnez	a4,ffffffffc02052cc <do_fork+0x35a>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204fc6:	4509                	li	a0,2
ffffffffc0204fc8:	e83fc0ef          	jal	ra,ffffffffc0201e4a <alloc_pages>
    if (page != NULL)
ffffffffc0204fcc:	2c050163          	beqz	a0,ffffffffc020528e <do_fork+0x31c>
    return page - pages + nbase;
ffffffffc0204fd0:	000a7a97          	auipc	s5,0xa7
ffffffffc0204fd4:	538a8a93          	addi	s5,s5,1336 # ffffffffc02ac508 <pages>
ffffffffc0204fd8:	000ab683          	ld	a3,0(s5)
ffffffffc0204fdc:	00004b17          	auipc	s6,0x4
ffffffffc0204fe0:	d54b0b13          	addi	s6,s6,-684 # ffffffffc0208d30 <nbase>
ffffffffc0204fe4:	000b3783          	ld	a5,0(s6)
ffffffffc0204fe8:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204fec:	000a7b97          	auipc	s7,0xa7
ffffffffc0204ff0:	4acb8b93          	addi	s7,s7,1196 # ffffffffc02ac498 <npage>
    return page - pages + nbase;
ffffffffc0204ff4:	8699                	srai	a3,a3,0x6
ffffffffc0204ff6:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204ff8:	000bb703          	ld	a4,0(s7)
ffffffffc0204ffc:	57fd                	li	a5,-1
ffffffffc0204ffe:	83b1                	srli	a5,a5,0xc
ffffffffc0205000:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0205002:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205004:	2ae7f863          	bleu	a4,a5,ffffffffc02052b4 <do_fork+0x342>
ffffffffc0205008:	000a7c97          	auipc	s9,0xa7
ffffffffc020500c:	4f0c8c93          	addi	s9,s9,1264 # ffffffffc02ac4f8 <va_pa_offset>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0205010:	000c3703          	ld	a4,0(s8)
ffffffffc0205014:	000cb783          	ld	a5,0(s9)
ffffffffc0205018:	02873c03          	ld	s8,40(a4)
ffffffffc020501c:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc020501e:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc0205020:	020c0863          	beqz	s8,ffffffffc0205050 <do_fork+0xde>
    if (clone_flags & CLONE_VM)
ffffffffc0205024:	1009f993          	andi	s3,s3,256
ffffffffc0205028:	1e098163          	beqz	s3,ffffffffc020520a <do_fork+0x298>
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
ffffffffc020502c:	030c2703          	lw	a4,48(s8)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0205030:	018c3783          	ld	a5,24(s8)
ffffffffc0205034:	c02006b7          	lui	a3,0xc0200
ffffffffc0205038:	2705                	addiw	a4,a4,1
ffffffffc020503a:	02ec2823          	sw	a4,48(s8)
    proc->mm = mm;
ffffffffc020503e:	03843423          	sd	s8,40(s0)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0205042:	2ad7e563          	bltu	a5,a3,ffffffffc02052ec <do_fork+0x37a>
ffffffffc0205046:	000cb703          	ld	a4,0(s9)
ffffffffc020504a:	6814                	ld	a3,16(s0)
ffffffffc020504c:	8f99                	sub	a5,a5,a4
ffffffffc020504e:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0205050:	6789                	lui	a5,0x2
ffffffffc0205052:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x76a0>
ffffffffc0205056:	96be                	add	a3,a3,a5
ffffffffc0205058:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc020505a:	87b6                	mv	a5,a3
ffffffffc020505c:	12048813          	addi	a6,s1,288
ffffffffc0205060:	6088                	ld	a0,0(s1)
ffffffffc0205062:	648c                	ld	a1,8(s1)
ffffffffc0205064:	6890                	ld	a2,16(s1)
ffffffffc0205066:	6c98                	ld	a4,24(s1)
ffffffffc0205068:	e388                	sd	a0,0(a5)
ffffffffc020506a:	e78c                	sd	a1,8(a5)
ffffffffc020506c:	eb90                	sd	a2,16(a5)
ffffffffc020506e:	ef98                	sd	a4,24(a5)
ffffffffc0205070:	02048493          	addi	s1,s1,32
ffffffffc0205074:	02078793          	addi	a5,a5,32
ffffffffc0205078:	ff0494e3          	bne	s1,a6,ffffffffc0205060 <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc020507c:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x1a>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0205080:	12090e63          	beqz	s2,ffffffffc02051bc <do_fork+0x24a>
ffffffffc0205084:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0205088:	00000797          	auipc	a5,0x0
ffffffffc020508c:	c5c78793          	addi	a5,a5,-932 # ffffffffc0204ce4 <forkret>
ffffffffc0205090:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0205092:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205094:	100027f3          	csrr	a5,sstatus
ffffffffc0205098:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020509a:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020509c:	12079f63          	bnez	a5,ffffffffc02051da <do_fork+0x268>
    if (++last_pid >= MAX_PID)
ffffffffc02050a0:	0009c797          	auipc	a5,0x9c
ffffffffc02050a4:	fd078793          	addi	a5,a5,-48 # ffffffffc02a1070 <last_pid.1691>
ffffffffc02050a8:	439c                	lw	a5,0(a5)
ffffffffc02050aa:	6709                	lui	a4,0x2
ffffffffc02050ac:	0017851b          	addiw	a0,a5,1
ffffffffc02050b0:	0009c697          	auipc	a3,0x9c
ffffffffc02050b4:	fca6a023          	sw	a0,-64(a3) # ffffffffc02a1070 <last_pid.1691>
ffffffffc02050b8:	14e55263          	ble	a4,a0,ffffffffc02051fc <do_fork+0x28a>
    if (last_pid >= next_safe)
ffffffffc02050bc:	0009c797          	auipc	a5,0x9c
ffffffffc02050c0:	fb878793          	addi	a5,a5,-72 # ffffffffc02a1074 <next_safe.1690>
ffffffffc02050c4:	439c                	lw	a5,0(a5)
ffffffffc02050c6:	000a7497          	auipc	s1,0xa7
ffffffffc02050ca:	52a48493          	addi	s1,s1,1322 # ffffffffc02ac5f0 <proc_list>
ffffffffc02050ce:	06f54063          	blt	a0,a5,ffffffffc020512e <do_fork+0x1bc>
        next_safe = MAX_PID;
ffffffffc02050d2:	6789                	lui	a5,0x2
ffffffffc02050d4:	0009c717          	auipc	a4,0x9c
ffffffffc02050d8:	faf72023          	sw	a5,-96(a4) # ffffffffc02a1074 <next_safe.1690>
ffffffffc02050dc:	4581                	li	a1,0
ffffffffc02050de:	87aa                	mv	a5,a0
ffffffffc02050e0:	000a7497          	auipc	s1,0xa7
ffffffffc02050e4:	51048493          	addi	s1,s1,1296 # ffffffffc02ac5f0 <proc_list>
    repeat:
ffffffffc02050e8:	6889                	lui	a7,0x2
ffffffffc02050ea:	882e                	mv	a6,a1
ffffffffc02050ec:	6609                	lui	a2,0x2
        le = list;
ffffffffc02050ee:	000a7697          	auipc	a3,0xa7
ffffffffc02050f2:	50268693          	addi	a3,a3,1282 # ffffffffc02ac5f0 <proc_list>
ffffffffc02050f6:	6694                	ld	a3,8(a3)
        while ((le = list_next(le)) != list)
ffffffffc02050f8:	00968f63          	beq	a3,s1,ffffffffc0205116 <do_fork+0x1a4>
            if (proc->pid == last_pid)
ffffffffc02050fc:	f3c6a703          	lw	a4,-196(a3)
ffffffffc0205100:	0ae78963          	beq	a5,a4,ffffffffc02051b2 <do_fork+0x240>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0205104:	fee7d9e3          	ble	a4,a5,ffffffffc02050f6 <do_fork+0x184>
ffffffffc0205108:	fec757e3          	ble	a2,a4,ffffffffc02050f6 <do_fork+0x184>
ffffffffc020510c:	6694                	ld	a3,8(a3)
ffffffffc020510e:	863a                	mv	a2,a4
ffffffffc0205110:	4805                	li	a6,1
        while ((le = list_next(le)) != list)
ffffffffc0205112:	fe9695e3          	bne	a3,s1,ffffffffc02050fc <do_fork+0x18a>
ffffffffc0205116:	c591                	beqz	a1,ffffffffc0205122 <do_fork+0x1b0>
ffffffffc0205118:	0009c717          	auipc	a4,0x9c
ffffffffc020511c:	f4f72c23          	sw	a5,-168(a4) # ffffffffc02a1070 <last_pid.1691>
ffffffffc0205120:	853e                	mv	a0,a5
ffffffffc0205122:	00080663          	beqz	a6,ffffffffc020512e <do_fork+0x1bc>
ffffffffc0205126:	0009c797          	auipc	a5,0x9c
ffffffffc020512a:	f4c7a723          	sw	a2,-178(a5) # ffffffffc02a1074 <next_safe.1690>
        proc->pid = get_pid();
ffffffffc020512e:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0205130:	45a9                	li	a1,10
ffffffffc0205132:	2501                	sext.w	a0,a0
ffffffffc0205134:	7e7000ef          	jal	ra,ffffffffc020611a <hash32>
ffffffffc0205138:	1502                	slli	a0,a0,0x20
ffffffffc020513a:	000a3797          	auipc	a5,0xa3
ffffffffc020513e:	33e78793          	addi	a5,a5,830 # ffffffffc02a8478 <hash_list>
ffffffffc0205142:	8171                	srli	a0,a0,0x1c
ffffffffc0205144:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0205146:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0205148:	7014                	ld	a3,32(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020514a:	0d840793          	addi	a5,s0,216
    prev->next = next->prev = elm;
ffffffffc020514e:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0205150:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc0205152:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0205154:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0205156:	0c840793          	addi	a5,s0,200
    elm->next = next;
ffffffffc020515a:	f06c                	sd	a1,224(s0)
    elm->prev = prev;
ffffffffc020515c:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc020515e:	e21c                	sd	a5,0(a2)
ffffffffc0205160:	000a7597          	auipc	a1,0xa7
ffffffffc0205164:	48f5bc23          	sd	a5,1176(a1) # ffffffffc02ac5f8 <proc_list+0x8>
    elm->next = next;
ffffffffc0205168:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc020516a:	e464                	sd	s1,200(s0)
    proc->yptr = NULL;
ffffffffc020516c:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0205170:	10e43023          	sd	a4,256(s0)
ffffffffc0205174:	c311                	beqz	a4,ffffffffc0205178 <do_fork+0x206>
        proc->optr->yptr = proc;
ffffffffc0205176:	ff60                	sd	s0,248(a4)
    nr_process++;
ffffffffc0205178:	000a2783          	lw	a5,0(s4)
    proc->parent->cptr = proc;
ffffffffc020517c:	fae0                	sd	s0,240(a3)
    nr_process++;
ffffffffc020517e:	2785                	addiw	a5,a5,1
ffffffffc0205180:	000a7717          	auipc	a4,0xa7
ffffffffc0205184:	34f72423          	sw	a5,840(a4) # ffffffffc02ac4c8 <nr_process>
    if (flag) {
ffffffffc0205188:	10091863          	bnez	s2,ffffffffc0205298 <do_fork+0x326>
    wakeup_proc(proc);
ffffffffc020518c:	8522                	mv	a0,s0
ffffffffc020518e:	59b000ef          	jal	ra,ffffffffc0205f28 <wakeup_proc>
    ret = proc->pid;
ffffffffc0205192:	4048                	lw	a0,4(s0)
}
ffffffffc0205194:	70a6                	ld	ra,104(sp)
ffffffffc0205196:	7406                	ld	s0,96(sp)
ffffffffc0205198:	64e6                	ld	s1,88(sp)
ffffffffc020519a:	6946                	ld	s2,80(sp)
ffffffffc020519c:	69a6                	ld	s3,72(sp)
ffffffffc020519e:	6a06                	ld	s4,64(sp)
ffffffffc02051a0:	7ae2                	ld	s5,56(sp)
ffffffffc02051a2:	7b42                	ld	s6,48(sp)
ffffffffc02051a4:	7ba2                	ld	s7,40(sp)
ffffffffc02051a6:	7c02                	ld	s8,32(sp)
ffffffffc02051a8:	6ce2                	ld	s9,24(sp)
ffffffffc02051aa:	6d42                	ld	s10,16(sp)
ffffffffc02051ac:	6da2                	ld	s11,8(sp)
ffffffffc02051ae:	6165                	addi	sp,sp,112
ffffffffc02051b0:	8082                	ret
                if (++last_pid >= next_safe)
ffffffffc02051b2:	2785                	addiw	a5,a5,1
ffffffffc02051b4:	0ec7d563          	ble	a2,a5,ffffffffc020529e <do_fork+0x32c>
ffffffffc02051b8:	4585                	li	a1,1
ffffffffc02051ba:	bf35                	j	ffffffffc02050f6 <do_fork+0x184>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02051bc:	8936                	mv	s2,a3
ffffffffc02051be:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02051c2:	00000797          	auipc	a5,0x0
ffffffffc02051c6:	b2278793          	addi	a5,a5,-1246 # ffffffffc0204ce4 <forkret>
ffffffffc02051ca:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02051cc:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02051ce:	100027f3          	csrr	a5,sstatus
ffffffffc02051d2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02051d4:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02051d6:	ec0785e3          	beqz	a5,ffffffffc02050a0 <do_fork+0x12e>
        intr_disable();
ffffffffc02051da:	c80fb0ef          	jal	ra,ffffffffc020065a <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc02051de:	0009c797          	auipc	a5,0x9c
ffffffffc02051e2:	e9278793          	addi	a5,a5,-366 # ffffffffc02a1070 <last_pid.1691>
ffffffffc02051e6:	439c                	lw	a5,0(a5)
ffffffffc02051e8:	6709                	lui	a4,0x2
        return 1;
ffffffffc02051ea:	4905                	li	s2,1
ffffffffc02051ec:	0017851b          	addiw	a0,a5,1
ffffffffc02051f0:	0009c697          	auipc	a3,0x9c
ffffffffc02051f4:	e8a6a023          	sw	a0,-384(a3) # ffffffffc02a1070 <last_pid.1691>
ffffffffc02051f8:	ece542e3          	blt	a0,a4,ffffffffc02050bc <do_fork+0x14a>
        last_pid = 1;
ffffffffc02051fc:	4785                	li	a5,1
ffffffffc02051fe:	0009c717          	auipc	a4,0x9c
ffffffffc0205202:	e6f72923          	sw	a5,-398(a4) # ffffffffc02a1070 <last_pid.1691>
ffffffffc0205206:	4505                	li	a0,1
ffffffffc0205208:	b5e9                	j	ffffffffc02050d2 <do_fork+0x160>
    if ((mm = mm_create()) == NULL) //创建mm_struct
ffffffffc020520a:	eb5fe0ef          	jal	ra,ffffffffc02040be <mm_create>
ffffffffc020520e:	8d2a                	mv	s10,a0
ffffffffc0205210:	c539                	beqz	a0,ffffffffc020525e <do_fork+0x2ec>
    if (setup_pgdir(mm) != 0) // alloc one page as PDT
ffffffffc0205212:	be3ff0ef          	jal	ra,ffffffffc0204df4 <setup_pgdir>
ffffffffc0205216:	e949                	bnez	a0,ffffffffc02052a8 <do_fork+0x336>
}

static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        lock(&(mm->mm_lock));
ffffffffc0205218:	038c0d93          	addi	s11,s8,56
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020521c:	4785                	li	a5,1
ffffffffc020521e:	40fdb7af          	amoor.d	a5,a5,(s11)
ffffffffc0205222:	8b85                	andi	a5,a5,1
ffffffffc0205224:	4985                	li	s3,1
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
ffffffffc0205226:	c799                	beqz	a5,ffffffffc0205234 <do_fork+0x2c2>
        schedule();
ffffffffc0205228:	57d000ef          	jal	ra,ffffffffc0205fa4 <schedule>
ffffffffc020522c:	413db7af          	amoor.d	a5,s3,(s11)
ffffffffc0205230:	8b85                	andi	a5,a5,1
    while (!try_lock(lock)) {
ffffffffc0205232:	fbfd                	bnez	a5,ffffffffc0205228 <do_fork+0x2b6>
        ret = dup_mmap(mm, oldmm); //复制mm
ffffffffc0205234:	85e2                	mv	a1,s8
ffffffffc0205236:	856a                	mv	a0,s10
ffffffffc0205238:	910ff0ef          	jal	ra,ffffffffc0204348 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020523c:	57f9                	li	a5,-2
ffffffffc020523e:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc0205242:	8b85                	andi	a5,a5,1
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
ffffffffc0205244:	c3e9                	beqz	a5,ffffffffc0205306 <do_fork+0x394>
    if (ret != 0)
ffffffffc0205246:	8c6a                	mv	s8,s10
ffffffffc0205248:	de0502e3          	beqz	a0,ffffffffc020502c <do_fork+0xba>
    exit_mmap(mm);
ffffffffc020524c:	856a                	mv	a0,s10
ffffffffc020524e:	996ff0ef          	jal	ra,ffffffffc02043e4 <exit_mmap>
    put_pgdir(mm);
ffffffffc0205252:	856a                	mv	a0,s10
ffffffffc0205254:	b23ff0ef          	jal	ra,ffffffffc0204d76 <put_pgdir>
    mm_destroy(mm);
ffffffffc0205258:	856a                	mv	a0,s10
ffffffffc020525a:	febfe0ef          	jal	ra,ffffffffc0204244 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020525e:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0205260:	c02007b7          	lui	a5,0xc0200
ffffffffc0205264:	0cf6e963          	bltu	a3,a5,ffffffffc0205336 <do_fork+0x3c4>
ffffffffc0205268:	000cb783          	ld	a5,0(s9)
    if (PPN(pa) >= npage) {
ffffffffc020526c:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc0205270:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc0205274:	83b1                	srli	a5,a5,0xc
ffffffffc0205276:	0ae7f463          	bleu	a4,a5,ffffffffc020531e <do_fork+0x3ac>
    return &pages[PPN(pa) - nbase];
ffffffffc020527a:	000b3703          	ld	a4,0(s6)
ffffffffc020527e:	000ab503          	ld	a0,0(s5)
ffffffffc0205282:	4589                	li	a1,2
ffffffffc0205284:	8f99                	sub	a5,a5,a4
ffffffffc0205286:	079a                	slli	a5,a5,0x6
ffffffffc0205288:	953e                	add	a0,a0,a5
ffffffffc020528a:	c49fc0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    kfree(proc);
ffffffffc020528e:	8522                	mv	a0,s0
ffffffffc0205290:	a7bfc0ef          	jal	ra,ffffffffc0201d0a <kfree>
    ret = -E_NO_MEM;
ffffffffc0205294:	5571                	li	a0,-4
    return ret;
ffffffffc0205296:	bdfd                	j	ffffffffc0205194 <do_fork+0x222>
        intr_enable();
ffffffffc0205298:	bbcfb0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc020529c:	bdc5                	j	ffffffffc020518c <do_fork+0x21a>
                    if (last_pid >= MAX_PID)
ffffffffc020529e:	0117c363          	blt	a5,a7,ffffffffc02052a4 <do_fork+0x332>
                        last_pid = 1;
ffffffffc02052a2:	4785                	li	a5,1
                    goto repeat;
ffffffffc02052a4:	4585                	li	a1,1
ffffffffc02052a6:	b591                	j	ffffffffc02050ea <do_fork+0x178>
    mm_destroy(mm);
ffffffffc02052a8:	856a                	mv	a0,s10
ffffffffc02052aa:	f9bfe0ef          	jal	ra,ffffffffc0204244 <mm_destroy>
ffffffffc02052ae:	bf45                	j	ffffffffc020525e <do_fork+0x2ec>
    int ret = -E_NO_FREE_PROC;
ffffffffc02052b0:	556d                	li	a0,-5
ffffffffc02052b2:	b5cd                	j	ffffffffc0205194 <do_fork+0x222>
    return KADDR(page2pa(page));
ffffffffc02052b4:	00002617          	auipc	a2,0x2
ffffffffc02052b8:	0b460613          	addi	a2,a2,180 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc02052bc:	06900593          	li	a1,105
ffffffffc02052c0:	00002517          	auipc	a0,0x2
ffffffffc02052c4:	0d050513          	addi	a0,a0,208 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc02052c8:	9bcfb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(current->wait_state == 0);
ffffffffc02052cc:	00003697          	auipc	a3,0x3
ffffffffc02052d0:	30c68693          	addi	a3,a3,780 # ffffffffc02085d8 <default_pmm_manager+0x12c0>
ffffffffc02052d4:	00002617          	auipc	a2,0x2
ffffffffc02052d8:	8fc60613          	addi	a2,a2,-1796 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02052dc:	1e800593          	li	a1,488
ffffffffc02052e0:	00003517          	auipc	a0,0x3
ffffffffc02052e4:	58850513          	addi	a0,a0,1416 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc02052e8:	99cfb0ef          	jal	ra,ffffffffc0200484 <__panic>
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc02052ec:	86be                	mv	a3,a5
ffffffffc02052ee:	00002617          	auipc	a2,0x2
ffffffffc02052f2:	0b260613          	addi	a2,a2,178 # ffffffffc02073a0 <default_pmm_manager+0x88>
ffffffffc02052f6:	19d00593          	li	a1,413
ffffffffc02052fa:	00003517          	auipc	a0,0x3
ffffffffc02052fe:	56e50513          	addi	a0,a0,1390 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205302:	982fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("Unlock failed.\n");
ffffffffc0205306:	00003617          	auipc	a2,0x3
ffffffffc020530a:	2f260613          	addi	a2,a2,754 # ffffffffc02085f8 <default_pmm_manager+0x12e0>
ffffffffc020530e:	03100593          	li	a1,49
ffffffffc0205312:	00003517          	auipc	a0,0x3
ffffffffc0205316:	2f650513          	addi	a0,a0,758 # ffffffffc0208608 <default_pmm_manager+0x12f0>
ffffffffc020531a:	96afb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020531e:	00002617          	auipc	a2,0x2
ffffffffc0205322:	0aa60613          	addi	a2,a2,170 # ffffffffc02073c8 <default_pmm_manager+0xb0>
ffffffffc0205326:	06200593          	li	a1,98
ffffffffc020532a:	00002517          	auipc	a0,0x2
ffffffffc020532e:	06650513          	addi	a0,a0,102 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0205332:	952fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0205336:	00002617          	auipc	a2,0x2
ffffffffc020533a:	06a60613          	addi	a2,a2,106 # ffffffffc02073a0 <default_pmm_manager+0x88>
ffffffffc020533e:	06e00593          	li	a1,110
ffffffffc0205342:	00002517          	auipc	a0,0x2
ffffffffc0205346:	04e50513          	addi	a0,a0,78 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc020534a:	93afb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020534e <kernel_thread>:
{
ffffffffc020534e:	7129                	addi	sp,sp,-320
ffffffffc0205350:	fa22                	sd	s0,304(sp)
ffffffffc0205352:	f626                	sd	s1,296(sp)
ffffffffc0205354:	f24a                	sd	s2,288(sp)
ffffffffc0205356:	84ae                	mv	s1,a1
ffffffffc0205358:	892a                	mv	s2,a0
ffffffffc020535a:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe)); // tf进行清零初始化
ffffffffc020535c:	4581                	li	a1,0
ffffffffc020535e:	12000613          	li	a2,288
ffffffffc0205362:	850a                	mv	a0,sp
{
ffffffffc0205364:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe)); // tf进行清零初始化
ffffffffc0205366:	262010ef          	jal	ra,ffffffffc02065c8 <memset>
    tf.gpr.s0 = (uintptr_t)fn;  // s0 寄存器保存函数指针
ffffffffc020536a:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg; // s1 寄存器保存函数参数
ffffffffc020536c:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020536e:	100027f3          	csrr	a5,sstatus
ffffffffc0205372:	edd7f793          	andi	a5,a5,-291
ffffffffc0205376:	1207e793          	ori	a5,a5,288
ffffffffc020537a:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020537c:	860a                	mv	a2,sp
ffffffffc020537e:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0205382:	00000797          	auipc	a5,0x0
ffffffffc0205386:	92278793          	addi	a5,a5,-1758 # ffffffffc0204ca4 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020538a:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020538c:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020538e:	be5ff0ef          	jal	ra,ffffffffc0204f72 <do_fork>
}
ffffffffc0205392:	70f2                	ld	ra,312(sp)
ffffffffc0205394:	7452                	ld	s0,304(sp)
ffffffffc0205396:	74b2                	ld	s1,296(sp)
ffffffffc0205398:	7912                	ld	s2,288(sp)
ffffffffc020539a:	6131                	addi	sp,sp,320
ffffffffc020539c:	8082                	ret

ffffffffc020539e <do_exit>:
{
ffffffffc020539e:	7179                	addi	sp,sp,-48
ffffffffc02053a0:	e84a                	sd	s2,16(sp)
    if (current == idleproc)
ffffffffc02053a2:	000a7717          	auipc	a4,0xa7
ffffffffc02053a6:	11670713          	addi	a4,a4,278 # ffffffffc02ac4b8 <idleproc>
ffffffffc02053aa:	000a7917          	auipc	s2,0xa7
ffffffffc02053ae:	10690913          	addi	s2,s2,262 # ffffffffc02ac4b0 <current>
ffffffffc02053b2:	00093783          	ld	a5,0(s2)
ffffffffc02053b6:	6318                	ld	a4,0(a4)
{
ffffffffc02053b8:	f406                	sd	ra,40(sp)
ffffffffc02053ba:	f022                	sd	s0,32(sp)
ffffffffc02053bc:	ec26                	sd	s1,24(sp)
ffffffffc02053be:	e44e                	sd	s3,8(sp)
ffffffffc02053c0:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02053c2:	0ce78c63          	beq	a5,a4,ffffffffc020549a <do_exit+0xfc>
    if (current == initproc)
ffffffffc02053c6:	000a7417          	auipc	s0,0xa7
ffffffffc02053ca:	0fa40413          	addi	s0,s0,250 # ffffffffc02ac4c0 <initproc>
ffffffffc02053ce:	6018                	ld	a4,0(s0)
ffffffffc02053d0:	0ee78b63          	beq	a5,a4,ffffffffc02054c6 <do_exit+0x128>
    struct mm_struct *mm = current->mm;
ffffffffc02053d4:	7784                	ld	s1,40(a5)
ffffffffc02053d6:	89aa                	mv	s3,a0
    if (mm != NULL)
ffffffffc02053d8:	c48d                	beqz	s1,ffffffffc0205402 <do_exit+0x64>
        lcr3(boot_cr3);
ffffffffc02053da:	000a7797          	auipc	a5,0xa7
ffffffffc02053de:	12678793          	addi	a5,a5,294 # ffffffffc02ac500 <boot_cr3>
ffffffffc02053e2:	639c                	ld	a5,0(a5)
ffffffffc02053e4:	577d                	li	a4,-1
ffffffffc02053e6:	177e                	slli	a4,a4,0x3f
ffffffffc02053e8:	83b1                	srli	a5,a5,0xc
ffffffffc02053ea:	8fd9                	or	a5,a5,a4
ffffffffc02053ec:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02053f0:	589c                	lw	a5,48(s1)
ffffffffc02053f2:	fff7871b          	addiw	a4,a5,-1
ffffffffc02053f6:	d898                	sw	a4,48(s1)
        if (mm_count_dec(mm) == 0)
ffffffffc02053f8:	cf4d                	beqz	a4,ffffffffc02054b2 <do_exit+0x114>
        current->mm = NULL;
ffffffffc02053fa:	00093783          	ld	a5,0(s2)
ffffffffc02053fe:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0205402:	00093783          	ld	a5,0(s2)
ffffffffc0205406:	470d                	li	a4,3
ffffffffc0205408:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc020540a:	0f37a423          	sw	s3,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020540e:	100027f3          	csrr	a5,sstatus
ffffffffc0205412:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205414:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205416:	e7e1                	bnez	a5,ffffffffc02054de <do_exit+0x140>
        proc = current->parent;
ffffffffc0205418:	00093703          	ld	a4,0(s2)
        if (proc->wait_state == WT_CHILD)
ffffffffc020541c:	800007b7          	lui	a5,0x80000
ffffffffc0205420:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0205422:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0205424:	0ec52703          	lw	a4,236(a0)
ffffffffc0205428:	0af70f63          	beq	a4,a5,ffffffffc02054e6 <do_exit+0x148>
ffffffffc020542c:	00093683          	ld	a3,0(s2)
                if (initproc->wait_state == WT_CHILD)
ffffffffc0205430:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0205434:	448d                	li	s1,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0205436:	0985                	addi	s3,s3,1
        while (current->cptr != NULL)
ffffffffc0205438:	7afc                	ld	a5,240(a3)
ffffffffc020543a:	cb95                	beqz	a5,ffffffffc020546e <do_exit+0xd0>
            current->cptr = proc->optr;
ffffffffc020543c:	1007b703          	ld	a4,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff5680>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0205440:	6008                	ld	a0,0(s0)
            current->cptr = proc->optr;
ffffffffc0205442:	faf8                	sd	a4,240(a3)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0205444:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0205446:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020544a:	10e7b023          	sd	a4,256(a5)
ffffffffc020544e:	c311                	beqz	a4,ffffffffc0205452 <do_exit+0xb4>
                initproc->cptr->yptr = proc;
ffffffffc0205450:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0205452:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0205454:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0205456:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0205458:	fe9710e3          	bne	a4,s1,ffffffffc0205438 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020545c:	0ec52783          	lw	a5,236(a0)
ffffffffc0205460:	fd379ce3          	bne	a5,s3,ffffffffc0205438 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0205464:	2c5000ef          	jal	ra,ffffffffc0205f28 <wakeup_proc>
ffffffffc0205468:	00093683          	ld	a3,0(s2)
ffffffffc020546c:	b7f1                	j	ffffffffc0205438 <do_exit+0x9a>
    if (flag) {
ffffffffc020546e:	020a1363          	bnez	s4,ffffffffc0205494 <do_exit+0xf6>
    schedule();
ffffffffc0205472:	333000ef          	jal	ra,ffffffffc0205fa4 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0205476:	00093783          	ld	a5,0(s2)
ffffffffc020547a:	00003617          	auipc	a2,0x3
ffffffffc020547e:	13e60613          	addi	a2,a2,318 # ffffffffc02085b8 <default_pmm_manager+0x12a0>
ffffffffc0205482:	27a00593          	li	a1,634
ffffffffc0205486:	43d4                	lw	a3,4(a5)
ffffffffc0205488:	00003517          	auipc	a0,0x3
ffffffffc020548c:	3e050513          	addi	a0,a0,992 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205490:	ff5fa0ef          	jal	ra,ffffffffc0200484 <__panic>
        intr_enable();
ffffffffc0205494:	9c0fb0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0205498:	bfe9                	j	ffffffffc0205472 <do_exit+0xd4>
        panic("idleproc exit.\n");
ffffffffc020549a:	00003617          	auipc	a2,0x3
ffffffffc020549e:	0fe60613          	addi	a2,a2,254 # ffffffffc0208598 <default_pmm_manager+0x1280>
ffffffffc02054a2:	22b00593          	li	a1,555
ffffffffc02054a6:	00003517          	auipc	a0,0x3
ffffffffc02054aa:	3c250513          	addi	a0,a0,962 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc02054ae:	fd7fa0ef          	jal	ra,ffffffffc0200484 <__panic>
            exit_mmap(mm);
ffffffffc02054b2:	8526                	mv	a0,s1
ffffffffc02054b4:	f31fe0ef          	jal	ra,ffffffffc02043e4 <exit_mmap>
            put_pgdir(mm);
ffffffffc02054b8:	8526                	mv	a0,s1
ffffffffc02054ba:	8bdff0ef          	jal	ra,ffffffffc0204d76 <put_pgdir>
            mm_destroy(mm);
ffffffffc02054be:	8526                	mv	a0,s1
ffffffffc02054c0:	d85fe0ef          	jal	ra,ffffffffc0204244 <mm_destroy>
ffffffffc02054c4:	bf1d                	j	ffffffffc02053fa <do_exit+0x5c>
        panic("initproc exit.\n");
ffffffffc02054c6:	00003617          	auipc	a2,0x3
ffffffffc02054ca:	0e260613          	addi	a2,a2,226 # ffffffffc02085a8 <default_pmm_manager+0x1290>
ffffffffc02054ce:	22f00593          	li	a1,559
ffffffffc02054d2:	00003517          	auipc	a0,0x3
ffffffffc02054d6:	39650513          	addi	a0,a0,918 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc02054da:	fabfa0ef          	jal	ra,ffffffffc0200484 <__panic>
        intr_disable();
ffffffffc02054de:	97cfb0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc02054e2:	4a05                	li	s4,1
ffffffffc02054e4:	bf15                	j	ffffffffc0205418 <do_exit+0x7a>
            wakeup_proc(proc); //change proc to RUNNABLE
ffffffffc02054e6:	243000ef          	jal	ra,ffffffffc0205f28 <wakeup_proc>
ffffffffc02054ea:	b789                	j	ffffffffc020542c <do_exit+0x8e>

ffffffffc02054ec <do_wait.part.1>:
int do_wait(int pid, int *code_store)
ffffffffc02054ec:	7139                	addi	sp,sp,-64
ffffffffc02054ee:	e852                	sd	s4,16(sp)
        current->wait_state = WT_CHILD;
ffffffffc02054f0:	80000a37          	lui	s4,0x80000
int do_wait(int pid, int *code_store)
ffffffffc02054f4:	f426                	sd	s1,40(sp)
ffffffffc02054f6:	f04a                	sd	s2,32(sp)
ffffffffc02054f8:	ec4e                	sd	s3,24(sp)
ffffffffc02054fa:	e456                	sd	s5,8(sp)
ffffffffc02054fc:	e05a                	sd	s6,0(sp)
ffffffffc02054fe:	fc06                	sd	ra,56(sp)
ffffffffc0205500:	f822                	sd	s0,48(sp)
ffffffffc0205502:	89aa                	mv	s3,a0
ffffffffc0205504:	8b2e                	mv	s6,a1
        proc = current->cptr;
ffffffffc0205506:	000a7917          	auipc	s2,0xa7
ffffffffc020550a:	faa90913          	addi	s2,s2,-86 # ffffffffc02ac4b0 <current>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020550e:	448d                	li	s1,3
        current->state = PROC_SLEEPING;
ffffffffc0205510:	4a85                	li	s5,1
        current->wait_state = WT_CHILD;
ffffffffc0205512:	2a05                	addiw	s4,s4,1
    if (pid != 0)
ffffffffc0205514:	02098f63          	beqz	s3,ffffffffc0205552 <do_wait.part.1+0x66>
        proc = find_proc(pid);
ffffffffc0205518:	854e                	mv	a0,s3
ffffffffc020551a:	9fdff0ef          	jal	ra,ffffffffc0204f16 <find_proc>
ffffffffc020551e:	842a                	mv	s0,a0
        if (proc != NULL && proc->parent == current)
ffffffffc0205520:	12050063          	beqz	a0,ffffffffc0205640 <do_wait.part.1+0x154>
ffffffffc0205524:	00093703          	ld	a4,0(s2)
ffffffffc0205528:	711c                	ld	a5,32(a0)
ffffffffc020552a:	10e79b63          	bne	a5,a4,ffffffffc0205640 <do_wait.part.1+0x154>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020552e:	411c                	lw	a5,0(a0)
ffffffffc0205530:	02978c63          	beq	a5,s1,ffffffffc0205568 <do_wait.part.1+0x7c>
        current->state = PROC_SLEEPING;
ffffffffc0205534:	01572023          	sw	s5,0(a4)
        current->wait_state = WT_CHILD;
ffffffffc0205538:	0f472623          	sw	s4,236(a4)
        schedule();
ffffffffc020553c:	269000ef          	jal	ra,ffffffffc0205fa4 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0205540:	00093783          	ld	a5,0(s2)
ffffffffc0205544:	0b07a783          	lw	a5,176(a5)
ffffffffc0205548:	8b85                	andi	a5,a5,1
ffffffffc020554a:	d7e9                	beqz	a5,ffffffffc0205514 <do_wait.part.1+0x28>
            do_exit(-E_KILLED);
ffffffffc020554c:	555d                	li	a0,-9
ffffffffc020554e:	e51ff0ef          	jal	ra,ffffffffc020539e <do_exit>
        proc = current->cptr;
ffffffffc0205552:	00093703          	ld	a4,0(s2)
ffffffffc0205556:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0205558:	e409                	bnez	s0,ffffffffc0205562 <do_wait.part.1+0x76>
ffffffffc020555a:	a0dd                	j	ffffffffc0205640 <do_wait.part.1+0x154>
ffffffffc020555c:	10043403          	ld	s0,256(s0)
ffffffffc0205560:	d871                	beqz	s0,ffffffffc0205534 <do_wait.part.1+0x48>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0205562:	401c                	lw	a5,0(s0)
ffffffffc0205564:	fe979ce3          	bne	a5,s1,ffffffffc020555c <do_wait.part.1+0x70>
    if (proc == idleproc || proc == initproc)
ffffffffc0205568:	000a7797          	auipc	a5,0xa7
ffffffffc020556c:	f5078793          	addi	a5,a5,-176 # ffffffffc02ac4b8 <idleproc>
ffffffffc0205570:	639c                	ld	a5,0(a5)
ffffffffc0205572:	0c878d63          	beq	a5,s0,ffffffffc020564c <do_wait.part.1+0x160>
ffffffffc0205576:	000a7797          	auipc	a5,0xa7
ffffffffc020557a:	f4a78793          	addi	a5,a5,-182 # ffffffffc02ac4c0 <initproc>
ffffffffc020557e:	639c                	ld	a5,0(a5)
ffffffffc0205580:	0cf40663          	beq	s0,a5,ffffffffc020564c <do_wait.part.1+0x160>
    if (code_store != NULL)
ffffffffc0205584:	000b0663          	beqz	s6,ffffffffc0205590 <do_wait.part.1+0xa4>
        *code_store = proc->exit_code;
ffffffffc0205588:	0e842783          	lw	a5,232(s0)
ffffffffc020558c:	00fb2023          	sw	a5,0(s6)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205590:	100027f3          	csrr	a5,sstatus
ffffffffc0205594:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205596:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205598:	e7d5                	bnez	a5,ffffffffc0205644 <do_wait.part.1+0x158>
    __list_del(listelm->prev, listelm->next);
ffffffffc020559a:	6c70                	ld	a2,216(s0)
ffffffffc020559c:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc020559e:	10043703          	ld	a4,256(s0)
ffffffffc02055a2:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02055a4:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02055a6:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02055a8:	6470                	ld	a2,200(s0)
ffffffffc02055aa:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02055ac:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02055ae:	e290                	sd	a2,0(a3)
ffffffffc02055b0:	c319                	beqz	a4,ffffffffc02055b6 <do_wait.part.1+0xca>
        proc->optr->yptr = proc->yptr;
ffffffffc02055b2:	ff7c                	sd	a5,248(a4)
ffffffffc02055b4:	7c7c                	ld	a5,248(s0)
    if (proc->yptr != NULL)
ffffffffc02055b6:	c3d1                	beqz	a5,ffffffffc020563a <do_wait.part.1+0x14e>
        proc->yptr->optr = proc->optr;
ffffffffc02055b8:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc02055bc:	000a7797          	auipc	a5,0xa7
ffffffffc02055c0:	f0c78793          	addi	a5,a5,-244 # ffffffffc02ac4c8 <nr_process>
ffffffffc02055c4:	439c                	lw	a5,0(a5)
ffffffffc02055c6:	37fd                	addiw	a5,a5,-1
ffffffffc02055c8:	000a7717          	auipc	a4,0xa7
ffffffffc02055cc:	f0f72023          	sw	a5,-256(a4) # ffffffffc02ac4c8 <nr_process>
    if (flag) {
ffffffffc02055d0:	e1b5                	bnez	a1,ffffffffc0205634 <do_wait.part.1+0x148>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02055d2:	6814                	ld	a3,16(s0)
ffffffffc02055d4:	c02007b7          	lui	a5,0xc0200
ffffffffc02055d8:	0af6e263          	bltu	a3,a5,ffffffffc020567c <do_wait.part.1+0x190>
ffffffffc02055dc:	000a7797          	auipc	a5,0xa7
ffffffffc02055e0:	f1c78793          	addi	a5,a5,-228 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc02055e4:	6398                	ld	a4,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc02055e6:	000a7797          	auipc	a5,0xa7
ffffffffc02055ea:	eb278793          	addi	a5,a5,-334 # ffffffffc02ac498 <npage>
ffffffffc02055ee:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc02055f0:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc02055f2:	82b1                	srli	a3,a3,0xc
ffffffffc02055f4:	06f6f863          	bleu	a5,a3,ffffffffc0205664 <do_wait.part.1+0x178>
    return &pages[PPN(pa) - nbase];
ffffffffc02055f8:	00003797          	auipc	a5,0x3
ffffffffc02055fc:	73878793          	addi	a5,a5,1848 # ffffffffc0208d30 <nbase>
ffffffffc0205600:	639c                	ld	a5,0(a5)
ffffffffc0205602:	000a7717          	auipc	a4,0xa7
ffffffffc0205606:	f0670713          	addi	a4,a4,-250 # ffffffffc02ac508 <pages>
ffffffffc020560a:	6308                	ld	a0,0(a4)
ffffffffc020560c:	8e9d                	sub	a3,a3,a5
ffffffffc020560e:	069a                	slli	a3,a3,0x6
ffffffffc0205610:	9536                	add	a0,a0,a3
ffffffffc0205612:	4589                	li	a1,2
ffffffffc0205614:	8bffc0ef          	jal	ra,ffffffffc0201ed2 <free_pages>
    kfree(proc);
ffffffffc0205618:	8522                	mv	a0,s0
ffffffffc020561a:	ef0fc0ef          	jal	ra,ffffffffc0201d0a <kfree>
    return 0;
ffffffffc020561e:	4501                	li	a0,0
}
ffffffffc0205620:	70e2                	ld	ra,56(sp)
ffffffffc0205622:	7442                	ld	s0,48(sp)
ffffffffc0205624:	74a2                	ld	s1,40(sp)
ffffffffc0205626:	7902                	ld	s2,32(sp)
ffffffffc0205628:	69e2                	ld	s3,24(sp)
ffffffffc020562a:	6a42                	ld	s4,16(sp)
ffffffffc020562c:	6aa2                	ld	s5,8(sp)
ffffffffc020562e:	6b02                	ld	s6,0(sp)
ffffffffc0205630:	6121                	addi	sp,sp,64
ffffffffc0205632:	8082                	ret
        intr_enable();
ffffffffc0205634:	820fb0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0205638:	bf69                	j	ffffffffc02055d2 <do_wait.part.1+0xe6>
        proc->parent->cptr = proc->optr;
ffffffffc020563a:	701c                	ld	a5,32(s0)
ffffffffc020563c:	fbf8                	sd	a4,240(a5)
ffffffffc020563e:	bfbd                	j	ffffffffc02055bc <do_wait.part.1+0xd0>
    return -E_BAD_PROC;
ffffffffc0205640:	5579                	li	a0,-2
ffffffffc0205642:	bff9                	j	ffffffffc0205620 <do_wait.part.1+0x134>
        intr_disable();
ffffffffc0205644:	816fb0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc0205648:	4585                	li	a1,1
ffffffffc020564a:	bf81                	j	ffffffffc020559a <do_wait.part.1+0xae>
        panic("wait idleproc or initproc.\n");
ffffffffc020564c:	00003617          	auipc	a2,0x3
ffffffffc0205650:	fd460613          	addi	a2,a2,-44 # ffffffffc0208620 <default_pmm_manager+0x1308>
ffffffffc0205654:	3ca00593          	li	a1,970
ffffffffc0205658:	00003517          	auipc	a0,0x3
ffffffffc020565c:	21050513          	addi	a0,a0,528 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205660:	e25fa0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0205664:	00002617          	auipc	a2,0x2
ffffffffc0205668:	d6460613          	addi	a2,a2,-668 # ffffffffc02073c8 <default_pmm_manager+0xb0>
ffffffffc020566c:	06200593          	li	a1,98
ffffffffc0205670:	00002517          	auipc	a0,0x2
ffffffffc0205674:	d2050513          	addi	a0,a0,-736 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0205678:	e0dfa0ef          	jal	ra,ffffffffc0200484 <__panic>
    return pa2page(PADDR(kva));
ffffffffc020567c:	00002617          	auipc	a2,0x2
ffffffffc0205680:	d2460613          	addi	a2,a2,-732 # ffffffffc02073a0 <default_pmm_manager+0x88>
ffffffffc0205684:	06e00593          	li	a1,110
ffffffffc0205688:	00002517          	auipc	a0,0x2
ffffffffc020568c:	d0850513          	addi	a0,a0,-760 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0205690:	df5fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205694 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0205694:	1141                	addi	sp,sp,-16
ffffffffc0205696:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0205698:	881fc0ef          	jal	ra,ffffffffc0201f18 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc020569c:	daefc0ef          	jal	ra,ffffffffc0201c4a <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02056a0:	4601                	li	a2,0
ffffffffc02056a2:	4581                	li	a1,0
ffffffffc02056a4:	fffff517          	auipc	a0,0xfffff
ffffffffc02056a8:	65050513          	addi	a0,a0,1616 # ffffffffc0204cf4 <user_main>
ffffffffc02056ac:	ca3ff0ef          	jal	ra,ffffffffc020534e <kernel_thread>
    if (pid <= 0)
ffffffffc02056b0:	00a04563          	bgtz	a0,ffffffffc02056ba <init_main+0x26>
ffffffffc02056b4:	a841                	j	ffffffffc0205744 <init_main+0xb0>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02056b6:	0ef000ef          	jal	ra,ffffffffc0205fa4 <schedule>
    if (code_store != NULL)
ffffffffc02056ba:	4581                	li	a1,0
ffffffffc02056bc:	4501                	li	a0,0
ffffffffc02056be:	e2fff0ef          	jal	ra,ffffffffc02054ec <do_wait.part.1>
    while (do_wait(0, NULL) == 0)
ffffffffc02056c2:	d975                	beqz	a0,ffffffffc02056b6 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02056c4:	00003517          	auipc	a0,0x3
ffffffffc02056c8:	f9c50513          	addi	a0,a0,-100 # ffffffffc0208660 <default_pmm_manager+0x1348>
ffffffffc02056cc:	ac3fa0ef          	jal	ra,ffffffffc020018e <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02056d0:	000a7797          	auipc	a5,0xa7
ffffffffc02056d4:	df078793          	addi	a5,a5,-528 # ffffffffc02ac4c0 <initproc>
ffffffffc02056d8:	639c                	ld	a5,0(a5)
ffffffffc02056da:	7bf8                	ld	a4,240(a5)
ffffffffc02056dc:	e721                	bnez	a4,ffffffffc0205724 <init_main+0x90>
ffffffffc02056de:	7ff8                	ld	a4,248(a5)
ffffffffc02056e0:	e331                	bnez	a4,ffffffffc0205724 <init_main+0x90>
ffffffffc02056e2:	1007b703          	ld	a4,256(a5)
ffffffffc02056e6:	ef1d                	bnez	a4,ffffffffc0205724 <init_main+0x90>
    assert(nr_process == 2);
ffffffffc02056e8:	000a7717          	auipc	a4,0xa7
ffffffffc02056ec:	de070713          	addi	a4,a4,-544 # ffffffffc02ac4c8 <nr_process>
ffffffffc02056f0:	4314                	lw	a3,0(a4)
ffffffffc02056f2:	4709                	li	a4,2
ffffffffc02056f4:	0ae69463          	bne	a3,a4,ffffffffc020579c <init_main+0x108>
    return listelm->next;
ffffffffc02056f8:	000a7697          	auipc	a3,0xa7
ffffffffc02056fc:	ef868693          	addi	a3,a3,-264 # ffffffffc02ac5f0 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0205700:	6698                	ld	a4,8(a3)
ffffffffc0205702:	0c878793          	addi	a5,a5,200
ffffffffc0205706:	06f71b63          	bne	a4,a5,ffffffffc020577c <init_main+0xe8>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020570a:	629c                	ld	a5,0(a3)
ffffffffc020570c:	04f71863          	bne	a4,a5,ffffffffc020575c <init_main+0xc8>

    cprintf("init check memory pass.\n");
ffffffffc0205710:	00003517          	auipc	a0,0x3
ffffffffc0205714:	03850513          	addi	a0,a0,56 # ffffffffc0208748 <default_pmm_manager+0x1430>
ffffffffc0205718:	a77fa0ef          	jal	ra,ffffffffc020018e <cprintf>
    return 0;
}
ffffffffc020571c:	60a2                	ld	ra,8(sp)
ffffffffc020571e:	4501                	li	a0,0
ffffffffc0205720:	0141                	addi	sp,sp,16
ffffffffc0205722:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0205724:	00003697          	auipc	a3,0x3
ffffffffc0205728:	f6468693          	addi	a3,a3,-156 # ffffffffc0208688 <default_pmm_manager+0x1370>
ffffffffc020572c:	00001617          	auipc	a2,0x1
ffffffffc0205730:	4a460613          	addi	a2,a2,1188 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0205734:	44100593          	li	a1,1089
ffffffffc0205738:	00003517          	auipc	a0,0x3
ffffffffc020573c:	13050513          	addi	a0,a0,304 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205740:	d45fa0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("create user_main failed.\n");
ffffffffc0205744:	00003617          	auipc	a2,0x3
ffffffffc0205748:	efc60613          	addi	a2,a2,-260 # ffffffffc0208640 <default_pmm_manager+0x1328>
ffffffffc020574c:	43800593          	li	a1,1080
ffffffffc0205750:	00003517          	auipc	a0,0x3
ffffffffc0205754:	11850513          	addi	a0,a0,280 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205758:	d2dfa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020575c:	00003697          	auipc	a3,0x3
ffffffffc0205760:	fbc68693          	addi	a3,a3,-68 # ffffffffc0208718 <default_pmm_manager+0x1400>
ffffffffc0205764:	00001617          	auipc	a2,0x1
ffffffffc0205768:	46c60613          	addi	a2,a2,1132 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020576c:	44400593          	li	a1,1092
ffffffffc0205770:	00003517          	auipc	a0,0x3
ffffffffc0205774:	0f850513          	addi	a0,a0,248 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205778:	d0dfa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020577c:	00003697          	auipc	a3,0x3
ffffffffc0205780:	f6c68693          	addi	a3,a3,-148 # ffffffffc02086e8 <default_pmm_manager+0x13d0>
ffffffffc0205784:	00001617          	auipc	a2,0x1
ffffffffc0205788:	44c60613          	addi	a2,a2,1100 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc020578c:	44300593          	li	a1,1091
ffffffffc0205790:	00003517          	auipc	a0,0x3
ffffffffc0205794:	0d850513          	addi	a0,a0,216 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205798:	cedfa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_process == 2);
ffffffffc020579c:	00003697          	auipc	a3,0x3
ffffffffc02057a0:	f3c68693          	addi	a3,a3,-196 # ffffffffc02086d8 <default_pmm_manager+0x13c0>
ffffffffc02057a4:	00001617          	auipc	a2,0x1
ffffffffc02057a8:	42c60613          	addi	a2,a2,1068 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc02057ac:	44200593          	li	a1,1090
ffffffffc02057b0:	00003517          	auipc	a0,0x3
ffffffffc02057b4:	0b850513          	addi	a0,a0,184 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc02057b8:	ccdfa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02057bc <do_execve>:
{
ffffffffc02057bc:	7135                	addi	sp,sp,-160
ffffffffc02057be:	f8d2                	sd	s4,112(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02057c0:	000a7a17          	auipc	s4,0xa7
ffffffffc02057c4:	cf0a0a13          	addi	s4,s4,-784 # ffffffffc02ac4b0 <current>
ffffffffc02057c8:	000a3783          	ld	a5,0(s4)
{
ffffffffc02057cc:	e14a                	sd	s2,128(sp)
ffffffffc02057ce:	e922                	sd	s0,144(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02057d0:	0287b903          	ld	s2,40(a5)
{
ffffffffc02057d4:	fcce                	sd	s3,120(sp)
ffffffffc02057d6:	f0da                	sd	s6,96(sp)
ffffffffc02057d8:	89aa                	mv	s3,a0
ffffffffc02057da:	842e                	mv	s0,a1
ffffffffc02057dc:	8b32                	mv	s6,a2
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02057de:	4681                	li	a3,0
ffffffffc02057e0:	862e                	mv	a2,a1
ffffffffc02057e2:	85aa                	mv	a1,a0
ffffffffc02057e4:	854a                	mv	a0,s2
{
ffffffffc02057e6:	ed06                	sd	ra,152(sp)
ffffffffc02057e8:	e526                	sd	s1,136(sp)
ffffffffc02057ea:	f4d6                	sd	s5,104(sp)
ffffffffc02057ec:	ecde                	sd	s7,88(sp)
ffffffffc02057ee:	e8e2                	sd	s8,80(sp)
ffffffffc02057f0:	e4e6                	sd	s9,72(sp)
ffffffffc02057f2:	e0ea                	sd	s10,64(sp)
ffffffffc02057f4:	fc6e                	sd	s11,56(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02057f6:	ab2ff0ef          	jal	ra,ffffffffc0204aa8 <user_mem_check>
ffffffffc02057fa:	40050663          	beqz	a0,ffffffffc0205c06 <do_execve+0x44a>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02057fe:	4641                	li	a2,16
ffffffffc0205800:	4581                	li	a1,0
ffffffffc0205802:	1008                	addi	a0,sp,32
ffffffffc0205804:	5c5000ef          	jal	ra,ffffffffc02065c8 <memset>
    memcpy(local_name, name, len);
ffffffffc0205808:	47bd                	li	a5,15
ffffffffc020580a:	8622                	mv	a2,s0
ffffffffc020580c:	0687ee63          	bltu	a5,s0,ffffffffc0205888 <do_execve+0xcc>
ffffffffc0205810:	85ce                	mv	a1,s3
ffffffffc0205812:	1008                	addi	a0,sp,32
ffffffffc0205814:	5c7000ef          	jal	ra,ffffffffc02065da <memcpy>
    if (mm != NULL)
ffffffffc0205818:	06090f63          	beqz	s2,ffffffffc0205896 <do_execve+0xda>
        cputs("mm != NULL");
ffffffffc020581c:	00002517          	auipc	a0,0x2
ffffffffc0205820:	2f450513          	addi	a0,a0,756 # ffffffffc0207b10 <default_pmm_manager+0x7f8>
ffffffffc0205824:	9a3fa0ef          	jal	ra,ffffffffc02001c6 <cputs>
        lcr3(boot_cr3);
ffffffffc0205828:	000a7797          	auipc	a5,0xa7
ffffffffc020582c:	cd878793          	addi	a5,a5,-808 # ffffffffc02ac500 <boot_cr3>
ffffffffc0205830:	639c                	ld	a5,0(a5)
ffffffffc0205832:	577d                	li	a4,-1
ffffffffc0205834:	177e                	slli	a4,a4,0x3f
ffffffffc0205836:	83b1                	srli	a5,a5,0xc
ffffffffc0205838:	8fd9                	or	a5,a5,a4
ffffffffc020583a:	18079073          	csrw	satp,a5
ffffffffc020583e:	03092783          	lw	a5,48(s2)
ffffffffc0205842:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205846:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc020584a:	28070d63          	beqz	a4,ffffffffc0205ae4 <do_execve+0x328>
        current->mm = NULL;
ffffffffc020584e:	000a3783          	ld	a5,0(s4)
ffffffffc0205852:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0205856:	869fe0ef          	jal	ra,ffffffffc02040be <mm_create>
ffffffffc020585a:	892a                	mv	s2,a0
ffffffffc020585c:	c135                	beqz	a0,ffffffffc02058c0 <do_execve+0x104>
    if (setup_pgdir(mm) != 0)
ffffffffc020585e:	d96ff0ef          	jal	ra,ffffffffc0204df4 <setup_pgdir>
ffffffffc0205862:	e931                	bnez	a0,ffffffffc02058b6 <do_execve+0xfa>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0205864:	000b2703          	lw	a4,0(s6)
ffffffffc0205868:	464c47b7          	lui	a5,0x464c4
ffffffffc020586c:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9aff>
ffffffffc0205870:	04f70a63          	beq	a4,a5,ffffffffc02058c4 <do_execve+0x108>
    put_pgdir(mm);
ffffffffc0205874:	854a                	mv	a0,s2
ffffffffc0205876:	d00ff0ef          	jal	ra,ffffffffc0204d76 <put_pgdir>
    mm_destroy(mm);
ffffffffc020587a:	854a                	mv	a0,s2
ffffffffc020587c:	9c9fe0ef          	jal	ra,ffffffffc0204244 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0205880:	59e1                	li	s3,-8
    do_exit(ret);
ffffffffc0205882:	854e                	mv	a0,s3
ffffffffc0205884:	b1bff0ef          	jal	ra,ffffffffc020539e <do_exit>
    memcpy(local_name, name, len);
ffffffffc0205888:	463d                	li	a2,15
ffffffffc020588a:	85ce                	mv	a1,s3
ffffffffc020588c:	1008                	addi	a0,sp,32
ffffffffc020588e:	54d000ef          	jal	ra,ffffffffc02065da <memcpy>
    if (mm != NULL)
ffffffffc0205892:	f80915e3          	bnez	s2,ffffffffc020581c <do_execve+0x60>
    if (current->mm != NULL)
ffffffffc0205896:	000a3783          	ld	a5,0(s4)
ffffffffc020589a:	779c                	ld	a5,40(a5)
ffffffffc020589c:	dfcd                	beqz	a5,ffffffffc0205856 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc020589e:	00003617          	auipc	a2,0x3
ffffffffc02058a2:	b7260613          	addi	a2,a2,-1166 # ffffffffc0208410 <default_pmm_manager+0x10f8>
ffffffffc02058a6:	28600593          	li	a1,646
ffffffffc02058aa:	00003517          	auipc	a0,0x3
ffffffffc02058ae:	fbe50513          	addi	a0,a0,-66 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc02058b2:	bd3fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    mm_destroy(mm);
ffffffffc02058b6:	854a                	mv	a0,s2
ffffffffc02058b8:	98dfe0ef          	jal	ra,ffffffffc0204244 <mm_destroy>
    int ret = -E_NO_MEM;
ffffffffc02058bc:	59f1                	li	s3,-4
ffffffffc02058be:	b7d1                	j	ffffffffc0205882 <do_execve+0xc6>
ffffffffc02058c0:	59f1                	li	s3,-4
ffffffffc02058c2:	b7c1                	j	ffffffffc0205882 <do_execve+0xc6>
    struct proghdr *ph_end = ph + elf->e_phnum; // 第一个段的头部地址
ffffffffc02058c4:	038b5703          	lhu	a4,56(s6)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02058c8:	020b3403          	ld	s0,32(s6)
    struct proghdr *ph_end = ph + elf->e_phnum; // 第一个段的头部地址
ffffffffc02058cc:	00371793          	slli	a5,a4,0x3
ffffffffc02058d0:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02058d2:	945a                	add	s0,s0,s6
    struct proghdr *ph_end = ph + elf->e_phnum; // 第一个段的头部地址
ffffffffc02058d4:	078e                	slli	a5,a5,0x3
ffffffffc02058d6:	97a2                	add	a5,a5,s0
ffffffffc02058d8:	ec3e                	sd	a5,24(sp)
    for (; ph < ph_end; ph++)
ffffffffc02058da:	02f47b63          	bleu	a5,s0,ffffffffc0205910 <do_execve+0x154>
    return KADDR(page2pa(page));
ffffffffc02058de:	5bfd                	li	s7,-1
ffffffffc02058e0:	00cbd793          	srli	a5,s7,0xc
    return page - pages + nbase;
ffffffffc02058e4:	000a7d97          	auipc	s11,0xa7
ffffffffc02058e8:	c24d8d93          	addi	s11,s11,-988 # ffffffffc02ac508 <pages>
ffffffffc02058ec:	00003d17          	auipc	s10,0x3
ffffffffc02058f0:	444d0d13          	addi	s10,s10,1092 # ffffffffc0208d30 <nbase>
    return KADDR(page2pa(page));
ffffffffc02058f4:	e43e                	sd	a5,8(sp)
ffffffffc02058f6:	000a7c97          	auipc	s9,0xa7
ffffffffc02058fa:	ba2c8c93          	addi	s9,s9,-1118 # ffffffffc02ac498 <npage>
        if (ph->p_type != ELF_PT_LOAD) //判断是否为段头
ffffffffc02058fe:	4018                	lw	a4,0(s0)
ffffffffc0205900:	4785                	li	a5,1
ffffffffc0205902:	0ef70f63          	beq	a4,a5,ffffffffc0205a00 <do_execve+0x244>
    for (; ph < ph_end; ph++)
ffffffffc0205906:	67e2                	ld	a5,24(sp)
ffffffffc0205908:	03840413          	addi	s0,s0,56
ffffffffc020590c:	fef469e3          	bltu	s0,a5,ffffffffc02058fe <do_execve+0x142>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0205910:	4701                	li	a4,0
ffffffffc0205912:	46ad                	li	a3,11
ffffffffc0205914:	00100637          	lui	a2,0x100
ffffffffc0205918:	7ff005b7          	lui	a1,0x7ff00
ffffffffc020591c:	854a                	mv	a0,s2
ffffffffc020591e:	979fe0ef          	jal	ra,ffffffffc0204296 <mm_map>
ffffffffc0205922:	89aa                	mv	s3,a0
ffffffffc0205924:	1a051663          	bnez	a0,ffffffffc0205ad0 <do_execve+0x314>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0205928:	01893503          	ld	a0,24(s2)
ffffffffc020592c:	467d                	li	a2,31
ffffffffc020592e:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0205932:	9bffd0ef          	jal	ra,ffffffffc02032f0 <pgdir_alloc_page>
ffffffffc0205936:	36050463          	beqz	a0,ffffffffc0205c9e <do_execve+0x4e2>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc020593a:	01893503          	ld	a0,24(s2)
ffffffffc020593e:	467d                	li	a2,31
ffffffffc0205940:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0205944:	9adfd0ef          	jal	ra,ffffffffc02032f0 <pgdir_alloc_page>
ffffffffc0205948:	32050b63          	beqz	a0,ffffffffc0205c7e <do_execve+0x4c2>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc020594c:	01893503          	ld	a0,24(s2)
ffffffffc0205950:	467d                	li	a2,31
ffffffffc0205952:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0205956:	99bfd0ef          	jal	ra,ffffffffc02032f0 <pgdir_alloc_page>
ffffffffc020595a:	30050263          	beqz	a0,ffffffffc0205c5e <do_execve+0x4a2>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc020595e:	01893503          	ld	a0,24(s2)
ffffffffc0205962:	467d                	li	a2,31
ffffffffc0205964:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0205968:	989fd0ef          	jal	ra,ffffffffc02032f0 <pgdir_alloc_page>
ffffffffc020596c:	2c050963          	beqz	a0,ffffffffc0205c3e <do_execve+0x482>
    mm->mm_count += 1;
ffffffffc0205970:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0205974:	000a3603          	ld	a2,0(s4)
    current->cr3 = PADDR(mm->pgdir); 
ffffffffc0205978:	01893683          	ld	a3,24(s2)
ffffffffc020597c:	2785                	addiw	a5,a5,1
ffffffffc020597e:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0205982:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_exit_out_size+0xf55a8>
    current->cr3 = PADDR(mm->pgdir); 
ffffffffc0205986:	c02007b7          	lui	a5,0xc0200
ffffffffc020598a:	28f6ee63          	bltu	a3,a5,ffffffffc0205c26 <do_execve+0x46a>
ffffffffc020598e:	000a7797          	auipc	a5,0xa7
ffffffffc0205992:	b6a78793          	addi	a5,a5,-1174 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc0205996:	639c                	ld	a5,0(a5)
ffffffffc0205998:	577d                	li	a4,-1
ffffffffc020599a:	177e                	slli	a4,a4,0x3f
ffffffffc020599c:	8e9d                	sub	a3,a3,a5
ffffffffc020599e:	00c6d793          	srli	a5,a3,0xc
ffffffffc02059a2:	f654                	sd	a3,168(a2)
ffffffffc02059a4:	8fd9                	or	a5,a5,a4
ffffffffc02059a6:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc02059aa:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02059ac:	4581                	li	a1,0
ffffffffc02059ae:	12000613          	li	a2,288
ffffffffc02059b2:	8522                	mv	a0,s0
ffffffffc02059b4:	415000ef          	jal	ra,ffffffffc02065c8 <memset>
    tf->epc = elf->e_entry; //(ELF文件头中标注的)入口点的虚拟地址
ffffffffc02059b8:	018b3703          	ld	a4,24(s6)
    tf->gpr.sp = USTACKTOP; // 用户栈栈顶
ffffffffc02059bc:	4785                	li	a5,1
ffffffffc02059be:	07fe                	slli	a5,a5,0x1f
ffffffffc02059c0:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry; //(ELF文件头中标注的)入口点的虚拟地址
ffffffffc02059c2:	10e43423          	sd	a4,264(s0)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc02059c6:	100027f3          	csrr	a5,sstatus
ffffffffc02059ca:	edf7f793          	andi	a5,a5,-289
    set_proc_name(current, local_name);
ffffffffc02059ce:	000a3503          	ld	a0,0(s4)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc02059d2:	0207e793          	ori	a5,a5,32
ffffffffc02059d6:	10f43023          	sd	a5,256(s0)
    set_proc_name(current, local_name);
ffffffffc02059da:	100c                	addi	a1,sp,32
ffffffffc02059dc:	ca4ff0ef          	jal	ra,ffffffffc0204e80 <set_proc_name>
}
ffffffffc02059e0:	60ea                	ld	ra,152(sp)
ffffffffc02059e2:	644a                	ld	s0,144(sp)
ffffffffc02059e4:	854e                	mv	a0,s3
ffffffffc02059e6:	64aa                	ld	s1,136(sp)
ffffffffc02059e8:	690a                	ld	s2,128(sp)
ffffffffc02059ea:	79e6                	ld	s3,120(sp)
ffffffffc02059ec:	7a46                	ld	s4,112(sp)
ffffffffc02059ee:	7aa6                	ld	s5,104(sp)
ffffffffc02059f0:	7b06                	ld	s6,96(sp)
ffffffffc02059f2:	6be6                	ld	s7,88(sp)
ffffffffc02059f4:	6c46                	ld	s8,80(sp)
ffffffffc02059f6:	6ca6                	ld	s9,72(sp)
ffffffffc02059f8:	6d06                	ld	s10,64(sp)
ffffffffc02059fa:	7de2                	ld	s11,56(sp)
ffffffffc02059fc:	610d                	addi	sp,sp,160
ffffffffc02059fe:	8082                	ret
        if (ph->p_filesz > ph->p_memsz) //段在文件中的大小  段在内存中的大小
ffffffffc0205a00:	7410                	ld	a2,40(s0)
ffffffffc0205a02:	701c                	ld	a5,32(s0)
ffffffffc0205a04:	20f66363          	bltu	a2,a5,ffffffffc0205c0a <do_execve+0x44e>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0205a08:	405c                	lw	a5,4(s0)
            vm_flags |= VM_EXEC;
ffffffffc0205a0a:	0017f693          	andi	a3,a5,1
        if (ph->p_flags & ELF_PF_W)
ffffffffc0205a0e:	0027f713          	andi	a4,a5,2
            vm_flags |= VM_EXEC;
ffffffffc0205a12:	068a                	slli	a3,a3,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc0205a14:	0e071263          	bnez	a4,ffffffffc0205af8 <do_execve+0x33c>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205a18:	4745                	li	a4,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0205a1a:	8b91                	andi	a5,a5,4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205a1c:	e03a                	sd	a4,0(sp)
        if (ph->p_flags & ELF_PF_R)
ffffffffc0205a1e:	c789                	beqz	a5,ffffffffc0205a28 <do_execve+0x26c>
            perm |= PTE_R;
ffffffffc0205a20:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0205a22:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0205a26:	e03e                	sd	a5,0(sp)
        if (vm_flags & VM_WRITE)
ffffffffc0205a28:	0026f793          	andi	a5,a3,2
ffffffffc0205a2c:	efe1                	bnez	a5,ffffffffc0205b04 <do_execve+0x348>
        if (vm_flags & VM_EXEC)
ffffffffc0205a2e:	0046f793          	andi	a5,a3,4
ffffffffc0205a32:	c789                	beqz	a5,ffffffffc0205a3c <do_execve+0x280>
            perm |= PTE_X;
ffffffffc0205a34:	6782                	ld	a5,0(sp)
ffffffffc0205a36:	0087e793          	ori	a5,a5,8
ffffffffc0205a3a:	e03e                	sd	a5,0(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0205a3c:	680c                	ld	a1,16(s0)
ffffffffc0205a3e:	4701                	li	a4,0
ffffffffc0205a40:	854a                	mv	a0,s2
ffffffffc0205a42:	855fe0ef          	jal	ra,ffffffffc0204296 <mm_map>
ffffffffc0205a46:	89aa                	mv	s3,a0
ffffffffc0205a48:	e541                	bnez	a0,ffffffffc0205ad0 <do_execve+0x314>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a4a:	01043b83          	ld	s7,16(s0)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205a4e:	02043983          	ld	s3,32(s0)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a52:	00843a83          	ld	s5,8(s0)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a56:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205a58:	99de                	add	s3,s3,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a5a:	9ada                	add	s5,s5,s6
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a5c:	00fbfc33          	and	s8,s7,a5
        while (start < end)
ffffffffc0205a60:	053bef63          	bltu	s7,s3,ffffffffc0205abe <do_execve+0x302>
ffffffffc0205a64:	aa79                	j	ffffffffc0205c02 <do_execve+0x446>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205a66:	6785                	lui	a5,0x1
ffffffffc0205a68:	418b8533          	sub	a0,s7,s8
ffffffffc0205a6c:	9c3e                	add	s8,s8,a5
ffffffffc0205a6e:	417c0833          	sub	a6,s8,s7
            if (end < la)
ffffffffc0205a72:	0189f463          	bleu	s8,s3,ffffffffc0205a7a <do_execve+0x2be>
                size -= la - end;
ffffffffc0205a76:	41798833          	sub	a6,s3,s7
    return page - pages + nbase;
ffffffffc0205a7a:	000db683          	ld	a3,0(s11)
ffffffffc0205a7e:	000d3583          	ld	a1,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205a82:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205a84:	40d486b3          	sub	a3,s1,a3
ffffffffc0205a88:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205a8a:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0205a8e:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0205a90:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205a94:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205a96:	16c5fc63          	bleu	a2,a1,ffffffffc0205c0e <do_execve+0x452>
ffffffffc0205a9a:	000a7797          	auipc	a5,0xa7
ffffffffc0205a9e:	a5e78793          	addi	a5,a5,-1442 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc0205aa2:	0007b883          	ld	a7,0(a5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205aa6:	85d6                	mv	a1,s5
ffffffffc0205aa8:	8642                	mv	a2,a6
ffffffffc0205aaa:	96c6                	add	a3,a3,a7
ffffffffc0205aac:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0205aae:	9bc2                	add	s7,s7,a6
ffffffffc0205ab0:	e842                	sd	a6,16(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205ab2:	329000ef          	jal	ra,ffffffffc02065da <memcpy>
            start += size, from += size;
ffffffffc0205ab6:	6842                	ld	a6,16(sp)
ffffffffc0205ab8:	9ac2                	add	s5,s5,a6
        while (start < end)
ffffffffc0205aba:	053bf863          	bleu	s3,s7,ffffffffc0205b0a <do_execve+0x34e>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0205abe:	01893503          	ld	a0,24(s2)
ffffffffc0205ac2:	6602                	ld	a2,0(sp)
ffffffffc0205ac4:	85e2                	mv	a1,s8
ffffffffc0205ac6:	82bfd0ef          	jal	ra,ffffffffc02032f0 <pgdir_alloc_page>
ffffffffc0205aca:	84aa                	mv	s1,a0
ffffffffc0205acc:	fd49                	bnez	a0,ffffffffc0205a66 <do_execve+0x2aa>
        ret = -E_NO_MEM;
ffffffffc0205ace:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc0205ad0:	854a                	mv	a0,s2
ffffffffc0205ad2:	913fe0ef          	jal	ra,ffffffffc02043e4 <exit_mmap>
    put_pgdir(mm);
ffffffffc0205ad6:	854a                	mv	a0,s2
ffffffffc0205ad8:	a9eff0ef          	jal	ra,ffffffffc0204d76 <put_pgdir>
    mm_destroy(mm);
ffffffffc0205adc:	854a                	mv	a0,s2
ffffffffc0205ade:	f66fe0ef          	jal	ra,ffffffffc0204244 <mm_destroy>
    return ret;
ffffffffc0205ae2:	b345                	j	ffffffffc0205882 <do_execve+0xc6>
            exit_mmap(mm);
ffffffffc0205ae4:	854a                	mv	a0,s2
ffffffffc0205ae6:	8fffe0ef          	jal	ra,ffffffffc02043e4 <exit_mmap>
            put_pgdir(mm);
ffffffffc0205aea:	854a                	mv	a0,s2
ffffffffc0205aec:	a8aff0ef          	jal	ra,ffffffffc0204d76 <put_pgdir>
            mm_destroy(mm); //把进程当前占用的内存释放，之后重新分配内存
ffffffffc0205af0:	854a                	mv	a0,s2
ffffffffc0205af2:	f52fe0ef          	jal	ra,ffffffffc0204244 <mm_destroy>
ffffffffc0205af6:	bba1                	j	ffffffffc020584e <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0205af8:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0205afc:	8b91                	andi	a5,a5,4
            vm_flags |= VM_WRITE;
ffffffffc0205afe:	2681                	sext.w	a3,a3
        if (ph->p_flags & ELF_PF_R)
ffffffffc0205b00:	f20790e3          	bnez	a5,ffffffffc0205a20 <do_execve+0x264>
            perm |= (PTE_W | PTE_R);
ffffffffc0205b04:	47dd                	li	a5,23
ffffffffc0205b06:	e03e                	sd	a5,0(sp)
ffffffffc0205b08:	b71d                	j	ffffffffc0205a2e <do_execve+0x272>
ffffffffc0205b0a:	01043983          	ld	s3,16(s0)
        end = ph->p_va + ph->p_memsz;
ffffffffc0205b0e:	7414                	ld	a3,40(s0)
ffffffffc0205b10:	99b6                	add	s3,s3,a3
        if (start < la)
ffffffffc0205b12:	098bf163          	bleu	s8,s7,ffffffffc0205b94 <do_execve+0x3d8>
            if (start == end)
ffffffffc0205b16:	df7988e3          	beq	s3,s7,ffffffffc0205906 <do_execve+0x14a>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205b1a:	6505                	lui	a0,0x1
ffffffffc0205b1c:	955e                	add	a0,a0,s7
ffffffffc0205b1e:	41850533          	sub	a0,a0,s8
                size -= la - end;
ffffffffc0205b22:	41798ab3          	sub	s5,s3,s7
            if (end < la)
ffffffffc0205b26:	0d89fb63          	bleu	s8,s3,ffffffffc0205bfc <do_execve+0x440>
    return page - pages + nbase;
ffffffffc0205b2a:	000db683          	ld	a3,0(s11)
ffffffffc0205b2e:	000d3583          	ld	a1,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205b32:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205b34:	40d486b3          	sub	a3,s1,a3
ffffffffc0205b38:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205b3a:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0205b3e:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0205b40:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205b44:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205b46:	0cc5f463          	bleu	a2,a1,ffffffffc0205c0e <do_execve+0x452>
ffffffffc0205b4a:	000a7617          	auipc	a2,0xa7
ffffffffc0205b4e:	9ae60613          	addi	a2,a2,-1618 # ffffffffc02ac4f8 <va_pa_offset>
ffffffffc0205b52:	00063803          	ld	a6,0(a2)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205b56:	4581                	li	a1,0
ffffffffc0205b58:	8656                	mv	a2,s5
ffffffffc0205b5a:	96c2                	add	a3,a3,a6
ffffffffc0205b5c:	9536                	add	a0,a0,a3
ffffffffc0205b5e:	26b000ef          	jal	ra,ffffffffc02065c8 <memset>
            start += size;
ffffffffc0205b62:	017a8733          	add	a4,s5,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205b66:	0389f463          	bleu	s8,s3,ffffffffc0205b8e <do_execve+0x3d2>
ffffffffc0205b6a:	d8e98ee3          	beq	s3,a4,ffffffffc0205906 <do_execve+0x14a>
ffffffffc0205b6e:	00003697          	auipc	a3,0x3
ffffffffc0205b72:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0208438 <default_pmm_manager+0x1120>
ffffffffc0205b76:	00001617          	auipc	a2,0x1
ffffffffc0205b7a:	05a60613          	addi	a2,a2,90 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0205b7e:	30400593          	li	a1,772
ffffffffc0205b82:	00003517          	auipc	a0,0x3
ffffffffc0205b86:	ce650513          	addi	a0,a0,-794 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205b8a:	8fbfa0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0205b8e:	ff8710e3          	bne	a4,s8,ffffffffc0205b6e <do_execve+0x3b2>
ffffffffc0205b92:	8be2                	mv	s7,s8
ffffffffc0205b94:	000a7a97          	auipc	s5,0xa7
ffffffffc0205b98:	964a8a93          	addi	s5,s5,-1692 # ffffffffc02ac4f8 <va_pa_offset>
        while (start < end)
ffffffffc0205b9c:	053be763          	bltu	s7,s3,ffffffffc0205bea <do_execve+0x42e>
ffffffffc0205ba0:	b39d                	j	ffffffffc0205906 <do_execve+0x14a>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205ba2:	6785                	lui	a5,0x1
ffffffffc0205ba4:	418b8533          	sub	a0,s7,s8
ffffffffc0205ba8:	9c3e                	add	s8,s8,a5
ffffffffc0205baa:	417c0633          	sub	a2,s8,s7
            if (end < la)
ffffffffc0205bae:	0189f463          	bleu	s8,s3,ffffffffc0205bb6 <do_execve+0x3fa>
                size -= la - end;
ffffffffc0205bb2:	41798633          	sub	a2,s3,s7
    return page - pages + nbase;
ffffffffc0205bb6:	000db683          	ld	a3,0(s11)
ffffffffc0205bba:	000d3803          	ld	a6,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205bbe:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205bc0:	40d486b3          	sub	a3,s1,a3
ffffffffc0205bc4:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205bc6:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0205bca:	96c2                	add	a3,a3,a6
    return KADDR(page2pa(page));
ffffffffc0205bcc:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205bd0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205bd2:	02b87e63          	bleu	a1,a6,ffffffffc0205c0e <do_execve+0x452>
ffffffffc0205bd6:	000ab803          	ld	a6,0(s5)
            start += size;
ffffffffc0205bda:	9bb2                	add	s7,s7,a2
            memset(page2kva(page) + off, 0, size);
ffffffffc0205bdc:	4581                	li	a1,0
ffffffffc0205bde:	96c2                	add	a3,a3,a6
ffffffffc0205be0:	9536                	add	a0,a0,a3
ffffffffc0205be2:	1e7000ef          	jal	ra,ffffffffc02065c8 <memset>
        while (start < end)
ffffffffc0205be6:	d33bf0e3          	bleu	s3,s7,ffffffffc0205906 <do_execve+0x14a>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0205bea:	01893503          	ld	a0,24(s2)
ffffffffc0205bee:	6602                	ld	a2,0(sp)
ffffffffc0205bf0:	85e2                	mv	a1,s8
ffffffffc0205bf2:	efefd0ef          	jal	ra,ffffffffc02032f0 <pgdir_alloc_page>
ffffffffc0205bf6:	84aa                	mv	s1,a0
ffffffffc0205bf8:	f54d                	bnez	a0,ffffffffc0205ba2 <do_execve+0x3e6>
ffffffffc0205bfa:	bdd1                	j	ffffffffc0205ace <do_execve+0x312>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205bfc:	417c0ab3          	sub	s5,s8,s7
ffffffffc0205c00:	b72d                	j	ffffffffc0205b2a <do_execve+0x36e>
        while (start < end)
ffffffffc0205c02:	89de                	mv	s3,s7
ffffffffc0205c04:	b729                	j	ffffffffc0205b0e <do_execve+0x352>
        return -E_INVAL;
ffffffffc0205c06:	59f5                	li	s3,-3
ffffffffc0205c08:	bbe1                	j	ffffffffc02059e0 <do_execve+0x224>
            ret = -E_INVAL_ELF;
ffffffffc0205c0a:	59e1                	li	s3,-8
ffffffffc0205c0c:	b5d1                	j	ffffffffc0205ad0 <do_execve+0x314>
ffffffffc0205c0e:	00001617          	auipc	a2,0x1
ffffffffc0205c12:	75a60613          	addi	a2,a2,1882 # ffffffffc0207368 <default_pmm_manager+0x50>
ffffffffc0205c16:	06900593          	li	a1,105
ffffffffc0205c1a:	00001517          	auipc	a0,0x1
ffffffffc0205c1e:	77650513          	addi	a0,a0,1910 # ffffffffc0207390 <default_pmm_manager+0x78>
ffffffffc0205c22:	863fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    current->cr3 = PADDR(mm->pgdir); 
ffffffffc0205c26:	00001617          	auipc	a2,0x1
ffffffffc0205c2a:	77a60613          	addi	a2,a2,1914 # ffffffffc02073a0 <default_pmm_manager+0x88>
ffffffffc0205c2e:	32a00593          	li	a1,810
ffffffffc0205c32:	00003517          	auipc	a0,0x3
ffffffffc0205c36:	c3650513          	addi	a0,a0,-970 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205c3a:	84bfa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205c3e:	00003697          	auipc	a3,0x3
ffffffffc0205c42:	91268693          	addi	a3,a3,-1774 # ffffffffc0208550 <default_pmm_manager+0x1238>
ffffffffc0205c46:	00001617          	auipc	a2,0x1
ffffffffc0205c4a:	f8a60613          	addi	a2,a2,-118 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0205c4e:	32100593          	li	a1,801
ffffffffc0205c52:	00003517          	auipc	a0,0x3
ffffffffc0205c56:	c1650513          	addi	a0,a0,-1002 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205c5a:	82bfa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205c5e:	00003697          	auipc	a3,0x3
ffffffffc0205c62:	8aa68693          	addi	a3,a3,-1878 # ffffffffc0208508 <default_pmm_manager+0x11f0>
ffffffffc0205c66:	00001617          	auipc	a2,0x1
ffffffffc0205c6a:	f6a60613          	addi	a2,a2,-150 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0205c6e:	32000593          	li	a1,800
ffffffffc0205c72:	00003517          	auipc	a0,0x3
ffffffffc0205c76:	bf650513          	addi	a0,a0,-1034 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205c7a:	80bfa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205c7e:	00003697          	auipc	a3,0x3
ffffffffc0205c82:	84268693          	addi	a3,a3,-1982 # ffffffffc02084c0 <default_pmm_manager+0x11a8>
ffffffffc0205c86:	00001617          	auipc	a2,0x1
ffffffffc0205c8a:	f4a60613          	addi	a2,a2,-182 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0205c8e:	31f00593          	li	a1,799
ffffffffc0205c92:	00003517          	auipc	a0,0x3
ffffffffc0205c96:	bd650513          	addi	a0,a0,-1066 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205c9a:	feafa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0205c9e:	00002697          	auipc	a3,0x2
ffffffffc0205ca2:	7da68693          	addi	a3,a3,2010 # ffffffffc0208478 <default_pmm_manager+0x1160>
ffffffffc0205ca6:	00001617          	auipc	a2,0x1
ffffffffc0205caa:	f2a60613          	addi	a2,a2,-214 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0205cae:	31e00593          	li	a1,798
ffffffffc0205cb2:	00003517          	auipc	a0,0x3
ffffffffc0205cb6:	bb650513          	addi	a0,a0,-1098 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205cba:	fcafa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205cbe <do_yield>:
    current->need_resched = 1;
ffffffffc0205cbe:	000a6797          	auipc	a5,0xa6
ffffffffc0205cc2:	7f278793          	addi	a5,a5,2034 # ffffffffc02ac4b0 <current>
ffffffffc0205cc6:	639c                	ld	a5,0(a5)
ffffffffc0205cc8:	4705                	li	a4,1
}
ffffffffc0205cca:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0205ccc:	ef98                	sd	a4,24(a5)
}
ffffffffc0205cce:	8082                	ret

ffffffffc0205cd0 <do_wait>:
{
ffffffffc0205cd0:	1101                	addi	sp,sp,-32
ffffffffc0205cd2:	e822                	sd	s0,16(sp)
ffffffffc0205cd4:	e426                	sd	s1,8(sp)
ffffffffc0205cd6:	ec06                	sd	ra,24(sp)
ffffffffc0205cd8:	842e                	mv	s0,a1
ffffffffc0205cda:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0205cdc:	cd81                	beqz	a1,ffffffffc0205cf4 <do_wait+0x24>
    struct mm_struct *mm = current->mm;
ffffffffc0205cde:	000a6797          	auipc	a5,0xa6
ffffffffc0205ce2:	7d278793          	addi	a5,a5,2002 # ffffffffc02ac4b0 <current>
ffffffffc0205ce6:	639c                	ld	a5,0(a5)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0205ce8:	4685                	li	a3,1
ffffffffc0205cea:	4611                	li	a2,4
ffffffffc0205cec:	7788                	ld	a0,40(a5)
ffffffffc0205cee:	dbbfe0ef          	jal	ra,ffffffffc0204aa8 <user_mem_check>
ffffffffc0205cf2:	c909                	beqz	a0,ffffffffc0205d04 <do_wait+0x34>
ffffffffc0205cf4:	85a2                	mv	a1,s0
}
ffffffffc0205cf6:	6442                	ld	s0,16(sp)
ffffffffc0205cf8:	60e2                	ld	ra,24(sp)
ffffffffc0205cfa:	8526                	mv	a0,s1
ffffffffc0205cfc:	64a2                	ld	s1,8(sp)
ffffffffc0205cfe:	6105                	addi	sp,sp,32
ffffffffc0205d00:	fecff06f          	j	ffffffffc02054ec <do_wait.part.1>
ffffffffc0205d04:	60e2                	ld	ra,24(sp)
ffffffffc0205d06:	6442                	ld	s0,16(sp)
ffffffffc0205d08:	64a2                	ld	s1,8(sp)
ffffffffc0205d0a:	5575                	li	a0,-3
ffffffffc0205d0c:	6105                	addi	sp,sp,32
ffffffffc0205d0e:	8082                	ret

ffffffffc0205d10 <do_kill>:
{
ffffffffc0205d10:	1141                	addi	sp,sp,-16
ffffffffc0205d12:	e406                	sd	ra,8(sp)
ffffffffc0205d14:	e022                	sd	s0,0(sp)
    if ((proc = find_proc(pid)) != NULL)
ffffffffc0205d16:	a00ff0ef          	jal	ra,ffffffffc0204f16 <find_proc>
ffffffffc0205d1a:	cd0d                	beqz	a0,ffffffffc0205d54 <do_kill+0x44>
        if (!(proc->flags & PF_EXITING))
ffffffffc0205d1c:	0b052703          	lw	a4,176(a0)
ffffffffc0205d20:	00177693          	andi	a3,a4,1
ffffffffc0205d24:	e695                	bnez	a3,ffffffffc0205d50 <do_kill+0x40>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0205d26:	0ec52683          	lw	a3,236(a0)
            proc->flags |= PF_EXITING;
ffffffffc0205d2a:	00176713          	ori	a4,a4,1
ffffffffc0205d2e:	0ae52823          	sw	a4,176(a0)
            return 0;
ffffffffc0205d32:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0205d34:	0006c763          	bltz	a3,ffffffffc0205d42 <do_kill+0x32>
}
ffffffffc0205d38:	8522                	mv	a0,s0
ffffffffc0205d3a:	60a2                	ld	ra,8(sp)
ffffffffc0205d3c:	6402                	ld	s0,0(sp)
ffffffffc0205d3e:	0141                	addi	sp,sp,16
ffffffffc0205d40:	8082                	ret
                wakeup_proc(proc);
ffffffffc0205d42:	1e6000ef          	jal	ra,ffffffffc0205f28 <wakeup_proc>
}
ffffffffc0205d46:	8522                	mv	a0,s0
ffffffffc0205d48:	60a2                	ld	ra,8(sp)
ffffffffc0205d4a:	6402                	ld	s0,0(sp)
ffffffffc0205d4c:	0141                	addi	sp,sp,16
ffffffffc0205d4e:	8082                	ret
        return -E_KILLED;
ffffffffc0205d50:	545d                	li	s0,-9
ffffffffc0205d52:	b7dd                	j	ffffffffc0205d38 <do_kill+0x28>
    return -E_INVAL;
ffffffffc0205d54:	5475                	li	s0,-3
ffffffffc0205d56:	b7cd                	j	ffffffffc0205d38 <do_kill+0x28>

ffffffffc0205d58 <proc_init>:
    elm->prev = elm->next = elm;
ffffffffc0205d58:	000a7797          	auipc	a5,0xa7
ffffffffc0205d5c:	89878793          	addi	a5,a5,-1896 # ffffffffc02ac5f0 <proc_list>

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0205d60:	1101                	addi	sp,sp,-32
ffffffffc0205d62:	000a7717          	auipc	a4,0xa7
ffffffffc0205d66:	88f73b23          	sd	a5,-1898(a4) # ffffffffc02ac5f8 <proc_list+0x8>
ffffffffc0205d6a:	000a7717          	auipc	a4,0xa7
ffffffffc0205d6e:	88f73323          	sd	a5,-1914(a4) # ffffffffc02ac5f0 <proc_list>
ffffffffc0205d72:	ec06                	sd	ra,24(sp)
ffffffffc0205d74:	e822                	sd	s0,16(sp)
ffffffffc0205d76:	e426                	sd	s1,8(sp)
ffffffffc0205d78:	000a2797          	auipc	a5,0xa2
ffffffffc0205d7c:	70078793          	addi	a5,a5,1792 # ffffffffc02a8478 <hash_list>
ffffffffc0205d80:	000a6717          	auipc	a4,0xa6
ffffffffc0205d84:	6f870713          	addi	a4,a4,1784 # ffffffffc02ac478 <is_panic>
ffffffffc0205d88:	e79c                	sd	a5,8(a5)
ffffffffc0205d8a:	e39c                	sd	a5,0(a5)
ffffffffc0205d8c:	07c1                	addi	a5,a5,16
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0205d8e:	fee79de3          	bne	a5,a4,ffffffffc0205d88 <proc_init+0x30>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0205d92:	f1bfe0ef          	jal	ra,ffffffffc0204cac <alloc_proc>
ffffffffc0205d96:	000a6717          	auipc	a4,0xa6
ffffffffc0205d9a:	72a73123          	sd	a0,1826(a4) # ffffffffc02ac4b8 <idleproc>
ffffffffc0205d9e:	000a6497          	auipc	s1,0xa6
ffffffffc0205da2:	71a48493          	addi	s1,s1,1818 # ffffffffc02ac4b8 <idleproc>
ffffffffc0205da6:	c559                	beqz	a0,ffffffffc0205e34 <proc_init+0xdc>
    }

    //---------------------------进一步初始化proc---------------------------
    // proc_init函数对idleproc内核线程进行进一步初始化
    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205da8:	4709                	li	a4,2
ffffffffc0205daa:	e118                	sd	a4,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
ffffffffc0205dac:	4405                	li	s0,1
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205dae:	00003717          	auipc	a4,0x3
ffffffffc0205db2:	25270713          	addi	a4,a4,594 # ffffffffc0209000 <bootstack>
    set_proc_name(idleproc, "idle");
ffffffffc0205db6:	00003597          	auipc	a1,0x3
ffffffffc0205dba:	9ca58593          	addi	a1,a1,-1590 # ffffffffc0208780 <default_pmm_manager+0x1468>
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205dbe:	e918                	sd	a4,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205dc0:	ed00                	sd	s0,24(a0)
    set_proc_name(idleproc, "idle");
ffffffffc0205dc2:	8beff0ef          	jal	ra,ffffffffc0204e80 <set_proc_name>
    nr_process++;
ffffffffc0205dc6:	000a6797          	auipc	a5,0xa6
ffffffffc0205dca:	70278793          	addi	a5,a5,1794 # ffffffffc02ac4c8 <nr_process>
ffffffffc0205dce:	439c                	lw	a5,0(a5)

    current = idleproc;
ffffffffc0205dd0:	6098                	ld	a4,0(s1)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205dd2:	4601                	li	a2,0
    nr_process++;
ffffffffc0205dd4:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205dd6:	4581                	li	a1,0
ffffffffc0205dd8:	00000517          	auipc	a0,0x0
ffffffffc0205ddc:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0205694 <init_main>
    nr_process++;
ffffffffc0205de0:	000a6697          	auipc	a3,0xa6
ffffffffc0205de4:	6ef6a423          	sw	a5,1768(a3) # ffffffffc02ac4c8 <nr_process>
    current = idleproc;
ffffffffc0205de8:	000a6797          	auipc	a5,0xa6
ffffffffc0205dec:	6ce7b423          	sd	a4,1736(a5) # ffffffffc02ac4b0 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205df0:	d5eff0ef          	jal	ra,ffffffffc020534e <kernel_thread>
    if (pid <= 0)
ffffffffc0205df4:	08a05c63          	blez	a0,ffffffffc0205e8c <proc_init+0x134>
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205df8:	91eff0ef          	jal	ra,ffffffffc0204f16 <find_proc>
    set_proc_name(initproc, "init");
ffffffffc0205dfc:	00003597          	auipc	a1,0x3
ffffffffc0205e00:	9ac58593          	addi	a1,a1,-1620 # ffffffffc02087a8 <default_pmm_manager+0x1490>
    initproc = find_proc(pid);
ffffffffc0205e04:	000a6797          	auipc	a5,0xa6
ffffffffc0205e08:	6aa7be23          	sd	a0,1724(a5) # ffffffffc02ac4c0 <initproc>
    set_proc_name(initproc, "init");
ffffffffc0205e0c:	874ff0ef          	jal	ra,ffffffffc0204e80 <set_proc_name>

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205e10:	609c                	ld	a5,0(s1)
ffffffffc0205e12:	cfa9                	beqz	a5,ffffffffc0205e6c <proc_init+0x114>
ffffffffc0205e14:	43dc                	lw	a5,4(a5)
ffffffffc0205e16:	ebb9                	bnez	a5,ffffffffc0205e6c <proc_init+0x114>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205e18:	000a6797          	auipc	a5,0xa6
ffffffffc0205e1c:	6a878793          	addi	a5,a5,1704 # ffffffffc02ac4c0 <initproc>
ffffffffc0205e20:	639c                	ld	a5,0(a5)
ffffffffc0205e22:	c78d                	beqz	a5,ffffffffc0205e4c <proc_init+0xf4>
ffffffffc0205e24:	43dc                	lw	a5,4(a5)
ffffffffc0205e26:	02879363          	bne	a5,s0,ffffffffc0205e4c <proc_init+0xf4>
}
ffffffffc0205e2a:	60e2                	ld	ra,24(sp)
ffffffffc0205e2c:	6442                	ld	s0,16(sp)
ffffffffc0205e2e:	64a2                	ld	s1,8(sp)
ffffffffc0205e30:	6105                	addi	sp,sp,32
ffffffffc0205e32:	8082                	ret
        panic("cannot alloc idleproc.\n");
ffffffffc0205e34:	00003617          	auipc	a2,0x3
ffffffffc0205e38:	93460613          	addi	a2,a2,-1740 # ffffffffc0208768 <default_pmm_manager+0x1450>
ffffffffc0205e3c:	45800593          	li	a1,1112
ffffffffc0205e40:	00003517          	auipc	a0,0x3
ffffffffc0205e44:	a2850513          	addi	a0,a0,-1496 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205e48:	e3cfa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205e4c:	00003697          	auipc	a3,0x3
ffffffffc0205e50:	98c68693          	addi	a3,a3,-1652 # ffffffffc02087d8 <default_pmm_manager+0x14c0>
ffffffffc0205e54:	00001617          	auipc	a2,0x1
ffffffffc0205e58:	d7c60613          	addi	a2,a2,-644 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0205e5c:	47000593          	li	a1,1136
ffffffffc0205e60:	00003517          	auipc	a0,0x3
ffffffffc0205e64:	a0850513          	addi	a0,a0,-1528 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205e68:	e1cfa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205e6c:	00003697          	auipc	a3,0x3
ffffffffc0205e70:	94468693          	addi	a3,a3,-1724 # ffffffffc02087b0 <default_pmm_manager+0x1498>
ffffffffc0205e74:	00001617          	auipc	a2,0x1
ffffffffc0205e78:	d5c60613          	addi	a2,a2,-676 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0205e7c:	46f00593          	li	a1,1135
ffffffffc0205e80:	00003517          	auipc	a0,0x3
ffffffffc0205e84:	9e850513          	addi	a0,a0,-1560 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205e88:	dfcfa0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("create init_main failed.\n");
ffffffffc0205e8c:	00003617          	auipc	a2,0x3
ffffffffc0205e90:	8fc60613          	addi	a2,a2,-1796 # ffffffffc0208788 <default_pmm_manager+0x1470>
ffffffffc0205e94:	46900593          	li	a1,1129
ffffffffc0205e98:	00003517          	auipc	a0,0x3
ffffffffc0205e9c:	9d050513          	addi	a0,a0,-1584 # ffffffffc0208868 <default_pmm_manager+0x1550>
ffffffffc0205ea0:	de4fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205ea4 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205ea4:	1141                	addi	sp,sp,-16
ffffffffc0205ea6:	e022                	sd	s0,0(sp)
ffffffffc0205ea8:	e406                	sd	ra,8(sp)
ffffffffc0205eaa:	000a6417          	auipc	s0,0xa6
ffffffffc0205eae:	60640413          	addi	s0,s0,1542 # ffffffffc02ac4b0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205eb2:	6018                	ld	a4,0(s0)
ffffffffc0205eb4:	6f1c                	ld	a5,24(a4)
ffffffffc0205eb6:	dffd                	beqz	a5,ffffffffc0205eb4 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205eb8:	0ec000ef          	jal	ra,ffffffffc0205fa4 <schedule>
ffffffffc0205ebc:	bfdd                	j	ffffffffc0205eb2 <cpu_idle+0xe>

ffffffffc0205ebe <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205ebe:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205ec2:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205ec6:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205ec8:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205eca:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205ece:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205ed2:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205ed6:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0205eda:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205ede:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205ee2:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205ee6:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0205eea:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205eee:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205ef2:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205ef6:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0205efa:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205efc:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205efe:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205f02:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205f06:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0205f0a:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205f0e:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205f12:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205f16:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0205f1a:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205f1e:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205f22:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205f26:	8082                	ret

ffffffffc0205f28 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f28:	4118                	lw	a4,0(a0)
{
ffffffffc0205f2a:	1101                	addi	sp,sp,-32
ffffffffc0205f2c:	ec06                	sd	ra,24(sp)
ffffffffc0205f2e:	e822                	sd	s0,16(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f30:	478d                	li	a5,3
ffffffffc0205f32:	04f70a63          	beq	a4,a5,ffffffffc0205f86 <wakeup_proc+0x5e>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f36:	100027f3          	csrr	a5,sstatus
ffffffffc0205f3a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205f3c:	4401                	li	s0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f3e:	ef8d                	bnez	a5,ffffffffc0205f78 <wakeup_proc+0x50>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205f40:	4789                	li	a5,2
ffffffffc0205f42:	00f70f63          	beq	a4,a5,ffffffffc0205f60 <wakeup_proc+0x38>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc0205f46:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc0205f48:	0e052623          	sw	zero,236(a0)
    if (flag) {
ffffffffc0205f4c:	e409                	bnez	s0,ffffffffc0205f56 <wakeup_proc+0x2e>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205f4e:	60e2                	ld	ra,24(sp)
ffffffffc0205f50:	6442                	ld	s0,16(sp)
ffffffffc0205f52:	6105                	addi	sp,sp,32
ffffffffc0205f54:	8082                	ret
ffffffffc0205f56:	6442                	ld	s0,16(sp)
ffffffffc0205f58:	60e2                	ld	ra,24(sp)
ffffffffc0205f5a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205f5c:	ef8fa06f          	j	ffffffffc0200654 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205f60:	00003617          	auipc	a2,0x3
ffffffffc0205f64:	95860613          	addi	a2,a2,-1704 # ffffffffc02088b8 <default_pmm_manager+0x15a0>
ffffffffc0205f68:	45d1                	li	a1,20
ffffffffc0205f6a:	00003517          	auipc	a0,0x3
ffffffffc0205f6e:	93650513          	addi	a0,a0,-1738 # ffffffffc02088a0 <default_pmm_manager+0x1588>
ffffffffc0205f72:	d7efa0ef          	jal	ra,ffffffffc02004f0 <__warn>
ffffffffc0205f76:	bfd9                	j	ffffffffc0205f4c <wakeup_proc+0x24>
ffffffffc0205f78:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0205f7a:	ee0fa0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc0205f7e:	6522                	ld	a0,8(sp)
ffffffffc0205f80:	4405                	li	s0,1
ffffffffc0205f82:	4118                	lw	a4,0(a0)
ffffffffc0205f84:	bf75                	j	ffffffffc0205f40 <wakeup_proc+0x18>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f86:	00003697          	auipc	a3,0x3
ffffffffc0205f8a:	8fa68693          	addi	a3,a3,-1798 # ffffffffc0208880 <default_pmm_manager+0x1568>
ffffffffc0205f8e:	00001617          	auipc	a2,0x1
ffffffffc0205f92:	c4260613          	addi	a2,a2,-958 # ffffffffc0206bd0 <commands+0x4a8>
ffffffffc0205f96:	45a5                	li	a1,9
ffffffffc0205f98:	00003517          	auipc	a0,0x3
ffffffffc0205f9c:	90850513          	addi	a0,a0,-1784 # ffffffffc02088a0 <default_pmm_manager+0x1588>
ffffffffc0205fa0:	ce4fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205fa4 <schedule>:

void schedule(void)
{
ffffffffc0205fa4:	1141                	addi	sp,sp,-16
ffffffffc0205fa6:	e406                	sd	ra,8(sp)
ffffffffc0205fa8:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205faa:	100027f3          	csrr	a5,sstatus
ffffffffc0205fae:	8b89                	andi	a5,a5,2
ffffffffc0205fb0:	4401                	li	s0,0
ffffffffc0205fb2:	e3d1                	bnez	a5,ffffffffc0206036 <schedule+0x92>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205fb4:	000a6797          	auipc	a5,0xa6
ffffffffc0205fb8:	4fc78793          	addi	a5,a5,1276 # ffffffffc02ac4b0 <current>
ffffffffc0205fbc:	0007b883          	ld	a7,0(a5)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205fc0:	000a6797          	auipc	a5,0xa6
ffffffffc0205fc4:	4f878793          	addi	a5,a5,1272 # ffffffffc02ac4b8 <idleproc>
ffffffffc0205fc8:	6388                	ld	a0,0(a5)
        current->need_resched = 0;
ffffffffc0205fca:	0008bc23          	sd	zero,24(a7) # 2018 <_binary_obj___user_faultread_out_size-0x7568>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205fce:	04a88e63          	beq	a7,a0,ffffffffc020602a <schedule+0x86>
ffffffffc0205fd2:	0c888693          	addi	a3,a7,200
ffffffffc0205fd6:	000a6617          	auipc	a2,0xa6
ffffffffc0205fda:	61a60613          	addi	a2,a2,1562 # ffffffffc02ac5f0 <proc_list>
        le = last;
ffffffffc0205fde:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205fe0:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205fe2:	4809                	li	a6,2
    return listelm->next;
ffffffffc0205fe4:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc0205fe6:	00c78863          	beq	a5,a2,ffffffffc0205ff6 <schedule+0x52>
                if (next->state == PROC_RUNNABLE)
ffffffffc0205fea:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0205fee:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205ff2:	01070463          	beq	a4,a6,ffffffffc0205ffa <schedule+0x56>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc0205ff6:	fef697e3          	bne	a3,a5,ffffffffc0205fe4 <schedule+0x40>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205ffa:	c589                	beqz	a1,ffffffffc0206004 <schedule+0x60>
ffffffffc0205ffc:	4198                	lw	a4,0(a1)
ffffffffc0205ffe:	4789                	li	a5,2
ffffffffc0206000:	00f70e63          	beq	a4,a5,ffffffffc020601c <schedule+0x78>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc0206004:	451c                	lw	a5,8(a0)
ffffffffc0206006:	2785                	addiw	a5,a5,1
ffffffffc0206008:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc020600a:	00a88463          	beq	a7,a0,ffffffffc0206012 <schedule+0x6e>
        {
            proc_run(next);
ffffffffc020600e:	e9dfe0ef          	jal	ra,ffffffffc0204eaa <proc_run>
    if (flag) {
ffffffffc0206012:	e419                	bnez	s0,ffffffffc0206020 <schedule+0x7c>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0206014:	60a2                	ld	ra,8(sp)
ffffffffc0206016:	6402                	ld	s0,0(sp)
ffffffffc0206018:	0141                	addi	sp,sp,16
ffffffffc020601a:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020601c:	852e                	mv	a0,a1
ffffffffc020601e:	b7dd                	j	ffffffffc0206004 <schedule+0x60>
}
ffffffffc0206020:	6402                	ld	s0,0(sp)
ffffffffc0206022:	60a2                	ld	ra,8(sp)
ffffffffc0206024:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0206026:	e2efa06f          	j	ffffffffc0200654 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020602a:	000a6617          	auipc	a2,0xa6
ffffffffc020602e:	5c660613          	addi	a2,a2,1478 # ffffffffc02ac5f0 <proc_list>
ffffffffc0206032:	86b2                	mv	a3,a2
ffffffffc0206034:	b76d                	j	ffffffffc0205fde <schedule+0x3a>
        intr_disable();
ffffffffc0206036:	e24fa0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc020603a:	4405                	li	s0,1
ffffffffc020603c:	bfa5                	j	ffffffffc0205fb4 <schedule+0x10>

ffffffffc020603e <sys_getpid>:
}

static int
sys_getpid(uint64_t arg[])
{
    return current->pid;
ffffffffc020603e:	000a6797          	auipc	a5,0xa6
ffffffffc0206042:	47278793          	addi	a5,a5,1138 # ffffffffc02ac4b0 <current>
ffffffffc0206046:	639c                	ld	a5,0(a5)
}
ffffffffc0206048:	43c8                	lw	a0,4(a5)
ffffffffc020604a:	8082                	ret

ffffffffc020604c <sys_pgdir>:
static int
sys_pgdir(uint64_t arg[])
{
    // print_pgdir();
    return 0;
}
ffffffffc020604c:	4501                	li	a0,0
ffffffffc020604e:	8082                	ret

ffffffffc0206050 <sys_putc>:
    cputchar(c);
ffffffffc0206050:	4108                	lw	a0,0(a0)
{
ffffffffc0206052:	1141                	addi	sp,sp,-16
ffffffffc0206054:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0206056:	96cfa0ef          	jal	ra,ffffffffc02001c2 <cputchar>
}
ffffffffc020605a:	60a2                	ld	ra,8(sp)
ffffffffc020605c:	4501                	li	a0,0
ffffffffc020605e:	0141                	addi	sp,sp,16
ffffffffc0206060:	8082                	ret

ffffffffc0206062 <sys_kill>:
    return do_kill(pid);
ffffffffc0206062:	4108                	lw	a0,0(a0)
ffffffffc0206064:	cadff06f          	j	ffffffffc0205d10 <do_kill>

ffffffffc0206068 <sys_yield>:
    return do_yield();
ffffffffc0206068:	c57ff06f          	j	ffffffffc0205cbe <do_yield>

ffffffffc020606c <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc020606c:	6d14                	ld	a3,24(a0)
ffffffffc020606e:	6910                	ld	a2,16(a0)
ffffffffc0206070:	650c                	ld	a1,8(a0)
ffffffffc0206072:	6108                	ld	a0,0(a0)
ffffffffc0206074:	f48ff06f          	j	ffffffffc02057bc <do_execve>

ffffffffc0206078 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0206078:	650c                	ld	a1,8(a0)
ffffffffc020607a:	4108                	lw	a0,0(a0)
ffffffffc020607c:	c55ff06f          	j	ffffffffc0205cd0 <do_wait>

ffffffffc0206080 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0206080:	000a6797          	auipc	a5,0xa6
ffffffffc0206084:	43078793          	addi	a5,a5,1072 # ffffffffc02ac4b0 <current>
ffffffffc0206088:	639c                	ld	a5,0(a5)
    return do_fork(0, stack, tf);
ffffffffc020608a:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc020608c:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020608e:	6a0c                	ld	a1,16(a2)
ffffffffc0206090:	ee3fe06f          	j	ffffffffc0204f72 <do_fork>

ffffffffc0206094 <sys_exit>:
    return do_exit(error_code);
ffffffffc0206094:	4108                	lw	a0,0(a0)
ffffffffc0206096:	b08ff06f          	j	ffffffffc020539e <do_exit>

ffffffffc020609a <syscall>:
};

#define NUM_SYSCALLS ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void syscall(void)
{
ffffffffc020609a:	715d                	addi	sp,sp,-80
ffffffffc020609c:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc020609e:	000a6497          	auipc	s1,0xa6
ffffffffc02060a2:	41248493          	addi	s1,s1,1042 # ffffffffc02ac4b0 <current>
ffffffffc02060a6:	6098                	ld	a4,0(s1)
{
ffffffffc02060a8:	e0a2                	sd	s0,64(sp)
ffffffffc02060aa:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02060ac:	7340                	ld	s0,160(a4)
{
ffffffffc02060ae:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0; //系统调用编号
    if (num >= 0 && num < NUM_SYSCALLS)
ffffffffc02060b0:	47fd                	li	a5,31
    int num = tf->gpr.a0; //系统调用编号
ffffffffc02060b2:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS)
ffffffffc02060b6:	0327ee63          	bltu	a5,s2,ffffffffc02060f2 <syscall+0x58>
    {
        if (syscalls[num] != NULL)
ffffffffc02060ba:	00391713          	slli	a4,s2,0x3
ffffffffc02060be:	00003797          	auipc	a5,0x3
ffffffffc02060c2:	86278793          	addi	a5,a5,-1950 # ffffffffc0208920 <syscalls>
ffffffffc02060c6:	97ba                	add	a5,a5,a4
ffffffffc02060c8:	639c                	ld	a5,0(a5)
ffffffffc02060ca:	c785                	beqz	a5,ffffffffc02060f2 <syscall+0x58>
        {
            arg[0] = tf->gpr.a1;
ffffffffc02060cc:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02060ce:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02060d0:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02060d2:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02060d4:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02060d6:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02060d8:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02060da:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc02060dc:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc02060de:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02060e0:	0028                	addi	a0,sp,8
ffffffffc02060e2:	9782                	jalr	a5
ffffffffc02060e4:	e828                	sd	a0,80(s0)

   //如果执行到这里，说明传入的系统调用编号还没有被实现，就崩掉了
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
          num, current->pid, current->name);
}
ffffffffc02060e6:	60a6                	ld	ra,72(sp)
ffffffffc02060e8:	6406                	ld	s0,64(sp)
ffffffffc02060ea:	74e2                	ld	s1,56(sp)
ffffffffc02060ec:	7942                	ld	s2,48(sp)
ffffffffc02060ee:	6161                	addi	sp,sp,80
ffffffffc02060f0:	8082                	ret
    print_trapframe(tf);
ffffffffc02060f2:	8522                	mv	a0,s0
ffffffffc02060f4:	f56fa0ef          	jal	ra,ffffffffc020084a <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02060f8:	609c                	ld	a5,0(s1)
ffffffffc02060fa:	86ca                	mv	a3,s2
ffffffffc02060fc:	00002617          	auipc	a2,0x2
ffffffffc0206100:	7dc60613          	addi	a2,a2,2012 # ffffffffc02088d8 <default_pmm_manager+0x15c0>
ffffffffc0206104:	43d8                	lw	a4,4(a5)
ffffffffc0206106:	07100593          	li	a1,113
ffffffffc020610a:	0b478793          	addi	a5,a5,180
ffffffffc020610e:	00002517          	auipc	a0,0x2
ffffffffc0206112:	7fa50513          	addi	a0,a0,2042 # ffffffffc0208908 <default_pmm_manager+0x15f0>
ffffffffc0206116:	b6efa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020611a <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc020611a:	9e3707b7          	lui	a5,0x9e370
ffffffffc020611e:	2785                	addiw	a5,a5,1
ffffffffc0206120:	02f5053b          	mulw	a0,a0,a5
    return (hash >> (32 - bits));
ffffffffc0206124:	02000793          	li	a5,32
ffffffffc0206128:	40b785bb          	subw	a1,a5,a1
}
ffffffffc020612c:	00b5553b          	srlw	a0,a0,a1
ffffffffc0206130:	8082                	ret

ffffffffc0206132 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0206132:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206136:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0206138:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020613c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020613e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206142:	f022                	sd	s0,32(sp)
ffffffffc0206144:	ec26                	sd	s1,24(sp)
ffffffffc0206146:	e84a                	sd	s2,16(sp)
ffffffffc0206148:	f406                	sd	ra,40(sp)
ffffffffc020614a:	e44e                	sd	s3,8(sp)
ffffffffc020614c:	84aa                	mv	s1,a0
ffffffffc020614e:	892e                	mv	s2,a1
ffffffffc0206150:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0206154:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0206156:	03067e63          	bleu	a6,a2,ffffffffc0206192 <printnum+0x60>
ffffffffc020615a:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020615c:	00805763          	blez	s0,ffffffffc020616a <printnum+0x38>
ffffffffc0206160:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0206162:	85ca                	mv	a1,s2
ffffffffc0206164:	854e                	mv	a0,s3
ffffffffc0206166:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0206168:	fc65                	bnez	s0,ffffffffc0206160 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020616a:	1a02                	slli	s4,s4,0x20
ffffffffc020616c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0206170:	00003797          	auipc	a5,0x3
ffffffffc0206174:	ad078793          	addi	a5,a5,-1328 # ffffffffc0208c40 <error_string+0xc8>
ffffffffc0206178:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020617a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020617c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0206180:	70a2                	ld	ra,40(sp)
ffffffffc0206182:	69a2                	ld	s3,8(sp)
ffffffffc0206184:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206186:	85ca                	mv	a1,s2
ffffffffc0206188:	8326                	mv	t1,s1
}
ffffffffc020618a:	6942                	ld	s2,16(sp)
ffffffffc020618c:	64e2                	ld	s1,24(sp)
ffffffffc020618e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206190:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0206192:	03065633          	divu	a2,a2,a6
ffffffffc0206196:	8722                	mv	a4,s0
ffffffffc0206198:	f9bff0ef          	jal	ra,ffffffffc0206132 <printnum>
ffffffffc020619c:	b7f9                	j	ffffffffc020616a <printnum+0x38>

ffffffffc020619e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020619e:	7119                	addi	sp,sp,-128
ffffffffc02061a0:	f4a6                	sd	s1,104(sp)
ffffffffc02061a2:	f0ca                	sd	s2,96(sp)
ffffffffc02061a4:	e8d2                	sd	s4,80(sp)
ffffffffc02061a6:	e4d6                	sd	s5,72(sp)
ffffffffc02061a8:	e0da                	sd	s6,64(sp)
ffffffffc02061aa:	fc5e                	sd	s7,56(sp)
ffffffffc02061ac:	f862                	sd	s8,48(sp)
ffffffffc02061ae:	f06a                	sd	s10,32(sp)
ffffffffc02061b0:	fc86                	sd	ra,120(sp)
ffffffffc02061b2:	f8a2                	sd	s0,112(sp)
ffffffffc02061b4:	ecce                	sd	s3,88(sp)
ffffffffc02061b6:	f466                	sd	s9,40(sp)
ffffffffc02061b8:	ec6e                	sd	s11,24(sp)
ffffffffc02061ba:	892a                	mv	s2,a0
ffffffffc02061bc:	84ae                	mv	s1,a1
ffffffffc02061be:	8d32                	mv	s10,a2
ffffffffc02061c0:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02061c2:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061c4:	00003a17          	auipc	s4,0x3
ffffffffc02061c8:	85ca0a13          	addi	s4,s4,-1956 # ffffffffc0208a20 <syscalls+0x100>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02061cc:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02061d0:	00003c17          	auipc	s8,0x3
ffffffffc02061d4:	9a8c0c13          	addi	s8,s8,-1624 # ffffffffc0208b78 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02061d8:	000d4503          	lbu	a0,0(s10)
ffffffffc02061dc:	02500793          	li	a5,37
ffffffffc02061e0:	001d0413          	addi	s0,s10,1
ffffffffc02061e4:	00f50e63          	beq	a0,a5,ffffffffc0206200 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc02061e8:	c521                	beqz	a0,ffffffffc0206230 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02061ea:	02500993          	li	s3,37
ffffffffc02061ee:	a011                	j	ffffffffc02061f2 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc02061f0:	c121                	beqz	a0,ffffffffc0206230 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc02061f2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02061f4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02061f6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02061f8:	fff44503          	lbu	a0,-1(s0)
ffffffffc02061fc:	ff351ae3          	bne	a0,s3,ffffffffc02061f0 <vprintfmt+0x52>
ffffffffc0206200:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0206204:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0206208:	4981                	li	s3,0
ffffffffc020620a:	4801                	li	a6,0
        width = precision = -1;
ffffffffc020620c:	5cfd                	li	s9,-1
ffffffffc020620e:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206210:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0206214:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206216:	fdd6069b          	addiw	a3,a2,-35
ffffffffc020621a:	0ff6f693          	andi	a3,a3,255
ffffffffc020621e:	00140d13          	addi	s10,s0,1
ffffffffc0206222:	20d5e563          	bltu	a1,a3,ffffffffc020642c <vprintfmt+0x28e>
ffffffffc0206226:	068a                	slli	a3,a3,0x2
ffffffffc0206228:	96d2                	add	a3,a3,s4
ffffffffc020622a:	4294                	lw	a3,0(a3)
ffffffffc020622c:	96d2                	add	a3,a3,s4
ffffffffc020622e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0206230:	70e6                	ld	ra,120(sp)
ffffffffc0206232:	7446                	ld	s0,112(sp)
ffffffffc0206234:	74a6                	ld	s1,104(sp)
ffffffffc0206236:	7906                	ld	s2,96(sp)
ffffffffc0206238:	69e6                	ld	s3,88(sp)
ffffffffc020623a:	6a46                	ld	s4,80(sp)
ffffffffc020623c:	6aa6                	ld	s5,72(sp)
ffffffffc020623e:	6b06                	ld	s6,64(sp)
ffffffffc0206240:	7be2                	ld	s7,56(sp)
ffffffffc0206242:	7c42                	ld	s8,48(sp)
ffffffffc0206244:	7ca2                	ld	s9,40(sp)
ffffffffc0206246:	7d02                	ld	s10,32(sp)
ffffffffc0206248:	6de2                	ld	s11,24(sp)
ffffffffc020624a:	6109                	addi	sp,sp,128
ffffffffc020624c:	8082                	ret
    if (lflag >= 2) {
ffffffffc020624e:	4705                	li	a4,1
ffffffffc0206250:	008a8593          	addi	a1,s5,8
ffffffffc0206254:	01074463          	blt	a4,a6,ffffffffc020625c <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc0206258:	26080363          	beqz	a6,ffffffffc02064be <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc020625c:	000ab603          	ld	a2,0(s5)
ffffffffc0206260:	46c1                	li	a3,16
ffffffffc0206262:	8aae                	mv	s5,a1
ffffffffc0206264:	a06d                	j	ffffffffc020630e <vprintfmt+0x170>
            goto reswitch;
ffffffffc0206266:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020626a:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020626c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020626e:	b765                	j	ffffffffc0206216 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0206270:	000aa503          	lw	a0,0(s5)
ffffffffc0206274:	85a6                	mv	a1,s1
ffffffffc0206276:	0aa1                	addi	s5,s5,8
ffffffffc0206278:	9902                	jalr	s2
            break;
ffffffffc020627a:	bfb9                	j	ffffffffc02061d8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020627c:	4705                	li	a4,1
ffffffffc020627e:	008a8993          	addi	s3,s5,8
ffffffffc0206282:	01074463          	blt	a4,a6,ffffffffc020628a <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0206286:	22080463          	beqz	a6,ffffffffc02064ae <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc020628a:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc020628e:	24044463          	bltz	s0,ffffffffc02064d6 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0206292:	8622                	mv	a2,s0
ffffffffc0206294:	8ace                	mv	s5,s3
ffffffffc0206296:	46a9                	li	a3,10
ffffffffc0206298:	a89d                	j	ffffffffc020630e <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc020629a:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020629e:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02062a0:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc02062a2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02062a6:	8fb5                	xor	a5,a5,a3
ffffffffc02062a8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02062ac:	1ad74363          	blt	a4,a3,ffffffffc0206452 <vprintfmt+0x2b4>
ffffffffc02062b0:	00369793          	slli	a5,a3,0x3
ffffffffc02062b4:	97e2                	add	a5,a5,s8
ffffffffc02062b6:	639c                	ld	a5,0(a5)
ffffffffc02062b8:	18078d63          	beqz	a5,ffffffffc0206452 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc02062bc:	86be                	mv	a3,a5
ffffffffc02062be:	00000617          	auipc	a2,0x0
ffffffffc02062c2:	36260613          	addi	a2,a2,866 # ffffffffc0206620 <etext+0x2e>
ffffffffc02062c6:	85a6                	mv	a1,s1
ffffffffc02062c8:	854a                	mv	a0,s2
ffffffffc02062ca:	240000ef          	jal	ra,ffffffffc020650a <printfmt>
ffffffffc02062ce:	b729                	j	ffffffffc02061d8 <vprintfmt+0x3a>
            lflag ++;
ffffffffc02062d0:	00144603          	lbu	a2,1(s0)
ffffffffc02062d4:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02062d6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02062d8:	bf3d                	j	ffffffffc0206216 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc02062da:	4705                	li	a4,1
ffffffffc02062dc:	008a8593          	addi	a1,s5,8
ffffffffc02062e0:	01074463          	blt	a4,a6,ffffffffc02062e8 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02062e4:	1e080263          	beqz	a6,ffffffffc02064c8 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc02062e8:	000ab603          	ld	a2,0(s5)
ffffffffc02062ec:	46a1                	li	a3,8
ffffffffc02062ee:	8aae                	mv	s5,a1
ffffffffc02062f0:	a839                	j	ffffffffc020630e <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc02062f2:	03000513          	li	a0,48
ffffffffc02062f6:	85a6                	mv	a1,s1
ffffffffc02062f8:	e03e                	sd	a5,0(sp)
ffffffffc02062fa:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02062fc:	85a6                	mv	a1,s1
ffffffffc02062fe:	07800513          	li	a0,120
ffffffffc0206302:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0206304:	0aa1                	addi	s5,s5,8
ffffffffc0206306:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc020630a:	6782                	ld	a5,0(sp)
ffffffffc020630c:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020630e:	876e                	mv	a4,s11
ffffffffc0206310:	85a6                	mv	a1,s1
ffffffffc0206312:	854a                	mv	a0,s2
ffffffffc0206314:	e1fff0ef          	jal	ra,ffffffffc0206132 <printnum>
            break;
ffffffffc0206318:	b5c1                	j	ffffffffc02061d8 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020631a:	000ab603          	ld	a2,0(s5)
ffffffffc020631e:	0aa1                	addi	s5,s5,8
ffffffffc0206320:	1c060663          	beqz	a2,ffffffffc02064ec <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0206324:	00160413          	addi	s0,a2,1
ffffffffc0206328:	17b05c63          	blez	s11,ffffffffc02064a0 <vprintfmt+0x302>
ffffffffc020632c:	02d00593          	li	a1,45
ffffffffc0206330:	14b79263          	bne	a5,a1,ffffffffc0206474 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206334:	00064783          	lbu	a5,0(a2)
ffffffffc0206338:	0007851b          	sext.w	a0,a5
ffffffffc020633c:	c905                	beqz	a0,ffffffffc020636c <vprintfmt+0x1ce>
ffffffffc020633e:	000cc563          	bltz	s9,ffffffffc0206348 <vprintfmt+0x1aa>
ffffffffc0206342:	3cfd                	addiw	s9,s9,-1
ffffffffc0206344:	036c8263          	beq	s9,s6,ffffffffc0206368 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0206348:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020634a:	18098463          	beqz	s3,ffffffffc02064d2 <vprintfmt+0x334>
ffffffffc020634e:	3781                	addiw	a5,a5,-32
ffffffffc0206350:	18fbf163          	bleu	a5,s7,ffffffffc02064d2 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0206354:	03f00513          	li	a0,63
ffffffffc0206358:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020635a:	0405                	addi	s0,s0,1
ffffffffc020635c:	fff44783          	lbu	a5,-1(s0)
ffffffffc0206360:	3dfd                	addiw	s11,s11,-1
ffffffffc0206362:	0007851b          	sext.w	a0,a5
ffffffffc0206366:	fd61                	bnez	a0,ffffffffc020633e <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc0206368:	e7b058e3          	blez	s11,ffffffffc02061d8 <vprintfmt+0x3a>
ffffffffc020636c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020636e:	85a6                	mv	a1,s1
ffffffffc0206370:	02000513          	li	a0,32
ffffffffc0206374:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0206376:	e60d81e3          	beqz	s11,ffffffffc02061d8 <vprintfmt+0x3a>
ffffffffc020637a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020637c:	85a6                	mv	a1,s1
ffffffffc020637e:	02000513          	li	a0,32
ffffffffc0206382:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0206384:	fe0d94e3          	bnez	s11,ffffffffc020636c <vprintfmt+0x1ce>
ffffffffc0206388:	bd81                	j	ffffffffc02061d8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020638a:	4705                	li	a4,1
ffffffffc020638c:	008a8593          	addi	a1,s5,8
ffffffffc0206390:	01074463          	blt	a4,a6,ffffffffc0206398 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0206394:	12080063          	beqz	a6,ffffffffc02064b4 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc0206398:	000ab603          	ld	a2,0(s5)
ffffffffc020639c:	46a9                	li	a3,10
ffffffffc020639e:	8aae                	mv	s5,a1
ffffffffc02063a0:	b7bd                	j	ffffffffc020630e <vprintfmt+0x170>
ffffffffc02063a2:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc02063a6:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063aa:	846a                	mv	s0,s10
ffffffffc02063ac:	b5ad                	j	ffffffffc0206216 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc02063ae:	85a6                	mv	a1,s1
ffffffffc02063b0:	02500513          	li	a0,37
ffffffffc02063b4:	9902                	jalr	s2
            break;
ffffffffc02063b6:	b50d                	j	ffffffffc02061d8 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc02063b8:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc02063bc:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02063c0:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063c2:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc02063c4:	e40dd9e3          	bgez	s11,ffffffffc0206216 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc02063c8:	8de6                	mv	s11,s9
ffffffffc02063ca:	5cfd                	li	s9,-1
ffffffffc02063cc:	b5a9                	j	ffffffffc0206216 <vprintfmt+0x78>
            goto reswitch;
ffffffffc02063ce:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc02063d2:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063d6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02063d8:	bd3d                	j	ffffffffc0206216 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc02063da:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc02063de:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063e2:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02063e4:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02063e8:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02063ec:	fcd56ce3          	bltu	a0,a3,ffffffffc02063c4 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc02063f0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02063f2:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc02063f6:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02063fa:	0196873b          	addw	a4,a3,s9
ffffffffc02063fe:	0017171b          	slliw	a4,a4,0x1
ffffffffc0206402:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0206406:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc020640a:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020640e:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206412:	fcd57fe3          	bleu	a3,a0,ffffffffc02063f0 <vprintfmt+0x252>
ffffffffc0206416:	b77d                	j	ffffffffc02063c4 <vprintfmt+0x226>
            if (width < 0)
ffffffffc0206418:	fffdc693          	not	a3,s11
ffffffffc020641c:	96fd                	srai	a3,a3,0x3f
ffffffffc020641e:	00ddfdb3          	and	s11,s11,a3
ffffffffc0206422:	00144603          	lbu	a2,1(s0)
ffffffffc0206426:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206428:	846a                	mv	s0,s10
ffffffffc020642a:	b3f5                	j	ffffffffc0206216 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc020642c:	85a6                	mv	a1,s1
ffffffffc020642e:	02500513          	li	a0,37
ffffffffc0206432:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0206434:	fff44703          	lbu	a4,-1(s0)
ffffffffc0206438:	02500793          	li	a5,37
ffffffffc020643c:	8d22                	mv	s10,s0
ffffffffc020643e:	d8f70de3          	beq	a4,a5,ffffffffc02061d8 <vprintfmt+0x3a>
ffffffffc0206442:	02500713          	li	a4,37
ffffffffc0206446:	1d7d                	addi	s10,s10,-1
ffffffffc0206448:	fffd4783          	lbu	a5,-1(s10)
ffffffffc020644c:	fee79de3          	bne	a5,a4,ffffffffc0206446 <vprintfmt+0x2a8>
ffffffffc0206450:	b361                	j	ffffffffc02061d8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0206452:	00003617          	auipc	a2,0x3
ffffffffc0206456:	8ce60613          	addi	a2,a2,-1842 # ffffffffc0208d20 <error_string+0x1a8>
ffffffffc020645a:	85a6                	mv	a1,s1
ffffffffc020645c:	854a                	mv	a0,s2
ffffffffc020645e:	0ac000ef          	jal	ra,ffffffffc020650a <printfmt>
ffffffffc0206462:	bb9d                	j	ffffffffc02061d8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0206464:	00003617          	auipc	a2,0x3
ffffffffc0206468:	8b460613          	addi	a2,a2,-1868 # ffffffffc0208d18 <error_string+0x1a0>
            if (width > 0 && padc != '-') {
ffffffffc020646c:	00003417          	auipc	s0,0x3
ffffffffc0206470:	8ad40413          	addi	s0,s0,-1875 # ffffffffc0208d19 <error_string+0x1a1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206474:	8532                	mv	a0,a2
ffffffffc0206476:	85e6                	mv	a1,s9
ffffffffc0206478:	e032                	sd	a2,0(sp)
ffffffffc020647a:	e43e                	sd	a5,8(sp)
ffffffffc020647c:	0cc000ef          	jal	ra,ffffffffc0206548 <strnlen>
ffffffffc0206480:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0206484:	6602                	ld	a2,0(sp)
ffffffffc0206486:	01b05d63          	blez	s11,ffffffffc02064a0 <vprintfmt+0x302>
ffffffffc020648a:	67a2                	ld	a5,8(sp)
ffffffffc020648c:	2781                	sext.w	a5,a5
ffffffffc020648e:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0206490:	6522                	ld	a0,8(sp)
ffffffffc0206492:	85a6                	mv	a1,s1
ffffffffc0206494:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206496:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0206498:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020649a:	6602                	ld	a2,0(sp)
ffffffffc020649c:	fe0d9ae3          	bnez	s11,ffffffffc0206490 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02064a0:	00064783          	lbu	a5,0(a2)
ffffffffc02064a4:	0007851b          	sext.w	a0,a5
ffffffffc02064a8:	e8051be3          	bnez	a0,ffffffffc020633e <vprintfmt+0x1a0>
ffffffffc02064ac:	b335                	j	ffffffffc02061d8 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc02064ae:	000aa403          	lw	s0,0(s5)
ffffffffc02064b2:	bbf1                	j	ffffffffc020628e <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc02064b4:	000ae603          	lwu	a2,0(s5)
ffffffffc02064b8:	46a9                	li	a3,10
ffffffffc02064ba:	8aae                	mv	s5,a1
ffffffffc02064bc:	bd89                	j	ffffffffc020630e <vprintfmt+0x170>
ffffffffc02064be:	000ae603          	lwu	a2,0(s5)
ffffffffc02064c2:	46c1                	li	a3,16
ffffffffc02064c4:	8aae                	mv	s5,a1
ffffffffc02064c6:	b5a1                	j	ffffffffc020630e <vprintfmt+0x170>
ffffffffc02064c8:	000ae603          	lwu	a2,0(s5)
ffffffffc02064cc:	46a1                	li	a3,8
ffffffffc02064ce:	8aae                	mv	s5,a1
ffffffffc02064d0:	bd3d                	j	ffffffffc020630e <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc02064d2:	9902                	jalr	s2
ffffffffc02064d4:	b559                	j	ffffffffc020635a <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc02064d6:	85a6                	mv	a1,s1
ffffffffc02064d8:	02d00513          	li	a0,45
ffffffffc02064dc:	e03e                	sd	a5,0(sp)
ffffffffc02064de:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02064e0:	8ace                	mv	s5,s3
ffffffffc02064e2:	40800633          	neg	a2,s0
ffffffffc02064e6:	46a9                	li	a3,10
ffffffffc02064e8:	6782                	ld	a5,0(sp)
ffffffffc02064ea:	b515                	j	ffffffffc020630e <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc02064ec:	01b05663          	blez	s11,ffffffffc02064f8 <vprintfmt+0x35a>
ffffffffc02064f0:	02d00693          	li	a3,45
ffffffffc02064f4:	f6d798e3          	bne	a5,a3,ffffffffc0206464 <vprintfmt+0x2c6>
ffffffffc02064f8:	00003417          	auipc	s0,0x3
ffffffffc02064fc:	82140413          	addi	s0,s0,-2015 # ffffffffc0208d19 <error_string+0x1a1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206500:	02800513          	li	a0,40
ffffffffc0206504:	02800793          	li	a5,40
ffffffffc0206508:	bd1d                	j	ffffffffc020633e <vprintfmt+0x1a0>

ffffffffc020650a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020650a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020650c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206510:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0206512:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206514:	ec06                	sd	ra,24(sp)
ffffffffc0206516:	f83a                	sd	a4,48(sp)
ffffffffc0206518:	fc3e                	sd	a5,56(sp)
ffffffffc020651a:	e0c2                	sd	a6,64(sp)
ffffffffc020651c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020651e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0206520:	c7fff0ef          	jal	ra,ffffffffc020619e <vprintfmt>
}
ffffffffc0206524:	60e2                	ld	ra,24(sp)
ffffffffc0206526:	6161                	addi	sp,sp,80
ffffffffc0206528:	8082                	ret

ffffffffc020652a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020652a:	00054783          	lbu	a5,0(a0)
ffffffffc020652e:	cb91                	beqz	a5,ffffffffc0206542 <strlen+0x18>
    size_t cnt = 0;
ffffffffc0206530:	4781                	li	a5,0
        cnt ++;
ffffffffc0206532:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0206534:	00f50733          	add	a4,a0,a5
ffffffffc0206538:	00074703          	lbu	a4,0(a4)
ffffffffc020653c:	fb7d                	bnez	a4,ffffffffc0206532 <strlen+0x8>
    }
    return cnt;
}
ffffffffc020653e:	853e                	mv	a0,a5
ffffffffc0206540:	8082                	ret
    size_t cnt = 0;
ffffffffc0206542:	4781                	li	a5,0
}
ffffffffc0206544:	853e                	mv	a0,a5
ffffffffc0206546:	8082                	ret

ffffffffc0206548 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206548:	c185                	beqz	a1,ffffffffc0206568 <strnlen+0x20>
ffffffffc020654a:	00054783          	lbu	a5,0(a0)
ffffffffc020654e:	cf89                	beqz	a5,ffffffffc0206568 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0206550:	4781                	li	a5,0
ffffffffc0206552:	a021                	j	ffffffffc020655a <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206554:	00074703          	lbu	a4,0(a4)
ffffffffc0206558:	c711                	beqz	a4,ffffffffc0206564 <strnlen+0x1c>
        cnt ++;
ffffffffc020655a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020655c:	00f50733          	add	a4,a0,a5
ffffffffc0206560:	fef59ae3          	bne	a1,a5,ffffffffc0206554 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0206564:	853e                	mv	a0,a5
ffffffffc0206566:	8082                	ret
    size_t cnt = 0;
ffffffffc0206568:	4781                	li	a5,0
}
ffffffffc020656a:	853e                	mv	a0,a5
ffffffffc020656c:	8082                	ret

ffffffffc020656e <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc020656e:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0206570:	0585                	addi	a1,a1,1
ffffffffc0206572:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0206576:	0785                	addi	a5,a5,1
ffffffffc0206578:	fee78fa3          	sb	a4,-1(a5)
ffffffffc020657c:	fb75                	bnez	a4,ffffffffc0206570 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc020657e:	8082                	ret

ffffffffc0206580 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206580:	00054783          	lbu	a5,0(a0)
ffffffffc0206584:	0005c703          	lbu	a4,0(a1)
ffffffffc0206588:	cb91                	beqz	a5,ffffffffc020659c <strcmp+0x1c>
ffffffffc020658a:	00e79c63          	bne	a5,a4,ffffffffc02065a2 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc020658e:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206590:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0206594:	0585                	addi	a1,a1,1
ffffffffc0206596:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020659a:	fbe5                	bnez	a5,ffffffffc020658a <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020659c:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020659e:	9d19                	subw	a0,a0,a4
ffffffffc02065a0:	8082                	ret
ffffffffc02065a2:	0007851b          	sext.w	a0,a5
ffffffffc02065a6:	9d19                	subw	a0,a0,a4
ffffffffc02065a8:	8082                	ret

ffffffffc02065aa <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02065aa:	00054783          	lbu	a5,0(a0)
ffffffffc02065ae:	cb91                	beqz	a5,ffffffffc02065c2 <strchr+0x18>
        if (*s == c) {
ffffffffc02065b0:	00b79563          	bne	a5,a1,ffffffffc02065ba <strchr+0x10>
ffffffffc02065b4:	a809                	j	ffffffffc02065c6 <strchr+0x1c>
ffffffffc02065b6:	00b78763          	beq	a5,a1,ffffffffc02065c4 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc02065ba:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02065bc:	00054783          	lbu	a5,0(a0)
ffffffffc02065c0:	fbfd                	bnez	a5,ffffffffc02065b6 <strchr+0xc>
    }
    return NULL;
ffffffffc02065c2:	4501                	li	a0,0
}
ffffffffc02065c4:	8082                	ret
ffffffffc02065c6:	8082                	ret

ffffffffc02065c8 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02065c8:	ca01                	beqz	a2,ffffffffc02065d8 <memset+0x10>
ffffffffc02065ca:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02065cc:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02065ce:	0785                	addi	a5,a5,1
ffffffffc02065d0:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02065d4:	fec79de3          	bne	a5,a2,ffffffffc02065ce <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02065d8:	8082                	ret

ffffffffc02065da <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02065da:	ca19                	beqz	a2,ffffffffc02065f0 <memcpy+0x16>
ffffffffc02065dc:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02065de:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02065e0:	0585                	addi	a1,a1,1
ffffffffc02065e2:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02065e6:	0785                	addi	a5,a5,1
ffffffffc02065e8:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02065ec:	fec59ae3          	bne	a1,a2,ffffffffc02065e0 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02065f0:	8082                	ret
