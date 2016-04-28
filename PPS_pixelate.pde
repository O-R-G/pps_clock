// Public Private Secret Clock
// O-R-G
// requires ipcature lib https://github.com/singintime/ipcapture

import processing.video.*;
import ipcapture.*;

Movie mov;
IPCapture cam;

color movColors[];

int pixels, pixelsH, pixelsW;
int blockSize = 10;
int sortProgress;


void setup() {
  // size(640, 360);
  size(640, 480);
frameRate(5);
  noStroke();
  
mov = new Movie(this, "broadway-fast.mov");
  mov.loop();
  pixelsW = width / blockSize;
  pixelsH = height / blockSize;
  pixels = pixelsW * pixelsH;
  movColors = new color[pixels];
  println("pixels : " + pixels);
	// ipcapture
  
	cam = new IPCapture(this, "http://192.168.1.21/live", "", "");
	cam.start();
}

void draw() {

	sortProgress++;


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

/*
  for (int j = 0; j < pixelsH; j++) {
    for (int i = 0; i < pixelsW; i++) {
      fill(movColors[j*pixelsW + i]);
      rect(i*blockSize, j*blockSize, blockSize, blockSize);
    }
  }
*/

/*
// invert rows, columns
	for (int j = 0; j < pixelsW; j++) {
    for (int i = 0; i < pixelsH; i++) {
      fill(movColors[j*pixelsH + i]);
      rect(j*blockSize, i*blockSize, blockSize, blockSize);
    }
  }
*/


// ipcam
  if (cam.isAvailable()) {
    cam.read();
    image(cam,0,0);
  }

	// saveFrame("out/frame-####.png");

}
