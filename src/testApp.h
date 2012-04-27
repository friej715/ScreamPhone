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
#define PORT 8000

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
    void setSettings();
	void audioIn( float * input, int bufferSize, int nChannels );

	int		initialBufferSize;
	int		sampleRate;
	int		drawCounter /*, bufferCounter*/;
	float 	* buffer;
    
    // string to keep track of where we are in setting this up
    string gamestate;
    
    // sending the OSC messages
    string host;
    string portNumber;
    ofxOscSender sender;
    ofRectangle button; // submit button
    
    // volume & fft
    float maxLevel;
    float maxMag;
    float locationMax;
    
    // keyboard
    ofxiPhoneKeyboard * keyboard;
    ofxiPhoneKeyboard * keyboardPort;
    
    
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

