#pragma once

#include "ofMain.h"
#include "ofxThinkgear.h"
#include "ofxUI.h"
#include "ofxUITextArea.h"

class ofApp : public ofBaseApp{

	public:
		void setup();
		void update();
		void draw();
		void exit();


		void keyPressed(int key);
		void keyReleased(int key);
		void mouseMoved(int x, int y );
		void mouseDragged(int x, int y, int button);
		void mousePressed(int x, int y, int button);
		void mouseReleased(int x, int y, int button);
		void windowResized(int w, int h);
		void dragEvent(ofDragInfo dragInfo);
		void gotMessage(ofMessage msg);


        void onThinkgearError(ofMessage& err);
		void onThinkgearReady(ofxThinkgearEventArgs& args);
        void onThinkgearRaw(ofxThinkgearEventArgs& args);
        void onThinkgearPower(ofxThinkgearEventArgs& args);
        void onThinkgearPoorSignal(ofxThinkgearEventArgs& args);
        void onThinkgearBlinkStrength(ofxThinkgearEventArgs& args);
        void onThinkgearAttention(ofxThinkgearEventArgs& args);
        void onThinkgearMeditation(ofxThinkgearEventArgs& args);
        void onThinkgearEeg(ofxThinkgearEventArgs& args);
        void onThinkgearConnecting(ofxThinkgearEventArgs& args);


        string devicePort;
        int baudRate;

        unsigned int tgPower;
        float tgPoorSignal;
        unsigned int tgBlinkStrength;
        unsigned int tgAttention;
        unsigned int tgMeditation;

        vector<float> attentionV;
    

        // GUI
        void setGUI1();
        void setGUI2();
        void setGUI3();
        ofxUITextArea* connectInfo;
        ofxUISuperCanvas *gui1;
        ofxUISuperCanvas *gui2;
        ofxUISuperCanvas *gui3;
        bool hideGUI;

        void guiEvent(ofxUIEventArgs &e);

        ofxUIMovingGraph *attentionGraph;

    private:

        ofxThinkgear tg;
        ofxThinkgearEventArgs data;
		
};
