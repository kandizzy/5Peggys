/*
* Copyright 2008 Jay Clegg.  All rights reserved.
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
	Peggy2-i2c interface, Copyright 2008 by Jay Clegg.  All rights reserved.
	
	This code is designed for an unmodified Peggy 2.0 board sold by evilmadscience.com

	The code configures the Peggy as an TWI (I2C) slave.
	
	Companion code for an Arduino allows it to act as an TWI master, so that it can transmit
	frames to the peggy.  
	
	Please see http://www.planetclegg.com/projects/Twi2Peggy.html for explanation of how all
	this is supposed to work.
	
	Credits goes to:
		Windell H Oskay, (http://www.evilmadscientist.com/) 
			for creating the Peggy 2.0 kit, and getting 16 shades of gray working
		Geoff Harrison (http://www.solivant.com/peggy2/), 
			for proving that interrupt driven display on the Peggy 2.0 was viable.
*/




////////////////////////////////////////////////////////////////////////////////////////////
// FPS must be high enough to not have obvious flicker, low enough that main loop has 
// time to process one byte per pass.
// ~140 seems to be about the absolute max for me (with this code on avr-gcc 4.2, -Os), 
// but compiler differences might make this maximum value larger or smaller. 
// if the value is too high errors start to occur or it will stop receiving altogether
// conversely, any lower than 60 and flicker becomes apparent.
// note: further code optimization might allow this number to
// be a bit higher, but only up to a point...  
// it *must* result in a value for OCR0A in the range of 1-255
// #include <Wire.h>

//#define FPS 144
#define FPS 90

// 25 rows * 13 bytes per row == 325
#define DISP_BUFFER_SIZE 325
#define MAX_BRIGHTNESS 15

#define TWI_SLAVE_ID 34
//#define TWI_SLAVE_ID 35
//#define TWI_SLAVE_ID 36
//#define TWI_SLAVE_ID 37
//#define TWI_SLAVE_ID 38


// int x;
// int Source; // who is talking to me
// char String1[20];


////////////////////////////////////////////////////////////////////////////////////////////
uint8_t frameBuffer[DISP_BUFFER_SIZE];

uint8_t *currentRowPtr = frameBuffer;
uint8_t currentRow=0;
uint8_t currentBrightness=0;


// Note: the refresh code has been optimized heavily from the previous version.
SIGNAL(TIMER0_COMPA_vect)
{	
	// there are 15 passes through this interrupt for each row per frame.
	// ( 15 * 25) = 375 times per frame.
	// during those 15 passes, a led can be on or off.
	// if it is off the entire time, the perceived brightness is 0/15
	// if it is on the entire time, the perceived brightness is 15/15
	// giving a total of 16 average brightness levels from fully on to fully off.
	// currentBrightness is a comparison variable, used to determine if a certain
	// pixel is on or off during one of those 15 cycles.   currentBrightnessShifted
	// is the same value left shifted 4 bits:  This is just an optimization for
	// comparing the high-order bytes.
	if (++currentBrightness >= MAX_BRIGHTNESS)  
	{
		currentBrightness=0;
		if (++currentRow > 24)
		{
			currentRow =0;
			currentRowPtr = frameBuffer;
		}
		else
		{
			currentRowPtr += 13;
		}
	}

		
	////////////////////  Parse a row of data and write out the bits via spi
	uint8_t currentBrightnessShifted = currentBrightness <<4;
	
	uint8_t *ptr = currentRowPtr + 12;  // its more convenient to work from right to left
	uint8_t p, bits=0;
	 
	// optimization: by using variables for these two masking constants, we can trick gcc into not 
	// promoting to 16-bit int (constants are 16 bit by default, causing the 
	// comparisons to get promoted to 16bit otherwise)].  This turns out to be a pretty
	// substantial optimization for this handler
	uint8_t himask = 0xf0;  
	uint8_t lomask = 0x0f;
	
	// Opimization: interleave waiting for SPI with other code, so the CPU can do something useful
	// when waiting for each SPI transmission to complete
	
	p = *ptr--;
	if ((p & lomask) > currentBrightness)  			bits|=1;
	SPDR = bits;

	bits=0;
	p = *ptr--;
	if ((p & lomask) > currentBrightness)  			bits|=64;
	if ((p & himask) > currentBrightnessShifted)	bits|=128;
	p = *ptr--;
	if ((p & lomask) > currentBrightness)  			bits|=16;
	if ((p & himask) > currentBrightnessShifted)	bits|=32;
	p = *ptr--;
	if ((p & lomask) > currentBrightness)  			bits|=4;
	if ((p & himask) > currentBrightnessShifted)	bits|=8;
	p = *ptr--;
	if ((p & lomask) > currentBrightness)  			bits|=1;
	if ((p & himask) > currentBrightnessShifted)	bits|=2;

	while (!(SPSR & (1<<SPIF)))  { } // wait for prior bitshift to complete
	SPDR = bits;
	
	
	bits=0;
	p = *ptr--;
	if ((p & lomask) > currentBrightness)  			bits|=64;
	if ((p & himask) > currentBrightnessShifted)	bits|=128;
	p = *ptr--;
	if ((p & lomask) > currentBrightness)  			bits|=16;
	if ((p & himask) > currentBrightnessShifted)	bits|=32;
	p = *ptr--;
	if ((p & lomask) > currentBrightness)  			bits|=4;
	if ((p & himask) > currentBrightnessShifted)	bits|=8;
	p = *ptr--;
	if ((p & lomask) > currentBrightness)  			bits|=1;
	if ((p & himask) > currentBrightnessShifted)	bits|=2;

	while (!(SPSR & (1<<SPIF)))  { } // wait for prior bitshift to complete
	SPDR = bits;
	
	
	bits=0;
	p = *ptr--;
	if ((p & lomask) > currentBrightness)  			bits|=64;
	if ((p & himask) > currentBrightnessShifted)	bits|=128;
	p = *ptr--;
	if ((p & lomask) > currentBrightness)  			bits|=16;
	if ((p & himask) > currentBrightnessShifted)	bits|=32;
	p = *ptr--;
	if ((p & lomask) > currentBrightness)  			bits|=4;
	if ((p & himask) > currentBrightnessShifted)	bits|=8;
	p = *ptr--;
	if ((p & lomask) > currentBrightness)  			bits|=1;
	if ((p & himask) > currentBrightnessShifted)	bits|=2;

	while (!(SPSR & (1<<SPIF)))  { }// wait for prior bitshift to complete
	SPDR = bits;
	
	////////////////////  Now set the row and latch the bits
	
	uint8_t portD;
	
	
	if (currentRow < 15)
		portD = currentRow+1;
	else
		portD = (currentRow -14)<<4;


	while (!(SPSR & (1<<SPIF)))  { } // wait for last bitshift to complete
	
	//if (currentBrightness == 0)
	PORTD = 0;				// set all rows to off
	PORTB |= _BV(1);//(1<<PB1); //  latch it, values now set
	//if (currentBrightness == 0)
	PORTD = portD;     // set row
	PORTB &= ~( _BV(1));//~((1<<PB1)); // reset latch for next time
	
	// notes to self, calculations from the oscope:
	// need about minimum of 6us total to clock out all 4 bytes
	// roughly 1.5ms per byte, although some of that is
	// idle time taken between bytes.  6=7us therefore is our
	// absolute minimum time needed to refresh a row, not counting calculation time.
	// Thats just if we do nothing else when writing out SPI and toggle to another row.
	//Measured values from this routine	
	// @ 144 fps the latch is toggled every 19us with an actual 4byte clock out time of 12-13us
	// @ 70 fps the latch is toggle every 39us, with a clock out time of 13-14us
	// times do not count setup/teardown of stack frame
	
	// one byte @ 115k takes 86us (max) 78us (min) , measured time
	// one byte @ 230k takes 43us (max) 39us (min) , measured time
	// so 230k serial might barely be possible, but not with a 16mhz crystal (error rate to high)
	// 250k might just barely be possible
}

void displayInit(void) 
{
	// need to set output for SPI clock, MOSI, SS and latch.  Eventhough SS is not connected,
	// it must apparently be set as output for hardware SPI to work.
	DDRB =  (1<<DDB5) | (1<<DDB3) | (1<<DDB2) | (1<<DDB1);
	// set all portd pins as output
	DDRD = 0xff; 

	PORTD=0; // select no row
	
	// enable hardware SPI, set as master and clock rate of fck/2
	SPCR = (1<<SPE) | (1<<MSTR);
	SPSR = (1<<SPI2X); 

	// setup the interrupt.
	TCCR0A = (1<<WGM01); // clear timer on compare match
	TCCR0B = (1<<CS01); // timer uses main system clock with 1/8 prescale
	OCR0A  = (F_CPU >> 3) / 25 / 15 / FPS; // Frames per second * 15 passes for brightness * 25 rows
	TIMSK0 = (1<<OCIE0A);	// call interrupt on output compare match


	for (uint8_t i=0; i < 4; i++)
	{
		SPDR = 0;
		while (!bit_is_set(SPSR, SPIF)) {}
	}
}




////////////////////////////////////////////////////////////////////////////////////////////
// I2C  routines
////////////////////////////////////////////////////////////////////////////////////////////

// TWI Slave Receiver staus codes, from Atmel notes
#define TWI_SRX_ADR_ACK            0x60 
#define TWI_SRX_ADR_ACK_M_ARB_LOST 0x68 
#define TWI_SRX_GEN_ACK            0x70 
#define TWI_SRX_GEN_ACK_M_ARB_LOST 0x78 
#define TWI_SRX_ADR_DATA_ACK       0x80 
#define TWI_SRX_ADR_DATA_NACK      0x88 
#define TWI_SRX_GEN_DATA_ACK       0x90 
#define TWI_SRX_GEN_DATA_NACK      0x98 
#define TWI_SRX_STOP_RESTART       0xA0 
#define TWI_NO_STATE               0xF8 
#define TWI_BUS_ERROR              0x00 

void initTwiSlave(uint8_t addr)
{
 
    PORTC |=  _BV(5) | _BV(4);      //(1<<PC5) | (1<<PC4); // enable pullups

    TWAR = (0<<TWGCE) |((uint8_t) (0xff & (addr<<1)));    // set slave address, no general call address
    TWDR = 0xff; // Default content = SDA released

    TWCR = (1<<TWINT) |   // "clear the flag"  (hate this backward terminology)
          (1<<TWEA) |     // send acks to master when getting address or data
          (0<<TWSTA) |    // not a master, cant do start 
          (0<<TWSTO) |    // doc says set these to 0
          (0<<TWWC) | 
          (1<<TWEN) |   // hardware TWI  enabled
          (0<<TWIE);   // do NOT generate interrupts.

    while (TWCR & (1<<TWIE)) { }

}


uint8_t getTwiByte(void)
{
	uint8_t result=0;
 
  	keepListening:
 
 	// wait for an state change
  	while (!(TWCR & (1<<TWINT))) { } // wait for TWINT to be set
  
  	
  	//uint8_t sr = TWSR;
  	switch (TWSR)
  	{
	    case TWI_SRX_ADR_DATA_ACK:  // received a byte of data data
	    case TWI_SRX_GEN_DATA_ACK:       
			result = TWDR;
	      	TWCR = (1<<TWEN)|(1<<TWINT)|(1<<TWEA);
			break;

  		
//        case TWI_SRX_GEN_ACK_M_ARB_LOST: 
//        case TWI_SRX_ADR_ACK_M_ARB_LOST: 
    	case TWI_SRX_GEN_ACK:             
    	case TWI_SRX_ADR_ACK:      // receive our address byte      
		      TWCR = (1<<TWEN)|(1<<TWINT)|(1<<TWEA);
		      goto keepListening;
		      break;
			
	    case TWI_SRX_STOP_RESTART:       // A STOP or repeated START condition was received 
	    	TWCR = (1<<TWEN)|(1<<TWINT)|(1<<TWEA); 
		    goto keepListening;       
	      	break;           

	    case TWI_SRX_ADR_DATA_NACK:   // data received, returned nack
	    case TWI_SRX_GEN_DATA_NACK:
	     	//result = TWDR;
	      	TWCR = (1<<TWEN)|(1<<TWINT); //|(1<<TWEA);
	      	goto keepListening;
			break;
	    
    	case TWI_NO_STATE:
    		goto keepListening;
    		break;   
    	
//	    case TWI_BUS_ERROR:      
	    default:     			 // something bad happened. assuming a bus error, we try to recover from this
	      //state = TWSR;
	      //TWCR = (1<<TWEN)|(0<<TWINT)|(0<<TWEA);    // Don't ack any further requests, will stop receiving
	      // alternate handling: reset state and continue
	      TWCR = (1<<TWEN)|(1<<TWINT)|(1<<TWEA)|(1<<TWSTO);    // ignore
	      // wait for stop condition to be exectued; TWINT will not be set after a stop
		  while(TWCR & (1<<TWSTO)){ }
		  result = 0xff;
	      break;
    }
	return result;
}



////////////////////////////////////////////////////////////////////////////////////////////
// MAIN LOOP: handle the input data stream  and stuff bytes into the framebuffer
////////////////////////////////////////////////////////////////////////////////////////////

void serviceInputData(void)
{
	uint8_t *ptr = frameBuffer;
	uint8_t state = 0; 
	int counter = 0;
	while (1)
	{   
		uint8_t c = getTwiByte();
		
		// very simple state machine to look for 6 byte start of frame
		// marker and copy bytes that follow into buffer
		if (state  <6)
		{
                        // BADDCAFE (board 5)
                        //if (state == 0 && c == 0xba) state++;
			//else if (state ==1 && c == 0xdd) state++;
			//else if (state ==2 && c == 0xca) state++;
			//else if (state ==3 && c == 0xfe) state++;
			//else if (state ==4 && c == 0x01) state++;

                        // FEEDFACE (board 4)
                        //if (state == 0 && c == 0xfe) state++;
			//else if (state ==1 && c == 0xed) state++;
			//else if (state ==2 && c == 0xfa) state++;
			//else if (state ==3 && c == 0xce) state++;
			//else if (state ==4 && c == 0x01) state++;
                        
                        // FEE1DEAD (board 3)
                        //if (state == 0 && c == 0xfe) state++;
			//else if (state ==1 && c == 0xe1) state++;
			//else if (state ==2 && c == 0xde) state++;
			//else if (state ==3 && c == 0xad) state++;
			//else if (state ==4 && c == 0x01) state++;
                        
                        //CAFEFEED (board 2)
                        if (state == 0 && c == 0xca) state++;
			else if (state ==1 && c == 0xfe) state++;
			else if (state ==2 && c == 0xfe) state++;
			else if (state ==3 && c == 0xed) state++;
			else if (state ==4 && c == 0x01) state++;
                        
                        // DEADBEEF (board 1)
			//if (state == 0 && c == 0xde) state++;
			//else if (state ==1 && c == 0xad) state++;
			//else if (state ==2 && c == 0xbe) state++;
			//else if (state ==3 && c == 0xef) state++;
			//else if (state ==4 && c == 0x01) state++;
			
                        // this stays for all boards
                        else if (state ==5)  // dont care what 6th byte is 
			{
				state++;
				counter = 0;
				ptr = frameBuffer;
			}
			else state = 0; // error: reset to look for start of frame
		}
		else 
		{
			// inside of a frame, so save each byte to buffer
			*ptr++ = c;
			counter++;
			if (counter >= DISP_BUFFER_SIZE)
			{
				// buffer filled, so reset everything to wait for next frame
				//counter = 0;
				//ptr = frameBuffer;
				state = 0;
			}
		}
	}
}

 


void setup()                    // run once, when the sketch starts
{ 
  	// Enable pullups for buttons/i2c
	PORTB |= _BV(0);//(1<<PB0); 
	PORTC = _BV(5) |  _BV(4) |  _BV(3) | _BV(2) |  _BV(1) |  _BV(0);
                 //(1<<PC5) | (1<<PC4) | (1<<PC3) | (1<<PC2) | (1<<PC1) | (1<<PC0);

	UCSR0B =0; // turn OFF serial RX/TX, necessary if using arduino bootloader 
	
	displayInit(); 

 	initTwiSlave(TWI_SLAVE_ID);
 	
 
 
 	sei( );

	// clear display and set to test pattern
	// pattern should look just like the "gray test pattern" from EMS

	uint8_t v = 0;
	for (int i =0; i < DISP_BUFFER_SIZE; i++)
	{
		v = (v+2) % 16;
	    // set to 0 for blank startup display
		// low order bits on the left, high order bits on the right
			frameBuffer[i]= v + ((v+1)<<4);  
		//	frameBuffer[i]=0;
	}
	
	serviceInputData();  // never returns

        // Wire.begin(TWI_SLAVE_ID);
        // Wire.onReceive(receiveEvent); // register event
}

void loop() // run over and over again
{ 
  
}

/*
void receiveEvent(int howMany) {
  
  int y;
  byte S;
  int L;
  
  Source = Wire.receive(); // receive the address of the sender
  L = Wire.receive();
  for (y=0; y<= L; y++) {
    S = Wire.receive(); // get byte y of L
    String1[y] = (char)S; // save it into the string
  }
  
  x = Wire.receive(); // receive whatever is after the string
  Serial.print("Received from #");  // who called?
  Serial.print(Source);
  Serial.print(": Message is ~ ");  // What they had to say
  Serial.print(String1);
  Serial.println(x);
}
*/
