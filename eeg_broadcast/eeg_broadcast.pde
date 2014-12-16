/*
 * receive MUSE data via OSC (muse-io driver)
 * receive ThinkGear data via OSC (OF thinkgear_broadcast)
 * receive Zeo data via OSC (P5 zeo_broadcast)
 * and broadcast via OSC
 *
 * start muse driver MUSEIO
 * muse-io --preset 14 --50hz --dsp --osc osc.udp://localhost:5001,osc.udp://localhost:5002
 */
 
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddressList myNetAddressList = new NetAddressList();
int myListeningPort = 5001;
int myBroadcastPort = 12000;

String myConnectPattern = "/eeg/connect";
String myDisconnectPattern = "/eeg/disconnect";

PFont myFont;

// muse values
int eeg_output_frequency_hz = 0;
int notch_frequency_hz = 0;
int battery_percent_remaining = 0;
int status_indicator[];
int dropped_samples = 0;
// thinkgear
int tgAttention = 0;
int tgMeditation = 0;
int tgPoorSignal = 0;


void setup() {
  size(900,450);
  oscP5 = new OscP5(this, myListeningPort);
  
  myFont = createFont("", 16);
  textFont(myFont);
  textLeading(25);
  
  status_indicator = new int[4];
  for (int i=0; i<4; i++) status_indicator[i] = 0;
  
}

void draw() {
  background(50);
  fill(255,0,0);
  text("MUSE", 10,30);
  text("ThinkGear", 300,30);
  text("Zeo", 600,30);
  
  fill(255);
  // MUSE
  text("eeg_output_frequency_hz \t" + eeg_output_frequency_hz, 10, 60);
  text("battery_percent_remaining \t" + battery_percent_remaining, 10,80);
  text("notch_frequency_hz \t\t" + notch_frequency_hz, 10,100);
  text("eeg: dropped_samples \t\t" + dropped_samples, 10,120);
  text("status_indicator " + status_indicator[0] + " " + status_indicator[1] + " " + status_indicator[2] + " " + status_indicator[3], 10, 140);

  text("poorSignal \t" + tgPoorSignal, 300, 60);
  text("attention \t" + tgAttention, 300, 80);
  text("meditation \t" + tgMeditation, 300, 100);
  

  fill(255,0,0);
  text("OSC CLIENTS", 10, 230);
  fill(255);
  for(int i=0; i<myNetAddressList.size(); i++ ) {
    text(myNetAddressList.get(i).address(), 10, 250+i*20, 70, 40);
  }
}



 
void oscEvent(OscMessage theOscMessage) {
  // println("broadcaster: oscEvent");
  /* check if the address pattern fits any of our patterns */
  if (theOscMessage.addrPattern().equals(myConnectPattern)) {
    connect(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals(myDisconnectPattern)) {
    disconnect(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals("/muse/config")) {
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
  else if (theOscMessage.addrPattern().equals("/muse/dsp/blink")) {
    println(theOscMessage.addrPattern());
    println(theOscMessage.get(0).intValue());
  }
  else if (theOscMessage.addrPattern().equals("/muse/dsp/status_indicator")) {
    for (int i=0; i<4; i++) status_indicator[i] = int(theOscMessage.get(i).floatValue());
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
  else if (theOscMessage.addrPattern().equals("/muse/dsp/status_indicator")) {
    oscP5.send(theOscMessage, myNetAddressList);
  }
  else if (theOscMessage.addrPattern().equals("/muse/dsp/blink")) {
    oscP5.send(theOscMessage, myNetAddressList);
  }
  else if (theOscMessage.addrPattern().equals("/muse/dsp/jaw_clench")) {
    oscP5.send(theOscMessage, myNetAddressList);
  }
  else {
    String startPattern = theOscMessage.addrPattern().substring(0,10);
    if(startPattern.equals("/thinkgear")) {
      
      if (theOscMessage.addrPattern().equals("/thinkgear/poorsignal")) {
        tgPoorSignal = theOscMessage.get(0).intValue();
      } 
      else if (theOscMessage.addrPattern().equals("/thinkgear/attention")) {
        tgAttention = theOscMessage.get(0).intValue();
      }
      else if (theOscMessage.addrPattern().equals("/thinkgear/meditation")) {
        tgMeditation = theOscMessage.get(0).intValue();
      }
      
      // then let's pass on all messages  
      oscP5.send(theOscMessage, myNetAddressList);
    }
    // println(theOscMessage.addrPattern());
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
