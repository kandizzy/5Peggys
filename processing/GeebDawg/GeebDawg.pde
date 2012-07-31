import processing.serial.*;

PImage titleImage;
float x, y;

int speed = 1;
Serial peggyPort;
PImage peggyImage = new PImage(25,25);

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

 size (50,50);
 noStroke();
 frameRate(15);
// smooth();
 // Set the starting position of the shape
 x= 0; // width/2;
 y = 0; // eight/2;

//peggyPort = new Serial(this, "/dev/tty.usbserial-FTF4R2RS", 115200);
peggyPort = new Serial(this, "/dev/tty.usbserial-A800ewwz", 115200);


  titleImage = loadImage("geeb-50.png", "png");
  x = 0.0;  
  
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
 //int idx3 = 0;
 int idx4 = 0;
 int idx5 = 0;

 PImage destImg = peggyImage;
 if (srcImg.width != 50 || srcImg.height != 50)
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
     color c = destImg.get(25-x,25-y);
     
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
     color c = destImg.get((25-x)+25,25-y);
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
/*
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
 */
 
 //==
   for (int y =0; y < 25; y++)
 {
   byte val = 0;
   for (int x=0; x < 25; x++)
   {
     color c = destImg.get(x,y+25);
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
     color c = destImg.get(x+25,y+25);
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

 peggyPort.write(peggyHeader5);
 peggyPort.write(peggyFrame5);
 
 peggyPort.write(peggyHeader4);
 peggyPort.write(peggyFrame4);
 
 peggyPort.write(peggyHeader2);
 peggyPort.write(peggyFrame2);
 
 peggyPort.write(peggyHeader);
 peggyPort.write(peggyFrame);


  /*
 peggyPort.write(peggyHeader2);
 peggyPort.write(peggyFrame);
  */

/*
 peggyPort.write(peggyHeader3);
 peggyPort.write(peggyFrame);


 peggyPort.write(peggyHeader4);
 peggyPort.write(peggyFrame);


 peggyPort.write(peggyHeader5);
 peggyPort.write(peggyFrame);
 */
 //no way to flush()?  Apparently this is done by write()
}

void draw() 
{
 background(255);

 //translate(x,y);
 
 image(titleImage,0,0);
 
 //filter(INVERT);
 
 /*
 x -= speed;
 if(x<-titleImage.width){ // use x<-textWidth("scrolling") or something here to get the proper clipping of the text
   x = width; 

  }
  */
 
 
 renderToPeggy(grabDisplay());

}
