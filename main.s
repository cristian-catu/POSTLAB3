; Archivo: main.S
; Dispositivo: PIC16F887
; Autor: Cristian Catú
; Compilador: pic-as (v.30), MPLABX V5.40
;
; Programa: Sumador de 4 bits
; Hardware: Botones y timer0
;
; Creado: 2 de feb, 2022
; Última modificación: 2 de feb, 2022

PROCESSOR 16F887
;----------------- bits de configuración --------------------
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  // config statements should precede project file includes.
#include <xc.inc>

PSECT udata_bank0 ;common memory
  contador: DS 1 ;1byte
    
PSECT resVect, class=CODE, abs, delta=2
; ----------------vector reset-----------------
ORG 00h ;posición 0000h para el reset
resetVec:
    PAGESEL main
    goto main
PSECT code, delta=2, abs
ORG 100h ;posición para el código
tabla:
    CLRF    PCLATH		; Limpiamos registro PCLATH
    BSF	    PCLATH, 0		; Posicionamos el PC en dirección 01xxh
    ANDLW   0x0F		; no saltar más del tamaño de la tabla
    ADDWF   PCL			; Apuntamos el PC a caracter en ASCII de CONT
    RETLW   00111111B			; ASCII char 0
    RETLW   00000110B			; ASCII char 1
    RETLW   01011011B			; ASCII char 2
    RETLW   01001111B			; ASCII char 3
    RETLW   01100110B           	; ASCII char 4
    RETLW   01101101B			; ASCII char 5
    RETLW   01111101B			; ASCII char 6
    RETLW   00000111B			; ASCII char 7
    RETLW   01111111B			; ASCII char 0
    RETLW   01101111B	                ; ASCII char 1
    RETLW   01110111B			; ASCII char 2
    RETLW   01111100B			; ASCII char 3
    RETLW   00111001B			; ASCII char 4
    RETLW   01011110B			; ASCII char 5
    RETLW   01111001B			; ASCII char 6
    RETLW   01110001B			; ASCII char 7
; ---------------- configuración ------------------
main:
    call CONFIG_IO
    call CONFIG_RELOJ
    call CONFIG_TMR0

    ;-------------- loop principal ---------------
LOOP:
    BTFSS RA0	    ; RA0=0 llama a checkboton, RA0=1 evalua otro bit
    CALL CHECKBOTON
    BTFSS RA1	    ; RA1=0 llama a checkboton2, RA1=1 evaluar otro bit
    CALL CHECKBOTON2
    
LOOP2:
    BTFSS   T0IF	    ; Verificamos interrupción del TMR0
    GOTO    LOOP
    CALL RESET_TMR0
    MOVF contador, W
    XORWF PORTD, W
    BTFSC STATUS, 2
    call es_igual
    INCF PORTD, F
    GOTO LOOP2
    
 
;---------------- subrutinas -------------------
CONFIG_IO:
    BSF	STATUS, 5   ; banco 01
    BSF STATUS, 6   ; banco 11
    CLRF ANSEL	    ; I/O del puerto A digitales
    CLRF ANSELH
    
    BCF STATUS, 6   ; banco 01
    BSF TRISA, 0    ; 2 bits del PORTA como entradas
    BSF TRISA, 1 
    BANKSEL TRISB
    BCF TRISB, 0
    
    CLRF TRISC
    BCF TRISD, 0
    BCF TRISD, 1
    BCF TRISD, 2
    BCF TRISD, 3
    
    BANKSEL PORTC
    CLRF PORTC      ; apagamos PORTC
    CLRF PORTD
    CLRF PORTB
    RETURN
    
CONFIG_RELOJ:
    BANKSEL OSCCON	    ; cambiamos a banco 1
    BSF	    OSCCON, 0	    ; SCS -> 1, Usamos reloj interno
    BCF	    OSCCON, 6
    BCF	    OSCCON, 5
    BSF	    OSCCON, 4	    ; IRCF<2:0> -> 001 125kHz
    return
    
CONFIG_TMR0:
    BANKSEL OPTION_REG	    ; cambiamos de banco
    BCF	    T0CS	    ; TMR0 como temporizador
    BCF	    PSA		    ; prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BSF	    PS0		    ; PS<2:0> -> 111 prescaler 1 : 256
    
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   140
    MOVWF   TMR0	    ; 50ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    return 
es_igual:
    INCF PORTB, F
    CLRF PORTD
    GOTO LOOP2
    
RESET_TMR0:
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   140
    MOVWF   TMR0	    ; 50ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    return
    
CHECKBOTON:
    BTFSS RA0  ; RA0=0 REGRESA, RA0=1 INCREMENTA EL PORTB
    GOTO $-1
    INCF contador   ; incremento de contador
    movf contador, W
    call tabla
    movwf PORTC
    RETURN
   
CHECKBOTON2:
    BTFSS RA1  ; RA1=0 REGRESA, RA0=1 INCREMENTA EL PORTB
    GOTO $-1
    DECF contador   ; incremento de contador
    movf contador, W
    call tabla
    movwf PORTC
    RETURN    
END