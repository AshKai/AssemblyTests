.data 0xFFFF0000
tControl: .space 4
tData: .space 4
pControl: .space 4
pData: .space 4

.data 0x10000000
fraseExcepcion: .asciiz " [TrapException!!] "

.text 0x400000
main:
lee:
	jal LeerTeclado
	j lee

LeerTeclado:
	lb $t1, tControl
	beqz $t1, LeerTeclado

	li $t2, 0x13
	lb $a0, tData
	teq $a0, $t2

PrintCharacter:
	sb $a0, pData
	jr $31

TrapRutina:
	li $v0, 4
	la $a0, fraseExcepcion
	syscall
	jr $31