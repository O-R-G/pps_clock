// Public Private Secret Clock
// O-R-G
// requires https://github.com/singintime/ipcapture

import processing.video.*;
import ipcapture.*;

Movie mov;
IPCapture cam;

boolean ip = false;
color colors[];
int pixels, pixelsH, pixelsW;
int blockSize = 10;
int speed = 2;
int sortProgress;
String ipsrc = "http://192.168.1.21/live";	
String movsrc = "broadway-slow.mov";

void setup() {
  	size(640, 480);
	frameRate(6*speed);
  	noStroke();
	if (ip) {
	  	println("Using ip camera . . . ");
		cam = new IPCapture(this, ipsrc, "", "");
		cam.start();
	} else if (!ip) {
  		println("Using local mov . . . ");
		mov = new Movie(this, movsrc);
	  	mov.loop();
	}
  	pixelsW = width / blockSize;
  	pixelsH = height / blockSize;
  	pixels = pixelsW * pixelsH;
  	colors = new color[pixels];
  	println("Pixels : " + pixels);
}

void draw() {
	background(0);
	sortProgress+=speed;

	if (ip && cam.isAvailable()) cam.read();
	if (!ip && mov.available()) mov.read();
	int count = 0;
	for (int j = 0; j < pixelsH; j++) {
		for (int i = 0; i < pixelsW; i++) {
			if (ip)  colors[count] = cam.get(i*blockSize, j*blockSize);
			if (!ip) colors[count] = mov.get(i*blockSize, j*blockSize);	
			count++;
		}
	}

	colors = sort(colors,sortProgress%(pixels-1));

	for (int j = 0; j < pixelsH; j++) {
    	for (int i = 0; i < pixelsW; i++) {
			fill(colors[j*pixelsW + i]);
			rect(i*blockSize, j*blockSize, blockSize, blockSize);
		}
  	}

	// ** todo ** write out to video
	// saveFrame("out/frame-####.png");
}
