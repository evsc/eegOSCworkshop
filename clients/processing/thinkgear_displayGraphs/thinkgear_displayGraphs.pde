//
// THINKGEAR displayGraphs
// receive data from eeg_broadcast


import oscP5.*;
import netP5.*;


OscP5 oscP5;
/* a NetAddress contains the ip address and 
port number of a remote location in the network. */
NetAddress myBroadcastLocation; 

String broadcastIP = "192.168.0.101";
int broadcastPort = 5001;
int listeningPort = 12000;


PFont bigFont;
PFont smFont;

// COLORS
color[] binColor = { color(0,0,50), color(40,40,250), color(180,0,230), color(0,250,150), color(255,50,0)};
color statusColor = color(255,0,0);
color mainColor = color(255);
color bgColor = color(50);
color concentrationColor = color(250, 50, 130);
color mellowColor = color(50,200,50);


// MEMORY
int maxmemory = 2001;  // keep
int ram = 100;        // display
int ramP = 2;
int[] ramSteps = { 10, 35, 100, 200, 400 };
ArrayList samples; 

// INTERPOLATION
int[] interpolateSteps = { 1, 5, 10, 25, 50, 100 };
int interpol = 2;
int interpolate = 10;  // in the time graph, how many samples to average across


boolean displayData = false;

// thinkgear
int tgPoorSignal;
int tgAttention;
int tgMeditation;
int tgEEG[];
String[] tgEEGband = { "Delta (0.5-2.75)", "Theta (3.5-6.75)", "Low Alpha (7.5-9.25)", "High Alpha (10-11.75)", "Low Beta (13-16.75)", "High Beta (18-29.75)", "Low Gamma (31-39.75)", "Mid Gamma (41-49.75)"};


/// simplify, group together 2x alpha, 2x beta, and 2x gamma bins
String[] EEGwave = { "Delta", "Theta", "Alpha", "Beta", "Gamma"};
String[] EEGhz = { "0.5-3", "3.5-7", "7-12", "13-30", "30-50" };



int display = 4;
boolean pause = false;
boolean block = false;



class Sample {

  int[] absolute;
  float[] relative;
  int poorSignal;
  int attention;
  int meditation;
  String time;
  
  Sample(){
    absolute = new int[5];
    relative = new float[5];
    poorSignal = 200;    // 0 = good, 200 = bad
    attention = 0;
    meditation = 0;
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

void clearValues() {
  
  tgPoorSignal = 200;
  tgAttention = 0;
  tgMeditation = 0;
  tgEEG = new int[8];
  for (int i=0; i<8; i++) tgEEG[i] = 0;
  
}


void draw() {
  
  if (!pause) {
    background(bgColor);
    noStroke();
    textAlign(LEFT, TOP);
    
    textFont(bigFont);
    fill(mainColor);
    
    text("ThinkGear", 50,50);
    textFont(smFont);
    text("interpolate", 300, 55);
    text("ram", 300, 70);
    if(block) text("blocked input", 500, 62);
    textAlign(RIGHT, TOP);
    text(interpolate, 420, 55);
    text(ram, 420, 70);
    textAlign(LEFT, TOP);
    
    fill(mainColor);
    
    if (displayData) {
      int x1 = 50;
      int x2 = x1+250;
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

    
    // 
    
    drawTimeSeries(50,200, 1100,500, true);
      
    drawTimeSeriesStatus(50,700, 1100, 30);
    drawTimeSeriesTime(50,730, 1100, 30);
    drawExpGraph(50,750, 1100, 70);
    
    for(int b=0; b<5; b++) {
      fill(binColor[b]);
      text(EEGwave[b] + " " + EEGhz[b] + " Hz", 500, 50+20*b);  
    }
    
    drawRamBin(800,50, 350, 130);


  }
}




void drawFrame(int w, int h) {
  noFill(); stroke(200);
  rect(0,0,w,h);
}




void drawRamBin(int x, int y, int w, int h) {
  
  int toplegend = 30;
  int legend = 0;
  int graphh = h - legend - toplegend;
  int graphw = w;
  int gap = 10;
  
  float scaleX = graphw / 5.0f;  // 5 frequency bins
  float scaleY = graphh / 1.0;  // scale height of frequency bins
  
  pushMatrix();
  translate(x, y);
  drawFrame(w,h);

  // draw legend
  fill(mainColor); noStroke();
  textFont(smFont);
  textAlign(CENTER, TOP);
  textLeading(25);
//  for(int i=0; i<5; i++) text(museEEGwave[i], (i+0.0)*scaleX, toplegend+graphh, scaleX, 30);
//  for(int i=0; i<5; i++) text(museEEGhz[i], (i+0.0)*scaleX, toplegend+graphh+25, scaleX, 30);
  

  int m = min(ram, samples.size());
  
  for(int i=0; i<5; i++) {
    
    float avg_abs = 0;
    float avg_rel = 0;
    int cnts = 0;
  
    for(h=0; h<m; h++) {
      Sample sample = (Sample) samples.get(samples.size()-h-1);

      if(!Float.isNaN(sample.relative[i])) {
        cnts++;
        avg_abs += sample.relative[i]; 
        avg_rel += sample.relative[i]; 
      }

    }
    
    avg_rel/=cnts;
//    avg_abs/=cnts;
//    fill(binColor[i],50);
//    rect(i*scaleX, toplegend+graphh, scaleX, (float) avg_abs*scaleY*-1);
    fill(binColor[i]);
    rect(i*scaleX, toplegend+graphh, scaleX, (float) avg_rel*scaleY*-1);
  
    textFont(smFont);
    textAlign(CENTER, TOP);
    fill(mainColor);
    textLeading(25);
    text(nf(avg_rel,0,2), (i+0.0)*scaleX, toplegend+graphh, scaleX, 30);
  }

  
  popMatrix();

  
}






void drawTimeSeriesTime(int x, int y, int w, int h) {
  textAlign(RIGHT, TOP);
  pushMatrix();
  translate(x, y);
  int legend = 70;
  int graphw = w - legend;
  float scaleX = graphw / (float) (ram-1);  //
  
  fill(mainColor);
  textFont(smFont);
  
  
  
  if(samples.size() > 1) {
    
    int m = min(ram, samples.size());
    
    
    int minDist = 100;
    int every = int(100.0 / (graphw / float(m)));
    // println("m "+m+"   every = "+every);
    if(every < 1) every = 1;
    
    for(int i=0; i<m; i+=every) {
      Sample sample = (Sample) samples.get(samples.size()-i-1);
      text(sample.time, w-i*scaleX, 0);
    }
    
  }
  popMatrix();
  
}




void drawTimeSeriesStatus(int x, int y, int w, int h) {
  
  pushMatrix();
  translate(x, y);
  int legend = 70;
  int graphw = w - legend;
  float scaleX = graphw / (float) (ram-1);  //
  
  
  if(samples.size() > 1) {
    
    int m = min(ram, samples.size());
    
    
    // draw status indicator
    fill(statusColor);
//    text("status indicator", legend, 10);
    noFill();
    
    strokeWeight(1.0);
    for(int i=0; i<m; i++) {
      Sample sample = (Sample) samples.get(samples.size()-i-1);
      stroke(statusColor);
      if(sample.poorSignal != 0) rect(w-i*scaleX, 20, 1, sample.poorSignal);
    }

  }
  
  popMatrix();
}



void drawTimeSeries(int x, int y, int w, int h, boolean filled) {
  
  pushMatrix();
  translate(x, y);
  drawFrame(w,h);
  
  int legend = 70;
  int graphh = h;
  int graphw = w-legend;
  
  float scaleX = graphw / (float) (ram-1);  // 
  float scaleY = graphh / 1.0f;  // 

  // draw legend
  textFont(smFont);
  textAlign(RIGHT, CENTER);
  for(float i=0.1; i<0.7; i+=0.1) {
    stroke(mainColor); noFill();
    line(legend, graphh-i*scaleY, legend-5, graphh-i*scaleY);
    fill(mainColor); noStroke();
    text( nf(i,0,1), legend-20, graphh-i*scaleY );
    
  }
  

  ArrayList last10 = new ArrayList();
  
  noFill();
  if(samples.size() > 1) {
    
    int m = min(ram, samples.size());
    float avg_abs = 0;
    float avg_rel = 0;
    int cnts = 0;
    int i = 0;
    

    if(filled) {
      
      for(int b=0; b<5; b++) {
        fill(binColor[b],150); 
        if(b==4) fill(binColor[b],220);
        beginShape();
        vertex(w, graphh);
        last10.clear();
        for(i=0; i<m; i++) {
          Sample sample = (Sample) samples.get(samples.size()-i-1);
          last10.add(sample);
          if(last10.size() > interpolate) last10.remove(0);
            
            cnts = 0;
            if(!Float.isNaN(sample.relative[b])) {
              avg_rel += sample.relative[b];
              cnts++;
            }
            for (int c=1; c<interpolate; c++) {
              if(last10.size()-1-c > 0) {
                Sample f = (Sample) last10.get(last10.size()-1-c);
                if(!Float.isNaN(f.relative[b])) {
                  avg_rel += f.relative[b];
                  cnts++;
                }
              }
            }  
            avg_rel/=cnts;
            vertex(w-(i)*scaleX, graphh-avg_rel*scaleY);
            avg_rel = 0;
          
        }
        vertex(w-(i-1)*scaleX, graphh);
        endShape();
      }
      
    }

    
  }
  
  
  popMatrix();
  strokeWeight(1.0);
  
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
  float scaleY = graphh / 100f;  // 
  
  textFont(smFont);
  textAlign(RIGHT, CENTER);
  for(int i=30; i<100; i+=30) {
    stroke(mainColor); noFill();
    line(legend, toplegend+graphh-i*scaleY, legend-5, toplegend+graphh-i*scaleY);
    fill(mainColor); noStroke();
    text( i, legend-20, toplegend+graphh-i*scaleY );
    
  }


  textAlign(LEFT, CENTER);
  noFill();
  if(samples.size() > 1) {
    
    int m = min(ram, samples.size());
    
    strokeWeight(2.0);
    
    fill(concentrationColor);
    text("attention", legend+150,10);


    fill(concentrationColor,50);
    noStroke();
    beginShape();
    vertex(w,toplegend+graphh);
    for(int i=0; i<m; i++) {
      Sample sample = (Sample) samples.get(samples.size()-i-1);
      vertex(w-i*scaleX, toplegend+graphh-sample.attention*scaleY);
    }
    vertex(w-m*scaleX,toplegend+graphh);
    endShape();
    
    // stroke only
    stroke(concentrationColor);
    noFill();
    beginShape();
    for(int i=0; i<m; i++) {
      Sample sample = (Sample) samples.get(samples.size()-i-1);
      vertex(w-i*scaleX, toplegend+graphh-sample.attention*scaleY);
    }
    endShape();
    
    
    fill(mellowColor);
    text("meditation", legend + 300, 10);
    noStroke();
    fill(mellowColor,50);
    beginShape();
    vertex(w,toplegend+graphh);
    for(int i=0; i<m; i++) {
      Sample sample = (Sample) samples.get(samples.size()-i-1);
      vertex(w-i*scaleX, toplegend+graphh-sample.meditation*scaleY);
    }
    vertex(w-m*scaleX,toplegend+graphh);
    endShape();
    
    // stroke only
    stroke(mellowColor);
    noFill();
    beginShape();
    for(int i=0; i<m; i++) {
      Sample sample = (Sample) samples.get(samples.size()-i-1);
      vertex(w-i*scaleX, toplegend+graphh-sample.meditation*scaleY);
    }
    endShape();
    
    strokeWeight(1.0);
  }
  
  
  popMatrix();
  strokeWeight(1.0);
  
}

















/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
//  theOscMessage.print();
  
  if(block) return;
  
  
  // thinkgear
  if (theOscMessage.addrPattern().equals("/thinkgear/attention")) {
    tgAttention = theOscMessage.get(0).intValue();
  } else if (theOscMessage.addrPattern().equals("/thinkgear/meditation")) {
    tgMeditation = theOscMessage.get(0).intValue();
    

    
    
    
  } else if (theOscMessage.addrPattern().equals("/thinkgear/poorsignal")) {
    tgPoorSignal = theOscMessage.get(0).intValue();
    

    
    
  } else if (theOscMessage.addrPattern().equals("/thinkgear/eeg")) {
    for (int i=0; i<8; i++) tgEEG[i] = int(theOscMessage.get(i).floatValue());
    
    
        
        
    //// 
    Sample sample = new Sample();
    
    sample.attention = tgAttention;
    sample.meditation = tgMeditation;
    sample.poorSignal = tgPoorSignal;
    
    sample.absolute[0] = tgEEG[0];
    sample.absolute[1] = tgEEG[1];
    sample.absolute[2] = tgEEG[2] + tgEEG[3];
    sample.absolute[3] = tgEEG[4] + tgEEG[5];
    sample.absolute[4] = tgEEG[6] + tgEEG[7];
    
    float total = 0;
    for (int i=0; i<8; i++) total += tgEEG[i];

    sample.relative[0] = sample.absolute[0]/total;  // delta
    sample.relative[1] = sample.absolute[1]/total;  // theta
    sample.relative[2] = sample.absolute[2]/total;  // alpha
    sample.relative[3] = sample.absolute[3]/total;  // beta
    sample.relative[4] = sample.absolute[4]/total;  // gamma
    
    println("delta = "+sample.relative[0]);
    
    sample.time = nf(hour(),2,0) + ":" + nf(minute(),2,0);
    samples.add(sample);
  
    if(samples.size() > maxmemory) {
      samples.remove(0);
    }
    
  }
  
  
}



void keyPressed() {
  switch(key) {
    case('p'):
      String daytime = nf(year(),4,0) + nf(month(),2,0) + nf(day(),2,0) + "_"+ nf(hour(),2,0) + nf(minute(),2,0) + nf(second(), 2,0);
      saveFrame("screenshots/tg_displaygraph_"+daytime+".png");
      break;
    case('d'):
      display++;
      if(display >4) display = 1;
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



