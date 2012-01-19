#include <Wire.h>

// Serial-to-TWI/I2C code, used to convert serial data from a PC/Mac to 
// TWI/I2C data for a Peggy 2.0 with the VideoPeggyTwi firmware.
//

#define PEGGY_ADDRESS 30

#define TWI_FREQ 300000

void setup()
{
  Serial.begin(115200);

  UBRR0H = 0;
  UBRR0L = 16; // manually set 115200
  UCSR0A = (1<<U2X0);
  //UCSR0B = (1<<RXEN0) | (1<<TXEN0);

  //Serial.print("Sender Initialized...");
  Wire.begin();

 PORTC |=  _BV(5) | _BV(4);      // //PORTC |=  (1<<PC5) | (1<<PC4); // enable pullups

  // jack up the frequency for TWI, we need a pretty high
  // rate  from the TWI engine for this to handle 115k input
  // without getting buffer overruns
  TWSR &= ~(1<<TWPS0);
  TWSR &= ~(1<<TWPS1);
  TWBR = ((F_CPU / TWI_FREQ) - 16) / 2;

}

void loop()
{
  uint8_t count = Serial.available();
  
  if (count > 0)
  {
    // dont allow send too many bytes at once, dont want to exceed the buffer
    // size of the Wire library 
    if (count > 16) count = 16;
  
    Wire.beginTransmission(PEGGY_ADDRESS); 
    while (count-- > 0 )
    {
      uint8_t c = Serial.read(); 
      Wire.send(c);
    }
    Wire.endTransmission();   
  }
}
