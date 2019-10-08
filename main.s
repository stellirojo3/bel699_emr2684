;****************** main.s ***************
; Program written by: Estela Rojas and Ben Liu
; Date Created: 2/14/2017
; Last Modified: 10/7/2019
; You are given a simple stepper motor software system with one input and
; four outputs. This program runs, but you are asked to add minimally intrusive
; debugging instruments to verify it is running properly. 
; The system outputs in one of three modes:
; 1) cycles through 10,6,5,9,... at a constant rate
; 2) cycles through 5,6,10,9,... at a constant rate
; 3) does not change the output, but still outputs at a constant rate
; When PA4 goes high and low again, the system cycles through these modes
; The output rate will be different on the simulator versus the real board
;   Insert debugging instruments which gather data (state and timing)
;   to verify that the system is functioning as expected.
; Hardware connections (External: One button and four outputs to stepper motor)
;  PA4 is Button input  (1 means pressed, 0 means not pressed)
;  PE3-0 are stepper motor outputs 
;  PF2 is Blue LED on Launchpad used as a heartbeat
; Instrumentation data to be gathered is as follows:
; After every output to Port E, collect one state and time entry. 
; The state information is the 5 bits on Port A bit 4 and Port E PE3-0
;   place one 8-bit entry in your Data Buffer  
; The time information is the 24-bit time difference between this output and the previous (in 12.5ns units)
;   place one 32-bit entry in the Time Buffer
;    24-bit value of the SysTick's Current register (NVIC_ST_CURRENT_R)
;    you must handle the roll over as Current goes 3,2,1,0,0x00FFFFFF,0xFFFFFE,
; Note: The size of both buffers is 100 entries. Once you fill these
;       entries you should stop collecting data
; The heartbeat is an indicator of the running of the program. 
; On each iteration of the main loop of your program toggle the 
; LED to indicate that your code(system) is live (not stuck or dead).

SYSCTL_RCGCGPIO_R  EQU 0x400FE608
NVIC_ST_CURRENT_R  EQU 0xE000E018
GPIO_PORTA_DATA_R  EQU 0x400043FC
GPIO_PORTA_DIR_R   EQU 0x40004400
GPIO_PORTA_DEN_R   EQU 0x4000451C
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_DEN_R   EQU 0x4002451C
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_DEN_R   EQU 0x4002551C
; RAM Area
          AREA    DATA, ALIGN=2
Index     SPACE 4 ; index into Stepper table 0,1,2,3
Direction SPACE 4 ; -1 for CCW, 0 for stop 1 for CW
DataBuffer  SPACE 100		;stores 8 bit entries
TimeBuffer	SPACE 400		;stores 32 bit entries
DataPt		SPACE 4
TimePt		SPACE 4
TimeBefore	SPACE 4
	
;place your debug variables in RAM here

; ROM Area
        IMPORT TExaS_Init
        IMPORT SysTick_Init
;-UUU-Import routine(s) from other assembly files (like SysTick.s) here
        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
Stepper DCB 5,6,10,9
        EXPORT  Start

Start		;from start to stepper_init: instruc = 28
 ; TExaS_Init sets bus clock at 80 MHz
; PA4, PE3-PE0 out logic analyzer to TExasDisplay
      LDR  R0,=SendDataToLogicAnalyzer
      ORR  R0,R0,#1
      BL   TExaS_Init ; logic analyzer, 80 MHz
 ;place your initializations here
      BL   Stepper_Init ; initialize stepper motor
      BL   Switch_Init  ; initialize switch input
;**********************
      BL   Debug_Init ;(you write this)
;**********************
      CPSIE  I    ; TExaS logic analyzer runs on interrupts
      MOV  R5,#0  ; last PA4
loop  
	  BL   Heartbeat
      LDR  R1,=GPIO_PORTA_DATA_R
      LDR  R4,[R1]  ;current value of switch
      AND  R4,R4,#0x10 ; select just bit 4
      CMP  R4,#0
      BEQ  no     ; skip if not pushed
      CMP  R5,#0
      BNE  no     ; skip if pushed last time
      ; this time yes, last time no
      LDR  R1,=Direction
      LDR  R0,[R1]  ; current direction
      ADD  R0,R0,#1 ;-1,0,1 to 0,1,2
      CMP  R0,#2
      BNE  ok
      MOV  R0,#-1  ; cycles through values -1,0,1
ok    STR  R0,[R1] ; Direction=0 (CW)  
no    MOV  R5,R4   ; setup for next time	;17 instruc from start of loop to here
      BL   Stepper_Step               
      LDR  R0,=1600000						
      BL   Wait  ; time delay fixed but not accurate   
      B    loop								;3200004 from after stepper to here
;Initialize stepper motor interface
Stepper_Init	;instructions in stepper_int = 21
      MOV R0,#1
      LDR R1,=Direction
      STR R0,[R1] ; Direction=0 (CW)
      MOV R0,#0
      LDR R1,=Index
      STR R0,[R1] ; Index=0
    ; activate clock for Port E
      LDR R1, =SYSCTL_RCGCGPIO_R
      LDR R0, [R1]
      ORR R0, R0, #0x10  ; Clock for E
      STR R0, [R1]
      NOP
      NOP                 ; allow time to finish activating
    ; set direction register
      LDR R1, =GPIO_PORTE_DIR_R
      LDR R0, [R1]
      ORR R0, R0, #0x0F    ; Output on PE0-PE3
       STR R0, [R1]
    ; enable digital port
      LDR R1, =GPIO_PORTE_DEN_R
      LDR R0, [R1]
      ORR R0, R0, #0x0F    ; enable PE3-0
      STR R0, [R1]
      BX  LR
	  
;Initialize switch interface
Switch_Init			;instructions in switch_init = 29
    ; activate clock for Port A
      LDR R1, =SYSCTL_RCGCGPIO_R
      LDR R0, [R1]
      ORR R0, R0, #0x01  ; Clock for A
      STR R0, [R1]
      NOP
      NOP                 ; allow time to finish activating
	; activate clock for Port F
	  LDR R1, =SYSCTL_RCGCGPIO_R
      LDR R0, [R1]
      ORR R0, R0, #0x20  ; Clock for F
      STR R0, [R1]
      NOP
      NOP                 ; allow time to finish activating
	  
    ; set direction register
      LDR R1, =GPIO_PORTA_DIR_R
      LDR R0, [R1]
      BIC R0, R0, #0x10    ; Input on PA4
      STR R0, [R1]
	; set direction register for PF2
	  LDR R1, =GPIO_PORTF_DIR_R
      LDR R0, [R1]
      ORR R0, R0, #0x04    ; Output on PF2
      STR R0, [R1]

    ; 5) enable digital port
      LDR R1, =GPIO_PORTA_DEN_R
      LDR R0, [R1]
      ORR R0, R0, #0x10    ; enable PA4
      STR R0, [R1]
	; enable digital port for PF2
      LDR R1, =GPIO_PORTF_DEN_R
      LDR R0, [R1]
      ORR R0, R0, #0x04    ; enable PA4
      STR R0, [R1]
      BX  LR
; Step the motor clockwise
; Direction determines the rotational direction
; Input: None
; Output: None
Stepper_Step		;instruction in stepper_step = 17 
      PUSH {R4,LR}
      LDR  R1,=Index
      LDR  R2,[R1]     ; old Index
      LDR  R3,=Direction
      LDR  R0,[R3]     ; -1 for CCW, 0 for stop 1 for CW
      ADD  R2,R2,R0
      AND  R2,R2,#3    ; 0,1,2,3,0,1,2,...
      STR  R2,[R1]     ; new Index
      LDR  R3,=Stepper ; table
      LDRB R0,[R2,R3]  ; next output: 5,6,10,9,5,6,10,...
      LDR  R1,=GPIO_PORTE_DATA_R ; change PE3-PE0
      STR  R0,[R1]
      BL   Debug_Capture
      POP {R4,PC}
; inaccurate and inefficient time delay
Wait 
      SUBS R0,R0,#1  ; outer loop
      BNE  Wait
      BX   LR
      
Debug_Init 				;#instruc in Debug_init = 24
      PUSH {R0-R4,LR}
; you write this
;set all entries of first DataBuffer to 0xFF
	  MOV R0, #0x00		;array element counter
	  MOV R1, #0xFF
	  LDR R2, =DataBuffer
again STRB R1, [R2,R0]
	  ADD R0, R0, #1		
	  CMP R0, #100		;check if at end of array
	  BNE again
;set all entries of first TimeBuffer to 0xFFFFFFFF
	  MOV R0, #0x00
	  MOV R1, #0xFFFFFFFF
	  LDR R2, =TimeBuffer
again2 STR R1, [R2,R0]
	  ADD R0, R0, #4
	  CMP R0, #400		;check if at end of array
	  BNE again2
	  
;initialize 2 pointers at beginnig of each buffer
	  LDR R1, =DataBuffer
	  LDR R0, =DataPt
	  STR R1, [R0]	;DataPt points to DataBuffer[0]
	  
	  LDR R1, =TimeBuffer
	  LDR R0, =TimePt
	  STR R1, [R0] 	;TimePt points to TimeBuffer[0]
	  
;active the SysTick timer
	  BL SysTick_Init
	  
;read 1st time
	  LDR R0, =NVIC_ST_CURRENT_R
	  LDR R1, [R0]
	  LDR R2, =TimeBefore
	  STR R1, [R2]		;arbitary 1st clock read
      POP {R0-R4,PC}
	  
	  
;Debug capture      
Debug_Capture 			;#instruc debug caputure = 36
		PUSH {R0-R6,LR}
; you write this
;save all registers used
;***return immediately if the buffers are full
		LDR R0, =DataBuffer	;starting array address
		ADD R0, R0, #100	;end array address
		LDR R1, =DataPt
		LDR R2, [R1]		;DataPt location
		CMP R0, R2			;check if DataBuffer full
		BEQ done
;read port A and E and the SysTick timer
		LDR R0, =GPIO_PORTA_DATA_R
		LDR R1, [R0]		;PortA read
		LDR R2, =GPIO_PORTE_DATA_R
		LDR R3, [R2]		;PortE read
		LDR R4, =NVIC_ST_CURRENT_R 
		LDR R5, [R4]		;SysTick read = R5

;mask, combining just bits PA4, PE3, PE2, PE1, PE0 into one 8-bit value
		AND R0,R1, #0x10	;isloate PA4
		AND R2,R3, #0x0F	;isolate PE3-PE0
		ORR R0,R0,R2		;R0 = comb 8 bit val
;dump data into DataBuffer using DataPt
		LDR R1, =DataPt
		LDR R2, [R1]		;array pointer
		STRB R0, [R2]	
;incr DataPt to next address
		ADD R2, R2, #1
		STR R2, [R1] 
;calc 24-bit elaspsed time
		LDR R0, =TimeBefore
		LDR R1, [R0]		;loop before clock read
		SUB R6, R1, R5		;prev time - current time (R5)
		AND R6, R6, #0x00FFFFFF	;R6 = elapsed time
		STR R5, [R0]		;storing current time for next loop
;dump elapsed time into TimeBuffer using TimePt
		LDR R1, =TimePt
		LDR R2, [R1]
		STR R6, [R2]
;incr TimePt to next address
		ADD R2, R2, #4
		STR R2, [R1]
;restore registers
done	POP  {R0-R6,PC}
		
	  
;INTRUSIVENESS ESTIMATE - Debug_Capture RUN
	;TOTAL INSTRUCTIONS = 36 
	;TOTAL CYCLES = 36 * 2 = 72
	;TOTAL TIME = 72 * 12.5ns = 900 ns
;INTRUSIVENESS ESTIMATE - TIME BETWEEN CALLS
	;TOTAL INSTRUCTIONS = est. 3200021
	;TOTAL CYCLES = 3200021 * 2 = 6400042
	;TOTAL TIME = 6400042 * 12.5 ns = 80000525 ns
	
;PERCENT OVERHEAD
	;900 ns / 80000525 ns = 0.00001125 = 0.00112%
	
Heartbeat					;#instruc heartbeat = 8
	;get PF2 data
	;flash continuously?
	PUSH {R0-R3}

	LDR R1,=GPIO_PORTF_DATA_R
	LDR R0,[R1]
	AND R0,R0, #0x04
	EOR R0,R0,#0x04
	STR R0,[R1]
	
	POP {R0-R3}
	BX	LR
	
	;# instruc below this =    9  
; edit the following only if you need to move pins from PA4, PE3-0      
; logic analyzer on the real board
PA4  equ  0x40004040   ; bit-specific addressing
PE30 equ  0x4002403C   ; bit-specific addressing
UART0_DR_R equ 0x4000C000 ;write to this to send data
SendDataToLogicAnalyzer
     LDR  R1,=PA4  
     LDR  R1,[R1]  ; read PA4
     LDR  R0,=PE30 ; read PE3-PE0
     LDR  R0,[R0]
     ORR  R0,R0,R1 ;combine into one 5-bit value
     ORR  R0,R0,#0x80 ;bit7=1 means digital data
     LDR  R1,=UART0_DR_R
     STR  R0,[R1] ; send data at 10 kHz
     BX   LR


     ALIGN    ; make sure the end of this section is aligned
     END      ; end of file

