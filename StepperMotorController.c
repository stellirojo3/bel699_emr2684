// StepperMotorController.c starter file EE319K Lab 5
// Runs on TM4C123
// Finite state machine to operate a stepper motor.  
// Jonathan Valvano
// September 2, 2019

// Hardware connections (External: two input buttons and four outputs to stepper motor)
//  PA5 is Wash input  (1 means pressed, 0 means not pressed)
//  PA4 is Wiper input  (1 means pressed, 0 means not pressed)
//  PE5 is Water pump output (toggle means washing)
//  PE4-0 are stepper motor outputs 
//  PF1 PF2 or PF3 control the LED on Launchpad used as a heartbeat
//  PB6 is LED output (1 activates external LED on protoboard)

#include "SysTick.h"
#include "TExaS.h"
#include <stdint.h>
#include "../inc/tm4c123gh6pm.h"

#define SYSCTL_RCGCGPIO_R       	(*((volatile uint32_t *)0x400FE608))
#define GPIO_PORTE_AMSEL_R        (*((volatile uint32_t *)0x40024528))
#define GPIO_PORTE_PCTL_R        	(*((volatile uint32_t *)0x4002452C))
#define GPIO_PORTE_DIR_R        	(*((volatile uint32_t *)0x40024400))
#define GPIO_PORTE_AFSEL_R        (*((volatile uint32_t *)0x40024420))
#define GPIO_PORTE_DEN_R        	(*((volatile uint32_t *)0x4002451C))

#define GPIO_PORTA_AMSEL_R        (*((volatile uint32_t *)0x40004528))
#define GPIO_PORTA_PCTL_R        	(*((volatile uint32_t *)0x4000452C))
#define GPIO_PORTA_DIR_R        	(*((volatile uint32_t *)0x40004400))
#define GPIO_PORTA_AFSEL_R        (*((volatile uint32_t *)0x40004420))
#define GPIO_PORTA_DEN_R        	(*((volatile uint32_t *)0x4000451C))

void EnableInterrupts(void);
// edit the following only if you need to move pins from PA4, PE3-0      
// logic analyzer on the real board
#define PA54       (*((volatile unsigned long *)0x400040C0))	//bit 5 const = 0x0080, bit 4 const = 0x0040 --> PA54 = 0x00C0 + 0x4000.4000 = 0x400040C0
#define PE50      (*((volatile unsigned long *)0x400240FC))

//linked data structure
struct State{
		uint32_t Out; 	//PE5-0: LED + stepper output
		uint32_t Time;	//wait * 10 ms
		uint32_t Next[4];};	//where does it go for 00, 01, 10, 11
	typedef const struct State State_t;
//Home
	#define	Home	0
		
//Clean/Wash - Wipe + LED			
	#define	CF1		1
	#define	CF2		2
	#define	CF4		3
	#define	CF8		4
	#define	CF16	5
	#define	CF11	6
	#define	CF12	7
	#define	CF14	8
	#define	CF18	9
	#define	CF116	10
	#define	CB18	11
	#define	CB14	12
	#define	CB12	13
	#define	CB11	14
	#define	CB16	15
	#define	CB8		16
	#define	CB4		17
	#define	CB2		18
	#define	CB1		19
	
//Wipe			
	#define	WF1		20
	#define	WF2		21
	#define	WF4		22
	#define	WF8		23
	#define	WF16	24
	#define	WF11	25
	#define	WF12	26
	#define	WF14	27
	#define	WF18	28
	#define	WF116	29
	#define	WB18	30
	#define	WB14	31
	#define	WB12	32
	#define	WB11	33
	#define	WB16	34
	#define	WB8		35
	#define	WB4		36
	#define	WB2		37
	#define	WB1		38
	
State_t FSM[39] = {
//Home
{0x00	,	5	,{Home	,WF1	,CF1	,CF1}},

//Clean/Wash - Wipe + LED													
{0x21	,	5	,{WF2,	WF2,	CF2,	CF2}},
{0x02	,	5	,{WF4,	WF4,	CF4,	CF4}},
{0x24	,	5	,{WF8,	WF8,	CF8,	CF8}},
{0x08	,	5	,{WF16,	WF16,	CF16,	CF16}},
{0x30	,	5	,{WF11,	WF11,	CF11,	CF11}},
{0x01	,	5	,{WF12,	WF12,	CF12,	CF12}},
{0x22	,	5	,{WF14,	WF14,	CF14,	CF14}},
{0x04	,	5	,{WF18,	WF18,	CF18,	CF18}},
{0x28	,	5	,{WF116, WF116,	CF116, CF116}},
{0x10	,	5	,{WB18,	WB18,	CB18,	CB18}},
{0x28	,	5	,{WB14,	WB14,	CB14,	CB14}},
{0x04	,	5	,{WB12,	WB12,	CB12,	CB12}},
{0x22	,	5	,{WB11,	WB11,	CB11,	CB11}},
{0x01	,	5	,{WB16,	WB16,	CB16,	CB16}},
{0x30	,	5	,{WB8,	WB8,	CB8,	CB8}},
{0x08	,	5	,{WB4,	WB4,	CB4,	CB4}},
{0x24	,	5	,{WB2,	WB2,	CB2,	CB2}},
{0x02	,	5	,{WB1,	WB1,	CB1,	CB1}},
{0x21	,	5	,{Home,	Home,	Home,	Home}},

//Wipe												
{0x01	,	5	,{WF2,	WF2,	CF2,	CF2	}},
{0x02	,	5	,{WF4,	WF4,	CF4,	CF4	}},
{0x04	,	5	,{WF8,	WF8,	CF8,	CF8	}},
{0x08	,	5	,{WF16,	WF16,	CF16,	CF16}},
{0x10	,	5	,{WF11,	WF11,	CF11,	CF11}},
{0x01	,	5	,{WF12,	WF12,	CF12,	CF12}},
{0x02	,	5	,{WF14,	WF14,	CF14,	CF14}},
{0x04	,	5	,{WF18,	WF18,	CF18,	CF18}},
{0x08	,	5	,{WF116, WF116, CF116, CF116}},
{0x10	,	5	,{WB18,	WB18,	CB18,	CB18}},
{0x08	,	5	,{WB14,	WB14,	CB14,	CB14}},
{0x04	,	5	,{WB12,	WB12,	CB12,	CB12}},
{0x02	,	5	,{WB11,	WB11,	CB11,	CB11}},
{0x01	,	5	,{WB16,	WB16,	CB16,	CB16}},
{0x10	,	5	,{WB8,	WB8,	CB8,	CB8}},
{0x08	,	5	,{WB4,	WB4,	CB4,	CB4}},
{0x04	,	5	,{WB2,	WB2,	CB2,	CB2}},
{0x02	,	5	,{WB1,	WB1,	CB1,	CB1}},
{0x01	,	5	,{Home,	Home,	Home,	Home}}};

uint32_t S;	//index to current state
uint32_t Input;


void SendDataToLogicAnalyzer(void){
  UART0_DR_R = 0x80|(PA54<<2)|PE50;
}

int main(void){ 
  TExaS_Init(&SendDataToLogicAnalyzer);    // activate logic analyzer and set system clock to 80 MHz
  SysTick_Init();   
// you initialize your system here
	SYSCTL_RCGCGPIO_R |= 0x11;							//turn on PortA and PortE clock
	while((SYSCTL_RCGCGPIO_R & 0x11)==0){		//clock stabilization
	}
	GPIO_PORTE_AMSEL_R &= ~0x3F;						//disable analog function on PE5 through PE0
	GPIO_PORTE_DIR_R |= 0x3F;								//set output: PE5, PE4, PE3, PE2, PE1, PE0
	GPIO_PORTE_DEN_R |= 0x3F;								//enable outputs
	
	GPIO_PORTA_DIR_R &= ~0x30;								// 5) set input: PA5, PA4
	GPIO_PORTA_AFSEL_R &= ~0x30;							// 6) regular function on PA5 and PA4, why doe we use this?
	GPIO_PORTA_DEN_R |= 0x30;									// 7) enable inputs

	S = Home;

  EnableInterrupts();   
  while(1){
// output
		PE50 = FSM[S].Out;							//LED + stepper motor
// wait
		SysTick_Wait10ms(FSM[S].Time);	//5*10 ms = 50 ms
// input
		Input = PA54>>4;							//either 00, 01, 10, 11
// next		
		S = FSM[S].Next[Input];
  }
}


