%% reward stuff
clear sesh_reward Channel_solenoid
global sesh_reward
sesh_reward = daq.createSession('ni');
sesh_reward.Rate = 10000;
% Channel_solenoid = addDigitalChannel(sesh, 'PXI1Slot6', 'Port0/Line1', 'OutputOnly');
% addAnalogInputChannel(sesh, 'PXI1Slot6',0,'Voltage'); % this channel is being used only to give a clock to the session. Nothing is being collected on it.
Channel_solenoid = addDigitalChannel(sesh_reward, 'PXI1Slot5', 'Port0/Line1', 'OutputOnly');
Channel_5VoutputForLickDetection = addDigitalChannel(sesh_reward, 'PXI1Slot5', 'Port0/Line2', 'OutputOnly');
addAnalogInputChannel(sesh_reward, 'PXI1Slot5',0,'Voltage'); % this channel is being used only to give a clock to the session. Nothing is being collected on it.

outputSingleScan(sesh_reward, [ 0 1 ])

%% sound stuff
clear sesh_sound Channel_sound
global sesh_sound
sesh_sound = daq.createSession('ni');
sesh_sound.Rate = 100000;
addAnalogOutputChannel(sesh_sound, 'PXI1Slot6',0,'Voltage'); % this channel is being used only to give a clock to the session. Nothing is being collected on it.

outputSingleScan(sesh_sound, [ 0 ])
