import peasy.org.apache.commons.math.*;
import peasy.*;
import peasy.org.apache.commons.math.geometry.*;



PeasyCam cam;



String[] act = { "audiobook", "audiobook eyes closed", "music eyes closed", "french", "log data", "programming", "read on tablet", "read", "sudoku", "tv", "web" }; 
float[][] coord = {  { 0.42, 0.2, 0.11 }, 
                     { 0.13, 0.19, 0.21},
                     { 0.16, 0.27, 0.135},
                     { 0.24, 0.12, 0.27},
                     { 0.285, 0.32, 0.14},
                     { 0.34, 0.37, 0.08},
                     { 0.27, 0.13, 0.28},
                     { 0.31, 0.127, 0.253},
                     { 0.143, 0.45, 0.123},
                     { 0.22, 0.108, 0.298},
                     { 0.405, 0.22, 0.115} }; 
int cnt;
float multi = 700;


void setup() {
  
  size(900,900, P3D);
  cnt = act.length;
  
  cam = new PeasyCam(this, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(500);
  
}


void draw() {
  rotateX(-.5);
  rotateY(-.5);
  
  
  pushMatrix();
  
  
  background(150);
//  camera(mouseX, mouseY, (height/2) / tan(PI/6), width/2, height/2, 0, 0, 1, 0);
  
  translate(width/2 - multi/2, height/2 - multi/2, -100);
  stroke(255);
  noFill();
  stroke(255,0,0);
  line(0,0,0,multi,0,0);
  stroke(0,255,0);
  line(0,0,0,0,multi,0);
  stroke(0,0,255);
  line(0,0,0,0,0,multi);
  
  
  
  noStroke();
  fill(255);
  for (int i=0; i<cnt; i++) {
    
    text(act[i], coord[i][0] * multi, coord[i][1] * multi, coord[i][2] * multi);
    
  }
  
  
  
  
  
  popMatrix();
}
