/*
 * can receive OSC data from:
 * - any MUSE via OSC from mind-monitor app (https://mind-monitor.com)
 * - MUSE2014 data via OSC from muse-io (Ubuntu, discontinued)
 * - MUSE2016 via OSC from muse direct (Windows, discontinued)
 * and broadcast that data via OSC to multiple clients
 *
 * Mind Monitor how to:
 * settings
   - OSC Stream Traget IP .. set to this computer IP
   - OSC Stream Port .. set to 5001
   - OSC Stream Brainwaves .. set to "average only"
   - OSC Path prefix .. /phone1
 *
 *
 * Muse-IO how to:
 * start muse driver MUSEIO on Ubuntu
 * ./muse-io --device 00:06:66:6C:11:66 --preset 14 --50hz --dsp --osc osc.udp://localhost:5001,osc.udp://localhost:5002
 *
 * Muse Direct how to:
 * 
 *
 *
 */
 
 
 
import oscP5.*;
import netP5.*;

/// /muse .. from ubuntu (has to be in first array position, else there's an OSC warning)
String[] patternMuse = { "/phone1/muse", "/phone2/muse", "/phone3/muse", "/phone4/muse", "/tablet5/muse", "/tablet6/muse" };
String[] patternReplace = { "/Person1", "/Person2", "/Person3", "/Person4", "/Person5", "/Person6" };

String myIP = "192.168.0.100";





///////////////////// OSC ////////////////////////////

OscP5 oscP5;
NetAddressList myNetAddressList = new NetAddressList();
int myListeningPort = 5001;
int myBroadcastPort = 12000;
String myConnectPattern = "/eeg/connect";
String myDisconnectPattern = "/eeg/disconnect";




/////////////////////// eeg ////////////////////

int numMuses = patternMuse.length;
MuseUnit[] muses;

String[] museEEGband = {"Delta (1-4)", 
                        "Theta (5-8)", 
                        "Alpha (9-13)", 
                        "Beta (13-30)", 
                        "Gamma (30-50)"};

String[] museEEGaddress = { "/delta", "/theta", "/alpha", "/beta", "/gamma"};

boolean doMuse = true;    // decode incoming osc messages for MUSE data
boolean ready = false;
boolean enableForwarding = true;
boolean debugPrint = false;
boolean displayAlg = false;    // show mellow and concentration values

boolean incomingData = false;
boolean[] incomingDataMuse;    // set by incoming Data, to display indicator on GUI
boolean broadcastAbsolute = true;


PFont myFont;
long lastTimer;



class MuseUnit {
  
  int id;
  int batt; 
  int touching_forehead;
  int horseshoe[];
  long lastInput;
  float relative[][];
  float relative_avg[];
  float absolute[][];
  float absolute_avg[];
  boolean blink;
  int mellow;
  int concentration;
  
  int signal_cnt;
  int signal_lastsec; 
  
  MuseUnit(int _id) {
    id = _id; batt = -1; touching_forehead = -1;
    horseshoe = new int[4];
    for (int i=0; i<4; i++) horseshoe[i] = 9;
    relative = new float[4][5];
    absolute = new float[4][5];
    for (int i=0; i<5; i++) {
      for (int j=0; j<4; j++) relative[j][i] = 0;
    }
    relative_avg = new float[5];
    absolute_avg = new float[5];
    for (int i=0; i<5; i++) {
      relative_avg[i] = 0;
      absolute_avg[i] = 0;
    }
    blink = false;
    mellow = 0;
    concentration = 0;
    lastInput = -10000000;
    signal_lastsec = 0;
    signal_cnt = 0;
  }
  
  void calcRelative() {
    float sum = 0;
    for (int b=0; b<5; b++) {
      sum += pow(10,absolute_avg[b]);
    }
    // alpha_relative = (10^alpha_absolute / (10^alpha_absolute + 10^beta_absolute + 10^delta_absolute + 10^gamma_absolute + 10^theta_absolute))
    for (int b=0; b<5; b++) {
      relative_avg[b] = pow(10,absolute_avg[b]) / sum;
    }
  }
  
  void avg_relative(int b) {
    if (b >= 0 && b <=4) {
      float total = 0;
      int cnts = 0;
      for (int i=0; i<4; i++) {
        float v = relative[i][b];
        if (!Float.isNaN(v)) {
          total += v;
          cnts++;
        }
      }
      relative_avg[b] = cnts > 0 ? total/cnts : 0;
    }
  }
  
  void avg_absolute(int b) {
    if (b >= 0 && b <=4) {
      float total = 0;
      int cnts = 0;
      for (int i=0; i<4; i++) {
        float v = absolute[i][b];
        if (!Float.isNaN(v)) {
          total += v;
          cnts++;
        }
      }
      absolute_avg[b] = cnts > 0 ? total/cnts : 0;
    }
  }
  
}





void setup() {
  size(1265,550);
  frameRate(10);
  oscP5 = new OscP5(this, myListeningPort);    // , OscP5.TCP
  
  myFont = loadFont("LucidaConsole-26.vlw");
  //myFont = createFont("", 16);
  textFont(myFont);
  textLeading(25);
  
  muses = new MuseUnit[numMuses];
  incomingDataMuse = new boolean[numMuses];
  for (int i=0; i<numMuses; i++) {
    muses[i] = new MuseUnit(i+1);
    incomingDataMuse[i] = false;
  }

  lastTimer = millis();
  ready = true;
  
  /// 
  //OscProperties myProperties = new OscProperties();
  //println("datagramSize: " +myProperties.datagramSize());   // 1536
  //println("networkProtocol: "+myProperties.networkProtocol());   // 0 (UDP), 1 (MULTICAST), 2 (TCP)
  
}






void draw() {
  
  if(millis() - lastTimer > 1000) {
    lastTimer = millis();
    // update signal-count on muses
    for (int i=0; i<numMuses; i++) {
      muses[i].signal_lastsec = muses[i].signal_cnt;
      muses[i].signal_cnt = 0;
    } 
  }
  
  
  int topline = 40;
  int header = 80;
  int firstline = 120;
  
  background(50);
  
  textSize(32);
  fill(255,0,0);
  text("MUSE - EEG BROADCAST", 10,topline);
  text(myIP, width-260,topline);

  textSize(16);
  if(doMuse) text("| input enabled (i)", 450, topline);
  else text("| input disabled (i)", 450, topline);
  
  
  
  
  fill(255);
  
  
  
  int x = 10;
  int y = firstline;
  
  
  // display OSC addresses
  fill(200);
  textSize(16);
  text("/batt", x, y+=20);
  text("/forehead", x, y+=20);
  text("/horseshoe", x, y+=20);
  if(displayAlg) {
    text("/mellow", x, y+=20);
    text("/concentration", x, y+=20);
  }
  y+=20;
  String addon = "  R";
  if(broadcastAbsolute) addon+=" (A)";
  text("/delta"+addon, x, y+=20);
  text("/theta"+addon, x, y+=20);
  text("/alpha"+addon, x, y+=20);
  text("/beta "+addon, x, y+=20);
  text("/gamma"+addon, x, y+=20);
  y+=20;
  text("update rate", x, y+=20);

  for (int i=0; i<numMuses; i++) {
    
    if (muses[i].lastInput > millis()-1000*3) {
      fill(255,255,0);  
    } else {
      fill(255);
    }
    
    x += 180;
    y = header;
    
    textSize(25);
    text(patternReplace[i], x,y);
    y+=20;
    textSize(16);
    text(patternMuse[i], x,y);
    
    y = firstline;
    textSize(16);
    text(muses[i].batt + " %", x, y+=20);
    text(muses[i].touching_forehead, x, y+=20);
    text(muses[i].horseshoe[0]+" "+muses[i].horseshoe[1]+" "+muses[i].horseshoe[2]+" "+muses[i].horseshoe[3], x, y+=20);
    if(displayAlg) {
      text(muses[i].mellow, x, y+=20);
      text(muses[i].concentration, x, y+=20);
    }
   
    y+=20;
    for(int j=0; j<5; j++) {
      //text(nfc(muses[i].relative_avg[j],2) + "    " + nfc(muses[i].absolute_avg[j],2), x, y+=20);
      text(nfc(muses[i].relative_avg[j],3), x, y+=20);
      if(broadcastAbsolute) text("("+nfc(muses[i].absolute_avg[j],3)+")", x+70, y);
    }
    
    y+=20;
    text(muses[i].signal_lastsec+"Hz", x, y+=20);
    if(incomingDataMuse[i]) text("DATA", x, y+=20);

    // i don't think this works
    if (muses[i].blink) {
      y+=20;
      text("BLINK", x, y+=20);
      muses[i].blink = false;
      //println("blink");
    }

  }


  x = 10;
  y+=100;
  
  fill(255,0,0);
  textSize(32);
  text("OSC CLIENTS", x, y);
  textSize(16);
  if(enableForwarding) text("| forwarding enabled (f)", x+250, y);
  else text("| forwarding disabled (f)", x+250, y);
  fill(255);
  y+=20;
  for(int i=0; i<myNetAddressList.size(); i++ ) {
    //text(ipnum[0]+"."+ipnum[1]+"."+ipnum[2]+"."+ipnum[3], 10, 350+i*20, 70, 40);
    text(myNetAddressList.get(i).address(), x+=100, y);
    if(x > width-200) {
      y+=20;
      x = 10;
    }
  }
  
  fill(100);
  textSize(32);
  if(incomingData) {
    text("DATA", width-150, height-60);
    incomingData = false;
    for(int m=0; m<numMuses; m++) incomingDataMuse[m] = false;
  }
  text(int(frameRate)+ " FPS", width-150, height-30);
}




void oscEvent(OscMessage theOscMessage) {
  
  if(debugPrint) println(theOscMessage.addrPattern()+" "+theOscMessage.typetag());
  incomingData = true;

  if (ready) {

    // CLIENTS CONNECTING TO THE BROADCASTER
    if (theOscMessage.addrPattern().equals(myConnectPattern)) {
      connect(theOscMessage.netAddress().address());
    }
    else if (theOscMessage.addrPattern().equals(myDisconnectPattern)) {
      disconnect(theOscMessage.netAddress().address());
    }
    
    else if (doMuse) {
      
      int whichMuse = -1;
      
      for( int i=0; i<numMuses; i++) {
        if (theOscMessage.addrPattern().substring(0,patternMuse[i].length()).equals(patternMuse[i])) {
          whichMuse = i;
          break;
        }
      }
      
      
      
      if (whichMuse != -1) {
        
        incomingDataMuse[whichMuse] = true;
        
        if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/horseshoe")) {
          //println("horseshoe "+theOscMessage.typetag());
          if(theOscMessage.typetag().equals("ffff")) {  // mind monitor
            for (int i=0; i<4; i++) muses[whichMuse].horseshoe[i] = (int) theOscMessage.get(i).floatValue();
          } else if(theOscMessage.typetag().equals("dddd")) {
            for (int i=0; i<4; i++) muses[whichMuse].horseshoe[i] = (int)(theOscMessage.get(i).doubleValue());
          } 
          
          // horseshoe is always the last message coming from mind-monitor
          // use this trigger to forward all new data as one bundle together
          if(enableForwarding) {
            forwardBundle(whichMuse);
          }
        } 
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/touching_forehead")) {
          //println("touching_forehead "+theOscMessage.typetag());
          muses[whichMuse].touching_forehead = theOscMessage.get(0).intValue();
        } 
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/batt")) {
          //println("batt " + theOscMessage.typetag());
          if (theOscMessage.typetag().equals("iiii")) {  // mind monitor
            muses[whichMuse].batt = theOscMessage.get(0).intValue()/100;
          } else if(theOscMessage.typetag().equals("ddd")) {
            muses[whichMuse].batt = (int) theOscMessage.get(0).doubleValue();
          }
          
          // forward message as INT
          if(enableForwarding) {
            OscMessage m = new OscMessage(patternReplace[whichMuse] + "/batt");
            m.add(muses[whichMuse].batt);
            oscP5.send(m, myNetAddressList);
          }
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/algorithm/mellow")) {
          muses[whichMuse].mellow = (int) theOscMessage.get(0).floatValue();
        } 
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/algorithm/concentration")) {
          muses[whichMuse].concentration = (int) theOscMessage.get(0).floatValue();
        }
        
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/delta_relative")) {
          receiveElementRelative(theOscMessage, whichMuse, 0);
        }
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/delta_absolute")) {
          receiveElementAbsolute(theOscMessage, whichMuse, 0);
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/theta_relative")) {
          receiveElementRelative(theOscMessage, whichMuse, 1);
        }
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/theta_absolute")) {
          receiveElementAbsolute(theOscMessage, whichMuse, 1);
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/alpha_relative")) {
          receiveElementRelative(theOscMessage, whichMuse, 2);
        }
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/alpha_absolute")) {
          receiveElementAbsolute(theOscMessage, whichMuse, 2);
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/beta_relative")) {
          receiveElementRelative(theOscMessage, whichMuse, 3);
        }
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/beta_absolute")) {
          receiveElementAbsolute(theOscMessage, whichMuse, 3);
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/gamma_relative")) {
          receiveElementRelative(theOscMessage, whichMuse, 4);
          // count the signal cnt one up, every time there's a gamma signal
          muses[whichMuse].signal_cnt++;
        }
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/gamma_absolute")) {
          receiveElementAbsolute(theOscMessage, whichMuse, 4);

          if(!patternMuse[whichMuse].equals("/muse")) {  // mind monitor
            muses[whichMuse].calcRelative();
            // count the signal cnt one up, every time there's a gamma signal
            muses[whichMuse].signal_cnt++;
  
          }
        }
        
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/blink")) {
          //println("blink " + theOscMessage.typetag());
          int v = theOscMessage.get(0).intValue();
          muses[whichMuse].blink = (v==1) ? true : false;
          
          if(v==1 && enableForwarding) {
            OscMessage m = new OscMessage(patternReplace[whichMuse] + "/blink");
            m.add(1);
            oscP5.send(m, myNetAddressList);
          }
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/version")) {
          //println("version " + theOscMessage.get(0));
        }
        
        else {
          // ignore all other incoming OSC messages
          //println(whichMuse + " \t " + theOscMessage.addrPattern() +  "\t" + theOscMessage.typetag());
        }
        
        muses[whichMuse].lastInput = millis();
        
        
      } else {
        // ignore all other incoming OSC messages
        //println(theOscMessage.addrPattern() +  "\t" + theOscMessage.typetag());
      }
      
    }
  
  }
}


void forwardBundle(int whichMuse) {

  // forward all averages now
  OscBundle myBundle = new OscBundle();
  
  OscMessage m = new OscMessage(patternReplace[whichMuse] + "/horseshoe");
  for (int i=0; i<4; i++) m.add(muses[whichMuse].horseshoe[i]);
  myBundle.add(m);
  m.clear();
  
  m.setAddrPattern(patternReplace[whichMuse] + "/forehead");
  m.add(muses[whichMuse].touching_forehead);
  myBundle.add(m);
  m.clear();
  
  for(int b=0; b<5; b++) {
    m.setAddrPattern(patternReplace[whichMuse] + museEEGaddress[b]);
    m.add(muses[whichMuse].relative_avg[b]);
    myBundle.add(m);
    m.clear();
  }
  if(broadcastAbsolute) {
    for(int b=0; b<5; b++) {
      m.setAddrPattern(patternReplace[whichMuse] + museEEGaddress[b] +"/absolute");
      m.add(muses[whichMuse].absolute_avg[b]);
      myBundle.add(m);
      m.clear();
    }
  }
  
  if(displayAlg) {
    // the 'mellow' and 'concentration' values from Mind-Monitor are not very satisfactory
    // see https://mind-monitor.com/FAQ.php
    m.setAddrPattern(patternReplace[whichMuse] + "/mellow");
    m.add(muses[whichMuse].mellow);
    myBundle.add(m);
    m.clear();
    
    m.setAddrPattern(patternReplace[whichMuse] + "/concentration");
    m.add(muses[whichMuse].concentration);
    myBundle.add(m);
    m.clear();
  }
  
  myBundle.setTimetag(myBundle.now() + 10000);
  oscP5.send(myBundle, myNetAddressList);

}




void receiveElementRelative(OscMessage theOscMessage, int whichMuse, int b) {
  //println("delta_relative " + theOscMessage.typetag());
  for (int i=0; i<4; i++) {
    if(theOscMessage.typetag().equals("dddd")) {
      muses[whichMuse].relative[i][b] = (float) theOscMessage.get(i).doubleValue();
    } else if (theOscMessage.typetag().equals("ffff")) {
      muses[whichMuse].relative[i][b] = theOscMessage.get(i).floatValue();
    }
  }
  muses[whichMuse].avg_relative(b);
  
  if(enableForwarding) {
    // forward avg only
    OscMessage m = new OscMessage(patternReplace[whichMuse] + museEEGaddress[b]);
    m.add(muses[whichMuse].relative_avg[b]);
    oscP5.send(m, myNetAddressList);
  }
}




void receiveElementAbsolute(OscMessage theOscMessage, int whichMuse, int b) {
  //println("delta_absolute " + theOscMessage.typetag());   
  if (theOscMessage.typetag().equals("f")) {  // muse monitor
     muses[whichMuse].absolute_avg[b] = theOscMessage.get(0).floatValue();
  } else {
    for (int i=0; i<4; i++) {
      if(theOscMessage.typetag().equals("dddd")) {
        muses[whichMuse].absolute[i][b] = (float) theOscMessage.get(i).doubleValue();
      } else if (theOscMessage.typetag().equals("ffff")) {
        muses[whichMuse].absolute[i][b] = theOscMessage.get(i).floatValue();
      }
    }
    muses[whichMuse].avg_absolute(b);
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
  if(key == 'f') {
    enableForwarding = !enableForwarding;
  } else if(key == 'i') {
    doMuse = !doMuse;
  } else if(key == 'd') {
    debugPrint = !debugPrint;
  }
}
