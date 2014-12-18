


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


// zeo
int zeoSleepState = 0;
float[] zeoEEG;
String[] zeoStageName = { "", "Wake", "REM", "Light", "Deep" };
String[] zeoEEGband = { "Delta", "Theta", "Alpha", "Beta1", "Beta2", "Beta3", "Gamma" };
String[] zeoEEGHertz = { "2-4", "4-8", "8-13", "13-18", "18-21", "11-14", "30-50"};





void setup() {
  size(1200,400);
  
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
  
  text("ThinkGear", 450,50);
  text("Zeo", 850,50);
  
  textFont(smFont);
  fill(0);
  int x1 = 10;
  int x2 = x1+250;
  int y1 = 100;
  
  // thinkgear
  x1 = 450;
  x2 = x1+260;
  y1 = 100;
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
  
  // thinkgear
  x1 = 850;
  x2 = x1+200;
  y1 = 100;
  text("sleepState", x1, y1+=20);
  text(zeoSleepState + " (" + zeoStageName[zeoSleepState]+ ")", x2, y1);
  y1+=20;
  for(int i=0; i<7; i++) {
    text(zeoEEGband[i] + " (" + zeoEEGHertz[i] + ")", x1, y1+=20);
    text(zeoEEG[i], x2, y1);
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
  
  // zeo
  if (theOscMessage.addrPattern().equals("/zeo/slice")) {
    if(theOscMessage.checkTypetag("fffffff")) {
      for(int i=0; i<7; i++) {
        zeoEEG[i] = theOscMessage.get(i).floatValue();
      }
    }
  } else if (theOscMessage.addrPattern().equals("/zeo/state")) {
    if(theOscMessage.checkTypetag("i")) {
      zeoSleepState = theOscMessage.get(0).intValue();
    }
  }
  
  
  
}


void clearValues() {
  
  // thinkgear
  tgPoorSignal = 200;
  tgAttention = 0;
  tgMeditation = 0;
  tgEEG = new int[8];
  for (int i=0; i<8; i++) tgEEG[i] = 0;
  
  // zeo
  zeoSleepState = 0;
  zeoEEG = new float[7];
  for (int i=0; i<7; i++) zeoEEG[i] = 0;
  
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

  
