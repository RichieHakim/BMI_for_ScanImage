cellNumsToUse = [1 2 3 4];
scale_factors = 1./std(dFoF_roi(:,cellNumsToUse));

sample_rate = 30;
duration_total = size(F_roi,1)/sample_rate;
clear total_rewards all_rewards all_cursor baselineState baselineHoldState thresholdState
threshVals = [0 .5 1 1.5 2];
cc = 1;
for ii = threshVals
    tic
    for jj = 1:size(F_roi,1)
    [all_rewards(jj,1), all_cursor(jj,1), baselineState(jj,1), baselineHoldState(jj,1), thresholdState(jj,1)] = program_simpleBMI_forSimulation(F_roi(jj,cellNumsToUse), ii, scale_factors);
        end
    ii
    total_rewards_per30s(cc) = sum(all_rewards)/(duration_total/30);
    figure; plot([all_rewards.*1.5, all_cursor, baselineState.*1.1, baselineHoldState*0.8, thresholdState.*0.6])
    toc
    cc = cc+1;
end
figure;
plot(threshVals, total_rewards)