


import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myBroadcastLocation; 

String broadcastIP = "192.168.0.100";
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


// muse
int museBattery = 0;
int[] museStatus;
float museEEG[][];
String[] museEEGband = { "Delta (1-4)", "Theta (508)", "Alpha (9-13)", "Beta (13-30)", "Gamma (30-50)"};
String[] museSensors = { "Left ear", "Left forehead", "Right forehead", "Right ear" };
int museBlink = 0;
int museJaw = 0;



void setup() {
  size(1200,850);
  
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
  
  text("MUSE", 50,50);
  text("ThinkGear", 450,50);
  text("Zeo", 850,50);
  
  textFont(smFont);
  fill(0);
  int x1 = 50;
  int x2 = x1+250;
  int y1 = 100;
  
  // muse
  text("battery", x1, y1+=20);
  text(museBattery + " %", x2, y1);
  y1+=20;
  text("status_indicator", x1, y1+=20);
  text(museStatus[0] + " " + museStatus[1] + " " + museStatus[2] + " " + museStatus[3], x2, y1);
  text("blink", x1, y1+=20);
  text(museBlink, x2, y1);
  text("jaw_clench", x1, y1+=20);
  text(museJaw, x2, y1);
  for(int i=0; i<4; i++) {
    text(museSensors[i], x1, y1+=40);
    for (int j=0; j<5; j++) {
      text(museEEGband[j], x1+20, y1+=20);
      text(museEEG[i][j], x2, y1);
    }
  }
  
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
  
  // muse
  if (theOscMessage.addrPattern().equals("/muse/elements/horseshoe")) {
      for (int i=0; i<4; i++) museStatus[i] = int(theOscMessage.get(i).floatValue());
  } else if (theOscMessage.addrPattern().equals("/muse/config")) {
    String config_json = theOscMessage.get(0).stringValue();
    JSONObject jo = JSONObject.parse(config_json);
    museBattery = jo.getInt("battery_percent_remaining");
  } else if (theOscMessage.addrPattern().equals("/muse/elements/delta_relative")) {
    for(int i=0; i<4; i++) {
      museEEG[i][0] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/theta_relative")) {
    for(int i=0; i<4; i++) {
      museEEG[i][1] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/alpha_relative")) {
    for(int i=0; i<4; i++) {
      museEEG[i][2] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/beta_relative")) {
    for(int i=0; i<4; i++) {
      museEEG[i][3] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/gamma_relative")) {
    for(int i=0; i<4; i++) {
      museEEG[i][4] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/blink")) {
    museBlink = theOscMessage.get(0).intValue();
  } else if (theOscMessage.addrPattern().equals("/muse/elements/jaw_clench")) {
    museJaw = theOscMessage.get(0).intValue();
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
  
  // muse
  museBattery = 0;
  museStatus = new int[4];
  for (int i=0; i<4; i++) museStatus[i] = 4;
  museEEG = new float[4][5];
  for (int i=0; i<4; i++) {
    for (int j=0; j<5; j++) {
      museEEG[i][j] = 0;
    }
  }
  museBlink = 0;
  museJaw = 0;
  
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

  