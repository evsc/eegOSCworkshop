/*
 * receive MUSE2014 data via OSC from muse-io
 * receive 2x MUSE2016 via OSC from muse direct
 * and broadcast via OSC
 *
 * start muse driver MUSEIO
 * ./muse-io --device 00:06:66:6C:11:66 --preset 14 --50hz --dsp --osc osc.udp://localhost:5001,osc.udp://localhost:5002
 */
 

import oscP5.*;
import netP5.*;

/// /muse .. from ubuntu
/// Person1 .. from Muse direct
//String[] patternMuse = { "/tablet2/muse", "Person0", "/muse","/phone2/muse", "/dtlj/muse", "/phone1/muse" };
//String[] patternReplace = { "/Person1", "/Person2", "/Person3", "/Person4", "/Person5", "/Person6" };
// "/muse" has to be in first position, else there's an OSC warning
String[] patternMuse = { "/muse", "Person0", "/tablet2/muse", "/phone2/muse", "/dtlj/muse", "/phone1/muse" };
String[] patternReplace = { "/Person1", "/Person2", "/Person3", "/Person4", "/Person5", "/Person6" };

OscP5 oscP5;
NetAddressList myNetAddressList = new NetAddressList();
String myIP = "192.168.0.100";
//String myIP = "127.0.0.1";
int myListeningPort = 5001;
int myBroadcastPort = 12000;
String myConnectPattern = "/eeg/connect";
String myDisconnectPattern = "/eeg/disconnect";


boolean doMuse = true;
boolean ready = false;
boolean incomingData = false;

PFont myFont;

int numMuses = patternMuse.length;
MuseUnit[] muses;

String[] museEEGband = {"Delta (1-4)", 
                        "Theta (5-8)", 
                        "Alpha (9-13)", 
                        "Beta (13-30)", 
                        "Gamma (30-50)"};

String[] museEEGaddress = { "/delta", "/theta", "/alpha", "/beta", "/gamma"};

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
  
  int signal_cnt;
  int signal_lastsec; 
 
  MuseUnit(int _id) {
    id = _id;
    batt = -1;
    touching_forehead = -1;
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
  size(1500,550);
  oscP5 = new OscP5(this, myListeningPort);
  
  myFont = loadFont("LucidaConsole-26.vlw");
  //myFont = createFont("", 16);
  textFont(myFont);
  textLeading(25);
  
  muses = new MuseUnit[numMuses];
  for (int i=0; i<numMuses; i++) {
    muses[i] = new MuseUnit(i+1);
  }

  lastTimer = millis();
  ready = true;
  
  
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
  fill(100);
  if(incomingData) {
    text("DATA", width-150, height-60);
    incomingData = false;
  }
  text(int(frameRate)+ " FPS", width-150, height-30);
  
  
  fill(255);
  
  
  
  int x = 10;
  int y = firstline;
  
  
  // display OSC addresses
  fill(200);
  textSize(16);
  text("/batt", x, y+=20);
  text("/forehead", x, y+=20);
  text("/horseshoe", x, y+=20);
  y+=20;
  text("/delta", x, y+=20);
  text("/theta", x, y+=20);
  text("/alpha", x, y+=20);
  text("/beta", x, y+=20);
  text("/gamma", x, y+=20);
  y+=20;
  text("update rate", x, y+=20);

  for (int i=0; i<numMuses; i++) {
    
    if (muses[i].lastInput > millis()-1000*10) {
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
   
    y+=20;
    for(int j=0; j<5; j++) {
      //text(nfc(muses[i].relative_avg[j],2) + "    " + nfc(muses[i].absolute_avg[j],2), x, y+=20);
      text(nfc(muses[i].relative_avg[j],3), x, y+=20);
    }
    
    y+=20;
    text(muses[i].signal_lastsec+"Hz", x, y+=20);

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
  text("OSC CLIENTS", x, y);
  fill(255);
  for(int i=0; i<myNetAddressList.size(); i++ ) {
    //text(ipnum[0]+"."+ipnum[1]+"."+ipnum[2]+"."+ipnum[3], 10, 350+i*20, 70, 40);
    text(myNetAddressList.get(i).address(), x, y+=20);
  }
}


 
void oscEvent(OscMessage theOscMessage) {
  
  //println(theOscMessage.addrPattern());
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
        
        if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/horseshoe")) {
          //println("horseshoe "+theOscMessage.typetag());
          if(theOscMessage.typetag().equals("ffff")) {
            for (int i=0; i<4; i++) muses[whichMuse].horseshoe[i] = (int) theOscMessage.get(i).floatValue();
          } else if(theOscMessage.typetag().equals("dddd")) {
            for (int i=0; i<4; i++) muses[whichMuse].horseshoe[i] = (int)(theOscMessage.get(i).doubleValue());
          } 
          
          // forward message as INTS
          OscMessage m = new OscMessage(patternReplace[whichMuse] + "/horseshoe");
          for (int i=0; i<4; i++) m.add(muses[whichMuse].horseshoe[i]);
          oscP5.send(m, myNetAddressList);
        } 
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/touching_forehead")) {
          //println("touching_forehead "+theOscMessage.typetag());
          muses[whichMuse].touching_forehead = theOscMessage.get(0).intValue();
          
          OscMessage m = new OscMessage(patternReplace[whichMuse] + "/forehead");
          m.add(muses[whichMuse].touching_forehead);
          oscP5.send(theOscMessage, myNetAddressList);
        } 
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/batt")) {
          //println("batt " + theOscMessage.typetag());
          if (theOscMessage.typetag().equals("iiii")) {
            muses[whichMuse].batt = theOscMessage.get(0).intValue()/100;
          } else if(theOscMessage.typetag().equals("ddd")) {
            muses[whichMuse].batt = (int) theOscMessage.get(0).doubleValue();
          }
          // forward message as INT
          OscMessage m = new OscMessage(patternReplace[whichMuse] + "/batt");
          m.add(muses[whichMuse].batt);
          oscP5.send(m, myNetAddressList);
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/delta_relative")) {
          //println("delta_relative " + theOscMessage.typetag());
          for (int i=0; i<4; i++) {
            if(theOscMessage.typetag().equals("dddd")) {
              muses[whichMuse].relative[i][0] = (float) theOscMessage.get(i).doubleValue();
            } else if (theOscMessage.typetag().equals("ffff")) {
              muses[whichMuse].relative[i][0] = theOscMessage.get(i).floatValue();
            }
          }
          muses[whichMuse].avg_relative(0);
          
          // forward avg only
          OscMessage m = new OscMessage(patternReplace[whichMuse] + "/delta");
          m.add(muses[whichMuse].relative_avg[0]);
          oscP5.send(m, myNetAddressList);
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/delta_absolute")) {
          //println("delta_absolute " + theOscMessage.typetag());
          
          if (theOscMessage.typetag().equals("f")) {
             // muse monitor
             muses[whichMuse].absolute_avg[0] = theOscMessage.get(0).floatValue();
          } else {
            for (int i=0; i<4; i++) {
              if(theOscMessage.typetag().equals("dddd")) {
                muses[whichMuse].absolute[i][0] = (float) theOscMessage.get(i).doubleValue();
              } else if (theOscMessage.typetag().equals("ffff")) {
                muses[whichMuse].absolute[i][0] = theOscMessage.get(i).floatValue();
              }
            }
            muses[whichMuse].avg_absolute(0);
          }
          // forward avg only
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/theta_relative")) {
          //println("theta_relative " + theOscMessage.typetag());
          for (int i=0; i<4; i++) {
            if(theOscMessage.typetag().equals("dddd")) {
              muses[whichMuse].relative[i][1] = (float) theOscMessage.get(i).doubleValue();
            } else if (theOscMessage.typetag().equals("ffff")) {
              muses[whichMuse].relative[i][1] = theOscMessage.get(i).floatValue();
            }
          }
          muses[whichMuse].avg_relative(1);
          
          // forward avg only
          OscMessage m = new OscMessage(patternReplace[whichMuse] + "/theta");
          m.add(muses[whichMuse].relative_avg[1]);
          oscP5.send(m, myNetAddressList);
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/theta_absolute")) {
          //println("theta_absolute " + theOscMessage.typetag());
          
          if (theOscMessage.typetag().equals("f")) {
             // muse monitor
             muses[whichMuse].absolute_avg[1] = theOscMessage.get(0).floatValue();
          } else {
            for (int i=0; i<4; i++) {
              if(theOscMessage.typetag().equals("dddd")) {
                muses[whichMuse].absolute[i][1] = (float) theOscMessage.get(i).doubleValue();
              } else if (theOscMessage.typetag().equals("ffff")) {
                muses[whichMuse].absolute[i][1] = theOscMessage.get(i).floatValue();
              }
            }
            muses[whichMuse].avg_absolute(1);
          }
          // forward avg only
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/alpha_relative")) {
          //println("alpha_relative " + theOscMessage.typetag());
          for (int i=0; i<4; i++) {
            if(theOscMessage.typetag().equals("dddd")) {
              muses[whichMuse].relative[i][2] = (float) theOscMessage.get(i).doubleValue();
            } else if (theOscMessage.typetag().equals("ffff")) {
              muses[whichMuse].relative[i][2] = theOscMessage.get(i).floatValue();
            }
          }
          muses[whichMuse].avg_relative(2);
          
          // forward avg only
          OscMessage m = new OscMessage(patternReplace[whichMuse] + "/alpha");
          m.add(muses[whichMuse].relative_avg[2]);
          oscP5.send(m, myNetAddressList);
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/alpha_absolute")) {
          //println("alpha_absolute " + theOscMessage.typetag());
          
          if (theOscMessage.typetag().equals("f")) {
             // muse monitor
             muses[whichMuse].absolute_avg[2] = theOscMessage.get(0).floatValue();
          } else {
            for (int i=0; i<4; i++) {
              if(theOscMessage.typetag().equals("dddd")) {
                muses[whichMuse].absolute[i][2] = (float) theOscMessage.get(i).doubleValue();
              } else if (theOscMessage.typetag().equals("ffff")) {
                muses[whichMuse].absolute[i][2] = theOscMessage.get(i).floatValue();
              }
            }
            muses[whichMuse].avg_absolute(2);
          }
          // forward avg only
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/beta_relative")) {
          //println("beta_relative " + theOscMessage.typetag());
          for (int i=0; i<4; i++) {
            if(theOscMessage.typetag().equals("dddd")) {
              muses[whichMuse].relative[i][3] = (float) theOscMessage.get(i).doubleValue();
            } else if (theOscMessage.typetag().equals("ffff")) {
              muses[whichMuse].relative[i][3] = theOscMessage.get(i).floatValue();
            }
          }
          muses[whichMuse].avg_relative(3);
          
          // forward avg only
          OscMessage m = new OscMessage(patternReplace[whichMuse] + "/beta");
          m.add(muses[whichMuse].relative_avg[3]);
          oscP5.send(m, myNetAddressList);
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/beta_absolute")) {
          //println("beta_absolute " + theOscMessage.typetag());
          
          if (theOscMessage.typetag().equals("f")) {
             // muse monitor
             muses[whichMuse].absolute_avg[3] = theOscMessage.get(0).floatValue();
          } else {
            for (int i=0; i<4; i++) {
              if(theOscMessage.typetag().equals("dddd")) {
                muses[whichMuse].absolute[i][3] = (float) theOscMessage.get(i).doubleValue();
              } else if (theOscMessage.typetag().equals("ffff")) {
                muses[whichMuse].absolute[i][3] = theOscMessage.get(i).floatValue();
              }
            }
            muses[whichMuse].avg_absolute(3);
          }
          // forward avg only
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/gamma_relative")) {
          //println("gamma_relative " + theOscMessage.typetag());
          for (int i=0; i<4; i++) {
            if(theOscMessage.typetag().equals("dddd")) {
              muses[whichMuse].relative[i][4] = (float) theOscMessage.get(i).doubleValue();
            } else if (theOscMessage.typetag().equals("ffff")) {
              muses[whichMuse].relative[i][4] = theOscMessage.get(i).floatValue();
            }
          }
          muses[whichMuse].avg_relative(4);
          
          // forward avg only
          OscMessage m = new OscMessage(patternReplace[whichMuse] + "/gamma");
          m.add(muses[whichMuse].relative_avg[4]);
          oscP5.send(m, myNetAddressList);
          
          // count the signal cnt one up, every time there's a gamma signal
          muses[whichMuse].signal_cnt++;
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/elements/gamma_absolute")) {
          //println("gamma_absolute " + theOscMessage.typetag());
          
          if (theOscMessage.typetag().equals("f")) {
             // muse monitor
             muses[whichMuse].absolute_avg[4] = theOscMessage.get(0).floatValue();
          } else {
            for (int i=0; i<4; i++) {
              if(theOscMessage.typetag().equals("dddd")) {
                muses[whichMuse].absolute[i][4] = (float) theOscMessage.get(i).doubleValue();
              } else if (theOscMessage.typetag().equals("ffff")) {
                muses[whichMuse].absolute[i][4] = theOscMessage.get(i).floatValue();
              }
            }
            muses[whichMuse].avg_absolute(4);
          }
          
          if(!patternMuse[whichMuse].equals("/muse")) {
            muses[whichMuse].calcRelative();

            // count the signal cnt one up, every time there's a gamma signal
            muses[whichMuse].signal_cnt++;
          
            // forward all averages now
            for(int b=0; b<5; b++) {
              OscMessage m = new OscMessage(patternReplace[whichMuse] + museEEGaddress[b]);
              m.add(muses[whichMuse].relative_avg[b]);
              oscP5.send(m, myNetAddressList);
            }
          }
        }
        
        else if (theOscMessage.addrPattern().equals(patternMuse[whichMuse] + "/blink")) {
          //println("blink " + theOscMessage.typetag());
          int v = theOscMessage.get(0).intValue();
          muses[whichMuse].blink = (v==1) ? true : false;
          if(v==1) {
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
