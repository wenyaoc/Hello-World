
      .data
hello: .asciiz "Hello World"
eol:  .asciiz "\n"     # char *eol = "\n";

      .text
main:
      la   $a0, hello    # reg[a0] = &hello
      li   $v0, 4
      syscall           # printf("%s",hello)

      la  $a0, eol
      li  $v0, 4
      syscall           # printf("%s", eol)

      li  $v0, 0	# set return value to 0
      jr  $ra           # return from main
