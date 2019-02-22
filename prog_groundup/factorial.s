#PURPOSE - Given a number, this program computes the
# factorial. For example, the factorial of
# 3 is 3 * 2 * 1, or 6. The factorial of
# 4 is 4 * 3 * 2 * 1, or 24, and so on.
#
#This program shows how to call a function recursively.

.section .data

.section .text

.globl _start

#Maybe we can use the function among other programs
#Kinda like a prototype
.globl factorial

_start:
	#The only argument - as we want the factorial of this number
	pushq $4
	
	#Run the function
	call factorial
	
	#Scrubs the parameter that was pushqed on the stack
	addq $8, %rsp
	
	#Return is done in rax, but we want to send it as our exit status
	#so we mov to rbx
	movq %rax, %rbx
	
	#System call and interruption
	movq $1, %rax
	int $0x80
	
#Actual function definition
.type factorial, @function

factorial:
	
	#pushq rbp so we can restore it to prior state before returning
	pushq %rbp
	
	#As we don't want to modify stack pointer, move it to rbp
	movq %rsp, %rbp
	
	#4(%rbp) holds return
	#8(%rbp) holds first parameter
	#-4(%rbp) holds first local var
	#Mov first arg to rax
	movq 16(%rbp), %rax
	
	#Compare: if 1, then we return (1 is already in rax as the return value)
	#Remember: 1 is our latest multiplication
	cmpq $1, %rax
	
	je end_factorial
	
	#Otherwise, decrease rax
	decq %rax
	
	#pushq it again for our call to factorial
	pushq %rax
	call factorial
	
	#rax has the return, we reload our parameter to rbx
	movq 16(%rbp), %rbx
	
	#multiply it by the result of the last call to factorial (in rax)
	#return values will still go to rax, that's cool
	imulq %rbx, %rax
	
end_factorial:
	#Store rbp and rsp to were they where before the function started
	movq %rbp, %rsp
	popq %rbp
	ret