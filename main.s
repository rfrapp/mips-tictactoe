# ============================================================================
# Authors:
# Ryan Frappier, Faizal Glenn
#
# Description:
# This is a simple tic-tac-toe game with a basic AI.
#
# Register usage: $s0 = input_row
#   			   $s1 = input_col
#				$s3
#
# ============================================================================

      	          .text
      	          .globl main

PRINTBOARD:
                    addiu $sp, $sp, -4
                    sw $ra, 0($sp)

		li $t0, 3		# t0 = rows and cols = 3
		li $t1, 0		# t1 = row = 0
		li $t3, 0 		# t3 = i = 0

		la $a0, BORDER1  #print “------- /n”
		li $v0, 4
		syscall


# for (int row = 0; row < rows; row++)
PRINTBOARD_OUTERLOOP:
		beq $t1, $t0, PRINTBOARD_BOTTOM
                    li $t2, 0 		# t2 = col = 0

                    la $a0, BORDER2  #print “|”
		li $v0, 4
		syscall


# for (int col = 0; col < cols; ++col)
PRINTBOARD_INNERLOOP:
		beq $t2, $t0, PRINTBOARD_OUTERLOOP_BOTTOM

		# Print board[i]
		la $a0, BOARD
		add $a0, $a0, $t3 		# &board[i]
                    lb $a0, 0($a0)
		li $v0, 11
		syscall

		la $a0, BORDER2  #print “|”
		li $v0, 4
		syscall

                    # li $v0, 1
                    # move $a0, $t3
                    # syscall

		addiu $t3, $t3, 1 	# ++i
                    addiu $t2, $t2, 1   # ++cols

                    j PRINTBOARD_INNERLOOP

PRINTBOARD_OUTERLOOP_BOTTOM:
		addiu $t1, $t1, 1		# ++row

		la $a0, NEWLINE
		li $v0, 4
		syscall

		# if (row == 2) continue;
		li $t4, 3
		beq $t1, $t4, PRINTBOARD_OUTERLOOP

		li $v0, 4
		la $a0, BORDER0
		syscall

		j PRINTBOARD_OUTERLOOP

# return;
PRINTBOARD_BOTTOM:
		la $a0, BORDER1 #print “------- /n”
		li $v0, 4
		syscall

                    lw $ra, 0($sp)
                    addiu $sp, $sp, 4
		jr $ra

main:
GAMELOOP:
		jal PRINTBOARD

                    li    $v0, 4
	          la   $a0, INPUTROW
	          syscall

                    li    $v0, 5 #get row selection from user
   		syscall
   		move $s0, $v0

		li    $v0, 4
	          la   $a0, INPUTCOLUMN
	          syscall

		li    $v0,5 #get column selection from user
   		syscall
   		move $s1, $v0

		j GAMELOOP

EXIT:
      		li    	$v0, 10
      		syscall

# -------
# | | | |
# |-----|
# | |X| |
# |-----|
# | | |O|
# -------

      		.data
INPUTROW: 		.asciiz "Enter row: "
INPUTCOLUMN: 	.asciiz "Enter column: "
BORDER0: 		.asciiz "|-----|\n"
BORDER1: 		.asciiz "------- \n"
BORDER2:		.asciiz "|"
NEWLINE:		.asciiz "\n"


BOARD:		.asciiz "         "
