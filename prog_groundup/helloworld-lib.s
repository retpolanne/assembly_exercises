#PURPOSE: This program writes the message "hello world" and
# exits
#

.section .data
	helloworld:
		.ascii "hello world\n\0"

.section .text
	.globl _start
	_start:
		pushq $helloworld
		call printf
		pushq $0
		call exit