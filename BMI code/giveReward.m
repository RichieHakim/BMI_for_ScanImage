function giveReward(reward_duration_in_ms)
global sesh_reward

outputTrace = zeros(round(reward_duration_in_ms/1000 * sesh_reward.Rate * 1.1),1); % make more zeros than there will be ones
outputTrace(2:round(reward_duration_in_ms/1000 * sesh_reward.Rate) + 1) = 1; % make a bunch of ones, the length of 

outputOther = ones(size(outputTrace,1),1); % constant output for lick detection

queueOutputData(sesh_reward, [ outputTrace     outputOther ]); % [ (reward solenoid) (lick detection voltage)]

listener_in = addlistener(sesh_reward,'DataAvailable',@(sesh,event)nullFunction); % check my old function liveTF for how to use this type of function. Here it is necessary to use because we have an analog channel (being used purely as a clock for the digital output channel). This requires a listener for some reason.

startBackground(sesh_reward);

end