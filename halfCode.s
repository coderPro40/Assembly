/*
 * Name:
 * ThankGod Ofurum
 * Description:
 * This program open two file, codeInput and codeOutput, and iterates through
 * each byte in codeInput and splits the words in two, thereby forming half-
 * words
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

/* 
 * r0 - current char swap
 * r1 - check bit for even/ odd value
 * r2 - start iterator value
 * r3 - mid iterator value
 * r4 - shifted midpoint
 * r5 - other char swap register
 */
compSwap:
	// store values
	stmfd sp!, {r0-r6, fp, lr}
	and r1, r9, #1
	cmp r1, #1
	beq less_loop
	bne less_equal_loop
	move_out:
	// restore values
	ldmfd sp!, {r0-r6, fp, lr}

	bx lr

	less_loop:
	ldr r6, =swapBuffer
	lsr r4, r9, #1
	add r4, r4, #1 //for odd values only
	mov r2, #0 //start value
	sub r3, r4, #1 //mid value
	loop_check1:
	cmp r2, r4 //check to begin loop

	blt start_loop //begin loop

	mov r2, #0 //start value
	mov r3, r4 //mid value
	loop_check3:
	cmp r2, r4 //check to begin extended loop

	blt extended_loop //start loop for odd numbers

	b move_out //exit function

	less_equal_loop:
	lsr r4, r9, #1 //for even values
	mov r2, #0 //start value
	mov r3, r4 //mid value
	loop_check2:
	cmp r2, r4 //check to begin loop

	blt start_loop //begin loop

	b move_out //exit function
	
	start_loop:
	ldrb r0, [r8, r2]
	ldrb r5, [r8, r3]

	cmp r2, #0 // check to see if first letter	
	beq capSwap
	capReturn:

	and r1, r9, #1
	cmp r1, #1
	streqb r0, [r6, r2]
	strb r5, [r8, r2]
	strb r0, [r8, r3]

	add r2, r2, #1 //beg value
	add r3, r3, #1 //mid value

	beq loop_check1
	bne loop_check2

	extended_loop:
	ldrb r0, [r6, r2]
	strb r0, [r8, r3]

	add r2, r2, #1 //beg value
	add r3, r3, #1 //mid value

	b loop_check3

	capSwap:
	cmp r0, #91 // check to see if upper-case
	bgt contd5
	cmplt r0, #64
	blt contd5
	subgt r5, r5, #32
	addgt r0, r0, #32
	contd5:
	b capReturn

/*  
 * - Description:
 * This method fills the read buffer from the specified file descriptor.
 * - Params:
 * r0 = file descriptor
 * r1 = buffer address
 * r2 = buffer length
 * - Returns:
 * r0 = number of bytes read
 */
fill_buffer:
	// store values
	stmfd sp!, {r7, fp, lr}


	mov r7, #3 @call read function from syscall
	svc 0

	// restore values
	ldmfd sp!, {r7, fp, lr}

	bx lr

write_buffer:
	// store values
	stmfd sp!, {r7, fp, lr}
	
	mov r7, #4 @call write function from syscall
	svc 0
	
	// restore values
	ldmfd sp!, {r7, fp, lr}
	
	bx lr

half_code:
	// store values
	stmfd sp!, {r4-r10, fp, lr}

	// r0 = current symbol
	// r1 = position in buffer
	// r2 = number of chars in buffer

	// r4 = buffer address
	// r5 = output file descriptor
	// r6 = file descriptor
	// r8 = output buffer
	// r9 = position in output buffer

	// handle args
	mov r6, r0
	mov r5, r1
	
	// init values
	mov r1, #0
	mov r2, #0
	mov r9, #0
	ldr r4, =buffer
	ldr r8, =outBuffer

	// read file and rotates words
	half_code_loop:
		
		// check for end of buffer and fill if needed
		cmp r1, r2	
		blt half_code_buffer_skip // r1 < r2 skip ahead
		
		// set up args for fill_buffer and call
		mov r0, r6  // descriptor
		mov r1, r4  // buffer address
		ldr r2, =bufferLength
		ldr r2, [r2, #0]
		bl fill_buffer
		
		// check results
		// movs sets flag, indicating r0's relation to #0
		movs r2, r0
		ble half_code_exit 
		
		mov r1, #0 // reset counter

		half_code_buffer_skip:

		// load next byte
		ldrb r0, [r4, r1]

		cmp r0, #122 //set of lower case ascii
		bgt contd1
		cmple r0, #97
		blt contd1
		bge half_code_buffer_skip2
		contd1:

		cmp r0, #57 //set of numeric
		bgt contd2
		cmple r0, #48
		blt contd2
		bge half_code_buffer_skip2
		contd2:

		cmp r0, #32 //space
		bne punctSwap
		beq spacePrevent

		//continue iteration
		half_code_buffer_skip2:

		strb r0, [r8, r9]
		add r9, r9, #1 //increase outBuffer counter
		add r1, r1, #1 //increase open_file counter

		b half_code_loop //continue loop

		spacePrevent:
		sub r3, r9, #1

		// load last byte
		ldrb r3, [r8, r3]

		cmp r3, #122 //set of lower case ascii
		bgt contd3
		cmple r3, #97
		blt contd3
		bge punctSwap //for when byte is a space character
		contd3:

		cmp r3, #57 //set of numeric
		bgt contd4
		cmple r3, #48
		blt contd4
		bge half_code_buffer_skip2 //for when byte is a numeric character
		contd4:

		b spaceSetup

		spaceSetup:
		strb r0, [r8, r9]
		add r9, r9, #1 //increase outBuffer counter

		bl write_buffer_setup
		
		add r1, r1, #1 //increase open_file counter
		b half_code_loop //continue loop

		punctSwap:
		bl compSwap

		cmp r0, #32 //space, check to see whether to branch to write buffer
		beq spaceSetup

		b half_code_buffer_skip2 //continue loop

	half_code_exit: // exit for loop

	//add file termination to end of output
	mov r3, #10 //newline character
	strb r3, [r8,r9]
	add r9, r9, #1

	mov r3, #0 //null byte
	strb r3, [r8,r9]
	add r9, r9, #1

	mov r3, #4 //end of transmission character
	strb r3, [r8,r9]
	add r9, r9, #1

	// write remainder of outBuffer
	bl write_buffer_setup

	// restore values
	ldmfd sp!, {r4-r10, fp, lr}

	bx lr

//function for making sure nothing in volatile registers is lost while writing to file
write_buffer_setup:
	stmfd sp!, {r0-r3, fp, lr}

	mov r0, r5
	mov r1, r8
	mov r2, r9

	bl write_buffer

	mov r9, #0 //reset position in buffer two

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

	// r4 = input file descriptor
	// r5 = output file descriptor		

	// open file
	ldr r0, =fileName
	bl open_file
	cmp r0, #0         // <0 indicates file open failure
	blt file_open_error	
	
	mov r4, r0        // save the file descriptor for the input file

	ldr r0, =outFileName
	bl open_file
	cmp r0, #0
	blt file_open_error

	mov r5, r0        // save the file descriptor for the output file

	// half codes and output to file
	mov r0, r4 		//copy descriptor to temporary registers
	mov r1, r5
	bl half_code	//half code function

	// close file
	mov r0, r4
	bl close_file
	cmp r0, #0
	blt file_close_error

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

	outputString:
		.asciz "Counted %d line(s).\n"
	fileName:
		.asciz "codeInput.txt"
	outFileName:
		.asciz "codeOutput.txt"
	bufferLength: // length of buffer in bytes
		.word 32
	buffer: // buffer of 32 bytes
		.skip 32
	swapBuffer: //buffer for swapping odd numbers
		.skip 32
	outBuffer:
		.skip 35 //slightly larger so we can add file termination chars
	debugString:
		.asciz "here \n"

// way to go multiple and/ or/ not cmp statement
