import processing.core.*;

public class TextureFactory {

  PApplet parent = null;

  public TextureFactory(PApplet parent) {
    this.parent = parent;
  }
  
  
  PImage depthMapToTextureOld(int[] depthMap, float depthMaxDist, int imgWidth, int imgHeight) {

    IntWrapper min = new IntWrapper();
    IntWrapper max = new IntWrapper();

    ArrayUtils.getMinAndMaxFromIntArray(depthMap, min, max);
    int minValue = min.getInt();
    int maxValue = max.getInt();		
    

    int scaleFactor = 255 / (maxValue - minValue);

    // create image for texture
    PImage depthTextureImage = parent.createImage(imgWidth, imgHeight, PApplet.RGB);
    depthTextureImage.loadPixels();

    // set pixel color values for texture
    for (int i = 0; i < depthMap.length; i++) {

      int currValue = depthMap[i];
      
      // make sure the currValue is within our distance threshold, and if not then set it to 0
      if (currValue > depthMaxDist) {
        currValue = 0;
      }

      /* to create our color value we do the following:
      *
      * subtract min value (this makes the minimum value now 0)
      * multiply by scale factor (the scale factor is the number of times the max value goes into 255) (this now makes the max value 255)
      * we would prefer light values to be closer so we flip the scale by subtracting 255 and taking the absolute value (0 goes to 255, 255 goes to 0)  
      */					

      int colorValue = 255;
      if (currValue > 0) {
        colorValue = ((currValue - minValue) * scaleFactor);
        //colorValue = Math.abs(((currValue - minValue) * scaleFactor) - 255); // use this one if you want closer values to be lighter	
      }						

      depthTextureImage.pixels[i] = parent.color(colorValue);

    }
    
//    recomposePImage(depthTextureImage, 40, 40);

    return depthTextureImage;
  }
  
  PImage recomposePImage(PImage origImage, int windowWidth, int windowHeight) {
    for (int yOffset = 0; yOffset < origImage.height; yOffset += windowHeight) {
      for (int xOffset = 0; xOffset < origImage.width; xOffset += windowWidth) {
        PImage subImage = origImage.get(xOffset, yOffset, windowWidth, windowHeight);
        subImage.loadPixels();
        IntWrapper min = new IntWrapper();
        IntWrapper max = new IntWrapper();
        getMinAndMaxFromGrayColorArray(subImage.pixels, min, max);
        int minValue = min.getInt();
        int maxValue = max.getInt();
        
        boolean disregardPixels = false;
        if (false && maxValue - minValue < 20) {
          disregardPixels = true;
        }
        
        //parent.println("subimage(" + xOffset + ", " + yOffset + "):  " + minValue + " min, " + maxValue + " max");*/
        
        
        for (int i = 0; i < subImage.pixels.length; i++) {
          
          int currValue = 0;
          
          boolean lightCrusts = false;
          
          int redValue = (subImage.pixels[i] >> 16) & 0xFF;
          
          if (lightCrusts) {
            if (disregardPixels) {
              currValue = 0;
            } else {
              currValue = Math.abs((int)parent.map(redValue, minValue, maxValue, 0, 255) - 255);              
            }
          } else {
            if (disregardPixels) {
              currValue = 255;
            } else {
              currValue = (int)parent.map(redValue, minValue, maxValue, 0, 255);              
            }

          }
          
          subImage.pixels[i] = parent.color(currValue, currValue, currValue);
        }
        subImage.updatePixels();
        
        //parent.image(subImage, xOffset, yOffset);
        
        
        origImage.loadPixels();
        
        for (int y = 0; y < subImage.height; y++) {
          for (int x = 0; x < subImage.width; x++) {
            origImage.set(xOffset + x, yOffset + y, subImage.get(x, y));
          }
        }
        
        getMinAndMaxFromGrayColorArray(subImage.pixels, min, max);
        minValue = min.getInt();
        maxValue = max.getInt();
        
        //parent.println("subimage after update(" + xOffset + ", " + yOffset + "):  " + minValue + " min, " + maxValue + " max");
        
      }      
    }
    origImage.updatePixels();
    
    return origImage;
  }
  
  
  
  PImage depthMapToTexture(int[] depthMap, float depthMaxDist, int imgWidth, int imgHeight) {

    IntWrapper min = new IntWrapper();
    IntWrapper max = new IntWrapper();

    ArrayUtils.getMinAndMaxFromIntArray(depthMap, min, max);
    int minValue = min.getInt();
    int maxValue = max.getInt();		
    
    parent.println("minValue: " + minValue);
    parent.println("maxValue: " + maxValue);
    

    // create image for texture
    PImage depthTextureImage = parent.createImage(imgWidth, imgHeight, PApplet.RGB);
    depthTextureImage.loadPixels();

    // set pixel color values for texture
    for (int i = 0; i < depthMap.length; i++) {
      
      float mappedValue = minValue;
      
      // make sure the currValue is within our distance threshold, and if not then set it to 0
      if (depthMap[i] < depthMaxDist) {
        mappedValue = parent.map(depthMap[i], minValue, maxValue, 0, 255);  
      }
      
      depthTextureImage.pixels[i] = parent.color(mappedValue, mappedValue, mappedValue);

    }

    return depthTextureImage;
  }


  public void getMinAndMaxFromGrayColorArray(int[] array, IntWrapper min, IntWrapper max) {

    int minValue       = 0;
    int maxValue       = 0;

    for (int i         = 0; i < array.length; i++) {
      int currValue  =  (array[i] >> 16) & 0xFF; // extract red value

      // set the minValue at the lowest non-zero value 
      if (minValue == 0 && currValue > 0) {
        minValue          = currValue;
      }

      if (i == 0) {
        maxValue          = currValue;
        } else {

          if (currValue < minValue && currValue > 0) {
            minValue      = currValue;
          }
          if (currValue > maxValue) {
            maxValue      = currValue;
          }
        }
      }

      min.setInt(minValue);
      max.setInt(maxValue);					
    }

  
}


