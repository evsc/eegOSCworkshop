#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){

	devicePort = "/dev/rfcomm0";
	baudRate = 57600;


	tgPower = 0;
	tgPoorSignal = 0;
	tgBlinkStrength = 0;
	tgAttention = 0;
	tgMeditation = 0;

	hideGUI = false;
	setGUI1();
	setGUI2();
	setGUI3();
	gui1->loadSettings("gui1Settings.xml");
	gui2->loadSettings("gui2Settings.xml");
	gui3->loadSettings("gui3Settings.xml");


	tg.setup(devicePort, baudRate);
    tg.addEventListener(this);

}

//--------------------------------------------------------------
void ofApp::update(){

	tg.update();

}

//--------------------------------------------------------------
void ofApp::draw(){

	ofBackground(180);

	if (tg.isReady) {
		connectInfo->setTextString("connected");
        // ofSetColor(50, 250, 50);
    } else {
    	connectInfo->setTextString("trying to connect ...");
        // ofSetColor(250, 50, 50);
    }
    // ofRect(10, 10, 30, 30);

}




void ofApp::guiEvent(ofxUIEventArgs &e) {

	string name = e.getName();
	int kind = e.getKind();
	cout << "got event from: " << name << endl;

}



//--------------------------------------------------------------
void ofApp::exit() {
    // gui1->saveSettings("gui1Settings.xml");
    
	delete gui1;

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
    gui1->addSlider("Poor Signal <0-200> ", 0.0f, 255.0f, &tgPoorSignal);


    gui1->setPosition(0, 0);
    gui1->autoSizeToFitWidgets();

}


void ofApp::setGUI2() {

	gui2 = new ofxUISuperCanvas("INTERPRETATIVE");

	// attentionGraph = gui2->addMovingGraph("ATTENTION", buffer, 256, 0.0, 1.0);


    gui2->setPosition(220, 0);
    gui2->autoSizeToFitWidgets();

}

void ofApp::setGUI3() {

	gui3 = new ofxUISuperCanvas("EEG BANDS");


    gui3->setPosition(440, 0);
    gui3->autoSizeToFitWidgets();

}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){

	switch (key) {
		case 'h':
	        gui1->toggleVisible();
			break;
	}
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

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
}

void ofApp::onThinkgearPower(ofxThinkgearEventArgs& args){
    // power.value = args.power;
}

void ofApp::onThinkgearPoorSignal(ofxThinkgearEventArgs& args){
	tgPoorSignal = int(args.poorSignal);
	cout << "onThinkgearPoorSignal " << int(args.poorSignal) << endl;
    // poorsignal.value = args.poorSignal;
}

void ofApp::onThinkgearBlinkStrength(ofxThinkgearEventArgs& args){
    // blink.value = args.blinkStrength;
    cout << "onThinkgearBlinkStrength " << int(args.blinkStrength) << endl;
}

void ofApp::onThinkgearAttention(ofxThinkgearEventArgs& args){
    // attention.value = args.attention;
    cout << "onThinkgearAttention " << int(args.attention) << endl;
}

void ofApp::onThinkgearMeditation(ofxThinkgearEventArgs& args){
    // meditation.value = args.meditation;
    cout << "onThinkgearMeditation " << int(args.meditation) << endl;
}

void ofApp::onThinkgearEeg(ofxThinkgearEventArgs& args){
	cout << "eegLowAlpha\t" << int(args.eegLowAlpha) << endl;
	cout << "eegHighAlpha\t" << int(args.eegHighAlpha) << endl;
}

void ofApp::onThinkgearConnecting(ofxThinkgearEventArgs& args){
}
