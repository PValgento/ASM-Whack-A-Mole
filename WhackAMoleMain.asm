;Patrick Valgento
;Whack-A-LED

; =========================
; PROGRAMMER NOTES/COMMENTS
; =========================
 
	;LED PORTS (A, B, C, D): 	RB4, RC2, RC1, RC0 
 
	;SWITCH PORTS (1, 2, 3, 4): 	RA5, RA4, RC4, RC5 
 
	;RGB LED (RED, GREEN, BLUE): 	RA0, RA1, RA2 	   
 
	;Switches are HIGH when unpressed, become LOW when pressed
 
	;DELAY 			- 	During game, checks for input and updates score.
	;DELAY_NOT_RUNNING 	- 	Not during game, checks for input but doesn't update score
	;DELAY_BASIC		-	For after a button is pressed, ignores all input so multiple inputs are not accidentally recorded for a single instance

;========================
; USER NOTES/INSTRUCTIONS
; =======================

	;   A      B      C      D
	;----------------------------
	;|  O  ||  O  ||  O  ||  O  |		<====   LEDS
	;----------------------------
 
 
 
	;   1      2      3      4
	;----------------------------
	;|  O  ||  O  ||  O  ||  O  |		<====	BUTTONS
	;----------------------------
 
	;When the program begins, the RGB will shine white
	
	;This is the main menu, your options are (1 - Easy, 2 - Medium, 3 - Hard, 4 - Randomize)
	;For option 4, please hold the switch until you feel it's random enough (rbg will be purple to indicate randomizing)
	
	;Once you choose a difficulty, the white rgb will go off and you will see the regular leds go on
	;Once any button is pressed, they will count down until they're all off, then the game has started
	
	;There will be 16 chances to hit an LED, then the game will end and your score will be displayed
	
	;Hits are 2 points
	
	;Misses deduct 1 point
 
	;When you're done looking at your score, press any button to reset the game state to being ready to begin as when you first started

;=======================
; INITIAL CONFIGURATION 
;=======================

#include "p16F1708.inc"

; CONFIG1
; __config 0x3FE4
 __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_ON & _FCMEN_ON
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _WRT_OFF & _PPS1WAY_ON & _ZCDDIS_ON & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_ON 
 

;==============================
;DATA and Variable Declarations
;==============================

 cblock 	0x20 
 
 difficulty
 rand
 toxorl
 toxorm
 counter1
 counter2
 maincounter
 countcycles
 score
 total
 
 endc

 ;====================
 ;MAIN PROGRAM MEMORY
 ;====================
  
 org	0x0000
 
;Initializing Switches and LEDs

;		Setting the microprocesser clock frequency
 banksel OSCCON
 movlw b'0101110'
 movwf OSCCON

;		Setting the analog selects
 banksel ANSELA
 clrf	ANSELA
 banksel ANSELB
 clrf	ANSELB
 banksel ANSELC
 clrf	ANSELC

;		Setting the tristate selects (clear the led ports, set the switch ports)
 banksel TRISA
 clrf TRISA
 bsf TRISA, 5
 bsf TRISA, 4
 banksel TRISB
 clrf TRISB
 banksel TRISC
 clrf TRISC
 bsf TRISC, 5
 bsf TRISC, 4
 
;		Initially clearing variables
 movlb 0
 clrf difficulty
 clrf rand
 clrf toxorl
 clrf toxorm
 clrf counter1
 clrf counter2
 clrf maincounter
 clrf countcycles
 clrf score
 clrf total
 bsf rand,0
 call CLEAR_ALL		;Turns off all LEDs

;=========================
;Main Program Loop Begins
;=========================

MAINMENU

 ;		Make RGB white
 bsf PORTA, 0
 bsf PORTA, 1
 bsf PORTA, 2
 
 ;		Check for button press if any button port is not set
 clrf difficulty
 btfss PORTA, 5 ; Easy mode
 call EASY
 btfss PORTA, 4 ; Medium mode
 call MEDIUM
 btfss PORTC, 4 ; Hard Mode
 call HARD
 btfss PORTC, 5 ; Randomize
 call WAIT_FOR_OFF
 
 ;		If no difficulty was selected, go to main menu and continue to wait for selection
 btfss difficulty, 0
 goto MAINMENU
		
;		Turn off all LEDs
 call CLEAR_ALL
 
;		Turns on all four regular LEDs
 bsf PORTB, 4
 bsf PORTC, 2
 bsf PORTC, 1
 bsf PORTC, 0
 
;		Waits for button input to begin the game
 call WAIT_FOR_ON

;		Turns off the leds one by one to mark the beginning of the game.
 movlw d'40'
 movwf counter2
 call DELAY_BASIC
 movwf counter2
 bcf PORTB, 4
 call DELAY_BASIC
 movwf counter2
 bcf PORTC, 2
 call DELAY_BASIC
 movwf counter2
 bcf PORTC, 1
 call DELAY_BASIC
 movwf counter2
 bcf PORTC, 0
 movlw d'100'
 movwf counter2
 call DELAY_BASIC
 
MAINLOOP

;		Determines which LED will go on based on random number algorithm
 btfsc rand, 4		
 call LOW_ON
 btfss rand, 4
 call HIGH_ON
 
;		Sets the delay for how long the led will stay on
 movfw difficulty	
 movwf counter2
 call DELAY

;		Turns off led and grants grace period so player does not "miss" if they don't let go immediately when led goes off.
 call CLEAR_ALL		
 movlw d'8'
 movwf counter2
 call DELAY_BASIC
;		Delays for the remainder of the time before led goes off. User will lose points pressing something at this point to avoid pre-emptive holding down of a button.
 movlw d'70'
 movwf counter2
 call DELAY
 
;		Updates the random number
 call ALGORITHM		
		
;		Updates total amount of times a light has shown up, checks whether the game is over
 incf total		
 btfsc total, 4;		   If total hits 16 
 goto GAME_OVER
	
;		Returns to the beginning of the loop
 goto MAINLOOP		
 
;=======================================
;Subroutines to support the main program
;=======================================

;	-------------------------------
;	Random LED Selector Subroutines
;	-------------------------------
LOW_ON
 btfsc rand, 3
 goto LB_ON
 goto LB_OFF
 
LB_ON
 bsf PORTC, 0
 return
 
LB_OFF
 bsf PORTC, 1
 return 
 
HIGH_ON
 btfsc rand, 3
 goto HB_ON
 goto HB_OFF
 
HB_ON
 bsf PORTC, 2
 return
 
HB_OFF
 bsf PORTB, 4
 return
 
;	-------------------------------
;	Waiting for Input from the user 
;	-------------------------------

;		Waits until it detects a button input, then returns to where it left off
WAIT_FOR_ON
 call ALGORITHM
 btfss PORTA, 5
 return 
 btfss PORTA, 4
 return
 btfss PORTC, 4
 return
 btfss PORTC, 5
 return
 goto WAIT_FOR_ON

;		Waits until user lets go of the button (button 4), randomizing while it waits
WAIT_FOR_OFF
 bcf PORTA, 1
 call ALGORITHM
 bsf PORTA, 1
 btfsc PORTC, 5
 return
 goto WAIT_FOR_OFF
 
;	-------------------------------
;	      Clearing all LEDs 
;	-------------------------------

;		Turns off all LEDs and returns where it left off
CLEAR_ALL
 bcf PORTB, 4
 bcf PORTC, 2
 bcf PORTC, 1
 bcf PORTC, 0
 bcf PORTA, 0
 bcf PORTA, 1
 bcf PORTA, 2 
 return
 
;	-------------------------------
;	    Random Number Generation
;	-------------------------------

;		Updates random number, then returns where it left off
ALGORITHM
 clrf toxorl
 clrf toxorm
 btfsc rand, 0
 bsf toxorl, 0
 btfsc rand, 7
 bsf toxorm, 0 
 movf toxorm,0
 xorwf toxorl, 0
 lslf rand, 1
 addwf rand, 1
 return

;	-------------------------------
;	     Button Press Analysis
;	-------------------------------
;		Subroutines for when the buttons are pressed while the game is running

PRESS1
 btfsc PORTB, 4
 goto HIT
 btfss PORTB, 4
 goto MISS
 return
 
PRESS2
 btfsc PORTC, 2
 goto HIT
 btfss PORTC, 2
 goto MISS
 return
 
PRESS3
 btfsc PORTC, 1
 goto HIT
 btfss PORTC, 1
 goto MISS
 return
 
PRESS4
 btfsc PORTC, 0
 goto HIT
 btfss PORTC, 0
 goto MISS
 return
 
;		Small subroutine for when the program is in the point score state
PRESS_0		
 call CLEAR_ALL
 movlw d'10'
 movwf counter2
 call DELAY_BASIC
 goto MAINMENU
 
;	-------------------------------
;	     User Hit/Miss Handling
;	-------------------------------

;		Subroutine for a successful hit. Updates score and indicates a hit with a green led
HIT
 incf score, 1
 incf score, 1
 bsf PORTA, 1
 call DELAY_BASIC
 bcf PORTA, 1
 return

;		Subroutine for an unsuccessful hit. Updates score and indicates a miss with a red led
MISS
 decfsz score, 1
 btfsc score, 7 
 incf score, 1 
 bsf PORTA, 0
 call DELAY_BASIC
 bcf PORTA, 0
 return
	
;	-------------------------------
;	     End Game Handling
;	-------------------------------

;		Subroutine for when the game has ended. Will handle score displaying then will wait for an input to go begin the game again
GAME_OVER
 call CLEAR_ALL
 bsf PORTA, 2
 movlw d'70'
 movwf counter2
 call DELAY_BASIC
 bcf PORTA, 2
 btfsc score, 5
 goto PERFECT
 btfsc score, 0
 bsf PORTA, 0
 btfsc score, 1
 bsf PORTC, 0
 btfsc score, 2
 bsf PORTC, 1
 btfsc score, 3
 bsf PORTC, 2
 btfsc score, 4
 bsf PORTB, 4
 clrf score
 clrf total
 call WAIT_FOR_ON
 call CLEAR_ALL
 movlw d'5'
 movwf counter2
 call DELAY_BASIC
 goto MAINMENU

;		Subroutine for a perfect score, flashes green light until the user presses a button to cancel the lighting and go back to the state ready to start again
PERFECT
 clrf score
 clrf total
 bsf PORTA, 1
 movlw d'10'
 movwf counter2
 call DELAY_NOT_RUNNING
 bcf PORTA, 1
 movlw d'10'
 movwf counter2
 call DELAY_NOT_RUNNING
 goto PERFECT

;	------------------------------- 
;	    Difficulty Subprograms
;	-------------------------------

EASY
 movlw d'29'
 movwf difficulty
 return
MEDIUM
 movlw d'21'
 movwf difficulty
 return
HARD
 movlw d'13'
 movwf difficulty
 return
;	-------------------------------
;       Time Management & Delays
;	-------------------------------

;		Delay when the game isn't running, it takes any button and once pressed it resets to the original state of the program, where it waits for a button press to start the game
DELAY_NOT_RUNNING
 decfsz counter1, 1
 goto DELAY_NOT_RUNNING
 btfss PORTA, 5
 call PRESS_0
 btfss PORTA, 4
 call PRESS_0
 btfss PORTC, 4
 call PRESS_0
 btfss PORTC, 5
 call PRESS_0
 decfsz counter2, 1
 goto DELAY_NOT_RUNNING
 return

;		Delay while the game is running, checks for switch input and cross-checks with led to see if it's a hit or not
DELAY
 decfsz counter1, 1
 goto DELAY
 btfss PORTA, 5
 goto PRESS1
 btfss PORTA, 4
 goto PRESS2
 btfss PORTC, 4
 goto PRESS3
 btfss PORTC, 5
 goto PRESS4 
 decfsz counter2, 1
 goto DELAY
 return

;		Delay that purposely delays the acceptation of any more input in a very small amount of time to avoid multiple inputs
DELAY_BASIC
 decfsz counter1, 1
 goto DELAY_BASIC
 decfsz counter2, 1
 goto DELAY_BASIC
 return

 end 
