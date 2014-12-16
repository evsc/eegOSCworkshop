/*
 * receive MUSE data via OSC (muse-io driver)
 * receive ThinkGear data via OSC (OF thinkgear_broadcast)
 * receive Zeo data via OSC (P5 zeo_broadcast)
 * and broadcast via OSC
 *
 * start muse driver MUSEIO
 * muse-io --preset 14 --50hz --dsp --osc osc.udp://localhost:5001,osc.udp://localhost:5002
 */
 
import processing.serial.*;
import src.zeo.library.*;
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddressList myNetAddressList = new NetAddressList();
int myListeningPort = 5001;
int myBroadcastPort = 12000;

boolean doZeo = false;
boolean doMuse = true;
boolean doThinkgear = true;
boolean ready = false;

String myConnectPattern = "/eeg/connect";
String myDisconnectPattern = "/eeg/disconnect";

PFont myFont;

// zeo
ZeoStream zeo;    // stream object
ZeoSlice slice;   // the current data

// muse values
int eeg_output_frequency_hz = 0;
int notch_frequency_hz = 0;
int battery_percent_remaining = 0;
int status_indicator[];
int dropped_samples = 0;
int museEEG[];
String[] museEEGband = { "Delta (1-4)", "Theta (508)", "Alpha (9-13)", "Beta (13-30)", "Gamma (30-50)"};


// thinkgear
int tgAttention = 0;
int tgMeditation = 0;
int tgPoorSignal = 0;
int tgEEG[];
String[] tgEEGband = { "Delta (0.5-2.75)", "Theta (3.5-6.75)", "Low Alpha (7.5-9.25)", "High Alpha (10-11.75)", "Low Beta (13-16.75)", "High Beta (18-29.75)", "Low Gamma (31-39.75)", "Mid Gamma (41-49.75)"};


void setup() {
  size(900,550);
  oscP5 = new OscP5(this, myListeningPort);
  
  myFont = createFont("", 16);
  textFont(myFont);
  textLeading(25);
  
  status_indicator = new int[4];
  for (int i=0; i<4; i++) status_indicator[i] = 0;
  
  tgEEG = new int[8];
  for (int i=0; i<8; i++) tgEEG[i] = 0;
  
  museEEG = new int[5];
  for (int i=0; i<5; i++) museEEG[i] = 0;
  
  
  if (doZeo) {
    // print serial ports
    println(Serial.list());
    // select serial port for ZEO
    zeo = new ZeoStream(this, Serial.list()[1] );
    zeo.debug = false;
    // start to read data from serial port
    zeo.start();
  }
  
  ready = true;
  
}

void draw() {
  background(50);
  fill(255,0,0);
  text("MUSE", 10,30);
  text("ThinkGear", 300,30);
  text("ZEO", 600,30);
  
  fill(255);
  
  // MUSE
  if (doMuse) {
    text("eeg_output_frequency_hz", 10, 60);
    text(eeg_output_frequency_hz, 210, 60);
    text("battery_percent_remaining", 10,80);
    text(battery_percent_remaining, 210,80);
    text("notch_frequency_hz ", 10,100);
    text(notch_frequency_hz, 210,100);
    text("eeg: dropped_samples", 10,120);
    text(dropped_samples, 210,120);
    text("status_indicator ", 10, 140);
    text(status_indicator[0] + " " + status_indicator[1] + " " + status_indicator[2] + " " + status_indicator[3], 210, 140);

    for(int i=0; i<5; i++) {
      text(museEEGband[i], 10, 160+i*20);
      text(museEEG[i], 10+200, 160+i*20);
    }
  }
  
  // thinkgear
  if (doThinkgear) {
    int x1 = 300;
    int x2 = x1+200;
    text("poorSignal", x1, 60);
    text(tgPoorSignal, x2, 60);
    text("attention", x1, 80);
    text(tgAttention, x2, 80);
    text("meditation", x1, 100);
    text(tgMeditation, x2, 100);
    
    for(int i=0; i<8; i++) {
      text(tgEEGband[i], x1, 120+i*20);
      text(tgEEG[i], x2, 120+i*20);
    }
    
  }
  
  // zeo
  if (doZeo) {
    for(int i=0; i<7; i++) {
      text(zeo.nameFrequencyBin(i), 600, 60+i*20);
      text(nf(zeo.slice.frequencyBin[i],0,3), 740, 60+i*20);
    }
    text("sleepState", 600, 60+7*20);
    text(zeo.slice.sleepState, 740, 60+7*20);
  }

  fill(255,0,0);
  text("OSC CLIENTS", 10, 330);
  fill(255);
  for(int i=0; i<myNetAddressList.size(); i++ ) {
    text(myNetAddressList.get(i).address(), 10, 350+i*20, 70, 40);
  }
}


public void zeoSliceEvent(ZeoStream z) {
  slice = z.slice;

  OscMessage myOscMessage = new OscMessage("/slice");
  for(int i=0; i<7; i++) {
    myOscMessage.add(slice.frequencyBin[i]);
  }
  oscP5.send(myOscMessage, myNetAddressList);
}

public void zeoSleepStateEvent(ZeoStream z) {
  // println("zeoSleepStateEvent "+z.sleepState);  
  OscMessage myOscMessage = new OscMessage("/state");
  myOscMessage.add(z.sleepState);
  oscP5.send(myOscMessage, myNetAddressList);
}
 
void oscEvent(OscMessage theOscMessage) {
//  println("broadcaster: oscEvent");
  if (ready) {

  /* check if the address pattern fits any of our patterns */
  if (theOscMessage.addrPattern().equals(myConnectPattern)) {
    connect(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals(myDisconnectPattern)) {
    disconnect(theOscMessage.netAddress().address());
  }

  if(doMuse && theOscMessage.addrPattern().length()>4 && theOscMessage.addrPattern().substring(0,5).equals("/muse")) {
  
    if (theOscMessage.addrPattern().equals("/muse/config")) {
      String config_json = theOscMessage.get(0).stringValue();
      JSONObject jo = JSONObject.parse(config_json);
      // println("config: " + jo.getString("mac_addr"));
      eeg_output_frequency_hz = jo.getInt("eeg_output_frequency_hz");
      notch_frequency_hz = jo.getInt("notch_frequency_hz");
      battery_percent_remaining = jo.getInt("battery_percent_remaining");
      // println(theOscMessage.addrPattern() + ": " + config_json);
    }
    else if (theOscMessage.addrPattern().equals("/muse/annotation")) {
      println(theOscMessage.addrPattern());
      for (int i=0; i<5; i++) println(theOscMessage.get(i).stringValue());
    }
    else if (theOscMessage.addrPattern().equals("/muse/dsp/status_indicator")) {
      for (int i=0; i<4; i++) status_indicator[i] = int(theOscMessage.get(i).floatValue());
      oscP5.send(theOscMessage, myNetAddressList);
      println(theOscMessage.addrPattern() + ": " + status_indicator[0]);
    }
    else if (theOscMessage.addrPattern().equals("/muse/eeg/dropped_samples")) {
      dropped_samples = theOscMessage.get(0).intValue();
    }
    else if (theOscMessage.addrPattern().equals("/muse/eeg")) {
      oscP5.send(theOscMessage, myNetAddressList);
    }  
    else if (theOscMessage.addrPattern().equals("/muse/eeg/quantization")) {
      oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/acc")) {
      oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/dsp/bandpower/delta")) {
      oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/dsp/bandpower/theta")) {
      oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/dsp/bandpower/alpha")) {
      oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/dsp/bandpower/beta")) {
      oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/dsp/bandpower/gamma")) {
      oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/dsp/blink")) {
      oscP5.send(theOscMessage, myNetAddressList);
      int blinkVal = theOscMessage.get(0).intValue();
      println("muse blink "+blinkVal);
    }
    else if (theOscMessage.addrPattern().equals("/muse/dsp/jaw_clench")) {
      oscP5.send(theOscMessage, myNetAddressList);
    }
    
  } else if (doThinkgear && theOscMessage.addrPattern().length() > 9 && theOscMessage.addrPattern().substring(0,10).equals("/thinkgear")) {

    
    if (theOscMessage.addrPattern().equals("/thinkgear/poorsignal")) {
      tgPoorSignal = theOscMessage.get(0).intValue();
    } 
    else if (theOscMessage.addrPattern().equals("/thinkgear/attention")) {
      tgAttention = theOscMessage.get(0).intValue();
    }
    else if (theOscMessage.addrPattern().equals("/thinkgear/meditation")) {
      tgMeditation = theOscMessage.get(0).intValue();
    }
    else if (theOscMessage.addrPattern().equals("/thinkgear/eeg")) {
      for (int i=0; i<8; i++) tgEEG[i] = int(theOscMessage.get(i).floatValue());
    }
    
    // then let's pass on all messages  
    oscP5.send(theOscMessage, myNetAddressList);
    
  } else {
    // println(theOscMessage.addrPattern());
  }
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
