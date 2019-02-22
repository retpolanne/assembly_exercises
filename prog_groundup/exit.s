.section .data
.section .text
_start:
movl $1, %eax      # this is the linux kernel command
# number (system call) for exiting
# a program
movl $0, %ebx      # this is the status number we will
# return to the operating system.
# Change this around and it will
# return different things to
# echo $?
int $0x80
