#PURPOSE: This program converts an input file
# to an output file with all letters
# converted to uppercase.
#
#PROCESSING: 1) Open the input file
# 2) Open the output file
# 4) While we’re not at the end of the input file
# a) read part of file into our memory buffer
# b) go through each byte of memory
# if the byte is a lower-case letter,
# convert it to uppercase
# c) write the memory buffer to output file

.section .data
	
	##### CONSTANTS #####
	
	#System Call Numbers
	#Remember: .equ lets us use a label for numbers, specially in syscalls
	.equ SYS_OPEN, 5
	.equ SYS_WRITE, 4
	.equ SYS_READ, 3
	.equ SYS_CLOSE, 6
	.equ SYS_EXIT, 1
	
	#options for open (look at
	#/usr/include/asm/fcntl.h for
	#various values. You can combine them
	#by adding them or ORing them)
	#This is discussed at greater length
	#in "Counting Like a Computer"
	#In other words, Read and write only 
	.equ O_RDONLY, 0
	.equ O_CREAT_WRONLY_TRUNC, 03101
	
	#standard file descriptors
	.equ STDIN, 0
	.equ STDOUT, 1
	.equ STDERR, 2
	
	#system call interrupt
	.equ LINUX_SYSCALL, 0X80
	#Return value of read
	.equ END_OF_FILE, 0
	.equ NUMBER_ARGUMENTS, 2
	
.section .bss
	#Buffer - this is where the data is loaded into
	# from the data file and written from
	# into the output file. This should
	# never exceed 16,000 for various
	# reasons.
	.equ BUFFER_SIZE, 500
	#This sets up the buffer 
	.lcomm BUFFER_DATA, BUFFER_SIZE
	
.section .text
	#The freaking stack positions
	#I should really reread the chapter 4
	.equ ST_SIZE_RESERVE, 16
	.equ ST_FD_IN, -8
	.equ ST_FD_OUT, -16
	
	#Number of arguments
	.equ ST_ARGC, 0
	#Name of program
	.equ ST_ARGV_0, 8
	#Input file name
	.equ ST_ARGV_1, 16
	#Output file name
	.equ ST_ARGV_2, 24
	
.globl _start

_start:
	###INITIALIZE PROGRAM###
	#save the stack pointer
	#interesting that it saves the esp before pushing
	movq %rsp, %rbp
	
	#and then, subtract esp to reserve space
	#haven't pushed anything yet
	subq $ST_SIZE_RESERVE, %rsp
	
	###FUNCTIONS###
	open_files:
	open_fd_in:
		###OPEN INPUT FILE###
		#These are the parameters for Linux Syscall
		
		#open syscall	
		movq $SYS_OPEN, %rax
		
		#input filename into rbx
		#This is like 4(%ebp)
		#Base pointer addressing mode
		movq ST_ARGV_1(%rbp), %rbx
		
		#read-only flag
		movq $O_RDONLY, %rcx
		
		#this doesn't matter for reading
		#movq $0666, %rdx
		
		#Call Linux
		int $LINUX_SYSCALL
		
	store_fd_in:
		#Save the given file descriptor
		#Again, like the 4(%ebp) mode 
		movq %rax, ST_FD_IN(%rbp)
		
	open_fd_out:
		###OPEN OUTPUT FILE###
		
		#open the file
		movq $SYS_OPEN, %rax
		
		#output filename into rbx
		movq ST_ARGV_2(%rbp), %rbx
		
		#flags for writing to the file
		movq $O_CREAT_WRONLY_TRUNC, %rcx
		
		#mode for new file (if it's created)
		movq $0666, %rdx
		
		#call Linux
		int $LINUX_SYSCALL
		
	store_fd_out:
		#store the file descriptor here
		movq %rax, ST_FD_OUT(%rbp)
		
	
	###BEGIN MAIN LOOP###
	read_loop_begin:
		
		###READ IN A BLOCK FROM THE INPUT FILE###
		movq $SYS_READ, %rax
		#get the input file descriptor
		movq ST_FD_IN(%rbp), %rbx
		#the location to read into
		movq $BUFFER_DATA, %rcx
		#the size of the buffer
		movq $BUFFER_SIZE, %rdx
		#Size of buffer read is return in %rax
		int $LINUX_SYSCALL
		
		###EXIT IF WE'VE REACHED THE END###
		#check for end of file marker
		cmpq $END_OF_FILE, %rax
		#if found or on error, go to the end
		jle end_loop
		
	continue_read_loop:
		###CONVERT THE BLOCK TO UPPER CASE###
		#location of buffer
		pushq $BUFFER_DATA
		#size of the buffer
		pushq %rax
		
		call convert_to_upper
		
		#get the size back
		popq %rax
		#restore esp
		addq $8, %rsp
		
		###WRITE THE BLOCK OUT TO THE OUTPUT FILE###
		movq %rax, %rdx
		movq $SYS_WRITE, %rax
		#file to use
		movq ST_FD_OUT(%rbp), %rbx
		#location of the bugger
		movq $BUFFER_DATA, %rcx
		int $LINUX_SYSCALL
		
		###CONTINUE THE LOOP###
		jmp read_loop_begin
		
	end_loop:
		###CLOSE THE FILES###
		#NOTE - we don’t need to do error checking
		# on these, because error conditions
		# don’t signify anything special here
		movq $SYS_CLOSE, %rax
		movq ST_FD_OUT(%rbp), %rbx
		int $LINUX_SYSCALL
		
		movq $SYS_CLOSE, %rax
		movq ST_FD_IN(%rbp), %rbx
		int $LINUX_SYSCALL
		
		##EXIT
		movq $SYS_EXIT, %rax
		movq $0, %rbx
		int $LINUX_SYSCALL
	#PURPOSE: This function actually does the
	# conversion to upper case for a block
	#
	#INPUT: The first parameter is the location
	# of the block of memory to convert
	# The second parameter is the length of
	# that buffer
	#
	#OUTPUT: This function overwrites the current
	# buffer with the upper-casified version.
	#
	#VARIABLES:
	# %eax - beginning of buffer
	# %ebx - length of buffer
	# %edi - current buffer offset
	# %cl - current byte being examined
	# (first part of %ecx)
	#
	
	###CONSTANTS###
	#the lower bounday of our search
	.equ LOWERCASE_A, 'a'
	#the upper boundary of our search
	.equ LOWERCASE_Z, 'z'
	#conversion between upper and lower case
	#THIS IS A FREAKING SUBTRACTION OF ASCII, WOW
	#This is how much we need to add to the ascii to get to the lowercase letter
	.equ UPPER_CONVERSION, 'A' - 'a'
	
	###STACK STUFF###
	#Length of buffer
	.equ ST_BUFFER_LEN, 16
	#Actual buffer
	.equ ST_BUFFER, 24
	
	
	convert_to_upper:
		pushq %rbp
		movq %rsp, %rbp
		
		#SET UP VARIABLES#
		movq ST_BUFFER(%rbp), %rax
		movq ST_BUFFER_LEN(%rbp), %rbx
		movq $0, %rdi
		
		#if a buffer with zero length was given to us, just leave
		cmpq $0, %rbx
		je end_convert_loop
		
	convert_loop:
		#get current byte
		movb (%rax, %rdi, 1), %cl
		
		#go to the next byte unless it is between 'a' and 'z'
		cmpb $LOWERCASE_A, %cl
		jl next_byte
		cmpb $LOWERCASE_Z, %cl
		jg next_byte
		
		#otherwise convert the byte to uppercase
		addb $UPPER_CONVERSION, %cl
		#and store it back
		movb %cl, (%rax, %rdi, 1)
		
	next_byte:
		#Next byte continue unless we've reached the end
		incq %rdi
		cmpq %rdi, %rbx
		jne convert_loop
		
	end_convert_loop:
		#no return value, just leave
		movq %rbp, %rsp
		popq %rbp
		ret 