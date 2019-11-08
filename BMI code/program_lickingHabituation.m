function teensyOutput = program_lickingHabituation(vals,varargin)

% ROI vars
frameRate = 30;
length_History = 300 * frameRate; % ADJUSTABLE: change number value (in seconds)
length_plot = 30 * frameRate; 
win_smooth = 1; % smoothing window (in frames)
F_baseline_prctile = 20; % percentile to define as F_baseline of cells
scale_factors = [1 1 1 1];
ensemble_assignments = [1 1 2 2];

baselineZScoreLimit = 1000;
minBaselineHold = 5*frameRate;
fractionOfTimeAtBaselineDuringHold = 0.5;
baselineCursorThreshold = 10; % fraction of 'threshold_value' that cursor has to get BELOW in order to be considered baselien

% reward vars
minRewardInterval = 30 * frameRate; %set lick frequency here
threshold_value = -1000;
threshold_duration = 1; % number of frames threshold must be crossed to enter reward state

% sound_thresh_min = -1.2390;
% sound_thresh_max = 1.2390;
% sound_freq_min = 3000;
% sound_freq_max = 80000;

clear  runningVals runningVals_smooth length_runningVals runningRewards length_runningRewards runningThresholdState runningCursor runningBaselineState
persistent  runningVals runningVals_smooth length_runningVals runningRewards length_runningRewards runningThresholdState runningCursor runningBaselineState
% clear  runningVals runningVals_smooth length_runningVals runningRewards length_runningRewards runningThresholdState runningCursor runningBaselineState

if numel(length_runningVals) < 1 % if just starting this code, then initialize running values
    runningVals = [];
    runningVals_smooth(1,:) = vals;
    runningCursor = [];
end

runningVals(size(runningVals,1) + 1,:) = vals; % make the bottom values of the matrix the newest values

if size(runningVals,1) > win_smooth
    runningVals_smooth(size(runningVals_smooth,1) + 1,:) = mean(runningVals(end-win_smooth:end,:),1); % smooth using a mean of past few values
end

if size(runningVals,1) > length_History % once there are more values than length_history, delete the first ones
    runningVals(1:end-length_History,:) = [];
    runningVals_smooth(1:end-length_History,:) = [];
end
length_runningVals = size(runningVals,1);

F_baseline = prctile(runningVals, F_baseline_prctile);
dF = runningVals_smooth(end,:) - F_baseline;
dFoF = dF ./ F_baseline;
vals_zscore = zscore(runningVals);
vals_zscore = vals_zscore(end,:);

cursor = algorithm_decoder(dFoF, scale_factors, ensemble_assignments);

runningCursor(size(runningCursor,1) + 1,:) = cursor; % make the bottom values of the matrix the newest values
if size(runningCursor,1) > length_History % once there are more values than length_history, delete the first ones
    runningCursor(1:end-length_History,:) = [];
end
% playFeedbackSound(cursor, [sound_thresh_min sound_thresh_max], [sound_freq_min sound_freq_max]); % (value, [min value , max value], [min Freq (Hz), max Freq (Hz)])


%% Reward stuff
if numel(length_runningRewards) < 1
    runningRewards = [0];
    runningThresholdState = [0];
    runningBaselineState = 0;
end

% baselineState = algorithm_baselineState(cursor, runningCursor, baselineZScoreLimit);
baselineState = algorithm_baselineState(cursor, baselineCursorThreshold);
baselineHoldState = algorithm_baselineHoldState(runningBaselineState, minBaselineHold, fractionOfTimeAtBaselineDuringHold);
thresholdState = algorithm_thresholdState(cursor, threshold_value);
rewardState = algorithm_rewardState(thresholdState , threshold_duration, runningThresholdState, runningRewards, minRewardInterval, baselineHoldState);
% rewardState

runningRewards(numel(runningRewards) + 1) = rewardState;
runningThresholdState(numel(runningThresholdState) + 1) = thresholdState;
runningBaselineState(numel(runningBaselineState) + 1) = baselineState;

if numel(runningRewards) > length_History
    runningRewards(1:end-length_History) = [];
end
length_runningRewards = numel(runningRewards);

if numel(runningThresholdState) > length_History
    runningThresholdState(1:end-length_History) = [];
end

if numel(runningBaselineState) > minBaselineHold
    runningBaselineState(1:end-minBaselineHold) = [];
end

if rewardState == 1
    giveReward(50) % in ms
end
 
%%
plotUpdatedOutput([cursor , dFoF], length_plot, frameRate, 'Cursor , E1 , E2', 10, 20)
plotUpdatedOutput2([rewardState, baselineState] , length_plot, frameRate, 'Rewards', 10, 20)
plotUpdatedOutput3([vals_zscore], length_plot, frameRate, 'zscore , E1 , E2', 10, 20)

%%

range_cursorSound = [0 10];
range_freqOutput = [1000 20000]; % this is set in the teensy code (Ofer made it)
range_teensyInputVoltage = [0 3.3]; % using a teensy 3.5 currently

freqToOutput = cursorToFrequency(cursor, range_cursorSound, range_freqOutput);
teensyOutput = teensyFrequencyToVoltageTransform(freqToOutput, range_freqOutput, range_teensyInputVoltage);

% HARD CODED CONSTRAINTS ON OUTPUT VOLTAGE FOR TEENSY 3.5
if teensyOutput > 3.3
    teensyOutput = 3.3;
    %     warning('CURSOR IS TRYING TO GO ABOVE 3.3V')
end
if teensyOutput < 0
    teensyOutput = 0;
    %     warning('CURSOR IS TRYING TO GO BELOW 0V')
end

end