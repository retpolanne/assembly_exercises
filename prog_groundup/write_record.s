.include "record-def.s"
.include "linux.s"

#PURPOSE: This function writes a record to
# the given file descriptor
#
#INPUT: The file descriptor and a buffer
#
#OUTPUT: This function produces a status code
#

#STACK LOCAL VARIABLES
.equ ST_WRITE_BUFFER, 16
.equ ST_FILEDES, 24

.section .text

.globl write_record

.type write_record, @function

write_record:
	pushq %rbp
	movq %rsp, %rbp
	
	pushq %rbx
	movq $SYS_WRITE, %rax
	movq ST_FILEDES(%rbp), %rbx
	movq ST_WRITE_BUFFER(%rbp), %rcx
	movq $RECORD_SIZE, %rdx
	int $LINUX_SYSCALL
	
	#NOTE - %eax has the return value, which we will
	# give back to our calling program
	popq %rbx
	movq %rbp, %rsp
	popq %rbp
	ret