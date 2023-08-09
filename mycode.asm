STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'

	WINDOW_WIDTH DW 140h                 ;the width of the window (320 pixels)
	WINDOW_HEIGHT DW 0C8h                ;the height of the window (200 pixels)
	WINDOW_BOUNDS DW 2                   ;variable used to check collisions early
	 
	PLAYER_POINTS DW 0 

	VERTICAL_CENTER DW 32h          ;    ;the limit of ball upward movement

	TIME_AUX DB 0                        ;variable used when checking if the time has changed
	
	BALL_ORIGINAL_X DW 0A0h              ;X position of the ball on the beginning of a game
	BALL_ORIGINAL_Y DW 96h               ;Y position of the ball on the beginning of a game
	BALL_X DW 0A0h                       ;current X position (column) of the ball
	BALL_Y DW 96h                        ;current Y position (line) of the ball
 	BALL_SIZE DW 06h                     ;size of the ball (how many pixels does the ball have in width and height)
	BALL_VELOCITY_X DW 05h               ;X (horizontal) velocity of the ball
	BALL_VELOCITY_Y DW 03h      ;Y (vertical) velocity of the ball
	BALL_COLLISION_VELOCITY DW 10h
	
	TEXT_GAME_OVER_TITLE DB 'GAME OVER','$' ;text with the game over menu title
	
	PLATFORM_X DW 250
	PLATFORM_Y DW 150
	PLATFORM_HEIGHT DW 4
	PLATFORM_WIDTH DW 25	
	
	JUMP_VELOCITY DW 15
	COUNTER DW 0
	NUM DW 100
	
	GAME_ACTIVE DB 1                     ;is the game active? (1 -> Yes, 0 -> No (game over))
	CURRENT_SCENE DB 0                   ;the index of the current scene (0 -> game over menu, 1 -> game)

DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK      ;assume as code,data and stack segments the respective registers
	PUSH DS                              ;push to the stack the DS segment
	SUB AX,AX                            ;clean the AX register
	PUSH AX                              ;push AX to the stack
	MOV AX,DATA                          ;save on the AX register the contents of the DATA segment
	MOV DS,AX                            ;save on the DS segment the contents of AX
	POP AX                               ;release the top item from the stack to the AX register
	POP AX                               ;release the top item from the stack to the AX register
		
	CALL CLEAR_SCREEN
	
	CHECK_TIME:                      ;time checking loop
				
		CMP GAME_ACTIVE,00h
		JE SHOW_GAME_OVER		
				
		MOV AH,2Ch 					 ;get the system time
		INT 21h    					 ;CH = hour CL = minute DH = second DL = 1/100 seconds
		
		CMP DL,TIME_AUX  			 ;is the current time equal to the previous one(TIME_AUX)?
		JE CHECK_TIME    		     ;if it is the same, check again		
;           If it reaches this point, it's because the time has passed

		MOV TIME_AUX,DL              ;update time

		CALL CLEAR_SCREEN
		CALL DRAW_PLATFORM
		CALL MOVE_BALL
		CALL DRAW_BALL
	    CALL DRAW_POINT
		JMP CHECK_TIME               ;after everything checks time again

		SHOW_GAME_OVER:
			CALL DRAW_GAME_OVER_MENU
			JMP CHECK_TIME
	
	RET		
	MAIN ENDP

;-----------------------move ball-----------------------		
	MOVE_BALL PROC NEAR			  ;proccess the movement of the ball
		;check if any key is being pressed
		MOV AH,01h
		INT 16h
		JZ NO_INT 

		;check which key is being pressed (AL = ASCII character)
		MOV AH,00h
		INT 16h
	   
		CMP AL,'j'
		JE MOVE_LEFT
		CMP AL,'k' 
		JE MOVE_RIGHT

		CMP AL,'J'
		JE MOVE_LEFT
		CMP AL,'K' 
		JE MOVE_RIGHT

		JMP NO_INT

		MOVE_LEFT:
			MOV AX,BALL_VELOCITY_X
			SUB BALL_X,AX
			JMP NO_INT
				
		MOVE_RIGHT:
			MOV AX,BALL_VELOCITY_X
			ADD BALL_X,AX
			

		NO_INT:	
		
;       Move the ball verticaly
		MOV AX,BALL_VELOCITY_Y
		SUB BALL_Y,AX
		
		
	;Check if the ball is colliding with the  PLATFORM

    ; BALL_X + BALL_SIZE > PLATFORM_X 
	;&& BALL_X < PLATFORM_X + PLATFORM_WIDTH 
    ;&& BALL_Y + BALL_SIZE > PLATFORM_Y 
	;&& BALL_Y < PLATFORM_Y + PLATFORM_HEIGHT

    MOV AX,BALL_X
    ADD AX,BALL_SIZE
    CMP AX,PLATFORM_X
    JNG NO_COLLISION  

    MOV AX,PLATFORM_X
    ADD AX,PLATFORM_WIDTH
    CMP BALL_X,AX
    JNL NO_COLLISION  

    MOV AX,BALL_Y
    ADD AX,BALL_SIZE
    CMP AX,PLATFORM_Y
    JNG NO_COLLISION 

    MOV AX,PLATFORM_Y
    ADD AX,PLATFORM_HEIGHT
    CMP BALL_Y,AX
    JNL NO_COLLISION 

    ;If it reaches this point, the ball is colliding with the PLATFORM

	ADD PLAYER_POINTS,1
	NEG BALL_VELOCITY_Y
	MOV AX,BALL_COLLISION_VELOCITY
	SUB BALL_Y,AX
	
    ;CHANGE_PLATFORM:	
	MOV AX,PLATFORM_X
	ADD AX,NUM
	MOV BX,280
	XOR DX,DX
	DIV BX
	ADD DX,10
	MOV PLATFORM_X,DX


	MOV AX,PLATFORM_Y
	ADD AX,NUM
	MOV BX,150
	XOR DX,DX
	DIV BX
	ADD DX,50
	MOV PLATFORM_Y,DX
	
	ADD NUM,100
    RET

	NO_COLLISION: 
		
;       Check if the ball has passed the top boundarie (BALL_Y < 0 + WINDOW_BOUNDS)
;       If is colliding, reverse the velocity in Y
		MOV AX,VERTICAL_CENTER   
		CMP BALL_Y,AX                    ;BALL_Y is compared with the top boundarie of the screen (0 + WINDOW_BOUNDS)
		JL NEG_VELOCITY_Y                ;if is less reverve the velocity in Y

;       Check if the ball has passed the bottom boundarie (BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)
;       If is colliding, reverse the velocity in Y		
		MOV AX,WINDOW_HEIGHT
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_Y,AX
		JG RESET
		
;       Check if the ball has passed the left boundarie (BALL_X < 0 + WINDOW_BOUNDS)	
		CMP BALL_X,0                    ;BALL_X is compared with the left boundarie of the screen (0 + WINDOW_BOUNDS)          
		JL HIT_LEFT_WALL
		
;       Check if the ball has passed the right boundarie (BALL_X > WINDOW_WIDTH - BALL_SIZE  - WINDOW_BOUNDS)	
		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_X,AX                     ;BALL_X is compared with the right boundarie of the screen (BALL_X > WINDOW_WIDTH - BALL_SIZE  - WINDOW_BOUNDS)  
		JG HIT_RIGHT_WALL
			
			RET
		HIT_LEFT_WALL:
			MOV BALL_X,0
			RET
			
		HIT_RIGHT_WALL:
			MOV AX,WINDOW_WIDTH
			SUB AX,BALL_SIZE
			SUB AX,WINDOW_BOUNDS
			MOV BALL_X,AX
			RET
			
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y   ;reverse the velocity in Y of the ball (BALL_VELOCITY_Y = - BALL_VELOCITY_Y)
			RET
		
		RESET:
			CALL DRAW_GAME_OVER_MENU
			RET   
	
		RET
	MOVE_BALL ENDP
;------------------------reset the position of ball-----------------------		
	RESET_BALL_POSITION PROC NEAR        ;restart ball position to the original position
		
		MOV AX,BALL_ORIGINAL_X
		MOV BALL_X,AX
		
		MOV AX,BALL_ORIGINAL_Y
		MOV BALL_Y,AX
		
		NEG BALL_VELOCITY_Y
		MOV PLAYER_POINTS,0
		
		RET
	RESET_BALL_POSITION ENDP
	
;------------------------draw ball-----------------------	
	DRAW_BALL PROC NEAR                  
		
		MOV CX,BALL_X                    ;set the initial column (X)
		MOV DX,BALL_Y                    ;set the initial line (Y)
		
		DRAW_BALL_HORIZONTAL:
			MOV AH,0Ch                   ;set the configuration to writing a pixel
			MOV AL,0Ah 					 ;choose green color
			MOV BH,00h 					 ;set the page number 
			INT 10h    					 ;execute the configuration
			
			INC CX     					 ;CX = CX + 1
			MOV AX,CX          	  		 ;CX - BALL_X > BALL_SIZE (Y -> We go to the next line,N -> We continue to the next column
			SUB AX,BALL_X
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
			
			MOV CX,BALL_X 				 ;the CX register goes back to the initial column
			INC DX       				 ;we advance one line
			
			MOV AX,DX             		 ;DX - BALL_Y > BALL_SIZE (Y -> we exit this procedure,N -> we continue to the next line
			SUB AX,BALL_Y
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
		CALL ROUND_THE_BALL
		RET
	DRAW_BALL ENDP
	
;-----------------------draw platform--------------------	
	DRAW_PLATFORM PROC NEAR                  
		
		MOV CX,PLATFORM_X                    ;set the initial column (X)
		MOV DX,PLATFORM_Y                    ;set the initial line (Y)
		
		DRAW_PLATFORM_HORIZONTAL:
			MOV AH,0Ch                   ;set the configuration to writing a pixel
			MOV AL,06h 					 ;choose white as color
			MOV BH,00h 					 ;set the page number 
			INT 10h    					 ;execute the configuration
			
			INC CX     					 ;CX = CX + 1
			MOV AX,CX          	  		 ;CX - PLATFORM_X > PLATFORM_SIZE (Y -> We go to the next line,N -> We continue to the next column
			SUB AX,PLATFORM_X
			CMP AX,PLATFORM_WIDTH
			JNG DRAW_PLATFORM_HORIZONTAL
			
			MOV CX,PLATFORM_X 				 ;the CX register goes back to the initial column
			INC DX       				 ;we advance one line
			
			MOV AX,DX             		 ;DX - PLATFORM_Y > PLATFORM_SIZE (Y -> we exit this procedure,N -> we continue to the next line
			SUB AX,PLATFORM_Y
			CMP AX,PLATFORM_HEIGHT
			JNG DRAW_PLATFORM_HORIZONTAL
		
		RET
	DRAW_PLATFORM ENDP	
	
;-----------------------draw point-----------------------
	DRAW_POINT PROC NEAR
	MOV AH,02h                       ;set cursor position
	MOV BH,00h                       ;set page number
	MOV DH,1                       	 ;set row 
	MOV DL,2						 ;set column
	INT 10h		
	
	MOV AX,PLAYER_POINTS
	XOR CX,CX
	MOV BX,10
	BEGIN_:
		INC CX
		
		XOR DX, DX
		DIV BX
		ADD DX,48
		PUSH DX  
		
		CMP AX,0
		JNZ BEGIN_
	PRINT_:
		POP DX 		
		MOV AX, 0200H
		INT 21H
		LOOP PRINT_		
	RET
DRAW_POINT ENDP

;---------------------
ROUND_THE_BALL    PROC      	
	MOV CX,BALL_X                
	MOV DX,BALL_Y               
	MOV AH,0CH                   
	MOV AL,0 					
	MOV BH,00H 					
	INT 10H 
	
	MOV CX,BALL_X      
	INC CX
	MOV DX,BALL_Y               
	MOV AH,0CH                   
	MOV AL,0 					
	MOV BH,00H 					
	INT 10H  
	
	MOV CX,BALL_X      	
	MOV DX,BALL_Y
	INC DX	
	MOV AH,0CH                   
	MOV AL,0 					
	MOV BH,00H 					
	INT 10H  
	
	MOV CX,BALL_X                
	MOV DX,BALL_Y                    	
	ADD DX,BALL_SIZE
	MOV AH,0CH                   
	MOV AL,0 					
	MOV BH,00H 					 
	INT 10H
	
	MOV CX,BALL_X    
	INC CX
	MOV DX,BALL_Y                    	
	ADD DX,BALL_SIZE
	MOV AH,0CH                   
	MOV AL,0 					
	MOV BH,00H 					 
	INT 10H
	
	MOV CX,BALL_X    
	MOV DX,BALL_Y                    	
	ADD DX,BALL_SIZE
	DEC DX
	MOV AH,0CH                   
	MOV AL,0 					
	MOV BH,00H 					 
	INT 10H
	
	MOV CX,BALL_X                 
	ADD CX,BALL_SIZE
	MOV DX,BALL_Y                  
	MOV AH,0CH                  
	MOV AL,0 					
	MOV BH,00H 					
	INT 10H  

	MOV CX,BALL_X                 
	ADD CX,BALL_SIZE
	DEC CX
	MOV DX,BALL_Y                  
	MOV AH,0CH                  
	MOV AL,0 					
	MOV BH,00H 					
	INT 10H   	
	
	MOV CX,BALL_X                 
	ADD CX,BALL_SIZE
	MOV DX,BALL_Y 
	INC DX
	MOV AH,0CH                  
	MOV AL,0 					
	MOV BH,00H 					
	INT 10H   	
	
	MOV CX,BALL_X                    
	MOV DX,BALL_Y                    
	ADD CX,BALL_SIZE
	ADD DX,BALL_SIZE	
	MOV AH,0CH                   
	MOV AL,0				 
	MOV BH,00H 					
	INT 10H  
	
	MOV CX,BALL_X                    
	MOV DX,BALL_Y                    
	ADD CX,BALL_SIZE
	ADD DX,BALL_SIZE	
	DEC CX
	MOV AH,0CH                   
	MOV AL,0				 
	MOV BH,00H 					
	INT 10H  

	MOV CX,BALL_X                    
	MOV DX,BALL_Y                    
	ADD CX,BALL_SIZE
	ADD DX,BALL_SIZE	
	DEC DX
	MOV AH,0CH                   
	MOV AL,0				 
	MOV BH,00H 					
	INT 10H 
      
    RET    
ROUND_THE_BALL    ENDP

;-----------------------game over screen---------------------------
	DRAW_GAME_OVER_MENU PROC NEAR        ;draw the game over menu
		
		CALL CLEAR_SCREEN                ;clear the screen before displaying the menu

;       Shows the menu title
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,04h                       ;set row 
		MOV DL,04h						 ;set column
		INT 10h							 
		
		MOV AH,09h                       ;WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_GAME_OVER_TITLE      ;give DX a pointer 
		INT 21h                          ;print the string

;       Shows the main menu message
		MOV AH,02h                       ;set cursor position
		MOV BH,00h                       ;set page number
		MOV DH,0Ah                       ;set row 
		MOV DL,04h						 ;set column
		INT 10h							 
		
;       Wait
		MOV AH,00h
		INT 16h
		RET
					
	DRAW_GAME_OVER_MENU ENDP

;-----------------clear screen--------------------	
CLEAR_SCREEN PROC NEAR               ;clear the screen by restarting the video mode

	MOV AH,00h                   	 ;set the configuration to video mode
	MOV AL,13h                   	 ;choose the video mode
	INT 10h    					 	 ;execute the configuration 

	MOV AH,0Bh 					 	 ;set the configuration
	MOV BH,00h 						 ;to the background color
	MOV BL,00h 						 ;choose black as background color
	INT 10h    						 ;execute the configuration
	
	RET
	
CLEAR_SCREEN ENDP
;--------------------------------------------------

	
CODE ENDS
END