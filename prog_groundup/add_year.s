.include "linux.s"
.include "record-def.s"

.section .data

	input_file_name:
		.ascii "tast.dat\0"
		
	output_file_name:
		.ascii "testout.dat\0"
		
.section .bss
	.lcomm record_buffer, RECORD_SIZE
	
#Stack offsets of local variables
.equ ST_INPUT_DESCRIPTOR, -8
.equ ST_OUTPUT_DESCRIPTOR, -16

.section .text
	
	.globl _start
	
	_start:
		#Copy stack pointer and make room for local variables
		movq %rsp, %rbp
		subq $16, %rsp
		
		#Open file for reading
		movq $SYS_OPEN, %rax
		movq $input_file_name, %rbx
		movq $0, %rcx
		movq $0666, %rdx
		int $LINUX_SYSCALL
		
		movq %rax, ST_INPUT_DESCRIPTOR(%rbp)
		
		###ERROR HANDLING FROM CHAPTER 7
		#This will test and see if %eax is
		#negative. If it is not negative, it
		#will jump to continue_processing.
		#Otherwise it will handle the error
		#condition that the negative number
		#represents.
		cmpq $0, %rax
		jl continue_processing
		
		#Send the error
		.section .data
			no_open_file_code:
				.ascii "0001: \0"
			no_open_file_msg:
				.ascii "Can't open input file\0"
		.section .text
			pushq $no_open_file_msg
			pushq $no_open_file_code
			call error_exit
			
		
		continue_processing:
		#Rest of the program
		#Open file for writing
		movq $SYS_OPEN, %rax
		movq $output_file_name, %rbx
		movq $0101, %rcx
		movq $0666, %rdx
		int $LINUX_SYSCALL
		movq %rax, ST_OUTPUT_DESCRIPTOR(%rbp)
		
	loop_begin:
		pushq ST_INPUT_DESCRIPTOR(%rbp)
		pushq $record_buffer
		call read_record
		addq $16, %rsp
		
		#Returns the number of bytes read.
		#If it isn’t the same number we
		#requested, then it’s either an
		#end-of-file, or an error, so we’re
		#quitting
		cmpq $RECORD_SIZE, %rax
		jne loop_end
		
		#Increment the age
		incq record_buffer + RECORD_AGE
		
		#Write the record out
		pushq ST_OUTPUT_DESCRIPTOR(%rbp)
		pushq $record_buffer
		call write_record
		addq $16, %rsp
		
		jmp loop_begin
		
	loop_end:
		movq $SYS_EXIT, %rax
		movq $0, %rbx
		int $LINUX_SYSCALL