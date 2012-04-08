import SimpleOpenNI.*;
import com.sun.image.codec.jpeg.*;
import hypermedia.video.*;
import java.awt.image.BufferedImage;
import org.json.*;
import unlekker.util.*;
import unlekker.modelbuilder.*;
import processing.opengl.*;


SimpleOpenNI  context; 
OpenCV opencv;

int maxZ = 2000;
int spacing = 3;
UGeometry model;
UVertexList vertexList;

PFont f;
int windowWidth = 0; 
int windowHeight = 0;
int imageRegionPadding = 10;
int textRegionHeight = 300;
String debugLog = "";

final String OUTPUT_DIRECTORY = "data\\output\\PostZZYZX";
final String INPUT_DIRECTORY = "data\\output";

final String SITE_ID_KEY = "siteID";
final String USE_SENSOR_CAPTURE_STREAM = "useSensorCaptureStream  ('/')";
final String UPDATE_SOURCE_IMAGE = "updateSourceImage  (']')";
final String DEPTH_MAX_DIST_KEY = "depthMaxDist  ('<' , '>')";
final String DEPTH_THRESHOLD_KEY = "depthThreshold (':' , '\"')";
final String RGB_THRESHOLD_KEY = "rgbThreshold  ('-' , '+')";
final String ENABLE_OPEN_CV = "enableOpenCV  ('~')";
final String MIN_BLOB_AREA_KEY = "minBlobArea";
final String FILL_IN_BLOBS_KEY = "fillInBlobs ('[')";
final String ENABLE_MESH_CONSTRUCTION = "enableMeshConstruction ('%')";

String[] adjustmentVariableNames = {SITE_ID_KEY, USE_SENSOR_CAPTURE_STREAM, UPDATE_SOURCE_IMAGE, DEPTH_MAX_DIST_KEY, DEPTH_THRESHOLD_KEY, RGB_THRESHOLD_KEY, ENABLE_OPEN_CV, MIN_BLOB_AREA_KEY, FILL_IN_BLOBS_KEY, ENABLE_MESH_CONSTRUCTION};

String currSiteID = "";
boolean useSensorCaptureStream = false;
boolean updateSourceImage = true;
float depthMaxDist = 0.0;
float depthThreshold = 0.0;
float rgbThreshold = 0.0;
boolean enableOpenCV = false;
float minBlobArea = 0.0;
boolean fillInBlobs = false;
boolean enableMeshConstruction = false;

boolean canUseConnectedSensor = true;
PImage sourceImage = null;
PImage depthTextureImage = null;
int[] sourceDepthPixels = null;

void setup()
{

    // set default values
    setDefaultAdjustmentVariableValues();

    // create kinect context
    context = new SimpleOpenNI(this);

    // create OpenCV instance
    opencv = new OpenCV(this);

    // mirror is by default
    // mirror is by default enabled
    context.setMirror(true);

    // enable lining up depth and rgb data
    context.alternativeViewPointDepthToImage();

    // enable depthMap generation 
    if(context.enableDepth() == false) {
	println("Can't open the depthMap, maybe the camera is not connected!");
	canUseConnectedSensor = false;
    }

    if(context.enableRGB() == false) {
	println("Can't open the rgbMap, maybe the camera is not connected or there is no rgbSensor!");
	canUseConnectedSensor = false;
    }

    // create buffer for openCV
    opencv.allocate(640, 480);

    // setup model and vertexList for mesh
    model = new UGeometry();
    vertexList = new UVertexList();


    // setup window
    windowWidth = context.depthWidth() + context.rgbWidth() + imageRegionPadding;
    windowHeight = context.rgbHeight() + textRegionHeight; 
	
    if (windowWidth == imageRegionPadding) {
	windowWidth += 640 * 2;
    }
    if (windowHeight == textRegionHeight) {
	windowHeight += 480;
    }

    size(windowWidth, windowHeight, OPENGL);
}

void draw()
{
    if (useSensorCaptureStream) {
	// update the cam
	context.update();

	background(200,0,0);

	if (enableOpenCV) {
	    // copy depth data into opencv buffer
	    opencv.copy(context.depthImage(), 0, 0, 640, 480, 0, 0, 640, 480);
			
	    // process and render depth data
	    processDepthDataInCurrentOpenCVBuffer();
	
	    // copy rgb data into opencv buffer
	    opencv.copy(context.rgbImage(), 0, 0, 640, 480, 0, 0, 640, 480);
			
	    // process and render RGB data
	    processRGBDataInCurrentOpenCVBuffer();

	} else {
	    // add modelbuilder flag
		    
	    // draw depthImageMap
	    image(context.depthImage(),0,0);			

	    // draw irImageMap
	    image(context.rgbImage(),context.depthWidth() + 10,0);	
	}  

    } else {
	// load image if necessary
	if (updateSourceImage) {
	    sourceImage = loadImage(INPUT_DIRECTORY + "//" + currSiteID + "\\combined_images_" + currSiteID + ".jpg");
	    updateSourceImage = false;
	    println(sourceImage == null ? "failed to load sourceImage" : "loaded source image");
			
			
	    // Now replace the source image depth texture with one we create from the raw depth data
	    String[] rawDepthStrings = loadStrings(INPUT_DIRECTORY + "//" + currSiteID + "\\depth.json");
	    if (rawDepthStrings != null && rawDepthStrings.length > 0) {
				
		int minValue = 0;
		int maxValue = 0; 
				
		// pull raw depth height map out of JSON data
		try {
		    JSONObject depthData = new JSONObject(rawDepthStrings[0]); 
		    JSONArray depthMap = depthData.getJSONArray("depth_map");
					
		    println("Number of elements in depthMap:  " + depthMap.length());
					
					
		    for (int i = 0; i < depthMap.length(); i++) {
			int currValue = ((Integer)depthMap.get(i)).intValue();
						
			// set the minValue at the lowest non-zero value 
			if (minValue == 0 && currValue > 0) {
			    minValue = currValue;
			}
						
			if (i == 0) {
			    maxValue = currValue;
			} else {
							
			    if (currValue < minValue && currValue > 0) {
				minValue = currValue;
			    }
			    if (currValue > maxValue) {
				maxValue = currValue;
			    }
			}
		    }
					
		    println("DepthMap minValue: " + minValue + "  maxValue: " + maxValue);
					
		    int scaleFactor = 255 / (maxValue - minValue);
					
		    // create image for texture
		    depthTextureImage = createImage(640, 480, RGB);
		    depthTextureImage.loadPixels();
					
		    // set pixel color values for texture
		    for (int i = 0; i < 640 * 480; i++) {
						
			int currValue = ((Integer)depthMap.get(i)).intValue();
						
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
						
			depthTextureImage.pixels[i] = color(colorValue, colorValue, colorValue);
		    }
		    depthTextureImage.updatePixels();
					
		} catch (JSONException e) {
		    println ("There was an error parsing the JSONObject.");
		}												
	    } else {
		println("Failed to load raw depth strings");
	    }
									
	}

	// use it if we've got it
	if (sourceImage != null) {
			
	    if (enableOpenCV) { // process source image with openCV
				
				// copy depth data into opencv buffer
		if (depthTextureImage != null) {					
		    opencv.copy(depthTextureImage, 0, 0, 640, 480, 0, 0, 640, 480);
		} else {
		    opencv.copy(sourceImage, 0, 0, 640, 480, 0, 0, 640, 480);
		}
				
				
		// process and render depth data
		processDepthDataInCurrentOpenCVBuffer();
				
		// copy rgb data into opencv buffer
		opencv.copy(sourceImage, 640 + imageRegionPadding, 0, 640, 480, 0, 0, 640, 480);
				
		// process and render rgb data
		processRGBDataInCurrentOpenCVBuffer();
				
	    } else { // just draw the current source image
		image(sourceImage, 0, 0);		
				
		// draw depthTextureImage on top if it is present
		if(depthTextureImage != null) {
		    image(depthTextureImage, 0, 0);
		}
	    }			
	}
    }

    // draw adjustment variables
    drawAdjustmentVariablesRegion();
}

void processDepthDataInCurrentOpenCVBuffer() {
	
    opencv.threshold(depthThreshold);
	
    image(opencv.image(), 0, 0, 640, 480);

    Blob blobs[] = opencv.blobs(10, width*height/2, 100, true, OpenCV.MAX_VERTICES*4 );
    // draw blob results
    for( int i=0; i<blobs.length; i++ ) {
	beginShape();
		
	if (fillInBlobs) {
	    fill(255, 0, 0);
	} else {
	    noFill();
	}
		
	for( int j=0; j<blobs[i].points.length; j++ ) {
	    vertex( blobs[i].points[j].x, blobs[i].points[j].y );
	}
	endShape(CLOSE);
    }
}

void processRGBDataInCurrentOpenCVBuffer() {
    opencv.threshold(rgbThreshold);

    image(opencv.image(), 640 + imageRegionPadding, 0, 640, 480);

    Blob blobs[] = opencv.blobs(10, width*height/2, 100, true, OpenCV.MAX_VERTICES*4 );

    // draw blob results
    for( int i=0; i<blobs.length; i++ ) {
	beginShape();
		
	if (fillInBlobs) {
	    fill(255, 0, 0);
	} else {
	    noFill();
	}
		
	for( int j=0; j<blobs[i].points.length; j++ ) {
	    vertex( blobs[i].points[j].x + 640 + imageRegionPadding, blobs[i].points[j].y );
	}
	endShape(CLOSE);
    }	
}

void drawAdjustmentVariablesRegion() {

    fill(30, 30, 30);
    rect(0, windowHeight - textRegionHeight, windowWidth, windowHeight);

    int variableNameColumnWidth = 175;
    int rowHeight = textRegionHeight / adjustmentVariableNames.length;
    int leftPadding = 15; 
    int startPosition = windowHeight - textRegionHeight;

    fill(255);  
    for (int i = 0; i < adjustmentVariableNames.length; i++) {
	int yPosition = i * rowHeight + rowHeight/2;

	// draw variable name column
	text(adjustmentVariableNames[i], leftPadding, startPosition + yPosition);

	// draw variable value column
	text(adjustmentVariableValueForVariableName(adjustmentVariableNames[i]), leftPadding + variableNameColumnWidth, startPosition + yPosition);
    }    

}

void keyPressed() { 
    if (key == '\b') {
	if (currSiteID.length() > 0) {
	    currSiteID = currSiteID.substring(0, currSiteID.length() - 1);
	}
    } else if (key == '\t') {
	if (currSiteID != "") {
	    saveDataForSiteJSON(currSiteID);
	}
    } else if (key == '<' || key == ',') { // depthMaxDist
	if (depthMaxDist - depthMaxDistIncrementValue >= depthMaxDistMinValue) {
	    depthMaxDist -= depthMaxDistIncrementValue;
	} 
	println("leftSign");
    } else if (key == '>' || key == '.') { // depthMaxDist
	if (depthMaxDist + depthMaxDistIncrementValue <= depthMaxDistMaxValue) {
	    depthMaxDist += depthMaxDistIncrementValue;
	} 
	println("rightSign");
    } else if (key == ';' || key == ':') {
	if (depthThreshold - depthThresholdIncrementValue >= depthThresholdMinValue) {
	    depthThreshold -= depthThresholdIncrementValue;
	}
    } else if (key == '\'' || key == '"') {
	if (depthThreshold + depthThresholdIncrementValue <= depthThresholdMaxValue) {
	    depthThreshold += depthThresholdIncrementValue;
	}
    } else if (key == '-') { // rgbThreshold
	if (rgbThreshold - rgbThresholdIncrementValue >= rgbThresholdMinValue) {
	    rgbThreshold -= rgbThresholdIncrementValue;	
	}
	println("minus");
    } else if (key == '=' || key == '+') { // rgbThreshold
	if (rgbThreshold + rgbThresholdIncrementValue <= rgbThresholdMaxValue) {
	    rgbThreshold += rgbThresholdIncrementValue;	
	}
	println("plus");
    } else if (key == '~' || key == '`') {
	enableOpenCV = !enableOpenCV;
    } else if (key == '/' || key == '?') {
	if (canUseConnectedSensor) {
	    useSensorCaptureStream = !useSensorCaptureStream;	
	} else {
	    println("Sensor was not initialized correctly, please connect it and restart the program");
	}
    } else if (key == ']' || key == '}') {
	updateSourceImage = true;
	println("Update Source Image");
    } else if (key == '[' || key == '{') {
	fillInBlobs = !fillInBlobs;
    } else if (key == '%') {
	enableMeshConstruction = !enableMeshConstruction;
    } else {
	currSiteID = currSiteID + key;
    }
}


int depthMaxDistMinValue = 300;
int depthMaxDistMaxValue = 3000;
int depthMaxDistIncrementValue = 1;
int depthMaxDistDefaultValue = 650; // default

int depthThresholdMinValue = 0;
int depthThresholdMaxValue = 255;
int depthThresholdIncrementValue = 1;
int depthThresholdDefaultValue = 125;

int rgbThresholdMinValue = 0;
int rgbThresholdMaxValue = 255;
int rgbThresholdIncrementValue = 1;
int rgbThresholdDefaultValue = 75; // default

int minBlobAreaMinValue = 4;
int minBlobAreaMaxValue = 640 * 480;
int minBlobAreaIncrmentValue = 100;
int minBlobAreaDefaultValue = 100;

boolean enableOpenCVDefaultValue = false;
boolean useSensorCaptureStreamDefaultValue = false;
boolean updateSourceImageDefaultValue = false;
boolean fillInBlobsDefaultValue = true;
boolean enableMeshConstructionDefaultValue = false;

void setDefaultAdjustmentVariableValues() {
    depthMaxDist = depthMaxDistDefaultValue;
    depthThreshold = depthThresholdDefaultValue;
    rgbThreshold = rgbThresholdDefaultValue;
    minBlobArea = minBlobAreaDefaultValue;

    enableOpenCV = enableOpenCVDefaultValue;
    useSensorCaptureStream = useSensorCaptureStreamDefaultValue;
    updateSourceImage = updateSourceImageDefaultValue;
    fillInBlobs = fillInBlobsDefaultValue;
    enableMeshConstruction = enableMeshConstructionDefaultValue;
}


/**
   Prints the Depth data as JSON in the following format:
   {"location_id" : 27, "depth_map" : [0, 1, 2]}
*/
void saveDataForSiteJSON(String siteID) {
	
    if (useSensorCaptureStream && canUseConnectedSensor) {
	String fileName = OUTPUT_DIRECTORY + "//" + currSiteID + "\\depth.json"; //"siteID\\depth_" + siteID + ".json";
	println("Creating file:  " + fileName);
	PrintWriter depthOut = createWriter(fileName);

	depthOut.print("{");
	printJSONStringStringKeyValuePair("location_id", siteID, depthOut);
	depthOut.print(", ");
	printJSONStringIntKeyValuePair("depth_width", context.depthWidth(), depthOut);
	depthOut.print(", ");
	printJSONStringIntKeyValuePair("depth_height", context.depthHeight(), depthOut);
	depthOut.print(", ");
	printJSONStringIntKeyValuePair("rgb_width", context.rgbWidth(), depthOut);
	depthOut.print(", ");
	printJSONStringIntKeyValuePair("rgb_height", context.rgbHeight(), depthOut);
	depthOut.print(", ");
	depthOut.print("\"depth_map\"");
	depthOut.print(" : ");
	printJSONArrayToOutput(context.depthMap(), depthOut);
	depthOut.print("}");
	depthOut.flush();
	depthOut.close();	
    }
	
    SaveJpg(OUTPUT_DIRECTORY + "//" + currSiteID + "\\combined_images_" + currSiteID + ".jpg");

    /* 
       String absolutePath = "C:\\Users\\skamuter\\Documents\\Code\\Processing\\SoilCrusts\\SoilCrustSampler\\";
       println("Absolute Path:  " + absolutePath);

       String depthPath = absolutePath + siteID + \\depth_image_" + currSiteID + ".jpg";
       String rgbPath = absolutePath + "rgb_image_" + currSiteID + ".jpg";

       debugLog = depthPath;

    */

    //opencv.copy(context.depthImage(), 0, 0, 640, 480, 0, 0, 640, 480);
    //opencv.image().save(OUTPUT_DIRECTORY + "//" + currSiteID + "\\depth_" + currSiteID + ".jpg");

    //context.depthImage().save(absolutePath);
    //String rgbPath = savePath("rgb_image_" + currSiteID + ".jpg");
    //context.rgbImage().save(rgbPath);
}


// Placeholder
void saveDataForSiteCSV(String siteID) {

    String fileName = currSiteID + "\\depth.json"; //"siteID\\depth_" + siteID + ".json";
    println("Creating file:  " + fileName);
    PrintWriter depthOut = createWriter(fileName);

    depthOut.print("{");
    printJSONStringStringKeyValuePair("location_id", siteID, depthOut);
    depthOut.print(", ");
    printJSONStringIntKeyValuePair("depth_width", context.depthWidth(), depthOut);
    depthOut.print(", ");
    printJSONStringIntKeyValuePair("depth_height", context.depthHeight(), depthOut);
    depthOut.print(", ");
    printJSONStringIntKeyValuePair("rgb_width", context.rgbWidth(), depthOut);
    depthOut.print(", ");
    printJSONStringIntKeyValuePair("rgb_height", context.rgbHeight(), depthOut);
    depthOut.print(", ");
    depthOut.print("\"depth_map\"");
    depthOut.print(" : ");
    printJSONArrayToOutput(context.depthMap(), depthOut);
    depthOut.print("}");
    depthOut.flush();
    depthOut.close();

    SaveJpg(currSiteID + "\\combined_images_" + currSiteID + ".jpg");

    /* 
       String absolutePath = "C:\\Users\\skamuter\\Documents\\Code\\Processing\\SoilCrusts\\SoilCrustSampler\\";
       println("Absolute Path:  " + absolutePath);

       String depthPath = absolutePath + siteID + \\depth_image_" + currSiteID + ".jpg";
       String rgbPath = absolutePath + "rgb_image_" + currSiteID + ".jpg";

       debugLog = depthPath;

    */

    //context.depthImage().save(absolutePath);
    //String rgbPath = savePath("rgb_image_" + currSiteID + ".jpg");
    //context.rgbImage().save(rgbPath);
}


void printJSONArrayToOutput(int [] array, PrintWriter out) {
    out.print("[");
    for (int i = 0; i < array.length; i++) {
	if (i == 0) {
	    out.print(array[0]);  
	} else {
	    out.print(", " + array[i]);
	}
    }
    out.print("]");
}

void printJSONStringStringKeyValuePair(String key, String value, PrintWriter out) {
    out.print("\"" + key + "\"");
    out.print(" : ");
    out.print("\"" + value + "\"");
}

void printJSONStringIntKeyValuePair(String key, int value, PrintWriter out) {
    out.print("\"" + key + "\"");
    out.print(" : ");
    out.print(value);
}



void SaveJpg(String fname){
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    BufferedImage img = new BufferedImage(width, height, 2);
    img = (BufferedImage)createImage(width, height);
    loadPixels();
    for(int i = 0; i < width; i++)
	{
	    for(int j = 0; j < height; j++)
		{
		    int id = j*width+i;
		    img.setRGB(i,j, pixels[id]); 
		}
	}
    try{
	JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(out);
	encoder.encode(img);
    }
    catch(FileNotFoundException e){
	System.out.println(e);
    }
    catch(IOException ioe){
	System.out.println(ioe);
    }
    byte [] a = out.toByteArray();
    saveBytes(fname,a);
}


String adjustmentVariableValueForVariableName(String adjustmentVariableName) {

    if (adjustmentVariableName.equalsIgnoreCase(SITE_ID_KEY)) {
	return currSiteID;
    } else if (adjustmentVariableName.equalsIgnoreCase(USE_SENSOR_CAPTURE_STREAM)) {
	return useSensorCaptureStream ? "True" : "False";	
    } else if (adjustmentVariableName.equalsIgnoreCase(UPDATE_SOURCE_IMAGE)) {
	return "N/A";
    } else if (adjustmentVariableName.equalsIgnoreCase(DEPTH_MAX_DIST_KEY)) {
	return Float.toString(depthMaxDist); 
    } else if (adjustmentVariableName.equalsIgnoreCase(RGB_THRESHOLD_KEY)) {
	return Float.toString(rgbThreshold);
    } else if (adjustmentVariableName.equalsIgnoreCase(MIN_BLOB_AREA_KEY)) {
	return Float.toString(minBlobArea);
    } else if (adjustmentVariableName.equalsIgnoreCase(ENABLE_OPEN_CV)) {
	return enableOpenCV ? "True" : "False";
    } else if (adjustmentVariableName.equalsIgnoreCase(DEPTH_THRESHOLD_KEY)) {
	return Float.toString(depthThreshold);
    } else if (adjustmentVariableName.equalsIgnoreCase(FILL_IN_BLOBS_KEY)) {
	return fillInBlobs ? "True" : "False";
    } else if (adjustmentVariableName.equalsIgnoreCase(ENABLE_MESH_CONSTRUCTION)) {
	return enableMeshConstruction ? "True" : "False";
    } else {
	return "Unknown NO Match";
    }
}
