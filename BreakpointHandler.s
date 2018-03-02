.data 0xFFFF0000
	tControl: .space 4
	tData: .space 4
	pCotrol: .space 4
	pData: .space 4

.data 0x10000000
	buffer: .space 0
	
.text 0x00400000
main:
	jal LeerTeclado
	j main
	
LeerTeclado:
	lb $a0 tControl
	beqz $a0, LeerTeclado
	
	lb $a0, tData
	beq $a0, 0x14, bucle
	
	sb $a0, buffer($t1)
	addi $t1, $t1, 1
		
	jr $31
	
bucle:
	li $t2, 0x20
	sb $t2, buffer($t1)
	addi $t1, $t1, 1
	break 5
	
	jr $31

BreakException:
	li $v0, 4
	la $a0, buffer
	syscall
	
	jr $31
