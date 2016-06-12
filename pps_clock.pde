// Public Private Secret Clock
// O-R-G

import processing.video.*;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.io.File;
import java.io.FilenameFilter;

Movie mov;
Capture[] captures;
Capture capture;
Capture captureNext;

PixelSort pixelsort;
PixelComparator comp;
PImage[] loadedimages;

int camswitchinterval = 15; // units = minutes
int saveimageinterval = 1;
int saveimagelastmin = -1;
int nosortswitchinterval = 2;
int nosortswitchlastmin = -1;
int sortswitchinterval = 10;
int sortswitchlastmin = -1;
int compswitchinterval = 120;
int compswitchlastmin = -1;
int imagesloadinterval = 59;
int imagesloadlastmin = -1;
int imagesplayinterval = 60;

int cap = 0;
int numpixels, ypixels, xpixels;
int outpixelsize = 6;
int inpixelsize = 4;
int pixelsize = 6;
int pixelstep = 1;

int alpha = 100; // [0-255]
int sorttype = 0;
int comptype = 0;
int nullframes = 0;
int numsorts = 6;
int numcomps = 2;
int imagescount;
int imagescounter;
int lastmin;
int lastsec;

boolean playimages;
boolean playingimages;
boolean canswitchcam = false;
boolean camstarted = false;
boolean verbose = true;

void setup() {
    frameRate(30); // [30]
    noStroke();
    background(0);
	noCursor();

    try {
        println("Using usb camera . . . ");
        capture = captures[cap];
        capture.start();
    } catch (Exception e) {
        e.printStackTrace();
        printArray(Capture.list()); 
    }

	imagescount = int(60/saveimageinterval);
	loadedimages = new PImage[imagescount];

    setResolution(pixelsize);
    pixelsort = new PixelSort(xpixels, ypixels);
}

void draw() {
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int h, m, s;

    h = hour();
    m = minute();
    s = second();
	if (h == 0) h = 24; // avoid 0 % 
	if (m == 0) m = 60; // avoid 0 % 
	if (s == 0) s = 60;

    // `date mmddHHMMyy.ss`
	if (verbose && s != lastsec)
		println(nf(h,2) + ":" + nf(m,2) + ":" + nf(s,2));	

	// scale(0.5);

	// timers

	lastmin = checkMin(m, lastmin);

	// playback

	if (playimages) 
		if (imagesLoaded(imagescount))
			playImages(imagescount, loadedimages, 1);

	// live

	if (!playingimages)
    	pixels = getPixels(capture);

    if (pixels != null && !playingimages) {
        pixels = pixelsort.sort(pixels, comptype, sorttype);

        for (int j = 0; j < ypixels; j++) {
            for (int i = 0; i < xpixels; i++) {
                int index = (j * xpixels + i) % numpixels;
                color c = pixels.get(index).getColor();
				fill(hue(c), saturation(c), brightness(c), alpha); 
				rect(i*pixelsize, j*pixelsize, pixelsize, pixelsize);
            }
        }
        if ((m % saveimageinterval == 0) && (m != saveimagelastmin) && s == 30) {
            saveImage();
            saveimagelastmin = m;		
        }
        camstarted = true;
    } else if (nullframes > 10 && camstarted) {
		turnOnNextCam();
        switchCam();
        camstarted = false;
    }

	lastsec = s;
}

int checkMin(int thism, int thislastmin) {
	// minutes
	if (thism != thislastmin) {
    	switch (thism) {
			case 5: 
				// new sort
				sorttype++;
		 		sorttype %= numsorts;
				if (verbose) println("+ " + thism);
				thislastmin = thism;
				break;
			case 6: 
			case 7: 
			case 8: 
				// new comp
				comptype++;	
				comptype %= numcomps;
				if (verbose) println("+ " + thism);
				thislastmin = thism;
				break;
			case 14: 
			case 29: 
			case 44:
				// next cam
				turnOnNextCam();
	            if (verbose) println("** turnOnNextCam() ** " + captures.length);
				if (verbose) println("+ " + thism);
				thislastmin = thism;
				break;
			case 15: 
			case 30: 
			case 45:
				// switch cam
				if (canswitchcam)
					switchCam();
	            if (verbose) println("** switchCam() **");
				if (verbose) println("+ " + thism);
				thislastmin = thism;
				break;
			case 59:
				// loadimages
				loadImages(imagescount, loadedimages);
				// next cam
				turnOnNextCam();
				if (verbose) println("+ " + thism);
				thislastmin = thism;
            	break;
			case 60:
				// nosort
				sorttype = 10; // default no sort
				// playimages
			    if (imagesLoaded(imagescount))
        			playImages(imagescount, loadedimages, 1);
				// switch cam
				if (canswitchcam)
					switchCam();
				if (verbose) println("+ " + thism);
				thislastmin = thism;
            	break;
        	default:
				thislastmin = thism - 1;
				break;
		}
	}
	return thislastmin;
}

ArrayList<Pixel> getPixels(Capture capture) {
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int x, y;
    color c;
    if (capture.available()) {
        nullframes = 0;
        capture.read();
        for (int j = 0; j < ypixels; j++) {
            y = (int) (j * inpixelsize);
            for (int i = 0; i < xpixels; i++) {
                x = (int) (i * inpixelsize);
                c = capture.get(x, y);
                pixels.add(new Pixel(c));
            }
        }
        return pixels;
    } else {
        nullframes++;
        return null;
    }
}

void saveImage() {
    SimpleDateFormat df;
    Date dateobj;
    String path;
    df = new SimpleDateFormat("yyyyMMdd'T'HHmmss");
    dateobj = new Date();
    path = basepath.concat(df.format(dateobj)).concat(".png");
    saveFrame(path);
    println("Saved to: ".concat(path));
}

void loadImages(int num, PImage[] stagedimages) {
	java.io.File folder = new java.io.File(dataPath(basepath));
 	String[] filenames = folder.list(pngFilter);
	filenames = reverse(filenames);

	int numfiles = min(num, filenames.length);
	println("Loading " + numfiles + " images . . .");

	for (int i = 0; i < numfiles; i++) {
		stagedimages[i] = requestImage(basepath.concat(filenames[i]));
	}

	imagescount = numfiles; // shorter if necc
	imagescounter = 0; 	// reset for display
}

void playImages(int num, PImage[] stagedimages, int loops) {
	if (imagescounter < num * loops) {               
		image(stagedimages[imagescounter % num],0,0);
		imagescounter++;
		playimages = true;
		playingimages = true;
	} else {
		playimages = false;
		playingimages = false;
	}
}

boolean imagesLoaded(int num) {
	for (int i = 0; i < num; i++) {
	    if ((loadedimages[i] == null) || (loadedimages[i].width == 0) || (loadedimages[i].width == -1)) {
			return false;
		}
	}
	return true;
}

final FilenameFilter pngFilter = new FilenameFilter() {
  	boolean accept(File dir, String name) {
    	return name.toLowerCase().endsWith(".png");
  	}
};

void turnOnNextCam() {
    boolean flag = true;
    while (flag) {
        flag = false;
        cap++;
        cap %= captures.length;
        captureNext = captures[cap];
        try {
            captureNext.start();
            canswitchcam = true;
        } catch (Exception e) {
            flag = true;
        }
    }
}

void switchCam() {
    capture.stop();
    capture = captureNext;
    canswitchcam = false;
}

void setResolution(int thispixelsize) {
    pixelsize = thispixelsize;
    if (pixelsize == 0)
        pixelsize = 1; 
    
    xpixels = width / pixelsize;
    ypixels = height / pixelsize;
    numpixels = xpixels * ypixels;
    println(xpixels);
    println(ypixels);
}

void keyPressed() {
    switch(key) {
        case ' ':
			if (sorttype != 10) 
				sorttype = 10;
			else 
 				sorttype = 0;
            break;
        case 'd':
            saveImage();
            break;
        case 's':
	        sorttype++;
    	    sorttype %= numsorts;
            break;
        case 'c':
            comptype++;
    	    comptype %= numcomps;
            break;
        case 'n':
			turnOnNextCam();
			if (verbose) println("** turnOnNextCam() ** " + captures.length);
            break;
        case 'm':
			if (captures.length > 1 && canswitchcam)
				switchCam();
			if (verbose) println("** switchCam() **");
            break;
        case '+':
            setResolution(pixelsize+1);
            println("pixelsize : " + pixelsize);
            break;
        case '_':
            setResolution(pixelsize-1);
            println("pixelsize : " + pixelsize);
            break;
        case '=':
            if (alpha + 1 < 255) alpha++;
            println("alpha : " + alpha);
            break;
        case '-':
            if (alpha - 1 > 0) alpha--;
            println("alpha : " + alpha);
            break;
        case 'i':
			imagescount = int(60/saveimageinterval);
			loadedimages = new PImage[imagescount];
	    	loadImages(imagescount, loadedimages);
			playimages = true;
            break;
        case 'o':
			imagescount = int(60/saveimageinterval);
			loadedimages = new PImage[imagescount];
			playimages = false;
            break;
        default:
            break;
    }
}
