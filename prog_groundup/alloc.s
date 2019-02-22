#PURPOSE: Program to manage memory usage - allocates
# and deallocates memory as requested
#
#NOTES: The programs using these routines will ask
# for a certain size of memory. We actually
# use more than that size, but we put it
# at the beginning, before the pointer
# we hand back. We add a size field and
# an AVAILABLE/UNAVAILABLE marker. So, the
# memory looks like this
#
# #########################################################
# #Available Marker#Size of memory#Actual memory locations#
# #########################################################
# ^--Returned pointer
# points here
# The pointer we return only points to the actual
# locations requested to make it easier for the
# calling program. It also allows us to change our
# structure without the calling program having to
# change at all.

.section .data
	#######GLOBAL VARIABLES########
	#This points to the beginning of the memory we are managing
	heap_begin:
		.long 0
		
	#This points to one location past the memory we are managing
	current_break:
		.long 0
		
	######STRUCTURE INFORMATION####
	#size of space for memory region header
	.equ HEADER_SIZE, 16
	#Location of the "available" flag in the header
	.equ HDR_AVAIL_OFFSET, 0
	#Location of the size field in the header
	.equ HDR_SIZE_OFFSET, 8
	
	###########CONSTANTS###########
	#This is the number we will use to mark space that has been given out
	.equ UNAVAILABLE, 0
	#This is the number we will use to mark 
	#space that has been returned, and is available for giving
	.equ AVAILABLE, 1
	#system call number for the break system call
	.equ SYS_BRK, 45
	#make system calls easier to read
	.equ LINUX_SYSCALL, 0x80
	
.section .text
	##########FUNCTIONS############
	##allocate_init##
	#PURPOSE: call this function to initialize the
	# functions (specifically, this sets heap_begin and
	# current_break). This has no parameters and no
	# return value.
	.globl allocate_init
	.type allocate_init, @function
	
	allocate_init:
		#Standard function stuff
		pushq %rbp
		movq %rsp, %rbp
		
		#If the brk system call is called with 0 in %ebx, it
		#returns the last valid usable address
		
		#find out where the break is
		movq $SYS_BRK, %rax
		movq $0, %rbx
		int $LINUX_SYSCALL
		
		#%eax now has the last valid address, and we want the
		#memory location after that
		incq %rax
		
		#store the current break
		movq %rax, current_break
		
		#store the current break as our first address. This will cause
		#the allocate function to get more memory from Linux the
		#first time it is run
		movq %rax, heap_begin
		
		#exit the function
		movq %rbp, %rsp
		popq %rbp
		ret
		#####END OF FUNCTION#######
		
		
	##allocate##
	#PURPOSE: This function is used to grab a section of
	# memory. It checks to see if there are any
	# free blocks, and, if not, it asks Linux
	# for a new one.
	#
	#PARAMETERS: This function has one parameter - the size
	# of the memory block we want to allocate
	#
	#RETURN VALUE:
	# This function returns the address of the
	# allocated memory in %eax. If there is no
	# memory available, it will return 0 in %eax
	#
	######PROCESSING########
	#Variables used:
	#
	# %ecx - hold the size of the requested memory
	# (first/only parameter)
	# %eax - current memory region being examined
	# %ebx - current break position
	# %edx - size of current memory region
	#
	#We scan through each memory region starting with
	#heap_begin. We look at the size of each one, and if
	#it has been allocated. If it’s big enough for the
	#requested size, and its available, it grabs that one.
	#If it does not find a region large enough, it asks
	#Linux for more memory. In that case, it moves
	#current_break up
	.globl allocate
	.type allocate, @function
	#stack position of the memory size to allocate
	.equ ST_MEM_SIZE, 16
	
	allocate:
		#standard function stuff
		pushq %rbp
		movq %rsp, %rbp
		
		#%ecx will hold the size we are looking for (which is the first
		#and only parameter)
		movq ST_MEM_SIZE(%rbp), %rcx
		
		#%eax will hold the current search location
		movq heap_begin, %rax
		
		#%ebx will hold the current break
		movq current_break, %rbx
	
	#here we iterate through each memory region
	alloc_loop_begin:
		#need more memory if these are equal
		cmpq %rbx, %rax
		je move_break
		
		#grab the size of this memory
		movq HDR_SIZE_OFFSET(%rax), %rdx
		
		#If the space is unavailable, go to the
		cmpq $UNAVAILABLE, HDR_AVAIL_OFFSET(%rax)
		
		#next one
		je next_location
		
		#If the space is available, compare 
		#the size to the needed size. If its
		#big enough, go to allocate_here
		cmpq %rdx, %rcx
		jle allocate_here
		
	next_location:
		#The total size of the memory
		#region is the sum of the size
		#requested (currently stored
		#in %edx), plus another 16 bytes
		#for the header (8 for the
		#AVAILABLE/UNAVAILABLE flag,
		#and 8 for the size of the
		#region). So, adding %edx and $16
		#to %eax will get the address
		#of the next memory region
		addq $HEADER_SIZE, %rax
		addq %rdx, %rax
		
		#go look at the next location
		jmp alloc_loop_begin
		
	allocate_here:
		#if we’ve made it here,
		#that means that the
		#region header of the region
		#to allocate is in %eax
		
		#mark space as unavailable
		movq $UNAVAILABLE, HDR_AVAIL_OFFSET(%rax)
		
		#move %eax past the header to
		#the usable memory (since
		#that’s what we return)
		addq $HEADER_SIZE, %rax
		
		#return from function
		movq %rbp, %rsp
		pushq %rbp
		ret
		
	move_break:
		#if we’ve made it here, that
		#means that we have exhausted
		#all addressable memory, and
		#we need to ask for more.
		#%ebx holds the current
		#endpoint of the data,
		#and %ecx holds its size

		#we need to increase %ebx to
		#where we _want_ memory
		#to end, so we
		#add space for the headers
		#structure
		addq $HEADER_SIZE, %rbx
		
		#add space to the break for
		#the data requested
		addq %rcx, %rbx
		
		#now its time to ask Linux
		#for more memory
		
		#save needed registers
		pushq %rax
		pushq %rcx
		pushq %rbx
		
		#reset the break (%ebx has
		#the requested break point)
		movq $SYS_BRK, %rax
		
		int $LINUX_SYSCALL
		
		#under normal conditions, this should
		#return the new break in %eax, which
		#will be either 0 if it fails, or
		#it will be equal to or larger than
		#we asked for. We don’t care
		#in this program where it actually
		#sets the break, so as long as %eax
		#isn’t 0, we don’t care what it is

		#check for error conditions
		cmpq $0, %rax
		je error
		
		#restore saved registers
		popq %rbx
		popq %rcx
		popq %rax
		
		
		#set this memory as unavailable, since we’re about to
		#give it away
		movq $UNAVAILABLE, HDR_AVAIL_OFFSET(%rax)
		
		#set the size of the memory
		movq %rcx, HDR_SIZE_OFFSET(%rax)
		
		#move %eax to the actual start of usable memory.
		#%eax now holds the return value
		addq $HEADER_SIZE, %rax
		
		#save the new break
		movq %rbx, current_break
		
		#return the function
		movq %rbp, %rsp
		pushq %rbp
		ret
		
	error:
		#on error, we return zero
		movq $0, %rax
		movq %rbp, %rsp
		pushq %rbp
		ret
		########END OF FUNCTION########
		
	
	##deallocate##
	#PURPOSE:
	# The purpose of this function is to give back
	# a region of memory to the pool after we’re done
	# using it.
	#
	#PARAMETERS:
	# The only parameter is the address of the memory
	# we want to return to the memory pool.
	#
	#RETURN VALUE:
	# There is no return value
	#
	#PROCESSING:
	# If you remember, we actually hand the program the
	# start of the memory that they can use, which is
	# 16 storage locations after the actual start of the
	# memory region. All we have to do is go back
	# 16 locations and mark that memory as available,
	# so that the allocate function knows it can use it.
	
	.globl deallocate
	.type deallocate, @function
	
	#stack position of the memory region to free
	.equ ST_MEMORY_SEG, 8
	
	deallocate:
		#since the function is so simple, we
		#don’t need any of the fancy function stuff
		#get the address of the memory to free
		#(normally this is 16(%ebp), but since
		#we didn’t push %ebp or move %esp to
		#%ebp, we can just do 8(%esp)
		movq ST_MEMORY_SEG(%rsp), %rax
		
		#get the pointer to the real beginning of the memory
		subq $HEADER_SIZE, %rax
		
		#mark it as available
		movq $AVAILABLE, HDR_AVAIL_OFFSET(%rax)
		
		#return
		ret
		########END OF FUNCTION##########