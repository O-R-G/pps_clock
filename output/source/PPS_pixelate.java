import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.video.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class PPS_pixelate extends PApplet {

// Public Private Secret Clock
// O-R-G



int pixels, pixelsH, pixelsW;
int blockSize = 10;
int sortProgress;
Movie mov;
int movColors[];

public void setup() {
  
	//	frameRate(5);
  noStroke();
  mov = new Movie(this, "broadway-fast.mov");
  mov.loop();
  pixelsW = width / blockSize;
  pixelsH = height / blockSize;
  pixels = pixelsW * pixelsH;
  movColors = new int[pixels];
  println("pixels : " + pixels);
}

public void draw() {

	sortProgress++;

 /*
 if (blockSize < 20) {
  blockSize++;
  } else if (blockSize > 0) {
  blockSize--;
  }
  */
  
  if (mov.available() == true) {
    mov.read();
    mov.loadPixels();
    int count = 0;
    for (int j = 0; j < pixelsH; j++) {
      for (int i = 0; i < pixelsW; i++) {
        movColors[count] = mov.get(i*blockSize, j*blockSize);
        count++;
      }
    }
    
	// movColors = sort(movColors,sortProgress%(pixels-1));
	movColors = sort(movColors,((pixels-1) - sortProgress%(pixels-1)));
	// movColors = reverse(sort(movColors,sortProgress%(pixels-1)));
  }

  background(0);

  for (int j = 0; j < pixelsH; j++) {
    for (int i = 0; i < pixelsW; i++) {
      fill(movColors[j*pixelsW + i]);
      rect(i*blockSize, j*blockSize, blockSize, blockSize);
    }
  }

/*
// invert rows, columns
	for (int j = 0; j < pixelsW; j++) {
    for (int i = 0; i < pixelsH; i++) {
      fill(movColors[j*pixelsH + i]);
      rect(j*blockSize, i*blockSize, blockSize, blockSize);
    }
  }
*/
	// saveFrame("out/frame-####.png");
}
  public void settings() {  size(640, 360); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "PPS_pixelate" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
