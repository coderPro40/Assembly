/*
 * Name:
 * ThankGod Ofurum
 * Date:
 * 4/6/2016
 * Description:
 * This program open one file, masterOut and prompts player one for code input
 * then player two is given 12 turns to guess what the code used by player one
 * is, and the results and answers are written to masterOut file.
 */

.global main
.func	main

/*
 * - Description:
 * This method opens a file and stores the descriptor at memory location file.
 * - Params:
 * r0 : Address of file name in memory.
 * - Returns:
 * r0 : File Descriptor
 */
open_file:
	// store values
	stmfd sp!, {r7, fp, lr}

	// set up syscall
	mov r1, #2 // flag O_RDWR
	mov r2, #0 // mode
	mov r7, #5
	svc 0

	ldmfd sp!, {r7, fp, lr}

	bx lr

/* 
 * - Description:
 * This method closes a file whose descriptor is stored at memory location file.
 * - Params:
 * r0 = file descriptor
 * - Returns:
 * r0 = 0 for success; -1 for error
 */
 close_file:
	stmfd sp!, {r7, fp, lr}

	mov r7, #6 //function call for closing file 
	svc 0

	ldmfd sp!, {r7, fp, lr}

	bx lr

begGameIntro:
	// store values
	stmfd sp!, {r4-r9, fp, lr}

	bl printf

	ldr r0, =strFormat
	mov r1, r10
	bl scanf

	// restore values
	ldmfd sp!, {r4-r9, fp, lr}

	bx lr

changeBuffer:
	// store values
	stmfd sp!, {r4-r6, fp, lr}

	ldr r3, =player
	ldr r3, [r3]
	mov r0, #0

	repLoop:
	cmp r3, #0	//conditon for changing

	ldrb r1, [r10, r0]
	streqb r1, [r8, r0]
	strgtb r1, [r9, r0]
	cmp r0, #4
	addlt r0, r0, #1
	blt repLoop

	// restore values
	ldmfd sp!, {r4-r6, fp, lr}

	bx lr

startGame:
	// store values
	stmfd sp!, {r0-r6, fp, lr}
	// r0 = loop count for code position
	// r1 = loop count for player's position
	// r2 = code element
	// r3 = player element 
	// r4 = free use counter

	// r5 = incorrect position
	// r6 = correct position
	ldr r0, =correctPosCount
	ldr r6, [r0]
	ldr r0, =incorrectPosCount
	ldr r5, [r0]
	mov r1, #0

	nextLoop:
	cmp r1, #4

	blt mainLoop

	LoopExit:
	ldmfd sp!, {r0-r6, fp, lr}

	bx lr

	mainLoop:	//mostly just for comparisons to arrive at best decision based on situation
		ldrb r2, [r8, r1]
		mov r4, r1

		backIterateLoop:
		cmp r4, #0
		bgt checkLoop

		mov r0, #0 //start second loop

		futureLoop:
		cmp r0, #4
		blt 2ndMainLoop

		add r1, r1, #1
		b nextLoop

	2ndMainLoop:	//new loop for player's symbols
		ldrb r3, [r9, r0]
		ldrb r4, [r8, r0]

		cmp r2, r3	//values
		bne nextPass

		cmpeq r0, r1	//positions of current value to value checked
		addeq r6, r6, #1
		beq nextPass		

		cmpne r3, r4	//upper positions of value checked
		addeq r6, r6, #1
		beq nextPass

		mov r4, r0		//for when correct position fails, and need to check for incorrect position
		backIterateLoop_two:
		cmp r4, #0
		bgt incorLoop
		ldrb r2, [r8, r1]
		add r5, r5, #1

		nextPass:
		add r0, r0, #1
		b futureLoop

	checkLoop:	//check to make sure no duplicate values
		sub r4, r4, #1
		ldrb r3, [r8, r4]

		cmp r2, r3
		addeq r1, r1, #1
		beq nextLoop

		b backIterateLoop

	incorLoop:	//check for incorrect use of cmp statement
		sub r4, r4, #1	//all previous values
		ldrb r2, [r9, r4]
		cmp r2, r3

		bne backIterateLoop_two

		mov r7, #0
		mov r10, #0
		mov r4, #0	//assuming equality, T/F

		backIterateLoop_three:
		cmp r4, #4
		blt incorLoop2
		cmp r7, r10

		addle r5, r5, #1
		ldrb r2, [r8, r1]

		b nextPass

	incorLoop2:
		ldrb r2, [r9, r4]
		cmp r2, r3
		addeq r7, r7, #1
		ldrb r2, [r8, r4]
		cmp r2, r3
		addeq r10, r10, #1
		b backIterateLoop_three

write_buffer:
	// store values
	stmfd sp!, {r7, fp, lr}
	
	mov r7, #4 @call write function from syscall
	svc 0
	
	// restore values
	ldmfd sp!, {r7, fp, lr}
	
	bx lr

gameStart:
	// store values
	stmfd sp!, {r4-r10, fp, lr}

	// r4 = current iteration count
	// r5 = position in output buffer
	// r6 = output file descriptor
	// r8 = code buffer
	// r9 = player input buffer
	// r10 = global & output buffer

	// handle args
	mov r6, r0

	// init values
	mov r4, #0
	mov r5, #0
	ldr r2, =player
	ldr r2, [r2] 

	repPrompt:
	ldr	r0, =codeString
	ldr r8, =codeBuff
	ldr r9, =inputBuff
	ldr r10, =globeBuff

	bl begGameIntro

	b GameComparison
	contGame:
	bl changeBuffer

	//for controlling player turns
	add r2, r2, #1
	ldr r1, =player
	str r2, [r1]

	write_buffer_setup

	//start the game with the iterations and all
	mainGameLoop:
		repPrompt_two:
		ldr r0, =inputString	// repeat loop process seen before
		bl begGameIntro

		b GameComparison	//need place holder
		contGame_two:
		bl changeBuffer		//buffers filled, game starts

		write_buffer_setup

		bl startGame

		ldr r10, =globeBuff	//for remembrance

		b gameExitChecker


	GameComparison:
	ldr r2, =player
	ldr r2, [r2]
	ldrb r0, [r10, r5]

	cmp r0, #103 //set of lower case ascii
	movge r5, #0
	cmpge r2, #0
	bgt repPrompt_two
	beq repPrompt
	cmp r0, #96
	movle r5, #0
	cmple r2, #1
	blt repPrompt
	beq repPrompt_two
	add r5, r5, #1 //Iterate to make sure values are within given parameters
	cmp r5, #4		// repeat if not
	blt GameComparison

	cmp r2, #0
	bgt contGame_two
	beq contGame

	gameExitChecker:
	add r4, r4, #1
	cmp r4, #12
	blt mainGameLoop
	b gameExit

	gameExit:
	ldmfd sp!, {r4-r10, fp, lr}

	bx lr

write_buffer_setup:
	stmfd sp!, {r0-r3, fp, lr}

	mov r3, #10 //newline character
	strb r3, [r10,r5]
	add r5, r5, #1

	mov r0, r6
	mov r1, r10
	mov r2, r5

	bl write_buffer

	mov r5, #0 //reset position in global buffer

	ldmfd sp!, {r0-r3, fp, lr}

	bx lr

debugging:
	stmfd sp!, {r0-r10, fp, lr}
	ldr r0, =debugString
	bl printf
	ldmfd sp!, {r0-r10, fp, lr}
	bx lr

main:
	// store values
	stmfd sp!, {r4-r10, fp, lr}

	// r5 = output file descriptor

	// open file
	ldr r0, =outFileName
	bl open_file
	cmp r0, #0			// <0 indicates file open failure
	blt file_open_error

	mov r5, r0        // save the file descriptor for the output file

	// Iterate turns and output to file
	mov r0, r5		//copy descriptor to temporary registers
	bl gameStart

	// close file
	mov r0, r5
	bl close_file
	cmp r0, #0
	blt file_close_error

	main_exit:

	// restore values
	ldmfd sp!, {r4-r10, fp, lr}

	bx lr

	file_open_error: 
		ldr r0, =fileOpenError
		bl printf
		mov r0, #1
		b main_exit
	file_close_error:
		ldr r0, =fileCloseError
		bl printf
		mov r0, #2
		b main_exit

.data
	fileOpenError:
		.asciz "Failed to open the specified file.\n"
	fileCloseError:
		.asciz "Failed to close the specified file.\n"

	codeString:
		.asciz "player 1 please enter code of 4 letters between A and F: \n"
	inputString:
		.asciz "player 2 please enter code of 4 letters between A and F: \n"
	outFileName:
		.asciz "masterOut.txt"
	win:
		.asciz "win \n"
	lose:
		.asciz "lose \n"

	bufferLength: // length of buffer in bytes
		.word 32
	globeBuff: // buffer of 32 bytes
		.skip 32
	codeBuff: // buffer for player 1
		.skip 4
	inputBuff: //buffer for player 2
		.skip 4

	correctPosCount:
		.word 0
	incorrectPosCount:
		.word 0
	player:
		.word 0

	correctResponse:
		.asciz "%d correct position \n"
	incorrectResponse:
		.asciz "%d incorrect position \n"
	incorrectResponse_two:
		.asciz "%d correct position, %d incorrect position \n"
	strFormat:
		.asciz "%4s"
	
	
	debugString:
		.asciz "here \n"