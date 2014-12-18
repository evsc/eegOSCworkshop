
/* send serial-data to connected Arduino
 * to set RGB values of LED with
 * thinkgear meditation+attention value
 */ 


import processing.serial.*;
import oscP5.*;
import netP5.*;

Serial myPort;    

OscP5 oscP5;
NetAddress myBroadcastLocation; 

String broadcastIP = "10.0.0.16";
int broadcastPort = 5001;
int listeningPort = 12000;

PFont myFont;

int attention = -1;
int meditation = -1;
int average = 128;

void setup() {
  size(256, 312);
  
  myFont = createFont("", 26);
  textFont(myFont);
  
  println(Serial.list());
  
  String portName = Serial.list()[32];
  myPort = new Serial(this, portName, 9600);
  
  
  /* create a new instance of oscP5. 
   * 12000 is the port number you are listening for incoming osc messages.
   */
  oscP5 = new OscP5(this,listeningPort);

  /* the address of the osc broadcast server */
  myBroadcastLocation = new NetAddress(broadcastIP, broadcastPort);
  
  
  prepareExitHandler();
  connectOscClient();
  
  // set LED lamp to average value
  myPort.write(average + "," + (255-average) + ",0\n");
}




void draw() {
  background(0);
  noStroke();
  
  fill(255);
  text("attention: ", 10, 50);
  text(attention, 200, 50);
  text("meditation: ", 10, 100);
  text(meditation, 200, 100);
  text("average: ", 10, 150);
  text(average, 200, 150);
  
  
  fill(average, 255-average, 0);
  rect(10,200, width-20, 100);
 
 
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  // theOscMessage.print();
  
  if (theOscMessage.addrPattern().equals("/thinkgear/attention")) {
    attention = theOscMessage.get(0).intValue();
    average = int(attention+meditation)/2;
    myPort.write(average + "," + (255-average) + ",0\n");
  } else if (theOscMessage.addrPattern().equals("/thinkgear/meditation")) {
    meditation = theOscMessage.get(0).intValue();
    average = int(attention+meditation)/2;
    myPort.write(average + "," + (255-average) + ",0\n");
  }
  
  
}


void keyPressed() {
  switch(key) {
    case('c'):
      connectOscClient();
      break;
    case('d'):
      disconnectOscClient();
      break;
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

