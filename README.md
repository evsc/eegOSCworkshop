
# EEG via OSC workshop

This repository contains software that enables the broadcasting of data from different EEG sensors  via OSC.  There are also multiple simple software clients to receive and interpret the data. 

## EEG headsets

The 4 EEG headsets I've used so far:

 * [ZEO](http://en.wikipedia.org/wiki/Zeo,_Inc.) bedside display
 * [MyndPlay BrainBandXL](http://myndplay.com/products.php?prod=9)
 * [Muse](http://www.choosemuse.com)
 * [Emotiv Insight](https://emotiv.com/insight.php)

The **ZEO headband**'s main purpose is to monitor your brainwaves during sleep, it is quite comfortable to wear, and a proprietary algorithm calculates your sleep stages during the night (deep / light / rem / wake). You can access live brainwave data over a serial port. Problem is, the company went bankrupt in 2012, you might only be able to get one of those off ebay. Also, the headband's conductive-fabric sensors get quite some wear during sleep and you are meant to replace them occasionally, but now it's hard to still find originals to buy. 

The **Myndplay BrainbandXL** is build around a [NeuroSky ThinkGear chip](http://neurosky.com/products-markets/eeg-biosensors/hardware/) and a Bluetooth 4.0 module ([Blue Creation BC127](http://www.bluecreation.com/product_info.php?products_id=38)). The soft headband has 2 conductive-fabric electrodes (=only 1 channel) sitting on your forehead. In addition you clip a grounding electrode onto your ear, which becomes slightly uncomfortable after a while. Data is transmitted about once per second. Besides 8 frequency bands, the ThinkGear chip provides the proprietary eSense algorithms that define a *meditation* (relaxation) and *attention* (focus, concentration) level. These are very useful when wanting to achieve fast prototyping results. In addition the ThinkGear Communications Protocol can also detect eye blinks (not implemented here). To change between 50 and 60 Hz zones, a [solder spot](https://www.flickr.com/photos/evsc/15347233443/) must be changed on the ThinkGear chip. 

**Muse** is the more advanced than the previous two, as it provides 4 signal channels (2 on your forehead, and 1 behind each of your ears) and also accelerometer data. The supplied MuseIO driver streams data via OSC. For each channel you get raw signal data, 6 frequency bands and also FFT spectrum data. In addition it reports blink and jaw_clench events. The 50/60Hz filter can be set within the driver. As it is the most powerful, it also seems to be the most sensitive. You are advised to sit up straight and don't move around, while doing measurements. It really can take a long time to calibrate, but at least you catch a glimpse of all the software processes that are necessary to receive reliable data. 

**Emotiv Insight** provides 5 signal channels (2 on forehead, 1 behind each ear, and one on the back of head). Of all the headbands this one can get the most uncomfortable to wear, as you have to place multiple quite rigid sensors probes across your skull. It's often also hard to achieve good signal quality, they recommend to apply a saline solution to the electrodes for better conductivity. I haven't succeeded in getting the API to run on Ubuntu, therefore this repository doesn't contain any software for the Insight. Yet Emotiv has 2 quite good apps in the app store for interfacing with the headset.

<p align="center">
	<img src="https://raw.githubusercontent.com/evsc/eegOSCworkshop/master/presentation/img/bci_compare.png"/>
</p>

### To stream ZEO headset data
You will need a FTDI usb cable to connect the ZEO bedside display to your computer. Then you need the [zeoLibrary processing library](https://github.com/evsc/zeoLibrary), so you can run the [eeg_broadcast](https://github.com/evsc/eegOSCworkshop/tree/master/eeg_broadcast) processing app to receive data via the Serial port, and broadcast it via OSC. 

<p align="center">
	<img src="https://raw.githubusercontent.com/evsc/eegOSCworkshop/master/presentation/img/eeg_broadcast.PNG"/>
</p>

### To stream Myndplay BrainBandXL data
You connect to the BrainBandXL via bluetooth. To receive and decode data over bluetooth run the openFrameworks app [thinkgear_broadcast](https://github.com/evsc/eegOSCworkshop/tree/master/thinkgear_broadcast) (requires 
[ofxThinkgear addon](https://github.com/evsc/ofxThinkgear)). The outgoing OSC data is meant to be received by the [eeg_broadcast](https://github.com/evsc/eegOSCworkshop/tree/master/eeg_broadcast) processing app, from where you could broadcast data from all 3 EEG sensors simultaneously. 

<p align="center">
	<img src="https://raw.githubusercontent.com/evsc/eegOSCworkshop/master/presentation/img/thinkgear_broadcast.PNG"/>
</p>


### To run Muse headset
You connect to Muse via bluetooth. Get the [MuseSDK](https://sites.google.com/a/interaxon.ca/muse-developer-site/download) and run the MuseIO driver via the commandline, to broadcast OSC data.

```shell 
# stream OSC data on 2 ports (5001 for clients, 5002 for extra MuseLab monitoring)
muse-io --preset 14 --50hz --dsp --osc osc.udp://localhost:5001,osc.udp://localhost:5002
```

The outgoing OSC data is meant to be received by the [eeg_broadcast](https://github.com/evsc/eegOSCworkshop/tree/master/eeg_broadcast) processing app, from where you could broadcast data from all 3 EEG sensors simultaneously. You can also use the SDK supplied [MuseLab](https://sites.google.com/a/interaxon.ca/muse-developer-site/muselab) visualization tool to quickly monitor the data. 

<p align="center">
	<img src="https://raw.githubusercontent.com/evsc/eegOSCworkshop/master/presentation/img/muselab.PNG"/>
</p>


## OSC messages

To connect/disconnect your software client to/from the eeg_broadcast OSC server, send these messages

```shell
/eeg/connect
/eeg/disconnect
```

Then your client will be able to receive the following OSC messages:


### ZEO

```shell
# ZEO's 7 frequency bins: 
# (1) delta (2) theta (3) alpha (4) beta1 (5) beta2 (6) beta3 (7) gamma
/zeo/slice fffffff
# ZEO's sleep state
/zeo/state i
```

### Myndplay BrainBandXL

```shell
# quality of signal. 200=no signal, 0=good
/thinkgear/poorsignal i
# thinkgear proprietary eSense meters: attention, meditation, range: 0-100
/thinkgear/attention i
/thinkgear/meditation i
# 8 frequency bands: (1) delta (2) theta (3) lowAlpha (4) highAlpha 
# (5) lowBeta (6) highBeta (7) lowGamma (8) midGamma
/thinkgear/eeg iiiiiiii
```

ThinkGear EEG frequency bands  

* delta (0.5 - 2.75Hz)
* theta (3.5 - 6.75Hz)
* low-alpha (7.5 - 9.25Hz)
* high-alpha (10 - 11.75Hz)
* low-beta (13 - 16.75Hz)
* high-beta (18 - 29.75Hz)
* low-gamma (31 - 39.75Hz)
* mid-gamma (41 - 49.75Hz)

### Muse
The Muse headband has 4 sensors, the values are communicated in the order: (1) left ear (2) left forehead (3) right forehead (4) right ear. All OSC values you can receive from the muse-io driver (v3-6-0), are documented [here](https://sites.google.com/a/interaxon.ca/muse-developer-site/museio/osc-paths/osc-paths---v3-6-0). [Note: the eeg_broadcast application only passes on selected messages.]

```shell
# status indicator for sensors, 1=good, 2=ok, >=3=bad
/muse/elements/horseshoe ffff

# frequency bands - absolute values 
/muse/elements/delta_absolute dddd 	# 1-4Hz
/muse/elements/theta_absolute dddd  # 5-8Hz
/muse/elements/alpha_absolute dddd  # 9-13Hz
/muse/elements/beta_absolute dddd  # 13-30Hz
/muse/elements/gamma_absolute dddd  # 30-50Hz

# frequency bands - relative values (0-1.0)
/muse/elements/delta_relative dddd 	# 1-4Hz
/muse/elements/theta_relative dddd  # 5-8Hz
/muse/elements/alpha_relative dddd  # 9-13Hz
/muse/elements/beta_relative dddd  # 13-30Hz
/muse/elements/gamma_relative dddd  # 30-50Hz

# detection of muscle movement: blink, jaw_clench, 1=detected
/muse/elements/blink i 
/muse/elements/jaw_clench i

# FFT (Fast Fourier Transform) spectrum data, 
# amplitude for each frequency, 129 bins btw. 0-110Hz
/muse/elements/raw_fft0 fffffffffffffffffffffffffffffffff.........
/muse/elements/raw_fft1
/muse/elements/raw_fft2
/muse/elements/raw_fft3

# EEG of 4 sensors, in microvolt range 0-1682.0
/muse/eeg ffff
# multiply eeg value with quantization value to get uncompressed value
/muse/eeg/quantization iiii
	
# accelerometer values 
# (1) forward/backward (2) up/down (3) left/right, range: -2000 to 1996 mg
/muse/acc fff
```



***

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
