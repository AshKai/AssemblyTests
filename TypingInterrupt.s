.data 0xFFFF0000
	tControl: .space 4
	tData:	  .space 4
	pControl: .space 4
	pData:	  .space 4
		
.data 0x10000000
	StartF: .asciiz "\nPulsar cnt+s cuando esté listo para empezar la prueba\n"
	PulsacionesM: .asciiz "\nPulsaciones/minuto = "
	enter: .asciiz "\n"
	counter: .word 0
	hour: .word 0
	minutes: .word 0
	seconds: .word 0
	flag: .word 0
	value: .word 1
	value0: .word 0

.text 0x400000
main:
	li $v0, 4
	la $a0, StartF
	syscall				#imprime frase inicial"
	
leeS:
	li $t2, 0x13		#espera hasta que se lea ctrl+s
	lb $a0, tData
	beq $a0, $t2, startP
	j leeS
	
lee:
	jal LeerTeclado
	j lee

LeerTeclado:
	lw $t6 flag			#si flag es 0 vuelve al main
	beqz $t6 main
	
	lb $t1, tControl
	beqz $t1, LeerTeclado
	
	lw $t1, counter
	addi $t1, $t1, 1		#incrementa counter pulsación
	sw $t1, counter	
	
	lb $a0, tData

PrintCharacter:
	sb $a0, pData
	jr $31
	
timerIntrEnable:
	mfc0 $t0, $12		#registro status
	ori $t0, $t0, 0x8001#mascara activación interrupciones timer
	mtc0 $t0, $12
	la $t0, 6000		#cada minuto interrumpirá
	mtc0 $t0,$11		#registro compare
	mtc0 $0, $9			#limpia registro count

	la $t9 flag		#flag a 1 (activadas)
	lw $t8 value
	sw $t8 0($t9)
	
	jr $31
	
.globl timeIntr
timeIntr:
	mtc0 $0, $9			#limpia registro count

	li $v0, 4
	la $a0, PulsacionesM
	syscall				#imprime Pulsaciones/minuto = "
	
	lw $t8, counter
	li $v0, 1
	move $a0, $t8
	syscall				#imprime número de pulsaciones
	
	la $t2 counter
	sw $0 0($t2)		#resetea counter
	
	li $v0, 4
	la $a0, enter
	syscall				#imprime \n"
	
	mfc0 $t0, $12		#registro status
	andi $t0, $t0, 0x0  #mascara desactivación interrupciones
	mtc0 $t0, $12
	la $t0, 0
	mtc0 $t0,$11		#registro compare a 0
	
	la $t5 flag
	lw $t6 value0
	sw $t6 0($t5)		#flag a 0 (desactivadas)
	
	jr $31
	
startP:
	jal timerIntrEnable
	jal lee