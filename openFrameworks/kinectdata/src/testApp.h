#pragma once

#include "ofMain.h"
#include "ofxOpenCv.h"
#include "ofxKinect.h"


#define PEGGY_SIZE 25

class testApp : public ofBaseApp {
public:
	
    void setup();
    void update();
    void draw();
    void exit();
    
    void drawPointCloud();
    
    void keyPressed(int key);
    void mouseDragged(int x, int y, int button);
    void mousePressed(int x, int y, int button);
    void mouseReleased(int x, int y, int button);
    void windowResized(int w, int h);
        
    void setupROIRegions(); // split up our kinect image
	
    ofxKinect kinect;
    
    // cv images
    ofxCvColorImage colorImg;
    //ofxCvGrayscaleImage grayImage; // grayscale depth image
    ofxCvFloatImage grayImage;
    
    ofShortPixels depthPixelsRaw;
    
    ofxCvGrayscaleImage grayThreshNear; // the near thresholded image
    ofxCvGrayscaleImage grayThreshFar; // the far thresholded image
    vector<ofxCvGrayscaleImage> quads;
    vector<ofxCvGrayscaleImage> downsampledQuads;
  
    // kinect options
    bool bThreshWithOpenCV;
    bool bDrawPointCloud;
    int nearThreshold;
    int farThreshold;
    int angle;
	
    // used for viewing the point cloud
    ofEasyCam cam;
    
    // fbo
    ofFbo peggyFbo; // FBO test for angled viewing
};
