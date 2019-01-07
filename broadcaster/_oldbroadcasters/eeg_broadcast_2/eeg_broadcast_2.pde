/*
 * receive MUSE data via OSC (muse-io driver)
 * receive MUSE2016 via muse monitor (phone app)
 * and broadcast via OSC
 *
 * start muse driver MUSEIO
 * ./muse-io --device 00:06:66:6C:11:66 --preset 14 --50hz --dsp --osc osc.udp://localhost:5001,osc.udp://localhost:5002
 */
 
import processing.serial.*;
//import src.zeo.library.*;
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddressList myNetAddressList = new NetAddressList();
int myListeningPort = 5001;
int myBroadcastPort = 12000;


boolean doMuse = true;
boolean ready = false;

String myConnectPattern = "/eeg/connect";
String myDisconnectPattern = "/eeg/disconnect";

PFont myFont;

// muse values
int muse1_eeg_output_frequency_hz = 0;
int muse1_notch_frequency_hz = 0;
int muse1_battery_percent_remaining = 0;
int muse1_touching_forehead;
int muse1_status_indicator[];
int muse1_dropped_samples = 0;
float muse1_EEG[][];
float muse1_EEG_rel[][];
String[] museEEGband = { "Delta (1-4)", "Theta (5-8)", "Alpha (9-13)", "Beta (13-30)", "Gamma (30-50)"};
float muse1_concentration = 0;
float muse1_mellow = 0;

int muse2_eeg_output_frequency_hz = 0;
int muse2_notch_frequency_hz = 0;
int muse2_battery_percent_remaining = 0;
int muse2_touching_forehead;
int muse2_status_indicator[];
int muse2_dropped_samples = 0;
float muse2_EEG[][];
float muse2_EEG_rel[][];
float muse2_concentration = 0;
float muse2_mellow = 0;

int count_oscEvents = 0;
int count_seconds = 0;
int oscbySecond = 0;
long start_millis = 0;

boolean blockMostOSC = false;

void setup() {
  size(1000,550);
  oscP5 = new OscP5(this, myListeningPort);
  
  myFont = createFont("", 16);
  textFont(myFont);
  textLeading(25);
  
  muse1_status_indicator = new int[4];
  muse2_status_indicator = new int[4];
  for (int i=0; i<4; i++) {
    muse1_status_indicator[i] = 0;
    muse2_status_indicator[i] = 0;
  }

  muse1_EEG = new float[4][5];
  muse1_EEG_rel = new float[4][5];
  muse2_EEG = new float[4][5];
  muse2_EEG_rel = new float[4][5];
  for (int i=0; i<5; i++) {
    for (int j=0; j<4; j++) {
      muse1_EEG[j][i] = 0;
      muse1_EEG_rel[j][i] = 0;
      muse2_EEG[j][i] = 0;
      muse2_EEG_rel[j][i] = 0;
    }
  }

  start_millis = millis();
  ready = true;
  
}

void draw() {
  background(50);
  fill(255,0,0);
  text("MUSE", 10,30);
  
 
  
  
  // MUSE
  int posx3 = 10;
  int posx1 = 310;
  int posx2 = 540;
  int posx4 = 770;
  
  text("MUSE 1", posx2,30);
  text("MUSE 2", posx4,30);
  text(nfs(frameRate,0,2)+" FPS", posx3, height-40);
  
  count_seconds = int(millis() - start_millis)/1000; 
  
  if(count_seconds>0) oscbySecond = int(count_oscEvents/count_seconds);
  text(oscbySecond + " OSC events / second", posx3, height-20);
  if(blockMostOSC) text("blockMostOSC", 300, height-20);
  
  fill(255);
  
  int y = 40;
  
  if (doMuse) {
    fill(200);
    text("/muse/config", posx3, y+=20);
    text("/muse/config", posx3, y+=20);
    text("/muse/config", posx3, y+=20);
    text("/muse/eeg/dropped_samples", posx3, y+=20);
    text("/muse/elements/horseshoe", posx3, y+=20);
    text("/muse/elements/touching_forehead", posx3, y+=20);
    
    text("/muse/elements/delta_relative", posx3, y+=20);
    text("/muse/elements/theta_relative", posx3, y+=20);
    text("/muse/elements/alpha_relative", posx3, y+=20);
    text("/muse/elements/beta_relative", posx3, y+=20);
    text("/muse/elements/gamma_relative", posx3, y+=20);
    
    fill(100);
    text("/muse/elements/experimental/concentration", posx3, y+=20);
    text("/muse/elements/experimental/mellow", posx3, y+=20);
    
    fill(255);
    
    y = 40;
    text("eeg_output_frequency_hz", posx1, y+=20);
    text(muse1_eeg_output_frequency_hz, posx2, y);
    text(muse2_eeg_output_frequency_hz, posx4, y);
    
    text("battery_percent_remaining", posx1,y+=20);
    text(muse1_battery_percent_remaining, posx2,y);
    text(muse2_battery_percent_remaining, posx4,y);
    
    text("notch_frequency_hz ", posx1,y+=20);
    text(muse1_notch_frequency_hz, posx2,y);
    text(muse2_notch_frequency_hz, posx4,y);
    
    text("eeg: dropped_samples", posx1,y+=20);
    text(muse1_dropped_samples, posx2,y);
    text(muse2_dropped_samples, posx4,y);
    
    text("status_indicator ", posx1, y+=20);
    text(muse1_status_indicator[0] + " " + muse1_status_indicator[1] + " " + muse1_status_indicator[2] + " " + muse1_status_indicator[3], posx2, y);
    text(muse2_status_indicator[0] + " " + muse2_status_indicator[1] + " " + muse2_status_indicator[2] + " " + muse2_status_indicator[3], posx4, y);


    text("touching_forehead ", posx1, y+=20);
    text(muse1_touching_forehead, posx2, y);
    text(muse2_touching_forehead, posx4, y);
    
    for(int i=0; i<5; i++) {
      text(museEEGband[i], posx1, y+=20);
      for (int j=0; j<4; j++) {
        text(muse1_EEG_rel[j][i], posx2-5+j*55, y);
        text(muse2_EEG_rel[j][i], posx4-5+j*55, y);
      }
    }
    
    fill(150);
    //text("CONCENTRATION ", posx1, y+=100);
    text(muse1_concentration, posx2-5, y+=20);
    text(muse2_concentration, posx4-5, y);
    //text("MELLOW ", posx1, y+=20);
    text(muse1_mellow, posx2-5, y+=20);
    text(muse2_mellow, posx4-5, y);
  }
  



  fill(255,0,0);
  text("OSC CLIENTS", 10, 330);
  fill(255);
  for(int i=0; i<myNetAddressList.size(); i++ ) {
    //String[] ipnum = split(myNetAddressList.get(i).address(), '.');
    //println(ipnum.length);
    //text(ipnum[0]+"."+ipnum[1]+"."+ipnum[2]+"."+ipnum[3], 10, 350+i*20, 70, 40);
    text(myNetAddressList.get(i).address(), 10, 350+i*20, 70, 40);
  }
}


 
void oscEvent(OscMessage theOscMessage) {
  
     //println(theOscMessage.addrPattern());
//  println("broadcaster: oscEvent");
  if (ready) {
    
    count_oscEvents++;

  /* check if the address pattern fits any of our patterns */
  if (theOscMessage.addrPattern().equals(myConnectPattern)) {
    connect(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals(myDisconnectPattern)) {
    disconnect(theOscMessage.netAddress().address());
  }
  
  
  // MUSE 2: data coming from Muse Monitor phone app 
 if(doMuse && theOscMessage.addrPattern().length()>4 && theOscMessage.addrPattern().substring(0,6).equals("/muse2")) {
  
    //println(theOscMessage.addrPattern());

    if (theOscMessage.addrPattern().equals("/muse2/muse/elements/horseshoe")) {
      for (int i=0; i<4; i++) muse2_status_indicator[i] = int(theOscMessage.get(i).floatValue());
    }
    // touching_forehead
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/touching_forehead")) {
      muse2_touching_forehead = theOscMessage.get(0).intValue();
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/delta_absolute")) {
      for(int i=0; i<4; i++) {
        muse2_EEG[i][0] = theOscMessage.get(i).floatValue();
      }
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/theta_absolute")) {
      for(int i=0; i<4; i++) {
        muse2_EEG[i][1] = theOscMessage.get(i).floatValue();
      }
      
      // CALC RELATIVE VALUES HERE BECAUSE THETA GETS SEND OUT LAST 
      for(int i=0; i<4; i++) {
        float div = pow(10,muse2_EEG[i][0]) + pow(10,muse2_EEG[i][1]) + pow(10,muse2_EEG[i][2]) + pow(10,muse2_EEG[i][3]) + pow(10,muse2_EEG[i][4]);
        for (int j=0; j<5; j++) {
          muse2_EEG_rel[i][j] = pow(10,muse2_EEG[i][j]) / div;
        }
      }
      
      // send out relative values 
      OscMessage m0 = new OscMessage("/mus2/elements/delta_relative");
      for(int i=0; i<4; i++) {
        m0.add(muse2_EEG_rel[i][0]);
      }
      oscP5.send(m0, myNetAddressList);
      OscMessage m1 = new OscMessage("/mus2/elements/theta_relative");
      for(int i=0; i<4; i++) {
        m1.add(muse2_EEG_rel[i][1]);
      }
      oscP5.send(m1, myNetAddressList);
      OscMessage m2 = new OscMessage("/mus2/elements/alpha_relative");
      for(int i=0; i<4; i++) {
        m2.add(muse2_EEG_rel[i][2]);
      }
      oscP5.send(m2, myNetAddressList);
      OscMessage m3 = new OscMessage("/mus2/elements/beta_relative");
      for(int i=0; i<4; i++) {
        m3.add(muse2_EEG_rel[i][3]);
      }
      oscP5.send(m3, myNetAddressList);
      OscMessage m4 = new OscMessage("/mus2/elements/gamma_relative");
      for(int i=0; i<4; i++) {
        m4.add(muse2_EEG_rel[i][4]);
      }
      oscP5.send(m4, myNetAddressList);
      
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/alpha_absolute")) {
      for(int i=0; i<4; i++) {
        muse2_EEG[i][2] = theOscMessage.get(i).floatValue();
      }
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/beta_absolute")) {
      for(int i=0; i<4; i++) {
        muse2_EEG[i][3] = theOscMessage.get(i).floatValue();
      }
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/gamma_absolute")) {
      for(int i=0; i<4; i++) {
        muse2_EEG[i][4] = theOscMessage.get(i).floatValue();
      }
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/delta_relative")) {
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/theta_relative")) {
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/alpha_relative")) {
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/beta_relative")) {
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/gamma_relative")) {
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/blink")) {
      int blinkVal = theOscMessage.get(0).intValue();
      //if (blinkVal == 1) println("muse2 blink "+blinkVal);
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/jaw_clench")) {
      int jawVal = theOscMessage.get(0).intValue();
      //if (jawVal == 1) println("muse2 jaw clench");
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/raw_fft0")) {
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/raw_fft1")) {
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/raw_fft2")) {
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/raw_fft3")) {
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/experimental/concentration")) {
      muse2_concentration = (theOscMessage.get(0).floatValue());
    }
    else if (theOscMessage.addrPattern().equals("/muse2/muse/elements/experimental/mellow")) {
      muse2_mellow = (theOscMessage.get(0).floatValue());
    }
    
    theOscMessage.setAddrPattern("/mus2" + theOscMessage.addrPattern().substring(11));
    //println("new addr pattern "+theOscMessage.addrPattern());
    oscP5.send(theOscMessage, myNetAddressList);
    
    
  } else if(doMuse && theOscMessage.addrPattern().length()>4 && theOscMessage.addrPattern().substring(0,5).equals("/muse")) {
  
     //println(theOscMessage.addrPattern());
    
    if (theOscMessage.addrPattern().equals("/muse/config")) {
      String config_json = theOscMessage.get(0).stringValue();
      JSONObject jo = JSONObject.parse(config_json);
      // println("config: " + jo.getString("mac_addr"));
      muse1_eeg_output_frequency_hz = jo.getInt("eeg_output_frequency_hz");
      muse1_notch_frequency_hz = jo.getInt("notch_frequency_hz");
      muse1_battery_percent_remaining = jo.getInt("battery_percent_remaining");
      // println(theOscMessage.addrPattern() + ": " + config_json);
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/annotation")) {
      println(theOscMessage.addrPattern());
      for (int i=0; i<5; i++) println(theOscMessage.get(i).stringValue());
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/horseshoe")) {
      for (int i=0; i<4; i++) muse1_status_indicator[i] = int(theOscMessage.get(i).floatValue());
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);

    }
    // touching_forehead
    else if (theOscMessage.addrPattern().equals("/muse/elements/touching_forehead")) {
      muse1_touching_forehead = theOscMessage.get(0).intValue();
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/eeg/dropped_samples")) {
      muse1_dropped_samples = theOscMessage.get(0).intValue();
    }
    else if (theOscMessage.addrPattern().equals("/muse/eeg")) {
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }  
    else if (theOscMessage.addrPattern().equals("/muse/eeg/quantization")) {
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/acc")) {
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/delta_absolute")) {
      for(int i=0; i<4; i++) {
        muse1_EEG[i][0] = theOscMessage.get(i).floatValue();
      }
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/theta_absolute")) {
      for(int i=0; i<4; i++) {
        muse1_EEG[i][1] = theOscMessage.get(i).floatValue();
      }
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
      
      //// CALC RELATIVE VALUES HERE BECAUSE THETA GETS SEND OUT LAST 
      //for(int i=0; i<4; i++) {
      //  float div = pow(10,muse1_EEG[i][0]) + pow(10,muse1_EEG[i][1]) + pow(10,muse1_EEG[i][2]) + pow(10,muse1_EEG[i][3]) + pow(10,muse1_EEG[i][4]);
      //  for (int j=0; j<5; j++) {
      //    float ne_r = pow(10,muse1_EEG[i][j]) / div;
      //    //if(i==2 && j == 1) {
      //    // println("calc rel "+ne_r+ "   reported rel "+muse1_EEG_rel[i][j] );
      //    //}
      //  }
      //}
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/alpha_absolute")) {
      for(int i=0; i<4; i++) {
        muse1_EEG[i][2] = theOscMessage.get(i).floatValue();
      }
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/beta_absolute")) {
      for(int i=0; i<4; i++) {
        muse1_EEG[i][3] = theOscMessage.get(i).floatValue();
      }
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/gamma_absolute")) {
      for(int i=0; i<4; i++) {
        muse1_EEG[i][4] = theOscMessage.get(i).floatValue();
      }
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/delta_relative")) {
      for(int i=0; i<4; i++) {
        muse1_EEG_rel[i][0] = theOscMessage.get(i).floatValue();
      }
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/theta_relative")) {
      for(int i=0; i<4; i++) {
        muse1_EEG_rel[i][1] = theOscMessage.get(i).floatValue();
      }
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/alpha_relative")) {
      for(int i=0; i<4; i++) {
        muse1_EEG_rel[i][2] = theOscMessage.get(i).floatValue();
      }
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/beta_relative")) {
      for(int i=0; i<4; i++) {
        muse1_EEG_rel[i][3] = theOscMessage.get(i).floatValue();
      }
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/gamma_relative")) {
      for(int i=0; i<4; i++) {
        muse1_EEG_rel[i][4] = theOscMessage.get(i).floatValue();
      }
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/blink")) {
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
      int blinkVal = theOscMessage.get(0).intValue();
      //if (blinkVal == 1) println("muse blink "+blinkVal);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/jaw_clench")) {
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
      int jawVal = theOscMessage.get(0).intValue();
      //if (jawVal == 1) println("jaw clench");
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/raw_fft0")) {
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/raw_fft1")) {
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/raw_fft2")) {
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/raw_fft3")) {
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/experimental/concentration")) {
      muse1_concentration = (theOscMessage.get(0).floatValue());
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
    else if (theOscMessage.addrPattern().equals("/muse/elements/experimental/mellow")) {
      muse1_mellow = (theOscMessage.get(0).floatValue());
      if (!blockMostOSC) oscP5.send(theOscMessage, myNetAddressList);
    }
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

void keyReleased() {
  if (key == 'b') {
    blockMostOSC = !blockMostOSC;
  }
}