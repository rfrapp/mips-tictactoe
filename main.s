# ============================================================================
# Authors:
# Ryan Frappier, Faizal Glenn
#
# Description:
# This is a simple tic-tac-toe game with a basic AI.
#
# Register usage:
# s0 = input_row
# s1 = input_col
# s2 = n (numrows/numcols)
#
# ============================================================================

      	.text
      	.globl main

# Prints a line of '+-...+-+' depending on the size of the
# board.
# Input:
#         a0 = n = size of board (int)
# Output:
#         (void)
PRINTLINE:
          la        $t0, BORDER0     # Load string "+-"
          move      $t1, $a0

# while (n > 0)
#         print '+-'
# print '+'
PRINTLINE_LOOP:
          beqz      $t1, PRINTLINE_BOTTOM

          # Print '+-'
          move      $a0, $t0
          li        $v0, 4
          syscall

          addi      $t1, $t1, -1
          j         PRINTLINE_LOOP

PRINTLINE_BOTTOM:
          # Print '+'
          la        $a0, PLUS
          li        $v0, 4
          syscall

          jr        $ra

# Prints a Tic-Tac-Toe board of size n.
# Input:
#         a0 = n
# Output:
#         (void)
# Registers:
#         t0 = n = numrows/numcols
#         t1 = row (counter for outer for loop)
#         t2 = col (counter for inner for loop)
#         t3 = i = (running index for printing the board elements)
#         t4 = (temporary for operations)
#         t5 = (temporary for operations)
#         t6 = (temporary for operations) = 2n + 1
PRINTBOARD:
          # Save the return address.
          addiu     $sp, $sp, -4
          sw        $ra, 0($sp)

	move      $t0, $a0	# t0 = rows and cols = n
	li        $t1, 0		# t1 = row = 0
	li        $t3, 0 	# t3 = i = 0

          li        $t6, 0
          add       $t6, $t6, $t0   # t6 = t0 = n
          add       $t6, $t6, $t0   # t6 = 2 * t0 = 2 * n
          addiu     $t6, $t6, 1

# for (int row = 0; row < rows; row++)
PRINTBOARD_OUTERLOOP:
	beq       $t1, $t6, PRINTBOARD_BOTTOM
          li        $t2, 0 	# t2 = col = 0

          li        $t4, 2
          div       $t1, $t4
          mfhi      $t4

          # if (row % 2 == 1) {
          li        $t5, 1
          beq       $t4, $t5, PRINTBOARD_INNERLOOP_START
          # }

          # else { print '+-...+-+' }

          move      $a0, $t0

          # Save t0, t1
          addi      $sp, $sp, -8
          sw        $t0, 0($sp)
          sw        $t1, 4($sp)

          jal       PRINTLINE

          # Load t0, t1 back
          lw        $t1, 4($sp)
          lw        $t0, 0($sp)
          addiu     $sp, $sp, 8

          j         PRINTBOARD_OUTERLOOP_BOTTOM

PRINTBOARD_INNERLOOP_START:
          la        $a0, PIPE     # print “|”
	li        $v0, 4
	syscall

# for (int col = 0; col < cols; ++col)
PRINTBOARD_INNERLOOP:
	beq       $t2, $t0, PRINTBOARD_OUTERLOOP_BOTTOM

	# Print board[i]
	la        $a0, BOARD
	add       $a0, $a0, $t3 	  # &board[i]
          lb        $a0, 0($a0)
	li        $v0, 11
	syscall

	la        $a0, PIPE          # print “|”
	li        $v0, 4
	syscall

	addiu     $t3, $t3, 1 	  # ++i
          addiu     $t2, $t2, 1     # ++cols

          j         PRINTBOARD_INNERLOOP

PRINTBOARD_OUTERLOOP_BOTTOM:
	addiu     $t1, $t1, 1		# ++row

	la        $a0, NEWLINE
	li        $v0, 4
	syscall

	j         PRINTBOARD_OUTERLOOP

# return;
PRINTBOARD_BOTTOM:
	li        $v0, 4
	syscall

          lw        $ra, 0($sp)
          addiu     $sp, $sp, 4
	jr        $ra

main:
          # get n from the user
          li        $v0, 5
          syscall
          move      $s2, $v0
          la        $t0, BOARD
          li        $t1, 0
          mul       $t2, $s2, $s2

# Initializes an n x n board with spaces.
# Pseudocode:
#         for (int i = 0; i < n * n; ++i)
#                   board[i] = ' ';
# Registers used:
#         t0 = &board[0]
#         t1 = i
#         t2 = n * n
#         t3 = temporary for storing bytes in the data segment
#         t4 = &board[i]
INITBOARD:
          beq      $t1, $t2 INITBOARD_END

          # Load the ASCII char for space.
          li        $t3, 32

          # Get the address of board[i].
          add       $t4, $t0, $t1

          # Store a ' ' in board[i].
          sb        $t3, 0($t4)

          addiu     $t1, $t1, 1         # ++i
          j INITBOARD

# Add a null terminator to the board string.
INITBOARD_END:
          add       $t4, $t0, $t1       # get board[n]
          li        $t3, 0
          sb        $t3, 0($t4)         # board[n] = ' '

GAMELOOP:
          # Print n x n board.
          move      $a0, $s2
	jal       PRINTBOARD

          li        $v0, 4
          la        $a0, INPUTROW
          syscall

          li        $v0, 5 #get row selection from user
	syscall
	move      $s0, $v0

	li        $v0, 4
          la        $a0, INPUTCOLUMN
          syscall

	li        $v0, 5 # get column selection from user
	syscall
	move      $s1, $v0

	j         GAMELOOP

EXIT:
	li    	$v0, 10
	syscall

# +-+-+-+
# | | | |
# +-+-+-+
# | |X| |
# +-+-+-+
# | | |O|
# +-+-+-+

          .data
INPUTROW: 	.asciiz "Enter row: "
INPUTCOLUMN: 	.asciiz "Enter column: "
PIPE:		.asciiz "|"
PLUS:               .asciiz "+"
NEWLINE:		.asciiz "\n"
BORDER0:            .asciiz "+-"

BOARD:		.byte 0
