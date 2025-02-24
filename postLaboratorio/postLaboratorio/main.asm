;
; postLaboratorio.asm
;
; Created: 24/2/2025 17:48:38
; Author : yelen
;


; Replace with your application code
.include "M328PDEF.inc"
.DEF	DISPLAY=R21 
.ORG	0x0000
	RJMP	SETUP	//Vector Reset

.ORG	PCI1addr
	RJMP	PCINT_ISR	//vector de interrupción PCINT1
.ORG	0x0020
	RJMP	INTERRUP_TIMER
		
.cseg
.def CONTADOR= R19	//variable para almacenar el contador
//Stack
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16

//Inicio del programa
SETUP:
	//Configurar Prescaler "Principal"
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16 // Habilitar cambio de PRESCALER
	LDI		R16, 0b00000100
	STS		CLKPR, R16 // Configurar Prescaler a 16 F_cpu = 1MHz
	// Inicializar timer0
	CALL	INIT_TMR0

	;PORTC COMO ENTRADA CON PULL-UP HABILIDATO 
	LDI		R16, 0x00
	OUT		DDRC, R16
	LDI		R16, 0xFF
	OUT		PORTC, R16

	;PORTB COMO SALIDA Inicialmente apagado
	LDI		R16, 0xFF
	OUT		DDRB,R16
	LDI		R16, 0x00
	OUT		PORTB, R16

	;PORTD COMO SALIDA Inicialmente apagado
	LDI		R16, 0xFF
	OUT		DDRD,R16
	LDI		R16, 0x00
	OUT		PORTD, R16

	// Deshabilitar serial (esto apaga los dem s LEDs del Arduino)
	LDI R16, 0x00
	STS UCSR0B, R16

	//Iniciar el display en 0s
	LDI		DISPLAY, 0x00	//Iniciar en 0
	CALL	ACTUALIZAR_DISPLAY	

	//configuración de interrupciones pin change
	LDI		R16,	(1 << PCIE1)			//Encender el bit PCIE1
	STS		PCICR,	R16				//Habilitar el PCI en el pin C
	LDI		R16,	(1<<PCINT8) | (1<<PCINT9)	//Habilitar pin 0 y pin 1
	STS		PCMSK1,	R16				//	Cargar a PCMSK1

	//configuración de interrupciones por desboradamiento
	LDI R16, (1 << TOIE0)	//Habilita interrupciones Timer0
	STS TIMSK0, R16


	SEI              ; Habilita interrupciones globales

	LDI R17, 0x00         ; Inicializar contador en 0

   
MAIN: 	
	RJMP	MAIN

//========================================================
//RUTINA DE INTERRUPCIÓN
//========================================================
PCINT_ISR:
	IN		R18, PINC	//Lee el estado actual de los pines
	SBRS	R18,0	//Si el bit 0 está en alto, incrementar
	CALL	INCREMENTAR
	SBRS	R18,1		//Si el bit 1 está en algo, decrementar
	CALL	DECREMENTAR
	RETI	//Retornar a la interrupción

//SUBRUTINAS
INCREMENTAR:
	INC		CONTADOR
	CPI		CONTADOR, 0x10	//Si llega a 16 reiniciar a 0
	BRNE	NO_RESET
	LDI		CONTADOR, 0x00

NO_RESET:
	OUT		PORTB, CONTADOR
	RET

DECREMENTAR:
	CPI		CONTADOR,0x00	//Comparar si es 0
	BREQ	NO_DECREMENTA
	DEC		CONTADOR	//Decrementar
NO_DECREMENTA:
	OUT	PORTB, CONTADOR
	RET

INIT_TMR0:
	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16 // Setear prescaler del TIMER 0 a 64
	LDI		R16, 100
	OUT		TCNT0, R16 // Cargar valor inicial en TCNT0
	RET

ACTUALIZAR_DISPLAY:
	LDI     ZH, HIGH(TABLA<<1)
    LDI     ZL, LOW(TABLA<<1)
	ADD		ZL, DISPLAY
	LPM		R23, Z
	OUT		PORTD, R23
	RET

INTERRUP_TIMER:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	INC		R22 
	CPI		R22, 100
	BRNE	SALIR_ISR_TMR
	CLR		R22
	
	INC		DISPLAY
	CPI		DISPLAY, 0x0A
	BRNE	SALIR_ISR_TMR
	LDI		DISPLAY, 0x00
SALIR_ISR_TMR:
	CALL	ACTUALIZAR_DISPLAY
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI

TABLA:
    .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67





