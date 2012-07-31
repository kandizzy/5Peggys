
/**
 * Video Mirror for Peggy
 * Based on the processing sketch "Mirror" by Daniel Shiffman. 
 * Modified by Windell H Oskay to adapt video to Peggy 2.0 
 * 
 * Also incorporates code from Jay Clegg, http://planetclegg.com/projects/
 *
 *
 * To use this file, please see http://www.evilmadscientist.com/article.php/peggy2twi
 *
 * You will need to edit the line below with your actual serial port name listed; search for "CHANGE_HERE"
 *
 */
  

import processing.video.*;
import processing.serial.*;

Serial peggyPort;
PImage peggyImage = new PImage(50,50);
byte [] peggyHeader4 = new byte[] { (byte)0xfe, (byte)0xed, (byte)0xfa,(byte)0xce,1,0 };
byte [] peggyHeader3 = new byte[] { (byte)0xfe, (byte)0xe1, (byte)0xde,(byte)0xad,1,0 };
byte [] peggyHeader5 = new byte[] { (byte)0xba, (byte)0xdd, (byte)0xca,(byte)0xfe,1,0 };
byte [] peggyHeader2 = new byte[] { (byte)0xca, (byte)0xfe, (byte)0xfe,(byte)0xed,1,0 };
byte [] peggyHeader = new byte[] { (byte)0xde, (byte)0xad, (byte)0xbe,(byte)0xef,1,0 };
byte [] peggyFrame = new byte[13*25];
byte [] peggyFrame2 = new byte[13*25];
byte [] peggyFrame4 = new byte[13*25];
byte [] peggyFrame5= new byte[13*25];



// Size of each cell in the grid
int cellSize = 3;//9;  
int cellSize2 = 12;//34;  // was 20 

// Number of columns and rows in our system
int cols, rows;
int ColLo, ColHi;
// Variable for capture device
Capture video;

int xDisplay,yDisplay;
int xs, ys; 
float brightTot;
int pixelCt;
color c2;

int OutputPoint = 0;

//int GrayArray[625];
//int[] GrayArray = new int[625];
int[] GrayArray = new int[2500];
int j;
byte k; 

int DataSent = 0;


// NEEDS TO HAVE YOUR ACTUAL SERIAL PORT LISTED!!!

void setup() {
    //peggyPort = new Serial(this, "/dev/tty.usbserial-FTF4R2RS", 115200);    // CHANGE_HERE
    peggyPort = new Serial(this, "/dev/tty.usbserial-A800ewwz", 115200);    // CHANGE_HERE
    smooth();
    noStroke();
//  size(640, 480, P3D);
    //size(cellSize2*25, cellSize2*25, JAVA2D);
    size(cellSize2*50, cellSize2*50, JAVA2D);
  //set up columns and rows
  //cols = 25; //width / cellSize;
    cols = 50;  
    ColLo = 8; //Was 4
    ColHi = 58; // Was 29
    rows = 50; //height / cellSize;
    colorMode(RGB, 255, 255, 255, 100);
    rectMode(CENTER);

  // Uses the default video input, see the reference if this causes an error
//  video = new Capture(this, width, height, 5);
    video = new Capture(this, 320, 240, 15);  //Last number is frames per second
    background(0);
  
    j = 0;
    k = 0;

    while (j < 2500){
  //while (j < 625){
      GrayArray[j] = 4;//k;
      k++;
      if (k > 15) k = 0;
    j++;   
  }
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
  
  PImage destImg = srcImg; 
  
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
   

  peggyPort.write(peggyHeader5);
  peggyPort.write(peggyFrame5); 
  
  peggyPort.write(peggyHeader4);
  peggyPort.write(peggyFrame4); 
  
  peggyPort.write(peggyHeader2);
  peggyPort.write(peggyFrame2); 
  
  peggyPort.write(peggyHeader);
  peggyPort.write(peggyFrame);

}





void draw() { 
  if (video.available()) { 
    video.read(); 
    video.loadPixels(); 
    
    background(0, 0, 0);

  //int MaxSoFar = 0;
  int thisByte = 0;
  int e,k;
  int br2;

  int idx = 0;

  //PImage img2 = createImage(25, 25, ARGB);
  PImage img2 = createImage(50, 50, ARGB);
  // Begin loop for columns
    
    k = 0;
    for (int i = ColLo; i < ColHi;i++) {
      // Begin loop for rows
      for (int j = 0; j < rows;j++) {
        // Where are we, pixel-wise?
        int x = i * cellSize;
        int y = j * cellSize;
        int loc = (video.width - x - 1) + y*video.width; // Reversing x to mirror the image

        // Each rect is colored white with a size determined by brightness
        color c = video.pixels[loc]; 
        
        pixelCt = 0;
        brightTot = 0;
        
        for (int xs = x; xs < (x + cellSize); xs++) {
         for (int ys = y; ys < (y + cellSize); ys++) {
        
          pixelCt++;
          loc = (video.width - xs - 1) + ys*video.width;
          c2 = video.pixels[loc];
          brightTot += brightness(c2);
           
        } 
        } 
        
        brightTot /= pixelCt;
         
        xDisplay = (i-ColLo)*cellSize2 + cellSize2/2;
        yDisplay = j*cellSize2 + cellSize2/2;        
        
         
  
// Linear brightness:        
         br2 = int(brightTot / 8);
   
          idx = (j)*cols + (i-ColLo); 
         GrayArray[idx] = (int) br2;  //inverted image      
      
          
        br2 = br2*8;    
         
        fill(br2,br2,br2);         // 8-level with true averaging   
         ellipse(xDisplay+1, yDisplay+1, cellSize2-1, cellSize2-1);    
        
       img2.pixels[idx] = br2; 
  k++;  
  }
    }
    
     renderToPeggy(img2);
        
  }  // End if video available
} // end main loop
