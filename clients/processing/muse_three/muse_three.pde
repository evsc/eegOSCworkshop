/*
 * MUSE_THREE
 * receive data from eeg_broadcast_3
 *
 * display brainwave data in time series and as graphs
 */

import oscP5.*;
import netP5.*;



/*********************NETWORK SETTINGS**************************/
// CHANGE THE IP ADDRESS TO THE IP ADDRESS OF THE OSC SERVER !!
String broadcastIP = "127.0.0.1";

String[] patternMuse = { "/Person1", "/Person2", "/Person3" };

OscP5 oscP5;
NetAddress myBroadcastLocation; 
int broadcastPort = 5001;
int listeningPort = 12000;

boolean pause = false;
boolean block = false;
/***************************************************************/





/*****************************MUSE DATA**************************/

ArrayList muses;

class Muse {
  
  int id;
  String patternMuse;
  int museBattery = 0;
  int museStatus[];
  float museFrequencyBands[];
  ArrayList samples; 
  
  Muse(int _id, String _name) {
    id = _id;
    patternMuse = _name;
    clearValues();
    samples = new ArrayList(1);
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
  
}

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
int ram = 1500;        // how many samples to display
int ramP = 3;
int[] ramSteps = { 100, 500, 1000, 1500, 2000 };

// INTERPOLATION
int[] interpolateSteps = { 1, 10, 50, 100, 200, 400 };
int interpol = 4;
int interpolate = 200;  // in the time graph, how many samples to average across

/***************************************************************/




/*********************DISPLAY SETTINGS**************************/

PFont bigFont;
PFont smFont;

// COLORS
color[] binColor = { color(0,0,50), color(40,40,250), color(180,0,230), color(0,250,150), color(255,50,0)};
color textColor = color(0);
color titleColor = color(0,100,200);
color bgColor = color(200);

/***************************************************************/




void setup() {
  size(1200,900);
  
  muses = new ArrayList();
  for(int i=0; i<patternMuse.length; i++) {
    Muse m = new Muse(i,patternMuse[i]);
    muses.add(m);
  }
  
  
  /* create a new instance of oscP5. 
   * 12000 is the port number you are listening for incoming osc messages.
   */
  oscP5 = new OscP5(this,listeningPort);

  /* the address of the osc broadcast server */
  myBroadcastLocation = new NetAddress(broadcastIP, broadcastPort);
  
  smFont = createFont("", 18);
  bigFont = createFont("", 30);
  textFont(bigFont);

  prepareExitHandler();
  connectOscClient();
}


void draw() {
  
  if (!pause) {
    
    background(bgColor);
    noStroke();
    textAlign(LEFT, TOP);
    
    int y = 20;
    int x = 20;

    fill(titleColor);
    textFont(bigFont);
    text("MUSE_THREE", x,y+=30);
    fill(150);
    text(int(frameRate)+" FPS", width-150,y);
    text("interpolate [i]", x, y+=30);
    text(interpolate, x+220, y);
    text("ram [r]", x, y+=30);
    text(ram, x+220, y);  
    

    
    for(int _m=0; _m<muses.size(); _m++) {
      
      y = 100;
      
      Muse m = (Muse) muses.get(_m);

      textAlign(LEFT, TOP);
      fill(textColor);
      textFont(bigFont);
      
      text("muse", x,y+=50);
      text(m.patternMuse, x+150, y);
      text("battery", x, y+=30);
      text(m.museBattery +" %", x+150, y);

      // FREQUENCY BINS
      drawBin(m, x,y+=40, 370, 300);
     
      // TIME GRAPH
      drawTimeSeries(m, x,y+=320, 370,300);
    
      // write out average across RAM
      float[] sum = new float[5];
      int cnts = 0;
      int min = min(ram, m.samples.size());
      for (int i=0; i<min; i++) {
        MuseSample f = (MuseSample) m.samples.get(i);
        for (int b=0; b<5; b++) {
          sum[b] += f.relative[b];
        }
        cnts++;
      }
      
      if (cnts > 0) {
        y+=300;
        textFont(bigFont);
        for (int b=0; b<5; b++) {
          fill(binColor[b]);
          float avg = sum[b]/cnts;
          text(nfs(avg,0,2), 30+x+b*370/5.0, y);
        }
      }
    
      x+=390;
      
    }
    
    
    
    
    

    
    
    

    
    
   
  }
 
}


void drawBin(Muse m, int x, int y, int w, int h) {
  
  //Muse m = (Muse) muses.get(_m);
  
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

  for(int i=0; i<5; i++) {
    fill(binColor[i]);
    rect(i*scaleX, toplegend+graphh, scaleX, (float) m.museFrequencyBands[i]*scaleY*-1);
    text(nfs(m.museFrequencyBands[i],0,2), i*scaleX+scaleX/2, toplegend+graphh-35+m.museFrequencyBands[i]*scaleY*-1);
  }
  
  
  
  popMatrix();

  
}








void drawTimeSeries(Muse m, int x, int y, int w, int h) {
  
  //Muse m = (Muse) muses.get(_m);
  
  pushMatrix();
  translate(x, y);
  drawFrame(w,h);
  
  int graphh = h;
  int graphw = w;
  
  float scaleX = graphw / (float) (ram-1);  // 
  float scaleY = graphh / 0.7f;  // 

  ArrayList lastX = new ArrayList();
  
  if(m.samples.size() > 1) {
    
    // minimum number of samples
    int min = min(ram, m.samples.size());

    for(int b=0; b<5; b++) {
      
      int i = 0;
      
      fill(binColor[b],150); noStroke();
      if(b==4) fill(binColor[b],220);
      beginShape();
      vertex(w, graphh); // right end of graph
      lastX.clear();
      
      int cnts = 0;
      float interpolated = 0;
      
      for(i=0; i<min; i++) {
        
        cnts = 0;
        float interSum = 0;
        MuseSample sample = (MuseSample) m.samples.get(m.samples.size()-i-1);
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
  
  int whichMuse = -1;
      
  for( int i=0; i<muses.size(); i++) {
    if (theOscMessage.addrPattern().substring(0,patternMuse[i].length()).equals(patternMuse[i])) {
      whichMuse = i;
    }
  }
  
  if (whichMuse != -1) {
    
    Muse m = (Muse) muses.get(whichMuse);

    String addp = theOscMessage.addrPattern().substring(patternMuse[whichMuse].length());
    // println("addp "+addp + " muse "+muse);
    
    if (addp.equals("/batt")) {
      m.museBattery = theOscMessage.get(0).intValue();
    } else if (addp.equals("/horseshoe")) {
        for (int i=0; i<4; i++) m.museStatus[i] = theOscMessage.get(i).intValue();
        
          //// HORSESHOE happens at least once per round,
          //// so let's store the last values in memory now!
        MuseSample sample = new MuseSample();
        for(int i=0; i<5; i++) {
         sample.relative[i] = m.museFrequencyBands[i];
        }
        for(int i=0; i<4; i++) {
         sample.museStatus[i] = m.museStatus[i];
        }
        sample.time = nf(hour(),2,0) + ":" + nf(minute(),2,0);
        m.samples.add(sample);
      
        if(m.samples.size() > maxmemory) {
         m.samples.remove(0);
        }
        
        
    } else if (addp.equals("/delta")) {
      m.museFrequencyBands[0] = theOscMessage.get(0).floatValue();
    } else if (addp.equals("/theta")) {
      m.museFrequencyBands[1] = theOscMessage.get(0).floatValue();
    } else if (addp.equals("/alpha")) {
      m.museFrequencyBands[2] = theOscMessage.get(0).floatValue();
    } else if (addp.equals("/beta")) {
      m.museFrequencyBands[3] = theOscMessage.get(0).floatValue();
    } else if (addp.equals("/gamma")) {
      m.museFrequencyBands[4] = theOscMessage.get(0).floatValue();
    }
  
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
    case('p'):
      String daytime = nf(year(),4,0) + nf(month(),2,0) + nf(day(),2,0) + "_"+ nf(hour(),2,0) + nf(minute(),2,0) + nf(second(), 2,0);
      saveFrame("screenshots/muse_three_"+daytime+".png");
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
