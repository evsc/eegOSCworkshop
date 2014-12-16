

int ledR = 9;
int ledG = 10;
int ledB = 11;

int inByte = 0;
int vRed = 0;
int vGreen = 0;
int vBlue = 0;

void setup() {
  
  pinMode(ledR, OUTPUT); 
  pinMode(ledG, OUTPUT); 
  pinMode(ledB, OUTPUT); 
  
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }
  
  
  Serial.println("hello world, let's make RGB lights");
  setRGB(0,255,0);
  
}

void loop() {
  
  while (Serial.available() > 0) {
   
    vRed = Serial.parseInt(); 
    vGreen = Serial.parseInt(); 
    vBlue = Serial.parseInt(); 
    
    Serial.print("RGB: ");
    Serial.print(vRed);
    Serial.print(" ");
    Serial.print(vGreen);
    Serial.print(" ");
    Serial.println(vBlue);
    
    if (Serial.read() == '\n') {

      vRed = constrain(vRed, 0, 255);
      vGreen = constrain(vGreen, 0, 255);
      vBlue = constrain(vBlue, 0, 255);
         
      setRGB(vRed, vGreen, vBlue);
      
    }
    
  }
  
  
  // faderCode
//  for(int fadeValue = 0 ; fadeValue <= 255; fadeValue +=5) { 
//    analogWrite(ledR, fadeValue);    
//    analogWrite(ledG, 255-fadeValue);   
//    analogWrite(ledB, fadeValue);       
//    delay(30);                            
//  } 
//
//  for(int fadeValue = 255 ; fadeValue >= 0; fadeValue -=5) { 
//    analogWrite(ledR, fadeValue);    
//    analogWrite(ledG, 255-fadeValue);  
//    analogWrite(ledB, fadeValue);   
//    delay(30);                            
//  } 
  
}

void setRGB(int r, int g, int b) {
  analogWrite(ledR, 255-r);
  analogWrite(ledG, 255-g);
  analogWrite(ledB, 255-b);
}
