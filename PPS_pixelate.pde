// Public Private Secret Clock
// O-R-G

// ** todo ** write sort
// ** todo ** sort using bit shifting to get specific color values
// ** todo ** implement byte reader
// ** todo ** examine asdf pixelsort
// ** todo ** exchange random image rows?

// build array which maps pixel locations
// reset that map to show regular positions
// could be dynamically resized

import processing.video.*;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.text.SimpleDateFormat;

Movie mov;
Capture[] captures;
Capture capture;
Capture captureNext;
int cap = 0;
int camSwitchInterval = 5; // units = minutes
boolean canSwitchCam = false;

boolean usb;                        // usb cam
boolean hsb;                        // enforce HSB color model
boolean shiftarray;                 // linear shift, ring buffer
boolean knuthshuffle;               // shuffle pixels

int numpixels, ypixels, xpixels;

int outpixelsize = 6;
int inpixelsize = 4;
int pixelsize = 6;
int pixelstep = 1;

int sortprogress;
int alpha = 50;                     // [0-255]
int shiftarrayamt;
int count = 0;
int sorttype = 0;
int comptype = 0;

float scale = 1.0;             // scale video input
float sortspeed = 100.0;

String movsrc = "basement.mov";
String basepath = "/Users/lily/Dropbox/shared/clock-images/";

PixelSort pixelsort;
PixelComparator comp;

// dynamically set the size because I CAN.
public void settings()
{
    int w, h;
    
    try 
    {
        usb = true;
        
        // add cameras to capture list
        // make sure captures array is the correct length!
        captures = new Capture[3];
        captures[0] = new Capture(this, "name=HD USB Camera,size=1296x972,fps=30");
        captures[1] = new Capture(this, "name=FaceTime HD Camera (Built-in),size=1280x720,fps=30");
        captures[2] = new Capture(this, "name=FaceTime HD Camera (Built-in),size=320x180,fps=30");
//         captures[1] = new Capture(this, "name=HD USB Camera #2,size=1296x972,fps=30");
//         captures[2] = new Capture(this, "name=HD USB Camera #3,size=1296x972,fps=30");
//         captures[3] = new Capture(this, "name=HD USB Camera #4,size=1296x972,fps=30");
//         captures[1] = new Capture(this, "name=FaceTime HD Camera,size=320x180,fps=30");
    } 
    catch (Exception e) 
    {
        usb = false;
        e.printStackTrace();
        w = 640;
        h = 360;
    }
    
    // size(1280,720);
    // size(1296,972);
    // size(2560, 1440);
    size(1920, 1080);
}

void setup()
{
    frameRate(60);
    noStroke();
    background(0);

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

    setResolution(pixelsize);
    pixelsort = new PixelSort(xpixels, ypixels);
}

ArrayList<Pixel> getPixels(Capture capture)
{
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int x, y;
    color c;
    
    if (capture.available())
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

ArrayList<Pixel> getPixelsFromMov(Movie mov)
{
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int x, y;
    color c;
    
    if (mov.available())
        mov.read();
    
    for (int j = 0; j < ypixels; j++)
    {
        y = (int) (j * pixelsize * scale);
        for (int i = 0; i < xpixels; i++)
        {
            x = (int) (i * pixelsize * scale);
            c = mov.get(x, y);
            pixels.add(new Pixel(c));
        }
    }
    
    return pixels;
}

void draw()
{
    ArrayList<Pixel> pixels;
    
    count++;
    
    // switch cameras
    if (usb && canSwitchCam && (minute() % camSwitchInterval == 0) && captures.length > 1)
    {  
        capture.stop();
        capture = captureNext;
        canSwitchCam = false;
    }
    
    // use movie if camera not available
    if (usb)
        pixels = getPixels(capture);
    else
        pixels = getPixelsFromMov(mov);

    // adjust pixels
    if (sortprogress < numpixels - 1) 
        sortprogress += sortspeed;
    
    // sort!
    pixels = pixelsort.sort(pixels, comptype, sorttype);

    if (shiftarray)
    {
        shiftarrayamt += 1;
    }

    if (knuthshuffle)
    {
        knuthShuffle(pixels, 0, sortprogress);
    } 

    // display
    for (int j = 0; j < ypixels; j++) {
        for (int i = 0; i < xpixels; i++) {
            int index = (j * xpixels + i + shiftarrayamt) % numpixels;
            color c = pixels.get(index).getColor();

            // rgb 
            // fill(red(c), green(c), blue(c), alpha);

            // hsb, max s, b
            // colorMode(HSB, 255);
            // fill(hue(c), 255, 255, alpha);

            // map hsb -> rgb
            fill(hue(c), saturation(c), brightness(c), alpha);

            rect(i*pixelsize*scale, j*pixelsize*scale, pixelsize*scale, pixelsize*scale);
        }
    }
    
    if (usb && (!canSwitchCam) && (minute() % camSwitchInterval == camSwitchInterval - 1) && (second() > 40))
    {
        cap++;
        cap %= captures.length;
        captureNext = captures[cap];
        captureNext.start();
        canSwitchCam = true;
        
        saveImage();
    }
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

void knuthShuffle(ArrayList<Pixel> pixels, int min, int max)
{
    for (int i = max; i > min; i--)
    {
        int j = int(random(min, max));
        Collections.swap(pixels, j, i-1);
    }
}

public int shiftArray(int[] array, int amt, int offset)
{
    // either:  
    // 1. assign global shift amt, which is incremented and % when read
    // 2. arrayCopy to modify pixelmap

    // splice last amt items into beginning of the array
    // shorten the array by amt
    // acting directly on array, so no need to return any value

    offset += amt;

/*
    for (int i = 0; i < pixels/8; i++) {
        int tmp = array[i]; // get discrete value
        println(tmp);
        array = splice(array, tmp, 0);
        println(array);
        // ** fix ** can also splice in arrays in total
        // see https://processing.org/reference/splice_.html
        // array = splice(array, array[10], 0);
        array = shorten(array);
        println(array.length);
        exit();
    }
*/

    shiftarray = true;
    return offset;
}

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
        case 'k':  
            knuthshuffle = !knuthshuffle;
            sortprogress = 0;
            break;
        case 'h':
            shiftarray = !shiftarray;
            sortprogress = 0;
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
        default:
            break;
    }
}