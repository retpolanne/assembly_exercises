# Assembly Exercises

These are some exercises from the book [Programming from the Ground Up](https://download-mirror.savannah.gnu.org/releases/pgubook/ProgrammingGroundUp-1-0-booksize.pdf). It's a really amazing book that teaches the basics of programming from the point of view of a low level language such as Assembly.

The syntax used in this book is the x86, Intel syntax, not the AT&T syntax (which I prefer). The registers in this book are all 32 bit, and at the time I didn't know how to configure my compiler to be compatible with then, so I used mostly 64 bit registers.

Compiling the codes as I did back when I was practicing was simple.

```
as file.s -o file.o # Generate an output file
ld file.o -o file # Link the file

./file 

echo $? # Read the status code
```

I read this book in the summer of 2015/2016 and kept the files in my hard drive (which I presumed was long lost). 