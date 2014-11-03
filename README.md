
EEG via OSC workshop
===

broadcasting EEG data from MyndPlay BrainBand XL (NeuroSky chip) via OSC and allowing multiple clients to receive and interpret the data


ofxThinkgear addon: https://github.com/evsc/ofxThinkgear



How To (Ubuntu 14)
---

Initial mapping of bluetooth device to serial port, see http://askubuntu.com/questions/248817/how-to-i-connect-a-raw-serial-terminal-to-a-bluetooth-connection

	$ cat rfcomm.conf 

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

