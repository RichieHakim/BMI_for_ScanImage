%% BMI Ensemble selection script
% function best_decoder_value = BMI_ensembleSelection(directory)
%% import baseline movie
directory = 'F:\RH_Local\Rich data\scanimage data\test';
file_baseName = 'baseline_00001_';

frames_totalExpected = 27000;
frames_perFile = 1000;

lastImportedFileIdx = 0;
% clear movie_all

scanAngleMultiplier = [1.7, 1.1];
pixelsPerDegree = [26.2463 , 31.3449] .* scanAngleMultiplier;

filesExpected = ceil(frames_totalExpected/frames_perFile);

ImportWarning_Waiting_Shown = 0;
ImportWarning_OpenAccess_Shown = 0;
while lastImportedFileIdx < filesExpected
    if ImportWarning_Waiting_Shown == 0
        disp('Looking for files to import')
        ImportWarning_Waiting_Shown = 1;
    end
    
    dirProps = dir([directory , '\', file_baseName, '*.tif']);
    
    if size(dirProps,1) > 0
        fileNames = str2mat(dirProps.name);
        fileNames_temp = fileNames;
        fileNames_temp(:,[1:numel(file_baseName), end-3:end]) = [];
        fileNums = str2num(fileNames_temp);
        
        if size(fileNames,1) > lastImportedFileIdx
            if fopen([directory, '\', fileNames(lastImportedFileIdx+1,:)]) ~= -1
                
                disp(['===== Importing:    ', fileNames(lastImportedFileIdx+1,:), '====='])
                movie_chunk = bigread4([directory, '\', fileNames(lastImportedFileIdx+1,:)]);
                
                if ~exist('movie_all')
                    movie_all = movie_chunk;
                else
                    movie_all = cat(3, movie_all, movie_chunk);
                end
                
                disp(['Completed import'])
                lastImportedFileIdx = lastImportedFileIdx + 1;
                ImportWarning_Waiting_Shown = 0;
                ImportWarning_OpenAccess_Shown = 0;
                
            else if ImportWarning_OpenAccess_Shown == 0
                    disp('New file found, waiting for access to file')
                    ImportWarning_OpenAccess_Shown = 1;
                end
            end
        end
    end
end
%%
Fs_frameRate = 30; % in Hz
duration_trace = size(movie_all,3) / Fs_frameRate;
duration_trial = 30; % in seconds
baseline_pctile = 20;
%% Make Standard Deviation Image
tic
chunk_size = 25; % number of columns to process at once. vary this value to maximize speed. There is a sweet spot for memory usage around 25 columns of size 512 each.
movie_std = nan(size(movie_all,1), size(movie_all,2));
for ii = 1:chunk_size:size(movie_all,2)
    if ii + chunk_size > size(movie_all,2)
        movie_std(:,ii:size(movie_all,2)) = std(single(movie_all(:,ii:size(movie_all,2),:)),[],3);
    else
        movie_std(:,ii:ii+chunk_size) = std(single(movie_all(:,ii:ii+chunk_size,:)),[],3);
    end
end
toc
%%
movie_mean = mean(movie_all,3);
movie_fano = movie_std ./ movie_mean;
%
% h1 = figure;
% imagesc(movie_mean)
% set(gca,'CLim',[0 1e4])

h1 = figure;
imagesc(movie_mean)

h2 = figure;
ax2 = subplot(1,1,1);
imagesc(movie_fano)
set(ax2, 'CLim',[0.1 .8]);

h3 = figure;
ax3 = subplot(2,1,1);
ax4 = subplot(2,1,2);
% set(h3,'Position',[100 20 900 1800]);

% ROI selection
cmap = distinguishable_colors(50,['b']);
pref_addROI = 1;
makeNewROI = 1;
cc = 1;

clear mask userShape mask_position ROI_coords F_roi dFoF_roi
while pref_addROI == 1
    %     set(h2,'CurrentAxes',ax2);
    axes(ax2)
    if makeNewROI == 1
        userShape{cc} = imrect;
        
        mask{cc} = userShape{cc}.createMask;
        mask_position{cc} = userShape{cc}.getPosition; % first two values are x and y of top left corner (assuming ROI made by dragging top left corner first), second two values are dX and dY
        ROI_coords{cc} = round([mask_position{cc}(1) , mask_position{cc}(1) + mask_position{cc}(3) , mask_position{cc}(2) , mask_position{cc}(2) + mask_position{cc}(4)]); % x1, x2 , y1, y2
        
        %% ROI extraction and dFoF calculation
        baselineWin = 90 * Fs_frameRate;
        F_roi(:,cc) = squeeze( mean( mean( movie_all([ROI_coords{cc}(3):ROI_coords{cc}(4)], [ROI_coords{cc}(1):ROI_coords{cc}(2)], : ) ,1) ,2) );
        dFoF_roi(:,cc) = (F_roi(:,cc) - medfilt1(F_roi(:,cc), baselineWin)) ./  medfilt1(F_roi(:,cc), baselineWin);
        numTraces = size(F_roi,2);
        
        %% plotting
        ROI_patchX = [ROI_coords{cc}(1) , ROI_coords{cc}(2) , ROI_coords{cc}(2) , ROI_coords{cc}(1)];
        ROI_patchY = [ROI_coords{cc}(3) , ROI_coords{cc}(3) , ROI_coords{cc}(4) , ROI_coords{cc}(4)];
        patch(ROI_patchX, ROI_patchY,cmap(cc,:),'EdgeColor',cmap(cc,:),'FaceColor','none','LineWidth',2);
        
        axes(ax3); hold on
        plot((1:size(movie_all,3)) / Fs_frameRate, F_roi(:,cc),'Color',cmap(cc,:))
        
        axes(ax4); hold on
        plot((1:size(movie_all,3)) / Fs_frameRate,dFoF_roi(:,cc),'Color',cmap(cc,:))
        %     plot((1:size(movie_all,3)) / Fs_frameRate, smooth(dFoF_roi(:,cc),15,'sgolay'),'Color',cmap(cc,:))
        
        clear figLegend
        for ii = 1:numTraces
            figLegend{ii} = num2str(ii);
        end
        legend(figLegend);
        
        cc = cc+1;
        makeNewROI = 0;
    end
    button = waitforbuttonpress;
    if button == 1
        keyPressOutput = get(gcf,'CurrentKey');
        if strcmp(keyPressOutput, 'return') == 1
            pref_addROI = 0;
        end
        
        if strcmp(keyPressOutput, 'space') ~= 0
            makeNewROI = 1;
        else makeNewROI = 0;
        end
    end
end

%% Update ROIs
figure; hold on;
clear F_roi_new dFoF_roi_new
for cc = 1:size(F_roi,2)
    F_roi_new(:,cc) = squeeze( mean( mean( movie_all([ROI_coords{cc}(3):ROI_coords{cc}(4)], [ROI_coords{cc}(1):ROI_coords{cc}(2)], : ) ,1) ,2) );
    dFoF_roi_new(:,cc) = (F_roi(:,cc) - medfilt1(F_roi(:,cc), baselineWin)) ./  medfilt1(F_roi(:,cc), baselineWin);
    plot((1:size(dFoF_roi,1)) / Fs_frameRate,dFoF_roi(:,cc),'Color',cmap(cc,:))
end
F_roi = F_roi_new; dFoF_roi = dFoF_roi_new;

%% Choose cells
traces_to_use_E1 = input('Input numbers for E1 trace to use:  ');
traces_to_use_E2 = input('Input numbers for E2 trace to use:  ');
cellNumsToUse = [traces_to_use_E1 , traces_to_use_E2];

%% Transofrm coordinates for ScanImage integration
% mask_position{cc} = userShape{cc}.getPosition; % first two values are x and y of top left corner (assuming ROI made by dragging top left corner first), second two values are dX and dY

clear mask_center mask_width
for ii = 1:numel(mask_position)
    mask_centerX_temp = mask_position{ii}(1) + mask_position{ii}(3)/2;
    mask_centerY_temp = mask_position{ii}(2) + mask_position{ii}(4)/2;
    
    mask_center(ii,:) = [mask_centerX_temp , mask_centerY_temp];
    mask_width(ii,:) = [mask_position{ii}(3) , mask_position{ii}(4)];
end
mask_center_cellsToUse = mask_center(cellNumsToUse,:);
mask_width_cellsToUse = mask_width(cellNumsToUse,:);

image_center = [size(movie_all,2) , size(movie_all,1)]/2;
mask_center_SI_angle = (mask_center - repmat(image_center, size(mask_center,1), 1)) ./ repmat(pixelsPerDegree, size(mask_center,1), 1);
mask_center_SI_angle_cellsToUse = mask_center_SI_angle(cellNumsToUse,:);

mask_width_SI_angle = mask_width ./ repmat(pixelsPerDegree, size(mask_width,1), 1);
mask_width_SI_angle_cellsToUse = mask_width_SI_angle(cellNumsToUse,:);

%% Simulation
figure; plot(logger_output(:,28), 'LineWidth', 1.5)

% threshVals = [0 2.4:.1:2.5];
threshVals = [2.65];

scale_factors = 1./std(dFoF_roi(:,cellNumsToUse));

duration_total = size(F_roi,1);
clear total_rewards_per30s logger_output
cc = 1;
for ii = threshVals
    tic
    disp(['testing threshold value:  ', num2str(ii)])

    for jj = 1:size(F_roi,1)
    if jj == 1
        startSession_pref = 1;
    else
        startSession_pref = 0;
    end
    
    [logger_output(jj,:)] = program_trialBMI_simulation(F_roi(jj,cellNumsToUse),startSession_pref, scale_factors, ii, duration_total);
    end
%     total_rewards_per30s(cc) = sum(all_rewards)/(duration_total/30);
%     disp(['total rewards per 30s at threshold = ' , num2str(ii) , ' is:   ', num2str(total_rewards_per30s(cc))]);
%     figure; plot([all_rewards.*1.5, all_cursor, baselineState.*1.1, baselineHoldState*0.8, thresholdState.*0.6])
    toc
    cc = cc+1;
end
% figure;
% plot(threshVals, total_rewards_per30s)
% figure; plot(logger_output(:,33:36) .* repmat(scale_factors,size(logger_output,1),1))
hold on; plot([0 size(logger_output,1)] , [threshVals(end) threshVals(end)])
rewardToneHold_diff = diff(logger_output(:,9));
timeout_diff = diff(logger_output(:,23));
numRewards = sum(rewardToneHold_diff(rewardToneHold_diff > 0.5))
numTimeouts = sum(timeout_diff(timeout_diff > 0.5))
numRewards/(numRewards+numTimeouts)

%%
baselineStuff.threshVals = threshVals;
baselineStuff.total_rewards_per30s = total_rewards_per30s;
baselineStuff.movie_std = movie_std;
baselineStuff.movie_fano = movie_fano;

baselineStuff.movie_mean = movie_mean;
baselineStuff.traces_to_use_E1 = traces_to_use_E1;
baselineStuff.traces_to_use_E2 = traces_to_use_E2;
baselineStuff.F_roi = F_roi;
baselineStuff.dFoF_roi = dFoF_roi;
baselineStuff.cellNumsToUse = cellNumsToUse;
baselineStuff.mask_center = mask_center;
baselineStuff.mask_width = mask_width;
baselineStuff.mask_center_cellsToUse = mask_center_cellsToUse;
baselineStuff.mask_width_cellsToUse = mask_width_cellsToUse;
baselineStuff.image_center = image_center;
baselineStuff.mask_center_SI_angle = mask_center_SI_angle;
baselineStuff.mask_center_SI_angle_cellsToUse = mask_center_SI_angle_cellsToUse;
baselineStuff.directory = directory;
baselineStuff.file_baseName = file_baseName;
baselineStuff.frames_totalExpected = frames_totalExpected;
baselineStuff.frames_perFile = frames_perFile;
baselineStuff.scanAngleMultiplier = scanAngleMultiplier;
baselineStuff.pixelsPerDegree = pixelsPerDegree;
baselineStuff.Fs_frameRate = Fs_frameRate;
baselineStuff.duration_trace = duration_trace;
baselineStuff.duration_trial = duration_trial;
baselineStuff.baseline_pctile = baseline_pctile;
baselineStuff.scale_factors = scale_factors;

baselineStuff.ROI_patchX = ROI_patchX;
baselineStuff.ROI_patchY = ROI_patchY;
baselineStuff.mask_width_SI_angle = mask_width_SI_angle;
baselineStuff.mask_width_SI_angle_cellsToUse = mask_width_SI_angle_cellsToUse;

save([directory, '\EnsembleSelectionWorkspace'], 'baselineStuff')
