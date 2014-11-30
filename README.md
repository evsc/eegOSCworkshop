
EEG via OSC workshop
===

broadcasting EEG data from MyndPlay BrainBand XL (NeuroSky chip) of ZEO bedside display via OSC and allowing multiple clients to receive and interpret the data


ofxThinkgear addon: https://github.com/evsc/ofxThinkgear


OSC messages
---

zeo broadcast:

	# ZEO's 7 frequency bins fffffff
	/slice 0. 0. 0. 0. 0. 0. 0. 
	# ZEO's sleep state i
	/state 0


TODO
---
- osc broadcaster for thinkgear


How To (Ubuntu 14)
---
Figure out your device's mac address by connecting to it with the Bluetooth New Device Setup. 

Initial mapping of bluetooth device to serial port, see http://askubuntu.com/questions/248817/how-to-i-connect-a-raw-serial-terminal-to-a-bluetooth-connection

	$ cat /etc/bluetooth/rfcomm.conf 

	rfcomm0 {
		bind no;
		device XX:XX:XX:XX:XX:XX;
		channel	1;
		comment "brainbandxl_bluetooth";
	}


Establishing pairing to bluetooth device with

	$ sudo rfcomm connect 0

should print out:

	Connected /dev/rfcomm0 to XX:XX:XX:XX:XX:XX on channel 1
	Press CTRL-C for hangup

