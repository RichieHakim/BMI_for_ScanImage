function baselineHoldState = algorithm_baselineHoldState(runningBaselineState, minBaselineHold, fractionOfTimeAtBaselineDuringHold)
% numel(runningBaselineState)
% numel(runningBaselineState) >= minBaselineHold
% sum(runningBaselineState(end-minBaselineHold + 1: end))   >   ones(1, minBaselineHold)*fractionOfTimeAtBaselineDuringHold
% sum(runningBaselineState(end-minBaselineHold + 1: end))
% sum(ones(1, minBaselineHold))*fractionOfTimeAtBaselineDuringHold
baselineHoldState = 0;
% numel(runningBaselineState)
% numel(runningBaselineState)>= minBaselineHold
if numel(runningBaselineState) >= minBaselineHold % have we been acquiring for at least longer than the minimum reward interval?
    if sum(runningBaselineState(end-minBaselineHold + 1: end))   >   sum(ones(1, minBaselineHold))*fractionOfTimeAtBaselineDuringHold  % has runningThresholdState been 1 for threshold_duration number of frames?
        baselineHoldState = 1;
    end
end
end