# BWAIN: BMI Without An Interesting Name
A Brain-Machine Interfacing system for ScanImage
Some simple code to run optical Brain Machine Interfacing experiments through ScanImage and Matlab.
Email me if you'd like to learn how to use it. I'm happy to help: RHakim@g.harvard.edu

Requirements:
- Matlab 2016a or later
- A microscope running a version of ScanImage that includes ROI integration
- A NI-DAQ system with some free inputs and outputs

Optional (currently configured for, but totally not necessary):
- A Teensy/Arduino used for real-time auditory feedback
- Some LEDs hooked up to an LED driver
- WaveSurfer for collecting behavioral data (licking, accelerometer, frame triggers, etc.)
- On your computer: A decent CPU, SSD, 32+GB of RAM. Used for the baseline calculations and simulations for determining the threshold to use.

How to use:
- Put all the files in Matlab's path
- Use the integration manager to make some ROIs
- Put the BMI_trial function in the output function of the Integration window
- Set experiment parameters in the BMI_trial function
- That's it! There are some extra functions here that allow for increased functionality, but the above is all that's required to get started.

I built this system to be modular and readable, so it should be a good base for people starting from scratch. That said it isn't perfect, and here are some imperfections:
- The feedback code is pretty quick but could be quicker; I get feedback within 40ms of a frame.
- It currently uses ScanImage's 'integration' feature to get ROI values, which makes life easy, but also results in slow-downs if you increase your resolution too much. I am currently doing 1024 x 512 with no issues.
- The 'Ensemble Selection' code could be quicker. It takes about 10 minutes to import, analyze, and calculate a threshold for a 15 minute baseline.
- The Ensemble Selection phase is pretty tough, user wise. This one is a bit difficult to explain, but basically you need to train yourself through the steps necessary to select ROIs, upload those ROIs to ScanImage, run those ROIs through the simulator, and then put the relevant values into the online BMI code. It usually takes about 10 minutes from the end of the baseline period to the beginning of the experiment.
- No drift/movement correction. I haven't gotten ScanImage's movement correction working, and I haven't implemented anything myself. Seems fine though.

What I would love some help with:
- If someone wants to help implement Suite 2p or CNMF or something to do a better job at ROI finding, that would be amazing. It's just a bit far down on my to do this right now, and manual ROI selection over a fano-factor image has worked fine.
- Implementing a running/rolling percentile calculation. This is the slowest step in the feedback (and simulation). It is used to calculate the dF/F at any given time point based on the last minute or so of data. I think there is a nice solution using heap structures in Matlab, I just haven't dug into it yet.
