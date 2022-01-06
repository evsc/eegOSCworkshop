/*
 * MUSE_SIMPLE
 * receive data from eeg_broadcast_3
 *
 * display brainwave data as graph
 */

import oscP5.*;
import netP5.*;


/*********************NETWORK SETTINGS**************************/
// CHANGE THE IP ADDRESS TO THE IP ADDRESS OF THE OSC SERVER !!
String broadcastIP = "192.168.0.101";

// CHANGE TO THE OSC PATTERN OF THE MUSE YOU WANT TO DISPLAY
String patternMuse = "/Person2";

OscP5 oscP5;
NetAddress myBroadcastLocation; 
int broadcastPort = 5001;
int listeningPort = 12000;
/***************************************************************/



/*****************************MUSE DATA**************************/

int museBattery = 0;
int museStatus[];
float museFrequencyBands[];

String[] museEEGwave = { "Delta", "Theta", "Alpha", "Beta", "Gamma"};
String[] museEEGhz = { "1-4", "5-8", "9-13", "13-30", "30-50" };
/***************************************************************/




/*********************DISPLAY SETTINGS**************************/
PFont bigFont;

// COLORS
color[] binColor = { color(0,0,50), color(40,40,250), color(180,0,230), color(0,250,150), color(255,50,0)};
color textColor = color(0);
color bgColor = color(200);
/***************************************************************/





void setup() {
  
  size(800,600);
  
  museBattery = 0;
  museStatus = new int[4];
  for (int i=0; i<4; i++) {
    museStatus[i] = 4;
  }
  museFrequencyBands = new float[5];
  for (int j=0; j<5; j++) {
    museFrequencyBands[j] = 0;
  }
  
  
  /* create a new instance of oscP5. 
   * 12000 is the port number you are listening for incoming osc messages.
   */
  oscP5 = new OscP5(this,listeningPort);

  /* the address of the osc broadcast server */
  myBroadcastLocation = new NetAddress(broadcastIP, broadcastPort);
  
  bigFont = createFont("", 30);
  textFont(bigFont);
  
  prepareExitHandler();
  connectOscClient();
}



void draw() {
  
  background(bgColor);
  
  noStroke();
  textAlign(LEFT, TOP);
  
  fill(textColor);
  textFont(bigFont);
  text("MUSE_SIMPLE", 20,20);
  
  text("muse", 460,20);
  text(patternMuse, 600, 20);
  text("battery", 460,50);
  text(museBattery + " %", 600, 50);
  text("status", 460,80);
  text(museStatus[0]+" "+museStatus[1]+" "+museStatus[2]+" "+museStatus[3], 600, 80);
  
  
  
  // draw frequency bins
  int margin = 50;
  float bin_width = (width - margin*2) / 5.0f;
  float bin_height = (height -margin*3) / 1.0f;
  
  
  textAlign(CENTER, TOP);
  for(int i=0; i<5; i++) {
    fill(binColor[i]);
    rect(margin+i*bin_width, margin+bin_height, bin_width, (float) museFrequencyBands[i]*-bin_height);
    text(nfs(museFrequencyBands[i],0,2), margin+i*bin_width+bin_width/2,margin+bin_height+museFrequencyBands[i]*-bin_height-35);
  }
  
  // draw legend
  fill(textColor); 
  textLeading(25);
  for(int i=0; i<5; i++) text(museEEGwave[i], margin+i*bin_width+bin_width/2, margin+bin_height+5);
  for(int i=0; i<5; i++) text(museEEGhz[i]+ "Hz", margin+i*bin_width+bin_width/2, margin+bin_height+35);
  
  
  
}




/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  //theOscMessage.print();
  

  // only let through the signals of the Muse unit we want to listen to
  if (!theOscMessage.addrPattern().substring(0,patternMuse.length()).equals(patternMuse)) {
    return;
  }
  
  
  String addp = theOscMessage.addrPattern().substring(patternMuse.length());
  
  if (addp.equals("/batt")) {
    museBattery = theOscMessage.get(0).intValue();
  } 
  
  else if (addp.equals("/horseshoe")) {
    for (int i=0; i<4; i++) museStatus[i] = theOscMessage.get(i).intValue();  
  } 
  
  else if (addp.equals("/delta")) {
    museFrequencyBands[0] = theOscMessage.get(0).floatValue();
  } 
  
  else if (addp.equals("/theta")) {
    museFrequencyBands[1] = theOscMessage.get(0).floatValue();
  } 
  
  else if (addp.equals("/alpha")) {
    museFrequencyBands[2] = theOscMessage.get(0).floatValue();
  } 
  
  else if (addp.equals("/beta")) {
    museFrequencyBands[3] = theOscMessage.get(0).floatValue();
  } 
  
  else if (addp.equals("/gamma")) {
    museFrequencyBands[4] = theOscMessage.get(0).floatValue();
  }
  
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
