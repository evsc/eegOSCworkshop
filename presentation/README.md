
#  EEG - ELECTRO ENCEPHALO GRAPHY

Recording of electrical activity along the scalp

<p align="center">
	<img src="https://raw.githubusercontent.com/evsc/eegOSCworkshop/master/presentation/img/eeg.jpg"/>
</p>


## Electricity on my mind

Electrical activity in the form of nerve impulses. 100 billion neurons. When the all fire in synchrony, a rhythm can be detected. 

<p align="center">
	<img src="https://raw.githubusercontent.com/evsc/eegOSCworkshop/master/presentation/img/neuron.png"/>
</p>


## EEG History

| year | history |
| ------- | ------- |
| **1875, 1890** | EEG activity of animals  |
| **1924** | first human EEG, Hans Berger named EEG  |
| **1937** | stages of sleep  |

<p align="center">
	<img src="https://raw.githubusercontent.com/evsc/eegOSCworkshop/master/presentation/img/Berger_EEG.jpg"/>
</p>



## Brainwaves

An EEG electrode detects the electrical activity from thousands of neurons underneath its sensor. One square millimeter of cortex has more than 100,000 neurons. The amplitudes recorded by scalp electrodes are in the range of microvolts. 

Amplitude and frequency are the primary characteristics of brain waves. The more neurons that work in synchrony, the larger the potential (amplitude) of the electrical oscillations measu­red in microvolts. The faster the neurons work together, the higher the frequency of the oscilla­tions measured in Hertz.

| WAVE | FREQ | STATE | AMPLITUDE | 
| ------- | ------- | ------- |------- |
| **GAMMA** | 30-120 Hz | hyper active, high energy state, ecstasy  | |
| **BETA** | 14-30 Hz | active thinking, alert | 5-10 uV |
| **ALPHA** | 7-14 Hz | idle state, relaxed focus, meditation, eyes closed | 20-200 uV |
| **THETA** | 4-7 Hz | drowsy, dreams, trance states | 10 uV |
| **DELTA** | < 4 Hz | dreamless sleep, coma | 20-200 uV |

<p align="center">
	<img src="https://raw.githubusercontent.com/evsc/eegOSCworkshop/master/presentation/img/Brain-Waves-Graph-1024x827.jpg"/>
</p>




## Measuring the Brain

| Method | Name | how it works |
| ------- | ------- | ------- | 
| **CT** | X-Ray Computed Tomography | | |
| **PET** | Position Emission Tomography | | |
| **MRI / fMRI** -| (Functional) Magnetic Resonance Imaging | measures blood flow changes | extreme spacial resolution |
| **MEG** | Magneto Encephalo Graphy | measures magnetic field | requires room of shielding |
| **fNIRS** | Functional Near-Infrared Spectroscopy | | low resolution (space, time) |
|  | Invasive Sensors | microarrays, neurochips, ECoG, ... | 




## Brain Computer Interfaces

Consumer affordable BCI interfaces, usually with only 1 to 5 channels. 

* [EPOC](https://emotiv.com/epoc.php) by Emotiv System
* BrainBand by [MyndPlay](http://myndplay.com/)
* [MindWave](http://store.neurosky.com/products/mindwave-1) by Neurosky
* [Muse](http://www.choosemuse.com/) by InteraXon
* [Open BCI](http://openbci.com/)
* [ModularEEG](http://openeeg.sourceforge.net/doc/modeeg/modeeg.html)

<p align="center">
	<img src="https://raw.githubusercontent.com/evsc/eegOSCworkshop/master/presentation/img/bci_compare.png"/>
</p>


## Sensors

dry or wet (conductive paste)

A electrode always needs at least a second electrode as a reference signal, so it can measure the difference in electrical potential (voltage) between their two positions. An electrode on the earlobe acts as a point of reference, ‘ground’, of the body’s baseline voltage due to other electrical activities within the body.

### 10-20 System

Electrode positions have been named according to the brain region below the area of the scalp: frontal, central (sulcus), parietal, temporal, and occipital. 

 * 19 recording electrodes
 * 1 ground
 * 1 system reference

<p align="center">
	<img src="https://raw.githubusercontent.com/evsc/eegOSCworkshop/master/presentation/img/image011.jpg"/>
</p>

## Circuitry

 1. Electrode and Reference
 2. Differential amplifier
 3. Amplifier
 4. 50/60 Hertz Filter
 5. Analog Digital Conversion (256-512 Hz, up to 20kHz)


<p align="center">
	<img src="https://raw.githubusercontent.com/evsc/eegOSCworkshop/master/presentation/img/circuitry.png"/>
</p>

After: FFT frequency analysis


## Types of BCI

| Type | what | example |
| ----- | ---- |---- |
| **Active BCI** | derives its outputs from brain activity which is consciously controlled by the user | |
| **Reactive BCI** | derives its outputs from brain activity arising in reaction to external stimulation, which is indirectly modulated by the user for controlling an application | |
| **Passive BCI** | derives its outputs from arbitrary brain activity without the purpose of voluntary control, for enriching a human-computer interaction with implicit information | |

## What can you measure?

| Class | what |
| ----- | ---- |
| Tonic state | slow changing brain processes: degree of relaxation, stress level, ... |
| Phasic State | fast states, switching attention, imagining movement .. |
| Event-related state | rely on presence of event: surprised/not surprised, committed error ... |





# Using EEG data

## Watch out

 * Variability! signals are different for every person
 * Variability! placement of sensors
 * Variability! brain dynamics constantly change
 * Signal-to-noise ratio very noisy!
 * Redundancy: all channels almost record the same signal
 * Calibration needed: record a baseline first


## EEG in Neurological Diagnostic

 * Epilepsy
 * Coma
 * Brain death
 * Brain dysfunctions
 * Sleep research
 * Sleep disorders
 * Anesthesia

## Applications

 * Speller programs, for locked-in syndrome
 * Prosthetic control, control wheelchair
 * Forensics, lie detection, brain fingerprinting
 * Gaming
 * Health: sleep stage recognition, neurorehabilitation


## Projects 

 * Alvin Lucier [Music For Solo Performer](https://www.youtube.com/watch?v=bIPU2ynqy2Y) (1965) 
 * Onur Sonmez - Tim Devine [The Mexican Standoff](https://vimeo.com/10047079) (2010)
 * Masaki Batoh [Brain Pulse Music Machine](http://www.monsterfresh.com/2012/04/04/masaki-batoh-brain-pulse-music-machine/) (2012)
 * George Khut + James Brown [ThetaLab](http://georgekhut.com/2013/07/thetalab-creative-neurofeedback-june-2013/) (2013)
 * Lisa Park [Eunoia](http://thelisapark.com/#/eunoia) (2013)
 * Varvara Guljajeva, Mar Canet and Sebastian Mealla - [NeuroKnitting](http://www.knitic.com/neuro/) (2013)
 * University Of Minnesota [Mind Over Mechanics (Control a drone with your thoughts)](https://www.youtube.com/watch?v=rpHy-fUyXYk) (2013)
 * Mats Sivertsen [subConch](http://www.mats-sivertsen.net/subconch.html) (2013)
 * Jody Xiong [Mind Art](http://thecreatorsproject.vice.com/blog/this-art-project-lets-anyone-paint-with-brainwaves) (2014)
 * Eduardo Miranda [Activating Memory](https://vimeo.com/89601884) (2014)
 * Ion Popian [Mental Fabrication](http://thecreatorsproject.vice.com/blog/this-machine-turns-your-mental-map-into-an-architectural-structure) (2014)



# DATA what to do

 * data visualization
 * data sonification
 * data trigger
 * neurofeedback
 * brain entrainment



# Brain Future

 * Gallant Lab, UC Berkley [Movie reconstruction from human brain activity](https://www.youtube.com/watch?v=nsjDnYxJ0bo)













