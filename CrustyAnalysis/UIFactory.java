import processing.core.*;
import java.util.HashMap;
import org.json.*;
import controlP5.*;

public class UIFactory {

  PApplet parent = null;
  ControlP5 cp5;
  
  // JSON Config object
  JSONObject config;

  public UIFactory(PApplet parent, ControlP5 cp5) {
    this.parent = parent;
    this.cp5 = cp5;
  }
  
  public void readJSONConfig(String fileName) {

    // populate global JSONConfig object
    String[] configStrings = parent.loadStrings(fileName);
    if (configStrings != null && configStrings.length > 0) {

      try {
        String joinedConfig = parent.join(configStrings, "\r");

        this.config = new JSONObject(joinedConfig);
      } catch (JSONException e) {
        parent.println ("There was an error parsing the JSONObject  : " + e);
      }		
    }
  }
  
  
  
  /**
    HashMap containing <String, HashMap> key value pair that correspond to:  <GroupName, UIGroup Array>
    (each element in the UIGroup Array is a hashmap that contains GUIGroupType value with key "type", 
    an the individual GUI elements indexed under their GUI name
  */
  public HashMap UIGroupsForCurrentConfigFile() {
    return null;
  }
   
}
  
/*

public enum GUIGroupType {
Slider,
SliderBoolean,  // <SliderNameOn>
Text,
TextButton, // <onTextName>
Button // <onButtonName>
}

*/