.set noreorder
.set noat
.globl __start
.section text

__start:
.text
		li $a0, 0	# ave
	li $a1, 0	# 10个平均值的加和
	li $a2, 0x80400000	#数组a的基础地址
	li $a3, 0x80600000	#数组b的基础地址
	li $v0,	0		#对a排序循环变量
	li $v1, 10		#常量10
	li $s0, 0		#存3000个总分循环变量
	li $s1, 3000		#常量3000
loop2:	beq $s0, $s1, next2
	nop
	li $v0, 0
loop1:	
	beq $v0, $v1, next1
	ori $t6, $0, 0	# t6 = i
	ori $t7, $0, 7	#每8个元素排一次序，t7 = n-1
place1:	ori $t5, $0 ,0 	# t5 = j
	addiu $t0, $0, -1	# t0 = -1
	xor $t0, $t6, $t0	# t0 = -i
	addiu $t0, $t0 , 1	# t0 = -i + 1
	addu $t4, $t7, $t0	# t4 = n - 1 - i
place2:	addu $t3, $a2, $t5	# *a[j]
	lb $t1, 0($t3)		# t1 = a[j]
	lb $t2, 1($t3)		# t2 = a[j+1]
	subu $t0, $t1, $t2
	bgtz $t0, swapend1
	nop
	xor $t2, $t2, $t1
	xor $t1, $t1, $t2
	xor $t2, $t2, $t1
swapend1:
	sb $t1, 0($t3)		# a[j] = t1
	sb $t2, 1($t3)		# a[j+1] = t2
	addiu $t5, $t5, 1	# j + 1
	bne $t5, $t4, place2
	nop	
	addiu $t6, $t6, 1	
	bne $t6, $t7, place1
	nop
	lb $t0, 2($a2)		# t0 = a[2]
	lb $t1, 3($a2)		# t1 = a[3]
	lb $t2, 4($a2)		# t2 = a[4]
	lb $t3, 5($a2)		# t3 = a[5]
	addiu $a2, $a2, 8
	li $a0, 0
	addu $a0, $a0, $t0
	addu $a0, $a0, $t1
	addu $a0, $a0, $t2
	addu $a0, $a0, $t3
	srl $a0, $a0, 2		#此时a0为ave
	addu $a1, $a1, $a0	#将一个ave存放在选手总分变量a1中
	addiu $v0, $v0, 1	#循环变量v0+1
	j loop1
	nop
next1:	sll $s2, $s0, 2
	addu $s2, $s2, $a3	#得到要存放在数组b的地址
	sw $a1, 0($s2)		#把每一个平均值加和存放在数组b相应位置中
	li $a1, 0
	addiu $s0, $s0, 1	#总分循环变量s0+1
	j loop2
	nop
next2:	ori $t6, $0, 0		# t6 = i
	ori $t7, $0, 2999	# 需要排序3000次，n-1= 2999
place3:	ori $t5, $0, 0		# t5 = j
	addiu $t0, $0, -1 	# t0 = -1
	xor $t0, $t6, $t0	# t0 = -i
	addiu $t0, $t0, 1	# t0 = -i + 1
	addu $t4, $t7, $t0	# t4 = n - 1 - i
place4:	ori $t0, $0, 2
	sllv $t0, $t5, $t0	# t0 = 4*j
	addu $t3, $a3, $t0	# *a[j]
	lw $t1, 0($t3)		# t1 = a[j]
	lw $t2, 4($t3)		# t2 = a[j+1]
	subu $t0, $t1, $t2
	bgtz $t0, swapend2
	nop
	xor $t2, $t2, $t1
	xor $t1, $t1, $t2
	xor $t2, $t2, $t1
swapend2:
	sw $t1, 0($t3)		# a[j] = t1
	sw $t2, 4($t3)		# a[j+1] = t2
	addiu $t5, $t5, 1	# j + 1
	bne $t5, $t4, place4
	nop
	addiu $t6, $t6, 1	# i + 1
	bne $t6, $t7, place3
	nop
final:
	jr $ra
	
	
	
	