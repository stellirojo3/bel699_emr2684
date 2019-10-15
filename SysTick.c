// SysTick.c
// Runs on TM4C123
// Provide functions that initialize the SysTick module
// Put your name here

// October 5, 2018

/* This example accompanies the book
   "Embedded Systems: Real Time Interfacing to Arm Cortex M Microcontrollers",
   ISBN: 978-1463590154, Jonathan Valvano, copyright (c) 2018
   Program 2.11, Section 2.6

 Copyright 2018 by Jonathan W. Valvano, valvano@mail.utexas.edu
    You may use, edit, run or distribute this file
    as long as the above copyright notice remains
 THIS SOFTWARE IS PROVIDED "AS IS".  NO WARRANTIES, WHETHER EXPRESS, IMPLIED
 OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE.
 VALVANO SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL,
 OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
 For more information about my classes, my research, and my books, see
 http://users.ece.utexas.edu/~valvano/
 */
#include <stdint.h>

// Initialize SysTick with busy wait running at bus clock.
#define NVIC_ST_CTRL_R      (*((volatile unsigned long *)0xE000E010))
#define NVIC_ST_RELOAD_R    (*((volatile unsigned long *)0xE000E014))
#define NVIC_ST_CURRENT_R   (*((volatile unsigned long *)0xE000E018))
void SysTick_Init(void){
	// write this
	NVIC_ST_CTRL_R  = 0;						//disable SysTick during setup - stock counter
	NVIC_ST_RELOAD_R = 0x00FFFFFF;	//set reload to max reload value
	NVIC_ST_CURRENT_R = 0;					//any write to current clear it
	NVIC_ST_CTRL_R = 0x00000005;		//enable SysTick with core clock
}
// The delay parameter is in units of the 80 MHz core clock. (12.5 ns)
void SysTick_Wait(uint32_t delay){
	// write this
	NVIC_ST_RELOAD_R = delay - 1;		//number of counts to wiat
	NVIC_ST_CURRENT_R = 0;					//any write to current clear it
	while((NVIC_ST_CTRL_R & 0x00010000) == 0){		//wait for count flag
	}
}
// The delay parameter is in ms.
// 80000 bus cycles equals 1ms
void SysTick_Wait1ms(uint32_t delay){
	// write this
	uint32_t i;
	for(i = 0; i < delay; i++){
		SysTick_Wait(80000);					//wait 1 ms
	}
}

// 800000 bus cycles equals 10ms
void SysTick_Wait10ms(unsigned long delay){
	// write this
	uint32_t j;
	for(j = 0; j < delay; j++){
		SysTick_Wait(800000);					//wait 10 ms
	}
}

