# Fib recursivo
.data
	input: .asciiz "Ingrese en numero n: "
	output: .asciiz "Resultado: "
	error: .asciiz "Valor no permitido"
	
.text
.globl main
	main:
		# --------------------------------------------
		#  MENSAJES DE ENTRADA Y LEER VALOR
		# --------------------------------------------
		
		# mostrar mensaje "Ingrese en numero n: "
		li $v0, 4
		la $a0, input
		syscall
		
		# leer valor n
		li $v0, 5
		syscall
		move $t0, $v0	# mover valor a $t0
		
		# incrementar $t0 en 1
		add $t0, $t0, 1
		
		# --------------------------------------------
		# evaluar $t0 para determinar el caso
		# --------------------------------------------

		# caso error: si $t0 < 1
		blt $t0, 1, caso_error
		
		# caso 1: si $t0 == 1
		beq $t0, 1, caso_1
		regreso_caso_1:

		# caso 2: si $t0 == 2
		beq $t0, 2, caso_2
		regreso_caso_2:
		
		# llamada recursiva			# si $t0 >=3
		move $a0, $t0				# argumento 1 (n)
		li $a1, 0					# argumento 2 (0) 
		li $a2, 1					# argumento 3 (1)
		bge $t0, 3, llamadafibRecursivo

		# --------------------------------------------
		# FIN DEL PROGRAMA
		# --------------------------------------------
		
		regreso_caso_error:
		li $v0, 10
		syscall
	
	
	# --------------------------------------------
	# FUNCIONES
	# --------------------------------------------

	# ********************************************
	# llamadafibRecursivo: llama a fibRecursivo 
	# con los argumentos adecuados y muestra el
	# resultado
	# ********************************************
	llamadafibRecursivo:
		jal fibRecursivo
		
		# mostrar resultado
		move $a0, $v0
		jal mostrar
		
		# fin de programa
		li $v0, 10
		syscall

	# ********************************************
	# caso_error: maneja el caso de error
	# cuando el valor ingresado es menor que 1
	# y muestra un mensaje de error
	# ********************************************
	caso_error:
		# devolver 0
		li $v0, 4
		la $a0, error
		syscall
		
		# regresar
		j regreso_caso_error

	# ********************************************
	# caso_1: maneja el caso cuando el valor
	# ingresado es 1, y muestra el resultado
	# que es 0
	# ********************************************
	caso_1:
		# devolver 0
		li $a0, 0
		jal mostrar
		
		# regresar
		j regreso_caso_1

	# ********************************************
	# caso_2: maneja el caso cuando el valor
	# ingresado es 2, y muestra el resultado
	# que es 1
	# ********************************************
	caso_2:
		# devolver 1
		li $a0, 1
		jal mostrar
		
		# regresar
		j regreso_caso_2

	
	# ********************************************
	# mostrar: muestra el valor recibido en $a0
	# en la consola. Guarda el valor de $ra en la
	# pila antes de mostrar y lo recupera al final.
	# ********************************************	
	mostrar:
		# guardar en pila $ra
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		
		# guardar valor a mostrar en $t6
		move $t6, $a0
		
		# mostrar mensaje "Resultado: "
		li $v0, 4
		la $a0, output
		syscall
	
		# mostrar el valor guardado en $t6
		li $v0, 1
		move $a0, $t6
		syscall
		
		# cargar desde pila $ra
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		
		# regresar al momento de la llamada
		jr $ra

	# ********************************************
	# fibRecursivo: función recursiva que
	# calcula el n-ésimo número de Fibonacci.
	# Recibe tres argumentos:
	#   - $a0: el índice n (número de Fibonacci a calcular)
	#   - $a1: el valor de Fibonacci en n-2 (inicialmente 0)
	#   - $a2: el valor de Fibonacci en n-1 (inicialmente 1)
	# ********************************************	
	fibRecursivo: # (N, 0, 1)
		# Reservamos espacio en la pila
		addi $sp, $sp, -16
		sw $ra, 0($sp)
		sw $a0, 4($sp)
		sw $a1, 8($sp)
		sw $a2, 12($sp)
		
		# Evaluar el caso base $a0 == 3
		# ya que los casos 1 y 2 ya fueron evaluados
		# en las funciones caso_1 y caso_2.
		beq $a0, 3, caso_base
		
		# preparar argumentos para la llamada recursiva
		move $t0, $a2		# $a2 en $t0
		add $a2, $a1, $t0	# $a2 = f(n-2) + f(n-1)
		move $a1, $t0		# $a1 = f(n-1)
		addi $a0, $a0, -1	# $a0 = n - 1

		# llamada recursiva a fibRecursivo
		# pasamos $a0 (n-1), $a1 (F(n-2)), $a2 (F(n-1))
		# y guardamos el resultado
		# en $v0		
		jal fibRecursivo
		
		# recuperar de la pila
		addi $sp, $sp, 16
		lw $ra, 0($sp)
		lw $a0, 4($sp)
		lw $a1, 8($sp)
		lw $a2, 12($sp)
		
		# regresar el punto donde se llamó
		jr $ra

		# este es el caso base
		# cuando $a0 == 3, que es el primer caso
		caso_base:
			# caso base
			add $v0, $a1, $a2
			
			# regresar
			jr $ra
