public class Pixel implements Comparable<Pixel> {
    private color c;
    // private int index;
    
    public Pixel(color c) {
        this.c = c;
        // this.index = index;
    }
    
    public color getColor() {
        return c;
    }

    public void setColor(color newc) {
        this.c = newc;
    }
    
    // basic compareTo 
    public int compareTo(Pixel other) {
        return this.c - other.getColor();
    }
}

public class PixelComparator implements Comparator<Pixel> {
    public static final float EPSILON = 0.001;
    
    public int compare(Pixel p1, Pixel p2) {
        return p1.compareTo(p2);
    }
}

// compare colours based on hue
public class HueComparator extends PixelComparator {
    public int compare(Pixel v1, Pixel v2) {
        float b1, b2;
        b1 = hue(v1.getColor());
        b2 = hue(v2.getColor());
        if(Math.abs(b1 - b2) < EPSILON)
            return 0;
        else if (b1 < b2)
            return -1;
        else
            return 1;
    }
}

// compare colours based on saturation
public class SaturationComparator extends PixelComparator {
    public int compare(Pixel v1, Pixel v2) {
        float b1, b2;
        b1 = saturation(v1.getColor());
        b2 = saturation(v2.getColor());
        if(Math.abs(b1 - b2) < EPSILON)
            return 0;
        else if (b1 < b2)
            return -1;
        else
            return 1;
    }
}

// compare colours based on brightness
public class BrightnessComparator extends PixelComparator {
    public int compare(Pixel v1, Pixel v2) {
        float b1, b2;
        b1 = brightness(v1.getColor());
        b2 = brightness(v2.getColor());
        if(Math.abs(b1 - b2) < EPSILON)
            return 0;
        else if (b1 < b2)
            return -1;
        else
            return 1;
    }
}

