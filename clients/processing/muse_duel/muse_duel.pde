//
// MUSE displayGraphs
// receive data from eeg_broadcast


import oscP5.*;
import netP5.*;


OscP5 oscP5;
/* a NetAddress contains the ip address and 
port number of a remote location in the network. */
NetAddress myBroadcastLocation; 

String broadcastIP = "127.0.0.1";
int broadcastPort = 5001;
int listeningPort = 12000;

PFont bigFont;
PFont smFont;


// COLORS
color[] binColor = { color(0,0,50), color(40,40,250), color(180,0,230), color(0,250,150), color(255,50,0)};
color statusColor = color(255,0,0);
color concentrationColor = color(250, 50, 130);
color mellowColor = color(50,200,50);
color mainColor = color(255);
color bgColor = color(50);


boolean displayData = false;

// MEMORY
int maxmemory = 2001;  // keep
int ram = 1500;        // display
int ramP = 3;
int[] ramSteps = { 100, 500, 1000, 1500, 2000 };
ArrayList samples[]; 

// INTERPOLATION
int[] interpolateSteps = { 1, 10, 50, 100, 200, 400 };
int interpol = 4;
int interpolate = 200;  // in the time graph, how many samples to average across




// muse
//int museBattery = 0;
int museStatus[][];
float museEEGrelative[][][];
float museEEGabsolute[][][];
String[] museEEGwave = { "Delta", "Theta", "Alpha", "Beta", "Gamma"};
String[] museEEGhz = { "1-4", "5-8", "9-13", "13-30", "30-50" };
String[] museSensors = { "Left ear", "Left forehead", "Right forehead", "Right ear", "Avg ear", "Avg forehead" };
int museBlink[];
int museJaw[];
float muse_concentration[];
float muse_mellow[];


int display = 1;
boolean pause = false;
boolean block = false;



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
  bigFont = createFont("", 30);
  textFont(bigFont);
  
  samples = new ArrayList[2];
  samples[0] = new ArrayList();
  samples[1] = new ArrayList();
  
  prepareExitHandler();
  connectOscClient();
}


void draw() {
  if (!pause) {
    background(bgColor);
    noStroke();
    textAlign(LEFT, TOP);

    fill(255,0,0);

    textFont(smFont);
    text("interpolate", 200, 55);
    text("ram", 200, 70);
    if(block) text("blocked input", 400, 62);
    textAlign(RIGHT, TOP);
    text(interpolate, 320, 55);
    text(ram, 320, 70);
    textAlign(LEFT, TOP);
    
    
    fill(mainColor);
    
    int x1 = 50;
    int x2 = x1+250;
    int y1 = 100;
    
    
    if(display == 1) {
      
      textFont(bigFont);
      fill(255,0,0);
      text("MUSE 1", 50,50);
      
      for (int i=0; i<4; i++) {
        drawBin(0,50+280*i,100, 260, 260, i);
      }
     
      // TIME GRAPHS AVERAGES
      drawTimeSeries(0, 50,390, 1100,400, -1, true);
      drawTimeSeriesStatus(0, 50,790, 1100, 30);
      drawTimeSeriesTime(0, 50,820, 1100, 30);
      
    } else if (display == 2) {
      
      textFont(bigFont);
      fill(255,0,0);
      text("MUSE 2", 50,50);
      
      for (int i=0; i<4; i++) {
        drawBin(1,50+280*i,100, 260, 260, i);
      }
     
      // TIME GRAPHS AVERAGES
      drawTimeSeries(1, 50,390, 1100,400, -1, true);
      drawTimeSeriesStatus(1, 50,790, 1100, 30);
      drawTimeSeriesTime(1, 50,820, 1100, 30);
      
    } else if (display == 3) {
      
      textFont(bigFont);
      fill(255,0,0);
      text("MUSE 1", 50,50);
      text("MUSE 2", 50,450);
      
      drawRamBin(0, 50,100, 350, 240, 5);
      drawTimeSeries(0, 450,100, 700,300, 5, true);
      drawTimeSeriesStatus(0, 450,390, 700, 30);
      drawTimeSeriesTime(0, 450,420, 700, 30);
      
      drawRamBin(1, 50,500, 350, 240, 5);
      drawTimeSeries(1, 450,500, 700,300, 5, true);
      drawTimeSeriesStatus(1, 450,790, 700, 30);
      drawTimeSeriesTime(1, 450,820, 700, 30);
      
    }
  }
 
}


void drawBin(int muse, int x, int y, int w, int h, int displaysensor) {
  
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
  fill(mainColor); noStroke();
  textFont(smFont);
  textAlign(CENTER, TOP);
  textLeading(25);
  for(int i=0; i<5; i++) text(museEEGwave[i], (i+0.0)*scaleX, toplegend+graphh, scaleX, 30);
  for(int i=0; i<5; i++) text(museEEGhz[i], (i+0.0)*scaleX, toplegend+graphh+25, scaleX, 30);
  
  // draw bins
  textFont(bigFont);
  textAlign(CENTER, TOP);
  if(displaysensor==-1) text("Average Bins", w/2,10);
  else text(museSensors[displaysensor], w/2,10);

  for(int i=0; i<5; i++) {
    float avg_rel = 0;
    int cnts = 0;
    if(displaysensor==-1 || displaysensor>3) {
      for (int s=0; s<4; s++) {
        if(!Float.isNaN(museEEGrelative[muse][s][i])) {
          if ((displaysensor != 4 || (s==0 || s==3)) && (displaysensor != 5 || (s==1 || s==2))) {
            cnts++;
            avg_rel += museEEGrelative[muse][s][i]; 
          }
        }
        
      }
    } else {
      if(!Float.isNaN(museEEGrelative[muse][displaysensor][i])) {
        cnts++;
        avg_rel += museEEGrelative[muse][displaysensor][i]; 
      }
    }
    avg_rel/=cnts;
    fill(binColor[i]);
    rect(i*scaleX, toplegend+graphh, scaleX, (float) avg_rel*scaleY*-1);
  }
  
  
  
  popMatrix();

  
}




void drawRamBin(int muse, int x, int y, int w, int h, int displaysensor) {
  
  int toplegend = 30;
  int legend = 0;
  int graphh = h - legend - toplegend;
  int graphw = w;
  int gap = 10;
  
  float scaleX = graphw / 5.0f;  // 5 frequency bins
  float scaleY = graphh / 1.0;  // scale height of frequency bins
  
  pushMatrix();
  translate(x, y);
  

  // draw legend
  fill(mainColor); noStroke();
  textFont(smFont);
  textAlign(CENTER, TOP);
  textLeading(25);
 for(int i=0; i<5; i++) text(museEEGwave[i], (i+0.0)*scaleX, toplegend+graphh+30, scaleX, 30);
 for(int i=0; i<5; i++) text(museEEGhz[i], (i+0.0)*scaleX, toplegend+graphh+50, scaleX, 30);
  
  textFont(bigFont);
  textAlign(CENTER, TOP);
  String title = "";
  if(displaysensor==-1) text(title +"Avg Bins", w/2,10);
  else text(title +museSensors[displaysensor], w/2,10);

  
  int m = min(ram, samples[muse].size());
  
  
  for(int i=0; i<5; i++) {
    
    float avg_abs = 0;
    float avg_rel = 0;
    int cnts = 0;
  
    // but let's exclude the last ~5 seconds = ~50 samples
    // buffer time to get to the computer
    if (m > 50) {
      for(int h2=50; h2<m; h2++) {
        Sample sample = (Sample) samples[muse].get(samples[muse].size()-h2-1);
    
        
        
        if(displaysensor==-1 || displaysensor>3) {
          for (int s=0; s<4; s++) {
            if(!Float.isNaN(sample.relative[s][i])) {
              if ((displaysensor != 4 || (s==0 || s==3)) && (displaysensor != 5 || (s==1 || s==2))) {
                cnts++;
                avg_abs += sample.absolute[s][i]; 
                avg_rel += sample.relative[s][i]; 
              }
            }
            
          }
        } else {
          if(!Float.isNaN(sample.relative[displaysensor][i])) {
            cnts++;
            avg_abs += sample.relative[displaysensor][i]; 
            avg_rel += sample.relative[displaysensor][i]; 
          }
        }
  
      }
    }
    
    avg_abs/=cnts;
    avg_rel/=cnts;
    fill(binColor[i]);
    rect(i*scaleX, toplegend+graphh, scaleX, (float) avg_rel*scaleY*-1);
    
    textFont(smFont);
    textAlign(CENTER, TOP);
    fill(mainColor);
    textLeading(25);
    text(nf(avg_rel,0,2), (i+0.0)*scaleX, toplegend+graphh, scaleX, 30);
  
  }

  drawFrame(w,h);
  
  popMatrix();

  
}






void drawTimeSeries(int muse, int x, int y, int w, int h, int displaysensor, boolean filled ) {
  
  pushMatrix();
  translate(x, y);
  drawFrame(w,h);
  
  int legend = 70;
  int graphh = h;
  int graphw = w-legend;
  
  float scaleX = graphw / (float) (ram-1);  // 
  float scaleY = graphh / 0.7f;  // 
  
  textFont(bigFont);
  fill(mainColor);
  textAlign(LEFT, TOP);
  String title = "";
  if(displaysensor==-1) text(title +"All sensors", legend+10,10);
  else text(title +museSensors[displaysensor], legend+10, 10);

  // draw legend
  textFont(smFont);
  textAlign(RIGHT, CENTER);
  float topLegend = 0.7;
  //topLegend = 1.8;
  float addLegend = 0.1;
  //addLegend = 0.3;
  for(float i=0.1; i<topLegend; i+=addLegend) {
    stroke(mainColor); noFill();
    line(legend, graphh-i*scaleY, legend-5, graphh-i*scaleY);
    fill(mainColor); noStroke();
    text( nf(i,0,1), legend-20, graphh-i*scaleY );
    
  }
  

  ArrayList last10 = new ArrayList();
  
  noFill();
  if(samples[muse].size() > 1) {
    
    int m = min(ram, samples[muse].size());
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
          Sample sample = (Sample) samples[muse].get(samples[muse].size()-i-1);
          last10.add(sample);
          if(last10.size() > interpolate) last10.remove(0);
            
            cnts = 0;
            if (displaysensor==-1 || displaysensor>3) {
              for (int s=0; s<4; s++) {
                if ((displaysensor != 4 || (s==0 || s==3)) && (displaysensor != 5 || (s==1 || s==2))) {
                  if(!Float.isNaN(sample.relative[s][b])) {
                    avg_rel += sample.relative[s][b];
                    cnts++;
                  }
                }
              }
            } else {
              if(!Float.isNaN(sample.relative[displaysensor][b])) {
                avg_rel += sample.relative[displaysensor][b];
                cnts++;
              }
            }
            for (int c=1; c<interpolate; c++) {
              if(last10.size()-1-c > 0) {
                Sample f = (Sample) last10.get(last10.size()-1-c);
                if (displaysensor==-1 || displaysensor>3) {
                  for (int s=0; s<4; s++) {
                    if ((displaysensor != 4 || (s==0 || s==3)) && (displaysensor != 5 || (s==1 || s==2))) {
                      if(!Float.isNaN(f.relative[s][b])) {
                        avg_rel += f.relative[s][b];
                        cnts++;
                      }
                    }
                  }
                } else {
                  if(!Float.isNaN(f.relative[displaysensor][b])) {
                    avg_rel += f.relative[displaysensor][b];
                    cnts++;
                  }
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
      
    } else {
      noFill();
      for(int b=0; b<5; b++) {
        stroke(binColor[b]); 
        beginShape();
        strokeWeight(2.0);
        last10.clear();
        for(i=0; i<m; i++) {
          Sample sample = (Sample) samples[muse].get(samples[muse].size()-i-1);
          last10.add(sample);
          if(last10.size() > interpolate) last10.remove(0);
            
            cnts = 0;
            if (displaysensor==-1 || displaysensor>3) {
              for (int s=0; s<4; s++) {
                if ((displaysensor != 4 || (s==0 || s==3)) && (displaysensor != 5 || (s==1 || s==2))) {
                  if(!Float.isNaN(sample.relative[s][b])) {
                    avg_rel += sample.relative[s][b];
                    cnts++;
                  }
                }
              }
            } else {
              if(!Float.isNaN(sample.relative[displaysensor][b])) {
                  avg_rel += sample.relative[displaysensor][b];
                  cnts++;
                }
            }
            for (int c=1; c<interpolate; c++) {
              if(last10.size()-1-c > 0) {
                Sample f = (Sample) last10.get(last10.size()-1-c);
                if (displaysensor==-1 || displaysensor>3) {
                  for (int s=0; s<4; s++) {
                    if ((displaysensor != 4 || (s==0 || s==3)) && (displaysensor != 5 || (s==1 || s==2))) {
                      if(!Float.isNaN(f.relative[s][b])) {
                        avg_rel += f.relative[s][b];
                        cnts++;
                      }
                    }
                  }
                } else {
                  if(!Float.isNaN(f.relative[displaysensor][b])) {
                    avg_rel += f.relative[displaysensor][b];
                    cnts++;
                  }
                }
              }
            }  
            avg_rel/=cnts;
            vertex(w-(i)*scaleX, graphh-avg_rel*scaleY);
            avg_rel = 0;
          
        }
        endShape();
      }
    }

    
  }
  
  
  popMatrix();
  strokeWeight(1.0);
  
}


void drawTimeSeriesTime(int muse, int x, int y, int w, int h) {
  textAlign(RIGHT, TOP);
  pushMatrix();
  translate(x, y);
  int legend = 70;
  int graphw = w - legend;
  float scaleX = graphw / (float) (ram-1);  //
  
  fill(mainColor);
  textFont(smFont);
  
  
  
  if(samples[muse].size() > 1) {
    
    int m = min(ram, samples[muse].size());
    
    int minDist = 100;
    int every = int(100.0 / (graphw / float(ram)));
    
    for(int i=0; i<m; i+=every) {
      Sample sample = (Sample) samples[muse].get(samples[muse].size()-i-1);
      text(sample.time, w-i*scaleX, 0);
    }
    
  }
  popMatrix();
  
}



void drawTimeSeriesStatus(int muse, int x, int y, int w, int h) {
  
  pushMatrix();
  translate(x, y);
  int legend = 70;
  int graphw = w - legend;
  float scaleX = graphw / (float) (ram-1);  //
  
  
  if(samples[muse].size() > 1) {
    
    int m = min(ram, samples[muse].size());
    
    
    // draw status indicator
    fill(statusColor);
//    text("status indicator", legend, 10);
    noFill();
    
    strokeWeight(1.0);
    for(int i=0; i<m; i++) {
      Sample sample = (Sample) samples[muse].get(samples[muse].size()-i-1);
      for(int s=0; s<4; s++) {
        stroke(statusColor);
        if(sample.museStatus[s] != 1) point(w-i*scaleX, 20+s*2);
      }
    }
    

  }
  
  popMatrix();
}








void drawFrame(int w, int h) {
  noFill(); stroke(200);
  rect(0,0,w,h);
}




/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  //theOscMessage.print();
  
  if(block) return;
  
  // which muse    /muse = 1, 2014v, white   /mus2 = 2, 2016v, black
  int muse = 0;
  if (theOscMessage.addrPattern().substring(0,5).equals("/mus2")) {
    muse = 1;
  }
  String addp = theOscMessage.addrPattern().substring(5);
  //println("addp "+addp + " muse "+muse);
  
  if (addp.equals("/elements/horseshoe")) {
      for (int i=0; i<4; i++) museStatus[muse][i] = int(theOscMessage.get(i).floatValue());
      
        //// THERE'S AT LEAST THIS VALUE ONCE PER ROUND
      Sample sample = new Sample();
      for(int i=0; i<4; i++) {
       sample.absolute[i][0] = museEEGabsolute[muse][i][0];
       sample.absolute[i][1] = museEEGabsolute[muse][i][1];
       sample.absolute[i][2] = museEEGabsolute[muse][i][2];
       sample.absolute[i][3] = museEEGabsolute[muse][i][3];
       sample.absolute[i][4] = museEEGabsolute[muse][i][4];
       sample.relative[i][0] = museEEGrelative[muse][i][0];
       sample.relative[i][1] = museEEGrelative[muse][i][1];
       sample.relative[i][2] = museEEGrelative[muse][i][2];
       sample.relative[i][3] = museEEGrelative[muse][i][3];
       sample.relative[i][4] = museEEGrelative[muse][i][4];
       sample.museStatus[i] = museStatus[muse][i];
      }
      sample.time = nf(hour(),2,0) + ":" + nf(minute(),2,0);
      samples[muse].add(sample);
    
      if(samples[muse].size() > maxmemory) {
       samples[muse].remove(0);
      }
      
      
  } else if (addp.equals("/elements/delta_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[muse][i][0] = theOscMessage.get(i).floatValue();
    }
  } else if (addp.equals("/elements/theta_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[muse][i][1] = theOscMessage.get(i).floatValue();
    }

  } else if (addp.equals("/elements/alpha_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[muse][i][2] = theOscMessage.get(i).floatValue();
    }
  } else if (addp.equals("/elements/beta_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[muse][i][3] = theOscMessage.get(i).floatValue();
    }
  } else if (addp.equals("/elements/gamma_absolute")) {
    for(int i=0; i<4; i++) {
      museEEGabsolute[muse][i][4] = theOscMessage.get(i).floatValue();
    }
  } else if (addp.equals("/elements/delta_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[muse][i][0] = theOscMessage.get(i).floatValue();
    }
  } else if (addp.equals("/elements/theta_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[muse][i][1] = theOscMessage.get(i).floatValue();
    }

  } else if (addp.equals("/elements/alpha_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[muse][i][2] = theOscMessage.get(i).floatValue();
    }
  } else if (addp.equals("/elements/beta_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[muse][i][3] = theOscMessage.get(i).floatValue();
    }
  } else if (addp.equals("/elements/gamma_relative")) {
    for(int i=0; i<4; i++) {
      museEEGrelative[muse][i][4] = theOscMessage.get(i).floatValue();
    }
  }
  
  
  
}


void clearValues() {
  
  // muse
  museStatus = new int[2][4];
  for (int i=0; i<4; i++) {
    for (int j=0; j<2; j++) {
      museStatus[j][i] = 4;
    }
  }
  museEEGabsolute = new float[2][4][5];
  museEEGrelative = new float[2][4][5];
  for (int i=0; i<4; i++) {
    for (int j=0; j<5; j++) {
      for (int m=0; m<2; m++) {
        museEEGabsolute[m][i][j] = 0;
        museEEGrelative[m][i][j] = 0;
      }
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
      saveFrame("screenshots/muse_duel_"+daytime+".png");
      break;
    case('d'):
      display++;
      if(display >3) display = 1;
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