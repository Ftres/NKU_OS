.text
# 内核线程入口函数 kernel_thread_entry 的实现
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
	jalr s0

	jal do_exit
