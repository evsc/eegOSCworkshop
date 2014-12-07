
# EEG via OSC workshop

broadcasting EEG data from MyndPlay BrainBand XL (NeuroSky chip) of ZEO bedside display via OSC and allowing multiple clients to receive and interpret the data


ofxThinkgear addon: https://github.com/evsc/ofxThinkgear


## OSC messages

### zeo broadcast

	# ZEO's 7 frequency bins fffffff
	/slice 0. 0. 0. 0. 0. 0. 0. 
	# ZEO's sleep state i
	/state 0

### thinkgear broadcast

	... 


## ThinkGear EEG

Myndplay BrainBandXL

EEG headset, soft headband with 2 dry sensor contact points (1 single sensor) and an ear clip. Runs with ThinkGear chip, 10 hour battery, Bluetooth 4.0 up to 30m range ([Blue Creation BC127](http://www.bluecreation.com/product_info.php?products_id=38)), 512Hz sampling rate.


EEG frequency bands  

* delta (0.5 - 2.75Hz)
* theta (3.5 - 6.75Hz)
* low-alpha (7.5 - 9.25Hz)
* high-alpha (10 - 11.75Hz)
* low-beta (13 - 16.75Hz)
* high-beta (18 - 29.75Hz)
* low-gamma (31 - 39.75Hz)
* mid-gamma (41 - 49.75Hz)


Interpretive data

* Attention (focus, concentration)
* Meditation (relaxation)
* eyeblink detection (only when access via ThinkGearConnector driver)



# Setup (Ubuntu 14)

## ThinkGear

### Bluetooth connection

Figure out your device's mac address by connecting to it with the Bluetooth New Device Setup.  

Initial mapping of bluetooth device to serial port, see http://askubuntu.com/questions/248817/how-to-i-connect-a-raw-serial-terminal-to-a-bluetooth-connection

	$ sudo nano /etc/bluetooth/rfcomm.conf 

	rfcomm0 {
		bind no;
		device XX:XX:XX:XX:XX:XX;
		channel	1;
		comment "brainbandxl_bluetooth";
	}

Establishing pairing to bluetooth device with the Bluetooth menu. Then map the bluetooth data to the serial port with 

	$ sudo rfcomm connect 0


should print out (while blinking of LED should have slowed down)

	Connected /dev/rfcomm0 to XX:XX:XX:XX:XX:XX on channel 1
	Press CTRL-C for hangup

If it says
	
	Can't connect RFCOMM socket: Host is down

then try toggeling the sensor unit on and off, and/or toggeling your computer's bluetooth on and off. 

If it says

	Can't create RFCOMM TTY: Address already in use

stop the app and try to reconnect


#### Screen

Verify that serial data is coming in (should print out a bunch of unencoded jibberish)

	$ sudo screen /dev/rfcomm0

Note, both screen and OF app need to be run with sudo, in order to read serial data from the port. 




### Hardware Reset

In case of emergencies, these are the steps to do a hardware reset on the sensor unit:

* Plug in USB: light should go on solid
* Hold down button for 5 seconds so it is flashing
* Press twice
* Press again and hold until light goes off (~ 7 sec)
* Unplug from USB, and plug back in