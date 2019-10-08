; SysTick.s
; Module written by: **-UUU-*Your Names**update this***
; Date Created: 2/14/2017
; Last Modified: 9/2/2019 
; Brief Description: Initializes SysTick

NVIC_ST_CTRL_R        EQU 0xE000E010
NVIC_ST_RELOAD_R      EQU 0xE000E014
NVIC_ST_CURRENT_R     EQU 0xE000E018
NVIC_ST_CTRL_CLK_SRC  EQU 0x00000004  ; Clock Source
NVIC_ST_CTRL_ENABLE   EQU 0x00000001  ; Counter mode
NVIC_ST_RELOAD_M      EQU 0x00FFFFFF  ; Counter load value

        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
; -UUU- You add code here to export your routine(s) from SysTick.s to main.s
        EXPORT SysTick_Init
;------------SysTick_Init------------
; ;-UUU-Complete this subroutine
; Initialize SysTick running at bus clock.
; Make it so NVIC_ST_CURRENT_R can be used as a 24-bit time
; Input: none
; Output: none
; Modifies: ??
SysTick_Init
 ; **-UUU-**Implement this function****
 ;disable SysTick during setup
    LDR R1, =NVIC_ST_CTRL_R         ; 
    MOV R0, #0                      ; clear enable - stops counter
    STR R0, [R1]                    ; [R1] = R0 = 0
 ; set reload to maximum reload value
    LDR R1, =NVIC_ST_RELOAD_R       ; 
    LDR R0, =NVIC_ST_RELOAD_M;      ; 
    STR R0, [R1]                    ; store 0x00FFFFFF into reload
 ; any write to current clears it
    LDR R1, =NVIC_ST_CURRENT_R      ; R1 = &NVIC_ST_CURRENT_R
    MOV R0, #0                      ; R0 = 0
    STR R0, [R1]                    ; [R1] = R0 = 0
 ; enable SysTick with core clock
    LDR R1, =NVIC_ST_CTRL_R         ; 
                                    ; R0 = ENABLE and CLK_SRC bits set
    MOV R0, #0x05					; enable but no interrupts (clk_src = 1 (bus), inten = 0, enable = 1)
    STR R0, [R1]                    ; 
    BX  LR                          ; return


    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file
