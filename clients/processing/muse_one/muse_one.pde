/*
 * MUSE_ONE
 * receive data from eeg_broadcast_3
 *
 * display brainwave data in time series and as graphs
 */

import oscP5.*;
import netP5.*;



/*********************NETWORK SETTINGS**************************/
// CHANGE THE IP ADDRESS TO THE IP ADDRESS OF THE OSC SERVER !!
String broadcastIP = "192.168.0.100";

// CHANGE TO THE OSC PATTERN OF THE MUSE YOU WANT TO DISPLAY
String patternMuse = "/Person2";

OscP5 oscP5;
NetAddress myBroadcastLocation; 
int broadcastPort = 5001;
int listeningPort = 12000;

boolean pause = false;
boolean block = false;
/***************************************************************/





/*****************************MUSE DATA**************************/

int museBattery = 0;
int museStatus[];
float museFrequencyBands[];

ArrayList samples; 

class MuseSample {
  float[] relative;
  int[] museStatus;
  String time;
  
  MuseSample(){
    relative = new float[5];
    museStatus = new int[4];
    time = "00:00";
  }
}

String[] museEEGwave = { "Delta", "Theta", "Alpha", "Beta", "Gamma"};
String[] museEEGhz = { "1-4", "5-8", "9-13", "13-30", "30-50" };

// MEMORY
int maxmemory = 2001;  // how many samples to store in memory
int ram = 500;        // how many samples to display
int ramP = 1;
int[] ramSteps = { 100, 500, 1000, 1500, 2000 };

// INTERPOLATION
int[] interpolateSteps = { 1, 10, 50, 100, 200, 400 };
int interpol = 3;
int interpolate = 100;  // in the time graph, how many samples to average across

/***************************************************************/




/*********************DISPLAY SETTINGS**************************/

PFont bigFont;
PFont smFont;

// COLORS
color[] binColor = { color(0,0,50), color(40,40,250), color(180,0,230), color(0,250,150), color(255,50,0)};
color textColor = color(0);
color titleColor = color(0,100,200);
color bgColor = color(200);

boolean displayAvg = false;

/***************************************************************/




void setup() {
  size(1175,680);
  
  clearValues();
  
  
  /* create a new instance of oscP5. 
   * 12000 is the port number you are listening for incoming osc messages.
   */
  oscP5 = new OscP5(this,listeningPort);

  /* the address of the osc broadcast server */
  myBroadcastLocation = new NetAddress(broadcastIP, broadcastPort);
  
  smFont = createFont("", 18);
  bigFont = createFont("", 30);
  textFont(bigFont);
  
  samples = new ArrayList(1);

  prepareExitHandler();
  connectOscClient();
}


void draw() {
  
  if (!pause) {
    
    background(bgColor);
    noStroke();
    textAlign(LEFT, TOP);

    fill(titleColor);
    textFont(bigFont);
    text("MUSE_ONE", 20,20);
    
    
    // FREQUENCY BINS
    drawBin(650,20, 500, 250);
   
    // TIME GRAPH
    drawTimeSeries(20,300, 1130,350);
    
    
    
    textAlign(LEFT, TOP);
    fill(textColor);
    textFont(bigFont);
    int y = 30;
    text("muse", 20,y+=30);
    text(patternMuse, 220, y);
    text("battery", 20, y+=30);
    text(museBattery +" %", 220, y);
    text("interpolate [i]", 20, y+=30);
    text(interpolate, 220, y);
    text("ram [r]", 20, y+=30);
    text(ram, 220, y);
    if(block) text("blocked input", 20, y+=30);
    
    
    
    // write out average across RAM
    float[] sum = new float[5];
    int cnts = 0;
    int m = min(ram, samples.size());
    for (int i=samples.size()-m; i<samples.size(); i++) {
      MuseSample f = (MuseSample) samples.get(i);
      for (int b=0; b<5; b++) {
        sum[b] += f.relative[b];
      }
      cnts++;
    }
      
    if (cnts > 0 && displayAvg) {
      fill(textColor);
      y+=30;
      text("averaged",20,y+30);
      for (int b=0; b<5; b++) {
        fill(binColor[b]);
        float avg = sum[b]/cnts;
        text(museEEGwave[b], 220, y+=30);
        text(avg, 420, y);
      }
      y-=50;
    }
    
    fill(150);
    text(int(frameRate)+" FPS", 20, y+=60);
   
  }
 
}


void drawBin(int x, int y, int w, int h) {
  
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
  fill(textColor); noStroke();
  textFont(smFont);
  textAlign(CENTER, TOP);
  textLeading(25);
  for(int i=0; i<5; i++) text(museEEGwave[i], (i+0.0)*scaleX, toplegend+graphh, scaleX, 30);
  for(int i=0; i<5; i++) text(museEEGhz[i], (i+0.0)*scaleX, toplegend+graphh+25, scaleX, 30);
  
  //// draw bins
  textFont(bigFont);
  textAlign(CENTER, TOP);
  text("Relative Frequency Bands", w/2,10);

  for(int i=0; i<5; i++) {
    fill(binColor[i]);
    rect(i*scaleX, toplegend+graphh, scaleX, (float) museFrequencyBands[i]*scaleY*-1);
    text(nfs(museFrequencyBands[i],0,2), i*scaleX+scaleX/2, toplegend+graphh-35+museFrequencyBands[i]*scaleY*-1);
  }
  
  
  
  popMatrix();

  
}








void drawTimeSeries(int x, int y, int w, int h) {
  
  pushMatrix();
  translate(x, y);
  drawFrame(w,h);
  
  int legend = 70;
  int graphh = h;
  int graphw = w-legend;
  
  float scaleX = graphw / (float) (ram-1);  // 
  float scaleY = graphh / 0.7f;  // 
  
  textFont(bigFont);
  fill(textColor);
  textAlign(LEFT, TOP);
  String title = "Relative Frequency Band Time Series";
  text(title, legend+10, 10);

  // draw legend
  textFont(smFont);
  textAlign(RIGHT, CENTER);
  float topLegend = 0.6;
  float addLegend = 0.1;
  for(float i=0.1; i<topLegend; i+=addLegend) {
    stroke(textColor); noFill();
    line(legend, graphh-i*scaleY, legend-5, graphh-i*scaleY);
    fill(textColor); noStroke();
    text( nf(i,0,1), legend-20, graphh-i*scaleY-3 );
  }
  

  ArrayList lastX = new ArrayList();
  
  noFill();
  if(samples.size() > 1) {
    
    // minimum number of samples
    int m = min(ram, samples.size());

    for(int b=0; b<5; b++) {
      
      int i = 0;
      
      fill(binColor[b],150); 
      if(b==4) fill(binColor[b],220);
      beginShape();
      vertex(w, graphh); // right end of graph
      lastX.clear();
      
      int cnts = 0;
      float interpolated = 0;
      
      for(i=0; i<m; i++) {
        
        cnts = 0;
        float interSum = 0;
        MuseSample sample = (MuseSample) samples.get(samples.size()-i-1);
        lastX.add(sample);
        if(lastX.size() > interpolate) lastX.remove(0);
          
        for (int c=0; c<interpolate; c++) {
          if(lastX.size()-c > 0) {
            MuseSample f = (MuseSample) lastX.get(lastX.size()-c-1);
            interSum += f.relative[b];
            cnts++;
          }
        }  
        interpolated = interSum/cnts;
        vertex(w-(i)*scaleX, graphh-interpolated*scaleY);
      }
      
      vertex(w-(i-2)*scaleX, graphh);
      endShape();
    }
    
    
    
    textAlign(RIGHT, TOP);
    fill(textColor);
    textFont(smFont);
    int every = int(200.0 / (graphw / float(ram)));
    
    for(int i=0; i<m; i+=every) {
      MuseSample sample = (MuseSample) samples.get(samples.size()-i-1);
      text(sample.time, w-i*scaleX, 40);
    }
    
    
    // draw status indicator
    strokeWeight(1.0);
    for(int i=0; i<m; i++) {
      MuseSample sample = (MuseSample) samples.get(samples.size()-i-1);
      for(int s=0; s<4; s++) {
        stroke(textColor);
        if(sample.museStatus[s] != 1) point(w-i*scaleX, 65+s*2);
      }
    }
      

  }
  
  popMatrix();
  strokeWeight(1.0);
  
}










void drawFrame(int w, int h) {
  noFill(); stroke(textColor);
  rect(0,0,w,h);
}




/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  //theOscMessage.print();
  
  if(block) return;
  
  // only let through the signals of the Muse unit we want to listen to
  if (!theOscMessage.addrPattern().substring(0,patternMuse.length()).equals(patternMuse)) {
    return;
  }
  
  String addp = theOscMessage.addrPattern().substring(patternMuse.length());
  // println("addp "+addp + " muse "+muse);
  
  if (addp.equals("/batt")) {
    museBattery = theOscMessage.get(0).intValue();
  } else if (addp.equals("/horseshoe")) {
      for (int i=0; i<4; i++) museStatus[i] = theOscMessage.get(i).intValue();
      
        //// HORSESHOE happens at least once per round,
        //// so let's store the last values in memory now!
      MuseSample sample = new MuseSample();
      for(int i=0; i<5; i++) {
       sample.relative[i] = museFrequencyBands[i];
      }
      for(int i=0; i<4; i++) {
       sample.museStatus[i] = museStatus[i];
      }
      sample.time = nf(hour(),2,0) + ":" + nf(minute(),2,0);
      samples.add(sample);
    
      if(samples.size() > maxmemory) {
       samples.remove(0);
      }
      
      
  } else if (addp.equals("/delta")) {
    museFrequencyBands[0] = theOscMessage.get(0).floatValue();
  } else if (addp.equals("/theta")) {
    museFrequencyBands[1] = theOscMessage.get(0).floatValue();
  } else if (addp.equals("/alpha")) {
    museFrequencyBands[2] = theOscMessage.get(0).floatValue();
  } else if (addp.equals("/beta")) {
    museFrequencyBands[3] = theOscMessage.get(0).floatValue();
  } else if (addp.equals("/gamma")) {
    museFrequencyBands[4] = theOscMessage.get(0).floatValue();
  }
  
  
  
}


void clearValues() {
  
  museBattery = 0;
  
  museStatus = new int[4];
  for (int i=0; i<4; i++) {
    museStatus[i] = 4;
  }
  museFrequencyBands = new float[5];
  for (int j=0; j<5; j++) {
    museFrequencyBands[j] = 0;
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

void keyPressed() {
  switch(key) {
    case('a'):
      displayAvg = !displayAvg;
      break;
    case('p'):
      String daytime = nf(year(),4,0) + nf(month(),2,0) + nf(day(),2,0) + "_"+ nf(hour(),2,0) + nf(minute(),2,0) + nf(second(), 2,0);
      saveFrame("screenshots/muse_one_"+daytime+".png");
      break;
    case(' '):
      pause = !pause;
      println("pause");
      break;
    case('i'):
      interpol++;
      if(interpol >= interpolateSteps.length) interpol = 0;
      interpolate = interpolateSteps[interpol];
      println("new interpolation value = "+interpolate);
      break;
    case('r'):
      ramP++;
      if(ramP >= ramSteps.length) ramP = 0;
      ram = ramSteps[ramP];
      println("new ram value = "+ram);
      break;
    case('b'):
      block = !block;
      println("block now: "+block);
  }  
}
