//
// displayGraphs
// receive data from zeo_broadcast
// and display frequency bins and history graph

import oscP5.*;
import netP5.*;


OscP5 oscP5;
/* a NetAddress contains the ip address and 
port number of a remote location in the network. */
NetAddress myBroadcastLocation; 

String broadcastIP = "127.0.0.1";
int broadcastPort = 32000;



PFont myFontBig;
PFont myFont;

color[] binColor = { color(50,50,50), color(40,40,200), color(150,0,200), color(0,250,150), color(50,200,50), color(200,250,0), color(250,100,50) };
color[] stageColor = { color(255,255,255), color(255,0,0), color(50,255,50), color(150,150,150), color(0,150,0) };

String[] stageName = { "", "Wake", "REM", "Light", "Deep" };
String[] binName = { "Delta", "Theta", "Alpha", "Beta1", "Beta2", "Beta3", "Gamma" };
String[] binHertz = { "2-4", "4-8", "8-13", "13-18", "18-21", "11-14", "30-50"};


int lastSleepState = 0;
int maxmemory = 30;
ArrayList slices;  // keep last x slices in arraylist

class Slice {
  float[] frequencyBin;
  int sleepState;
  
  Slice() {
    frequencyBin = new float[7];
    sleepState = lastSleepState;
  }
}


void setup() {
  size(1024,768);
  frameRate(25);
  
  /* create a new instance of oscP5. 
   * 12000 is the port number you are listening for incoming osc messages.
   */
  oscP5 = new OscP5(this,12000);

  /* the address of the osc broadcast server */
  myBroadcastLocation = new NetAddress(broadcastIP, broadcastPort);
  
  
  myFont = createFont("", 20);
  textFont(myFont);
  myFontBig = createFont("", 40);
  
  slices = new ArrayList();  
  
  prepareExitHandler();
  connectOscClient();
}

void draw() {
  background(255);
  
  int px = 20;
  int py = 20;
  
  drawBins(px,py,980,300);
  py+=320;
  
  drawBinGraph(px, py, 980, 300);
  py+=320;
  
  drawStage(px, py, 980, 80);
  py+=100;
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
  
  if (theOscMessage.addrPattern().equals("/slice")) {
    if(theOscMessage.checkTypetag("fffffff")) {
      Slice _slice = new Slice();
      print("slice: \t");
      for(int i=0; i<7; i++) {
        _slice.frequencyBin[i] = theOscMessage.get(i).floatValue();
        print(nf(_slice.frequencyBin[i],2,3) + "  ");
      }
      println();
      slices.add(_slice);
    }
  } else if (theOscMessage.addrPattern().equals("/state")) {
    if(theOscMessage.checkTypetag("i")) {
      int sleepState = theOscMessage.get(0).intValue();
      println("sleepState\t" + sleepState);
      lastSleepState = sleepState;
    }
  }
}

void connectOscClient() {
  OscMessage m;
  println("connect");
  /* connect to the broadcaster */
  m = new OscMessage("/zeo/connect",new Object[0]);
  oscP5.flush(m,myBroadcastLocation);  
} 

void disconnectOscClient() {
  OscMessage m;
  println("disconnect");
  /* disconnect from the broadcaster */
  m = new OscMessage("/zeo/disconnect",new Object[0]);
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

