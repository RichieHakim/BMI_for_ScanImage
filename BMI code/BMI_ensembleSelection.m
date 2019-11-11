%% BMI Ensemble selection script
% function best_decoder_value = BMI_ensembleSelection(directory)
%% import baseline movie
tic
% movie = bigread4('F:\RH_Local\Rich data\scanimage data\20191109\mouse 10.13A\baseline_00003.tif');
movie = bigread2('F:\RH_Local\Rich data\scanimage data\baseline_00002.tif',1,500);
% movie = bigread4(directory);
toc
%%
Fs_frameRate = 30; % in Hz
duration_trace = size(movie,3) / Fs_frameRate;
duration_trial = 30; % in seconds
baseline_pctile = 20;

%%
tic
chunk_size = 25; % number of columns to process at once. vary this value to maximize speed. There is a sweet spot for memory usage around 25 columns of size 512 each.
movie_std = nan(size(movie,1), size(movie,2));
for ii = 1:chunk_size:size(movie,2)
    if ii + chunk_size > size(movie,2)
        movie_std(:,ii:size(movie,2)) = std(single(movie(:,ii:size(movie,2),:)),[],3);
    else
        movie_std(:,ii:ii+chunk_size) = std(single(movie(:,ii:ii+chunk_size,:)),[],3);
    end
end
toc
%%
movie_mean = mean(movie,3);

h1 = figure;
imagesc(movie_mean)
set(gca,'CLim',[0 1e4])


h1 = figure;
ax1 = subplot(7,1,1:3);
imagesc(movie_mean)
set(h1,'Position',[100 20 900 1800]);

h2 = figure;
ax1 = subplot(7,1,1:3);

% imagesc(log(mean(movie,3)))
% imagesc((mean(movie,3)))
% figure;
% imagesc(movie_std)
imagesc(movie_std ./ movie_mean)
set(ax1,'CLim',[0.2 1])
set(h2,'Position',[100 20 900 1800]);

% ROI selection

cmap = distinguishable_colors(50,['b']);

pref_addROI = 1;
cc = 1;
clear mask userShape mask_position ROI_coords
clear F_roi dFoF_roi

while pref_addROI == 1
    set(h2,'CurrentAxes',ax1);
    userShape{cc} = imrect;
    
    mask{cc} = userShape{cc}.createMask;
    mask_position{cc} = userShape{cc}.getPosition; % first two values are x and y of top left corner (assuming ROI made by dragging top left corner first), second two values are dX and dY
    ROI_coords{cc} = round([mask_position{cc}(1) , mask_position{cc}(1) + mask_position{cc}(3) , mask_position{cc}(2) , mask_position{cc}(2) + mask_position{cc}(4)]); % x1, x2 , y1, y2
    
    %% ROI extraction and dFoF calculation
    baselineWin = 90 * Fs_frameRate;
    F_roi(:,cc) = squeeze( mean( mean( movie([ROI_coords{cc}(3):ROI_coords{cc}(4)], [ROI_coords{cc}(1):ROI_coords{cc}(2)], : ) ,1) ,2) );
    dFoF_roi(:,cc) = (F_roi(:,cc) - medfilt1(F_roi(:,cc), baselineWin)) ./  medfilt1(F_roi(:,cc), baselineWin);
    numTraces = size(F_roi,2);
    
    %% plotting
    ROI_patchX = [ROI_coords{cc}(1) , ROI_coords{cc}(2) , ROI_coords{cc}(2) , ROI_coords{cc}(1)];
    ROI_patchY = [ROI_coords{cc}(3) , ROI_coords{cc}(3) , ROI_coords{cc}(4) , ROI_coords{cc}(4)];
    patch(ROI_patchX, ROI_patchY,cmap(cc,:),'EdgeColor',cmap(cc,:),'FaceColor','none','LineWidth',2);
    
    ax2 = subplot(7,1,4:5); hold on
    plot((1:size(movie,3)) / Fs_frameRate, F_roi(:,cc),'Color',cmap(cc,:))
    
    ax3 = subplot(7,1,6:7); hold on
    plot((1:size(movie,3)) / Fs_frameRate,dFoF_roi(:,cc),'Color',cmap(cc,:))
    
    clear figLegend
    for ii = 1:numTraces
        figLegend{ii} = num2str(ii);
    end
    legend(figLegend);
    
    cc = cc+1;
    userInput = input('Drag ROI from top left corner. Afterwards, press ENTER to add another ROI, or enter ANY NUMBER to process ROIs:    ');
    if numel(userInput) > 0
        pref_addROI = 0;
    end
    
end
%% Decoder algorithm & Threshold grid search

traces_to_use_E1 = input('Input numbers for E1 trace to use:  ');
% scaler_E1 = input('Input scale factors for E1:  ');
scaler_E1 = 1./std(dFoF_roi(:,traces_to_use_E1));

E1 = mean(dFoF_roi(:,traces_to_use_E1) .* repmat(scaler_E1, size(dFoF_roi,1),1) , 2); % trace to use for Ensemble 1

traces_to_use_E2 = input('Input numbers for E2 trace to use:  ');
% scaler_E2 = input('Input scale factors for E2:  ');
scaler_E2 = 1./std(dFoF_roi(:,traces_to_use_E2));

E2 = mean(dFoF_roi(:,traces_to_use_E2) .* repmat(scaler_E2, size(dFoF_roi,1),1) , 2); % trace to use for Ensemble 1


cursor = E1-E2; % This is the decoder algorithm

% the idea here is to move a threshold across the decoder trace and see in
% what percentage of trials a threshold crossing occurs.
% To smooth out the result, I am iterating this over different 'phases' of
% trials so that large events can be shared across adjacent trials

TC_goal = 0.3;

framesPerTrial = round(duration_trial * Fs_frameRate);
trialsInTrace = floor(numel(cursor) / framesPerTrial);
% %%
% % reshape the cursor trace into trials
% clear cursor_chopped
% for ii = (1:framesPerTrial)-1
%     cursor_crop = cursor((1 : (trialsInTrace-1)*framesPerTrial) + ii); % notice the -1. this is needed because we slide the window for each trial forward in time
%     cursor_chopped(:,:,ii+1) = reshape(cursor_crop,framesPerTrial, trialsInTrace - 1)'; % dim 1: trial num, dim 2: time, dim 3: time shift of trial
% end
% cursor_chopped_maxValsPerTrial = squeeze(max(cursor_chopped,[],2));
% cursor_chopped_minValsPerTrial = squeeze(min(cursor_chopped,[],2));
% 
% % determine what percentage of trials result in a threshold crossing
% threshold_search_space = min(cursor): 0.01 : max(cursor);
% clear thresh_crossings TC_prob thresh_crossings_inverse TC_inverse_prob
% for ii = 1:numel(threshold_search_space)
%     thresh_crossings(:,:,ii) = cursor_chopped_maxValsPerTrial > threshold_search_space(ii);
%     TC_prob(ii) = mean(mean(thresh_crossings(:,:,ii),1),2);
%     
%     thresh_crossings_inverse(:,:,ii) = cursor_chopped_minValsPerTrial < threshold_search_space(ii);
%     TC_inverse_prob(ii) = mean(mean(thresh_crossings_inverse(:,:,ii),1),2);
% end
%%
baselineHoldTime = 3;
baselineThreshold = 0.15;
baselineHoldFraction = .5;
minRewardInterval = 5;

threshold_search_space = 0: 0.01 : max(cursor);
clear thresh_crossings TC_prob thresh_crossings_inverse TC_inverse_prob
for ii = 1:numel(threshold_search_space)
    thresh_crossings(:,ii) = cursor > threshold_search_space(ii);
%     thresh_crossings_inverse(:,ii) = -cursor > threshold_search_space(ii);
    for jj = 1:size(cursor,1)
        if thresh_crossings(jj,ii)==1 && jj > 30*(baselineHoldTime+1) && jj > 30*(minRewardInterval+1)
            if mean(cursor(jj-30*baselineHoldTime:jj) < baselineThreshold * threshold_search_space(ii)) < baselineHoldFraction
                thresh_crossings(jj,ii) = 0;
            end
            if sum(cursor(jj-30*minRewardInterval:jj) > threshold_search_space(ii)) > 1
                thresh_crossings(jj,ii) = 0;
            end
            
        end
        
%         if thresh_crossings_inverse(jj,ii)==1 && jj > 30*6
%             if mean(cursor(jj-30*5:jj) < 0.1 * threshold_search_space(ii)) < 0.5
%                 thresh_crossings_inverse(jj,ii) = 0;
%             end
%             if sum(cursor(jj-30*5:jj) > threshold_search_space(ii)) > 1
%                 thresh_crossings_inverse(jj,ii) = 0;
%             end
%             
%         end
    end
end
axis_time = (1:numel(cursor)) / (Fs_frameRate);
% figure; imagesc(threshold_search_space, axis_time, thresh_crossings)
rewards_total = sum(thresh_crossings);
% figure; plot(threshold_search_space,rewards_total)

step_size = round(size(thresh_crossings,1)/trialsInTrace);
clear thresh_crossings_chopped trialHitRate

for jj = 1:size(thresh_crossings,2)
    thresh_crossings_chopped(:,jj) = movsum(thresh_crossings(:,jj), framesPerTrial) > 1;
    for ii = 1:framesPerTrial
        trialHitRate(ii,jj) = mean(thresh_crossings_chopped(jj:step_size:end));
    end
end
    TC_prob = mean(trialHitRate,1);

best_decoder_value = max(threshold_search_space(find(TC_prob > TC_goal)));

figure; plot(threshold_search_space,TC_prob)



% thresh_crossings_crop = thresh_crossings((1 : (trialsInTrace-1)*framesPerTrial) + ii); % notice the -1. this is needed because we slide the window for each trial forward in time
% thresh_crossings_chopped(:,:,ii+1) = reshape(thresh_crossings_crop, framesPerTrial, trialsInTrace - 1)'; % dim 1: trial num, dim 2: time, dim 3: time shift of trial


%%
% best_decoder_value = mean(threshold_search_space(find(abs(TC_prob - TC_goal) == min(abs(TC_prob - TC_goal))))); % find the x value that gives TC_goal
% best_decoder_inverse_value = mean(threshold_search_space(find(abs(TC_inverse_prob - TC_goal) == min(abs(TC_inverse_prob - TC_goal)))));


h3 = figure; hold on

% set(0,'CurrentFigure',h3);
ax4 = subplot(2,1,2); hold on
plot(cursor,'LineWidth',2)
plot(E1)
plot(E2)

ax5 = subplot(2,1,1); hold on

plot(threshold_search_space, TC_prob,'LineWidth',2)
% plot(threshold_search_space, TC_inverse_prob,'LineWidth',2)

plot([best_decoder_value best_decoder_value] , [0 max(TC_prob)], 'Color', [0.6 0.6 0.6])
% plot([best_decoder_inverse_value best_decoder_inverse_value] , [0 1], 'Color', [0.6 0.6 0.6])

xlabel('decoder value')
ylabel('probability of threshold crossing during trial')
legend('positive threshold', 'best decoder value')


best_decoder_value
scaler_E1
scaler_E2

% end

