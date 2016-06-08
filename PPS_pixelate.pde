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

int cap = 0;
int camSwitchInterval = 15; // units = minutes
boolean canSwitchCam = false;

int saveImageLastMin = -1;
int saveImageInterval = 1;

int sortSwitchInterval = 10;
int sortSwitchLastMin = -1;

int compSwitchInterval = 5;
int compSwitchLastMin = -1;

boolean usb;                        // usb cam
boolean hsb;                        // enforce HSB color model

int numpixels, ypixels, xpixels;

int outpixelsize = 6;
int inpixelsize = 4;
int pixelsize = 6;
int pixelstep = 1;

int alpha = 100;                     // [0-255]
int count = 0;

int sorttype = 1;
int comptype = 0;

int numSorts = 7;
int numComps = 3;

boolean camStarted = false;
int nullFrames = 0;

String movsrc = "basement.mov";

PixelSort pixelsort;
PixelComparator comp;

PImage[] loadedimages;

int imagescount;
int imagescounter;

void setup()
{
    frameRate(30);
    noStroke();
    background(0);
	noCursor();

    // start the cameras
    if (usb)
    {
        try 
        {
            println("Using usb camera . . . ");
            capture = captures[cap];
            capture.start();
        } 
        catch (Exception e) 
        {
            usb = false;
            e.printStackTrace();
            printArray(Capture.list()); 
        }
    } 
    else
    {
        println("Using local mov . . . ");
        mov = new Movie(this, movsrc);
        mov.loop();
        mov.read();
        surface.setSize(mov.width, mov.height);
    }

	imagescount = int(60/saveImageInterval);
	loadedimages = new PImage[imagescount];

    setResolution(pixelsize);
    pixelsort = new PixelSort(xpixels, ypixels);
}

ArrayList<Pixel> getPixels(Capture capture)
{
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int x, y;
    color c;
    
    if (capture.available())
    {
        nullFrames = 0;
        capture.read();
    
        for (int j = 0; j < ypixels; j++)
        {
            y = (int) (j * inpixelsize);
            for (int i = 0; i < xpixels; i++)
            {
                x = (int) (i * inpixelsize);
                c = capture.get(x, y);
                pixels.add(new Pixel(c));
            }
        }
        return pixels;
    }
    else
    {
        nullFrames++;
        return null;
    }
}

ArrayList<Pixel> getPixelsFromMov(Movie mov)
{
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int x, y;
    color c;
    
    if (mov.available())
        mov.read();
    
    for (int j = 0; j < ypixels; j++)
    {
        y = (int) (j * pixelsize);
        for (int i = 0; i < xpixels; i++)
        {
            x = (int) (i * pixelsize);
            c = mov.get(x, y);
            pixels.add(new Pixel(c));
        }
    }
    
    return pixels;
}

void draw()
{
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int m, s;
    
    m = minute();
    s = second();
    count++;
    
    // switch cameras
    if (usb)
    {  
        if (captures.length > 1 && m % camSwitchInterval == 0 && canSwitchCam)
        {
            switchCams();
        }
        
        // start the next camera 20 seconds early
        if (!canSwitchCam && (m % camSwitchInterval == camSwitchInterval - 1) && (s > 40))
        {
            turnOnNextCam();
        }
        
        pixels = getPixels(capture);
    }
    else
    {
        pixels = getPixelsFromMov(mov);
    }
    
    // switch sort every compSwitchInterval minutes
    // choose random sort
    if (m % sortSwitchInterval == 0 && sortSwitchLastMin != m)
    {
        // choose random sort
        sorttype = int(random(0, numSorts));
        sortSwitchLastMin = m;
    }

    // switch comps every compSwitchInterval minutes        
    if (m % compSwitchInterval == 0 && compSwitchLastMin != m)
    {
        // choose random pixelcomp
        comptype = int(random(0, numComps));
        compSwitchLastMin = m;
    }
    
    if (pixels != null)
    {
        // sort!
        pixels = pixelsort.sort(pixels, comptype, sorttype);

        // display
        for (int j = 0; j < ypixels; j++) {
            for (int i = 0; i < xpixels; i++) {
                int index = (j * xpixels + i) % numpixels;
                color c = pixels.get(index).getColor();

                // rgb 
                // fill(red(c), green(c), blue(c), alpha);

                // hsb, max s, b
				// colorMode(HSB, 255);
				// fill(hue(c), 255, 255, alpha);

                // map hsb -> rgb
                fill(hue(c), saturation(c), brightness(c), alpha);

                rect(i*pixelsize, j*pixelsize, pixelsize, pixelsize);
            }
        }
    
        // save a frame every saveImageInterval minutes
        if ((m % saveImageInterval == 0) && (m != saveImageLastMin) && s == 30)
        {
            saveImage();
            saveImageLastMin = m;		
        }

		// ** dev **
		// can even read these into pixels array perhaps
		// and should move up in the draw loop
		// so that it is not drawing on top of the other
		// how to handle timing ?
		// or alternately, save states and replay from that

		if (imagesloaded(imagescount)) 
		{
			// draw images in sequence
			image(loadedimages[imagescounter % imagescount],0,0);	
			println("loadedimages " + imagescounter % imagescount);
			imagescounter++;
		}

        camStarted = true;
    }
    else if (nullFrames > 10 && camStarted)
    {
        turnOnNextCam();
        switchCams();
        camStarted = false;
    }
}

void turnOnNextCam()
{
    boolean flag = true;
    while (flag)
    {
        flag = false;
        cap++;
        cap %= captures.length;
        captureNext = captures[cap];
        // make sure next camera is available
        try {
            captureNext.start();
            canSwitchCam = true;
        }
        // move on to the next-next
        catch (Exception e) {
            flag = true;
        }
    }
}

void switchCams()
{
    capture.stop();
    capture = captureNext;
    canSwitchCam = false;
}

void saveImage()
{
    SimpleDateFormat df;
    Date dateobj;
    String path;
    
    df = new SimpleDateFormat("yyyyMMdd'T'HHmmss");
    dateobj = new Date();
    
    path = basepath.concat(df.format(dateobj)).concat(".png");
    saveFrame(path);
    println("Saved to: ".concat(path));
}

void loadImages(int num, PImage[] stagedimages)
{
	// loadedimages is an array passed as a pointer no need to return value

	java.io.File folder = new java.io.File(dataPath(basepath));
 	String[] filenames = folder.list(pngFilter);
	filenames = reverse(filenames);		// last modified
	for (int i = 0; i < num; i++) 
	{
		stagedimages[i] = requestImage(basepath.concat(filenames[i]));
	}
	println("Loading images . . .");
}

boolean imagesloaded(int num)
{
	for (int i = 0; i < num; i++) 
	{
	    if ((loadedimages[i] == null) || (loadedimages[i].width == 0) || (loadedimages[i].width == -1))
			return false;
	}	
	return true;
}

final FilenameFilter pngFilter = new FilenameFilter() 
{
  	boolean accept(File dir, String name) 
	{
    	return name.toLowerCase().endsWith(".png");
  	}
};

void setResolution(int thispixelsize)
{
    pixelsize = thispixelsize;
    if (pixelsize == 0)
        pixelsize = 1; 
    
    xpixels = width / pixelsize;
    ypixels = height / pixelsize;
    numpixels = xpixels * ypixels;
    println(xpixels);
    println(ypixels);
}

void keyPressed()
{
    switch(key)
    {
        case ' ':
            hsb = !hsb;
            if (hsb)
                colorMode(HSB, 255);
            if (!hsb)
                colorMode(RGB, 255);
            break;
        case 'd':
            saveImage();
            break;
        case 's':
            sorttype++;
            break;
        case 'c':
            comptype++;
            break;
        case '+':       // pixelsize++
            setResolution(pixelsize+1);
            println("pixelsize : " + pixelsize);
            break;
        case '_':       // pixelsize--
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
			loadedimages = new PImage[imagescount];
	    	loadImages(imagescount, loadedimages);
            break;
        case 'o':
			loadedimages = new PImage[imagescount];
            break;
        default:
            break;
    }
}
