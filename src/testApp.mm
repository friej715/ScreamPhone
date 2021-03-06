#include "testApp.h"


//--------------------------------------------------------------
void testApp::setup(){
    
	// IMPORTANT!!! if your sound doesn't work in the simulator - read this post - which requires you set the input stream to 24bit!!
	//	http://www.cocos2d-iphone.org/forum/topic/4159
    
	// register touch events
	ofRegisterTouchEvents(this);
	
	ofxiPhoneSetOrientation(OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT);
    
	ofBackground(0);
    
	//for some reason on the iphone simulator 256 doesn't work - it comes in as 512!
	//so we do 512 - otherwise we crash
	initialBufferSize	= 512;
	sampleRate 			= 44100;
	drawCounter			= 0;
	bufferCounter		= 0;
	
	buffer				= new float[initialBufferSize];
	memset(buffer, 0, initialBufferSize * sizeof(float));
    
	// 0 output channels,
	// 1 input channels
	// 44100 samples per second
	// 512 samples per buffer
	// 4 num buffers (latency)
	ofSoundStreamSetup(0, 1, this, sampleRate, initialBufferSize, 4);
	ofSetFrameRate(60);
    
    left = new float[BUFFER_SIZE];
	right = new float[BUFFER_SIZE];
    
	for (int i = 0; i < NUM_WINDOWS; i++)
	{
		for (int j = 0; j < BUFFER_SIZE/2; j++)
		{
			freq[i][j] = 0;	
		}
	}
	
	ofSetColor(0x666666);
    
    gamestate = "settings";
    
    // keyboard
    //iPhoneAlerts will be sent to this.
	ofxiPhoneAlerts.addListener(this);
    
    keyboard = new ofxiPhoneKeyboard(100,200,320,32);
	keyboard->setVisible(true);
	keyboard->setBgColor(255, 255, 255, 255);
	keyboard->setFontColor(0,0,0, 255);
	keyboard->setFontSize(26);
    
    keyboardPort = new ofxiPhoneKeyboard(100,240,320,32);
	keyboardPort->setVisible(true);
	keyboardPort->setBgColor(255, 255, 255, 255);
	keyboardPort->setFontColor(0,0,0, 255);
	keyboardPort->setFontSize(26);
    
    button.set(100, 250, 100, 100);
    
}

// ohhhhh... there should be a setup mode where you choose whether you're P1 or P2...



//--------------------------------------------------------------
void testApp::update(){
    
    if (gamestate == "settings") {
        host = keyboard->getText();
        portNumber = keyboardPort->getText();
        
    }
    
    if (gamestate == "running") {
        // we need to keep the iphone alive--send some stuff so it doesn't turn off. the mare you gnaw!
        if( ofGetFrameNum() % 120 == 0 ){
            ofxOscMessage m;
            m.setAddress( "/misc/heartbeat" );
            m.addIntArg( ofGetFrameNum() );
            sender.sendMessage( m );
        }
    }
    
}

//--------------------------------------------------------------
void testApp::draw(){
    if (gamestate == "settings") {
        ofSetColor(0,255,0);
        ofRect(button.x, button.y, button.width, button.height);
    }
    
    if (gamestate == "running") {
        cout << "running!" << endl;
        maxMag = 0;
        
        ofBackground(0);
        
        ofTranslate(0, -50, 0);
        
        //  draw the input:
        //	ofSetHexColor(0x333333);
        //	ofRect(70,100,256,200);
        //	ofSetHexColor(0xFFFFFF);
        //	for (int i = 0; i < initialBufferSize; i++){
        //		ofLine(70+i,200,70+i,200+left[i]*100.0f);
        //	}
        //
        //	ofSetHexColor(0x333333);
        //	drawCounter++;
        //	char reportString[255];
        //	sprintf(reportString, "buffers received: %i\ndraw routines called: %i\n", bufferCounter,drawCounter);
        //	ofDrawBitmapString(reportString, 70,308);
        //
        //    ofSetColor(255, 255, 255,255);
        
        static int index=0;
        float avg_power = 0.0f;	
        
        if(index < 80)
            index += 1;
        else
            index = 0;
        
        /* do the FFT	*/
        myfft.powerSpectrum(0,(int)BUFFER_SIZE/2, left,BUFFER_SIZE,&magnitude[0],&phase[0],&power[0],&avg_power);
        
        /* start from 1 because mag[0] = DC component */
        /* and discard the upper half of the buffer */
        for(int j=1; j < BUFFER_SIZE/2; j++) {
            freq[index][j] = magnitude[j];	
            
            if (freq[index][j] > maxMag) {
                maxMag = freq[index][j];
                locationMax = j; // this way we know the loc of the max mag, to compare it against the other player's
            }
        }
        
        /* draw the FFT */
        //	for (int i = 1; i < (int)(BUFFER_SIZE/2); i++){
        //        if (magnitude[i] == maxMag) {
        //            ofSetColor(255, 0, 0);
        //        } else {
        //            ofSetColor(255);
        //        }
        //		ofLine((i*8),400,(i*8),400-magnitude[i]*10.0f);
        //	}
        //    ofRect(locationMax*8, 0, 20, maxMag*10);
        
        ofxOscMessage m;
        m.setAddress( "/fft/levels" );
        m.addFloatArg(locationMax);
        sender.sendMessage(m);
        
        // let's make a test 2nd player who's at a certain frequency, just so we can see if this works.
        // will we need a different app for each device? just in terms of the location set? there's gotta be an easier way to do it, but that might save time...
        
        ofxOscMessage testm;
        testm.setAddress("/test/levels");
        testm.addFloatArg(5);
        sender.sendMessage(testm);
        
        ofDrawBitmapString("Location Of Max: " + ofToString(locationMax), 70, 308);
        ofDrawBitmapString("Volume: " + ofToString(maxLevel), 70, 350);
    }
}





//--------------------------------------------------------------
void testApp::audioIn(float * input, int bufferSize, int nChannels){

    if (gamestate == "running") {
        
         cout << "audioin" << endl;
        
        if( initialBufferSize != bufferSize ){
            ofLog(OF_LOG_ERROR, "your buffer size was set to %i - but the stream needs a buffer size of %i", initialBufferSize, bufferSize);
            return;
        }	
        
        // changes happening here!!!!!
        // samples are "interleaved"
        maxLevel = 0.0f;
        for (int i = 0; i < bufferSize; i++){
            left[i] = input[i*2];
            right[i] = input[i*2+1];
            
            float abs1 = ABS(input[i*2]);
            if (maxLevel < abs1) maxLevel = abs1;
        }
        bufferCounter++;
        
        //    cout << "maxlevel" << maxLevel << endl;
        ofxOscMessage ms;
        ms.setAddress( "/volume/max" );
        ms.addFloatArg(maxLevel);
        sender.sendMessage(ms);
        // samples are "interleaved"
        //	for (int i = 0; i < bufferSize; i++){
        //		buffer[i] = input[i];
        //	}
        //	bufferCounter++;
    }
    
}
//--------------------------------------------------------------
void testApp::setSettings() {
    // let's set up our osc sender so we can get these messages to the game
    int portInt = atoi(portNumber.c_str());
    cout << "portInt" << portInt << endl;
    sender.setup(host, portInt);
    gamestate = "running";
    
}


//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs &touch){
    cout << "touch" << endl;
    if (gamestate == "settings") {
        if (touch.id == 1){
            if(!keyboard->isKeyboardShowing()){
                keyboard->openKeyboard();
                keyboard->setVisible(true);
            } else {
                keyboard->setVisible(false);
            }
            
            if(!keyboardPort->isKeyboardShowing()){
                keyboardPort->openKeyboard();
                keyboardPort->setVisible(true);
            } else {
                keyboardPort->setVisible(false);
            }
         
        }
        
        if (button.inside(touch.x, touch.y) == true) {
            setSettings();
        }
    }
}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs &touch){
    
}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs &touch){
    
}

//--------------------------------------------------------------
void testApp::touchDoubleTap(ofTouchEventArgs &touch){
    
}

//--------------------------------------------------------------
void testApp::touchCancelled(ofTouchEventArgs& args){
    
}

