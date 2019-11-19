%% reward stuff
clear sesh_reward Channel_solenoid Channel_LEDAmplitudeModulation
global sesh_reward
sesh_reward = daq.createSession('ni');
sesh_reward.Rate = 100000;
% Channel_solenoid = addDigitalChannel(sesh, 'PXI1Slot6', 'Port0/Line1', 'OutputOnly');
% addAnalogInputChannel(sesh, 'PXI1Slot6',0,'Voltage'); % this channel is being used only to give a clock to the session. Nothing is being collected on it.
Channel_solenoid = addDigitalChannel(sesh_reward, 'PXI1Slot5', 'Port0/Line1', 'OutputOnly');
Channel_5VoutputForLickDetection = addDigitalChannel(sesh_reward, 'PXI1Slot5', 'Port0/Line2', 'OutputOnly');
Channel_LEDAmplitudeModulation = addDigitalChannel(sesh_reward, 'PXI1Slot5', 'Port0/Line3', 'OutputOnly');
addAnalogInputChannel(sesh_reward, 'PXI1Slot5',0,'Voltage'); % this channel is being used only to give a clock to the session. Nothing is being collected on it.
% Channel_SoundAmplitudeModulation = addAnalogOutputChannel(sesh_reward, 'PXI1Slot5',1,'Voltage'); % this channel is being used only to give a clock to the session. Nothing is being collected on it.

outputSingleScan(sesh_reward, [ 0 1 1])

%% sound stuff
clear sesh_sound Channel_SoundAmplitudeModulation
global sesh_sound
sesh_sound = daq.createSession('ni');
sesh_sound.Rate = 100000;
Channel_SoundAmplitudeModulation = addAnalogOutputChannel(sesh_sound, 'PXI1Slot6',1,'Voltage'); 

outputSingleScan(sesh_sound, [ 0 ])

% test sound amplitude modulation
outputSingleScan(sesh_sound, [ 1 ])
pause(0.5)
outputSingleScan(sesh_sound, [ 2 ])
pause(0.5)
outputSingleScan(sesh_sound, [ 3.3 ])

% %% LED stuff
% 
% clear sesh_LED Channel_LEDAmplitudeModulation
% global sesh_LED
% sesh_LED = daq.createSession('ni');
% sesh_LED.Rate = 100000;
% addAnalogInputChannel(sesh_LED, 'PXI1Slot5',1,'Voltage'); % this channel is being used only to give a clock to the session. Nothing is being collected on it.
% % Channel_SoundAmplitudeModulation = addAnalogOutputChannel(sesh_reward, 'PXI1Slot5',1,'Voltage'); % this channel is being used only to give a clock to the session. Nothing is being collected on it.
% Channel_LEDAmplitudeModulation = addDigitalChannel(sesh_LED, 'PXI1Slot5', 'Port0/Line3', 'OutputOnly');
% 
% outputSingleScan(sesh_LED, [ 1 ])




