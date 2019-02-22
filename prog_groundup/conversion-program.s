.include "linux.s"
.section .data

	#This is where it will be stored
	tmp_buffer:
		.ascii "\0\0\0\0\0\0\0\0\0\0\0"

.section .text

.globl _start
_start:
	movq %rsp, %rbp
	
	#Storage for the result
	pushq $tmp_buffer
	
	#Number to convert
	pushq $824
	call integer2string
	addq $16, %rsp
	
	#Get the character count for our system call
	pushq $tmp_buffer
	call count_chars
	addq $8, %rsp
	
	#The count goes in %rdx for SYS_WRITE
	movq %rax, %rdx
	
	#Make the system call
	movq $SYS_WRITE, %rax
	movq $STDOUT, %rbx
	movq $tmp_buffer, %rcx
	
	int $LINUX_SYSCALL
	
	#Write a carriage return
	pushq $STDOUT
	call write_newline
	
	#Exit
	movq $SYS_EXIT, %rax
	movq $0, %rbx
	int $LINUX_SYSCALL
	
