#include "testApp.h"


//--------------------------------------------------------------
void testApp::setup() {
    ofSetLogLevel(OF_LOG_VERBOSE);
	
    // enable depth->video image calibration
    kinect.setRegistration(true);
    
    kinect.init();
    //kinect.init(true); // shows infrared instead of RGB video image
    //kinect.init(false, false); // disable video image (faster fps)
    kinect.open();
	
    colorImg.allocate(kinect.width, kinect.height);
    grayImage.allocate(kinect.width, kinect.height);
    
    grayThreshNear.allocate(kinect.width, kinect.height);
    grayThreshFar.allocate(kinect.width, kinect.height);
	
    depthPixelsRaw.allocate(kinect.width, kinect.height, 1);
    
    peggyFbo.allocate(50, 50); // allocate the tiny FBO
    
    nearThreshold = 230;
    farThreshold = 70;
    bThreshWithOpenCV = true;
	
    ofSetFrameRate(60);
    
    // zero the tilt on startup
    angle = 0;
    kinect.setCameraTiltAngle(angle);
	
    // start from the front
    bDrawPointCloud = false;
        
    
    // setup some vectors to store the image information
    // normal grayscale image size
    for (int x = 0; x < 5; x++) {
        ofxCvGrayscaleImage emptyImg;
        emptyImg.allocate(160, 120); // 1/4 scale
        quads.push_back(emptyImg);
    }
    
    // downsampled version for peggy // 25x25
    for (int x = 0; x < 5; x++) {
        ofxCvGrayscaleImage emptyPImg;
        emptyPImg.allocate(25, 25);
        downsampledQuads.push_back(emptyPImg);
    }
}

//--------------------------------------------------------------
void testApp::update() {
	
    ofBackground(50, 50, 50);
	
    kinect.update();
	
    // there is a new frame and we are connected
    if(kinect.isFrameNew()) {
        
        // load grayscale depth image from the kinect source
        //depthPixelsRaw = kinect.getRawDepthPixels(); // TODO: still working on this
        
        grayImage.setFromPixels(kinect.getDistancePixels(), kinect.width, kinect.height);
        
        grayImage.scale(0.5, 0.5); // scaling the image for now (faster?)
        
        // setup the 4 ROI's from the grayscale image
        setupROIRegions();
        
        // update the cv images
        grayImage.flagImageChanged();
        
	}
    
    
    // draw the downsampled peggy outputs to an FBO
    peggyFbo.begin();
        ofClear(255,255,255);
        downsampledQuads[0].draw(0, 0, 25, 25); // draw the upscaled version of the downsample
        downsampledQuads[1].draw(25, 0, 25, 25);
        downsampledQuads[2].draw(0, 25, 25, 25);
        downsampledQuads[3].draw(25, 25, 25, 25);
    peggyFbo.end();
	
}

//--------------------------------------------------------------
void testApp::draw() {
	
    ofSetColor(255, 255, 255);
    
    // draw our debug images
    kinect.drawDepth(10, 10, 200, 150);
    ofDrawBitmapString("depth pixels", ofPoint(10,20));
    
    kinect.draw(10, 170, 200, 150);
    ofDrawBitmapString("kinect rgb", ofPoint(10,180));
    
    grayImage.draw(10, 330, 200, 150);
    ofDrawBitmapString("threshold image", ofPoint(10,340));
    
    
    // draw our ROI from the grayscale image
    quads[0].draw(250, 10); // draw the original ROI
    ofDrawBitmapString("ROI display" , ofPoint(250, 20));
    quads[1].draw(415, 10);
    quads[2].draw(250, 135);
    quads[3].draw(415, 135);
    
    
    //ofPushMatrix();
        cam.begin();
        ofRotateX(ofRadToDeg(3.25));
        ofTranslate(-ofGetWidth()/2, -ofGetHeight()/2);
        peggyFbo.draw(650,40, 300, 300);
        ofDrawBitmapString("to peggy" , ofPoint(650, 50));
        cam.end();
    //ofPopMatrix();
    
    
    
    // draw instructions
    ofSetColor(255, 255, 255);
    stringstream reportStream;
    reportStream << "accel is: " << ofToString(kinect.getMksAccel().x, 2) << " / "
    << ofToString(kinect.getMksAccel().y, 2) << " / "
    << ofToString(kinect.getMksAccel().z, 2) << endl
    << "use your mouse to rotate the peggy output" << endl
    << "using opencv threshold = " << bThreshWithOpenCV <<" (press spacebar)" << endl
    << "set near threshold " << nearThreshold << " (press: + -)" << endl
    << "set far threshold " << farThreshold << " (press: < >) num blobs found " << endl
    << ", fps: " << ofGetFrameRate() << endl
    << "press c to close the connection and o to open it again, connection is: " << kinect.isConnected() << endl
    << "press UP and DOWN to change the tilt angle: " << angle << " degrees" << endl;
    ofDrawBitmapString(reportStream.str(),20, 530);
}


//--------------------------------------------------------------
void testApp::setupROIRegions() {
    
    // calculate the ROI images
    // 640x480 divided into 4 regions
    
    // quick HACK for now
    // the downsampled quad is a quick hack to resize the 160x120 quad into 25x25
    // we feign the downsampled image by upscaling when we draw
    
    // roi 1
    grayImage.setROI(0, 0, 160, 120); // define the ROI region
    quads[0].setFromPixels( grayImage.getRoiPixels(), 160, 120 ); // copy the ROI into an image
    ofxCvGrayscaleImage quad1copy = quads[0]; // copy the quad for a resize
    quad1copy.resize(25, 25); // hacked downsample
    downsampledQuads[0] = quad1copy; // assign it to the vector
    grayImage.resetROI(); // always reset the ROI when complete
    
    // roi 2
    grayImage.setROI(160, 0, 160, 120);
    quads[1].setFromPixels( grayImage.getRoiPixels(), 160, 120 );
    ofxCvGrayscaleImage quad2copy = quads[1];
    quad2copy.resize(25, 25);
    downsampledQuads[1] = quad2copy;
    grayImage.resetROI();
    
    // roi 3
    grayImage.setROI(0, 120, 160, 120);
    ofxCvGrayscaleImage quad3;
    quads[2].setFromPixels( grayImage.getRoiPixels(), 160, 120 );
    ofxCvGrayscaleImage quad3copy = quads[2];
    quad3copy.resize(25, 25);
    downsampledQuads[2] = quad3copy;
    grayImage.resetROI();
    
    // roi 4
    grayImage.setROI(160, 120, 160, 120);
    quads[3].setFromPixels( grayImage.getRoiPixels(), 160, 120 );
    ofxCvGrayscaleImage quad4copy = quads[3];
    quad4copy.resize(25, 25);
    downsampledQuads[3] = quad4copy;
    grayImage.resetROI();

}

//--------------------------------------------------------------
void testApp::exit() {
	kinect.setCameraTiltAngle(0); // zero the tilt on exit
	kinect.close();
}

//--------------------------------------------------------------
void testApp::keyPressed (int key) {
	switch (key) {
		case ' ':
			bThreshWithOpenCV = !bThreshWithOpenCV;
			break;
			
		case '>':
		case '.':
			farThreshold ++;
			if (farThreshold > 255) farThreshold = 255;
			break;
			
		case '<':
		case ',':
			farThreshold --;
			if (farThreshold < 0) farThreshold = 0;
			break;
			
		case '+':
		case '=':
			nearThreshold ++;
			if (nearThreshold > 255) nearThreshold = 255;
			break;
			
		case '-':
			nearThreshold --;
			if (nearThreshold < 0) nearThreshold = 0;
			break;
			
		case 'w':
			kinect.enableDepthNearValueWhite(!kinect.isDepthNearValueWhite());
			break;
			
		case 'o':
			kinect.setCameraTiltAngle(angle); // go back to prev tilt
			kinect.open();
			break;
			
		case 'c':
			kinect.setCameraTiltAngle(0); // zero the tilt
			kinect.close();
			break;
			
		case OF_KEY_UP:
			angle++;
			if(angle>30) angle=30;
			kinect.setCameraTiltAngle(angle);
			break;
			
		case OF_KEY_DOWN:
			angle--;
			if(angle<-30) angle=-30;
			kinect.setCameraTiltAngle(angle);
			break;
	}
}

//--------------------------------------------------------------
void testApp::mouseDragged(int x, int y, int button)
{}

//--------------------------------------------------------------
void testApp::mousePressed(int x, int y, int button)
{}

//--------------------------------------------------------------
void testApp::mouseReleased(int x, int y, int button)
{}

//--------------------------------------------------------------
void testApp::windowResized(int w, int h)
{}
