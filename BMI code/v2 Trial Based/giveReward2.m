function giveReward2(solenoid_duration_in_ms, LED_duration_in_sec, LED_ramping_pref, LED_ramping_duration_in_sec)
global sesh_reward

% solenoid_duration_in_ms = 50;
% LED_duration_in_sec = 1;
% LED_ramping_pref = 1;
% LED_ramping_duration_in_sec = 0.1;

traceDuration = max([solenoid_duration_in_ms/1000 , LED_duration_in_sec]) * sesh_reward.Rate;

outputTrace_LED = ones(traceDuration,1);
trace_LED_temp = makeLEDoutputPWMTrace(LED_duration_in_sec, LED_ramping_pref, LED_ramping_duration_in_sec);
outputTrace_LED(1:numel(trace_LED_temp)) = trace_LED_temp;

outputTrace_solenoid = zeros(traceDuration,1);
trace_solenoid_temp = zeros(round(solenoid_duration_in_ms/1000 * sesh_reward.Rate * 1.1),1); % make more zeros than there will be ones
trace_solenoid_temp(2:round(solenoid_duration_in_ms/1000 * sesh_reward.Rate) + 1) = 1; % make a bunch of ones, the length of 
outputTrace_solenoid(1:numel(trace_solenoid_temp)) = trace_solenoid_temp;

outputTrace_5VForLickDetection = ones(traceDuration,1); % constant output for lick detection

queueOutputData(sesh_reward, [ outputTrace_solenoid     outputTrace_5VForLickDetection   outputTrace_LED ]); % [ (reward solenoid) (lick detection voltage)]

listener_in = addlistener(sesh_reward,'DataAvailable',@(sesh,event)nullFunction); % check my old function liveTF for how to use this type of function. Here it is necessary to use because we have an analog channel (being used purely as a clock for the digital output channel). This requires a listener for some reason.

startBackground(sesh_reward);

end