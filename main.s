# ============================================================================
# Authors:
# Ryan Frappier, Faizal Glenn
#
# Description:
# This is a simple tic-tac-toe game with a basic AI.
#
# Register usage: $s0 = input_row
#                  $s1 = input_col
#
# ============================================================================

          .text
          .globl    main

main:
GAMELOOP:    
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
              li        $v0, 10
              syscall
# Converts a row and column to an index for a 1-D array.
# INPUTS:
# a0 = row
# a1 = col
# OUTPUTS:
# v0 = index
ROWCOLTOINDEX: 
        move $v0, $a0
        li   $t0, 3
        mul  $v0, $v0, $t0
        add  $v0, $v0, $a1
        
        jr   $ra

# -------
# | | | |
# |-----|
# | |X| |
# |-----|
# | | |O|
# -------

PRINTBOARD:

              .data
INPUTROW:         .asciiz "Enter row: "
INPUTCOLUMN:     .asciiz "Enter column: "
BOARD:
        .byte 32 32 32
        .byte 32 32 32
        .byte 32 32 32
