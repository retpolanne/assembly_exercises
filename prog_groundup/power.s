#PURPOSE: Program to illustrate how functions work
# This program will compute the value of
# 2^3 + 5^2
#
#NOTE: due to issues with 64bit architecture, rax was changed to rax
#With rax, we can pushq and popq what was supposed to be rax
#Also, we can't use pushl and popl
#Everything in the main program is stored in registers,
#so the data section doesn’t have anything.

#Note for 64bit: 8 bytes convention, not 4

.section .data

.section .text

.globl _start

_start:
	
	#####Calling the function the first time
	#To pushq arguments, do it in the inverse order
	#pushqing second argument
	pushq $3
	
	#pushqing first argument
	pushq $2
	
	#Call the function power
	call power
	
	#This happens when we get back from the function, I think
	#We need to movq the stack pointer (the one that moves between the code) 
	#back to where it was
	#As we had 2 parameters, we need to move rsp 16 bytes
	#We restore the esp to where it was before we pushed anything
	addq $16, %rsp
	
	#And we save the answer to rax
	pushq %rax
	
	#####Calling the function the second time
	#Remember that rax gets overwritten
	pushq $2
	pushq $5
	call power
	addq $16, %rsp
	
	#rax already has the first answer, popq the second to rbx
	popq %rbx
	
	#Now, the things we want
	#The first answer is in rax
	#The second answer is in rbx
	addq %rax, %rbx
	
	#####Ending the program
	#Exit system call (1)
	movq $1, %rax
	
	#Interrupt
	int $0x80
	
	
	
	
	
	########## FUNCTIONS
	#PURPOSE: This function is used to compute
	# the value of a number raised to
	# a power.
	#
	#INPUT: First argument - the base number
	# Second argument - the power to
	# raise it to
	#
	#OUTPUT: Will give the result as a return value
	#
	#NOTES: The power must be 1 or greater
	#
	#VARIABLES:
	# %rbx - holds the base number
	# %rcx - holds the power
	#
	# -4(%rbp) - holds the current result
	#
	# %rax is used for temporary storage
	#
	
	#I think this is obligatory for when declaring functions
	#They are of the parts of the same function, so we use ".type power, @function"
	.type power, @function
	
	power:
		#Now I understand, we save the base pointer (as the base pointer points
		#the addqress at the top of the parameters)
		pushq %rbp
		
		#movqe rsp to rbp
		movq %rsp, %rbp
		
		#Make room for local storage
		#Local storage will be addqresses rbp - 4, rbp - 8, etc.
		subq $8, %rsp
		
		#First arg to rbx
		movq 16(%rbp), %rbx
		
		#Second arg to rcx
		movq 24(%rbp), %rcx
		
		#Store current result
		#Probably in a local variable
		movq %rbx, -8(%rbp)
		
	power_loop_start:
		#If power is 1, end function
		cmp $1, %rcx
		je end_power
		
		#movqe current result into %rax (so we can return and use it later)
		movq -8(%rbp), %rax
		
		#Multiply current result by base number(?)
		imulq %rbx, %rax
		
		#Store current result
		movq %rax, -8(%rbp)
		
		#Decrease the power
		dec %rcx
		
		#Run next power
		jmp power_loop_start
	 
	end_power:
		#Return value is stored in rax
		movq -8(%rbp), %rax
		
		#Restore stack pointer
		movq %rbp, %rsp
		
		#Restore base pointer
		popq %rbp
		
		#Return value
		ret
		