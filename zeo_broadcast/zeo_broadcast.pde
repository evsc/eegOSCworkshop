//
// zeo_broadcast
// read values from zeo bedside display
// and pass on via OSC to all clients that connect
// display current frequency values, and connected client ips


import processing.serial.*;
import src.zeo.library.*;

import oscP5.*;
import netP5.*;

ZeoStream zeo;    // stream object
ZeoSlice slice;   // the current data

OscP5 oscP5;
NetAddressList myNetAddressList = new NetAddressList();
/* listeningPort is the port the server is 
listening for incoming messages */
int myListeningPort = 32000;
/* the broadcast port is the port the clients 
should listen for incoming messages from the server*/
int myBroadcastPort = 12000;

String myConnectPattern = "/zeo/connect";
String myDisconnectPattern = "/zeo/disconnect";


PFont myFont;


void setup() {
  size(200,450);
  oscP5 = new OscP5(this, myListeningPort);
  
  myFont = createFont("", 16);
  textFont(myFont);
  textLeading(25);
  
  // print serial ports
  println(Serial.list());
  // select serial port for ZEO
  zeo = new ZeoStream(this, Serial.list()[1] );
  zeo.debug = false;
  // start to read data from serial port
  zeo.start();
}


void draw() {
  background(50);
  fill(255,0,0);
  text("ZEO", 10,30);
  
  fill(255);
  
  for(int i=0; i<7; i++) {
    text(zeo.nameFrequencyBin(i), 10, 50+i*20, 70, 40);
    text(nf(zeo.slice.frequencyBin[i],0,3), 100, 50+i*20, 70, 40);
  }
  
  fill(255,0,0);
  text("OSC CLIENTS", 10, 230);
  fill(255);
  for(int i=0; i<myNetAddressList.size(); i++ ) {
    text(myNetAddressList.get(i).address(), 10, 250+i*20, 70, 40);
  }
}

/*****************************************
         ZEO EVENTS
 *****************************************/

public void zeoSliceEvent(ZeoStream z) {
  slice = z.slice;

  OscMessage myOscMessage = new OscMessage("/slice");
  for(int i=0; i<7; i++) {
    myOscMessage.add(slice.frequencyBin[i]);
  }
  oscP5.send(myOscMessage, myNetAddressList);
}

public void zeoSleepStateEvent(ZeoStream z) {
//  println("zeoSleepStateEvent "+z.sleepState);  
  OscMessage myOscMessage = new OscMessage("/state");
  myOscMessage.add(z.sleepState);
  oscP5.send(myOscMessage, myNetAddressList);
}




/*****************************************
         OSC EVENTS
 *****************************************/
 
 
 
void oscEvent(OscMessage theOscMessage) {
  println("broadcaster: oscEvent");
  /* check if the address pattern fits any of our patterns */
  if (theOscMessage.addrPattern().equals(myConnectPattern)) {
    connect(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals(myDisconnectPattern)) {
    disconnect(theOscMessage.netAddress().address());
  }
}


private void connect(String theIPaddress) {
  if (!myNetAddressList.contains(theIPaddress, myBroadcastPort)) {
     myNetAddressList.add(new NetAddress(theIPaddress, myBroadcastPort));
     println("### adding "+theIPaddress+" to the list.");
  } else {
     println("### "+theIPaddress+" is already connected.");
  }
  println("### currently there are "+myNetAddressList.list().size()+" remote locations connected.");
}



private void disconnect(String theIPaddress) {
  if (myNetAddressList.contains(theIPaddress, myBroadcastPort)) {
    myNetAddressList.remove(theIPaddress, myBroadcastPort);
    println("### removing "+theIPaddress+" from the list.");
  } else {
    println("### "+theIPaddress+" is not connected.");
  }
  println("### currently there are "+myNetAddressList.list().size());
}
