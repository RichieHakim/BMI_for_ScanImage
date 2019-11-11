function teensyOutput = program_simpleBMI(vals,varargin)
persistent  runningVals runningVals_smooth length_runningVals runningRewards length_runningRewards runningThresholdState runningCursor runningBaselineState
% global baselineStuff

% ROI vars
frameRate = 30;
duration_plotting = 30 * frameRate; % ADJUSTABLE: change number value (in seconds)
win_smooth = 3; % smoothing window (in frames)
F_baseline_prctile = 20; % percentile to define as F_baseline of cells
scale_factors = [6.93088166200986,5.85766320834125,4.90333714230996,7.79732599546290];
% scale_factors = baselineStuff.scale_factors;
ensemble_assignments = [1 1 2 2];

duration_trial = 30*60*3; % in frames

minBaselineHold = 3*frameRate;
fractionOfTimeAtBaselineDuringHold = 0.5;
baselineCursorThreshold = 0.15; % fraction of 'threshold_value' that cursor has to get BELOW in order to be considered baselien

% reward vars
minRewardInterval = 5 * frameRate;
threshold_value =   2.45;
threshold_duration = 1; % number of frames threshold must be crossed to enter reward state

range_cursorSound = [-threshold_value threshold_value];
range_freqOutput = [1000 20000]; % this is set in the teensy code (Ofer made it)

% %%
% resetRunningRewards % YOU MUST COMMENT THIS OUT IN ORDER TO ACCUMULATE REWARDS
% saveParams('F:\RH_Local\Rich data\scanimage data\20191110\mouse 10.13A\expParams.mat')
% saveParams(baselineStuff.directory)


%%
% clear  runningVals runningVals_smooth length_runningVals runningRewards length_runningRewards runningThresholdState runningCursor runningBaselineState
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

if size(runningVals,1) > duration_plotting % once there are more values than length_history, delete the first ones
    runningVals(1:end-duration_plotting,:) = [];
    runningVals_smooth(1:end-duration_plotting,:) = [];
end
length_runningVals = size(runningVals,1);

F_baseline = prctile(runningVals, F_baseline_prctile);
dF = runningVals_smooth(end,:) - F_baseline;
dFoF = dF ./ F_baseline;
vals_zscore = zscore(runningVals);
vals_zscore = vals_zscore(end,:);

cursor = algorithm_decoder(dFoF, scale_factors, ensemble_assignments);

runningCursor(size(runningCursor,1) + 1,:) = cursor; % make the bottom values of the matrix the newest values
if size(runningCursor,1) > duration_plotting % once there are more values than length_history, delete the first ones
    runningCursor(1:end-duration_plotting,:) = [];
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
NumOfRewardsAcquired = sum(runningRewards);
% runningNumOfRewards

runningRewards(numel(runningRewards) + 1) = rewardState;
runningThresholdState(numel(runningThresholdState) + 1) = thresholdState;
runningBaselineState(numel(runningBaselineState) + 1) = baselineState;

if numel(runningRewards) > duration_trial
    runningRewards(1:end-duration_trial) = [];
end
length_runningRewards = numel(runningRewards);

if numel(runningThresholdState) > duration_plotting
    runningThresholdState(1:end-duration_plotting) = [];
end

if numel(runningBaselineState) > minBaselineHold
    runningBaselineState(1:end-minBaselineHold) = [];
end
% 1
if rewardState == 1
    giveReward(50) % in ms
end

%%
plotUpdatedOutput([cursor , dFoF], duration_plotting, frameRate, 'Cursor , E1 , E2', 10, 20)
plotUpdatedOutput2([rewardState, baselineState] , duration_plotting, frameRate, 'Rewards', 10, 20, ['Num of Rewards:  ' , num2str(NumOfRewardsAcquired)])
%     plotUpdatedOutput3([vals_zscore], length_History, frameRate, 'zscore , E1 , E2', 10, 20)
%%
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

%% FUNCTIONS
    function resetRunningRewards
        runningRewards = 0;
    end

    function saveParams(directory)
        expParams.frameRate = frameRate;
        expParams.length_History = duration_trial;
        expParams.win_smooth = win_smooth;
        expParams.F_baseline_prctile = F_baseline_prctile;
        expParams.scale_factors = scale_factors;
        expParams.ensemble_assignments = ensemble_assignments;
        expParams.minBaselineHold = minBaselineHold;
        expParams.fractionOfTimeAtBaselineDuringHold = fractionOfTimeAtBaselineDuringHold;
        expParams.baselineCursorThreshold = baselineCursorThreshold;
        expParams.minRewardInterval = minRewardInterval;
        expParams.threshold_value = threshold_value;
        expParams.threshold_duration = threshold_duration;
        expParams.range_cursorSound = range_cursorSound;
        expParams.range_freqOutput = range_freqOutput;
        
        save(directory, 'expParams')
    end
end