//
// MUSE displayGraphs
// receive data from zeo_broadcast

import oscP5.*;
import netP5.*;


OscP5 oscP5;
/* a NetAddress contains the ip address and 
port number of a remote location in the network. */
NetAddress myBroadcastLocation; 

String broadcastIP = "192.168.1.9";
int broadcastPort = 5001;
int listeningPort = 12000;

PFont bigFont;
PFont smFont;

color[] binColor = { color(50,50,50), color(40,40,200), color(150,0,200), color(0,250,150), color(50,200,50)};
boolean displayData = false;
int maxmemory = 100;  // keep
int ram = 30;        // display
ArrayList samples; 

// muse
int museBattery = 0;
int[] museStatus;
float museEEGabsolute[][];
float museEEGrelative[][];
String[] museEEGwave = { "Delta", "Theta", "Alpha", "Beta", "Gamma"};
String[] museEEGhz = { "1-4", "5-8", "9-13", "13-30", "30-50" };
String[] museSensors = { "Left ear", "Left forehead", "Right forehead", "Right ear" };
int museBlink = 0;
int museJaw = 0;


class Sample {
  float[][] absolute;
  float[][] relative;
  
  Sample(){
    absolute = new float[4][5];
    relative = new float[4][5];
  }
}



void setup() {
  size(1200,850);
  
  clearValues();
  
  /* create a new instance of oscP5. 
   * 12000 is the port number you are listening for incoming osc messages.
   */
  oscP5 = new OscP5(this,listeningPort);

  /* the address of the osc broadcast server */
  myBroadcastLocation = new NetAddress(broadcastIP, broadcastPort);
  
  smFont = createFont("", 14);
  bigFont = createFont("", 32);
  textFont(bigFont);
  
  samples = new ArrayList();
  
  prepareExitHandler();
  connectOscClient();
}


void draw() {
  background(255);
  noStroke();
  textAlign(LEFT, TOP);
  
  textFont(bigFont);
  fill(255,0,0);
  
  text("MUSE", 50,50);
  
  textFont(smFont);
  fill(0,0,0);
  
  int x1 = 50;
  int x2 = x1+250;
  int y1 = 100;
  
  // muse
  // display all incoming data
  if (displayData) {
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
        text(museEEGwave[j] + " ("+museEEGhz[j]+")", x1+20, y1+=20);
        text(museEEGabsolute[i][j], x2, y1);
        text("relative: "+nf(museEEGrelative[i][j],0,4), x2+100, y1);
      }
    }
  }
  
  drawBins(50,100, 260, 180);
  drawAvgBin(50,360, 400, 300);
  
}

void drawBins(int x, int y, int w, int h) {
  
  int toplegend = 30;
  int legend = 30;
  int graphh = h - legend - toplegend;
  int graphw = w;
  int gap = 10;
  
  float scaleX = graphw / 5.0f;  // 5 frequency bins
  float scaleY = graphh / 1.0;  // scale height of frequency bins
  
  for (int sensor=0; sensor<4; sensor++) {
    
    pushMatrix();
    translate(x+(w+gap)*sensor, y);
    drawFrame(w,h);

    // draw legend
    fill(0); noStroke();
    textFont(smFont);
    textAlign(CENTER, TOP);
    textLeading(25);
    for(int i=0; i<5; i++) text(museEEGwave[i], (i+0.0)*scaleX, toplegend+graphh, scaleX, 30);
   
    // draw bins
    textFont(bigFont);
    textAlign(CENTER, TOP);
    text(museSensors[sensor], w/2,0);
    for(int i=0; i<5; i++) {
      fill(binColor[i],50);
      rect(i*scaleX, toplegend+graphh, scaleX, (float) museEEGabsolute[sensor][i]*scaleY*-1);
      fill(binColor[i]);
      rect(i*scaleX, toplegend+graphh, scaleX, (float) museEEGrelative[sensor][i]*scaleY*-1);
    }
    
    popMatrix();
  
  }
  
}

void drawAvgBin(int x, int y, int w, int h) {
  
  int toplegend = 30;
  int legend = 60;
  int graphh = h - legend - toplegend;
  int graphw = w;
  int gap = 10;
  
  float scaleX = graphw / 5.0f;  // 5 frequency bins
  float scaleY = graphh / 1.0;  // scale height of frequency bins
  
  pushMatrix();
  translate(x, y);
  drawFrame(w,h);

  // draw legend
  fill(0); noStroke();
  textFont(smFont);
  textAlign(CENTER, TOP);
  textLeading(25);
  for(int i=0; i<5; i++) text(museEEGwave[i], (i+0.0)*scaleX, toplegend+graphh, scaleX, 30);
  for(int i=0; i<5; i++) text(museEEGhz[i], (i+0.0)*scaleX, toplegend+graphh+25, scaleX, 30);
  
  // draw bins
  textFont(bigFont);
  textAlign(CENTER, TOP);
  text("Average Bins", w/2,0);
  for(int i=0; i<5; i++) {
    float avg_abs = 0;
    float avg_rel = 0;
    for (int s=0; s<4; s++) {
      avg_abs += museEEGabsolute[s][i]; 
      avg_rel += museEEGrelative[s][i]; 
    }
    avg_abs/=5.0;
    avg_rel/=5.0;
    fill(binColor[i],50);
    rect(i*scaleX, toplegend+graphh, scaleX, (float) avg_abs*scaleY*-1);
    fill(binColor[i]);
    rect(i*scaleX, toplegend+graphh, scaleX, (float) avg_rel*scaleY*-1);
  }
  
  popMatrix();

  
}







void drawFrame(int w, int h) {
  noFill(); stroke(200);
  rect(0,0,w,h);
}




/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  // theOscMessage.print();
  
  Sample sample = new Sample();
  
  // muse
  if (theOscMessage.addrPattern().equals("/muse/elements/horseshoe")) {
      for (int i=0; i<4; i++) museStatus[i] = int(theOscMessage.get(i).floatValue());
  } else if (theOscMessage.addrPattern().equals("/muse/config")) {
    String config_json = theOscMessage.get(0).stringValue();
    JSONObject jo = JSONObject.parse(config_json);
    museBattery = jo.getInt("battery_percent_remaining");
  } else if (theOscMessage.addrPattern().equals("/muse/elements/delta_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[i][0] = theOscMessage.get(i).floatValue();
      sample.absolute[i][0] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/theta_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[i][1] = theOscMessage.get(i).floatValue();
      sample.absolute[i][1] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/alpha_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[i][2] = theOscMessage.get(i).floatValue();
      sample.absolute[i][2] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/beta_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[i][3] = theOscMessage.get(i).floatValue();
      sample.absolute[i][3] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/gamma_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[i][4] = theOscMessage.get(i).floatValue();
      sample.absolute[i][4] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/delta_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[i][0] = theOscMessage.get(i).floatValue();
      sample.relative[i][0] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/theta_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[i][1] = theOscMessage.get(i).floatValue();
      sample.relative[i][1] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/alpha_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[i][2] = theOscMessage.get(i).floatValue();
      sample.relative[i][2] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/beta_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[i][3] = theOscMessage.get(i).floatValue();
      sample.relative[i][3] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/gamma_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[i][4] = theOscMessage.get(i).floatValue();
      sample.relative[i][4] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/blink")) {
    museBlink = theOscMessage.get(0).intValue();
  } else if (theOscMessage.addrPattern().equals("/muse/elements/jaw_clench")) {
    museJaw = theOscMessage.get(0).intValue();
  } 
  
  samples.add(sample);
  
  if(samples.size() > maxmemory) {
    samples.remove(0);
  }
  
}


void clearValues() {
  
  // muse
  museBattery = 0;
  museStatus = new int[4];
  for (int i=0; i<4; i++) museStatus[i] = 4;
  museEEGabsolute = new float[4][5];
  museEEGrelative = new float[4][5];
  for (int i=0; i<4; i++) {
    for (int j=0; j<5; j++) {
      museEEGabsolute[i][j] = 0;
      museEEGrelative[i][j] = 0;
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




