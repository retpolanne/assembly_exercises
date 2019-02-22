.include "record-def.s"
.include "linux.s"


.section .data
#Constant data of the records we want to write
#Each text data item is padded to the proper
#length with null (i.e. 0) bytes.
#.rept is used to pad each item. .rept tells
#the assembler to repeat the section between
#.rept and .endr the number of times specified.
#This is used in this program to add extra null
#characters at the end of each field to fill
#it up

	record1:
		.ascii "Alice\0"
		#Padding to 40 bytes
		.rept 31
		.byte 0
		.endr
		
		.ascii "Prisma\0"
		#Padding to 40 bytes
		.rept 31 
		.byte 0
		.endr
		
		.ascii "4242 S Prairie\nTulsa, OK 55555\0"
		#Padding to 240 bytes
		.rept 209 
		.byte 0
		.endr
		
		.long 45
		
	record2:
		.ascii "Bob\0"
		#Padding to 40 bytes
		.rept 32
		.byte 0
		.endr
		
		.ascii "Triangle\0"
		#Padding to 40 bytes
		.rept 33
		.byte 0
		.endr
		
		.ascii "4242 S Prairie\nTulsa, OK 55555\0"
		#Padding to 240 bytes
		.rept 203
		.byte 0
		.endr
		
		.long 29
		
	record3:
		.ascii "Carol\0"
		#Padding to 40 bytes
		.rept 32
		.byte 0
		.endr
		
		.ascii "Square\0"
		#Padding to 40 bytes
		.rept 31
		.byte 0
		.endr
		
		.ascii "500 W Oakland\nSan Diego, CA 54321\0"
		#Padding to 240 bytes
		.rept 206
		.byte 0
		.endr
		
		.long 36
		
#This is the name of the file we will write to
	file_name:
		.ascii "test.dat\0"
		.equ ST_FILE_DESCRIPTOR, -8
		
	.globl _start
		
	_start:
		#Copy the stack pointer to rbp
		movq %rsp, %rbp
		#Alocate space to hold the file descriptor
		subq $8, %rsp
		
		#Open the file
		movq $SYS_OPEN, %rax
		movq $file_name, %rbx
		#Create file if it doesn't exist and open for writing
		movq $0101, %rcx
		movq $0666, %rdx
		int $LINUX_SYSCALL
		
		#Store file descriptor away
		movq %rax, ST_FILE_DESCRIPTOR(%rbp)
		
		#Write the first record
		pushq ST_FILE_DESCRIPTOR(%rbp)
		pushq $record1
		call write_record
		addq $16, %rsp
		
		#Write the second record
		pushq ST_FILE_DESCRIPTOR(%rbp)
		pushq $record2
		call write_record
		addq $16, %rsp
		
		#Write the third record
		pushq ST_FILE_DESCRIPTOR(%rbp)
		pushq $record3
		call write_record
		addq $16, %rsp
		
		#Close the file descriptor
		movq $SYS_CLOSE, %rax
		movq ST_FILE_DESCRIPTOR(%rbp), %rbx
		int $LINUX_SYSCALL
		
		#Exit the program 
		movq $SYS_EXIT, %rax
		movq $0, %rbx
		int $LINUX_SYSCALL