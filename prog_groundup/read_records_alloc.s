.include "linux.s"
.include "record-def.s"

.section .data
	record_buffer_ptr:
		.long 0

file_name:
	.ascii "test.dat\0"
	
.section .bss
	.lcomm record_buffer, RECORD_SIZE
	
.section .text

#Main program
.globl _start

_start:
	#These are the locations on the stack where
	#we will store the input and output descriptors
	#(FYI - we could have used memory addresses in
	#a .data section instead)
	.equ ST_INPUT_DESCRIPTOR, -8
	.equ ST_OUTPUT_DESCRIPTOR, -16
	
	#Copy the stack pointer to %rbp
	movq %rsp, %rbp
	movq $file_name, %rbx
	#Open read-only
	movq $0, %rcx
	movq $0666, %rdx
	int $LINUX_SYSCALL
	
	#Save file descriptor
	movq %rax, ST_INPUT_DESCRIPTOR(%rbp)
	
	#Even though it’s a constant, we are
	#saving the output file descriptor in
	#a local variable so that if we later
	#decide that it isn’t always going to
	#be STDOUT, we can change it easily.
	movq $STDOUT, ST_OUTPUT_DESCRIPTOR(%ebp)
	
	call allocate_init
	pushq $RECORD_SIZE
	call allocate
	movq %rax, record_buffer_ptr
	
record_read_loop:
	pushq ST_INPUT_DESCRIPTOR(%rbp)
	pushq record_buffer_ptr
	call read_record
	addq $16, %rsp
	
	#Returns the number of bytes read.
	#If it isn’t the same number we
	#requested, then it’s either an
	#end-of-file, or an error, so we’re
	#quitting
	cmpq $RECORD_SIZE, %rax
	jne finished_reading
	
	#Otherwise, print out the first name
	#but first, we must know it’s size
	movq record_buffer_ptr, %rax
	addq $RECORD_FIRSTNAME, %rax
	pushq %rax
	call count_chars
	addq $8, %rsp
	
	movq %rax, %rdx
	movq ST_OUTPUT_DESCRIPTOR(%rbp), %rbx
	movq $SYS_WRITE, %rax
	movq record_buffer_ptr, %rcx
	addq $RECORD_FIRSTNAME, %rcx
	int $LINUX_SYSCALL
	
	pushq ST_OUTPUT_DESCRIPTOR(%rbp)
	call write_newline
	addq $8, %rsp
	jmp record_read_loop
	
finished_reading:
	pushq record_buffer_ptr
	call deallocate
	movq $SYS_EXIT, %rax
	movq $0, %rbx
	int $LINUX_SYSCALL
	

