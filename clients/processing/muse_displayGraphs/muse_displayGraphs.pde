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

color[] binColor = { color(50,50,50), color(40,40,200), color(150,0,200), color(0,250,150), color(250,150,0)};
color statusColor = color(255,0,0);
color concentrationColor = color(250, 50, 130);
color mellowColor = color(50,200,50);
boolean displayData = false;
int maxmemory = 2001;  // keep
int ram = 2000;        // display
ArrayList samples; 
int interpolate = 50;  // in the time graph, how many samples to average across

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
float muse_concentration = 0;
float muse_mellow = 0;


class Sample {
  float[][] absolute;
  float[][] relative;
  int[] museStatus;
  float concentration;
  float mellow;
  String time;
  
  Sample(){
    absolute = new float[4][5];
    relative = new float[4][5];
    museStatus = new int[4];
    time = "00:00";
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
  //drawAvgBin(50,360, 400, 280);
  
  drawAvgGraph(50,360, 1100,280);
  drawExpGraph(50,700, 1100, 100);
  drawTimeline(50,650, 1100, 30);
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
    int cnts = 0;
    for (int s=0; s<4; s++) {
      if(!Float.isNaN(museEEGrelative[s][i])) {
        cnts++;
        avg_abs += museEEGabsolute[s][i]; 
        avg_rel += museEEGrelative[s][i]; 
      }
      
    }
    avg_abs/=cnts;
    avg_rel/=cnts;
    fill(binColor[i],50);
    rect(i*scaleX, toplegend+graphh, scaleX, (float) avg_abs*scaleY*-1);
    fill(binColor[i]);
    rect(i*scaleX, toplegend+graphh, scaleX, (float) avg_rel*scaleY*-1);
  }
  

  
  popMatrix();

  
}


void drawAvgGraph(int x, int y, int w, int h) {
  
  pushMatrix();
  translate(x, y);
  drawFrame(w,h);
  
  int legend = 70;
  int graphh = h;
  int graphw = w-legend;
  
  float scaleX = graphw / (float) (ram-1);  // 
  float scaleY = graphh / 0.6f;  // 
  
  textFont(smFont);
  textAlign(RIGHT, CENTER);
  for(float i=0.1; i<0.6; i+=0.1) {
    stroke(0); noFill();
    line(legend, graphh-i*scaleY, legend-5, graphh-i*scaleY);
    fill(0); noStroke();
    text( nf(i,0,1), legend-20, graphh-i*scaleY );
    
  }

  int keyframe;  // draw these frames, and inteprolate previous x
  
  noFill();
  if(samples.size() > 1) {
    
    int m = min(ram, samples.size());
    float avg_abs = 0;
    float avg_rel = 0;
    int cnts = 0;
    for(int b=0; b<5; b++) {
      stroke(binColor[b]); 
      beginShape();
      strokeWeight(2.0);
      keyframe = interpolate;
      for(int i=0; i<m; i++) {
        Sample sample = (Sample) samples.get(samples.size()-i-1);
        
        try {
          for (int s=0; s<4; s++) {
            if(!Float.isNaN(sample.relative[s][b])) {
              cnts++;
              avg_abs += sample.relative[s][b]; 
              avg_rel += sample.relative[s][b]; 
            }
          }
        } catch (Exception c) {
          println("error");
        }
        if(keyframe >= interpolate) {
          keyframe = 0;  
          avg_abs/=cnts;
          avg_rel/=cnts;
          vertex(w-i*scaleX, graphh-avg_rel*scaleY);
          avg_abs = 0;
          avg_rel = 0;
          cnts = 0;
        }
        keyframe++;
        
      }
      endShape();
    }

    
  }
  
  
  popMatrix();
  strokeWeight(1.0);
  
}

void drawTimeline(int x, int y, int w, int h) {
  textAlign(RIGHT, TOP);
  pushMatrix();
  translate(x, y);
  int legend = 70;
  int graphw = w - legend;
  float scaleX = graphw / (float) (ram-1);  //
  
  fill(0);
  textFont(smFont);
  
  
  
  if(samples.size() > 1) {
    
    int m = min(ram, samples.size());
    
    int minDist = 100;
    int every = int(100.0 / (graphw / float(ram)));
    
    for(int i=0; i<m; i+=every) {
      Sample sample = (Sample) samples.get(samples.size()-i-1);
      text(sample.time, w-i*scaleX, 0);
    }
    
  }
  popMatrix();
  
}

void drawExpGraph(int x, int y, int w, int h) {
  
  textAlign(LEFT, TOP);
  pushMatrix();
  translate(x, y);
  drawFrame(w,h);
  
  int toplegend = 30;
  int legend = 70;
  int graphh = h - toplegend;
  int graphw = w-legend;
  
  float scaleX = graphw / (float) (ram-1);  // 
  float scaleY = graphh / 1.0f;  // 
  
  textFont(smFont);
  textAlign(RIGHT, CENTER);
  for(float i=0.25; i<1; i+=0.25) {
    stroke(0); noFill();
    line(legend, toplegend+graphh-i*scaleY, legend-5, toplegend+graphh-i*scaleY);
    fill(0); noStroke();
    text( nf(i,0,2), legend-20, toplegend+graphh-i*scaleY );
    
  }


  textAlign(LEFT, CENTER);
  noFill();
  if(samples.size() > 1) {
    
    int m = min(ram, samples.size());
    
    
    // draw status indicator
    fill(statusColor);
    text("status indicator", legend, 10);
    noFill();
    
    strokeWeight(1.0);
    for(int i=0; i<m; i++) {
      Sample sample = (Sample) samples.get(samples.size()-i-1);
      for(int s=0; s<4; s++) {
        stroke(statusColor);
        if(sample.museStatus[s] != 1) point(w-i*scaleX, 20+s*2);
      }
    }
    
    strokeWeight(2.0);
    
    fill(concentrationColor);
    text("concentration", legend+150,10);


    fill(concentrationColor,50);
    noStroke();
    beginShape();
    vertex(w,toplegend+graphh);
    for(int i=0; i<m; i++) {
      Sample sample = (Sample) samples.get(samples.size()-i-1);
      vertex(w-i*scaleX, toplegend+graphh-sample.concentration*scaleY);
    }
    vertex(w-m*scaleX,toplegend+graphh);
    endShape();
    
    // stroke only
    stroke(concentrationColor);
    noFill();
    beginShape();
    for(int i=0; i<m; i++) {
      Sample sample = (Sample) samples.get(samples.size()-i-1);
      vertex(w-i*scaleX, toplegend+graphh-sample.concentration*scaleY);
    }
    endShape();
    
    
    fill(mellowColor);
    text("mellow", legend + 300, 10);
    noStroke();
    fill(mellowColor,50);
    beginShape();
    vertex(w,toplegend+graphh);
    for(int i=0; i<m; i++) {
      Sample sample = (Sample) samples.get(samples.size()-i-1);
      vertex(w-i*scaleX, toplegend+graphh-sample.mellow*scaleY);
    }
    vertex(w-m*scaleX,toplegend+graphh);
    endShape();
    
    // stroke only
    stroke(mellowColor);
    noFill();
    beginShape();
    for(int i=0; i<m; i++) {
      Sample sample = (Sample) samples.get(samples.size()-i-1);
      vertex(w-i*scaleX, toplegend+graphh-sample.mellow*scaleY);
    }
    endShape();
    
    strokeWeight(1.0);
  }
  
  
  popMatrix();
  strokeWeight(1.0);
  
}



void drawFrame(int w, int h) {
  noFill(); stroke(200);
  rect(0,0,w,h);
}




/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  // theOscMessage.print();
  
  
  
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
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/theta_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[i][1] = theOscMessage.get(i).floatValue();
      
    }
    
    //// THETA ABSOLUTE SEEMS TO BE THE LAST OSC MSG 
    Sample sample = new Sample();
    for(int i=0; i<4; i++) {
      sample.absolute[i][0] = museEEGabsolute[i][0];
      sample.absolute[i][1] = museEEGabsolute[i][1];
      sample.absolute[i][2] = museEEGabsolute[i][2];
      sample.absolute[i][3] = museEEGabsolute[i][3];
      sample.absolute[i][4] = museEEGabsolute[i][4];
      sample.relative[i][0] = museEEGrelative[i][0];
      sample.relative[i][1] = museEEGrelative[i][1];
      sample.relative[i][2] = museEEGrelative[i][2];
      sample.relative[i][3] = museEEGrelative[i][3];
      sample.relative[i][4] = museEEGrelative[i][4];
      sample.museStatus[i] = museStatus[i];
    }
    sample.concentration = muse_concentration;
    sample.mellow = muse_mellow;
    sample.time = nf(hour(),2,0) + ":" + nf(minute(),2,0);
    samples.add(sample);
  
    if(samples.size() > maxmemory) {
      samples.remove(0);
    }
    
  } else if (theOscMessage.addrPattern().equals("/muse/elements/alpha_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[i][2] = theOscMessage.get(i).floatValue();
      
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/beta_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[i][3] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/gamma_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[i][4] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/delta_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[i][0] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/theta_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[i][1] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/alpha_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[i][2] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/beta_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[i][3] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/gamma_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[i][4] = theOscMessage.get(i).floatValue();
    }
  } else if (theOscMessage.addrPattern().equals("/muse/elements/blink")) {
    museBlink = theOscMessage.get(0).intValue();
  } else if (theOscMessage.addrPattern().equals("/muse/elements/jaw_clench")) {
    museJaw = theOscMessage.get(0).intValue();
  } else if (theOscMessage.addrPattern().equals("/muse/elements/experimental/concentration")) {
    muse_concentration = (theOscMessage.get(0).floatValue());
  }
  else if (theOscMessage.addrPattern().equals("/muse/elements/experimental/mellow")) {
    muse_mellow = (theOscMessage.get(0).floatValue());
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

void keyPressed() {
  switch(key) {
    case('p'):
      String daytime = nf(year(),4,0) + nf(month(),2,0) + nf(day(),2,0) + "_"+ nf(hour(),2,0) + nf(minute(),2,0) + nf(second(), 2,0);
      saveFrame("screenshots/muse_displaygraph_"+daytime+".png");
      break;
  }  
}




