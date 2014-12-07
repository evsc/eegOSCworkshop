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
        void onThinkgearHeartRate(ofxThinkgearEventArgs& args);
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
        int tgRaw;


        void resetDataValues();

        unsigned int tgDelta;      // 100000 / 1500000 . 0.5-2.75hz
        unsigned int tgTheta;      // 300000 / 600000 . 3.5-6.75hz
        unsigned int tgLowAlpha;   // 2500 / 75000 . 7.5-9.25hz
        unsigned int tgHighAlpha;  // 2500 / 150000 . 10-11.75hz
        unsigned int tgLowBeta;    // 1500 / 60000 . 13-16.75hz
        unsigned int tgHighBeta;   // 2500 / 60000 . 18-29.75hz
        unsigned int tgLowGamma;   // 5000 / 300000 . 31-39.75hz
        unsigned int tgMidGamma;   // 5000 / 300000 . 41-49.75hz
    

        // GUI
        void setGUI1();
        void setGUI2();
        void setGUI3();
        ofxUITextArea* connectInfo;
        ofxUISuperCanvas *gui1;
        ofxUISuperCanvas *gui2;
        ofxUISuperCanvas *gui3;
        bool hideGUI;
        bool insertRawData;

        void guiEvent(ofxUIEventArgs &e);

        ofxUIMovingGraph *incomingDataGraph;

        ofxUILabel *attentionLabel;
        ofxUIMovingGraph *attentionGraph;
        ofxUILabel *meditationLabel;
        ofxUIMovingGraph *meditationGraph;
        ofxUILabel *rawLabel;
        ofxUIMovingGraph *rawGraph;

        ofxUILabel *deltaLabel;
        ofxUIMovingGraph *deltaGraph;
        ofxUILabel *thetaLabel;
        ofxUIMovingGraph *thetaGraph;
        ofxUILabel *lowAlphaLabel;
        ofxUIMovingGraph *lowAlphaGraph;
        ofxUILabel *highAlphaLabel;
        ofxUIMovingGraph *highAlphaGraph;
        ofxUILabel *lowBetaLabel;
        ofxUIMovingGraph *lowBetaGraph;
        ofxUILabel *highBetaLabel;
        ofxUIMovingGraph *highBetaGraph;
        ofxUILabel *lowGammaLabel;
        ofxUIMovingGraph *lowGammaGraph;
        ofxUILabel *midGammaLabel;
        ofxUIMovingGraph *midGammaGraph;

        // 
        unsigned int lastDataMillis;
        float msCounter;
        float avgMsCounter;
        float avgSamplingRateHz;
        float interpolateSampling;
        bool newData;
        
        float beatCounter;
        float beat;
        bool clearedData;
        float clearCounter;
        int bufferSize;


    private:

        ofxThinkgear tg;
        ofxThinkgearEventArgs data;
		
};
