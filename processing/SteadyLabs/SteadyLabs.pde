/**
* Bounce code modified from the Processing samples and modified to display on a Peggy 2.. 

BE SURE TO CHANGE THE SERIAL PORT NAME!! IN THE Setup() METHOD!

*/ 
import processing.serial.*;
int x, y;
PFont dFont;
int speed = 5;
Serial peggyPort;
PImage peggyImage = new PImage(125,25);
byte [] peggyHeader = new byte[] { (byte)0xde, (byte)0xad, (byte)0xbe,(byte)0xef,1,0 };
byte [] peggyFrame = new byte[13*25];

byte [] peggyHeader2 = new byte[] { (byte)0xca, (byte)0xfe, (byte)0xfe,(byte)0xed,1,0 };
byte [] peggyFrame2 = new byte[13*25];

byte [] peggyHeader3 = new byte[] { (byte)0xfe, (byte)0xe1, (byte)0xde,(byte)0xad,1,0 };
byte [] peggyFrame3 = new byte[13*25];

byte [] peggyHeader4 = new byte[] { (byte)0xfe, (byte)0xed, (byte)0xfa,(byte)0xce,1,0 };
byte [] peggyFrame4 = new byte[13*25];

byte [] peggyHeader5 = new byte[] { (byte)0xba, (byte)0xdd, (byte)0xca,(byte)0xfe,1,0 };
byte [] peggyFrame5 = new byte[13*25];

int size = 60;       // Width of the shape
float xpos, ypos;    // Starting position of shape    

float xspeed = 4.8;  // Speed of the shape
float yspeed = 4.2;  // Speed of the shape

int xdirection = 1;  // Left or Right
int ydirection = 1;  // Top to Bottom


void setup() 
{
 size(1000, 200);
 noStroke();
 frameRate(30);
// smooth();
 // Set the starting position of the shape
 xpos = width/2;
 ypos = height/2;

 peggyPort = new Serial(this, "/dev/tty.usbserial-A800ewwz", 115200);
x = width;
y = 10+(int)random(height-50); // not entire height so the text is allways inside the screen. 

 dFont = createFont("FFScala", 200);

textFont(dFont,100);
textAlign(LEFT);
}

// this method creates a PImage that is a copy 
// of the current processing display.
// Its very crude and inefficient, but it works.
PImage grabDisplay()
{
 PImage img = createImage(width, height, ARGB);
 loadPixels();
//  img.loadPixels();  // apparently not necessary
 arraycopy(pixels, 0, img.pixels, 0, width * height);
//  updatePixels();   // apparently not necessary
 return img;
}

// render a PImage to the Peggy by transmitting it serially.  
// If it is not already sized to 25x25, this method will 
// create a downsized version to send...
void renderToPeggy(PImage srcImg)
{
 int idx = 0;
 int idx2 =0;
 int idx3 = 0;
 int idx4 = 0;
 int idx5 = 0;

 PImage destImg = peggyImage;
 if (srcImg.width != 25 || srcImg.height != 25)
   destImg.copy(srcImg,0,0,srcImg.width,srcImg.height,0,0,destImg.width,destImg.height);
 else
   destImg = srcImg;

 // iterate over the image, pull out pixels and 
 // build an array to serialize to the peggy
 for (int y =0; y < 25; y++)
 {
   byte val = 0;
   for (int x=0; x < 25; x++)
   {
     color c = destImg.get(x,y);
     int br = ((int)brightness(c))>>4;
     if (x % 2 ==0)
       val = (byte)br;
     else
     {
       val = (byte) ((br<<4)|val);
       peggyFrame[idx++]= val;
     }
   }
   peggyFrame[idx++]= val;  // write that one last leftover half-byte
 }


 //===
 for (int y =0; y < 25; y++)
 {
   byte val = 0;
   for (int x=0; x < 25; x++)
   {
     color c = destImg.get(x+25,y);
     int br = ((int)brightness(c))>>4;
     if (x % 2 ==0)
       val = (byte)br;
     else
     {
       val = (byte) ((br<<4)|val);
       peggyFrame2[idx2++]= val;
     }
   }
   peggyFrame2[idx2++]= val;  // write that one last leftover half-byte
 }

 //===
 for (int y =0; y < 25; y++)
 {
   byte val = 0;
   for (int x=0; x < 25; x++)
   {
     color c = destImg.get(x+50,y);
     int br = ((int)brightness(c))>>4;
     if (x % 2 ==0)
       val = (byte)br;
     else
     {
       val = (byte) ((br<<4)|val);
       peggyFrame3[idx3++]= val;
     }
   }
   peggyFrame3[idx3++]= val;  // write that one last leftover half-byte
 }
 //==
   for (int y =0; y < 25; y++)
 {
   byte val = 0;
   for (int x=0; x < 25; x++)
   {
     color c = destImg.get(x+75,y);
     int br = ((int)brightness(c))>>4;
     if (x % 2 ==0)
       val = (byte)br;
     else
     {
       val = (byte) ((br<<4)|val);
       peggyFrame4[idx4++]= val;
     }
   }
   peggyFrame4[idx4++]= val;  // write that one last leftover half-byte
 }
 //==
   for (int y =0; y < 25; y++)
 {
   byte val = 0;
   for (int x=0; x < 25; x++)
   {
     color c = destImg.get(x+100,y);
     int br = ((int)brightness(c))>>4;
     if (x % 2 ==0)
       val = (byte)br;
     else
     {
       val = (byte) ((br<<4)|val);
       peggyFrame5[idx5++]= val;
     }
   }
   peggyFrame5[idx5++]= val;  // write that one last leftover half-byte
 }

 // send the header, followed by the frame
 peggyPort.write(peggyHeader);
 peggyPort.write(peggyFrame);

 peggyPort.write(peggyHeader2);
 peggyPort.write(peggyFrame2);

 peggyPort.write(peggyHeader3);
 peggyPort.write(peggyFrame3);

 peggyPort.write(peggyHeader4);
 peggyPort.write(peggyFrame4);

 peggyPort.write(peggyHeader5);
 peggyPort.write(peggyFrame5);
 //no way to flush()?  Apparently this is done by write()
}

void draw() 
{
 background(0);
 /*
   // Update the position of the shape
 xpos = xpos + ( xspeed * xdirection );
 ypos = ypos + ( yspeed * ydirection );

 // Test to see if the shape exceeds the boundaries of the screen
 // If it does, reverse its direction by multiplying by -1
 if (xpos > width-size || xpos < 0) {
   xdirection *= -1;
 }
 if (ypos > height-size || ypos < 0) {
   ydirection *= -1;
 }
*/
 // Draw the shape
//  ellipse(xpos+size/2, ypos+size/2, size, size);

fill(255);
text("STEADY LABS",x,y);
x -= speed;
if(x<-textWidth("STEADY LABS")){ // use x<-textWidth("scrolling") or something here to get the proper clipping of the text
 x = width; 
 y = 10+(int)random(height-50);
}

 renderToPeggy(grabDisplay());

}
