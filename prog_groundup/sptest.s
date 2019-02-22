#Stack Pointer test
#I'm doing this test to visualize how stack and base pointer moves at the program

.section .data

.section .text

.globl _start

_start:
	pushq $3
	pushq $3
	pushq $3
	pushq $3
	pushq $4
	movq %rsp, %rbx
	movq $1, %rax
	int $0x80