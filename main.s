# ============================================================================
# Authors:
# Ryan Frappier, Faizal Glenn
#
# Description:
# This is a simple tic-tac-toe game with a basic AI.
#
# Register usage:
#
# ============================================================================

          .text
          .globl    main

main: li $v0, 5 # get input 
	

EXIT:
          li        $v0, 10
          syscall


          .data
