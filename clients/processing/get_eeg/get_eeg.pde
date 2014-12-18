


import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myBroadcastLocation; 

String broadcastIP = "10.0.0.16";
int broadcastPort = 5001;
int listeningPort = 12000;

PFont bigFont;
PFont smFont;


// thinkgear
int tgPoorSignal;
int tgAttention;
int tgMeditation;
int tgEEG[];
String[] tgEEGband = { "Delta (0.5-2.75)", "Theta (3.5-6.75)", "Low Alpha (7.5-9.25)", "High Alpha (10-11.75)", "Low Beta (13-16.75)", "High Beta (18-29.75)", "Low Gamma (31-39.75)", "Mid Gamma (41-49.75)"};


void setup() {
  size(1000,400);
  
  clearValues();
  
  /* create a new instance of oscP5. 
   * 12000 is the port number you are listening for incoming osc messages.
   */
  oscP5 = new OscP5(this,listeningPort);

  /* the address of the osc broadcast server */
  myBroadcastLocation = new NetAddress(broadcastIP, broadcastPort);
  
  smFont = createFont("", 20);
  bigFont = createFont("", 40);
  textFont(bigFont);
  
  prepareExitHandler();
  connectOscClient();
}

void draw() {
  background(255);
  noStroke();
  
  
  
  
  textFont(bigFont);
  fill(255,0,0);
  text("ThinkGear", 300,50);
  
  textFont(smFont);
  fill(0);
  
  // thinkgear
  int x1 = 300;
  int x2 = x1+260;
  int y1 = 100;
  text("poorSignal", x1, y1+=20);
  text(tgPoorSignal, x2, y1);
  text("attention", x1, y1+=20);
  text(tgAttention, x2, y1);
  text("meditation", x1, y1+=20);
  text(tgMeditation, x2, y1);
  
  y1+=20;
  for(int i=0; i<8; i++) {
    text(tgEEGband[i], x1, y1+=20);
    text(tgEEG[i], x2, y1);
  }
  
  
}


void keyPressed() {
  switch(key) {
    case('c'):
      connectOscClient();
      break;
    case('d'):
      disconnectOscClient();
      break;
  }  
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  // theOscMessage.print();
  
  // thinkgear
  if (theOscMessage.addrPattern().equals("/thinkgear/attention")) {
    tgAttention = theOscMessage.get(0).intValue();
  } else if (theOscMessage.addrPattern().equals("/thinkgear/meditation")) {
    tgMeditation = theOscMessage.get(0).intValue();
  } else if (theOscMessage.addrPattern().equals("/thinkgear/poorsignal")) {
    tgPoorSignal = theOscMessage.get(0).intValue();
  } else if (theOscMessage.addrPattern().equals("/thinkgear/eeg")) {
    for (int i=0; i<8; i++) tgEEG[i] = int(theOscMessage.get(i).floatValue());
  }
}


void clearValues() {
  
  // thinkgear
  tgPoorSignal = 200;
  tgAttention = 0;
  tgMeditation = 0;
  tgEEG = new int[8];
  for (int i=0; i<8; i++) tgEEG[i] = 0;
  
}

void connectOscClient() {
  OscMessage m;
  println("connect");
  /* connect to the broadcaster */
  m = new OscMessage("/eeg/connect",new Object[0]);
  oscP5.flush(m,myBroadcastLocation);  
} 

void disconnectOscClient() {
  OscMessage m;
  println("disconnect");
  /* disconnect from the broadcaster */
  m = new OscMessage("/eeg/disconnect",new Object[0]);
  oscP5.flush(m,myBroadcastLocation);  
}


  
private void prepareExitHandler() {
 Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
   public void run () {
//     System.out.println("SHUTDOWN HOOK");
     try {
       disconnectOscClient();
     } catch (Exception ex){
       ex.printStackTrace(); // not much else to do at this point
     }
   }
 }));
}  

  
