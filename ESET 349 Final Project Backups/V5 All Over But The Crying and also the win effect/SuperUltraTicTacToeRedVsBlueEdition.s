
			area SuperUltraTicTacToeRedVsBlueEdition, code, readonly
P1LED			EQU 0x20000000 ;LED array for Player 1(Red)
P1PortOffset  	DCB 0x20,0x20,0x20,0x40,0x40,0x40,0x01,0x01,0x01 ;Port offsets for each Player 1 LED
P1Pin			DCB 0x20,0x40,0x80,0x01,0x02,0x04,0x20,0x40,0x80 ;Pin positions offsets for each Player 1 LED

P2LED			EQU (0x20000000+0x10) ;LED array for Player 2(Blue)
P2PortOffset  	DCB 0x00,0x00,0x00,0x21,0x21,0x21,0x21,0x21,0x21 ;Port offsets for each Player 2 LED
P2Pin   		DCB 0x20,0x40,0x80,0x08,0x10,0x20,0x01,0x02,0x04 ;Pin positions offsets for each Player 2 LED 

SWPortOffset 	DCB 0x20,0x20,0x20,0x40,0x40,0x40,0x41,0x41,0x41
SWPin   		DCB 0x01,0x04,0x08,0x10,0x20,0x40,0x10,0x20,0x40

PlayerPortOffset 	DCB 0x41, 0x41 ;Port Offset for P1 and P2 indicators
PlayerPin			DCB 0x01, 0x02 ;Pins for P1 and P2 indicators

			export __main
				
__main proc
			BL RAMClear ;This calls for a ram clear to ensure no loose dat is in the active LED arrays
			
			MOV r4, #2 ;Sets array size to 2 for indicator array initialization
			LDR r10, =PlayerPortOffset 
			LDR r11, =PlayerPin
			BL InitLED ;Initializes player indicator LEDS
			MOV r4, #9 ;Sets array size to 9 for LED array initialization
			LDR r10, =P1PortOffset
			LDR r11, =P1Pin
			BL InitLED ;Initializes Player 1's LEDs
			LDR r10, =P2PortOffset
			LDR r11, =P2Pin
			BL InitLED ;Initializes Player 2's LEDs
			LDR r10, =SWPortOffset
			LDR r11, =SWPin
			BL InitSwitch ;Initializes the buttons

			MOV r5, #0x0 ;Sets starting player to P1

GameLoop	CMP r5, #0x0
			BNE SetP2Array
			;These array setups set r10 and 11
SetP1Array 	LDR r8, =P1PortOffset
			LDR r9, =P1Pin	
			LDR r6, =P1LED	
			B ExitArraySetup
			
SetP2Array	LDR r8, =P2PortOffset
			LDR r9, =P2Pin
			LDR r6, =P2LED	
			B ExitArraySetup
			
ExitArraySetup
			LDR r10, =PlayerPortOffset 
			LDR r11, =PlayerPin
			BL ToggleActivePlayerIndicator ;Turns indicator for current player ON
			
LEDInUse	LDR r10, =SWPortOffset
			LDR r11, =SWPin
			BL ReadSwitch
			
			LDR r2, =P1LED
			BL IsLEDOn ;Checks Player 1 for active LED
			CMP r3, #0x1
			BEQ LEDInUse
			LDR r2, =P2LED
			BL IsLEDOn ;Checks Player 2 for active LED
			CMP r3, #0x1
			BEQ LEDInUse
			
			BL UpdateLEDArray
			
			;PHYSICAL LED SWITCH GOES HERE
			BL CheckWin
			CMP r4, #0x1
			BEQ WinnerWinnerChickenDinner
			
			LDR r10, =PlayerPortOffset 
			LDR r11, =PlayerPin
			BL ToggleActivePlayerIndicator ;Turns current playe indicator LED OFF
			BL ToggleActivePlayer
			BL Delay
			B GameLoop
			
WinnerWinnerChickenDinner
			NOP
			B WinnerWinnerChickenDinner
end
			NOP
			B end
			
			
			
			;BL Test	
			;NOP
			;NOP
			
			endp
		
	
ReadSwitch function 
			;r10 holds switch port offset array
			;r11 holds switch pin array
			;r0 holds base address
			;r1 retuns index for FIRST activated switch
			;r2 holds register contents
			;r3 holds pin mask
			STMFD sp!, {lr}
NoInput		MOV r1, #0	;Starts/resets temp index at position 0
ReadSwitchLoop	
			LDR r0, =0x40004C00 ;this loads base address	
			LDRB r2, [r10, r1] ;loads offset at index pos from port offset array
			ADD r0, r0, r2 ; adds offset to base address
			LDRB r3, [r11, r1] ;loads pin at index from pin array
			LDRB r2, [r0, #0x00] ;Loads current INPUT from port	
			AND r3, r3, r2 ;ands cueent input to isolate pin
			CMP r3, #0x00 ;checks if input is high
			BNE InputFound ;breaks out of loop if a switch is detected to be pressed
			ADD r1, r1, #0x01 ;increments index
			CMP r1, #0x09 ;checks if all buttons have been checked
			BLT ReadSwitchLoop
			B NoInput ;reruns detector if no input is found
				
InputFound  NOP

			LDMFD sp!, {pc}
			endp	
	
RAMClear function ;clears all memory in RAM
			;r10 holds current address in RAM
			;r11 holds clear for ram
			STMFD sp!, {lr}
			LDR r10, =0x20000000
RAMClearLoop	
			MOV r11, #0x00
			STRB r11, [r10]
			ADD r10, #0x1
			LDR r11, =0x20000100
			CMP r10, r11
			BNE RAMClearLoop
			
			LDMFD sp!, {pc}
			endp
				
InitSwitch	function
			;Switch Port offset array passed by r10
			;Switch Pin array passed by r11
			;r0 holds the base address
			;r1 holds index
			;r2 holds current pin mask
			;r3 holds register contents
			;array size passed by r4
			STMFD sp!, {lr}
			MOV r1, #0	;Starts index as position 0
SwitchInitLoop	
			LDR r0, =0x40004C00 ;this loads base address
			LDRB r2, [r10, r1] ;loads offset at index pos from port offset array
			ADD r0, r0, r2 ; adds offset to base address
			LDRB r2, [r11, r1] ;loads pin at index from pin array
			LDRB r3, [r0, #0x06] ;Loads current REN from port
			ORR r3, r2, r3 ;sets r2 pin REN to 1
			STRB r3, [r0, #0x06]  ;Stores updated REN back to port	
			EOR r2, r2, #0xFF ;inverts r2 to clear bits		
			LDRB r3, [r0, #0x04] ;Loads current pin directions from port
			AND r3, r2, r3 ;sets current pin to input without altering others
			STRB r3, [r0, #0x04] ;Stores updated port directions to port
			

			ADD r1, r1, #1
			CMP r1, r4
			BNE SwitchInitLoop
			
			LDMFD sp!, {pc}
			endp

EnableLED	function
			;PlayerX Port offset passed by r8
			;PlayerX Pin passed by r9
			;r0 holds the base address
			;r1 passes index
			;r2 holds current pin mask
			;r3 holds register contents
			STMFD sp!, {lr}
			LDR r0, =0x40004C00 ;this loads base address
			LDRB r2, [r8, r1] ;loads offset at index pos from port offset array
			ADD r0, r0, r2 ; adds offset to base address
			LDRB r2, [r9, r1] ;loads pin at index from pin array
			LDRB r3, [r0, #0x02] ;Loads current output from port
			ORR r3, r2, r3 ;sets r2 pin output to high(1)
			STRB r3, [r0, #0x02]  ;Stores updated output back to port			
			
			
			LDMFD sp!, {pc}
			endp

InitLED	function
			;PlayerX Port offset passed by r10
			;PlayerX Pin passed by r11
			;r0 holds the base address
			;r1 holds index
			;r2 holds current pin mask
			;r3 holds register contents
			;array size passed by r4
			STMFD sp!, {lr}
			MOV r1, #0	;Starts index as position 0
LEDInitLoop	LDR r0, =0x40004C00 ;this loads base address
			LDRB r2, [r10, r1] ;loads offset at index pos from port offset array
			ADD r0, r0, r2 ; adds offset to base address
			LDRB r2, [r11, r1] ;loads pin at index from pin array
			LDRB r3, [r0, #0x04] ;Loads current pin directions from port
			ORR r3, r2, r3 ;sets current pin to output without altering others
			STRB r3, [r0, #0x04] ;Stores updated port directions to port
			EOR r2, r2, #0xFF ;inverts r2 to clear bits
			LDRB r3, [r0, #0x06] ;Loads current REN from port
			AND r3, r2, r3 ;sets r2 pin REN to 0
			STRB r3, [r0, #0x06]  ;Stores updated REN back to port
			LDRB r3, [r0, #0x02] ;Loads current output from port
			AND r3, r2, r3 ;sets r2 pin output to 0
			STRB r3, [r0, #0x02]  ;Stores updated output back to port			
			
			ADD r1, r1, #1
			CMP r1, r4
			BNE LEDInitLoop
			
			LDMFD sp!, {pc}
			endp

ToggleActivePlayerIndicator function
			;current player value is passed by r5(This acts as the index)
			;0x0 is player 1 0x1 is player 2
			;PlayerPortOffset array passed by r10
			;PlayerPin array passed by r11
			;r2 holds base address
			;r3 holds current pin mask
			;r4 holds register contents
			STMFD sp!, {lr}
			LDR r2, =0x40004C00 ;this loads base address
			LDRB r4, [r10, r5] ;loads offset at index pos from port offset array
			ADD r2, r2, r4 ; adds offset to base address
			LDRB r4, [r2, #0x02] ;Loads current output from port
			LDRB r3, [r11, r5] ;loads pin at index from pin array
			EOR r4, r4, r3 ;sets r3 pin output to 1
			STRB r4, [r2, #0x02]  ;Stores updated output back to port						
			
			LDMFD sp!, {pc}
			endp
				
ToggleActivePlayer function ;DO NOT EVER, EVER TOUCH THIS
			;current player value is passed by r5
			;r5 returns updated player value
			;0x0 is player 1 0x1 is player 2
			STMFD sp!, {lr}
			EOR r5, #0x1 ;This flips the active player IT SHOULD ALWAYS BE 0x1 OTHERWISE BAD THINGS HAPPEN
			LDMFD sp!, {pc}
			endp
				
UpdateLEDArray	function
			;Index is passed by r1
			;Current Player array address is passed by r6
			;NO RETURN VALUE
			STMFD sp!, {lr}
			MOV r10, #0x1 ;preps r10 with an activatedd LED valeue to add to array
			STRB r10, [r6, r1]
			
			LDMFD sp!, {pc}
			endp

IsLEDOn	function
			;Index is passed by r1
			;Current Player array address is passed by r2
			;Returns LED status in r3
			STMFD sp!, {lr}

			LDRB r3, [r2, r1]
			
			LDMFD sp!, {pc}
			endp

;THIS FUNCTION IS DEPRECATED,it has been commented out in case something from it is still needed
;ButtonToIndex 	function ;Index = X + Y*3 
			;convert 0xXY of button into array index
			;XY is passed by register 0
			;index is returned in register 1
			;STMFD sp!, {lr}

			;MOV r10, r0, LSR#4 ;Isolates X into Register 10
			;AND r11, r0, #0x0F ;Isolates Y into Register 11
			
			;MOV r1, r10 ; Clears return register and adds X
			;MOV r10, #3 ;Sets r10 to 3 for multiplication with r11 since X has already been transferred
			;MUL r11, r11, r10 ;Multiplies Y by 3
			;ADD r1, r1, r11 ;Adds 3Y to index		
			
			;CMP r1, #9 ;Index should never be greater than 8, if so return error
			;BGE ErrorUnreachableIndex
			
			;LDMFD sp!, {pc}
			;endp

ErrorUnreachableIndex	B ErrorUnreachableIndex 
			;If you end up here something is VERY wrong
			;check button XY to ensure neither are greater than 2
		
CheckWin 	function ;Check Page# on manual for array guide to win cases
			;Current Player array address is passed by r6
			;r10 and r11 are used as temp registers tocheck for win
			;Win boolean is returned by r4
			STMFD sp!, {lr}
			MOV r4, #0 ;Defaults to no win
		
			;Check for Win Condition 1
			MOV r11, #0
			LDRB r10, [r6, r11]
			MOV r11, #3
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			MOV r11, #6
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			ORR r4, r4, r10
			
			;Check for Win Condition 2
			MOV r11, #1
			LDRB r10, [r6, r11]
			MOV r11, #4
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			MOV r11, #7
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			ORR r4, r4, r10
			
			;Check for Win Condition 3
			MOV r11, #2
			LDRB r10, [r6, r11]
			MOV r11, #5
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			MOV r11, #8
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			ORR r4, r4, r10
			
			;Check for Win Condition 4
			MOV r11, #6
			LDRB r10, [r6, r11]
			MOV r11, #7
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			MOV r11, #8
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			ORR r4, r4, r10
			
			;Check for Win Condition 5
			MOV r11, #3
			LDRB r10, [r6, r11]
			MOV r11, #4
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			MOV r11, #5
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			ORR r4, r4, r10
			
			;Check for Win Condition 6
			MOV r11, #0
			LDRB r10, [r6, r11]
			MOV r11, #1
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			MOV r11, #2
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			ORR r4, r4, r10
			
			;Check for Win Condition 7
			MOV r11, #6
			LDRB r10, [r6, r11]
			MOV r11, #4
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			MOV r11, #2
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			ORR r4, r4, r10
			
			;Check for Win Condition 8
			MOV r11, #8
			LDRB r10, [r6, r11]
			MOV r11, #4
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			MOV r11, #0
			LDRB r11, [r6, r11]
			AND r10, r10, r11
			ORR r4, r4, r10
			
			LDMFD sp!, {pc}
			endp

Delay 		function
			STMFD sp!, {lr}
			MOV r12, #0x500
inner		SUBS r12,#0x01
			CMP r12, #0x00
			bne inner		
			
			LDMFD sp!, {pc}
			endp
				

;Test function has been deprecated by ReadSwitch, all testing should be done manually
;Test 		function
			;STMFD sp!, {lr}
			;This tests the ButtonToIndex converter
			;MOV r0, #0x00
			;BL ButtonToIndex
			;CMP  r1, #0
			;BNE ErrorIndexIncorrect
			;MOV r0, #0x11
			;BL ButtonToIndex
			;CMP  r1, #4
			;BNE ErrorIndexIncorrect
			;MOV r0, #0x32
			;BL ButtonToIndex
			;CMP  r1, #9
			;BNE Error
			
			;;This tests the UpdateLEDArray and IsLEDOn functions for Player 1's array
			;MOV r0, #0x00
			;BL ButtonToIndex
			;LDR r2, =P1LED
			;BL IsLEDOn
			;CMP r3, #0x01
			;BEQ ErrorLEDNotCleared
			;BL UpdateLEDArray
			;BL IsLEDOn
			;CMP r3, #0x01
			;BNE ErrorLEDNotUpdated
			
			;MOV r0, #0x00
			;BL ButtonToIndex
			;LDR r2, =P2LED
			;BL IsLEDOn
			;CMP r3, #0x01
			;BEQ ErrorLEDNotCleared
			;BL UpdateLEDArray
			;BL IsLEDOn
			;CMP r3, #0x01
			;BNE ErrorLEDNotUpdated
			
			;This tests win condition 1 For player 2
			;MOV r0, #0x00
			;BL ButtonToIndex
			;LDR r2, =P2LED
			;BL UpdateLEDArray
			;MOV r0, #0x01
			;BL ButtonToIndex
			;LDR r2, =P2LED
			;BL UpdateLEDArray
			;MOV r0, #0x02
			;BL ButtonToIndex
			;LDR r2, =P2LED
			;BL UpdateLEDArray
			;BL CheckWin
			;CMP r4, #0x1
			;BNE ErrorWinNotDetected
			;LDR r2, =P1LED
			;BL CheckWin
			;CMP r4, #0x1
			;BEQ ErrorUndeservedWin
			
			;This tests win condition 7 for player 1
			;MOV r0, #0x02
			;BL ButtonToIndex
			;LDR r2, =P1LED
			;BL UpdateLEDArray
			;MOV r0, #0x11
			;BL ButtonToIndex
			;LDR r2, =P1LED
			;BL UpdateLEDArray
			;MOV r0, #0x20
			;BL ButtonToIndex
			;LDR r2, =P1LED
			;BL UpdateLEDArray
			;BL CheckWin
			;CMP r4, #0x1
			;BNE ErrorWinNotDetected

			;LDMFD sp!, {pc}			
			;endp
			

ErrorWinNotDetected B ErrorWinNotDetected
			;This means that CheckWin failed to detect a valid win condition
			;Consult the guide for the condition that failed and then check CheckWin

ErrorUndeservedWin B ErrorUndeservedWin
			;This means that CheckWin has incorrectly granted a player a win
			;Check the index codes for each win and then check to make sure that the RAM positions for both player arrays are successfully clearing
			;You may also wish to chack player 1's pockets

ErrorLEDNotCleared	B ErrorLEDNotCleared
			;This means that the LED array did not startt zeroed
			;CHECK LED STATUS ARRAYS AT TOP OF PROGRAM
			
ErrorLEDNotUpdated B ErrorLEDNotUpdated
			;This means that the LED did not get enabled by the update function
			;CHECK UpdateLEDArray FOR ERROR

ErrorIndexIncorrect	B ErrorIndexIncorrect
			;This means the Index converter is not returning the correct value
			;Check ButtonToIndex Function
			
			end