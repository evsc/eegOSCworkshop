//
// MUSE / THINKGEAR draw frequency bins incircular graph
// receive data from eeg_broadcast


import oscP5.*;
import netP5.*;


int whichHeadset = 0;       // 0... muse, 1... thinkgear



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
int ram = 10;        // display
int ramP = 0;
int[] ramSteps = { 10, 35, 100, 200, 400 };
ArrayList samples; 

// INTERPOLATION
int[] interpolateSteps = { 1, 5, 10, 25, 50, 100 };
int interpol = 0;
int interpolate = 1;  // in the time graph, how many samples to average across


boolean displayData = false;

// thinkgear
float tgEEG[];
String[] tgEEGband = { "Delta", "Theta", "Low Alpha", "High Alpha", "Low Beta", "High Beta", "Low Gamma", "Mid Gamma"};
String[] tgEEGhz = { "0.5-2.75", "3.5-6.75", "7.5-9.25", "10-11.75", "13-16.75", "18-29.75", "31-39.75", "41-49.75"};

/// simplify, group together 2x alpha, 2x beta, and 2x gamma bins
String[] EEGwave = { "Delta", "Theta", "Alpha", "Beta", "Gamma"};
String[] EEGhz = { "0.5-3", "3.5-7", "7-12", "13-30", "30-50" };

// muse
float museEEGabsolute[][];
float museEEGrelative[][];

String[] museEEGwave = { "Delta", "Theta", "Alpha", "Beta", "Gamma"};
String[] museEEGhz = { "1-4", "5-8", "9-13", "13-30", "30-50" };






boolean pause = false;
boolean block = false;



class Sample {

  float[] absolute;
  float[] relative;

  Sample(){
    if (whichHeadset==1) {
      absolute = new float[5];
      relative = new float[5];
    } else {
      absolute = new float[8];
      relative = new float[8];
    }
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

  tgEEG = new float[8];
  for (int i=0; i<8; i++) tgEEG[i] = 0;
  
  
  museEEGabsolute = new float[4][5];
  museEEGrelative = new float[4][5];
  for (int i=0; i<4; i++) {
    for (int j=0; j<5; j++) {
      museEEGabsolute[i][j] = 0;
      museEEGrelative[i][j] = 0;
    }
  }
  
}


void draw() {
  
  if (!pause) {
    background(bgColor);
    noStroke();
    textAlign(LEFT, TOP);
    
    textFont(bigFont);
    fill(mainColor);
    
    text("Muse", 50,50);
    textFont(smFont);
    text("interpolate", 300, 55);
    text("ram", 300, 70);
    if(block) text("blocked input", 500, 62);
    textAlign(RIGHT, TOP);
    text(interpolate, 420, 55);
    text(ram, 420, 70);
    textAlign(LEFT, TOP);
    
 
    drawRing(50,150,650,650);
    



  }
}




void drawFrame(int w, int h) {
  noFill(); stroke(200);
  rect(0,0,w,h);
}







void drawRing(int x, int y, int w, int h) {
  
  int maxB = 5;  // Muse
  if (whichHeadset == 1) {
    maxB = 8;    // thinkGear
  }
  
  pushMatrix();
  translate(x, y);
  drawFrame(w,h);
  
  
  float radius = w/2 - 100;
  float multi = PI*2 / float(maxB);
  float minr = 0.3;
  
  String displayText = "";
  for(int b=0; b<maxB; b++) {
    textAlign(CENTER, BOTTOM);
    displayText = (whichHeadset == 0) ? museEEGwave[b] : tgEEGband[b];
    text(displayText, w/2 + cos(b*multi) * (radius+50), h/2 + sin(b*multi) * (radius+50));
    textAlign(CENTER, TOP);
    displayText = (whichHeadset == 0) ? museEEGhz[b] : tgEEGhz[b];
    text(displayText, w/2 + cos(b*multi) * (radius+50), h/2 + sin(b*multi) * (radius+50));
  }
 


  ArrayList last10 = new ArrayList();
  
  noFill();
  if(samples.size() > 1) {
    
    int m = min(ram, samples.size());
    float avg_abs = 0;
    float avg_rel = 0;
    int cnts = 0;
    int i = 0;
    
    strokeWeight(5.0);
    
    
    for(i=m-1; i>=0; i--) {
      Sample sample = (Sample) samples.get(samples.size()-i-1);
//        last10.add(sample);
//        if(last10.size() > interpolate) last10.remove(0);
//        last10.clear();
      
      cnts = 0;
      
      
      stroke(255, 150- i*(150/float(ram))); 
      if (i==0) stroke(255,255,0);
      noFill();
      beginShape();
      
      
      for(int b=0; b<5; b++) {
        float v = sample.relative[b] + minr;
       
        vertex(w/2 + cos(b*multi) * v*radius, h/2 + sin(b*multi) * v*radius);
        // vertex(w/2 + cos(b*multi) * radius, h/2 + sin(b*multi) * radius);
      
      }
      endShape(CLOSE);
        
    }
    

    
    
  }

  
  
  popMatrix();
  strokeWeight(1.0);
  
}


















/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
//  theOscMessage.print();
  
  if(block) return;
  
  
  // thinkgear
  if (theOscMessage.addrPattern().equals("/thinkgear/eeg")) {
    for (int i=0; i<8; i++) tgEEG[i] = int(theOscMessage.get(i).floatValue());
  
    //// 
    Sample sample = new Sample();

    
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

    samples.add(sample);
  
    if(samples.size() > maxmemory) {
      samples.remove(0);
    }
    
  }
  
  
  // muse
  if (theOscMessage.addrPattern().equals("/muse/elements/horseshoe")) {

        //// THERE'S AT LEAST THIS VALUE ONCE PER ROUND
      Sample sample = new Sample();
      // use left forehead values
      sample.relative[0] = museEEGrelative[1][0];
      sample.relative[1] = museEEGrelative[1][1];
      sample.relative[2] = museEEGrelative[1][2];
      sample.relative[3] = museEEGrelative[1][3];
      sample.relative[4] = museEEGrelative[1][4];
      samples.add(sample);
    
      if(samples.size() > maxmemory) {
        samples.remove(0);
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
  }
  
  
}



void keyPressed() {
  switch(key) {
    case('p'):
      String daytime = nf(year(),4,0) + nf(month(),2,0) + nf(day(),2,0) + "_"+ nf(hour(),2,0) + nf(minute(),2,0) + nf(second(), 2,0);
      saveFrame("screenshots/tg_displaygraph_"+daytime+".png");
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