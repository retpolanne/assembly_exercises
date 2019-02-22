.include "linux.s"

.equ ST_ERROR_CODE, 16
.equ ST_ERROR_MSG, 24

.globl error_exit

.type error_exit, @function

error_exit:
	pushq %rbp
	movq %rsp, %rbp
	
	#Write out error code
	movq ST_ERROR_CODE(%rbp), %rcx
	pushq %rcx
	call count_chars
	popq %rcx
	movq %rax, %rdx
	movq $STDERR, %rdx
	movq $SYS_WRITE, %rax
	int $LINUX_SYSCALL
	
	#Write out error message
	movq ST_ERROR_MSG(%rbp), %rcx
	pushq %rcx
	call count_chars
	popq %rcx
	movq %rax, %rdx
	movq $STDERR, %rbx
	movq $SYS_WRITE, %rax
	int $LINUX_SYSCALL
	
	pushq $STDERR
	call write_newline
	
	#Exit with status 1
	movq $SYS_EXIT, %rax
	movq $1, %rbx
	int $LINUX_SYSCALL