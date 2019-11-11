function [rewardState , cursor, baselineState, baselineHoldState, thresholdState] = program_simpleBMI_forSimulation(vals,threshold_value, scale_factors, varargin)
persistent  runningVals runningVals_smooth length_runningVals runningRewards length_runningRewards runningThresholdState runningCursor runningBaselineState

% ROI vars
frameRate = 30;
duration_plotting = 30 * frameRate; % ADJUSTABLE: change number value (in seconds)
win_smooth = 3; % smoothing window (in frames)
F_baseline_prctile = 20; % percentile to define as F_baseline of cells
% scale_factors = [6.0260    8.4324   8.4734    6.2810];
ensemble_assignments = [1 1 2 2];

duration_history = 30*60*3; % in frames

minBaselineHold = 3*frameRate;
fractionOfTimeAtBaselineDuringHold = 0.5;
baselineCursorThreshold = 0.15; % fraction of 'threshold_value' that cursor has to get BELOW in order to be considered baselien

% reward vars
minRewardInterval = 5 * frameRate;
% threshold_value =   1.800;
threshold_duration = 1; % number of frames threshold must be crossed to enter reward state

% range_cursorSound = [-1 1.13];
% range_freqOutput = [1000 20000]; % this is set in the teensy code (Ofer made it)

% %%
% resetRunningRewards % YOU MUST COMMENT THIS OUT IN ORDER TO ACCUMULATE REWARDS
% saveParams('F:\RH_Local\Rich data\scanimage data\20191109\mouse 10.13A\params.mat')


%%
% clear  runningVals runningVals_smooth length_runningVals runningRewards length_runningRewards runningThresholdState runningCursor runningBaselineState
% clear  runningVals runningVals_smooth length_runningVals runningRewards length_runningRewards runningThresholdState runningCursor runningBaselineState

if numel(length_runningVals) < 1 % if just starting this code, then initialize running values
    runningVals = [];
    runningVals_smooth(1,:) = vals;
end

runningVals(size(runningVals,1) + 1,:) = vals; % make the bottom values of the matrix the newest values

if size(runningVals,1) > win_smooth
    runningVals_smooth(size(runningVals_smooth,1) + 1,:) = mean(runningVals(end-win_smooth:end,:),1); % smooth using a mean of past few values
end

if size(runningVals,1) > duration_history % once there are more values than length_history, delete the first ones
    runningVals(1:end-duration_history,:) = [];
    runningVals_smooth(1:end-duration_history,:) = [];
end
length_runningVals = size(runningVals,1);

F_baseline = prctile(runningVals, F_baseline_prctile);
dF = runningVals_smooth(end,:) - F_baseline;
dFoF = dF ./ F_baseline;
% vals_zscore = zscore(runningVals);
% vals_zscore = vals_zscore(end,:);

cursor = algorithm_decoder(dFoF, scale_factors, ensemble_assignments);



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
% runningNumOfRewards

runningRewards(numel(runningRewards) + 1) = rewardState;
runningThresholdState(numel(runningThresholdState) + 1) = thresholdState;
runningBaselineState(numel(runningBaselineState) + 1) = baselineState;

if numel(runningRewards) > duration_history
    runningRewards(1:end-duration_history) = [];
end
length_runningRewards = numel(runningRewards);

if numel(runningThresholdState) > duration_history
    runningThresholdState(1:end-duration_history) = [];
end

if numel(runningBaselineState) > minBaselineHold
    runningBaselineState(1:end-minBaselineHold) = [];
end

end