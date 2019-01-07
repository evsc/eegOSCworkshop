﻿﻿﻿﻿﻿﻿﻿# EEG via OSC workshopThis repository contains software that enables the broadcasting of data from different EEG sensors  via OSC.  There are also multiple simple software clients to receive and interpret the data. ## EEG headsetsThe 4 EEG headsets I've used so far: * [ZEO](http://en.wikipedia.org/wiki/Zeo,_Inc.) bedside display * [MyndPlay BrainBandXL](http://myndplay.com/products.php?prod=9) * [Muse](http://www.choosemuse.com) * [Emotiv Insight](https://emotiv.com/insight.php)The **ZEO headband**'s main purpose is to monitor your brainwaves during sleep, it is quite comfortable to wear, and a proprietary algorithm calculates your sleep stages during the night (deep / light / rem / wake). You can access live brainwave data over a serial port. Problem is, the company went bankrupt in 2012, you might only be able to get one of those off ebay. Also, the headband's conductive-fabric sensors get quite some wear during sleep and you are meant to replace them occasionally, but now it's hard to still find originals to buy. The **Myndplay BrainbandXL** is build around a [NeuroSky ThinkGear chip](http://neurosky.com/products-markets/eeg-biosensors/hardware/) and a Bluetooth 4.0 module ([Blue Creation BC127](http://www.bluecreation.com/product_info.php?products_id=38)). The soft headband has 2 conductive-fabric electrodes (=only 1 channel) sitting on your forehead. In addition you clip a grounding electrode onto your ear, which becomes slightly uncomfortable after a while. Data is transmitted about once per second. Besides 8 frequency bands, the ThinkGear chip provides the proprietary eSense algorithms that define a *meditation* (relaxation) and *attention* (focus, concentration) level. These are very useful when wanting to achieve fast prototyping results. In addition the ThinkGear Communications Protocol can also detect eye blinks (not implemented here). To change between 50 and 60 Hz zones, a [solder spot](https://www.flickr.com/photos/evsc/15347233443/) must be changed on the ThinkGear chip. **Muse** is the more advanced than the previous two, as it provides 4 signal channels (2 on your forehead, and 1 behind each of your ears) and also accelerometer data. The supplied MuseIO driver streams data via OSC. For each channel you get raw signal data, 6 frequency bands and also FFT spectrum data. In addtion it reports blink and jaw_clench events. The 50/60Hz filter can be set within the driver. As it is the most powerful, it also seems to be the most sensitive. You are advised to sit up straight and don't move around, while doing measurements. It really can take a long time to calibrate, but at least you catch a glimpse of all the software processes that are necessary to receive reliable data. **Emotiv Insight** provides 5 signal channels (2 on forehead, 1 behind each ear, and one on the back of head). Of all the headbands this one can get the most uncomfortable to wear, as you have to place multiple quite rigid sensors probes across your skull. It's often also hard to achieve good signal quality, they recommend to apply a saline solution to the electrodes for better conductivity. I haven't succeeded in getting the API to run on Ubuntu, therefore this repository doesn't contain any software for the Insight. But Emotiv has 2 quite good apps in the app store for interfacing with the headset.<p align="center">	<img src="https://raw.githubusercontent.com/evsc/eegOSCworkshop/master/presentation/img/bci_compare.png"/></p>### To run Muse headsets ## On UbuntuYou connect to Muse via bluetooth. Get the [MuseSDK](https://sites.google.com/a/interaxon.ca/muse-developer-site/download) and run the MuseIO driver via the commandline, to broadcast OSC data.```shell # stream OSC data muse-io --preset 14 --50hz --dsp --osc osc.udp://localhost:5001```## On WindowsFor Muse 2016 devices use [Muse Direct](http://developer.choosemuse.com/tools/windows-tools/musedirect) to receive Muse data and output it via OSC.## Receive DataThe outgoing OSC data from either _MuseIO_ or _Muse Direct_ is meant to be received by the [eeg\_broadcast\_3](https://github.com/evsc/eegOSCworkshop/tree/master/broadcaster) processing app, which simplifies and broadcasts data from multiple Muse sensors simultaneously. Else, you can also use the SDK supplied [MuseLab](https://sites.google.com/a/interaxon.ca/muse-developer-site/muselab) visualization tool to quickly monitor the data. <p align="center">	<img src="https://raw.githubusercontent.com/evsc/eegOSCworkshop/master/presentation/img/muselab.PNG"/></p>