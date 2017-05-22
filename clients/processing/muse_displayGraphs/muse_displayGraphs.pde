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
ArrayList samples; 

// INTERPOLATION
int[] interpolateSteps = { 1, 10, 50, 100, 200, 400 };
int interpol = 4;
int interpolate = 200;  // in the time graph, how many samples to average across




// muse
int museBattery = 0;
int[] museStatus;
float museEEGabsolute[][];
float museEEGrelative[][];
String[] museEEGwave = { "Delta", "Theta", "Alpha", "Beta", "Gamma"};
String[] museEEGhz = { "1-4", "5-8", "9-13", "13-30", "30-50" };
String[] museSensors = { "Left ear", "Left forehead", "Right forehead", "Right ear", "Avg ear", "Avg forehead" };
int museBlink = 0;
int museJaw = 0;
float muse_concentration = 0;
float muse_mellow = 0;


int display = 5;
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
  bigFont = createFont("", 32);
  textFont(bigFont);
  
  samples = new ArrayList();
  
  prepareExitHandler();
  connectOscClient();
}


void draw() {
  if (!pause) {
    background(bgColor);
    noStroke();
    textAlign(LEFT, TOP);
    
    textFont(bigFont);
    fill(255,0,0);
    
    text("MUSE", 50,50);
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
    
    if(display == 1) {
      
      // REAL TIME BINS FOR ALL CHANNELS
      // AND AVERAGE BINS 
      
      for (int i=0; i<4; i++) {
        drawBin(50+280*i,100, 260, 260, i);
      }
      drawBin(50,400, 350, 350, 4);
      drawBin(425,400, 350, 350, 5);
      drawBin(800,400, 350, 350, -1);
      
    } else if(display == 2) {
      
      // REAL TIME TIME GRAPHS FOR ALL CHANNELS
       
      for (int i=0; i<4; i++) {
        drawTimeSeries(50,100+140*i, 1100,120, i, true, true);
      }
  
      drawExpGraph(50,700, 1100, 100);
      
      drawTimeSeriesStatus(50,640, 1100, 30);
      drawTimeSeriesTime(50,670, 1100, 30);
      
    } else if(display == 3) {
      
      // TIME GRAPHS AVERAGES
      
      drawTimeSeries(50,100, 1100,200, 4, true, true);
      drawTimeSeries(50,320, 1100,200, 5, true, true);
      drawTimeSeries(50,540, 1100,200, -1, true, true);
      
      drawTimeSeriesStatus(50,740, 1100, 30);
      drawTimeSeriesTime(50,770, 1100, 30);
      
    } else if (display == 4) {
      
      // BIG AVERGAE FOREHEAD TIME GRAPH
      // AVG RAM BIN
      
      drawTimeSeries(50,200, 1100,500, 5, true, true);
      
      drawTimeSeriesStatus(50,700, 1100, 30);
      drawTimeSeriesTime(50,730, 1100, 30);
      drawExpGraph(50,750, 1100, 70);
      
      for(int b=0; b<5; b++) {
        fill(binColor[b]);
        text(museEEGwave[b] + " " + museEEGhz[b] + " Hz", 500, 50+20*b);  
      }
      
      drawRamBin(800,50, 350, 130, 5, true);
      
      
      
    } else if (display == 5) {
      
      // FOREHEAD TIMEGRAPH, RELATIVE AND ABSOLUTE
      
      drawTimeSeries(50,220, 1100,270, 5, true, false);  // absolute
      drawTimeSeries(50,520, 1100,200, 5, true, true);  // relative
      drawRamBin(400,50, 350, 130, 5, false);
      drawRamBin(800,50, 350, 130, 5, true);
      
      
      for(int b=0; b<5; b++) {
        fill(binColor[b]);
        //text(museEEGwave[b] + " " + museEEGhz[b] + " Hz", 500, 50+20*b);  
      }
      
      drawTimeSeriesStatus(50,700, 1100, 30);
      drawTimeSeriesTime(50,730, 1100, 30);
      drawExpGraph(50,750, 1100, 70);
      
      
    }
  }
 
}


void drawBin(int x, int y, int w, int h, int displaysensor) {
  
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
  if(displaysensor==-1) text("Average Bins", w/2,0);
  else text(museSensors[displaysensor], w/2,0);

  for(int i=0; i<5; i++) {
    float avg_abs = 0;
    float avg_rel = 0;
    int cnts = 0;
    if(displaysensor==-1 || displaysensor>3) {
      for (int s=0; s<4; s++) {
        if(!Float.isNaN(museEEGrelative[s][i])) {
          if ((displaysensor != 4 || (s==0 || s==3)) && (displaysensor != 5 || (s==1 || s==2))) {
            cnts++;
            avg_abs += museEEGabsolute[s][i]; 
            avg_rel += museEEGrelative[s][i]; 
          }
        }
        
      }
    } else {
      if(!Float.isNaN(museEEGrelative[displaysensor][i])) {
        cnts++;
        avg_abs += museEEGabsolute[displaysensor][i]; 
        avg_rel += museEEGrelative[displaysensor][i]; 
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




void drawRamBin(int x, int y, int w, int h, int displaysensor, boolean useRelative) {
  
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
  
  textFont(bigFont);
  textAlign(CENTER, TOP);
  String title = "";
  if (useRelative) title = "Relative ";
  else title = "Absolute ";
  if(displaysensor==-1) text(title +"Avg Bins", w/2,0);
  else text(title +museSensors[displaysensor], w/2,0);

  
  int m = min(ram, samples.size());
  
  
  for(int i=0; i<5; i++) {
    
    float avg_abs = 0;
    float avg_rel = 0;
    int cnts = 0;
  
    // but let's exclude the last ~5 seconds = ~50 samples
    // buffer time to get to the computer
    if (m > 50) {
      for(h=50; h<m; h++) {
        Sample sample = (Sample) samples.get(samples.size()-h-1);
    
        
        
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
    if (useRelative) {
    //fill(binColor[i],50);
    //rect(i*scaleX, toplegend+graphh, scaleX, (float) avg_abs*scaleY*-1);
      fill(binColor[i]);
      rect(i*scaleX, toplegend+graphh, scaleX, (float) avg_rel*scaleY*-1);
    } else {
      fill(binColor[i]);
      rect(i*scaleX, toplegend+graphh, scaleX, (float) avg_abs*scaleY*-1);
    }
    
    textFont(smFont);
    textAlign(CENTER, TOP);
    fill(mainColor);
    textLeading(25);
    if (useRelative) {
      text(nf(avg_rel,0,2), (i+0.0)*scaleX, toplegend+graphh, scaleX, 30);
    } else {
      text(nf(avg_abs,0,2), (i+0.0)*scaleX, toplegend+graphh, scaleX, 30);
    }
  
  }

  
  popMatrix();

  
}






void drawTimeSeries(int x, int y, int w, int h, int displaysensor, boolean filled, boolean useRelative) {
  
  pushMatrix();
  translate(x, y);
  drawFrame(w,h);
  
  int legend = 70;
  int graphh = h;
  int graphw = w-legend;
  
  float scaleX = graphw / (float) (ram-1);  // 
  float scaleY = graphh / 0.7f;  // 
  if (!useRelative) scaleY *= 0.4;
  
  textFont(bigFont);
  fill(mainColor);
  textAlign(LEFT, TOP);
  String title = "";
  if (useRelative) title+= "Relative ";
  else title+= "Absolute ";
  if(displaysensor==-1) text(title +"All sensors", legend+10,10);
  else text(title +museSensors[displaysensor], legend+10, 10);

  // draw legend
  textFont(smFont);
  textAlign(RIGHT, CENTER);
  float topLegend = 0.7;
  if (!useRelative) topLegend = 1.8;
  float addLegend = 0.1;
  if (!useRelative) addLegend = 0.3;
  for(float i=0.1; i<topLegend; i+=addLegend) {
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
            if (displaysensor==-1 || displaysensor>3) {
              for (int s=0; s<4; s++) {
                if ((displaysensor != 4 || (s==0 || s==3)) && (displaysensor != 5 || (s==1 || s==2))) {
                  if(!Float.isNaN(sample.relative[s][b])) {
                    avg_rel += sample.relative[s][b];
                    avg_abs += sample.absolute[s][b];
                    cnts++;
                  }
                }
              }
            } else {
              if(!Float.isNaN(sample.relative[displaysensor][b])) {
                avg_rel += sample.relative[displaysensor][b];
                avg_abs += sample.absolute[displaysensor][b];
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
                        avg_abs += f.absolute[s][b];
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
            avg_abs/=cnts;
            if (useRelative) {
              vertex(w-(i)*scaleX, graphh-avg_rel*scaleY);
            } else {
              vertex(w-(i)*scaleX, graphh-avg_abs*scaleY);
            }
            avg_rel = 0;
            avg_abs = 0;
          
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
          Sample sample = (Sample) samples.get(samples.size()-i-1);
          last10.add(sample);
          if(last10.size() > interpolate) last10.remove(0);
            
            cnts = 0;
            if (displaysensor==-1 || displaysensor>3) {
              for (int s=0; s<4; s++) {
                if ((displaysensor != 4 || (s==0 || s==3)) && (displaysensor != 5 || (s==1 || s==2))) {
                  if(!Float.isNaN(sample.relative[s][b])) {
                    avg_rel += sample.relative[s][b];
                    avg_abs += sample.absolute[s][b];
                    cnts++;
                  }
                }
              }
            } else {
              if(!Float.isNaN(sample.relative[displaysensor][b])) {
                  avg_rel += sample.relative[displaysensor][b];
                  avg_abs += sample.absolute[displaysensor][b];
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
                        avg_abs += f.absolute[s][b];
                        cnts++;
                      }
                    }
                  }
                } else {
                  if(!Float.isNaN(f.relative[displaysensor][b])) {
                    avg_rel += f.relative[displaysensor][b];
                    avg_abs += f.absolute[displaysensor][b];
                    cnts++;
                  }
                }
              }
            }  
            avg_rel/=cnts;
            avg_abs/=cnts;
            if (useRelative) {
              vertex(w-(i)*scaleX, graphh-avg_rel*scaleY);
            } else {
              vertex(w-(i)*scaleX, graphh-avg_abs*scaleY);
            }
            avg_rel = 0;
            avg_abs = 0;
          
        }
        endShape();
      }
    }

    
  }
  
  
  popMatrix();
  strokeWeight(1.0);
  
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
    int every = int(100.0 / (graphw / float(ram)));
    
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
      for(int s=0; s<4; s++) {
        stroke(statusColor);
        if(sample.museStatus[s] != 1) point(w-i*scaleX, 20+s*2);
      }
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
    stroke(mainColor); noFill();
    line(legend, toplegend+graphh-i*scaleY, legend-5, toplegend+graphh-i*scaleY);
    fill(mainColor); noStroke();
    text( nf(i,0,2), legend-20, toplegend+graphh-i*scaleY );
    
  }


  textAlign(LEFT, CENTER);
  noFill();
  if(samples.size() > 1) {
    
    int m = min(ram, samples.size());
    
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
  
  if(block) return;
  
  // muse
  if (theOscMessage.addrPattern().equals("/muse/elements/horseshoe")) {
      for (int i=0; i<4; i++) museStatus[i] = int(theOscMessage.get(i).floatValue());
      
        //// THERE'S AT LEAST THIS VALUE ONCE PER ROUND
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
    case('d'):
      display++;
      if(display >5) display = 1;
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