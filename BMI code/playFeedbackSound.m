function playFeedbackSound(val , range_ROIInput , range_freqOutput)
% val
if val < min(range_ROIInput)
    val = min(range_ROIInput);
end
if val > max(range_ROIInput)
    val = max(range_ROIInput);
end

value_norm = (val-min(range_ROIInput)) / (max(range_ROIInput) - min(range_ROIInput)); % this is how far between the min and max of the range the value is as a fraction

maxFreq = range_ROIInput(end);

frameRate = 30; % imaging frame rate (Hz)

freq_toUse = (  (1 - value_norm) * min(range_freqOutput) )  +   (  (value_norm) * max(range_freqOutput)  );

stretchFactor = 1.1;

num_periods = floor( ((1/frameRate) * freq_toUse) * stretchFactor );

% Fs_sound = 100000;
Fs_sound = 5000;

num_samples = floor((Fs_sound / frameRate) * stretchFactor);

soft_window = ones(1,num_samples);
soft_rampSize = round(numel(soft_window)/20);
soft_window(1:soft_rampSize) = 1/soft_rampSize : 1/soft_rampSize : 1;
soft_window(end-soft_rampSize+1:end) = fliplr(1/soft_rampSize : 1/soft_rampSize : 1);

xBasis = (1/num_samples: 1/num_samples : 1) * 2*pi * num_periods;

sineWave = sin(xBasis);
sineWave_soft = sineWave .* soft_window;
% figure; plot(sineWave_soft);

% sound(sineWave_soft , Fs_sound,8)
% sound(sineWave_soft , 200000,8)

% global sesh_sound
% outputSingleScan(sesh_sound, [ val ])


end