//
// MUSE display spectrum FFT
// receive data from eeg_broadcast


import oscP5.*;
import netP5.*;


OscP5 oscP5;
/* a NetAddress contains the ip address and 
port number of a remote location in the network. */
NetAddress myBroadcastLocation; 

String broadcastIP = "127.0.0.1";
int broadcastPort = 5001;
int listeningPort = 12000;

PFont bigFont;
PFont smFont;

float museFFT[][];

void setup() {
  
  size(1200,850);
  
  museFFT = new float[4][129];
  for (int i=0; i<4; i++) {
    for (int j=0; j<129; j++) {
      museFFT[i][j] = 0;
    }
  }
  
  /* create a new instance of oscP5. 
   * 12000 is the port number you are listening for incoming osc messages.
   */
  oscP5 = new OscP5(this,listeningPort);

  /* the address of the osc broadcast server */
  myBroadcastLocation = new NetAddress(broadcastIP, broadcastPort);
  
  smFont = createFont("", 14);
  bigFont = createFont("", 30);
  textFont(bigFont);

  
  prepareExitHandler();
  connectOscClient();
  
}


void draw() {
  
  background(100);
  
  int x = 100;
  int y = 100;
  int w = width-200;
  int h = height-500;
  float col = w/129.0;
  float scaler = 5;
  fill(255);
  noStroke();
  for (int i=0; i<129; i++) {
    rect(x+i*col,y+h, col,museFFT[1][i]*scaler);
    
  }
  
  
  
}





/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  // theOscMessage.print();
   
  // muse
  if (theOscMessage.addrPattern().equals("/muse/elements/raw_fft0")) {
    for (int i=0; i<129; i++) museFFT[0][i] = int(theOscMessage.get(i).floatValue());
  } else if (theOscMessage.addrPattern().equals("/muse/elements/raw_fft1")) {
    for (int i=0; i<129; i++) museFFT[1][i] = int(theOscMessage.get(i).floatValue());
  } else if (theOscMessage.addrPattern().equals("/muse/elements/raw_fft2")) {
    for (int i=0; i<129; i++) museFFT[2][i] = int(theOscMessage.get(i).floatValue());
  } else if (theOscMessage.addrPattern().equals("/muse/elements/raw_fft3")) {
    for (int i=0; i<129; i++) museFFT[3][i] = int(theOscMessage.get(i).floatValue());
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