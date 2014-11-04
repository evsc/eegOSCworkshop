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


	// update GUI 
	if (tg.isReady) {
		connectInfo->setTextString("connected");
    } else {
    	connectInfo->setTextString("trying to connect ...");
    }

    attentionLabel->setLabel("Attention 0-100: " + ofToString(tgAttention));
    meditationLabel->setLabel("Meditation 0-100: " + ofToString(tgMeditation));
    deltaLabel->setLabel("Delta 0-1500000: " + ofToString(tgDelta));
    thetaLabel->setLabel("Theta 0-600000: " + ofToString(tgTheta));
    lowAlphaLabel->setLabel("Low Alpha 0-75000: " + ofToString(tgLowAlpha));
    highAlphaLabel->setLabel("High Alpha 0-150000: " + ofToString(tgTheta));
    lowBetaLabel->setLabel("Low Beta 0-60000: " + ofToString(tgTheta));
    highBetaLabel->setLabel("High Beta 0-60000: " + ofToString(tgTheta));
    lowGammaLabel->setLabel("Low Gamma 0-300000: " + ofToString(tgTheta));
    midGammaLabel->setLabel("Mid Gamma 0-300000: " + ofToString(tgTheta));

}

//--------------------------------------------------------------
void ofApp::draw(){

	ofBackground(180);



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
    gui1->addSlider("Signal Quality 0-200", 0.0f, 255.0f, &tgPoorSignal);


    gui1->setPosition(0, 0);
    gui1->autoSizeToFitWidgets();

}


void ofApp::setGUI2() {

	int bufferSize = 10;
    vector<float> buffer;
    for (int i = 0; i < bufferSize; i++) {
        buffer.push_back(0.0);
    }

	gui2 = new ofxUISuperCanvas("INTERPRETATIVE", 220, 0, 300, 800);
	gui2->addSpacer();

	attentionGraph = gui2->addMovingGraph("ATTENTION", buffer, bufferSize, 0.0, 100.0);
	attentionLabel = gui2->addLabel("Attention 0-100: ", OFX_UI_FONT_SMALL);

	meditationGraph = gui2->addMovingGraph("MEDITATION", buffer, bufferSize, 0.0, 100.0);
	meditationLabel = gui2->addLabel("Meditation 0-100: ", OFX_UI_FONT_SMALL);


    gui2->autoSizeToFitWidgets();

}

void ofApp::setGUI3() {

	int bufferSize = 10;
    vector<float> buffer;
    for (int i = 0; i < bufferSize; i++) {
        buffer.push_back(0.0);
    }

	// gui3 = new ofxUISuperCanvas("EEG BANDS");
	gui3 = new ofxUISuperCanvas("EEG BANDS", 600, 0, 400, 800);

	gui3->addSpacer();

	deltaGraph = gui3->addMovingGraph("DELTA", buffer, bufferSize, 0.0, 1500000.0);
	deltaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	thetaGraph = gui3->addMovingGraph("THETA", buffer, bufferSize, 0.0, 600000.0);
	thetaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	lowAlphaGraph = gui3->addMovingGraph("LOW ALPHA", buffer, bufferSize, 0.0, 75000.0);
	lowAlphaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	highAlphaGraph = gui3->addMovingGraph("HIGH ALPHA", buffer, bufferSize, 0.0, 150000.0);
	highAlphaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	lowBetaGraph = gui3->addMovingGraph("LOW BETA", buffer, bufferSize, 0.0, 60000.0);
	lowBetaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	highBetaGraph = gui3->addMovingGraph("HIGH BETA", buffer, bufferSize, 0.0, 60000.0);
	highBetaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	lowGammaGraph = gui3->addMovingGraph("LOW GAMMA", buffer, bufferSize, 0.0, 300000.0);
	lowGammaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);

	midGammaGraph = gui3->addMovingGraph("MID GAMMA", buffer, bufferSize, 0.0, 300000.0);
	midGammaLabel = gui3->addLabel(" ", OFX_UI_FONT_SMALL);


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
	// cout << "onThinkgearPoorSignal " << int(args.poorSignal) << endl;
}

void ofApp::onThinkgearBlinkStrength(ofxThinkgearEventArgs& args){
    // blink.value = args.blinkStrength;
    cout << "onThinkgearBlinkStrength " << int(args.blinkStrength) << endl;
}

void ofApp::onThinkgearAttention(ofxThinkgearEventArgs& args){
    tgAttention = int(args.attention);
    attentionGraph->addPoint(tgAttention);
    // cout << "onThinkgearAttention " << tgAttention << endl;
}

void ofApp::onThinkgearMeditation(ofxThinkgearEventArgs& args){
    tgMeditation = int(args.meditation);
    meditationGraph->addPoint(tgMeditation);
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
	deltaGraph->addPoint(tgDelta);
	thetaGraph->addPoint(tgTheta);
	lowAlphaGraph->addPoint(tgLowAlpha);
	highAlphaGraph->addPoint(tgHighAlpha);
	lowBetaGraph->addPoint(tgLowBeta);
	highBetaGraph->addPoint(tgHighBeta);
	lowGammaGraph->addPoint(tgLowGamma);
	midGammaGraph->addPoint(tgMidGamma);
}

void ofApp::onThinkgearConnecting(ofxThinkgearEventArgs& args){
}
