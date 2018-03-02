.data 0xFFFF0000
	tControl: .space 4
	tData:	  .space 4
	pControl: .space 4
	pData:	  .space 4
		
.data 0x10000000
	Sentence: .asciiz "Pulse Ctrl+R para ajustar la hora...\n"
	trapSentence: .asciiz "[Excepción de tipo trap detectada, parando ejecución del programa]"
	breakSentence: .asciiz "[Excepción de tipo breakpoint detectada, parando ejecución del programa]"
	s3: .asciiz "[Pulsacion("
	s4: .asciiz ")="
	s5: .asciiz "]"
	s6: .asciiz "\nIntroduzca los segundos: "
	s7: .asciiz "\nIntroduzca los minutos: "
	s8: .asciiz "\nIntroduzca la hora: "
	s9: .asciiz "\nLa hora local es: "
	s10: .asciiz "\nValor incorrecto, introduzca de nuevo(formato 23:59:59)."
	s11: .asciiz "\nPoner en hora, use el siguiente formato 23:59:59\nSi pone una letra el valor se le inciaria a 0\n"
	s12: .asciiz ":"
	s13: .word 0
	s14: .asciiz "\n"
	hour: .word 0
	minutes: .word 0
	seconds: .word 0
	delay: .word 150000
	counter : .word 0
	clean: .asciiz ""

.text 0x400000
main:
	jal kbdIntrEnable
	jal timerIntrEnable
			
init:
	la $a0,Sentence

sentenceLoop:
	lb $a1, 0($a0)
	beqz $a1, init		#cuando termine la frase carga la dirección otra vez
	jal printCharacter
	addi $a0, $a0, 1	#actualiza puntero de Sentence
	j sentenceLoop

printCharacter:
	lw $t0, pControl
	andi $t0, $t0, 1
	beqz $t0, printCharacter	#pantalla no preparada para mostrar dato (evitar que se muestren desordenados)
	sw $a1, pData				#muestra el dato por pantalla
	
	lw $a2, delay				#retardo de introduccion de siguiente letra

loopDelay:
	addi $a2, $a2, -1
	bnez $a2 loopDelay		#mientras delay no sea 0 no pasa a la siguiente letra
	jr $31
			
kbdIntrEnable:
	mfc0 $t0, $12		#registro status
	ori $t0,$t0,0x801	#mascara de activación de interrupciones teclado
	mtc0 $t0, $12
	lb $t2,tControl	
	ori $t2,$t2,2		#se activa el bit para interrupciones de teclado
	sb $t2,tControl	
	jr $31
	
timerIntrEnable:
	mfc0 $t0, $12		#registro status
	ori $t0, $t0, 0x8001#mascara activación interrupciones timer
	mtc0 $t0, $12
	mtc0 $0, $9			#limpia registro count
	la $t0, 100			#cada segundo interrumpirá
	mtc0 $t0,$11		#registro compare
	jr $31
	
.globl CaseIntr
CaseIntr:
	mfc0 $s1,$13		#registro cause
	
	srl $s4,$s1,11		#IP3
	andi $s4,$s4,1
	bnez $s4,kbdIntr	#si esta activado atiende interrupción de teclado
	
	srl $s4,$s1,15		#IP7
	andi $s4,$s4,1
	bnez $s4,timeIntr	#si esta activado atiende interrupción de timer
	
	jr $31
	
kbdIntr:
	#ctrl+r cambiar hora
	li $s2, 0x12
	lb $s7, tData
	beq $s7,$s2,setHour
	
	#ctrl+s frase más lenta
	li $s2, 0x13
	lb $s7, tData
	beq $s7,$s2,slow
	
	#ctrl+t frase más rápido
	li $t7, 0x14
	lb $s6, tData
	beq $s6,$t7,fast

	#ctrl+u frase velocidad igual que al principio
	li $t8, 0x15
	lb $s8, tData
	beq $s8,$t8,same
	
	#ctrl+v manejo de excepción trap
	li $t2, 0x16
	lb $a0, tData
	teq $a0, $t2
	
	#ctrl+w manejo de excepción breakpoint
	li $t2, 0x17
	lb $a0, tData
	beq $a0, $t2,break5

	li $v0, 4
	la $a0, s3
	syscall 			#imprime "[Pulsacion("
	
	lw $t8, counter
	addi $t8, $t8, 1
	sw $t8, counter	
	
	li $v0, 1
	move $a0, $t8
	syscall				#imprime número de pulsación
	
	li $v0, 4
	la $a0, s4
	syscall				#imprime ")="
	
	li $v0, 11
	lb $s3, tData
	move $a0, $s3
	syscall				#imprime el caracter pulsado
	
	li $v0, 4
	la $a0, s5
	syscall				#imprime "]"
	
	jr $31
	
timeIntr:
	mtc0 $0, $9			#limpia registro count
	
	lw $s3, seconds
	addi $s3,$s3,1
	sw $s3 seconds
	ble $s3,59,count
	sw $0,seconds
	
	lw $s1,minutes
	addi $s1,$s1,1
	sw $s1 minutes
	ble $s1,59,count
	sw $0,minutes
	
	lw $s2, hour
	addi $s2,$s2,1
	sw $s2, hour
	ble $s2,23,count
	sw $0,hour
	
	jr $31
	
errorClock:
	li $v0,4
	la $a0,s10
	syscall				#muestra mensaje de error
	
setHour:
	li $v0, 4
	la $a0, s11
	syscall				#muestra mensaje de poner en hora
	
	li $v0, 4
	la $a0, s6
	syscall				#muestra mensaje introducir segundos
	
	li $v0, 5
	syscall				#lee por teclado
	sw $31 s13
	bge $v0, 60, errorClock
	lw $31 s13

	lw $s3, seconds
	move $s3 $v0
	sw $s3 seconds			#almacena los segundos introducidos
	
	li $v0, 4
	la $a0, s7
	syscall					#muestra mensaje introducir minutos
	
	li $v0, 5
	syscall					#lee por teclado
	sw $31 s13
	bge $v0, 60, errorClock
	lw $31 s13
	
	lw $s3, minutes
	move $s3 $v0
	sw $s3 minutes			#almacena los minutos introducidos
	
	li $v0, 4
	la $a0, s8
	syscall					#muestra mensaje introducir hora
	
	li $v0, 5
	syscall					#lee por teclado
	sw $31 s13
	bge $v0, 24, errorClock
	lw $31 s13
	
	lw $s3, hour
	move $s3 $v0
	sw $s3 hour				#almacena las horas introducidas
	
	sw $31,s13
	jal count
	lw $31,s13
	
	jr $31
	
count:
	addi $s0 $s0 1
	li $s1 10
	beq $s0 $s1 showClock	#muestro la hora cada 10 segundos
	
	jr $31
	
showClock:
	li $v0,4 
	la $a0,s9
	syscall
	
	lw $s3, hour
	li $v0 1
	move $a0 $s3
	syscall
	
	li $v0 4
	la $a0 s12
	syscall
	
	lw $s3, minutes
	li $v0 1
	move $a0 $s3
	syscall
	
	li $v0 4
	la $a0 s12
	syscall
	
	lw $s3, seconds
	li $v0 1
	move $a0 $s3
	syscall
	
	li $v0 4
	la $a0 s14
	syscall
	
	li $s0 0	#restauro a 0 el contador de segundos
	
	jr $31
	
slow:
	li $a0, 300000
	sw $a0, delay
	jr $31

fast:
	li $a0, 150
	sw $a0, delay
	jr $31

same:
	li $a0, 150000
	sw $a0, delay
	jr $31
	
trapRoutine:
	li $v0, 4
	la $a0, trapSentence
	syscall
	j end
	
break5:
	break 5
	
breakRoutine:
	li $v0, 4
	la $a0, breakSentence
	syscall
	
end:
	nop