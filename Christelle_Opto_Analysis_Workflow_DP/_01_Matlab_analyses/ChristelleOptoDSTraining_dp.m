%dp adapted from Christelle's code OptoDSTraining_0409.m

clear all
close all
clc

%% Figure options

savingDir= strcat(pwd,'\_output\_DS_task\');


%- establish criteria thresholds for plotting
criteriaPEratio= 0.6; %respond to DS 60% of the time
criteriaDiscrimIndex= 1.5; %respond to DS 30% more than NS

%% Import Data- update paths accordingly

% %--christelle opto data

%2023-06-28 reextracted data sheet row profile was missing ToneDur column, so fails
    %Prior code used the old "MasterOptoDSTrainingData" sheet so that
    %should work but data is outdated.
    
    % ToneDur is still in sheet, unlabeled as A(2) 
    % Should be able to use MSN info to determine ToneDur based on stage
    % Also, ToneDur is still in this sheet "F:\_Github\Richard Lab\data-vp-opto\_Excel_Sheets\VP-Opto_allSessions_FullExtract_Corrected.xlsx"
    % unlabeled as A(2)

%import behavioral data; dp reextracted data from data repo
[~,~,raw] = xlsread("F:\_Github\Richard Lab\data-vp-opto\_Excel_Sheets\_dp_reextracted\dp_reextracted_DS_sessions_and_Opto_sessions.xlsx");

%import subject metadata; update metadata sheet from data repo
[~,~,ratinfo]= xlsread("F:\_Github\Richard Lab\data-vp-opto\_Excel_Sheets\Christelle Opto Summary Record_dp.xlsx");


VarNames = raw(1,:);
%remove spaces in VarName (strip)
VarNames= strrep(VarNames, ' ','');
Data = raw(2: end,:);

TrainingData = struct();


%% Assign data to corresponding variables within a structure 

for i=1:40 % until column before the 'DSCueOnset' Column (general information from med PC)
    TrainingData.(VarNames{i}) = Data(1:end,(i));
end

VarNames= string(VarNames); %convert to string for strip() function; %TODO: loop through these and strip() all?

TrainingData.Subject = strip([TrainingData.Subject]);

DSColIndex = find(strcmp(strip(VarNames),'DSCueOnset'));
TrainingData.DSCueOnset = Data(1:end,DSColIndex+1 : DSColIndex + 30); % 30 trials of DS
NSColIndex = find(strcmp(strip(VarNames),'NSCueOnset'));
TrainingData.NSCueOnset = Data(1:end,NSColIndex : NSColIndex + 29); % Christelle's has 29 trials of NS??

%DP clearly missing PE timestamps... dependance on row profile is a problem
PEColIndexFirst = find(strcmp(strip(VarNames),'PETimeStamps'))+1;% the column after this is the column that has data for the timestamps in Christelle data
PEColIndexFinal = find(strcmp(strip(VarNames),'PEDurations')) - 1;
TrainingData.PETimestamps = Data(1:end,PEColIndexFirst:PEColIndexFinal); % for first 3 groups the largest number of port entry is 674, which is 908 column

medpcDSlatIndex = find(strcmp(strip(VarNames),'medpcDSLat'));
TrainingData.medpcDSLat = Data(1:end,medpcDSlatIndex : medpcDSlatIndex + 29); % 30 trials of DS
medpcNSlatIndex = find(strcmp(strip(VarNames),'medpcNSLat'));
TrainingData.medpcNSLat = Data(1:end,medpcNSlatIndex : medpcNSlatIndex + 29); % 30 trials of NS
% make sure there is no char in medpcDSLat and medpcNSLat
A = cellfun('isclass',TrainingData.medpcDSLat,'double');% checking if numeric values?
B = cellfun('isclass',TrainingData.medpcNSLat,'double');
noresultcell{1} = NaN;
TrainingData.medpcDSLat(~A) = noresultcell;% if there was something that was not a double it would be 'NaN'
TrainingData.medpcNSLat(~B) = noresultcell;

%todo: shouldn't 0s also be replaced with nan?
% TrainingData.medpcDSLat(TrainingData.medpcDSLat==0) = noresultcell;


%% assign variables to rats                         
for i = 1 : length(TrainingData.Subject)
    ind = strcmp(TrainingData.Subject{i},ratinfo(:,1));
    TrainingData.Sex{i,1} = ratinfo{ind,3};
    TrainingData.Expression{i,1}=ratinfo{ind,6};
    TrainingData.ExpType{i,1}=ratinfo{ind,5};
    TrainingData.Projection{i,1}=ratinfo{ind,4};
    TrainingData.RatNum{i,1}=ratinfo{ind,10};    
end


%% Sort all data by by rat id given before
[sortedRat,index] = sortrows([TrainingData(:).RatNum]);% index is what row the sorted data came from
fields = fieldnames(TrainingData);
for i = 1 : length(fields)
    TrainingData.(fields{i}) = TrainingData.(fields{i})(index,:);% using index to sort each field of the struct to get data sorted by rat number
end


%% Number the start dates for each rat and display any errors
Rat = TrainingData.Subject{1};% initializing at first animal
k = 1;
for i=1:length(TrainingData.StartDate)
    if strcmp(TrainingData.Subject{i},Rat)% if TrainingData.StartDate and Rat are the same, will give you logical 1, and TraindayData.Day(i,1)=k
        TrainingData.Day(i,1) = k;
        k = k + 1;% add one to k everytime there is another day for the same subject
        if i < length(TrainingData.StartDate) && TrainingData.StartDate{i} == TrainingData.StartDate{i+1} % check if the date in next row is the same as the current one
            fprintf('repeated date %d with rat %s\n', TrainingData.StartDate{i}, TrainingData.Subject{i});
        end
    else
        k = 1;% reinitialize for another animal
        Rat = TrainingData.Subject(i,1);
        TrainingData.Day(i,1) = k;
        k = k + 1;% then  add 1 to k to keep going through if loop
    end
end

%% Determine stages of training
% look at durations
% if duration == 60 ==> stage 1
% if duration == 30 ==> stage 2
% if duration == 20 ==> stage 3
% if duration == 10 and numtrials == 30 ==> stage 4
% if duration == 10 and numtrials == 60 ==> stage 5 (ps. DS + NS == 60)
% if duration = anything else ==> stage NaN, print rat and date in which this occurs


% 2023-06-28 - You will get an error with reextracted data sheet. see note above where data is loaded. need to recover ToneDur
for i=1:length(TrainingData.ToneDur)% changed for christelle, are there trials/stages excluded because stages sometimes start at 3?
    if TrainingData.ToneDur{i} >= 60
        TrainingData.Stage(i,:) = 1;
    elseif TrainingData.ToneDur{i} == 30
        TrainingData.Stage(i,:) = 2;
    elseif TrainingData.ToneDur{i} == 20
        TrainingData.Stage(i,:) = 3;
    elseif TrainingData.ToneDur{i} == 10 && (TrainingData.NumNS{i,1}) == 0 %JR - this was previously assigning stage 4 and 5 as stage 4
        TrainingData.Stage(i,:) = 4;
    elseif TrainingData.ToneDur{i} == 10 && (TrainingData.NumNS{i,1}) >0 %dp changed this to just check for any NS trials
        TrainingData.Stage(i,:) = 5;
    else
        TrainingData.Stage(i,:) = NaN;
        fprintf('stage is NaN for rat %s on date %d\n', TrainingData.Subject{i}, TrainingData.StartDate{i});
    end
end

%% Number the training days for early training (stage 1-4) and final training for each rat and display any errors
Rat = TrainingData.Subject{1};% initializing at first animal
k = 1;
Stage = NaN;
for i=1:length(TrainingData.StartDate)
    if strcmp(TrainingData.Subject{i},Rat) && TrainingData.Stage(i)<=4% if TrainingData.StartDate and Rat are the same, will give you logical 1, and TraindayData.Day(i,1)=k
        TrainingData.EarlyDay(i,1) = k;
        TrainingData.FinalDay(i,1) = NaN;
        k = k + 1;% add one to k everytime there is another day for the same subject
        Stage = TrainingData.Stage(i);      
    else if strcmp(TrainingData.Subject{i},Rat) & TrainingData.Stage(i)==5%
            if TrainingData.Stage(i)==Stage
                TrainingData.EarlyDay(i,1)=NaN;
                TrainingData.FinalDay(i,1)=k;
                k=k+1;
                Stage=TrainingData.Stage (i);
            else
                k=1; %start count over for final stage
                TrainingData.EarlyDay(i,1)=NaN;
                TrainingData.FinalDay(i,1)=k;
                k=k+1;
                Stage=TrainingData.Stage(i);
            end
        else
            k = 1;% reinitialize for another animal
            Rat = TrainingData.Subject(i,1);
            TrainingData.EarlyDay(i,1) = k;
            TrainingData.FinalDay(i,1) = NaN;
            k = k + 1;% then  add 1 to k to keep going through if loop
        end
    end
end


%% Calculate trial-by-trial PE latencies for DS and NS

% Convert necessary cells to matrices, setting all strings to NaN
for y=1:length(TrainingData.DSCueOnset)
    for x=1:size(TrainingData.DSCueOnset,2)
        if ischar(TrainingData.DSCueOnset{y,x})% if there is a characterarray in DS Cue onset cell array then make that cell "nan"
           TrainingData.DSCueOnset{y,x} = NaN;
        end
    end
end

for y=1:length(TrainingData.NSCueOnset) % do the same thing for the NS Cue onset cell array
    for x=1:size(TrainingData.NSCueOnset,2)
        if ischar(TrainingData.NSCueOnset{y,x})
           TrainingData.NSCueOnset{y,x} = NaN;
        end
    end
end

for y=1:size(TrainingData.PETimestamps,1)% and repeat for the PE timstamps
    for x=1:size(TrainingData.PETimestamps,2)
        if ischar(TrainingData.PETimestamps{y,x})
           TrainingData.PETimestamps{y,x} = NaN;
        end
    end
end
% DS latency calculation

%Two different latencies here! Relative (DSRelLatency) and Absolute
%(DSAbsLatency)... relative I think is within cue window and I think
%Absolute may be even beyond the cue window?
TrainingData.DSCueOnset = cell2mat(TrainingData.DSCueOnset);% turn the cell arrays into matricies
TrainingData.NSCueOnset = cell2mat(TrainingData.NSCueOnset);
TrainingData.PETimestamps = cell2mat(TrainingData.PETimestamps);

for i =  1 : size(TrainingData.DSCueOnset,1)
    for j = 1 : size(TrainingData.DSCueOnset,2)
        if ~isnan(TrainingData.DSCueOnset(i,j)) && TrainingData.DSCueOnset(i,j) > 0  && TrainingData.medpcDSLat{i,j} > 0.01 % anything that is not a NaN and greater than zero and the latency is greater than 0.01 continues on in the loop
            curDS = TrainingData.DSCueOnset(i,j); % if all that was true then current DS= the (i,j) cell
            nextDS = TrainingData.DSCueOnset(i,find(TrainingData.DSCueOnset(i,:) > curDS,1)); % next DS will be in the same row and the first element that is greater than the curDS in the i row of every column
            nextNS = TrainingData.NSCueOnset(i,find(TrainingData.NSCueOnset(i,:) > curDS,1)); % next NS will be in the same row and the first element that is greater than the curDS in variable NSCueOnset
            if ~isempty(nextDS) && ~isempty(nextNS)%if next DS is not empty and next NS is not empty nextcue is the smallest value of the two elements it is comparing
            nextCue = min(nextDS,nextNS);
            elseif isempty(nextDS) && ~isempty(nextNS) % no DS left
                nextCue = nextNS;
            elseif isempty(nextNS) && ~isempty(nextDS) % no NS left
                nextCue = nextDS;
            else % no cue left
                nextCue = inf;%inf is infinity, don't know why?
            end
            curDSDuration = TrainingData.ToneDur{i,1}; %match up the tone duration location for the current DS with the i location
            firstEnter = TrainingData.PETimestamps(i,find(TrainingData.PETimestamps(i,:) > curDS & TrainingData.PETimestamps(i,:) < nextCue,1 ));% identify when animal first entered by finding the 
            %first element of PETimestamps that is greater than the curDS
            %and less than the next cue
            if isempty(firstEnter)% if the first enter variable is an empry vector than the latencies are NaN
                TrainingData.DSRelLatency(i,j) = NaN;
                TrainingData.DSAbsLatency(i,j) = NaN;
                TrainingData.DS10sResponse(i,j) = 0;
            elseif firstEnter - curDS > curDSDuration % otherwise if the time of first entering-curDS cue time is greater than the DS duration the absolute latencey is the difference between the DScue and the PEtime
                TrainingData.DSRelLatency(i,j) = NaN;
                TrainingData.DS10sResponse(i,j) = 0;
                TrainingData.DSAbsLatency(i,j) = firstEnter - curDS;              
            elseif firstEnter - curDS < curDSDuration % otherwise if the difference between the DS and PE times is less than the duration of the cue (entered during the cue), both the relative and absolute latency is equal to that difference
                TrainingData.DSRelLatency(i,j) = firstEnter - curDS;
                TrainingData.DSAbsLatency(i,j) = firstEnter - curDS;
                if firstEnter - curDS <= 10
                    TrainingData.DS10sResponse(i,j) = 1;
                else
                    TrainingData.DS10sResponse(i,j) = 0;
                end
            end
        else
            TrainingData.DSRelLatency(i,j) = NaN; % if the DS cue onset is Nan, equal to zero or the medPC reads the latency as 0.01 then assign these cells a NaN value
            TrainingData.DSAbsLatency(i,j) = NaN;%  WANT TO CHANGE THIS EVENTUALLY TO HAVE RESPONSE VARIABLES!!
            TrainingData.DS10sResponse(i,j) = NaN;
        end        
    end
end


TrainingData.DSRelLatMean = nanmean(TrainingData.DSRelLatency,2);
TrainingData.DSAbsLatMean = nanmean(TrainingData.DSAbsLatency,2);

% NS latency calculation
for i = 1 : size(TrainingData.NSCueOnset,1)
    for j = 1 : size(TrainingData.NSCueOnset,2)
        if ~isnan(TrainingData.NSCueOnset(i,j)) && TrainingData.NSCueOnset(i,j) > 0 %&& TrainingData.medpcNSLat{i,j} > 0.01
            curNS = TrainingData.NSCueOnset(i,j);
            nextNS = TrainingData.NSCueOnset(i,find(TrainingData.NSCueOnset(i,:) > curNS,1));
            nextDS = TrainingData.DSCueOnset(i,find(TrainingData.DSCueOnset(i,:) > curNS,1));
            if ~isempty(nextDS) && ~isempty(nextNS) 
                nextCue = min(nextDS,nextNS);
            elseif isempty(nextDS) && ~isempty(nextNS) % no DS left
                nextCue = nextNS;
            elseif isempty(nextNS) && ~isempty(nextDS) % no NS left
                nextCue = nextDS;
            else % no cue left
                nextCue = inf;
            end
            curNSDuration = TrainingData.ToneDur{i,1}; % NS always last 10 s
            firstEnter = TrainingData.PETimestamps(i,find(TrainingData.PETimestamps(i,:) > curNS & TrainingData.PETimestamps(i,:) < nextCue,1 ));
            if isempty(firstEnter)
                TrainingData.NSRelLatency(i,j) = NaN;
                TrainingData.NSAbsLatency(i,j) = NaN;  
                TrainingData.NS10sResponse(i,j) = 0;
            elseif firstEnter - curNS > curNSDuration
                TrainingData.NSRelLatency(i,j) = NaN;
                TrainingData.NSAbsLatency(i,j) = firstEnter - curNS; 
                TrainingData.NS10sResponse(i,j) = 0;
            elseif firstEnter - curNS < curNSDuration
                TrainingData.NSRelLatency(i,j) = firstEnter - curNS;
                TrainingData.NSAbsLatency(i,j) = firstEnter - curNS;
                TrainingData.NS10sResponse(i,j) = 1;
            end
        else
            TrainingData.NSRelLatency(i,j) = NaN;
            TrainingData.NSAbsLatency(i,j) = NaN;
            TrainingData.NS10sResponse(i,j) = NaN;
        end
    end
end

TrainingData.DS10sResponseProb = nanmean(TrainingData.DS10sResponse,2);
TrainingData.DS10sResponseProb(isnan(TrainingData.DS10sResponseProb)) = 0; %Runbo added this to turn Nans into zero. Nans happen when animal makes no port entries at all. 
TrainingData.NS10sResponseProb = nanmean(TrainingData.NS10sResponse,2);
TrainingData.NSRelLatMean = nanmean(TrainingData.NSRelLatency,2);% removing nan values and calculating the NSRelLatMean across columns
TrainingData.NSAbsLatMean = nanmean(TrainingData.NSAbsLatency,2);% removing nan values and calculating the DSRelLatMean across columns

%% dp redefining peratio and latency
%previous method inaccurate bc pes missing
%just using the mpc calculated values for now
TrainingData.DS10sResponseProb= TrainingData.DSRatio;
TrainingData.NS10sResponseProb= TrainingData.NSRatio;

TrainingData.DS10sResponseProb= cell2mat(TrainingData.DS10sResponseProb);
TrainingData.NS10sResponseProb= cell2mat(TrainingData.NS10sResponseProb);

%just taking the mean latency computed by MPC
TrainingData.DSRelLatMean= cell2mat(TrainingData.DSLat);
TrainingData.NSRelLatMean= cell2mat(TrainingData.NSLat);

%% plot Training DS Early Training PERatio ( using data from medpc)using @gramm package

TrainingData.DSRatio=cell2mat(TrainingData.DSRatio);
TrainingData.NSRatio=cell2mat(TrainingData.NSRatio);
TrainingData.Sex=cell2mat(TrainingData.Sex);
TrainingData.Sex=cellstr(TrainingData.Sex);
TrainingData.ExpType=cell2mat(TrainingData.ExpType);
TrainingData.RatNum=cell2mat(TrainingData.RatNum);

%% DP adding specific exception for a single session with code error, PEs were lost that session but I think the DS and NS ratios computed by MPC should be correct
%just replace the calculated ds & ns PE ratio with the MPC values
for specialSession= find([TrainingData.StartDate{:}]==210530) %only session is 20210530
%    TrainingData.DS10sResponseProb(specialSession)= TrainingData.DSRatio(specialSession);  
%    TrainingData.NS10sResponseProb(specialSession)= TrainingData.NSRatio(specialSession);
end


%% PLOT ABS LATENCY: plot calculated DS and NS Early Training and Late Training Absolute Latency using @gramm package

%Overall Early Training Abs Latency by Mode only 

%Inhibition Early-- all inhibition animals
figure
selection = TrainingData.ExpType==0;
i=gramm('x',TrainingData.EarlyDay(selection),'y',TrainingData.DSAbsLatMean(selection),'color',TrainingData.Projection(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Latency (sec)','color','DS(-)','column','Group')
i.set_title('Overall Inhib Early Training Stage Latency')
i.axe_property( 'YLim',[0 50])
days= TrainingData.EarlyDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.draw()
i.export( 'file_name','Overall Inhib Early Training Stage Latency','export_path',SavingDir,'file_type','pdf')

%Stimulation Early--all stimulation animals
figure
selection = TrainingData.ExpType==1;
i=gramm('x',TrainingData.EarlyDay(selection),'y',TrainingData.DSAbsLatMean(selection),'color',TrainingData.Projection(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Latency (sec)','color','DS(-)','column','Group')
i.set_title('Overall Stim Early Training Stage Latency')
i.axe_property( 'YLim',[0 50])
days= TrainingData.EarlyDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.draw()
i.export( 'file_name','Overall Stim Early Training Stage Latency','export_path',SavingDir,'file_type','pdf')


%Overall early training progress by subject
figure
i=gramm('x',TrainingData.EarlyDay,'y',TrainingData.DSAbsLatMean,'color',TrainingData.Subject)
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Latency (sec)','color','DS(-)','column','RatID');
i.set_title('Individual Early Training Stage Abs Latency');
i.axe_property( 'YLim',[0 150]);
days= TrainingData.EarlyDay(selection);
days= days(~isnan(days));
% i.axe_property( 'XLim',[1, numel(unique(days))]);
i.draw()
i.export( 'file_name','Individual Early Training Stage Abs Latency','export_path',SavingDir,'file_type','pdf')



%%
%Overall LATE training Abs Latency progress by Mode only


%Inhibition Late-- all inhibition animals
figure
selection = TrainingData.ExpType==0;
i=gramm('x',TrainingData.FinalDay(selection),'y',TrainingData.DSAbsLatMean(selection),'color',TrainingData.Projection(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Latency (sec)','color','DS(-)','column','Group')
i.set_title('Overall Inhib Late Training Stage Latency')
i.axe_property( 'YLim',[0 50])
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.draw()

i.update('x',TrainingData.FinalDay(selection),'y',TrainingData.NSAbsLatMean(selection),'color',TrainingData.Projection(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Latency(sec)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 50]);
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.no_legend()
i.draw()
i.export( 'file_name','Overall Inhib Late Training Stage Latency','export_path',SavingDir,'file_type','pdf')

%Stimulation Late--all stimulation animals
figure
selection = TrainingData.ExpType==1;
i=gramm('x',TrainingData.FinalDay(selection),'y',TrainingData.DSAbsLatMean(selection),'color',TrainingData.Projection(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Latency (sec)','color','DS(-)','column','Group')
i.set_title('Overall Stim Late Training Stage Latency')
i.axe_property( 'YLim',[0 50])
i.axe_property( 'XLim',[1 18]);
i.draw()

i.update('x',TrainingData.FinalDay(selection),'y',TrainingData.NSAbsLatMean(selection),'color',TrainingData.Projection(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Latency(sec)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 50]);
i.axe_property( 'XLim',[1 13]);
i.no_legend()
i.draw()
i.export( 'file_name','Overall Stim Late Training Stage Latency','export_path',SavingDir,'file_type','pdf')


%Overall LATE Individual PE Latencies
figure
i=gramm('x',TrainingData.FinalDay,'y',TrainingData.DSAbsLatMean,'color',TrainingData.Subject)
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Latency (sec)','color','DS(-)','column','RatID');
i.set_title('Individual Late Training Stage Abs Latency');
i.axe_property( 'YLim',[0 150]);
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
% i.axe_property( 'XLim',[1, numel(unique(days))]);i.draw()

i.update('x',TrainingData.FinalDay,'y',TrainingData.NSAbsLatMean,'color',TrainingData.Subject)
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Latency(sec)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 50]);
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
% i.axe_property( 'XLim',[1, numel(unique(days))]);i.no_legend()
i.draw()
i.export( 'file_name','Individual Late Training Stage Abs Latency','export_path',SavingDir,'file_type','pdf')

%Overall LATE Individual Relative PE Latencies
figure
i=gramm('x',TrainingData.FinalDay,'y',TrainingData.DSRelLatMean,'color',TrainingData.Subject)
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Latency (sec)','color','DS(-)','column','RatID');
i.set_title('Individual Late Training Stage Rel Latency');
i.axe_property( 'YLim',[0 150]);
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
% i.axe_property( 'XLim',[1, numel(unique(days))]);
i.draw()

i.update('x',TrainingData.FinalDay,'y',TrainingData.NSRelLatMean,'color',TrainingData.Subject)
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Latency(sec)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 50]);
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
% i.axe_property( 'XLim',[1, numel(unique(days))]);
i.no_legend()
i.draw()
i.export( 'file_name','Individual Late Training Stage Rel Latency','export_path',SavingDir,'file_type','pdf')





%%
%Overall absolute latency by sex (early and late)

%Early Abs Latency
figure
i=gramm('x',TrainingData.EarlyDay,'y',TrainingData.DSAbsLatMean,'color',TrainingData.Sex)
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Latency (sec)','color','DS(-)','column','RatID');
i.set_title('Early Training Stage Abs Latency by Sex');
i.axe_property( 'YLim',[0 50]);
i.axe_property( 'XLim',[1 18]);
i.draw()
i.export( 'file_name','Early Training Stage Abs Latency by Sex','export_path',SavingDir,'file_type','pdf')

%Late Abs Latency
figure
i=gramm('x',TrainingData.FinalDay,'y',TrainingData.DSAbsLatMean,'color',TrainingData.Sex)
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Latency (sec)','color','DS(-)','column','RatID');
i.set_title('Final Training Stage Abs Latency by Sex');
i.axe_property( 'YLim',[0 50]);
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
% i.axe_property( 'XLim',[1, numel(unique(days))]);
i.draw()

i.update('x',TrainingData.FinalDay,'y',TrainingData.NSAbsLatMean,'color',TrainingData.Sex)
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Latency(sec)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 50]);
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
% i.axe_property( 'XLim',[1, numel(unique(days))]);
i.no_legend()
i.draw()
i.export( 'file_name','Final Training Stage Abs Latency by Sex','export_path',SavingDir,'file_type','pdf')

%% ABSOLUTE LATENCY: Plots indiv animals by mode and projection

export_path= SavingDir;

%Early Stim Thalamus 
figure
selection = TrainingData.ExpType==1 & (strcmp(TrainingData.Projection,'mdThal')); 
i=gramm('x',TrainingData.EarlyDay(selection),'y',TrainingData.DSAbsLatMean(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Latency (sec)','color','DS(-)','column','RatID');
i.set_title('Stim mdThal Early Abs Latency');
i.axe_property( 'YLim',[0 50]);
i.axe_property( 'XLim',[1 18]);
i.draw()
i.export( 'file_name','Stim mdThal Early Abs Latency','export_path',SavingDir,'file_type','pdf') 


%Late Stim Thalamus
figure
selection = TrainingData.ExpType==1 & (strcmp(TrainingData.Projection,'mdThal')); 
i=gramm('x',TrainingData.FinalDay(selection),'y',TrainingData.DSAbsLatMean(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Latency (sec)','color','DS(-)','column','RatID');
i.set_title('Stim mdThal Late Abs Latency');
i.axe_property( 'YLim',[0 50]);
i.axe_property( 'XLim',[1 18]);
i.draw()

i.update('x',TrainingData.FinalDay(selection),'y',TrainingData.NSAbsLatMean(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Latency(sec)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 50]);
i.axe_property( 'XLim',[1 13]);
i.no_legend()
i.draw()
i.export( 'file_name','Stim mdThal Late Abs Latency','export_path',SavingDir,'file_type','pdf')

%Early Stim VTA
figure
selection = TrainingData.ExpType==1 & (strcmp(TrainingData.Projection,'VTA')); 
i=gramm('x',TrainingData.EarlyDay(selection),'y',TrainingData.DSAbsLatMean(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Latency (sec)','color','DS(-)','column','RatID');
i.set_title('Stim VTA Early Abs Latency');
i.axe_property( 'YLim',[0 50]);
i.axe_property( 'XLim',[1 18]);
i.draw()
i.export( 'file_name','Stim VTA Early Abs Latency','export_path',SavingDir,'file_type','pdf')

%Late Stim VTA
figure
selection = TrainingData.ExpType==1 & (strcmp(TrainingData.Projection,'VTA')); 
i=gramm('x',TrainingData.FinalDay(selection),'y',TrainingData.DSAbsLatMean(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Latency (sec)','color','DS(-)','column','RatID');
i.set_title('Stim VTA Late Abs Latency');
i.axe_property( 'YLim',[0 50]);
i.axe_property( 'XLim',[1 18]);
i.draw()

i.update('x',TrainingData.FinalDay(selection),'y',TrainingData.NSAbsLatMean(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Latency(sec)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 50]);
i.axe_property( 'XLim',[1 13]);
i.no_legend()
i.draw()
i.export( 'file_name','Stim VTA Late Abs Latency','export_path',SavingDir,'file_type','pdf')


%Inhib Early Thal
figure
selection = TrainingData.ExpType==0 & (strcmp(TrainingData.Projection,'mdThal')); 
i=gramm('x',TrainingData.EarlyDay(selection),'y',TrainingData.DSAbsLatMean(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Latency (sec)','color','DS(-)','column','RatID');
i.set_title('Inhib mdthal Early Training Stage Abs Latency');
i.axe_property( 'YLim',[0 50]);
i.axe_property( 'XLim',[1 18]);
i.draw()
i.export( 'file_name','Inhib mdthal Early Training Stage Abs Latency','export_path',SavingDir,'file_type','pdf')


%Inhib Late mdThal
figure
selection = TrainingData.ExpType==0 & (strcmp(TrainingData.Projection,'mdThal')); 
i=gramm('x',TrainingData.FinalDay(selection),'y',TrainingData.DSAbsLatMean(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Latency (sec)','color','DS(-)','column','RatID');
i.set_title('Inhib mdThal Late Abs Latency');
i.axe_property( 'YLim',[0 50]);
i.axe_property( 'XLim',[1 18]);
i.draw()

i.update('x',TrainingData.FinalDay(selection),'y',TrainingData.NSAbsLatMean(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Latency(sec)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 50]);
i.axe_property( 'XLim',[1 13]);
i.no_legend()
i.draw()
i.export( 'file_name','Inhib mdThal Late Abs Latency','export_path',SavingDir,'file_type','pdf')


%Inhib Early VTA 
figure
selection = TrainingData.ExpType==0 & (strcmp(TrainingData.Projection,'VTA')); 
i=gramm('x',TrainingData.EarlyDay(selection),'y',TrainingData.DSAbsLatMean(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Latency (sec)','color','DS(-)','column','RatID');
i.set_title('Inhib VTA Early Abs Latency');
i.axe_property( 'YLim',[0 50]);
days= TrainingData.EarlyDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.draw()
i.export( 'file_name','Inhib VTA Early Abs Latency','export_path',SavingDir,'file_type','pdf')


%%Inhib Late VTA
figure
selection = TrainingData.ExpType==0 & (strcmp(TrainingData.Projection,'VTA')); 
i=gramm('x',TrainingData.EarlyDay(selection),'y',TrainingData.DSAbsLatMean(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Latency (sec)','color','DS(-)','column','RatID');
i.set_title('Inhib VTA Late Abs Latency');
i.axe_property( 'YLim',[0 50]);
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.draw()

i.update('x',TrainingData.FinalDay(selection),'y',TrainingData.NSAbsLatMean(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Latency(sec)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 50]);
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.no_legend()
i.draw()
i.export( 'file_name','Inhib VTA Late Abs Latency','export_path',SavingDir,'file_type','pdf')



%% PLOT RESPONSE PROBABILITIES BY SEX: Plot calculated DS and NS Early Training and Late Training Response Probability using @gramm package

%Early Response Prob by Sex
figure
i=gramm('x',TrainingData.EarlyDay,'y',TrainingData.DS10sResponseProb,'color',TrainingData.Sex)
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Response Probability (10s)','color','DS(-)','column','RatID');
i.set_title('Early Response Probability by Sex');
i.axe_property( 'YLim',[0 1]);
i.axe_property( 'XLim',[1 18]);
i.draw()
i.export( 'file_name','Early Response Probability by Sex','export_path',SavingDir,'file_type','pdf')


%Late Response Prob by Sex
figure
i=gramm('x',TrainingData.FinalDay,'y',TrainingData.DS10sResponseProb,'color',TrainingData.Sex)
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'DS Response Probability (10s)','color','DS(-)   NS(--)','column','RatID');
i.set_title('Late Response Probability by Sex');
i.axe_property( 'YLim',[0 1]);
i.axe_property( 'XLim',[1 13]);
i.draw()

i.update('x',TrainingData.FinalDay,'y',TrainingData.NS10sResponseProb,'color',TrainingData.Sex)
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Response Probability (10s)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 1]);
i.axe_property( 'XLim',[1 13]);
i.no_legend()
i.draw()
i.export( 'file_name','Late Response Probability by Sex','export_path',SavingDir,'file_type','pdf')


%% PLOT RESPONSE PROBABILITIES BY MODE: Plot calculated DS and NS Early Training and Late Training Response Probability using @gramm package

%Overall Early Stim
figure
selection = TrainingData.ExpType==1;
i=gramm('x',TrainingData.EarlyDay(selection),'y',TrainingData.DS10sResponseProb(selection),'color',TrainingData.Projection(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Response Probability (10s)','color','DS(-)','column','RatID');
i.set_title('Overall Early Stim Response Probability');
i.axe_property( 'YLim',[0 1]);
i.axe_property( 'XLim',[1 18]);
i.draw()
i.export( 'file_name','Overall Early Stim Response Probability','export_path',SavingDir,'file_type','pdf')


%Overall Late Stim
figure
selection = TrainingData.ExpType==1;
i=gramm('x',TrainingData.FinalDay(selection),'y',TrainingData.DS10sResponseProb(selection),'color',TrainingData.Projection(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'DS Response Probability (10s)','color','DS(-)   NS(--)','column','RatID');
i.set_title('Overall Late Stim Response Probability');
i.axe_property( 'YLim',[0 1]);
i.axe_property( 'XLim',[1 13]);
i.draw()

i.update('x',TrainingData.FinalDay(selection),'y',TrainingData.NS10sResponseProb(selection),'color',TrainingData.Projection(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Response Probability (10s)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 1]);
i.axe_property( 'XLim',[1 13]);
i.no_legend()
i.draw()
i.export( 'file_name','Overall Late Stim Response Probability','export_path',SavingDir,'file_type','pdf')

%Overall Early Inhib
figure
selection = TrainingData.ExpType==0;
i=gramm('x',TrainingData.EarlyDay(selection),'y',TrainingData.DS10sResponseProb(selection),'color',TrainingData.Projection(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Response Probability (10s)','color','DS(-)','column','RatID');
i.set_title('Overall Early Inhib Response Probability');
i.axe_property( 'YLim',[0 1]);
days= TrainingData.EarlyDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.draw()
i.export( 'file_name','Overall Early Inhib Response Probability','export_path',SavingDir,'file_type','pdf')


%Overall Late Inhib
figure
selection = TrainingData.ExpType==0;
i=gramm('x',TrainingData.FinalDay(selection),'y',TrainingData.DS10sResponseProb(selection),'color',TrainingData.Projection(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Response Probability (10s)','color','DS(-)   NS(--)','column','RatID');
i.set_title('Overall Late Inhib Response Probability');
i.axe_property( 'YLim',[0 1]);
%set x axes limits to the number of days represented in graph...
%to use the unique() function, need to first get rid of any nans
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);
i.draw()

i.update('x',TrainingData.FinalDay(selection),'y',TrainingData.NS10sResponseProb(selection),'color',TrainingData.Projection(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Response Probability (10s)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 1]);
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.no_legend()
i.draw()
i.export( 'file_name','Overall Late Inhib Response Probability','export_path',SavingDir,'file_type','pdf')

%% PLOT RESPONSE PROBABILITIES BY MODE AND PROJECTION: Plot calculated DS and NS Early Training and Late Training Response Probability using @gramm package


%Stim Early mdThal
figure
selection = TrainingData.ExpType==1 & (strcmp(TrainingData.Projection,'mdThal')); 
i=gramm('x',TrainingData.EarlyDay(selection),'y',TrainingData.DS10sResponseProb(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Response Probability (10s)','color','DS(-)','column','RatID');
i.set_title('Stim Early mdThal Response Prob');
i.axe_property( 'YLim',[0 1]);
i.axe_property( 'XLim',[1 18]);
i.draw()
i.export( 'file_name','Stim Early mdThal Response Prob','export_path',SavingDir,'file_type','pdf')


%Stim Late mdThal
figure
selection = TrainingData.ExpType==1 & (strcmp(TrainingData.Projection,'mdThal')); 
i=gramm('x',TrainingData.FinalDay(selection),'y',TrainingData.DS10sResponseProb(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Response Probability (10s)','color','DS(-)','column','RatID');
i.set_title('Stim Late mdThal Response Probability');
i.axe_property( 'YLim',[0 1]);
i.axe_property( 'XLim',[1 13]);
i.draw()

i.update('x',TrainingData.FinalDay(selection),'y',TrainingData.NS10sResponseProb(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Response Probability (10s)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 1]);
i.axe_property( 'XLim',[1 13]);
i.no_legend()
i.draw()
i.export( 'file_name','Stim Late mdThal Response Probability','export_path',SavingDir,'file_type','pdf')



%Stim Early VTA
figure
selection = TrainingData.ExpType==1 & (strcmp(TrainingData.Projection,'VTA')); 
i=gramm('x',TrainingData.EarlyDay(selection),'y',TrainingData.DS10sResponseProb(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Response Probability (10s)','color','DS(-)','column','RatID');
i.set_title('Stim Early VTA Response Prob');
i.axe_property( 'YLim',[0 1]);
days= TrainingData.EarlyDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.draw()
i.export( 'file_name','Stim Early VTA Response Prob','export_path',SavingDir,'file_type','pdf')


%Stim Late VTA
figure
selection = TrainingData.ExpType==1 & (strcmp(TrainingData.Projection,'VTA')); 
i=gramm('x',TrainingData.FinalDay(selection),'y',TrainingData.DS10sResponseProb(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Response Probability (10s)','color','DS(-)','column','RatID');
i.set_title('Stim Late VTA Response Probability');
i.axe_property( 'YLim',[0 1]);
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.draw()

i.update('x',TrainingData.FinalDay(selection),'y',TrainingData.NS10sResponseProb(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Response Probability (10s)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 1]);
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.no_legend()
i.draw()
i.export( 'file_name','Stim Late VTA Response Probability','export_path',SavingDir,'file_type','pdf')



%Inhib Early mdThal
figure
selection = TrainingData.ExpType==0 & (strcmp(TrainingData.Projection,'mdThal')); 
i=gramm('x',TrainingData.EarlyDay(selection),'y',TrainingData.DS10sResponseProb(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Response Probability (10s)','color','DS(-)','column','RatID');
i.set_title('Inhib Early mdThal Response Prob');
i.axe_property( 'YLim',[0 1]);
i.axe_property( 'XLim',[1 18]);
i.draw()
i.export( 'file_name','Inhib Early mdThal Response Prob','export_path',SavingDir,'file_type','pdf')


%Inhib Late mdThal
figure
selection = TrainingData.ExpType==0 & (strcmp(TrainingData.Projection,'mdThal')); 
i=gramm('x',TrainingData.FinalDay(selection),'y',TrainingData.DS10sResponseProb(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Response Probability (10s)','color','DS(-)','column','RatID');
i.set_title('Inhib Late mdThal Response Probability');
i.axe_property( 'YLim',[0 1]);
i.axe_property( 'XLim',[1 13]);
i.draw()

i.update('x',TrainingData.FinalDay(selection),'y',TrainingData.NS10sResponseProb(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y','Response Probability (10s)');
i.set_line_options( 'styles',{':'});
i.axe_property( 'YLim',[0 1]);
i.axe_property( 'XLim',[1 13]);
i.no_legend()
i.draw()
i.export( 'file_name','Inhib  Late mdThal Response Probability','export_path',SavingDir,'file_type','pdf')



%Inhib Early VTA
figure
selection = TrainingData.ExpType==0 & (strcmp(TrainingData.Projection,'VTA')); 
i=gramm('x',TrainingData.EarlyDay(selection),'y',TrainingData.DS10sResponseProb(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Response Probability (10s)','color','DS(-)','column','RatID');
i.set_title('Inhib Early VTA Response Prob');
i.axe_property( 'YLim',[0 1]);
days= TrainingData.EarlyDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.draw()
i.export( 'file_name','Inhib Early VTA Response Prob','export_path',SavingDir,'file_type','pdf')


%% Inhib Late VTA
figure
selection = TrainingData.ExpType==0 & (strcmp(TrainingData.Projection,'VTA')); 
i=gramm('x',TrainingData.FinalDay(selection),'y',TrainingData.DS10sResponseProb(selection),'color',TrainingData.Subject(selection))
i.stat_summary('type','sem','geom','area');
i.set_names('x','Training Day','y', 'Response Probability (10s)','color','DS(-)','column','RatID');
i.set_title('Inhib Late VTA Response Probability');
i.axe_property( 'YLim',[0 1]);
days= TrainingData.FinalDay(selection);
days= days(~isnan(days));
i.axe_property( 'XLim',[1, numel(unique(days))]);i.draw()

i.geom_hline('yintercept',criteriaPEratio); %add line at criteria threshold


% i.update('x',TrainingData.FinalDay(selection),'y',TrainingData.NS10sResponseProb(selection),'color',TrainingData.Subject(selection))
% i.stat_summary('type','sem','geom','area');
% i.set_names('x','Training Day','y','Response Probability (10s)');
% i.set_line_options( 'styles',{':'});
% i.axe_property( 'YLim',[0 1]);
% days= TrainingData.FinalDay(selection);
% days= days(~isnan(days));
% i.axe_property( 'XLim',[1, numel(unique(days))]);i.no_legend()
i.draw()
i.export( 'file_name','Inhib Late VTA Response Probability','export_path',SavingDir,'file_type','pdf')







