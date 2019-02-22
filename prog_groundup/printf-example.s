#PURPOSE: This program is to demonstrate how to call printf
#

.section .data
	#This string is called the format string. It’s the first
	#parameter, and printf uses it to find out how many parameters
	#it was given, and what kind they are.
	firststring:
		.ascii "Hello! %s is a %s who loves the number %d\n\0"
	name:
		.ascii "Alice\0"
	personstring:
		.ascii "person\0"
	#This could also have been an .equ, but we decided to give it
	#a real memory location just for kicks
	numberloved:
		.long 3
		
.section .text
	.globl _start
	_start:
		#note that the parameters are passed in the
		#reverse order that they are listed in the
		#function’s prototype.
		#This is the %d
		pushq numberloved
		#This is the second %s
		pushq $personstring
		#This is the first %s
		pushq $name
		#This is the format string in the prototype
		pushq $firststring
		
		call printf
		pushq $0
		call exit