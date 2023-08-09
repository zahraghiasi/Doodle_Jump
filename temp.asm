;       Move the ball verticaly
		MOV AX,BALL_VELOCITY_Y
		SUB BALL_Y,AX
		
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
		JNG CHECK_LEFT
		MOV BALL_X,0A0h
		MOV BALL_Y,96h
		

		CHECK_LEFT:
		;Check if the ball has passed the LEFT boundarie (BALL_X < 0)		
		CMP BALL_X,0                    
		JNL CHECK_RIGHT		        
		MOV BALL_X,0
		
		CHECK_RIGHT:
		;Check if the ball has passed the RIGHT boundarie (BALL_X + BALL_SIZE > WINDOW_WIDTH)	
		MOV AX,BALL_X
		ADD AX,BALL_SIZE
		CMP AX,WINDOW_WIDTH                    
		JNG CHECK_UP	
		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE
		DEC AX
		MOV BALL_X,AX
		
		CHECK_UP:    	
		CMP BALL_Y,5                   
		JGE NO_COLLISION2		         
		MOV BALL_Y,5
		MOV JUMPING,0
		RET
		
		NO_COLLISION2:
		MOV AX,JUMPING
		CMP AX,1
		JE JUMP
		
		MOV AX, BALL_VELOCITY_Y
		ADD BALL_Y, AX
		RET

		
		NO1:
		RET
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y   ;reverse the velocity in Y of the ball (BALL_VELOCITY_Y = - BALL_VELOCITY_Y)
			RET