
			area SuperUltraTicTacToeRedVsBlueEdition, code, readonly
P1LED	dcb 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0 ;LED array for Player 1(Red)
P2LED	dcb 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0 ;LED array for Player 2(Blue)


			export __main
				
__main proc
			BL Test	
			endp
		
	




ButtonToIndex 		function ;Index = X + Y*3 
			;convert 0xXY of button into array index
			;XY is passed by register 0
			;index is returned in register 1
			MOV r10, r0, LSR#4 ;Isolates X into Register 10
			AND r11, r0, #0x0F ;Isolates Y into Register 11
			
			MOV r1, r10 ; Clears return register and adds X
			MOV r10, #3 ;Sets r10 to 3 for multiplication with r11 since X has already been transferred
			MUL r11, r11, r10 ;Multiplies Y by 3
			ADD r1, r1, r11 ;Adds 3Y to index		
			
			CMP r1, #9 ;Index should never be greater than 8, if so return error
			BGE Error
			
			BX LR
			
			endp
				
Delay 		function
inner		MOV R12, #0x50
			subs r12,#1
			bne inner			
			BX LR
			
			endp
				
Error		B Error

Test 		function
			MOV r0, #0x00
			BL ButtonToIndex
			CMP  r1, #0
			BNE Error
			MOV r0, #0x11
			BL ButtonToIndex
			CMP  r1, #4
			BNE Error
			;MOV r0, #0x32
			;BL ButtonToIndex
			;CMP  r1, #9
			;BNE Error
			
			BX LR
			
			endp
			
			end