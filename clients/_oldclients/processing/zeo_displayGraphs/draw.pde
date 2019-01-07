void drawBins(int x, int y, int w, int h) {
  
  pushMatrix();
  translate(x, y);
  drawFrame(w,h);
  
  int toplegend = 30;
  int legend = 60;
  int graphh = h - legend - toplegend;
  int graphw = w;
  
  float scaleX = graphw / 7.0f;  // 7 frequency bins
  float scaleY = graphh / 15.0;  // scale height of frequency bins
  
  // draw legend
  fill(0); noStroke();
  textFont(myFont);
  textAlign(CENTER, TOP);
  textLeading(25);
  for(int i=0; i<7; i++) text(binName[i], (i+0.0)*scaleX, toplegend+graphh, scaleX, 30);
  for(int i=0; i<7; i++) text(binHertz[i]+" Hz", (i+0.0)*scaleX, toplegend+graphh+25, scaleX, 30);
  
  // draw bins
  textFont(myFontBig);
  textAlign(CENTER, TOP);
  if(slices.size() > 0) {
    Slice zs = (Slice) slices.get(slices.size()-1);
    for(int i=0; i<7; i++) {
      fill(binColor[i]);
      rect(i*scaleX, toplegend+graphh, scaleX, (float) zs.frequencyBin[i]*scaleY*-1);
      fill(0);
      if (i==6) text(nf(zs.frequencyBin[i],0,3), 10+i*scaleX, 0, scaleX, 70);
      else text(nf(zs.frequencyBin[i],0,2), i*scaleX, 0, scaleX, 70);
    }
  }
  
  popMatrix();
}

void drawFrame(int w, int h) {
  noFill(); stroke(200);
  rect(0,0,w,h);
}




void drawBinGraph(int x, int y, int w, int h) {

  pushMatrix();
  translate(x, y);
  drawFrame(w,h);
  
  int legend = 70;
  int graphh = h;
  int graphw = w-legend;
  
  
  
  int mem = maxmemory;  // how many slices to display
  
  float scaleX = graphw / (float) (mem-1);  // 
  float scaleY = graphh / 15.0f;  // 
  
  textFont(myFont);
  textAlign(RIGHT, CENTER);
  for(int i=2; i<15; i+=2) {
//    fill(binColor[i]);
//    text(zeo.nameFrequencyBin(i), 10, (i)*scaleY, 70, 40 );
    stroke(0); noFill();
    line(legend, graphh-i*scaleY, legend-5, graphh-i*scaleY);
    fill(0); noStroke();
    text( i, legend-20, graphh-i*scaleY );
    
  }

  strokeWeight(2.0);
  noFill();
  if(slices.size() > 1) {
    
    int m = min(mem, slices.size());
    
    for(int b=0; b<7; b++) {
      stroke(binColor[b]); 
      beginShape();
      for(int i=0; i<m; i++) {
        Slice zs = (Slice) slices.get(slices.size()-i-1);
        float v;
        try {
          v = (float) zs.frequencyBin[b];
          if(b==6) v*= 10;
        } catch (Exception c) {
          v = 0;
        }
        vertex(w-i*scaleX, graphh-v*scaleY);
      }
      endShape();
    }
  }
  
  
  popMatrix();
  strokeWeight(1.0);
}






void drawStage(int x, int y, int w, int h) {

  pushMatrix();
  translate(x, y);
  
  
  int legend = 70;
  int graphh = h;
  int graphw = w-legend;

  int mem = maxmemory;  // how many slices to display
  
  float scaleX = graphw / (float) mem;  // 
  float scaleY = graphh / 5.0f;  // 
  
  textFont(myFont);
  textAlign(RIGHT, CENTER);
  for(int i=1; i<5; i++) {
    stroke(0); noFill();
    line(legend, i*scaleY, legend-5, i*scaleY);
    fill(0); noStroke();
    text(stageName[i], legend-10, i*scaleY );
  }
  
  noStroke();
  if(slices.size() > 0) {
    
    int m = min(mem, slices.size());
    textAlign(LEFT);
    for(int i=0; i<m; i++) {
      Slice zs = (Slice) slices.get(slices.size()-i-1);
      int stage = zs.sleepState;
      fill(stageColor[stage]);
      rect(w-i*scaleX, graphh, -scaleX, -(5-stage)*scaleY);
    }
  }
  drawFrame(w,h);
  popMatrix();
  
}
