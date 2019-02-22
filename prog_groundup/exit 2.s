#PURPOSE: Simple program that exits and returns a
# status code back to the Linux kernel
#
#INPUT: none
#
#OUTPUT: returns a status code. This can be viewed
# by typing
#
# echo $?
#
# after running the program
#
#VARIABLES:
# %eax holds the system call number
# %ebx holds the return status
#

#Every assembly program is separated in sections
#Section .data is kinda like a variable creation section
#We aren't declaring any variables, so there's nothing here
.section .data 

#Section .text is the... text section, what else could it be? 
#These two are kinda obligatory, I think
.section .text

#This is where the fun starts
#_start is like a function
#.globl tells the assembler to keep this "function" running the entire #program
.globl _start

#Here's the "function" _start
_start:
#Move the number 1 to eax (that's the system call code (1))
movl $1, %eax
#Move the number 42 to ebx (so Linux will have something to return #after the program is ran
#System call exit requires the program to return a value
movl $42, %ebx
#int (interrupt) returns the control to whoever started the program 
#(in this case, Linux Kernel)
int $0x80

