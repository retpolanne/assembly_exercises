#PURPOSE: This program finds the minimum number of a
# set of data items.
#
#VARIABLES: The registers have the following uses:
#
# %edi - Holds the index of the data item being examined
# %ebx - Largest data item found
# %eax - Current data item
#
# The following memory locations are used:
#
# data_items - contains the item data. A 0 is used
# to terminate the data
#

#Remember: (:) is used to assign values, like the (=)

.section .data

data_items:
	.long 0,67,34,222,45,75,54,34,44,33,22,11,66,3

.section .text

	.globl _start
		
	_start:
		#edi is the index, we start with 14
		movl $14, %edi
		
		#Load first byte of data to eax (current data item)
		#(, index, size) I suppose
		movl data_items(, %edi, 4), %eax   
		
		#The first time the program is ran, the first item will be the lowest
		movl %eax, %ebx

	start_loop:
		#check if we hit the end (by comparing zero with the current data
		cmpl $0, %eax
		
		#This is a jump, the e stands for equal
		je loop_exit
		
		#Load next value
		#decl is decrement, or the -- symbol
		decl %edi
		
		#Move data to current (again)
		movl data_items(,%edi, 4), %eax
		
		cmpl %ebx, %eax
		
		#If they are equal, then repeat the loop
		#Because ebx is the highest value
		#l - less, e - equal
		jge start_loop
		
		movl %eax, %ebx
		
		#Unconditional jump
		jmp start_loop


	loop_exit:
		#eax is the system call
		#ebx has the greatest number which will be shown
		movl $1, %eax
		int $0x80