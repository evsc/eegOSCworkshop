#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){

	cout << "setup" << endl;

	ofSetFrameRate(60);
	beatCounter = 0;
	msCounter = 0;
	avgMsCounter = 0;
	avgSamplingRateHz = 0;
	beat = 0.2;	// sample incoming Data every 20ms 
	interpolateSampling = 0.3;
	lastDataMillis = ofGetElapsedTimeMillis();
	newData = false;
	clearCounter = 2.f;
	clearedData = false;
	bufferSize = 100;

	devicePort = "/dev/rfcomm0";
	baudRate = 57600;


	resetDataValues();

	hideGUI = false;
	insertRawData = true;
	setGUI1();
	setGUI2();
	setGUI3();
	gui1->loadSettings("gui1Settings.xml");
	gui2->loadSettings("gui2Settings.xml");
	gui3->loadSettings("gui3Settings.xml");


	tg.setup(devicePort, baudRate);
    tg.addEventListener(this);

    // print out all serial ports
    // tg.device.listDevices();
    // [notice ] ofSerial: [0] = rfcomm0
    cout << "setup" << endl;

}

//--------------------------------------------------------------
void ofApp::update(){

	// cout << ".";

	// display at what rate data comes in
	float dt = ofGetLastFrameTime();
	beatCounter += dt;

	// clear data in case it's been a while
	if (msCounter > clearCounter*1000 && !clearedData) {
		clearedData = true;
		resetDataValues();
	}



	tg.update();

	// update GUI 
	if (tg.isReady) {
		connectInfo->setTextString("connected");
    } else {
    	connectInfo->setTextString("trying to connect ...");
    }


	
	if (beatCounter >= beat) {
		beatCounter -= beat;

		if (newData) {

	    	newData = false;
	    	incomingDataGraph->addPoint(1);

	    } else {
	    	incomingDataGraph->addPoint(0);
	    }

	    deltaGraph->addPoint(tgDelta);
		thetaGraph->addPoint(tgTheta);
		lowAlphaGraph->addPoint(tgLowAlpha);
		highAlphaGraph->addPoint(tgHighAlpha);
		lowBetaGraph->addPoint(tgLowBeta);
		highBetaGraph->addPoint(tgHighBeta);
		lowGammaGraph->addPoint(tgLowGamma);
		midGammaGraph->addPoint(tgMidGamma);	

		attentionGraph->addPoint(tgAttention);
		meditationGraph->addPoint(tgMeditation);

		attentionLabel->setLabel("Attention 0-100: " + ofToString(tgAttention));
	    meditationLabel->setLabel("Meditation 0-100: " + ofToString(tgMeditation));
	    
	    deltaLabel->setLabel("Delta (0.5 - 2.75Hz) 0-3000000: " + ofToString(tgDelta));
	    thetaLabel->setLabel("Theta (3.5 - 6.75Hz) 0-3000000: " + ofToString(tgTheta));
	    lowAlphaLabel->setLabel("Low Alpha (7.5 - 9.25Hz) 0-500000: " + ofToString(tgLowAlpha));
	    highAlphaLabel->setLabel("High Alpha (10 - 11.75Hz) 0-500000: " + ofToString(tgHighAlpha));
	    lowBetaLabel->setLabel("Low Beta (13 - 16.75Hz) 0-500000: " + ofToString(tgLowBeta));
	    highBetaLabel->setLabel("High Beta (18 - 29.75Hz) 0-500000: " + ofToString(tgHighBeta));
	    lowGammaLabel->setLabel("Low Gamma (31 - 39.75Hz) 0-100000: " + ofToString(tgLowGamma));
	    midGammaLabel->setLabel("Mid Gamma (41 - 49.75Hz) 0-100000: " + ofToString(tgMidGamma));
	}



	rawLabel->setLabel("Raw: " + ofToString(tgRaw));

    
    

}

//--------------------------------------------------------------
void ofApp::draw(){

	ofBackground(180);



}




void ofApp::guiEvent(ofxUIEventArgs &e) {

	string name = e.getName();
	int kind = e.getKind();
	cout << "got event from: " << name << endl;

	if (e.getName() == "Show RAW Data") {
		ofxUIToggle *toggle = e.getToggle(); 
		insertRawData = toggle->getValue();
	}

}



//--------------------------------------------------------------
void ofApp::exit() {
    // gui1->saveSettings("gui1Settings.xml");
    
	delete gui1;

}


void ofApp::resetDataValues() {

	cout << "resetDataValues() " << endl;

	tgPower = 0;
	tgPoorSignal = 200;
	tgBlinkStrength = 0;
	tgAttention = 0;
	tgMeditation = 0;
	tgRaw = 0;
	tgDelta = 0;
	tgTheta = 0;
	tgLowAlpha = 0;
	tgHighAlpha = 0;
	tgLowBeta = 0;
	tgHighBeta = 0;
	tgLowGamma = 0;
	tgMidGamma = 0;

}


void ofApp::setGUI1() {

	gui1 = new ofxUISuperCanvas("THINKGEAR");

    gui1->addSpacer();
    gui1->addLabel("DEVICE PORT: " + devicePort, OFX_UI_FONT_SMALL);
    gui1->addLabel("BAUDRATE: " + ofToString(baudRate), OFX_UI_FONT_SMALL);


    gui1->addSpacer();
    string textString = "...";
	connectInfo = gui1->addTextArea("connectInfo", textString, OFX_UI_FONT_SMALL);

	// gui1->addSpacer();
	// gui1->addFPSSlider("FPS SLIDER");

	gui1->addSpacer();
    gui1->addSlider("Signal Quality 0-200", 0.0f, 255.0f, &tgPoorSignal);

    gui1->addSpacer();
    gui1->addLabel("DATA INPUT FREQUENCY", OFX_UI_FONT_SMALL);


    vector<float> buffer;
    for (int i = 0; i < bufferSize; i++) {
        buffer.push_back(0.0);
    }

    incomingDataGraph = gui1->addMovingGraph("DATA", buffer, bufferSize, 0.0, 1.0);
    incomingDataGraph->setDrawFill(true);
    incomingDataGraph->setColorFill(ofColor(255, 0, 0));

	// gui1->addSpacer();
    gui1->addSlider("Avg Hz", 0.0f, 2.0f, &avgSamplingRateHz);

	// gui1->addSpacer();
    gui1->addSlider("Interpolate 0-1", 0.0f, 1.0f, &interpolateSampling);

	// gui1->addSpacer();
    gui1->addSlider("Clear Counter 1-10", 0.0f, 10.0f, &clearCounter);


    gui1->setPosition(0, 0);
    gui1->autoSizeToFitWidgets();

}


void ofApp::setGUI2() {

    vector<float> buffer;
    for (int i = 0; i < bufferSize; i++) {
        buffer.push_back(0.0);
    }

	gui2 = new ofxUISuperCanvas("INTERPRETATIVE", 220, 0, 300, 800);
	gui2->addSpacer();

	attentionGraph = gui2->addMovingGraph("ATTENTION", buffer, bufferSize, 0.0, 100.0);
	attentionLabel = gui2->addLabel(" ", OFX_UI_FONT_SMALL);

	meditationGraph = gui2->addMovingGraph("MEDITATION", buffer, bufferSize, 0.0, 100.0);
	meditationLabel = gui2->addLabel(" ", OFX_UI_FONT_SMALL);


	gui2->addSpacer();
	gui2->addLabel("RAW DATA");

	int rawBufferSize = 512;
	buffer.clear();
    for (int i = 0; i < rawBufferSize; i++) {
        buffer.push_back(0.0);
    }

    gui2->addToggle("Show RAW Data", true);
	rawGraph = gui2->addMovingGraph("RAW", buffer, rawBufferSize, -5000, 5000);
	rawLabel = gui2->addLabel(" ", OFX_UI_FONT_SMALL);

    gui2->autoSizeToFitWidgets();

    ofAddListener(gui2->newGUIEvent, this, &ofApp::guiEvent); 

}

void ofApp::setGUI3() {

    vector<float> buffer;
    for (int i = 0; i < bufferSize; i++) {
        buffer.push_back(0.0);
    }

	// gui3 = new ofxUISuperCanvas("EEG BANDS");
	gui3 = new ofxUISuperCanvas("EEG BANDS", 600, 0, 400, 800);

	gui3->addSpacer();

	deltaGraph = gui3->addMovingGraph("DELTA", buffer, bufferSize, 0.0, 3000000.0);
	deltaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	thetaGraph = gui3->addMovingGraph("THETA", buffer, bufferSize, 0.0, 3000000.0);
	thetaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	lowAlphaGraph = gui3->addMovingGraph("LOW ALPHA", buffer, bufferSize, 0.0, 500000.0);
	lowAlphaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	highAlphaGraph = gui3->addMovingGraph("HIGH ALPHA", buffer, bufferSize, 0.0, 500000.0);
	highAlphaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	lowBetaGraph = gui3->addMovingGraph("LOW BETA", buffer, bufferSize, 0.0, 500000.0);
	lowBetaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	highBetaGraph = gui3->addMovingGraph("HIGH BETA", buffer, bufferSize, 0.0, 500000.0);
	highBetaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	lowGammaGraph = gui3->addMovingGraph("LOW GAMMA", buffer, bufferSize, 0.0, 100000.0);
	lowGammaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	midGammaGraph = gui3->addMovingGraph("MID GAMMA", buffer, bufferSize, 0.0, 100000.0);
	midGammaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);


    gui3->autoSizeToFitWidgets();

}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){

	
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

	if (key=='g') {
        gui1->toggleVisible();
	}

	if (key=='p') {
		// save a screenshot
        ofImage img;
        img.grabScreen(0,0,ofGetWidth(), ofGetHeight());
        string fileName = "screenshots/think_"+ofGetTimestampString()+".png";
        img.saveImage(fileName);
        cout << "saved screenshot " << fileName.c_str() << endl;
    }
}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}






//--------------Thinkgear callback Events-----------------------

void ofApp::onThinkgearReady(ofxThinkgearEventArgs& args){
    cout << "onReady" << endl;
}

void ofApp::onThinkgearError(ofMessage& err){
    cout << "onError " << err.message << endl;
}

void ofApp::onThinkgearRaw(ofxThinkgearEventArgs& args){
	// cout << "raw: " << args.raw << endl;
	if(insertRawData) {
		tgRaw = int(args.raw);
		rawGraph->addPoint(tgRaw);
	}
}

void ofApp::onThinkgearPower(ofxThinkgearEventArgs& args){
    // power.value = args.power;
}

void ofApp::onThinkgearPoorSignal(ofxThinkgearEventArgs& args){
	tgPoorSignal = int(args.poorSignal);
	cout << "onThinkgearPoorSignal " << int(args.poorSignal) << endl;
	msCounter = ofGetElapsedTimeMillis() - lastDataMillis;
	avgMsCounter = msCounter*interpolateSampling + avgMsCounter*(1.0f-interpolateSampling);
	avgSamplingRateHz = 1.0f / (avgMsCounter/1000.f);

	cout << "msCounter = \t" << msCounter << "ms \t avg: " << avgMsCounter << "ms\t " << avgSamplingRateHz << "Hz" << endl;
	lastDataMillis = ofGetElapsedTimeMillis();
	newData = true;
	clearedData = false;
}

void ofApp::onThinkgearHeartRate(ofxThinkgearEventArgs& args){
	// tgPoorSignal = int(args.poorSignal);
	cout << "onThinkgearHeartRate " << int(args.heartRate) << endl;
}

void ofApp::onThinkgearBlinkStrength(ofxThinkgearEventArgs& args){
    // blink.value = args.blinkStrength;
    cout << "onThinkgearBlinkStrength " << int(args.blinkStrength) << endl;
}

void ofApp::onThinkgearAttention(ofxThinkgearEventArgs& args){
    tgAttention = int(args.attention);
    
    // cout << "onThinkgearAttention " << tgAttention << endl;
}

void ofApp::onThinkgearMeditation(ofxThinkgearEventArgs& args){
    tgMeditation = int(args.meditation);
    
    // cout << "onThinkgearMeditation " << tgMeditation << endl;
}

void ofApp::onThinkgearEeg(ofxThinkgearEventArgs& args){
	tgDelta = int(args.eegDelta);
	tgTheta = int(args.eegTheta);
	tgLowAlpha = int(args.eegLowAlpha);
	tgHighAlpha = int(args.eegHighAlpha);
	tgLowBeta = int(args.eegLowBeta);
	tgHighBeta = int(args.eegHighBeta);
	tgLowGamma = int(args.eegLowGamma);
	tgMidGamma = int(args.eegMidGamma);
	
	// cout << "onThinkgearEeg " << endl;
}

void ofApp::onThinkgearConnecting(ofxThinkgearEventArgs& args){
}
