.data
	message: .asciiz "Hola Mundo"

.text
	li $v0, 4
	la $a0, message
	syscall
