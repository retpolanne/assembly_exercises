#PURPOSE: This program writes the message "hello world" and
# exits
#

.include "linux.s"
.section .data

	helloworld: 
		.ascii "hello world\n"
	helloworld_end:
		.equ helloworld_len, helloworld_end - helloworld
		
.section .text
	.globl _start
	
	_start:
		movq $STDOUT, %rbx
		movq $helloworld, %rcx
		movq $helloworld_len, %rdx
		movq $SYS_WRITE, %rax
		int $LINUX_SYSCALL
		
		movq $0, %rbx
		movq $SYS_EXIT, %rax
		int $LINUX_SYSCALL
