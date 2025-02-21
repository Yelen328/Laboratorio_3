;
; Prelaboratorio_3.asm
;
; Created: 20/2/2025 23:58:17
; Author : yelena Cotzojay

.include "M328PDEF.inc"
.cseg
.dseg
CONTADOR: .BYTE 1	//variable para almacenar el contador
.ORG	0x00
	RJMP	RESET	//Vector Reset
.ORG	PCI1addr
	RJMP	PCINT_ISR	//vector de interrupción PCINT1


//Inicio del programa
RESET:
//Stack
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16

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

	//configuración de interrupciones
	LDI		R16,	0X02			//Encender el bit PCIE1
	STS		PCICR,	R16				//Habilitar el PCI en el pin C
	LDI		R16,	(1<<PCINT8) | (1<<PCINT9)	//Habilitar pin 0 y pin 1
	STS		PCMSK1,	R16				//	Cargar a PCMSK1
	SEI              ; Habilita interrupciones globales

	LDI R17, 0x00         ; Inicializar contador en 0
    STS CONTADOR, R17

MAIN:
	LDS		R16, CONTADOR 
	OUT		PORTB, R16
	RJMP	MAIN

//========================================================
//RUTINA DE INTERRUPCIÓN
//========================================================
PCINT_ISR:
	IN		R18, PINC	//Lee el estado actual de los pines
	SBRC	R18,0	//Si el bit 0 está en alto, incrementar
	CALL	INCREMENTAR
	SBRC	R18,1		//Si el bit 1 está en algo, decrementar
	CALL	DECREMENTAR
	RETI	//Retornar a la interrupción

//SUBRUTINAS
INCREMENTAR:
	LDS		R16, CONTADOR
	INC		R16
	CPI		R16, 0x10	//Si llega a 16 reiniciar a 0
	BRLO	NO_RESET
	LDI		R16, 0x00

NO_RESET:
	STS		PORTB, CONTADOR
	RET

DECREMENTAR:
	LDS		R16, CONTADOR
	CPI		CONTADOR,0x00	//Comparar si es 0
	BREQ	NO_DECREMENTA
	DEC		CONTADOR	//Decrementar
NO_DECREMENTA:
	STS	PORTB, CONTADOR
	RET





