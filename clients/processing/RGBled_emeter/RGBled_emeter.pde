
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

String broadcastIP = "192.168.1.3";
int broadcastPort = 5001;
int listeningPort = 12000;

PFont myFont;

int tgPoorSignal;
int attention = -1;
int meditation = -1;
int average = -1;
int LEDval = -1;

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
  
  // turn LED off at the start
  myPort.write(0 + "," + 0 + ",0\n");
}




void draw() {
  background(0);
  noStroke();
  
  fill(255);
  text("signal quality: ", 10, 20);
  text(tgPoorSignal, 200, 20);
  text("attention: ", 10, 80);
  text(attention, 200, 80);
  text("meditation: ", 10, 115);
  text(meditation, 200, 115);
  text("average: ", 10, 150);
  text(average, 200, 150);
  
  if (LEDval < 0) fill(255);
  else fill(LEDval, 255-LEDval, 0);
  rect(10,200, width-20, 100);
 
 
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  // theOscMessage.print();
  
  if (theOscMessage.addrPattern().equals("/thinkgear/attention")) {
    attention = theOscMessage.get(0).intValue();
    average = int((attention+meditation)/2);
    LEDval = int(255 - average*2.55);
    myPort.write(LEDval + "," + (255-LEDval) + ",0\n");
  } else if (theOscMessage.addrPattern().equals("/thinkgear/meditation")) {
    meditation = theOscMessage.get(0).intValue();
    average = int((attention+meditation)/2);
    LEDval = int(255 - average*2.55);
    myPort.write(LEDval + "," + (255-LEDval) + ",0\n");
  } else if (theOscMessage.addrPattern().equals("/thinkgear/poorsignal")) {
    tgPoorSignal = theOscMessage.get(0).intValue();
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

