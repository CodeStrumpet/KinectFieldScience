import org.json.*;
import processing.core.*;

public class ArrayUtils {

  public static int[] getIntArrayFromJSONArray(JSONArray jsonArray) {
    try {
      int[] newArray = new int[jsonArray.length()];

      for (int i     = 0; i < jsonArray.length(); i++) {
        int currValue     = ((Integer)jsonArray.get(i)).intValue();

        // store value in global array for additional operations later
        newArray[i]       = currValue;
      }

      return newArray;

      } catch (JSONException e) {
        return null;
      } 
    }

    public static void getMinAndMaxFromIntArray(int[] array, IntWrapper min, IntWrapper max) {

      int minValue       = 0;
      int maxValue       = 0;

      for (int i         = 0; i < array.length; i++) {
        int currValue  = array[i];

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

