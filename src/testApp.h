#pragma once

#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"
//#include "ofxMaxim.h"
#include "fft.h"
#include "ofxOsc.h"

#define BUFFER_SIZE 256
#define NUM_WINDOWS 80

// for osc messages; change to whatever's needed
#define HOST "localhost"
#define PORT 12345

class testApp : public ofxiPhoneApp{
	
public:
	void setup();
	void update();
	void draw();
	
	void touchDown(ofTouchEventArgs &touch);
	void touchMoved(ofTouchEventArgs &touch);
	void touchUp(ofTouchEventArgs &touch);
	void touchDoubleTap(ofTouchEventArgs &touch);
	void touchCancelled(ofTouchEventArgs &touch);

	void audioIn( float * input, int bufferSize, int nChannels );

	int		initialBufferSize;
	int		sampleRate;
	int		drawCounter /*, bufferCounter*/;
	float 	* buffer;
    
    // sending the OSC messages
    ofxOscSender sender;
    
    // volume & fft
    float maxLevel;
    float maxMag;
    float maxMagMapped;
    float locationMax;
    
    
//    void audioReceived 	(float * input, int bufferSize, int nChannels); 
    
private:	
    float * left;
    float * right;
    int 	bufferCounter;
    fft		myfft;
    
    float magnitude[BUFFER_SIZE];
    float phase[BUFFER_SIZE];
    float power[BUFFER_SIZE];
    
    float freq[NUM_WINDOWS][BUFFER_SIZE/2];
    float freq_phase[NUM_WINDOWS][BUFFER_SIZE/2];
    
    
};

