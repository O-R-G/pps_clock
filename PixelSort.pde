public class PixelSort
{
    private int xpixels;
    private int ypixels;
    
    public PixelSort(int xpixels, int ypixels)
    {
        this.xpixels = xpixels;
        this.ypixels = ypixels;
    }
    public ArrayList<Pixel> sort(ArrayList<Pixel> plist, int ctype, int stype)
    {
        ArrayList<Pixel> sorted = plist;
        
        switch (ctype % 3)
        {
            case 0:
                comp = new HueComparator();
                break;
            case 1:
                comp = new SaturationComparator();
                break;
            case 2:
                comp = new BrightnessComparator();
                break;
        }
        
        switch (stype % 7)
        {
            case 0:
                break;
            case 1:
                Collections.sort(sorted, comp);
                break;
            case 2:
                sorted = this.sortRows(sorted, comp);
                break;
            case 3:
                sorted = this.sortCols(sorted, comp);
                break;
            case 4:
                sorted = this.sortRows(sorted, comp);
                sorted = this.sortCols(sorted, comp);
                break;
            case 5:
                sorted = this.sortCols(sorted, comp);
                sorted = this.sortRows(sorted, comp);
                break;
            case 6:
                sorted = this.knuthShuffle(sorted);
                break;
        }

        return sorted;
    }
    
    protected ArrayList<Pixel> sortRows(ArrayList<Pixel> plist, PixelComparator comp)
    {
        ArrayList<Pixel> sorted, row;
        sorted = new ArrayList<Pixel>();
    
         for (int j = 0; j < ypixels; j++)
         {
            row = new ArrayList<Pixel>();
        
            for (int i = 0; i < xpixels; i++)
                row.add(plist.get(j * xpixels + i));
            
            Collections.sort(row, comp);
            sorted.addAll(row);
         }
     
         return sorted;
    }

    protected ArrayList<Pixel> sortCols(ArrayList<Pixel> plist, PixelComparator comp)
    {
        ArrayList<ArrayList<Pixel>> columns;
        ArrayList<Pixel> sorted, col;
    
        sorted = new ArrayList<Pixel>();
        columns = new ArrayList<ArrayList<Pixel>>();
    
         for (int j = 0; j < xpixels; j++)
         {
            col = new ArrayList<Pixel>();
        
            for (int i = 0; i < ypixels; i++)
                col.add(plist.get(i * xpixels + j));
        
            Collections.sort(col, comp);
        
            columns.add(col);
         }
     
         for (int i = 0; i < columns.get(0).size(); i++)
         {
            for (int j = 0; j < columns.size(); j++)
            {
                sorted.add(columns.get(j).get(i));
            }
         }
     
         return sorted;
    }
    
    protected ArrayList<Pixel> knuthShuffle(ArrayList<Pixel> pixels)
    {
        int min, max;
        min = 0;
        max = pixels.size();
        for (int i = max; i > min; i--)
        {
            int j = int(random(min, max));
            Collections.swap(pixels, j, i-1);
        }
        return pixels;
    }
}
