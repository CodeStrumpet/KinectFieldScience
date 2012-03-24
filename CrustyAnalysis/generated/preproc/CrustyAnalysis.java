import processing.core.*; 
import processing.xml.*; 

import SimpleOpenNI.*; 
import com.sun.image.codec.jpeg.*; 
import hypermedia.video.*; 
import java.awt.image.BufferedImage; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class CrustyAnalysis extends PApplet {








SimpleOpenNI  context; 
OpenCV opencv;

PFont f;
int windowWidth = 0; 
int windowHeight = 0;
int imageRegionPadding = 10;
int textRegionHeight = 300;
String debugLog = "";

final String OUTPUT_DIRECTORY = "data\\output";

final String SITE_ID_KEY = "siteID";
final String USE_SENSOR_CAPTURE_STREAM = "useSensorCaptureStream  ('/')";
final String UPDATE_SOURCE_IMAGE = "updateSourceImage  (']')";
final String DEPTH_MAX_DIST_KEY = "depthMaxDist  ('<' , '>')";
final String RGB_THRESHOLD_KEY = "rgbThreshold  ('-' , '+')";
final String ENABLE_OPEN_CV = "enableOpenCV  ('~')";
final String MIN_BLOB_AREA_KEY = "minBlobArea";

String[] adjustmentVariableNames = {SITE_ID_KEY, USE_SENSOR_CAPTURE_STREAM, UPDATE_SOURCE_IMAGE, DEPTH_MAX_DIST_KEY, RGB_THRESHOLD_KEY, ENABLE_OPEN_CV, MIN_BLOB_AREA_KEY};
String currSiteID = "";
boolean useSensorCaptureStream = false;
boolean updateSourceImage = true;
float depthMaxDist = 0.0f;
float rgbThreshold = 0.0f;
boolean enableOpenCV = false;
float minBlobArea = 0.0f;

boolean canUseConnectedSensor = true;

public void setup()
{

	// set default values
	setDefaultAdjustmentVariableValues();

	// create kinect context
	context = new SimpleOpenNI(this);

	// create OpenCV instance
	opencv = new OpenCV(this);

	/*   AlternativeViewPoint????!
  XnBool isSupported = context.IsCapabilitySupported("AlternativeViewPoint"); 
if(TRUE == isSupported) 
{ 
  XnStatus res = depthGenerator.GetAlternativeViewPointCap().SetViewPoint(imageGenerator); 
  if(XN_STATUS_OK != res) 
  { 
    printf("Getting and setting AlternativeViewPoint failed: %s\n", xnGetStatusString(res)); 
  } 
} 
	 */

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

	windowWidth = context.depthWidth() + context.rgbWidth() + imageRegionPadding;
	windowHeight = context.rgbHeight() + textRegionHeight; 
	
	if (windowWidth == imageRegionPadding) {
		windowWidth += 640 * 2;
	}
	if (windowHeight == textRegionHeight) {
		windowHeight += 480;
	}

	// create window
	size(windowWidth, windowHeight);
}

public void draw()
{

	if (useSensorCaptureStream) {
		// update the cam
		context.update();

		background(200,0,0);

		if (enableOpenCV) {

			opencv.copy(context.depthImage(), 0, 0, 640, 480, 0, 0, 640, 480);

			//opencv.threshold(80);

			//opencv.absDiff();

			image(opencv.image(), 0, 0, 640, 480);

			Blob blobs[] = opencv.blobs(10, width*height/2, 100, true, OpenCV.MAX_VERTICES*4 );
			// draw blob results
			for( int i=0; i<blobs.length; i++ ) {
				beginShape();
				for( int j=0; j<blobs[i].points.length; j++ ) {
					vertex( blobs[i].points[j].x, blobs[i].points[j].y );
				}
				endShape(CLOSE);
			}

			opencv.copy(context.rgbImage(), 0, 0, 640, 480, 0, 0, 640, 480);

			opencv.threshold(rgbThreshold);

			image(opencv.image(), 640 + imageRegionPadding, 0, 640, 480);

			blobs = opencv.blobs(10, width*height/2, 100, true, OpenCV.MAX_VERTICES*4 );

			// draw blob results
			for( int i=0; i<blobs.length; i++ ) {
				beginShape();
				for( int j=0; j<blobs[i].points.length; j++ ) {
					vertex( blobs[i].points[j].x + 640 + imageRegionPadding, blobs[i].points[j].y );
				}
				endShape(CLOSE);
			}

		} else {
			// draw depthImageMap
			image(context.depthImage(),0,0);

			// draw irImageMap
			image(context.rgbImage(),context.depthWidth() + 10,0);	
		}  


	} else {
		// do nothing for now
	}



	// draw adjustment variables
	drawAdjustmentVariablesRegion();
}

public void drawAdjustmentVariablesRegion() {

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

	//text(currSiteID, 20, windowHeight - (textRegionHeight / 2));	
}

public void keyPressed() { 
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
	} else {
		currSiteID = currSiteID + key;
	}
}

/*
float depthMaxDist = 0.0;
float rgbThreshold = 0.0;
float minBlobArea = 0.0;
 */

int depthMaxDistMinValue = 300;
int depthMaxDistMaxValue = 3000;
int depthMaxDistIncrementValue = 10;
int depthMaxDistDefaultValue = 2000; // default

int rgbThresholdMinValue = 0;
int rgbThresholdMaxValue = 255;
int rgbThresholdIncrementValue = 5;
int rgbThresholdDefaultValue = 80; // default

int minBlobAreaMinValue = 4;
int minBlobAreaMaxValue = 640 * 480;
int minBlobAreaIncrmentValue = 100;
int minBlobAreaDefaultValue = 100;

boolean enableOpenCVDefaultValue = false;
boolean useSensorCaptureStreamDefaultValue = false;
boolean updateSourceImageDefaultValue = false;

public void setDefaultAdjustmentVariableValues() {
	depthMaxDist = depthMaxDistDefaultValue;
	rgbThreshold = rgbThresholdDefaultValue;
	minBlobArea = minBlobAreaDefaultValue;

	enableOpenCV = enableOpenCVDefaultValue;
	useSensorCaptureStream = useSensorCaptureStreamDefaultValue;
	updateSourceImage = updateSourceImageDefaultValue;
}

/**
Prints the Depth data as JSON in the following format:
{"location_id" : 27, "depth_map" : [0, 1, 2]}
 */
public void saveDataForSiteJSON(String siteID) {
	
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
public void saveDataForSiteCSV(String siteID) {

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


public void printJSONArrayToOutput(int [] array, PrintWriter out) {
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

public void printJSONStringStringKeyValuePair(String key, String value, PrintWriter out) {
	out.print("\"" + key + "\"");
	out.print(" : ");
	out.print("\"" + value + "\"");
}

public void printJSONStringIntKeyValuePair(String key, int value, PrintWriter out) {
	out.print("\"" + key + "\"");
	out.print(" : ");
	out.print(value);
}



public void SaveJpg(String fname){
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


public String adjustmentVariableValueForVariableName(String adjustmentVariableName) {

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
	} else {
		return "Unknown NO Match";
	}
}

    static public void main(String args[]) {
        PApplet.main(new String[] { "--bgcolor=#ECE9D8", "CrustyAnalysis" });
    }
}
