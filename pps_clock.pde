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

int cap;
int numpixels, ypixels, xpixels;
int pixelsize = 4;

int alpha = 100; // [0-255]
int sorttype;
int comptype;
int nullframes;
int numsorts = 6;
int numcomps = 2;
int imagesmax = 60; // #/hr
int imagescount;
int imagescounter;
int lasth;
int lastm;
int lasts;
int lastsdebug;

boolean rgb;
boolean canswitchcam;
boolean playimages;
boolean playingimages;
boolean sort;

boolean histogram = true;
boolean adjustcolors = true;

boolean debug = true;
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

    sort = true;
    imagescount = imagesmax;
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
    
   	// lasth = checkHour(h, lasth);
	// lastm = checkMin(m, lastm);
    // lasts = checkSec(s, lasts);

    // use `date mmddHHMMyy.ss`
    // set 1" = 1' --> lasts = checkMin(s,lasts);
    // set 1' = 1 hr --> lastm = checkHour(m,lastm);

   	lastm = checkHour(m % 12, lastm);
    lasts = checkMin(s, lasts);

    if (debug && s != lastsdebug && verbose) {
        println(nf(h,2) + ":" + nf(m,2) + ":" + nf(s,2));	
        println("> " + nf(m % 12,2) + ":" + nf(s,2));
        println("(" + cap + ") " + sorttype + "," + comptype);
        // println("(" + capture + ")");
    }

	if (playimages) 
		if (imagesLoaded(imagescount))
			playImages(imagescount, loadedimages, 1);

	if (!playingimages) 
    	pixels = getPixels(capture);

    if (nullframes > 30)
        pixels = makePixels();

    if (pixels != null && !playingimages) {
        if (histogram)
            displayHistogram(pixels, 2, 100, 100);
        if (adjustcolors)
            adjustColorsEnvelope(pixels, random(255)*.01);
        if (sort)
            pixels = pixelsort.sort(pixels, comptype, sorttype);
        for (int j = 0; j < ypixels; j++) {
            for (int i = 0; i < xpixels; i++) {
                int index = (j * xpixels + i) % numpixels;
                color c = pixels.get(index).getColor();
    	        fill(hue(c), saturation(c), brightness(c), alpha); 
				rect(i*pixelsize, j*pixelsize, pixelsize, pixelsize);
            }
        }
    }
    if (debug)    
        lastsdebug = s;
}


// timers

int checkHour(int thish, int thislasth) {
	if (thish != thislasth) {
    	switch (thish) {
			case 0:
				sorttype = 0;
				comptype = 0;	
                thislasth = thish;
				break;
			case 12:
				sorttype = 0;
				comptype = 1;	
                thislasth = thish;
				break;
			case 6:
			case 18:
				sorttype = 0;
				comptype = 0;	
                thislasth = thish;
				break;
			case 1:
			case 7:
			case 13:
			case 19:
				sorttype = 1;
                thislasth = thish;
				break;
			case 2:
			case 8:
			case 14:
			case 20:
				sorttype = 2;
                thislasth = thish;
				break;
			case 3:
			case 9:
			case 15:
			case 21:
				sorttype = 3;
                thislasth = thish;
				break;
			case 4:
			case 10:
			case 16:
			case 22:
				sorttype = 4;
                thislasth = thish;
				break;
			case 5:
			case 11:
			case 17:
			case 23:
				sorttype = 5;
                thislasth = thish;
				break;
        	default:
				break;
		}
	}
	return thislasth;
}

int checkMin(int thism, int thislastm) {
	if (thism != thislastm) {
    	switch (thism) {
	   		case 0:
 				switchCam();
                sort = false;
                playimages=true;
				if (verbose) println("+ " + thism);
				thislastm = thism;
            	break;
			case 5: 
                sort = true;
				if (verbose) println("+ " + thism);
				thislastm = thism;
 				break;
			case 14: 
			case 29: 
			case 44:
				turnOnNextCam();
				if (verbose) println("+ " + thism);
				thislastm = thism;
				break;
			case 15: 
			case 30: 
			case 45:
				switchCam();
				if (verbose) println("+ " + thism);
				thislastm = thism;
				break;
			case 59:
				turnOnNextCam();
				loadedimages = new PImage[imagesmax];
				loadImages(imagesmax, loadedimages);
				if (verbose) println("+ " + thism);
				thislastm = thism;
            	break;
            default:
				break;
		}
	}
	return thislastm;
}

int checkSec(int thiss, int thislasts) {
	if (thiss != thislasts) {
    	switch (thiss) {
			case 30: 
				// save image
				saveImage();
                if (verbose) println("+ " + thiss);
                thislasts = thiss;
				break;
        	default:
				break;
		}
	}
	return thislasts;
}


// capture

ArrayList<Pixel> getPixels(Capture capture) {
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int x, y;
    color c;
    if (capture.available()) {
        nullframes = 0;
        capture.read();
        for (int j = 0; j < ypixels; j++) {
            y = (int) (j * pixelsize);
            for (int i = 0; i < xpixels; i++) {
                x = (int) (i * pixelsize);
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

ArrayList<Pixel> makePixels() {
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int x, y;
    color c;
        
    for (int j = 0; j < ypixels; j++) {
        y = (int) (j * pixelsize);
        for (int i = 0; i < xpixels; i++) {
            x = (int) (i * pixelsize);
            c = color(int(random(50)), int(random(50)), int(random(50)));
            pixels.add(new Pixel(c));
        }
    }
    return pixels;
}

void turnOnNextCam() {
    if (!canswitchcam && captures.length > 1) {
        boolean flag = true;
        while (flag) {
            flag = false;
            cap++;
            cap %= captures.length;
            captureNext = captures[cap];
            try {
                captureNext.start();
            } catch (Exception e) {
                if (verbose) println("exception " + e);
                flag = true;
            }
        }
        if (verbose) println("++ turnOnNextCam() --> " + cap);
        canswitchcam = true;
    }
}

void switchCam() {
    if (canswitchcam) {
        capture.stop();
        capture = captureNext;
        if (verbose) println("++ switchCam() --> " + capture);
        canswitchcam = false;
    }
}


// images

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
	if (verbose)
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
	    if (loadedimages[i].width == -1) {
            if (verbose) println("++ error reading image " + i);
            imagescount = i;
            return true;
        }
	    if ((loadedimages[i] == null) || (loadedimages[i].width == 0)) 
			return false;
	}
	return true;
}

final FilenameFilter pngFilter = new FilenameFilter() {
  	boolean accept(File dir, String name) {
    	return name.toLowerCase().endsWith(".png");
  	}
};


// utility

void setResolution(int thispixelsize) {
    pixelsize = thispixelsize;
    if (pixelsize == 0)
        pixelsize = 1; 
    xpixels = width / pixelsize;
    ypixels = height / pixelsize;
    numpixels = xpixels * ypixels;    
    pixelsort = new PixelSort(xpixels, ypixels);
    println(xpixels + " x " + ypixels);
}

void displayHistogram(ArrayList<Pixel> thispixels, int resolution, int xpos, int ypos) {
    int[] histogram = new int[256];
    for (int i = 0; i < thispixels.size(); i++) {
        color c = thispixels.get(i).getColor();
        int b = int(brightness(c));
        histogram[b]++;
    }
    int histogramMax = max(histogram);
    stroke(255);
    for (int i = 0; i < xpixels; i += resolution) {
        int which = int(map(i, 0, xpixels, 0, 255));
        int y = int(map(histogram[which], 0, histogramMax, ypixels, 0));
        line(xpos + i, ypos + ypixels, xpos + i, ypos + y);
    }
    noStroke();
}




void adjustColorsEnvelope(ArrayList<Pixel> thispixels, float stubx) {

    // adjust colors envelope
    // adjust color values using sin(x/512-1)
    // send the value to that function and return new
    // which shifts mid-range values more than the ends

    // gaussian distribution function
    // https://en.wikipedia.org/wiki/Gaussian_function

    float a = 1/TWO_PI; // ?
    float b = 1;        //
    float c = 1;        // 
    float e = 1;        // 
 
    float x = random(100000);

    float gaussian = a * pow(e,-(pow(x-b,2) / 2 * pow(c,2)));
    println("=== " + gaussian);

/*
    int[] histogram = new int[256];
    for (int i = 0; i < thispixels.size(); i++) {
        // color c = thispixels.get(i).getColor();
        color c = color(100,100,100);
        thispixels.get(i).setColor(c);
        // int b = int(brightness(c));
        // histogram[b]++;
    }
*/
}






void keyPressed() {
    switch(key) {
        case ' ':
            sort = !sort;
            break;
        case 'a':
            adjustcolors = !adjustcolors;
            break;
        case 'r':
            rgb = !rgb;
            if (rgb) 
                colorMode(RGB);
            else 
                colorMode(HSB);
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
            break;
        case 'm':
			switchCam();
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
			loadedimages = new PImage[imagesmax];
	    	loadImages(imagesmax, loadedimages);
			playimages = true;
            break;
        case 'o':
			imagescount = 60;
			loadedimages = new PImage[imagescount];
			playimages = false;
            break;
        default:
            break;
    }
}
