
/* send serial-data to connected Arduino
 * to set RGB values of LED
 */ 

import processing.serial.*;

Serial myPort;    

void setup() {
  size(256, 256);
  
  println(Serial.list());
  
  String portName = Serial.list()[32];
  myPort = new Serial(this, portName, 9600);
}


void draw() {
  background(0);
  noStroke();
  
  for (int i=0; i<width; i++) {
    fill(i, 255-i,0);
    rect(i,0,1,height);
  }
 
}

void mouseReleased() {
  int v = constrain(mouseX,0,255);
  myPort.write(v + "," + (255-v) + ",0\n");
}
