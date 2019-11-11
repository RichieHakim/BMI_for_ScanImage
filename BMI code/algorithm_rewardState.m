function rewardState = algorithm_rewardState(thresholdState , threshold_duration , runningThresholdState, runningRewards, minRewardInterval, baselineHoldState)
rewardState = 0;
if thresholdState == 1
    if isequal( runningThresholdState(end-threshold_duration + 1: end)  ,  ones(1, threshold_duration) ) % has runningThresholdState been 1 for threshold_duration number of frames?
        if numel(runningRewards) > minRewardInterval % have we been acquiring for at least longer than the minimum reward interval?
            if isequal( runningRewards(end-minRewardInterval + 1 : end) , zeros(1, minRewardInterval)) % have we received a reward in the last minimum reward interval?
                if baselineHoldState == 1; % has the animal stayed within baseline for some fraction of the last few seconds?
                    rewardState = 1;
                end
            end
        end
    end
end