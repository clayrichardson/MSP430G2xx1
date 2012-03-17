;*******************************************************************************
;   MSP430G2x31 Demo - ADC10, DTC Sample A1 32x, AVcc, TA0 Trig, DCO
;
;   Description: A1 is sampled in 32x burst using DTC ever 16/second
;   (ACLK/2048) with reference to AVcc. All.  Activity is interrupt driven.
;   Timer_A in upmode uses TA0 toggle to drive ADC10 conversion. Sample burst
;   is automatically triggered by TA0 rising edge every 16 ACLK cycles.
;   ADC10_ISR will exit from LPM3 mode and return CPU active. Internal ADC10OSC
;   times sample (16x) and conversion (13x). DTC transfers conversion code to
;   RAM 200h - 240h. In the Mainloop P1.0 is toggled. Normal Mode is LPM3.
;   //* An external watch crystal on XIN XOUT is required for ACLK *//
;
;                MSP430G2x31
;             -----------------
;         /|\|              XIN|-
;          | |                 | 32kHz
;          --|RST          XOUT|-
;            |                 |
;        >---|P1.1/A1     P1.0 |--> LED
;
;   D. Dang
;   Texas Instruments Inc.
;   October 2010
;   Built with Code Composer Essentials Version: 4.2.0
;*******************************************************************************
 .cdecls C,LIST,  "msp430g2231.h"

;------------------------------------------------------------------------------
            .text                           ; Progam Start
;------------------------------------------------------------------------------
RESET       mov.w   #0280h,SP               ; Initialize stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
SetupADC10  mov.w   #INCH_1+SHS_2+CONSEQ_2,&ADC10CTL1 ; TA0 trigger
            mov.w   #ADC10SHT_2+MSC+ADC10ON+ADC10IE,&ADC10CTL0;
            mov.b   #020h,&ADC10DTC1        ; 32 conversions
SetupP1     bis.b   #001h,&P1DIR            ; P1.0 output
            bis.b   #002h,&ADC10AE0         ; P1.1 ADC10 option select
            mov.w   #1024-1,&TACCR0         ; PWM Period
SetupC0     mov.w   #OUTMOD_4,&TACCTL0      ; TACCR0 toggle
SetupTA     mov.w   #TASSEL_1+MC_1,TACTL    ; ACLK, up mode
                                            ;
Mainloop    bic.w   #ENC,&ADC10CTL0         ;
busy_test   bit     #BUSY,&ADC10CTL1        ; ADC10 core inactive?
            jnz     busy_test               ;
            mov.w   #0200h,&ADC10SA         ; Data buffer start
            bis.w   #ENC,&ADC10CTL0         ; Sampling and conversion ready
            bis.w   #LPM3+GIE,SR            ; LPM3, ADC10_ISR will force exit
            xor.b   #001h,&P1OUT            ; P1.0 = toggle
            jmp     Mainloop                ; Again
                                            ;
;-------------------------------------------------------------------------------
ADC10_ISR;  Exit LPM3 on reti
;-------------------------------------------------------------------------------
            bic.w   #LPM3,0(SP)             ; Exit LPM3 on reti
            reti                            ;
                                            ;
;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET                   ;
            .sect   ".int05"                ; ADC10 Vector
            .short  ADC10_ISR               ;
            .end
