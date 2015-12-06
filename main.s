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
# s3 = turncount = 0
#
# if (turncount % 2 == 0) AI's turn
# else Player's turn
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

# while (n > 0) {
#         print '+-'
#         n--
# }
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

          move      $t0, $a0            # t0 = rows and cols = n
          li        $t1, 0              # t1 = row = 0
          li        $t3, 0              # t3 = i = 0

          li        $t6, 0
          add       $t6, $t6, $t0       # t6 = t0 = n
          add       $t6, $t6, $t0       # t6 = 2 * t0 = 2 * n
          addiu     $t6, $t6, 1

# for (int row = 0; row < rows; row++)
PRINTBOARD_OUTERLOOP:
          beq       $t1, $t6, PRINTBOARD_BOTTOM
          li        $t2, 0 		# t2 = col = 0

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

AISTURN:

#===============================================================================================
#===============================================================================================

# Check to see if there is a winning move for the AI
# across rows, i.e.
#
#   +--+--+--+
#   |->|->|->|
# v +--+--+--+
#   |->|->|->|
# v +--+--+--+
#   |->|->|->|
#   +--+--+--+
#
# Register Usage:
#         t0 = i = 0
#         t1 = j = 0
#         t2 = numspaces = 0
#         t3 = numos = 0
#         t4 = index = -1
#         t5 = (temporary)
#         t6 = (temporary)
#         t7 = (temporary)
#         t8 = (temporary)
# Pseudocode:
#
# numspaces = 0
# numos = 0
# index = -1
# for (int i = 0; i < n; ++i) {
#   for (int j = 0; j < n; ++j) {
#     if (board[i * n + j] == 'X')
#       numos++;
#     if (board[i * n + j] == ' ') {
#       numspaces++;
#       index = i * n + j;
#     }
#   }
#   if (numspaces == 1 && numos == n - 1) {
#     board[index] = 'O';
#     break;
#   }
# }
AISTURN_WINNINGMOVE_CHECKROWS:
          li        $t0, 0              # i = 0
          li        $t1, 0              # j = 0

AISTURN_WINNINGMOVE_CHECKROWS_OUTERLOOP:
          beq       $t0, $s2, AISTURN_WINNINGMOVE_CHECKCOL  # No winning move found.
          li        $t1, 0                                  # j = 0
          li        $t2, 0                                  # numspaces = 0
          li        $t3, 0                                  # numos = 0
          li        $t4, -1

AISTURN_WINNINGMOVE_CHECKROWS_INNERLOOP:
          beq       $t1, $s2, AISTURN_WINNINGMOVE_CHECKROWS_OUTERLOOP_BOTTOM

          # if (board[i * n + j] == ' ')
          #   ++numspaces;
          mul       $t5, $t0, $s2       # t5 = i * n
          add       $t5, $t5, $t1       # t5 = i * n + j
          move      $t8, $t5            # t8 = t5
          la        $t6, BOARD
          addu      $t6, $t6, $t5
          lb        $t5, 0($t6)         # t5 = board[i * n + j]

          li        $t6, ' '
          beq       $t5, $t6, AISTURN_WINNINGMOVE_CHECKROWS_INNERLOOP_IF

          j         AISTURN_WINNINGMOVE_CHECKROWS_INNERLOOP_BOTTOM

AISTURN_WINNINGMOVE_CHECKROWS_INNERLOOP_IF:
          addiu     $t2, $t2, 1         # ++numspaces
          move      $t4, $t8            # index = i * n + j

AISTURN_WINNINGMOVE_CHECKROWS_INNERLOOP_BOTTOM:
          # if (board[i * n + j] == 'O')
          #   ++numspaces;
          li        $t6, 'O'
          seq       $t6, $t5, $t6       # t6 = (board[i * n + j] == ' ')
          addu      $t3, $t3, $t6       # numos += t6

          addiu     $t1, $t1, 1         # ++j

          j AISTURN_WINNINGMOVE_CHECKROWS_INNERLOOP

AISTURN_WINNINGMOVE_CHECKROWS_OUTERLOOP_BOTTOM:
          # if (numspaces == 1 && numos == n - 1)
          #   board[index] = 'O'
          li        $t5, 1
          seq       $t6, $t2, $t5       # t6 = (numspaces == 1)
          move      $t5, $s2
          addiu     $t5, $t5, -1        # t5 = n - 1
          seq       $t7, $t3, $t5       # t7 = (numos == n - 1)

          and       $t6, $t6, $t7       # t6 = t6 && t7

          li        $t5, 1
          beq       $t6, $t5, AISTURN_WINNINGMOVE_CHECKROWS_OUTERLOOP_EXIT

          addiu     $t0, $t0, 1         # ++i

          j AISTURN_WINNINGMOVE_CHECKROWS_OUTERLOOP

AISTURN_WINNINGMOVE_CHECKROWS_OUTERLOOP_EXIT:
          move      $t0, $t4

          # li        $v0, 4
          # la        $a0, AIWINNER
          # syscall
          la        $t2, BOARD
          add       $t2, $t2, $t0
          li        $t3, 'O'
          sb        $t3, 0($t2)
          addiu     $s3, $s3, 1

          la        $a0, NEWLINE
          li        $v0, 4
          syscall

          j         AI_WIN
          # j         AISTURN_MAKE_MOVE

#=========================================================================FAIZAL CHECK #COL==============
# Check to see if there is a winning move for the AI
# down columns i.e.
#
#   +--+--+--+
#   |v |v | v|
# v +--+--+--+
#   |v |v | v|
# v +--+--+--+
#   |v |v | v|
#   +--+--+--+
#
# Register Usage:
#         t0 = i = 0
#         t1 = j = 0
#         t2 = numspaces = 0
#         t3 = numos = 0
#         t4 = index = -1
#         t5 = (temporary)
#         t6 = (temporary)
#         t7 = (temporary)
#         t8 = (temporary)
# Pseudocode:
#
# numspaces = 0
# numos = 0
# index = -1
# for (int i = 0; i < n; ++i) {
#   for (int j = 0; j < n; ++j) {
#     if (board[j * n + i] == 'X')
#       numos++;
#     if (board[j * n + i] == ' ') {
#       numspaces++;
#       index = i * n + i;
#     }
#   }
#   if (numspaces == 1 && numos == n - 1) {
#     board[index] = 'O';
#     break;
#   }
# }
AISTURN_WINNINGMOVE_CHECKCOL:
          li        $t0, 0              # i = 0
          li        $t1, 0              # j = 0

AISTURN_WINNINGMOVE_CHECKCOL_OUTERLOOP:
          beq       $t0, $s2, AISTURN_WINNINGMOVE_DIAGLEFT  # No winning move found.
          li        $t1, 0                                  # j = 0
          li        $t2, 0                                  # numspaces = 0
          li        $t3, 0                                  # numos = 0
          li        $t4, -1

AISTURN_WINNINGMOVE_CHECKCOL_INNERLOOP:
          beq       $t1, $s2, AISTURN_WINNINGMOVE_CHECKCOL_OUTERLOOP_BOTTOM

          # if (board[i * n + j] == ' ')
          #   ++numspaces;
          mul       $t5, $t1, $s2       # t5 = j * n
          add       $t5, $t5, $t0       # t5 = j * n + i
          move      $t8, $t5            # t8 = t5
          la        $t6, BOARD
          addu      $t6, $t6, $t5
          lb        $t5, 0($t6)         # t5 = board[j * n + i]

          li        $t6, ' '
          beq       $t5, $t6, AISTURN_WINNINGMOVE_CHECKCOL_INNERLOOP_IF

          j         AISTURN_WINNINGMOVE_CHECKCOL_INNERLOOP_BOTTOM

AISTURN_WINNINGMOVE_CHECKCOL_INNERLOOP_IF:
          addiu     $t2, $t2, 1         # ++numspaces
          move      $t4, $t8            # index = i * n + j

AISTURN_WINNINGMOVE_CHECKCOL_INNERLOOP_BOTTOM:
          # if (board[i * n + j] == 'O')
          #   ++numspaces;
          li        $t6, 'O'
          seq       $t6, $t5, $t6       # t6 = (board[i * n + j] == ' ')
          addu      $t3, $t3, $t6       # numos += t6

          addiu     $t1, $t1, 1         # ++j

          j AISTURN_WINNINGMOVE_CHECKCOL_INNERLOOP

AISTURN_WINNINGMOVE_CHECKCOL_OUTERLOOP_BOTTOM:
          # if (numspaces == 1 && numos == n - 1)
          #   board[index] = 'O'
          li        $t5, 1
          seq       $t6, $t2, $t5       # t6 = (numspaces == 1)
          move      $t5, $s2
          addiu     $t5, $t5, -1        # t5 = n - 1
          seq       $t7, $t3, $t5       # t7 = (numos == n - 1)

          and       $t6, $t6, $t7       # t6 = t6 && t7

          li        $t5, 1
          beq       $t6, $t5, AISTURN_WINNINGMOVE_CHECKCOL_OUTERLOOP_EXIT

          addiu     $t0, $t0, 1         # ++i

          j AISTURN_WINNINGMOVE_CHECKCOL_OUTERLOOP

AISTURN_WINNINGMOVE_CHECKCOL_OUTERLOOP_EXIT:
          move      $t0, $t4

          # li        $v0, 4
          # la        $a0, AIWINNER
          # syscall
          la        $t2, BOARD
          add       $t2, $t2, $t0
          li        $t3, 'O'
          sb        $t3, 0($t2)
          addiu     $s3, $s3, 1

          la        $a0, NEWLINE
          li        $v0, 4
          syscall
          j         AI_WIN
          # j         AISTURN_MAKE_MOVE

AISTURN_WINNINGMOVE_DIAGLEFT:
          li        $t0, 0    # i = 0
          li        $t1, 0    # numspaces = 0
          li        $t2, 0    # numos = 0
          li        $t3, 0    # index = 0

AISTURN_WINNINGMOVE_DIAGLEFT_LOOP:
          beq       $t0, $s2, AISTURN_WINNINGMOVE_DIAGLEFT_CHECK

          la        $t4, BOARD          # load address of board
          mul       $t5, $t0, $s2
          add       $t5, $t5, $t0
          add       $t8, $t5, $t4
          lb        $t4, 0($t8)

          # Count an O if it is seen.
          li        $t6, 'O'
          seq       $t7, $t4, $t6
          addu      $t2, $t2, $t7

          li        $t6, ' '
          beq       $t4, $t6, AISTURN_WINNINGMOVE_DIAGLEFT_LOOP_IF

AISTURN_WINNINGMOVE_DIAGLEFT_LOOP_BOTTOM:
          addiu     $t0, $t0, 1 	# ++i
          j         AISTURN_WINNINGMOVE_DIAGLEFT_LOOP

AISTURN_WINNINGMOVE_DIAGLEFT_CHECK:
          addi      $t6, $s2, -1

          seq       $t7, $t2, $t6       # t7 = (numos == n - 1)

          li        $t6, 1
          seq       $t8, $t1, $t6       # t8 = (numspaces == 1)

          and       $t7, $t7, $t8       # t7 = ((numos == n - 1) && (numspaces == 1))

          li        $t6, 1
          beq       $t7, $t6, AISTURN_WINNINGMOVE_DIAGLEFT_LOOP_EXIT

          j         AISTURN_WINNINGMOVE_DIAGRIGHT

AISTURN_WINNINGMOVE_DIAGLEFT_LOOP_IF:
          addiu $t1, $t1, 1 # inc numspaces
          move  $t3, $t5    # index = i * n + i

          j 	AISTURN_WINNINGMOVE_DIAGLEFT_LOOP_BOTTOM

AISTURN_WINNINGMOVE_DIAGLEFT_LOOP_EXIT:
          move      $t0, $t3
          # j         AISTURN_MAKE_MOVE

          la        $t2, BOARD
          add       $t2, $t2, $t0
          li        $t3, 'O'
          sb        $t3, 0($t2)
          addiu     $s3, $s3, 1

          la        $a0, NEWLINE
          li        $v0, 4
          syscall

          j         AI_WIN

AISTURN_WINNINGMOVE_DIAGRIGHT:
          li        $t0, 0              # i = 0
          li        $t1, 0              # numspaces = 0
          li        $t2, 0              # numos = 0
          li        $t3, 0              # index = 0
          addi      $t9, $s2, -1        # j = n - 1

AISTURN_WINNINGMOVE_DIAGRIGHT_LOOP:
          beq       $t0, $s2, AISTURN_WINNINGMOVE_DIAGRIGHT_CHECK

          la        $t4, BOARD          # load address of board
          add       $t5, $t9, $t4
          lb        $t4, 0($t5)

          # Count an O if it is seen.
          li        $t6, 'O'
          seq       $t7, $t4, $t6
          addu      $t2, $t2, $t7

          li        $t6, ' '
          beq       $t4, $t6, AISTURN_WINNINGMOVE_DIAGRIGHT_LOOP_IF

AISTURN_WINNINGMOVE_DIAGRIGHT_LOOP_BOTTOM:
          addiu     $t0, $t0, 1 	# ++i
          add       $t9, $t9, $s2       # j += n - 1
          addi      $t9, $t9, -1
          j         AISTURN_WINNINGMOVE_DIAGRIGHT_LOOP

AISTURN_WINNINGMOVE_DIAGRIGHT_CHECK:
          move      $t6, $s2
          addi      $t6, $t6, -1

          seq       $t7, $t2, $t6       # t7 = (numos == n - 1)

          li        $t6, 1
          seq       $t8, $t1, $t6       # t8 = (numspaces == 1)

          and       $t7, $t7, $t8       # t7 = ((numos == n - 1) && (numspaces == 1))

          li        $t6, 1
          beq       $t7, $t6, AISTURN_WINNINGMOVE_DIAGRIGHT_LOOP_EXIT

          j         AI_BLOCK_MOVE

AISTURN_WINNINGMOVE_DIAGRIGHT_LOOP_IF:
          addiu $t1, $t1, 1 # inc numspaces
          move  $t3, $t9    # index = j

          j 	AISTURN_WINNINGMOVE_DIAGRIGHT_LOOP_BOTTOM

AISTURN_WINNINGMOVE_DIAGRIGHT_LOOP_EXIT:
          move      $t0, $t3
          # j         AISTURN_MAKE_MOVE
          la        $t2, BOARD
          add       $t2, $t2, $t0
          li        $t3, 'O'
          sb        $t3, 0($t2)
          addiu     $s3, $s3, 1

          la        $a0, NEWLINE
          li        $v0, 4
          syscall

          j         AI_WIN

#===============================================================================================
#===============================================================================================
#===============================================================================================

AI_BLOCK_MOVE:

# Check to see if there is a winning move for the AI
# across rows, i.e.
#
#   +--+--+--+
#   |->|->|->|
# v +--+--+--+
#   |->|->|->|
# v +--+--+--+
#   |->|->|->|
#   +--+--+--+
#
# Register Usage:
#         t0 = i = 0
#         t1 = j = 0
#         t2 = numspaces = 0
#         t3 = numos = 0
#         t4 = index = -1
#         t5 = (temporary)
#         t6 = (temporary)
#         t7 = (temporary)
#         t8 = (temporary)
# Pseudocode:
#
# numspaces = 0
# numos = 0
# index = -1
# for (int i = 0; i < n; ++i) {
#   for (int j = 0; j < n; ++j) {
#     if (board[i * n + j] == 'X')
#       numos++;
#     if (board[i * n + j] == ' ') {
#       numspaces++;
#       index = i * n + j;
#     }
#   }
#   if (numspaces == 1 && numos == n - 1) {
#     board[index] = 'O';
#     break;
#   }
# }
AISTURN_BLOCK_CHECKROWS:
          li        $t0, 0              # i = 0
          li        $t1, 0              # j = 0

AISTURN_BLOCK_CHECKROWS_OUTERLOOP:
          beq       $t0, $s2, AISTURN_BLOCK_CHECKCOL  # No winning move found.
          li        $t1, 0                                  # j = 0
          li        $t2, 0                                  # numspaces = 0
          li        $t3, 0                                  # numos = 0
          li        $t4, -1

AISTURN_BLOCK_CHECKROWS_INNERLOOP:
          beq       $t1, $s2, AISTURN_BLOCK_CHECKROWS_OUTERLOOP_BOTTOM

          # if (board[i * n + j] == ' ')
          #   ++numspaces;
          mul       $t5, $t0, $s2       # t5 = i * n
          add       $t5, $t5, $t1       # t5 = i * n + j
          move      $t8, $t5            # t8 = t5
          la        $t6, BOARD
          addu      $t6, $t6, $t5
          lb        $t5, 0($t6)         # t5 = board[i * n + j]

          li        $t6, ' '
          beq       $t5, $t6, AISTURN_BLOCK_CHECKROWS_INNERLOOP_IF

          j         AISTURN_BLOCK_CHECKROWS_INNERLOOP_BOTTOM

AISTURN_BLOCK_CHECKROWS_INNERLOOP_IF:
          addiu     $t2, $t2, 1         # ++numspaces
          move      $t4, $t8            # index = i * n + j

AISTURN_BLOCK_CHECKROWS_INNERLOOP_BOTTOM:
          # if (board[i * n + j] == 'O')
          #   ++numspaces;
          li        $t6, 'X' #$$$$$$$$$$
          seq       $t6, $t5, $t6       # t6 = (board[i * n + j] == ' ')
          addu      $t3, $t3, $t6       # numos += t6

          addiu     $t1, $t1, 1         # ++j

          j AISTURN_BLOCK_CHECKROWS_INNERLOOP

AISTURN_BLOCK_CHECKROWS_OUTERLOOP_BOTTOM:
          # if (numspaces == 1 && numos == n - 1)
          #   board[index] = 'O'
          li        $t5, 1
          seq       $t6, $t2, $t5       # t6 = (numspaces == 1)
          move      $t5, $s2
          addiu     $t5, $t5, -1        # t5 = n - 1
          seq       $t7, $t3, $t5       # t7 = (numos == n - 1)

          and       $t6, $t6, $t7       # t6 = t6 && t7

          li        $t5, 1
          beq       $t6, $t5, AISTURN_BLOCK_CHECKROWS_OUTERLOOP_EXIT

          addiu     $t0, $t0, 1         # ++i

          j AISTURN_BLOCK_CHECKROWS_OUTERLOOP

AISTURN_BLOCK_CHECKROWS_OUTERLOOP_EXIT:
          move      $t0, $t4

          # li        $v0, 4
          # la        $a0, AIWINNER
          # syscall

          j         AISTURN_MAKE_MOVE

#CHECKCOL===============================================================================
#=======================================================================================
# Check to see if there is a winning move for the AI
# down columns i.e.
#
#   +--+--+--+
#   |v |v | v|
# v +--+--+--+
#   |v |v | v|
# v +--+--+--+
#   |v |v | v|
#   +--+--+--+
#
# Register Usage:
#         t0 = i = 0
#         t1 = j = 0
#         t2 = numspaces = 0
#         t3 = numos = 0
#         t4 = index = -1
#         t5 = (temporary)
#         t6 = (temporary)
#         t7 = (temporary)
#         t8 = (temporary)
# Pseudocode:
#
# numspaces = 0
# numos = 0
# index = -1
# for (int i = 0; i < n; ++i) {
#   for (int j = 0; j < n; ++j) {
#     if (board[j * n + i] == 'X')
#       numos++;
#     if (board[j * n + i] == ' ') {
#       numspaces++;
#       index = i * n + i;
#     }
#   }
#   if (numspaces == 1 && numos == n - 1) {
#     board[index] = 'O';
#     break;
#   }
# }
AISTURN_BLOCK_CHECKCOL:
          li        $t0, 0              # i = 0
          li        $t1, 0              # j = 0

AISTURN_BLOCK_CHECKCOL_OUTERLOOP:
          beq       $t0, $s2, AISTURN_BLOCK_DIAGLEFT  # No winning move found.
          li        $t1, 0                                  # j = 0
          li        $t2, 0                                  # numspaces = 0
          li        $t3, 0                                  # numos = 0
          li        $t4, -1

AISTURN_BLOCK_CHECKCOL_INNERLOOP:
          beq       $t1, $s2, AISTURN_BLOCK_CHECKCOL_OUTERLOOP_BOTTOM

          # if (board[i * n + j] == ' ')
          #   ++numspaces;
          mul       $t5, $t1, $s2       # t5 = j * n
          add       $t5, $t5, $t0       # t5 = j * n + i
          move      $t8, $t5            # t8 = t5
          la        $t6, BOARD
          addu      $t6, $t6, $t5
          lb        $t5, 0($t6)         # t5 = board[j * n + i]

          li        $t6, ' '
          beq       $t5, $t6, AISTURN_BLOCK_CHECKCOL_INNERLOOP_IF

          j         AISTURN_BLOCK_CHECKCOL_INNERLOOP_BOTTOM

AISTURN_BLOCK_CHECKCOL_INNERLOOP_IF:
          addiu     $t2, $t2, 1         # ++numspaces
          move      $t4, $t8            # index = i * n + j

AISTURN_BLOCK_CHECKCOL_INNERLOOP_BOTTOM:
          # if (board[i * n + j] == 'O')
          #   ++numspaces;
          li        $t6, 'X'#$$$$$$$$$$$$$
          seq       $t6, $t5, $t6       # t6 = (board[i * n + j] == ' ')
          addu      $t3, $t3, $t6       # numos += t6

          addiu     $t1, $t1, 1         # ++j

          j AISTURN_BLOCK_CHECKCOL_INNERLOOP

AISTURN_BLOCK_CHECKCOL_OUTERLOOP_BOTTOM:
          # if (numspaces == 1 && numos == n - 1)
          #   board[index] = 'O'
          li        $t5, 1
          seq       $t6, $t2, $t5       # t6 = (numspaces == 1)
          move      $t5, $s2
          addiu     $t5, $t5, -1        # t5 = n - 1
          seq       $t7, $t3, $t5       # t7 = (numos == n - 1)

          and       $t6, $t6, $t7       # t6 = t6 && t7

          li        $t5, 1
          beq       $t6, $t5, AISTURN_BLOCK_CHECKCOL_OUTERLOOP_EXIT

          addiu     $t0, $t0, 1         # ++i

          j AISTURN_BLOCK_CHECKCOL_OUTERLOOP

AISTURN_BLOCK_CHECKCOL_OUTERLOOP_EXIT:
          move      $t0, $t4

          # li        $v0, 4
          # la        $a0, AIWINNER
          # syscall

          j         AISTURN_MAKE_MOVE

AISTURN_BLOCK_DIAGLEFT:
          li        $t0, 0    # i = 0
          li        $t1, 0    # numspaces = 0
          li        $t2, 0    # numos = 0
          li        $t3, 0    # index = 0

AISTURN_BLOCK_DIAGLEFT_LOOP:
          beq       $t0, $s2, AISTURN_BLOCK_DIAGLEFT_CHECK

          la        $t4, BOARD          # load address of board
          mul       $t5, $t0, $s2
          add       $t5, $t5, $t0
          add       $t8, $t5, $t4
          lb        $t4, 0($t8)

          # Count an X if it is seen.
          li        $t6, 'X'
          seq       $t7, $t4, $t6
          addu      $t2, $t2, $t7

          li        $t6, ' '
          beq       $t4, $t6, AISTURN_BLOCK_DIAGLEFT_LOOP_IF

AISTURN_BLOCK_DIAGLEFT_LOOP_BOTTOM:
          addiu     $t0, $t0, 1 	# ++i
          j         AISTURN_BLOCK_DIAGLEFT_LOOP

AISTURN_BLOCK_DIAGLEFT_CHECK:
          addi      $t6, $s2, -1

          seq       $t7, $t2, $t6       # t7 = (numos == n - 1)

          li        $t6, 1
          seq       $t8, $t1, $t6       # t8 = (numspaces == 1)

          and       $t7, $t7, $t8       # t7 = ((numos == n - 1) && (numspaces == 1))

          li        $t6, 1
          beq       $t7, $t6, AISTURN_BLOCK_DIAGLEFT_LOOP_EXIT

          j         AISTURN_BLOCK_DIAGRIGHT

AISTURN_BLOCK_DIAGLEFT_LOOP_IF:
          addiu $t1, $t1, 1 # inc numspaces
          move  $t3, $t5    # index = i * n + i

          j 	AISTURN_BLOCK_DIAGLEFT_LOOP_BOTTOM

AISTURN_BLOCK_DIAGLEFT_LOOP_EXIT:
          move      $t0, $t3
          j         AISTURN_MAKE_MOVE

AISTURN_BLOCK_DIAGRIGHT:
          li        $t0, 0              # i = 0
          li        $t1, 0              # numspaces = 0
          li        $t2, 0              # numos = 0
          li        $t3, 0              # index = 0
          addi      $t9, $s2, -1        # j = n - 1

AISTURN_BLOCK_DIAGRIGHT_LOOP:
          beq       $t0, $s2, AISTURN_BLOCK_DIAGRIGHT_CHECK

          la        $t4, BOARD          # load address of board
          add       $t5, $t9, $t4
          lb        $t4, 0($t5)

          # Count an X if it is seen.
          li        $t6, 'X'
          seq       $t7, $t4, $t6
          addu      $t2, $t2, $t7

          li        $t6, ' '
          beq       $t4, $t6, AISTURN_BLOCK_DIAGRIGHT_LOOP_IF

AISTURN_BLOCK_DIAGRIGHT_LOOP_BOTTOM:
          addiu     $t0, $t0, 1 	# ++i
          add       $t9, $t9, $s2       # j += n - 1
          addi      $t9, $t9, -1
          j         AISTURN_BLOCK_DIAGRIGHT_LOOP

AISTURN_BLOCK_DIAGRIGHT_CHECK:
          move      $t6, $s2
          addi      $t6, $t6, -1

          seq       $t7, $t2, $t6       # t7 = (numos == n - 1)

          li        $t6, 1
          seq       $t8, $t1, $t6       # t8 = (numspaces == 1)

          and       $t7, $t7, $t8       # t7 = ((numos == n - 1) && (numspaces == 1))

          li        $t6, 1
          beq       $t7, $t6, AISTURN_BLOCK_DIAGRIGHT_LOOP_EXIT

          j         AISTURN_PICKFIRST

AISTURN_BLOCK_DIAGRIGHT_LOOP_IF:
          addiu $t1, $t1, 1 # inc numspaces
          move  $t3, $t9    # index = j

          j 	AISTURN_BLOCK_DIAGRIGHT_LOOP_BOTTOM

AISTURN_BLOCK_DIAGRIGHT_LOOP_EXIT:
          move      $t0, $t3
          j         AISTURN_MAKE_MOVE



#==============================================================================================
#===============================================================================================
#===============================================================================================
# This label will only be executed if the AI cannot block the player
# from winning and it cannot make a winning move of its own.
#
# Register Usage:
#         t0 = i
#         t1 = s2 * s2 = n * n
#         t2 = (temporary used for loading board[i])
# Pseudocode:
# for (int i = 0; i < n * n; ++i)
#   if (board[i] == ' ') {
#     board[i] = 'O';
#     break;
#   }
AISTURN_PICKFIRST:
          li        $t0, 0              # i = 0
          mul       $t1, $s2, $s2       # t1 = n * n

AISTURN_PICKFIRST_LOOP:
          la        $t2, BOARD
          add       $t2, $t2, $t0
          lb        $t2, 0($t2)
          li        $t3, ' '
          beq       $t2, $t3, AISTURN_MAKE_MOVE

          addiu     $t0, $t0, 1 	# ++i
          j AISTURN_PICKFIRST_LOOP

# Prereq: t0 = the index to put an 'O'
AISTURN_MAKE_MOVE:
          la        $t2, BOARD
          add       $t2, $t2, $t0
          li        $t3, 'O'
          sb        $t3, 0($t2)
          addiu     $s3, $s3, 1

          la        $a0, NEWLINE
          li        $v0, 4
          syscall

          j         GAMELOOP_BOTTOM
main:
	li        $s3, 1

	li        $v0, 4
	la        $a0, GREETING
	syscall

	li        $v0, 4
	la        $a0, ENTERn
	syscall

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
#           board[i] = ' ';
# Registers used:
#         t0 = &board[0]
#         t1 = i = 0
#         t2 = n * n
#         t3 = temporary for storing bytes in the data segment
#         t4 = &board[i]
INITBOARD:
          beq       $t1, $t2 INITBOARD_END

          # Load the ASCII char for space.
          li        $t3, ' '

          # Get the address of board[i].
          add       $t4, $t0, $t1

          # Store a ' ' in board[i].
          sb        $t3, 0($t4)

          addiu     $t1, $t1, 1         # ++i
          j         INITBOARD

# Add a null terminator to the board string.
INITBOARD_END:
          add       $t4, $t0, $t1       # get board[n]
          li        $t3, 0
          sb        $t3, 0($t4)         # board[n] = ' '

          li        $v0, 4
          la        $a0, FIRST
          syscall

	# ==============================================================
	# Place a '0' in the 'center' of the board.
	# row = (n - 1) / 2
	# col = (n - 1) / 2
     # ==============================================================
          addi      $t0, $s2, -1
          li 	$t1, 2
          div       $t0, $t1
          mflo      $t0

          addi      $t2, $s2, -1
          div       $t2, $t1
          mflo      $t2

          mul       $t0, $t0, $s2
          add       $t0, $t0, $t2
          la 	$t1, BOARD
          add       $t0, $t0, $t1

          li        $t2, 'O'
          sb        $t2, 0($t0)
          # ==============================================================

GAMELOOP:

          # Print n x n board.
          move      $a0, $s2            # hello
          jal       PRINTBOARD

          li        $t0, 2
          div       $s3, $t0
          mfhi      $t0
          beqz      $t0, AISTURN

          li        $v0, 4
          la        $a0, INPUTROW
          syscall

          li        $v0, 5 # get row selection from user
          syscall
          move      $s0, $v0

          li        $v0, 4
          la        $a0, INPUTCOLUMN
          syscall

          li        $v0, 5 # get column selection from user
          syscall
          move      $s1, $v0

# if (row < 0 || row >= n) goto INVALID_MOVE
VALIDATE_ROW:
          bltz      $s0, INVALID_MOVE
          move      $t0, $s2
          bge       $s0, $t0, INVALID_MOVE

# if (col < 0 || col >= n) goto INVALID_MOVE
VALIDATE_COL:
          bltz      $s1, INVALID_MOVE
          move      $t0, $s2
          bge       $s1, $t0, INVALID_MOVE

# For 2-D array:
# if (board[row][col] != ' ')
#           goto INVALID_MOVE
# For 1-D array:
#           index = row * n + col
#           if board[index] != ' ')
#                     goto INVALID_MOVE
VALIDATE_ROWCOL:
          # Get index in array of row in s0 and col in s1
          mul       $t0, $s0, $s2
          add       $t0, $t0, $s1

          la        $t1, BOARD         # t1 = board[0]
          addu      $t1, $t1, $t0      # t1 = board[0] + i
          lb        $t1, 0($t1)        # t1 = *(board[0] + i)
          li        $t2, ' '
          bne       $t1, $t2, INVALID_MOVE
          j         VALID_MOVE

INVALID_MOVE:
          li        $v0, 4
          la        $a0, INVALIDMOVESTR
          syscall
          j         GAMELOOP_BOTTOM

VALID_MOVE:
          mul       $t0, $s0, $s2
          add       $t0, $t0, $s1
          la        $t1, BOARD
          add       $t1, $t1, $t0
          li        $t2, 'X'
          sb        $t2, 0($t1)

          addiu     $s3, $s3, 1         # turncount++
GAMELOOP_BOTTOM:

#===============================================================================================
#===============================================================================================
#===============================================================================================

CHICKEN_DINNER:

# Check to see if there is a winning move for the AI
# across rows, i.e.
#
#   +--+--+--+
#   |->|->|->|
# v +--+--+--+
#   |->|->|->|
# v +--+--+--+
#   |->|->|->|
#   +--+--+--+
#
# Register Usage:
#         t0 = i = 0
#         t1 = j = 0
#         t2 = numspaces = 0
#         t3 = numos = 0
#         t4 = index = -1
#         t5 = (temporary)
#         t6 = (temporary)
#         t7 = (temporary)
#         t8 = (temporary)
# Pseudocode:
#
# numspaces = 0
# numos = 0
# index = -1
# for (int i = 0; i < n; ++i) {
#   for (int j = 0; j < n; ++j) {
#     if (board[i * n + j] == 'X')
#       numos++;
#     if (board[i * n + j] == ' ') {
#       numspaces++;
#       index = i * n + j;
#     }
#   }
#   if (numspaces == 1 && numos == n - 1) {
#     board[index] = 'O';
#     break;
#   }
# }
CHICKEN_DINNER_CHECKROWS:
          li        $t0, 0              # i = 0
          li        $t1, 0              # j = 0

CHICKEN_DINNER_CHECKROWS_OUTERLOOP:
          beq       $t0, $s2, CHICKEN_DINNER_CHECKCOL  # No winning move found.
          li        $t1, 0                                  # j = 0
          li        $t2, 0                                  # numspaces = 0
          li        $t3, 0                                  # numos = 0
          li        $t4, -1

CHICKEN_DINNER_CHECKROWS_INNERLOOP:
          beq       $t1, $s2, CHICKEN_DINNER_CHECKROWS_OUTERLOOP_BOTTOM

          # if (board[i * n + j] == ' ')
          #   ++numspaces;
          mul       $t5, $t0, $s2       # t5 = i * n
          add       $t5, $t5, $t1       # t5 = i * n + j
          move      $t8, $t5            # t8 = t5
          la        $t6, BOARD
          addu      $t6, $t6, $t5
          lb        $t5, 0($t6)         # t5 = board[i * n + j]

          li        $t6, ' '
          beq       $t5, $t6, CHICKEN_DINNER_CHECKROWS_INNERLOOP_IF

          j         CHICKEN_DINNER_CHECKROWS_INNERLOOP_BOTTOM

CHICKEN_DINNER_CHECKROWS_INNERLOOP_IF:
          addiu     $t2, $t2, 1         # ++numspaces
          move      $t4, $t8            # index = i * n + j

CHICKEN_DINNER_CHECKROWS_INNERLOOP_BOTTOM:
          # if (board[i * n + j] == 'O')
          #   ++numspaces;
          li        $t6, 'X' #$$$$$$$$$$
          seq       $t6, $t5, $t6       # t6 = (board[i * n + j] == ' ')
          addu      $t3, $t3, $t6       # numos += t6

          addiu     $t1, $t1, 1         # ++j

          j CHICKEN_DINNER_CHECKROWS_INNERLOOP

CHICKEN_DINNER_CHECKROWS_OUTERLOOP_BOTTOM:
          # if (numspaces == 0 && numos == n)
          #   board[index] = 'O'
          li        $t5, 0
          seq       $t6, $t2, $t5       # t6 = (numspaces == 1)
          move      $t5, $s2
          seq       $t7, $t3, $t5       # t7 = (numos == n - 1)

          and       $t6, $t6, $t7       # t6 = t6 && t7

          li        $t5, 1
          beq       $t6, $t5, CHICKEN_DINNER_CHECKROWS_OUTERLOOP_EXIT

          addiu     $t0, $t0, 1         # ++i

          j CHICKEN_DINNER_CHECKROWS_OUTERLOOP

CHICKEN_DINNER_CHECKROWS_OUTERLOOP_EXIT:
          j   CHICKEN_DINNER_PRINT_WINNER

#CHECKCOL===============================================================================
#=======================================================================================
# Check to see if there is a winning move for the AI
# down columns i.e.
#
#   +--+--+--+
#   |v |v | v|
# v +--+--+--+
#   |v |v | v|
# v +--+--+--+
#   |v |v | v|
#   +--+--+--+
#
# Register Usage:
#         t0 = i = 0
#         t1 = j = 0
#         t2 = numspaces = 0
#         t3 = numos = 0
#         t4 = index = -1
#         t5 = (temporary)
#         t6 = (temporary)
#         t7 = (temporary)
#         t8 = (temporary)
# Pseudocode:
#
# numspaces = 0
# numos = 0
# index = -1
# for (int i = 0; i < n; ++i) {
#   for (int j = 0; j < n; ++j) {
#     if (board[j * n + i] == 'X')
#       numos++;
#     if (board[j * n + i] == ' ') {
#       numspaces++;
#       index = i * n + i;
#     }
#   }
#   if (numspaces == 1 && numos == n - 1) {
#     board[index] = 'O';
#     break;
#   }
# }
CHICKEN_DINNER_CHECKCOL:
          li        $t0, 0              # i = 0
          li        $t1, 0              # j = 0

CHICKEN_DINNER_CHECKCOL_OUTERLOOP:
          beq       $t0, $s2, CHICKEN_DINNER_DIAGLEFT  # No winning move found.
          li        $t1, 0                                  # j = 0
          li        $t2, 0                                  # numspaces = 0
          li        $t3, 0                                  # numos = 0
          li        $t4, -1

CHICKEN_DINNER_CHECKCOL_INNERLOOP:
          beq       $t1, $s2, CHICKEN_DINNER_CHECKCOL_OUTERLOOP_BOTTOM

          # if (board[i * n + j] == ' ')
          #   ++numspaces;
          mul       $t5, $t1, $s2       # t5 = j * n
          add       $t5, $t5, $t0       # t5 = j * n + i
          move      $t8, $t5            # t8 = t5
          la        $t6, BOARD
          addu      $t6, $t6, $t5
          lb        $t5, 0($t6)         # t5 = board[j * n + i]

          li        $t6, ' '
          beq       $t5, $t6, CHICKEN_DINNER_CHECKCOL_INNERLOOP_IF

          j         CHICKEN_DINNER_CHECKCOL_INNERLOOP_BOTTOM

CHICKEN_DINNER_CHECKCOL_INNERLOOP_IF:
          addiu     $t2, $t2, 1         # ++numspaces
          move      $t4, $t8            # index = i * n + j

CHICKEN_DINNER_CHECKCOL_INNERLOOP_BOTTOM:
          # if (board[i * n + j] == 'O')
          #   ++numspaces;
          li        $t6, 'X'#$$$$$$$$$$$$$
          seq       $t6, $t5, $t6       # t6 = (board[i * n + j] == ' ')
          addu      $t3, $t3, $t6       # numos += t6

          addiu     $t1, $t1, 1         # ++j

          j CHICKEN_DINNER_CHECKCOL_INNERLOOP

CHICKEN_DINNER_CHECKCOL_OUTERLOOP_BOTTOM:
          # if (numspaces == 0 && numos == n)
          #   board[index] = 'O'
          li        $t5, 0
          seq       $t6, $t2, $t5       # t6 = (numspaces == 1)
          move      $t5, $s2
          seq       $t7, $t3, $t5       # t7 = (numos == n - 1)

          and       $t6, $t6, $t7       # t6 = t6 && t7

          li        $t5, 1
          beq       $t6, $t5, CHICKEN_DINNER_CHECKCOL_OUTERLOOP_EXIT

          addiu     $t0, $t0, 1         # ++i

          j CHICKEN_DINNER_CHECKCOL_OUTERLOOP

CHICKEN_DINNER_CHECKCOL_OUTERLOOP_EXIT:
          j         CHICKEN_DINNER_PRINT_WINNER

CHICKEN_DINNER_DIAGLEFT:
          li        $t0, 0    # i = 0
          li        $t1, 0    # numspaces = 0
          li        $t2, 0    # numos = 0
          li        $t3, 0    # index = 0

CHICKEN_DINNER_DIAGLEFT_LOOP:
          beq       $t0, $s2, CHICKEN_DINNER_DIAGLEFT_CHECK

          la        $t4, BOARD          # load address of board
          mul       $t5, $t0, $s2
          add       $t5, $t5, $t0
          add       $t8, $t5, $t4
          lb        $t4, 0($t8)

          # Count an X if it is seen.
          li        $t6, 'X'
          seq       $t7, $t4, $t6
          addu      $t2, $t2, $t7

          li        $t6, ' '
          beq       $t4, $t6, CHICKEN_DINNER_DIAGLEFT_LOOP_IF

CHICKEN_DINNER_DIAGLEFT_LOOP_BOTTOM:
          addiu     $t0, $t0, 1 	# ++i
          j         CHICKEN_DINNER_DIAGLEFT_LOOP

CHICKEN_DINNER_DIAGLEFT_CHECK:
          move      $t6, $s2

          seq       $t7, $t2, $t6       # t7 = (numos == n)

          li        $t6, 0
          seq       $t8, $t1, $t6       # t8 = (numspaces == 0)

          and       $t7, $t7, $t8       # t7 = ((numos == n - 1) && (numspaces == 1))

          li        $t6, 1
          beq       $t7, $t6, CHICKEN_DINNER_DIAGLEFT_LOOP_EXIT

          j         CHICKEN_DINNER_DIAGRIGHT

CHICKEN_DINNER_DIAGLEFT_LOOP_IF:
          addiu $t1, $t1, 1 # inc numspaces
          move  $t3, $t5    # index = i * n + i

          j 	CHICKEN_DINNER_DIAGLEFT_LOOP_BOTTOM

CHICKEN_DINNER_DIAGLEFT_LOOP_EXIT:
          j         CHICKEN_DINNER_PRINT_WINNER

CHICKEN_DINNER_DIAGRIGHT:
          li        $t0, 0              # i = 0
          li        $t1, 0              # numspaces = 0
          li        $t2, 0              # numos = 0
          li        $t3, 0              # index = 0
          addi      $t9, $s2, -1        # j = n - 1

CHICKEN_DINNER_DIAGRIGHT_LOOP:
          beq       $t0, $s2, CHICKEN_DINNER_DIAGRIGHT_CHECK

          la        $t4, BOARD          # load address of board
          add       $t5, $t9, $t4
          lb        $t4, 0($t5)

          # Count an X if it is seen.
          li        $t6, 'X'
          seq       $t7, $t4, $t6
          addu      $t2, $t2, $t7

          li        $t6, ' '
          beq       $t4, $t6, CHICKEN_DINNER_DIAGRIGHT_LOOP_IF

CHICKEN_DINNER_DIAGRIGHT_LOOP_BOTTOM:
          addiu     $t0, $t0, 1 	# ++i
          add       $t9, $t9, $s2       # j += n - 1
          addi      $t9, $t9, -1
          j         CHICKEN_DINNER_DIAGRIGHT_LOOP

CHICKEN_DINNER_DIAGRIGHT_CHECK:
          move      $t6, $s2

          seq       $t7, $t2, $t6       # t7 = (numxs == n)

          li        $t6, 0
          seq       $t8, $t1, $t6       # t8 = (numspaces == 0)

          and       $t7, $t7, $t8       # t7 = ((numos == n - 1) && (numspaces == 1))

          li        $t6, 1
          beq       $t7, $t6, CHICKEN_DINNER_DIAGRIGHT_LOOP_EXIT

          j         GAMEOVER

CHICKEN_DINNER_DIAGRIGHT_LOOP_IF:
          addiu $t1, $t1, 1 # inc numspaces
          move  $t3, $t9    # index = j

          j 	CHICKEN_DINNER_DIAGRIGHT_LOOP_BOTTOM

CHICKEN_DINNER_DIAGRIGHT_LOOP_EXIT:
          move      $t0, $t3
          j         CHICKEN_DINNER_PRINT_WINNER

CHICKEN_DINNER_PRINT_WINNER:
          move      $a0, $s2
          jal       PRINTBOARD

          la        $a0, NEWLINE
          li        $v0, 4
          syscall

          li        $v0, 4
          la        $a0, PLAYERWINMSG
          syscall

          j         EXIT

#==============================================================================================
#===============================================================================================
#===============================================================================================

AI_WIN:
          move      $a0, $s2
          jal       PRINTBOARD

          la        $a0, NEWLINE
          li        $v0, 4
          syscall

          li        $v0, 4
          la        $a0, AIWONMSG
          syscall

          j         EXIT

GAMEOVER:
          li        $t0, 0              # i = 0
          mul       $t1, $s2, $s2       # t1 = n * n

# for (int i = 0; i < n * n; ++i)
#   if (board[i] == ' ')
#     gameover = false;
# gameover = true;
# print game over message.
GAMEOVERLOOP:
          beq       $t0, $t1, GAME_OVER_BOTTOM

          la        $t2, BOARD
          add       $t2, $t2, $t0
          lb        $t2, 0($t2)
          li        $t3, ' '
          beq       $t2, $t3, GAMELOOP
          addiu     $t0, $t0, 1

          j         GAMEOVERLOOP

GAME_OVER_BOTTOM:
          # Print the board.
          move      $a0, $s2
          jal       PRINTBOARD

          la        $a0, NEWLINE
          li        $v0, 4
          syscall

          la        $a0, GAMEOVERMSG
          li        $v0, 4
          syscall

          la        $a0, NEWLINE
          li        $v0, 4
          syscall

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
AIWINNER:           .asciiz "AI won!\n"
INPUTROW:           .asciiz "Enter row: "
INPUTCOLUMN:        .asciiz "Enter column: "
INVALIDMOVESTR:     .asciiz "Invalid move. Please try again.\n"
PIPE:               .asciiz "|"
PLUS:               .asciiz "+"
NEWLINE:            .asciiz "\n"
BORDER0:            .asciiz "+-"
GREETING:           .asciiz "Let's play a game of Tic-Tac-Toe.\n"
ENTERn:             .asciiz "Enter n: "
FIRST:              .asciiz "I'll go first.\n"
GAMEOVERMSG:        .asciiz "The game is over. It's a tie!"
AIWONMSG:           .asciiz "I'm the winner!\n"
PLAYERWINMSG:       .asciiz "You are the winner!\n"
BOARD:              .byte 0
