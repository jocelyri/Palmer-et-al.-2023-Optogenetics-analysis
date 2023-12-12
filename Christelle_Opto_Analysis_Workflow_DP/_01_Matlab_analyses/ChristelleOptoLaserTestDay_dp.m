clear all
close all

clc

%% Figure options
figPath= strcat(pwd,'\_output\_DS_task_stimDay\');

% figFormats= {'.png'} %list of formats to save figures as (for saveFig.m)
figFormats= {'.svg', '.pdf'} %list of formats to save figures as (for saveFig.m)


%% Set GRAMM defaults for plots

set_gramm_plot_defaults();

%% Import data- update paths accordingly

% %--christelle opto data

%import behavioral data; dp reextracted data from data repo
[~,~,raw]= xlsread("F:\_Github\Richard Lab\data-vp-opto\_Excel_Sheets\_dp_reextracted\dp_reextracted_DS_sessions_and_Opto_sessions.xlsx");

%import subject metadata; update metadata sheet from data repo
[~,~,ratinfo]= xlsread("F:\_Github\Richard Lab\data-vp-opto\_Excel_Sheets\Christelle Opto Summary Record_dp.xlsx");


%load the original behavior data sheet used by Christelle
% (used to confirm laser duration)
[~,~,DataOG] = xlsread("F:\_Github\Richard Lab\data-vp-opto\_Excel_Sheets\OptoStimDayAnalysis051121.xlsx");

VarNames = raw(1,:);
Data = raw(2: end,:);

% first convert to table(nice to work with)
% cell2table kinda slow here? profiling... 247s
Data= cell2table(raw);

%assign first row as column names
Data.Properties.VariableNames = Data{1,:};

% %remove first row with var names
Data= Data(2:end,:);

 %% dp 2023-01-31 dynamic manual assignment of laserDur based on MSN
% %  % -- skip this, won't work, see note below 
% %  %Christelle's sheet shows animals included always ran in order: StimLength
% %  %0, 1, 10, 20 (if they ran 20)
% %  
% %  % SO should be able to groupby() and cumcount sessions with opto stim MSNs
% %  % and assign based on count/order
% %  % also should give good verification that n sessions per MSN is as
% %  % expected
%  
% %MSNs to include
% % for some reason, MPC2XL seems to be cutting off MSNs before spaces but
% % for this application it's fine 
% MSNopto= 'PulsePal';
% 
% % subset data
% % table to use table functions
% data= Data(:,["Subject","StartDate","StartTime","MSN","Experiment"]);
% 
% %initialize new col
% data(:,'SessionOptoManip')= table(nan);
% 
% %use findgroups to groupby subject,trainPhaseLabel and manually cumcount() for
% %sessions within-trainPhaseLabel
% 
% groupIDs= [];
% %actually just need to group by Subject, assuming 1 row = 1 session 
% groupIDs= findgroups(data.Subject, data.MSN);
% 
% groupIDsUnique= [];
% groupIDsUnique= unique(groupIDs);
% 
% for thisGroupID= 1:numel(groupIDsUnique)
%     %for each groupID, find index matching groupID
%     ind= [];
%     ind= find(groupIDs==groupIDsUnique(thisGroupID));
%     
%     %for each groupID, get the table data matching this group
%     thisGroup=[];
%     thisGroup= data(ind,:);
% 
%     %now cumulative count of observations in this group
%     %make default value=1 for each, and then cumsum() to get cumulative count
%     thisGroup(:,'cumcount')= table(1);
%     thisGroup(:,'cumcount')= table(cumsum(thisGroup.cumcount));
%     
%     %assign back into table
% %     data(ind, 'SessionOptoManip')= table(thisGroup.cumcount);
% 
%     %make assignment contingent on opto manipulation MSN
%     ind2= [];
%     
%     ind2= find(strcmp(data.MSN, MSNopto));
%     
%     ind= ind(ismember(ind,ind2)); %simply exclude groups without this MSN 
%     
%     if ~isempty(ind)
%        data((ind), 'SessionOptoManip')= table(thisGroup.cumcount);
%     end
%     
% end 
% 
% %assign back into struct
% % DSStimulation.SessionOptoManip= data.SessionOptoManip;
% %  
% 

%- laser duration was USUALLY fixed, but not always (e.g. OM10)... also
%there's intermixing of MSNs (with some normal DS training MSNs used for
%"0" stimLength in her sheet)
% - SO , above approach won’t work probably… instead could check against StartDate only?
%     - looks like laser dur was the same for all subjects within-date ?

% %- cant even really group by MSN because 0 StimLength sessions are mixed in with non-opto MSN.
% 
% % subsetting opto manipulation MSN data just for quick date comparison (are
% % any missing)?
% %MSNs to include
% % for some reason, MPC2XL seems to be cutting off MSNs before spaces but
% % for this application it's fine 
% MSNopto= 'PulsePal';
% 
% % subset data
% % table to use table functions
% data= Data(:,["Subject","StartDate","StartTime","MSN","Experiment"]);
% 
% ind= [];
% ind= strcmp(data.MSN, MSNopto);
% 
% data= data(ind, :);
% 
% datesNew= unique([data.StartDate{:}]);

% %load the original sheet used by Christelle
% [~,~,DataOG] = xlsread("OptoStimDayAnalysis051121.xlsx");

DataOG= cell2table(DataOG);

DataOG.Properties.VariableNames = DataOG{1,:};

DataOG= DataOG(2:end,:);


% make dictionary like for stimLength lookup by date (again assuming
% stimLength same for all subjects within-date)
stimLengthLookup= table();


stimLengthLookup(:,'Date')= table(unique([DataOG.StartDate{:}]'));

% this is based on christelle's og spreadsheet (note flip between 190828 =
% 1s and 191002 = 0s ... not sure why she did this)
stimLengthLookup(:,'StimLengthRecorded')= table([0,1,10,0,1,10,1,0,10, 0, 1, 10, 20, 0, 1, 10, 20]');


% there are dates that are missing from Christelle's sheet.

%paper records: 190827=0, 190829= 10s

% keep these dates manually review them.
ind= [];
ind= height(stimLengthLookup)+1 : height(stimLengthLookup)+2;

stimLengthLookup(ind,'Date')= table([190827, 190829]');

stimLengthLookup(ind,'StimLengthRecorded')= table([0, 10]');

% Now, add StimLength column to Data table based on dictionary above

% initialize StimLength field
Data(:,"StimLength")= table(nan);%cell(size(Data,1));

%convert StartDate to array for numerical comparison
Data.StartDate= cell2mat(Data.StartDate);

%loop through opto session dates and assign stimLength accordingly
for thisDate= 1:height(stimLengthLookup)

    ind= [];  
    ind= Data.StartDate== stimLengthLookup.Date(thisDate);
    
      
    
    Data(ind, "StimLength")= table(stimLengthLookup.StimLengthRecorded(thisDate));
    
end

% %convert back to cells so works with rest of code?
% Data.StartDate= cell(Data.StartDate);
% Data.StimLength= cell(Data.StimLength);


%- Manual data exclusion/exception for specific subjects in Opto Group 3-- 
%Group 3 had date overlap of normal DS training sessions with group 2's opto sessions 
%group 3 opto sessions shouldn't start until late august 2019 (20190827) 
% exclude dates prior to this (make StimLength = nan)
subjGroup3= {'OM10', 'OM11', 'OM12', 'OM13', 'OP6', 'OP7', 'OP8', 'OP9', 'OV11', 'OV13', 'OV14', 'OM14'};

ind= [];
ind= ismember(Data.Subject, subjGroup3);

ind2= [];
ind2= Data.StartDate < 190827;

ind3= [];
ind3= ind & ind2;

Data(ind3, "StimLength")= table(nan);


%- Manual data exclusion/exception for specific dates in opto group 3-
% % group 3 for unknown reason has 2 test sessions where expected (between DS and lever choice)
% % as well s +2 more test sessions after lever choice... which were included
% % instead of the expected ones in chritelle's sheet. no clear reason why so
% % examine
% 
datesToExclude= [];
datesToExclude= [191002, 191003];

ind=[];
ind= ismember(Data.StartDate, datesToExclude);

Data(ind, "StimLength")= table(nan);


%% --SUBSET data from only opto manipulation stages

% %-'Experiment' field should have notes for laser stim days? - imperfect,
% %relies on user imput and I saw some that I think were left blank
% %search for files with stimulation day .mpc specifically
% 
% %  unique(Data.Experiment(:))
% % experimentStringToFind= {'STIM DAY', 'STIMULATION DAY', 'STIMULATION TEST'};
% 
% 
% % - just use StimLength later on to exclude
% % % Better to use MSN if possible
% % %-' MSN ' field has the MSN used for each session.
% % % unique(Data.MSN);
% % %- seems that 'PulsePal Gated Stimulation' = 10s laser
% % % -seems that 'PulsePal Opto Laser DS Code' = 1s laser
% % msnToInclude= {'PulsePal Opto Laser DS Code', 'PulsePal Gated Stimulation'}
% % 
% % % find index of data rows matching msnToInclude
% % ind= [];
% % ind= ismember(Data.MSN, msnToInclude);
% % 
% % %subset data
% % Data= Data(ind, :);
% 
% % Remove empty data entries (missing Subject)  ? %TODO: Validate, make sure these are
% % actually empty sessions
% ind= [];
% 
% ind= cellfun(@isnan,Data.Subject,'UniformOutput',false);
% 
% ind= ~cellfun(@any,ind);
% 
% Data= Data(ind,:);
% 
% %Remove ses where NumDSCues blank 
% ind= [];
% 
% ind= cellfun(@ischar,Data.NumDSCues,'UniformOutput',false);
% 
% ind= ~cellfun(@any,ind);
% 
% Data= Data(ind,:);
% 
%  
% % Noting another weird empty data entry (82) 
% % DS Cue onsets are all blank...
% % Probably due to macro or something autofilling subject? Search for these
% % and remove also.
% ind= [];
% % ind= Data.NumDSCues>0 %non-zero
% ind= [Data.NumDSCues{:}] >0;
% 
% Data= Data(ind,:);

%% -- Use Christelle's spreadsheet to find StimLength for sessions
% - StimLength seems manually added by Christelle per session in .xlsx
% 
% TODO: Should use another variable to match up correctly...fixed manually for now tho
% 
% initialize StimLength field
% Data{:,"StimLength"}= {nan};%cell(size(Data,1));
% 
% load the original sheet used by Christelle
% [~,~,DataOG] = xlsread("OptoStimDayAnalysis051121.xlsx");
% 
% DataOG= cell2table(DataOG);
% 
% DataOG.Properties.VariableNames = DataOG{1,:};
% 
% DataOG= DataOG(2:end,:);
% 
% get unique subjects & sessions from my sheet for matching
% subjects= unique(Data.Subject);
% 
% dates= unique([Data.StartDate{:}]);
% 
% loop thru unique subj & dates to match up StimLengths between .xlsx sheets
% for subj= 1:numel(subjects)
%     ind= [];
%     ind= strcmp(Data.Subject,subjects{subj});
%     
%     find dates for this subject
%     datesThisSubj= [];
%     datesThisSubj= unique([Data.StartDate{ind}]); 
% 
%     search original spreadsheet for matches
%     for date = 1:numel(datesThisSubj)
%         get data matching this session from OG xlsx
%         indOG= [];
%         
%         indOG= strcmp(DataOG.Subject,subjects{subj});
%         
%         indOG= indOG &  ismember([DataOG.StartDate{:}], datesThisSubj(date))';
%      
%         StimLength= [];
%         StimLength= DataOG.StimLength(indOG);
%         
%         if isempty(StimLength) %if not found, make nan
%             StimLength= {nan};
%         end
%         
%         insert into updated Data on matching session
%         ind=[];
%         ind= strcmp(Data.Subject,subjects{subj});
%         ind= ind &  ismember([Data.StartDate{:}], datesThisSubj(date))';
% 
%         
%         Data{ind, "StimLength"}= StimLength;
%         
% 
%     end
%     
%     
% end
% 
%  Update VsrNames!
%  VarNames= Data.Properties.VariableNames;
%  
 
 
 

 %% Exclude data without StimLength
%  
% ind= [];
% ind= ~isnan([Data.StimLength{:}]);
% 
% %subset data
% Data= Data(ind, :);

%- new post- stimLengthLookup table
ind= [];
ind= ~isnan([Data.StimLength]);

%subset data
Data= Data(ind, :);


%% searching for missing files

%185 sessions in original sheet
%only 142 in mine...

% - diffs
% + OM1
% - multiple subjs test 200121 , 200123
% % 
% datesOG= unique([DataOG.StartDate{:}]);
% datesNew= unique([Data.StartDate{:}]);
% 
% datesMissing= datesOG(~ismember(datesOG,datesNew));

%- new post- StimLengthLookup
datesOG= unique([DataOG.StartDate{:}]);
datesNew= unique([Data.StartDate]);

datesMissing= datesOG(~ismember(datesOG,datesNew));



 
 %% Save this Data set as .xlsx (to compare against orginial)
filename = '_new_Data.xlsx';
% writetable(Data,filename);

%% convert table back to original format (so works with old code)

%update varnames!
VarNames= Data.Properties.VariableNames;


Data=table2cell(Data);




%% Initialize DSStimulation struct to hold data
DSStimulation = struct();

%remove spaces in VarName
VarNames= strrep(VarNames, ' ','');

%dp- seems christelle looped thru 41 simply bc first 41 variables were ones
% she wanted saved into the struct. I left others in.

%for her col 41= 'TotalLaserTrials'

%old- I could get rid of the extra data or just include it all (will do this, shouldn't hurt)
% for me this is col 69

%dp getting rid of extra data cols in spreadsheet.
%now TotalLaserTrials is col 45

for i = 1 :45 %41
    if strcmp(VarNames{i},'Subject') %strcmp=compares string. If the string is 'Subject' then.. 
        DSStimulation.(VarNames{i}) = Data(1:end,(i));
    else
        %dp- seems cell2mat here is used for math computations later on..
        %make exception for strings
        if any(cellfun(@ischar, Data(:,i)))%any(ischar(Data{:,i}))
            DSStimulation.(VarNames{i}) = (Data(1:end,(i)));%cell2mat(Data(1:end,(i)));
        else
            DSStimulation.(VarNames{i}) = cell2mat(Data(1:end,(i)));
        end
    end
end

for i = 1 : size(DSStimulation.Subject,1)
    DSStimulation.Group{i,1} = DSStimulation.Subject{i,1}(1:2);
    DSStimulation.SubjectNum(i,1) = str2double(DSStimulation.Subject{i,1}(3:end));
end

DSColIndex = find(strcmp(strip(VarNames),'DSCueOnset'));
DSStimulation.DSCueOnset = Data(1:end,DSColIndex+1 : DSColIndex + 29); % 30 trials of DS, not sure this is the same as Runbo's?
NSColIndex = find(strcmp(strip(VarNames),'NSCueOnset'));
DSStimulation.NSCueOnset = Data(1:end,NSColIndex : NSColIndex + 29); % Christelle's has 29 trials of NS??

%dp add StimLength field (at end of my data  so search)
ind=[];
ind = find(strcmp(strip(VarNames),'StimLength'));
DSStimulation.StimLength = Data(1:end,ind);
DSStimulation.StimLength= cell2mat(DSStimulation.StimLength);

%DP clearly missing port entries, only getting like 160 PEtimestamps
%this dependence on the row profile is a problem? 
PEColIndexFirst = find(strcmp(strip(VarNames),'PETimestamps'))+1;% the column after this is the column that has data for the timestamps in Christelle data
PEColIndexFinal = find(strcmp(strip(VarNames),'PEDurations')) - 1;
DSStimulation.PETimestamps = Data(1:end,PEColIndexFirst:PEColIndexFinal); % for first 3 groups the largest number of port entry is 674, which is 908 column
LaserColIndex = find(strcmp(strip(VarNames),'LaserTimestamps'));
DSStimulation.LaserTimestamps = Data(1:end,LaserColIndex+1 : LaserColIndex + 30);

%dp add laser status for each trial
DSColIndex = find(strcmp(strip(VarNames),'DSLaserTrialArray'));
DSStimulation.DSLaserTrialArray = Data(1:end,DSColIndex+1 : DSColIndex + 29);
NSColIndex = find(strcmp(strip(VarNames),'NSLaserTrialArray'));
DSStimulation.NSLaserTrialArray = Data(1:end,NSColIndex : NSColIndex + 29); % Christelle's has 29 trials of NS??

    %dp 2022-07-12 error not finding these vars
% medPCDSlatIndex = find(strcmp(strip(VarNames),'medPCDSLat'));
% DSStimulation.medPCDSLat = Data(1:end,medPCDSlatIndex : medPCDSlatIndex + 29); % 30 trials of DS
% medPCNSlatIndex = find(strcmp(strip(VarNames),'medPCNSLat'));
% DSStimulation.medPCNSLat = Data(1:end,medPCNSlatIndex : medPCNSlatIndex + 29); % 30 trials of NS

for i = 1 : length(DSStimulation.Subject)
    ind = strcmp(DSStimulation.Subject{i},ratinfo(:,1));
    DSStimulation.Sex{i,1} = ratinfo{ind,3};
    DSStimulation.Expression{i,1}=ratinfo{ind,6};
    DSStimulation.ExpType{i,1}=ratinfo{ind,5};
    DSStimulation.Projection{i,1}=ratinfo{ind,4};
    DSStimulation.RatID{i,1}=ratinfo{ind,10};    
    DSStimulation.Learner{i,1}=ratinfo{ind,11};  
end


%% ------ Christelle old code -----------
%% Sort into DS vs NS Laser vs No Laser Arrays
DSStimulation.DSCueOnset = cell2mat(DSStimulation.DSCueOnset);% turn the cell arrays into matricies
DSStimulation.NSCueOnset = cell2mat(DSStimulation.NSCueOnset);



for y=1:size(DSStimulation.PETimestamps,1)
    for x=1:size(DSStimulation.PETimestamps,2)
        if ischar(DSStimulation.PETimestamps{y,x})
           DSStimulation.PETimestamps{y,x} = NaN;
        end
    end
end

for y=1:size(DSStimulation.LaserTimestamps,1)
    for x=1:size(DSStimulation.LaserTimestamps,2)
        if ischar(DSStimulation.LaserTimestamps{y,x})
           DSStimulation.LaserTimestamps{y,x} = NaN;
        end
    end
end

DSStimulation.PETimestamps = cell2mat(DSStimulation.PETimestamps);
DSStimulation.LaserTimestamps = cell2mat(DSStimulation.LaserTimestamps);
%%
GroupIndex = 1;
DSStimulation.DSNoLaserArray=NaN(size(DSStimulation.DSCueOnset,1),size(DSStimulation.DSCueOnset,2))
DSStimulation.DSLaserArray=NaN(size(DSStimulation.DSCueOnset,1),size(DSStimulation.DSCueOnset,2))
DSStimulation.NSNoLaserArray=NaN(size(DSStimulation.DSCueOnset,1),size(DSStimulation.DSCueOnset,2))
DSStimulation.NSLaserArray=NaN(size(DSStimulation.DSCueOnset,1),size(DSStimulation.DSCueOnset,2))
%for i = 1 : 2
for j = 1:size(DSStimulation.DSCueOnset,1)
    % DS
    DSNoLaserIndex = 1;
    DSLaserIndex = 1;
    for k = 1 : size(DSStimulation.DSCueOnset,2)
        if isempty(find(DSStimulation.LaserTimestamps(j,:) == DSStimulation.DSCueOnset(j,k), 1))
            DSStimulation.DSNoLaserArray(j,DSNoLaserIndex) = DSStimulation.DSCueOnset(j,k);
            DSNoLaserIndex = DSNoLaserIndex + 1;
        else
            DSStimulation.DSLaserArray(j,DSLaserIndex) = DSStimulation.DSCueOnset(j,k);
            DSLaserIndex = DSLaserIndex + 1;
        end
    end
    % NS
    NSNoLaserIndex = 1;
    NSLaserIndex = 1;
    for k = 1 : size(DSStimulation.NSCueOnset,2)
        
        if isempty(find(DSStimulation.LaserTimestamps(j,:) == DSStimulation.NSCueOnset(j,k), 1))
            DSStimulation.NSNoLaserArray(j,NSNoLaserIndex) = DSStimulation.NSCueOnset(j,k);
            NSNoLaserIndex = NSNoLaserIndex + 1;
        else
            DSStimulation.NSLaserArray(j,NSLaserIndex) = DSStimulation.NSCueOnset(j,k);
            NSLaserIndex = NSLaserIndex + 1;
        end
    end
end
%end

 
%% todo: dp check stimLength observations by subj 


% convert to table to use table functions
data= struct2table(DSStimulation);

% if not assigning back into table, groupsummary() is sufficient
%groupby subject, laserDur, trialType

grouped=[];
grouped= groupsummary(data, ["Subject", "MSN", "StimLength"]);

% groupedFlagged= grouped(grouped.GroupCount>1,:)



%% Calculate trial-by-trial PE latencies for DS and NS


for i =  1 : size(DSStimulation.DSLaserArray,1)
    for j = 1 : size(DSStimulation.DSLaserArray,2)
        if ~isnan(DSStimulation.DSLaserArray(i,j)) && DSStimulation.DSLaserArray(i,j) > 0  %&& DSStimulation.medpcDSLat{i,j} > 0.01 % anything that is not a NaN and greater than zero and the latency is greater than 0.01 continues on in the loop
            curDS = DSStimulation.DSLaserArray(i,j); % if all that was true then current DS= the (i,j) cell
            nextDS = DSStimulation.DSCueOnset(i,find(DSStimulation.DSCueOnset(i,:) > curDS,1)); % next DS will be in the same row and the first element that is greater than the curDS in the i row of every column
            nextNS = DSStimulation.NSCueOnset(i,find(DSStimulation.NSCueOnset(i,:) > curDS,1)); % next NS will be in the same row and the first element that is greater than the curDS in variable NSCueOnset
            if ~isempty(nextDS) && ~isempty(nextNS)%if next DS is not empty and next NS is not empty nextcue is the smallest value of the two elements it is comparing
            nextCue = min(nextDS,nextNS);
            elseif isempty(nextDS) && ~isempty(nextNS) % no DS left
                nextCue = nextNS;
            elseif isempty(nextNS) && ~isempty(nextDS) % no NS left
                nextCue = nextDS;
            else % no cue left
                nextCue = inf;%inf is infinity, don't know why?
            end
            curDSDuration = 10; %match up the tone duration location for the current DS with the i location
            firstEnter = DSStimulation.PETimestamps(i,find(DSStimulation.PETimestamps(i,:) > curDS & DSStimulation.PETimestamps(i,:) < nextCue,1 ));% identify when animal first entered by finding the 
            %first element of PETimestamps that is greater than the curDS
            %and less than the next cue
            if isempty(firstEnter)% if the first enter variable is an empry vector than the latencies are NaN
                DSStimulation.DSLaserRelLatency(i,j) = NaN;
                DSStimulation.DSLaserAbsLatency(i,j) = NaN;
                DSStimulation.DSLaser10sResponse(i,j) = 0;
            elseif firstEnter - curDS > curDSDuration % otherwise if the time of first entering-curDS cue time is greater than the DS duration the absolute latencey is the difference between the DScue and the PEtime
                DSStimulation.DSLaserRelLatency(i,j) = NaN;
                DSStimulation.DSLaser10sResponse(i,j) = 0;
                DSStimulation.DSLaserAbsLatency(i,j) = firstEnter - curDS;              
            elseif firstEnter - curDS < curDSDuration % otherwise if the difference between the DS and PE times is less than the duration of the cue (entered during the cue), both the relative and absolute latency is equal to that difference
                DSStimulation.DSLaserRelLatency(i,j) = firstEnter - curDS;
                DSStimulation.DSLaserAbsLatency(i,j) = firstEnter - curDS;
                if firstEnter - curDS <= 10
                    DSStimulation.DSLaser10sResponse(i,j) = 1;
                else
                    DSStimulation.DSLaser10sResponse(i,j) = 0;
                end
            end
        else
            DSStimulation.DSLaserRelLatency(i,j) = NaN; % if the DS cue onset is Nan, equal to zero or the medPC reads the latency as 0.01 then assign these cells a NaN value
            DSStimulation.DSLaserAbsLatency(i,j) = NaN;%  WANT TO CHANGE THIS EVENTUALLY TO HAVE RESPONSE VARIABLES!!
            DSStimulation.DSLaser10sResponse(i,j) = NaN;
        end        
    end
end


% NS Laser latency calcualtion
for i = 1 : size(DSStimulation.NSLaserArray,1)
    for j = 1 : size(DSStimulation.NSLaserArray,2)
        if ~isnan(DSStimulation.NSLaserArray(i,j)) && DSStimulation.NSLaserArray(i,j) > 0 %&& TrainingData.medpcNSLat{i,j} > 0.01
            curNS = DSStimulation.NSLaserArray(i,j);
            nextNS = DSStimulation.NSCueOnset(i,find(DSStimulation.NSCueOnset(i,:) > curNS,1));
            nextDS = DSStimulation.DSCueOnset(i,find(DSStimulation.DSCueOnset(i,:) > curNS,1));
            if ~isempty(nextDS) && ~isempty(nextNS) 
                nextCue = min(nextDS,nextNS);
            elseif isempty(nextDS) && ~isempty(nextNS) % no DS left
                nextCue = nextNS;
            elseif isempty(nextNS) && ~isempty(nextDS) % no NS left
                nextCue = nextDS;
            else % no cue left
                nextCue = inf;
            end
            curNSDuration = 10; % NS always last 10 s
            firstEnter = DSStimulation.PETimestamps(i,find(DSStimulation.PETimestamps(i,:) > curNS & DSStimulation.PETimestamps(i,:) < nextCue,1 ));
            if isempty(firstEnter)
                DSStimulation.NSLaserRelLatency(i,j) = NaN;
                DSStimulation.NSLaserAbsLatency(i,j) = NaN;  
                DSStimulation.NSLaser10sResponse(i,j) = 0;
            elseif firstEnter - curNS > curNSDuration
                DSStimulation.NSLaserRelLatency(i,j) = NaN;
                DSStimulation.NSLaserAbsLatency(i,j) = firstEnter - curNS; 
                DSStimulation.NSLaser10sResponse(i,j) = 0;
            elseif firstEnter - curNS < curNSDuration
                DSStimulation.NSLaserRelLatency(i,j) = firstEnter - curNS;
                DSStimulation.NSLaserAbsLatency(i,j) = firstEnter - curNS;
                DSStimulation.NSLaser10sResponse(i,j) = 1;
            end
        else
            DSStimulation.NSLaserRelLatency(i,j) = NaN;
            DSStimulation.NSLaserAbsLatency(i,j) = NaN;
            DSStimulation.NSLaser10sResponse(i,j) = NaN;
        end
    end
end

DSStimulation.DSLaserRelLatMean = nanmean(DSStimulation.DSLaserRelLatency,2);
DSStimulation.DSLaserAbsLatMean = nanmean(DSStimulation.DSLaserAbsLatency,2);
DSStimulation.DSLaser10sResponseProb = nanmean(DSStimulation.DSLaser10sResponse,2);
DSStimulation.NSLaser10sResponseProb = nanmean(DSStimulation.NSLaser10sResponse,2);
DSStimulation.NSLaserRelLatMean = nanmean(DSStimulation.NSLaserRelLatency,2);% removing nan values and calculating the NSRelLatMean across columns
DSStimulation.NSLaserAbsLatMean = nanmean(DSStimulation.NSLaserAbsLatency,2);% removing nan values and calculating the DSRelLatMean across columns
%% No laser DS latency calculation

for i =  1 : size(DSStimulation.DSNoLaserArray,1)
    for j = 1 : size(DSStimulation.DSNoLaserArray,2)
        if ~isnan(DSStimulation.DSNoLaserArray(i,j)) && DSStimulation.DSNoLaserArray(i,j) > 0  %&& DSStimulation.medpcDSLat{i,j} > 0.01 % anything that is not a NaN and greater than zero and the latency is greater than 0.01 continues on in the loop
            curDS = DSStimulation.DSNoLaserArray(i,j); % if all that was true then current DS= the (i,j) cell
            nextDS = DSStimulation.DSCueOnset(i,find(DSStimulation.DSCueOnset(i,:) > curDS,1)); % next DS will be in the same row and the first element that is greater than the curDS in the i row of every column
            nextNS = DSStimulation.NSCueOnset(i,find(DSStimulation.NSCueOnset(i,:) > curDS,1)); % next NS will be in the same row and the first element that is greater than the curDS in variable NSCueOnset
            if ~isempty(nextDS) && ~isempty(nextNS)%if next DS is not empty and next NS is not empty nextcue is the smallest value of the two elements it is comparing
            nextCue = min(nextDS,nextNS);
            elseif isempty(nextDS) && ~isempty(nextNS) % no DS left
                nextCue = nextNS;
            elseif isempty(nextNS) && ~isempty(nextDS) % no NS left
                nextCue = nextDS;
            else % no cue left
                nextCue = inf;%inf is infinity, don't know why?
            end
            curDSDuration = 10; %match up the tone duration location for the current DS with the i location
            firstEnter = DSStimulation.PETimestamps(i,find(DSStimulation.PETimestamps(i,:) > curDS & DSStimulation.PETimestamps(i,:) < nextCue,1 ));% identify when animal first entered by finding the 
            %first element of PETimestamps that is greater than the curDS
            %and less than the next cue
            if isempty(firstEnter)% if the first enter variable is an empry vector than the latencies are NaN
                DSStimulation.DSNoLaserRelLatency(i,j) = NaN;
                DSStimulation.DSNoLaserAbsLatency(i,j) = NaN;
                DSStimulation.DSNoLaser10sResponse(i,j) = 0;
            elseif firstEnter - curDS > curDSDuration % otherwise if the time of first entering-curDS cue time is greater than the DS duration the absolute latencey is the difference between the DScue and the PEtime
                DSStimulation.DSNoLaserRelLatency(i,j) = NaN;
                DSStimulation.DSNoLaser10sResponse(i,j) = 0;
                DSStimulation.DSNoLaserAbsLatency(i,j) = firstEnter - curDS;              
            elseif firstEnter - curDS < curDSDuration % otherwise if the difference between the DS and PE times is less than the duration of the cue (entered during the cue), both the relative and absolute latency is equal to that difference
                DSStimulation.DSNoLaserRelLatency(i,j) = firstEnter - curDS;
                DSStimulation.DSNoLaserAbsLatency(i,j) = firstEnter - curDS;
                if firstEnter - curDS <= 10
                    DSStimulation.DSNoLaser10sResponse(i,j) = 1;
                else
                    DSStimulation.DSNoLaser10sResponse(i,j) = 0;
                end
            end
        else
            DSStimulation.DSNoLaserRelLatency(i,j) = NaN; % if the DS cue onset is Nan, equal to zero or the medPC reads the latency as 0.01 then assign these cells a NaN value
            DSStimulation.DSNoLaserAbsLatency(i,j) = NaN;%  WANT TO CHANGE THIS EVENTUALLY TO HAVE RESPONSE VARIABLES!!
            DSStimulation.DSNoLaser10sResponse(i,j) = NaN;
        end        
    end
end

% No laser NS latency calcualtion
for i = 1 : size(DSStimulation.NSNoLaserArray,1)
    for j = 1 : size(DSStimulation.NSNoLaserArray,2)
        if ~isnan(DSStimulation.NSNoLaserArray(i,j)) && DSStimulation.NSNoLaserArray(i,j) > 0 %&& TrainingData.medpcNSLat{i,j} > 0.01
            curNS = DSStimulation.NSNoLaserArray(i,j);
            nextNS = DSStimulation.NSCueOnset(i,find(DSStimulation.NSCueOnset(i,:) > curNS,1));
            nextDS = DSStimulation.DSCueOnset(i,find(DSStimulation.DSCueOnset(i,:) > curNS,1));
            if ~isempty(nextDS) && ~isempty(nextNS) 
                nextCue = min(nextDS,nextNS);
            elseif isempty(nextDS) && ~isempty(nextNS) % no DS left
                nextCue = nextNS;
            elseif isempty(nextNS) && ~isempty(nextDS) % no NS left
                nextCue = nextDS;
            else % no cue left
                nextCue = inf;
            end
            curNSDuration = 10; % NS always last 10 s
            firstEnter = DSStimulation.PETimestamps(i,find(DSStimulation.PETimestamps(i,:) > curNS & DSStimulation.PETimestamps(i,:) < nextCue,1 ));
            if isempty(firstEnter)
                DSStimulation.NSNoLaserRelLatency(i,j) = NaN;
                DSStimulation.NSNoLaserAbsLatency(i,j) = NaN;  
                DSStimulation.NSNoLaser10sResponse(i,j) = 0;
            elseif firstEnter - curNS > curNSDuration
                DSStimulation.NSNoLaserRelLatency(i,j) = NaN;
                DSStimulation.NSNoLaserAbsLatency(i,j) = firstEnter - curNS; 
                DSStimulation.NSNoLaser10sResponse(i,j) = 0;
            elseif firstEnter - curNS < curNSDuration
                DSStimulation.NSNoLaserRelLatency(i,j) = firstEnter - curNS;
                DSStimulation.NSNoLaserAbsLatency(i,j) = firstEnter - curNS;
                DSStimulation.NSNoLaser10sResponse(i,j) = 1;
            end
        else
            DSStimulation.NSNoLaserRelLatency(i,j) = NaN;
            DSStimulation.NSNoLaserAbsLatency(i,j) = NaN;
            DSStimulation.NSNoLaser10sResponse(i,j) = NaN;
        end
    end
end

DSStimulation.DSNoLaserRelLatMean = nanmean(DSStimulation.DSNoLaserRelLatency,2);
DSStimulation.DSNoLaserAbsLatMean = nanmean(DSStimulation.DSNoLaserAbsLatency,2);
DSStimulation.DSNoLaser10sResponseProb = nanmean(DSStimulation.DSNoLaser10sResponse,2);
DSStimulation.NSNoLaser10sResponseProb = nanmean(DSStimulation.NSNoLaser10sResponse,2);
DSStimulation.NSNoLaserRelLatMean = nanmean(DSStimulation.NSNoLaserRelLatency,2);% removing nan values and calculating the NSRelLatMean across columns
DSStimulation.NSNoLaserAbsLatMean = nanmean(DSStimulation.NSNoLaserAbsLatency,2);% removing nan values and calculating the DSRelLatMean across columns

%%Calculate DS/NS Ratio
DSStimulation.DSNSRatio=DSStimulation.DSPERatio./DSStimulation.NSPERatio

%% Reformat data for plots

%seems cuetype here is simply associated with data by order of cat()
%together of individual trial types DS, DS+Laser, NS, NS+Laser= [1,2,3,4]

CueType=vertcat(ones([length(DSStimulation.Subject) 1]),2.*ones([length(DSStimulation.Subject) 1]),3.*ones([length(DSStimulation.Subject) 1]),4.*ones([length(DSStimulation.Subject) 1])); 
RelLatency=vertcat(DSStimulation.DSNoLaserRelLatMean,DSStimulation.DSLaserRelLatMean,DSStimulation.NSNoLaserRelLatMean,DSStimulation.NSLaserRelLatMean);
ResponseProb=vertcat(DSStimulation.DSNoLaser10sResponseProb,DSStimulation.DSLaser10sResponseProb,DSStimulation.NSNoLaser10sResponseProb,DSStimulation.NSLaser10sResponseProb);
StimLength=vertcat(DSStimulation.StimLength,DSStimulation.StimLength,DSStimulation.StimLength,DSStimulation.StimLength);
Group=vertcat(DSStimulation.Group,DSStimulation.Group,DSStimulation.Group,DSStimulation.Group);
Subject=vertcat(DSStimulation.Subject,DSStimulation.Subject,DSStimulation.Subject,DSStimulation.Subject);
RatID=vertcat(DSStimulation.RatID,DSStimulation.RatID,DSStimulation.RatID,DSStimulation.RatID);

Sex=vertcat(DSStimulation.Sex,DSStimulation.Sex,DSStimulation.Sex,DSStimulation.Sex);
Expression=vertcat(DSStimulation.Expression,DSStimulation.Expression,DSStimulation.Expression,DSStimulation.Expression);
Mode=vertcat(DSStimulation.ExpType,DSStimulation.ExpType,DSStimulation.ExpType,DSStimulation.ExpType);
DSRatio=vertcat(DSStimulation.DSPERatio,DSStimulation.DSPERatio,DSStimulation.DSPERatio,DSStimulation.DSPERatio);
DSNSRatio=vertcat(DSStimulation.DSNSRatio,DSStimulation.DSNSRatio,DSStimulation.DSNSRatio,DSStimulation.DSNSRatio);
Learner=vertcat(DSStimulation.Learner,DSStimulation.Learner,DSStimulation.Learner,DSStimulation.Learner);

Projection= vertcat(DSStimulation.Projection, DSStimulation.Projection, DSStimulation.Projection, DSStimulation.Projection);

StartDate= vertcat(DSStimulation.StartDate, DSStimulation.StartDate, DSStimulation.StartDate, DSStimulation.StartDate);


Learner=cell2mat(Learner);
Expression=cell2mat(Expression);
Mode=cell2mat(Mode);
RatID= cell2mat(RatID);
% Subject=cell2mat(Subject);



%dp add cueType label
% make list of labels and use values for cueType as ind to match
labels= {};
labels= {'DS','DS+Laser','NS','NS+Laser'};

CueTypeLabel=[];
CueTypeLabel= {labels{CueType(:)}}';


%% DP Subset data for vp--> vta group only
% 
% ind=[];
% % ind= ~(DSStimulation.Projection==1);
% ind= ~strcmp(DSStimulation.Projection, 'VTA');
% 
% %loop thru fields and eliminate data
% allFields= fieldnames(DSStimulation);
% for field= 1:numel(allFields)
%     DSStimulation.(allFields{field})(ind)= [];
% end
% 
% 
% ind=[];
% % ind= ~(DSStimulation.Projection==1);
% ind= strcmp(Group, 'OV');
% 
% 
% %eliminate data
% Group= Group(ind);
% CueType= CueType(ind);
% RelLatency=RelLatency(ind);
% ResponseProb= ResponseProb(ind);
% StimLength=StimLength(ind);
% Subject= Subject(ind);
% Sex= Sex(ind);
% Expression= Expression(ind);
% Mode= Mode(ind);
% DSRatio= DSRatio(ind);
% DSNSRatio= DSNSRatio(ind);
% Learner= Learner(ind);
% CueTypeLabel= CueTypeLabel(ind);


%% dp reorganizing data into table for table fxns and easy faceting

stimTable= table();

%list of vars to include in table as columns
tableVars= {'Group','CueType','CueTypeLabel','RelLatency','ResponseProb'...
    'StimLength','Subject','Sex','Expression','Mode','DSRatio','DSNSRatio','Learner','Projection','RatID', 'StartDate'};



%loop thru vars and fill table
allVars= tableVars;
for var= 1:numel(allVars)
    stimTable.(allVars{var})= eval(tableVars{var});
end

%dp split CueType into 2 variables: 1 for cue type (simple DS v NS) and 1 for laser state
%- simply subsetting and manually assigning instead of fancy table transform fxns
stimTable(:,"CueID")= {''}; %preassign
stimTable(:,"LaserTrial")= {''};
 
% make list of labels and use values for cueType as ind to match
labels= {};
labels= {'DS', 'DS', 'NS', 'NS'};

stimTable(:,"CueID")= {labels{CueType(:)}}';

%repeat for LaserTrial var
labels= {'noLaser', 'Laser', 'noLaser', 'Laser'};

stimTable(:,"LaserTrial")= {labels{CueType(:)}}';

%dp add expType label for virus type, Mode (Excitation/Inhibition)
% expType= [0,1]%
expTypesAll= [0,1];
% %1= excitation, 0= inhibition
expTypeLabels= {'inhibition','stimulation'};

%loop thru and assign labels
for thisExpType= 1:numel(expTypesAll)
    
    %2022-11-09
    %TODO: need to match the labels up actually with expType...
%     ind= [];
%     ind= expTypeLabels
%     
    ind= [];
    ind= stimTable.Mode==expTypesAll(thisExpType);
    
    stimTable(ind, "virusType")= expTypeLabels(thisExpType);
    
%     stimTable(:,"virusType")= expTypeLabels(thisExpType);
    
    %todo- doesnt match with 'mode'
%     stimTable(:,"ExpType")= table(expTypesAll(thisExpType)); %binary 0 or 1 for consistency w other scripts
    
end


%DP converting "Group" to "Projection" label for consistency between analyses scripts/figures



% TODO: may be good to add fileID
% %actually GROUP should = fileID? since observations paired by group within-file
% data(:,"fileID")= table(nan);
% data(:,"fileID")= table([1:size(data,1)]');
% 
% group= data.fileID;

% %% DP check for duplicate sessions
% 
% %if there are duplicate sessions, then the # of unique groupIDsUnique would be >
% %than the size of of each variable in DSStimulation
% 
% numSessions= numel(DSStimulation.Subject);
% 
% groupIDs= [];
% % ------dp stimTable has the 4x repeats for trialtypes so try running on
% % DSStimulation?
% groupIDs= findgroups(DSStimulation.Subject,DSStimulation.StartDate);
% 
% groupIDsUnique= [];
% groupIDsUnique= unique(groupIDs);
% 
% %compare for equality
% numSessions==numel(groupIDsUnique)
% 
% %todo: duplicates are present, so find them:
% 
% %method a
% [uniqueA i j] = unique(groupIDs,'first');
% indexToDupes = find(not(ismember(1:numel(groupIDs),i)))
% 
% 
% %method b
% [U, I] = unique(groupIDs, 'first');
% x = 1:length(groupIDs); 
% %go through each value and retain only the first (I)
% x(I) = []; %groupIDs remaining, which are duplicates
% 
% dupes= table()
% for thisGroupID= 1:numel(indexToDupes)
%  
%     %for each groupID, find index matching groupID
%     ind= [];
%     ind= find(groupIDs==groupIDsUnique(thisGroupID));
%     
%     %for each groupID, get the table data matching this group
%     thisGroup=[];
%     thisGroup= stimTable(ind,:);
%     
%     %save to table?
%     dupes(ind,:)= thisGroup;
%    
% end


%% DP- Find duplicate sessions in spreadsheet
% find duplicate sessions?


% convert to table to use table functions
data= struct2table(DSStimulation);


% convert to table to use table functions
data= struct2table(DSStimulation);

groupIDs= [];

% data.StartDate= cell2mat(data.StartDate);
groupIDs= findgroups(data.Subject, data.StartDate);

groupIDsUnique= [];
groupIDsUnique= unique(groupIDs);

%table to collect duplicate flagged sessions
dupes =table();

for thisGroupID= 1:numel(groupIDsUnique)
    %for each groupID, find index matching groupID
    ind= [];
    ind= find(groupIDs==groupIDsUnique(thisGroupID));
    
    %for each groupID, get the table data matching this group
    thisGroup=[];
    thisGroup= data(ind,:);

    % Check if >1 observation here in group
    % if so, flag for review
    if height(thisGroup)>1
       disp('duplicate ses found!')
        dupes(ind, :)= thisGroup;

    end
    
end 

%subset only nonzero startdates for concise view , lazy
if ~isempty(dupes)
    dupes= dupes(dupes.StartDate~=0,:);
end


%% Behavioral Criteria plots

criteriaDS= 0.6; %require at least 60% responding to DS


criteriaDSNS= 1.5;  %require 50% more responding to DS than NS


%histogram to determine which animals learned

%- histogram of NS PE Ratio calculated by MPC

%subset only laser days
selection= DSStimulation.StimLength==0 
learn= DSStimulation.NSPERatio(selection)
animal= DSStimulation.Subject (selection)
BinNums = [0:.1:1]

figure(); subplot(3,1,1);
histogram (learn, BinNums)
title('NS PE ratio, pre-stim sessions');

%subplot DS NS and NS/DS Ratio
y2= [];
y2= DSStimulation.DSPERatio(selection);
subplot(3,1,2); hold on; title('DS PE ratio, pre-stim sessions');
histogram (y2, BinNums)
plot([criteriaDS, criteriaDS], ylim, 'r--'); %DS criteria overlay


y3=[];
y3= DSStimulation.DSNSRatio(selection);
subplot(3,1,3); hold on; title('DS/NS PE Ratio, pre-stim sessions');


BinNums = [0:.1:5];

histogram (y3, BinNums)
plot([criteriaDSNS, criteriaDSNS],ylim, 'r--'); %DS/NS criteria overlay


figTitle=('DStask-behavior-distribution- pre-stim PE ratios');
saveFig(gcf, figPath,figTitle,figFormats);

%scatter of DS vs DS/NS
figure(); hold on;
scatter(y2,y3);
%overlay criteria
plot([criteriaDS, criteriaDS], ylim, 'r--'); %DS criteria overlay
plot(xlim,[criteriaDSNS, criteriaDSNS], 'r--'); %DS/NS criteria overlay
title('DS vs DS/NS Ratio')

figTitle=('DStask-behavior-scatter- pre-stim PE ratios');
saveFig(gcf, figPath,figTitle,figFormats);


%- plot ratio being used here

%- histogram of 10s NS PE Ratio
% histogram of NS PE Ratio calculated by MPC
selection= DSStimulation.StimLength==0;
learn= DSStimulation.NSNoLaser10sResponseProb(selection);
animal= DSStimulation.Subject (selection);
BinNums = [0:.1:1];

figure(); subplot(3,1,1);
histogram (learn, BinNums)
title('NS 10s PE ratio, pre-stim sessions');

%subplot DS NS and NS/DS Ratio
y2= [];
y2= DSStimulation.DSNoLaser10sResponseProb(selection);
subplot(3,1,2); hold on; title('DS 10s PE ratio, pre-stim sessions');
histogram (y2, BinNums)
plot([criteriaDS, criteriaDS], ylim, 'r--'); %DS criteria overlay


%calculate the 'no laser' NSDS ratio?
DSStimulation.DSNS10sNoLaserRatio= DSStimulation.DSNoLaser10sResponseProb./DSStimulation.NSNoLaser10sResponseProb;

y3=[];
y3= DSStimulation.DSNS10sNoLaserRatio(selection);

BinNums = [0:.1:5];


subplot(3,1,3); hold on; title('DS/NS 10s PE Ratio, pre-stim sessions');
histogram (y3, BinNums)
plot([criteriaDSNS, criteriaDSNS],ylim, 'r--'); %DS/NS criteria overlay

figTitle=('DStask-behavior-distribution- pre-stim 10s PE ratios');
saveFig(gcf, figPath,figTitle,figFormats);


figure(); hold on;
scatter(y2,y3);
%overlay criteria
plot([criteriaDS, criteriaDS], ylim, 'r--'); %DS criteria overlay
plot(xlim,[criteriaDSNS, criteriaDSNS], 'r--'); %DS/NS criteria overlay
title('10s DS vs DS/NS Ratio')

figTitle=('DStask-behavior-scatter- pre-stim 10s PE ratios');
saveFig(gcf, figPath,figTitle,figFormats);


% subset

%TODO 
%ds/ns ratio

% DSStimulation.DSNSRatio=DSStimulation.DSPERatio./DSStimulation.NSPERatio




%Now -subset those subjects meeting criteria 
% criteriaDS= 0.6
% criteriaNS= 0.5
% 
% selection2 = DSStimulation.DSPERatio(selection) >= criteriaDS & DSStimulation.NSPERatio(selection) <= criteriaNS
% learned= DSStimulation.Subject (selection2) 

%% dp EXCLUDE SUBJECTS based on behavioral criteria
% modeExcludeBehavioral= 'DS'; %exclude based on DS ratio alone

modeExcludeBehavioral= 'DS & DS/NS'; %exclude based on DS/NS discrimination 

% %1- subset data from pre-laser days
% %2- check if meeting criteria
% %3- if not, record the subject names
% %4- exclude these subjects from table 


%1- subset on pre-laser days
ind= [];
ind= stimTable.StimLength==0;

data= [];
data= stimTable(ind,:);


%2- check if meet criteria
if strcmp(modeExcludeBehavioral, 'DS & DS/NS') %run based on both criteria
    
    ind= [];
    ind= (data.DSRatio <= criteriaDS) & (data.DSNSRatio <= criteriaDSNS);
    
  
elseif strcmp(modeExcludeBehavioral, 'DS') %run based on DS responding alone
    
    ind= [];
    ind= (data.DSRatio <= criteriaDS); 
    
end

%3- find subjects not meeting criteria
subjectsToExclude= {};
subjectsToExclude= data(ind,'Subject'); 


%4- actually exclude data from table
%find data containing subjectsToExclude and remove
ind= [];

ind= contains(stimTable.Subject, subjectsToExclude{:,:});

stimTable(ind,:)= [];

%% DP SAVE DATA TO RELOAD AND MAKE MANUSCRIPT FIGS
save(fullfile(figPath,strcat('VP-OPTO-DStaskTest','-',date, '-stimTable')), 'stimTable', '-v7.3');


%% dp compute N- Count of subjects by sex for each group

for thisExpType= 1:numel(expTypesAll)

    thisExpTypeLabel= expTypeLabels{thisExpType};

    %subset data- by expType/virus
    ind=[];
    ind= stimTable.Mode==expTypesAll(thisExpType);

    data= stimTable(ind,:);

    %subset data- by expression & behavioral criteria
    ind=[];
    ind= data.Expression>0 & data.Learner==1;

    data= data(ind,:);


    nTable= table;

   
    %initialize variable for cumcount of subjects
    data(:,"cumcountSubj")= table(nan);
    
    %- now limit to one unique subject observation within this subset
    %(findGroups)
    

    groupIDs= [];

    groupIDs= findgroups(data.Projection,data.Sex, data.Subject);

    groupIDsUnique= [];
    groupIDsUnique= unique(groupIDs);

    for thisGroupID= 1:numel(groupIDsUnique)

        %for each groupID, find index matching groupID
        ind= [];
        ind= find(groupIDs==groupIDsUnique(thisGroupID));

        %for each groupID, get the table data matching this group
        thisGroup=[];
        thisGroup= data(ind,:);

        %now cumulative count of observations in this group
        %make default value=1 for each, and then cumsum() to get cumulative count
        thisGroup(:,'cumcount')= table(1);
        thisGroup(:,'cumcount')= table(cumsum(thisGroup.cumcount));    
        
        %assign cumulative count for this subject's sessions back to data
        %table, this will be used to limit to first observation only for
        %count of unique subjects
        data(ind,"cumcountSubject")= thisGroup(:,'cumcount');
        
    end
    
    %- finally subset to 1 row per subject and count this data
    ind=[];
    ind= data.cumcountSubject==1;
    
    data= data(ind,:);
    
    nTable= groupsummary(data, ["Mode","Projection","Sex"]);
       
    %- save this along with figures
    titleFile= [];
    titleFile= strcat(thisExpTypeLabel,'-N-subjects');

    %save as .csv
    titleFile= strcat(figPath,titleFile,'.csv');
    
    writetable(nTable,titleFile)

end

% counting n observations / sessions per condition

data= stimTable;

%subset data- by expression & behavioral criteria
ind=[];
ind= data.Expression>0 & data.Learner==1;

data= data(ind,:);


test=[];
test= groupsummary(data, ["Subject", "StimLength", "CueID", "LaserTrial"]);

test2= groupsummary(data, ["virusType",  "Group", "StimLength", "CueType"]);
    


%% Plot Stim Day 0

%--- note this is plotting subjects meeting only specific criteria 

%Latency
figure; clear g; 
selection= Mode==1 & Expression==1 & StimLength==0 & DSRatio > 0.4 & DSNSRatio >1.5 
g=gramm('x',Group(selection),'y',RelLatency(selection),'color',CueType(selection))
g.stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}) 
g.set_names('x','Projections','y','Latency')
g.set_title('Pre Stim Day Latency')
g.draw()


figTitle= 'pre_stimulation_day_peLatency';

saveFig(gcf, figPath,figTitle,figFormats);


%Probability 
figure; clear g;
selection= Mode==1 & Expression==1 & StimLength==0 & DSRatio > 0.4 & DSNSRatio >1.5
g=gramm('x',Group(selection),'y',ResponseProb(selection),'color',CueType(selection))
g.stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'})
g.set_names('x','Projections','y','Probability')
g.set_title('Pre Stim Day Probability')
g.draw()

SubjMetCriteria=unique(Subject(selection))


figTitle= 'pre_stimulation_day_peProb';

saveFig(gcf, figPath,figTitle,figFormats);


%% Plot Stim Days - OG Christelle
%%Stimulation Latency

figure; clear g; 
selection= Mode==1 & Expression==1 & Learner==1 
g(1,1)=gramm('x',Group(selection),'y',RelLatency(selection),'color',CueType(selection))
g(1,1).stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}) 

g(1,1).facet_grid([],StimLength(selection))
g(1,1).set_names('x','Projections','y','Latency')
g(1,1).set_title('Stim Laser Day Latency')
g.draw()

%%Stimulation Probability

selection= Mode==1 & Expression==1 & Learner==1 
g(2,1)=gramm('x',Group(selection),'y',ResponseProb(selection),'color',CueType(selection))
g(2,1).stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'})
g(2,1).facet_grid([],StimLength(selection))
g(2,1).set_names('x','Projections','y','Probability')
g(2,1).set_title('Stim Laser Day Probability')
g(2,1).no_legend()
g.draw()
% g.export('file_name','Stimulation Day Data','export_path','/Volumes/nsci_richard/Christelle/Data/Opto Project/Figures','file_type','pdf') 

figTitle= 'stimulation_day_data_ogPlot'

saveFig(gcf, figPath,figTitle,figFormats);


%% Plot Stim Days - dp new with table

% made virus Group a subplot facet instead of X in order to appropriately
% pair individual subject observations with lines. If you don't want the
% lines you can use the x=Group plots. I think that x= Group doens't work
% for pointplot since geom_line probably needs 1 observation per X value?
    %maybe would work if made group=observationID (combo of multiple
    %groupers)
%TODO: find way to connect individual subj points when an Xvalue /category is
%skipped. (in this case no laser trials on non-laser days.) could fill with
%0 but would like to remain nan.

%- also subfaceting of Latency v Probability wasn't working at some point
%to left to separate figures

%dp 2022-10-03 add expType loop for inhibition and stim group plotting


%plot default settings 
 %if only 2 groupings, brewer2 and brewer_dark work well 
% cmapGrand= 'brewer_dark';
% cmapSubj= 'brewer2';
cmapGrand= cmapCueLaserGrand;
cmapSubj= cmapCueLaserSubj;


dodge= 	1; %if dodge constant between point and bar, will align correctly
width=3.5; %good for bar w dodge >=1



for thisExpType= 1:numel(expTypesAll)

    thisExpTypeLabel= expTypeLabels{thisExpType};

    %subset data- by expType/virus
    ind=[];
    ind= stimTable.Mode==expTypesAll(thisExpType);

    data0= stimTable(ind,:);

    %%Stimulation Latency
    clear g;
    figure; 

    %subset data- by expression & behavioral criteria
    ind=[];
    ind= data0.Expression>0 & data0.Learner==1;

    data= data0(ind,:);

    % -- 1 = subplot of stimulation PE latency
    %- Bar of btwn subj means (group = [] or Group)
    group= []; %var by which to group

    % dp changing faceting- x cueType so can connect dots and facet by virus Group as rows

    g=gramm('x',data.CueType,'y',data.RelLatency,'color',data.CueTypeLabel, 'group', group);
    g.facet_grid(data.Projection,data.StimLength)

    % g(1,1).stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}) 
    % g(1,1).stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}, 'dodge', dodge) 
    % g(1,1).stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'},'width',width) 

    g.stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}, 'dodge', dodge,'width',width) 


    g(1,1).set_color_options('map',cmapGrand); 

    g(1,1).set_names('x','Cue Type','y','Latency', 'column', 'StimLength length')
    
    
    figTitle= strcat(thisExpTypeLabel,'-','Laser Day Latency');   
    g(1,1).set_title(figTitle);

    g.set_text_options(text_options_DefaultStyle{:}); 

    g.draw();


    %- Draw lines between individual subject points (group= subject, color=[]);

    group= data.Subject;

    g(1,1).update('x', data.CueType,'y',data.RelLatency,'color',[], 'group', group)

     %here specifically multiple observations
    % per subject so using stat_summary to get mean line
    g(1,1).stat_summary('type','sem','geom',{'line'});
    % g(1,1).geom_line;%('alpha',0.3);

    g(1,1).set_line_options('base_size',linewidthSubj);

    g(1,1).set_color_options('chroma', chromaLineSubj); %black lines connecting points

    %set x lims and ticks (a bit more manual good for bars)
    lims= [min(data.CueType)-.6,max(data.CueType)+.6];

    g.axe_property('XLim',lims);
    g.axe_property('XTick',round([lims(1):1:lims(2)]));



    g.draw();


    %- Update with point of individual subj points (group= subject)
    group= data.Subject;
    g(1,1).update('x',data.CueType,'y',data.RelLatency,'color',data.CueTypeLabel, 'group', group);
    g(1,1).stat_summary('type','sem','geom',{'point'}, 'dodge', dodge)%,'bar' 'black_errorbar'});

    g(1,1).set_color_options('map',cmapSubj);

    g.no_legend(); %avoid duplicate legend for subj

    g.draw();

    
    figTitle= strcat('DSTask_Opto-',thisExpTypeLabel,'-','LaserDay_peLatency_wIndividualLines');   

    saveFig(gcf, figPath,figTitle,figFormats);

    %----Stimulation PE Probability
    figure; clear g;

    % -- 1 = subplot of stimulation PE latency
    %- Bar of btwn subj means (group = [] or Group)
    group= []; %var by which to group

    % dp changing faceting- x cueType so can connect dots and facet by virus Group as rows

    g(1,1)=gramm('x',data.CueType,'y',data.ResponseProb,'color',data.CueTypeLabel, 'group', group);
    g(1,1).facet_grid(data.Projection,data.StimLength)

    g(1,1).stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}, 'dodge', dodge, 'width', width) 
    g(1,1).set_color_options('map',cmapGrand); 

    g(1,1).set_names('x','Cue Type','y','PE Probability', 'column', 'StimLength length')

    figTitle= strcat(thisExpTypeLabel,'-','Laser Day PE Probability');   
    g(1,1).set_title(figTitle);

    g.set_text_options(text_options_DefaultStyle{:}); 

    g.draw();


    %- Draw lines between individual subject points (group= subject, color=[]);

    group= data.Subject;

    g(1,1).update('x', data.CueType,'y',data.ResponseProb,'color',[], 'group', group)

     %here specifically multiple observations
    % per subject so using stat_summary to get mean line
    g(1,1).stat_summary('type','sem','geom',{'line'});
    % g(1,1).geom_line;%('alpha',0.3);

    g(1,1).set_line_options('base_size',linewidthSubj);

    g(1,1).set_color_options('chroma', chromaLineSubj); %black lines connecting points

    g.draw();


    %- Update with point of individual subj points (group= subject)
    group= data.Subject;
    g(1,1).update('x',data.CueType,'y',data.ResponseProb,'color',data.CueTypeLabel, 'group', group);
    g(1,1).stat_summary('type','sem','geom',{'point'}, 'dodge', dodge)%,'bar' 'black_errorbar'});

    g(1,1).set_color_options('map',cmapSubj);

    g.no_legend(); %avoid duplicate legend for subj

    
    %set x lims and ticks (a bit more manual good for bars)
    lims= [min(data.CueType)-.6,max(data.CueType)+.6];

    g.axe_property('XLim',lims);
    g.axe_property('XTick',round([lims(1):1:lims(2)]));

    
    g.draw();

    figTitle= strcat('DSTask_Opto-',thisExpTypeLabel,'-','LaserDay_peProb_wIndividualLines');   

    saveFig(gcf, figPath,figTitle,figFormats);


end %end expType (mode; stim/inhib) loop

%% 2022-10-13 dp Figure 4c/d

%-------Figure 4c--------------------

%copying from above plot code but updating so axes are shared



%plot default settings 
 %if only 2 groupings, brewer2 and brewer_dark work well 
% cmapGrand= 'brewer_dark';
% cmapSubj= 'brewer2';
cmapGrand= cmapCueLaserGrand;
cmapSubj= cmapCueLaserSubj;


dodge= 	.6; %if dodge constant between point and bar, will align correctly
width= .5; %good for bar w dodge >=1



for thisExpType= 1:numel(expTypesAll)

    thisExpTypeLabel= expTypeLabels{thisExpType};

    %subset data- by expType/virus
    ind=[];
    ind= stimTable.Mode==expTypesAll(thisExpType);

    data0= stimTable(ind,:);

    %%Stimulation Latency
    clear g;
    figure; 

    %subset data- by expression & behavioral criteria
    ind=[];
    ind= data0.Expression>0 & data0.Learner==1;

    data= data0(ind,:);

    %dp make stimLength categorical
    data.StimLength= categorical(data.StimLength);
    
    % -- 1 = subplot of stimulation PE latency
    %- Bar of btwn subj means (group = [] or Group)
    group= []; %var by which to group

    % dp changing faceting- x cueType so can connect dots and facet by virus Group as rows

    g=gramm('x',data.StimLength,'y',data.RelLatency,'color',data.CueTypeLabel, 'group', group);
    g.facet_grid(data.Projection,[]);%data.StimLength)

    % g(1,1).stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}) 
    % g(1,1).stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}, 'dodge', dodge) 
    % g(1,1).stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'},'width',width) 

    g.stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}, 'dodge', dodge,'width',width) 


    g(1,1).set_color_options('map',cmapGrand); 

    g(1,1).set_names('row','','x','Laser Duration (s)','y','Latency')
    
    
    figTitle= strcat(thisExpTypeLabel,'-','Laser Day Latency');   
    g(1,1).set_title(figTitle);

    g.set_text_options(text_options_DefaultStyle{:}); 

    g.draw();

% % 
% % TODO: can't get individual lines to line up correctly with this faceting
% %     %- Draw lines between individual subject points (group= subject, color=[]);
% 
% %- Group for this should be Subject,Session
% still not working
% %     
%     groupIDs= [];
%     groupIDs= findgroups(data.Subject,data.StartDate);
% 
%     groupIDsUnique= [];
%     groupIDsUnique= unique(groupIDs);
% 
%     for thisGroupID= 1:numel(groupIDsUnique)
%         %for each groupID, find index matching groupID
%         ind= [];
%         ind= find(groupIDs==groupIDsUnique(thisGroupID));
% 
%         %for each groupID, get the table data matching this group
%         thisGroup=[];
%         thisGroup= data(ind,:);
% 
%         %now cumulative count of observations in this group
%         %make default value=1 for each, and then cumsum() to get cumulative count
% %         thisGroup(:,'cumcount')= table(1);
% %         thisGroup(:,'cumcount')= table(cumsum(thisGroup.cumcount));
% 
%         %specific code for trainDayThisPhase
%         %assign back into table
%         data(ind, 'observationID')= table(thisGroupID);
% 
%     end 
% 
%     group= data.observationID;
% 
%     
% %     g(1,1).update('x', data.StimLength,'y',data.RelLatency,'color',[], 'group', group)
%     g(1,1).update('x', data.StimLength,'y',data.RelLatency,'color',data.CueTypeLabel, 'group', group)
% 
%     
%      %here specifically multiple observations
%     % per subject so using stat_summary to get mean line
%     g(1,1).stat_summary('type','sem','geom',{'line'}, 'dodge', dodge); %points working, no line tho
% %     g(1,1).geom_line;%('alpha',0.3);
% %     g(1,1).geom_line('dodge',dodge);%('alpha',0.3);
% 
% 
%     g(1,1).set_line_options('base_size',linewidthSubj);
% 
%     g(1,1).set_color_options('chroma', chromaLineSubj); %black lines connecting points
% 
%     %set x lims and ticks (a bit more manual good for bars)
% %     lims= [1-.6,numel(data.StimLength)+.6];
% % 
% %     g.axe_property('XLim',lims);
%     g.axe_property('XTick',round([lims(1):1:lims(2)]));
% 
% 
% 
%     g.draw();


    %- Update with point of individual subj points (group= subject)
    group= data.Subject;
    g(1,1).update('x',data.StimLength,'y',data.RelLatency,'color',data.CueTypeLabel, 'group', group);
    g(1,1).stat_summary('type','sem','geom',{'point'}, 'dodge', dodge)%,'bar' 'black_errorbar'});

    
    g(1,1).set_color_options('map',cmapSubj);

    g.no_legend(); %avoid duplicate legend for subj

    g.draw();

    % dp counting observations
    
    test=[];
    test= groupsummary(data, ["Subject", "StimLength", "CueID", "LaserTrial"]);
    
    test2= groupsummary(data, ["StimLength", "LaserTrial", "CueID", "Group"]);
    
    figTitle= strcat('Figure3-','DSTask_Opto-',thisExpTypeLabel,'-','LaserDay_peLatency_wIndividualLines');   

    saveFig(gcf, figPath,figTitle,figFormats);

    %----Stimulation PE Probability
    figure; clear g;

    % -- 1 = subplot of stimulation PE latency
    %- Bar of btwn subj means (group = [] or Group)
    group= []; %var by which to group

    % dp changing faceting- x cueType so can connect dots and facet by virus Group as rows

    g(1,1)=gramm('x',data.StimLength,'y',data.ResponseProb,'color',data.CueTypeLabel, 'group', group);
    g(1,1).facet_grid(data.Projection, [])

    g(1,1).stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}, 'dodge', dodge, 'width', width) 
    g(1,1).set_color_options('map',cmapGrand); 

    g(1,1).set_names('row','','x','Laser Duration (s)','y','PE Probability')

    figTitle= strcat(thisExpTypeLabel,'-','Laser Day PE Probability');   
    g(1,1).set_title(figTitle);

    g.set_text_options(text_options_DefaultStyle{:}); 

    g.draw();


    %TODO: given this faceting can't get individual subj points to line up
    %properly (I think bc x has multiple categories with hue so is
    %ambiguous)
    
%     %- Draw lines between individual subject points (group= subject, color=[]);
% 
%     group= data.Subject;
%     
%     %still need color for this particular plot to connect dots
%     g(1,1).update('x', data.StimLength,'y',data.ResponseProb,'color',[], 'group', group)
% 
% %     g(1,1).update('x', data.StimLength,'y',data.ResponseProb,'color',[], 'group', group)
% 
%      %here specifically multiple observations
%     % per subject so using stat_summary to get mean line
%     g(1,1).stat_summary('type','sem','geom',{'line'});
%     % g(1,1).geom_line;%('alpha',0.3);
% 
%     g(1,1).set_line_options('base_size',linewidthSubj);
% 
%     g(1,1).set_color_options('chroma', chromaLineSubj); %black lines connecting points
% 
%     g.draw();


    %- Update with point of individual subj points (group= subject)
    group= data.Subject;
    g(1,1).update('x',data.StimLength,'y',data.ResponseProb,'color',data.CueTypeLabel, 'group', group);
    g(1,1).stat_summary('type','sem','geom',{'point'}, 'dodge', dodge)%,'bar' 'black_errorbar'});

    g(1,1).set_color_options('map',cmapSubj);

    g.no_legend(); %avoid duplicate legend for subj

    
    %set x lims and ticks (a bit more manual good for bars)
%     lims= [min(data.StimLength)-.6,max(data.CueType)+.6];

%     g.axe_property('XLim',lims);
%     g.axe_property('XTick',round([lims(1):1:lims(2)]));

    
    g.draw();

    figTitle= strcat('Figure3-','DSTask_Opto-',thisExpTypeLabel,'-','LaserDay_peProb_wIndividualLines');   

    saveFig(gcf, figPath,figTitle,figFormats);


end %end expType (mode; stim/inhib) loop


%% ---DP 2023-01-31 manually reviewing specific dates of subj with multiple opto test sessions
% % group 3 for unknown reason has 2 test sessions where expected (between DS and lever choice)
% % as well s +2 more test sessions after lever choice... which were included
% % instead of the expected ones in chritelle's sheet. no clear reason why so
% % examine
% 
% datesToInclude= [];
% datesToInclude= [190827, 190828, 190829, 191002, 191003];
% 
% ind= ismember(stimTable.StartDate, datesToInclude);
% 
% data0= [];
% data0= stimTable(ind,:);
% 
% %subset data- by expression & behavioral criteria
% ind=[];
% ind= data0.Expression>0 & data0.Learner==1;
% 
% data= data0(ind,:);
% 
% %dp make stimLength categorical
% data.StimLength= categorical(data.StimLength);
% 
% %%Stimulation Latency
% clear g;
% figure; 
% 
% 
% % -- 1 = subplot of stimulation PE latency
% group= data.Subject;
% 
% g=gramm('x',data.StartDate,'y',data.RelLatency,'color',data.CueTypeLabel, 'marker', group, 'group', group);
% g.facet_grid(data.Projection,data.StimLength);%data.StimLength)
% 
% g.geom_line();
% g.geom_point();
% 
% g.draw();
% 
% 
% 
% % -- 2 = subplot of stimulation PE prob
% figure;
% 
% group= data.Subject;
% 
% g=gramm('x',data.StartDate,'y',data.ResponseProb,'color',data.CueTypeLabel, 'marker', group, 'group', group);
% g.facet_grid(data.Projection,data.StimLength);%data.StimLength)
% 
% g.geom_line();
% g.geom_point();
% 
% g.draw();
% 
% %- without the stimLength facet
% figure;
% 
% group= data.Subject;
% 
% g=gramm('x',data.CueTypeLabel,'y',data.ResponseProb,'color',data.CueTypeLabel, 'marker', group, 'group', group);
% g.facet_grid(data.Projection,data.StartDate);%data.StimLength)
% 
% g.geom_line();
% g.geom_point();
% 
% g.draw();



%% Plot Stim Days - dp new

%TODO: connect individual subj points. tried this but was just drawing
%vertically. perhaps table format would work? works fine for ICSS data.
%Could also be categorical data type here.

%TODO: facet grid not aggreeing with subplots here it seems for some reason

%plot default settings 
 %if only 2 groupings, brewer2 and brewer_dark work well 
% cmapGrand= 'brewer_dark';
% cmapSubj= 'brewer2';

cmapGrand= cmapCueLaserGrand;
cmapSubj= cmapCueLaserSubj;

dodge= 0.6; %if dodge constant between point and bar, will align correctly


for thisExpType= 1:numel(expTypesAll)

    thisExpTypeLabel= expTypeLabels{thisExpType};

    %subset data- by expType/virus
    ind=[];
    ind= stimTable.Mode==expTypesAll(thisExpType);

    data0= stimTable(ind,:);

    %%Stimulation Latency
    clear g;
    figure; 

    %subset data- by expression & behavioral criteria
    ind=[];
    ind= data0.Expression>0 & data0.Learner==1;

    data= data0(ind,:);


    %%Stimulation Latency
    clear g;
    figure; 

    %adding point of individual observations, but i think requires update()
    %call with different grouping for proper alignment

    % -- 1 = subplot of stimulation PE latency
    %- Bar of btwn subj means (group = [] or Group)
    group= []; %var by which to group

    g(1,1)=gramm('x',Group(selection),'y',RelLatency(selection),'color',CueType(selection), 'group', group);
    g(1,1).facet_grid([],StimLength(selection))

    g(1,1).stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}, 'dodge', dodge) 
    g(1,1).set_color_options('map',cmapGrand); 

    g(1,1).set_names('x','Projections','y','Latency')
   
    figTitle= strcat(thisExpTypeLabel,'-','Laser Day Latency');   
    g(1,1).set_title(figTitle);

    g.set_text_options(text_options_DefaultStyle{:}); 

    g.draw()


    %- Update with point of individual subj points (group= subject)
    group= Subject(selection);
    g(1,1).update('x',Group(selection),'y',RelLatency(selection),'color',CueType(selection), 'group', group);
    g(1,1).stat_summary('type','sem','geom',{'point'}, 'dodge', dodge)%,'bar' 'black_errorbar'});

    g(1,1).set_color_options('map',cmapSubj); 
    g.draw()


    figTitle= strcat('DSTask_Opto-',thisExpTypeLabel,'-','LaserDay_peLatency');   

    saveFig(gcf, figPath,figTitle,figFormats);


    % % -- 2 = subplot of stimulation PE probability

    %- Bar of btwn subj means (group = [] or Group)
    group= []; %var by which to group

    clear g; figure; %TODO: subplot not agreeing with facet so sep figs now

    selection= Mode==1 & Expression==1 & Learner==1 

    g(1,1)= gramm('x',Group(selection),'y',ResponseProb(selection),'color',CueType(selection), 'group', group);
    g(1,1).facet_grid([],StimLength(selection))

    g(1,1).stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}, 'dodge', dodge);
    % g(1,1).stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}, 'dodge', dodge,'width',1);

    g(1,1).set_color_options('map',cmapGrand); 

    g(1,1).set_names('x','Projections','y','Probability')
    
    figTitle= strcat(thisExpTypeLabel,'-','Laser Day Probability');   
    g(1,1).set_title(figTitle);

    g(1,1).no_legend()
    g.set_text_options(text_options_DefaultStyle{:}); 
    g.draw()

    %- Update with point of individual subj points (group= subject)
    group= Subject(selection);
    g(1,1).update('x',Group(selection),'y',ResponseProb(selection),'color',CueType(selection), 'group', group);

        %todo: tried lines connecting subj but doesn't seem to work-- probs bc
        %color facet wont allow
    % g(1,1).geom_line('dodge',dodge) %lines connecting subj
    g(1,1).stat_summary('type','sem','geom',{'line'}, 'dodge', dodge)%,'bar' 'black_errorbar'});

    % g(1,1).stat_summary('type','sem','geom',{'point'}, 'dodge', dodge)%,'bar' 'black_errorbar'});

    g(1,1).set_color_options('map',cmapSubj); 
    g.draw()


    figTitle= strcat('DSTask_Opto-',thisExpTypeLabel,'-','stimulation_day_peProbability');   


    saveFig(gcf, figPath,figTitle,figFormats);

    %TODO: 3- lines for each subj (no color facet?)
    %still doesn't work below:
    % group= Subject(selection);
    % 
    % g(1,1).update('x',Group(selection),'y',ResponseProb(selection), 'group', group);
    % g(1,1).stat_summary('type','sem','geom',{'line'}, 'dodge', dodge)%,'bar' 'black_errorbar'});
    % g.draw()


    % g.export('file_name','Stimulation Day Data','export_path','/Volumes/nsci_richard/Christelle/Data/Opto Project/Figures','file_type','pdf') 
end %end ExpType loop

%% -- 2022-07-12 STAT Comparison of above PE Behavior with separate CueID & LaserState Variables

%copying dataset above prior to dummy coding variables
data2= data; 

%-- exclude non-laser session data
allStimLength= unique(data2.StimLength);

%Don't include StimLength =0 or =20(there are no laser trials and thus won't be
%able to run model) 
allStimLength = allStimLength((allStimLength~=0) & (allStimLength~=20));
%subset data
ind= [];
ind= ismember(data2.StimLength,allStimLength);
  
data2= data2(ind,:);



% STAT Testing
%are mean nosepokes different by laser state/virus etc?... lme with random subject intercept

%- dummy variable conversion
% converting to dummies(retains only one column, as 2+ is redundant)
% 
% create dummyvars as necessary
dummy=[];
dummy= categorical(data2.CueID);
dummy= dummyvar(dummy); 
data2.CueIDdummy= dummy(:,1);


dummy=[];
dummy= categorical(data2.LaserTrial);
dummy= dummyvar(dummy); 
data2.LaserTrialDummy= dummy(:,1);

% data2.CueType= dummy(:,1); %is this correct? reducing to 2 instead of 4 values...should take first 3?
% 
% % %convert StimLength to dummy variable 
% % dummy=[];
% % dummy= categorical(data2.StimLength);
% % dummy= dummyvar(dummy); 
% 
% % data2.StimLength= dummy(:,1);

%--Run LME
lme1=[];

lme1= fitlme(data2, 'RelLatency~ CueIDdummy*StimLength*LaserTrialDummy + (1|Subject)');

lme1


%print and save results to file
%seems diary keeps running log to same file (e.g. if code rerun seems prior output remains)
diary('DS Task Stim Day- All trials Latency Stats lmeDetails.txt')
lme1
diary off

%% - Run followup LME for each StimLength & CueType
% allStimLength= unique(data2.StimLength);

%Don't include StimLength =0 or =20(there are no laser trials and thus won't be
%able to run model) 
% allStimLength = allStimLength((allStimLength~=0) & (allStimLength~=20));

for thisStimLength= 1:numel(allStimLength)
   
    %subset data
    ind= [];
    ind= ismember(data2.StimLength,allStimLength(thisStimLength));
    
    data3=[];
    data3= data2(ind,:);
    
    %run the model
    lme1= [];
    
    lme1= fitlme(data3, 'RelLatency~ CueIDdummy*LaserTrialDummy + (1|Subject)');

    diary('DS Task Stim Day- Followup Stats 1- StimLength subset lmeDetails.txt')
    printStr= (strcat('Data Subset-------------****--------StimLength = ', num2str(allStimLength(thisStimLength)),'--------------****---------------'));
    printStr
    lme1
    diary off
    
    
    % -Followup for each CueID separately
        allCueID= unique(data3.CueID);
        for thisCueID= 1:numel(allCueID)

            %subset data
            ind= [];
            ind= ismember(data3.CueID,allCueID(thisCueID));

            data4=[];
            data4= data3(ind,:);

            %run the model
            lme1= [];

            lme1= fitlme(data4, 'RelLatency~ LaserTrialDummy + (1|Subject)');

            diary('DS Task Stim Day- Followup Stats 2- CueID & LaserState subset lmeDetails.txt')
            printStr= (strcat('Data Subset-------------****--------CueID = ',data4.CueID{1}, '---StimLength = ', num2str(allStimLength(thisStimLength)),'--------------****---------------'));
            printStr
            lme1
            diary off
            
%             %viz
%             printStr= strcat('data subset CueID = ',data4.CueID{1}, '--StimLength = ', num2str(allStimLength(thisStimLength)));
%             group= []; %var by which to group
% 
%             figure(); clear g;
%             g= gramm('x', data4.LaserTrial, 'y', data4.RelLatency, 'color', data4.LaserTrial);
%             g.geom_point();
% %             g.stat_summary('type','sem','geom','bar');
%             g().stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'}, 'dodge', dodge) 
%             g().set_color_options('map',cmapBlueGrayGrand); 
%             g().set_names('x','LaserState','y','Latency')
%             g().set_title(printStr)
% 
%             g.draw();
% %              
% %             %update subj lines
%             group= data4.Subject;
%             g.update('x',data4.LaserTrial,'y',data4.RelLatency,'color',[], 'group', group);
% %             g.stat_summary('type','sem','geom',{'line'})%,'bar' 'black_errorbar'});
%             g.geom_line()
%             g.set_color_options('chroma',0);
%             g.draw();
% 
%                %update subj points
%             group= data4.Subject;
%             g.update('x',data4.LaserTrial,'y',data4.RelLatency,'color',data4.LaserTrial, 'group', group);
%             g.stat_summary('type','sem','geom',{'point'})%,'bar' 'black_errorbar'});
% 
% %               g.geom_point();
%             g.set_color_options('map',cmapBlueGraySubj);
%             
%             g.draw();
% 
% %             %viz distribution? 
% %             figure(); clear g;
% % 
% %             g= gramm('x', data4.RelLatency, 'color', data4.LaserTrial);
% % 
% %             g.facet_grid(data4.LaserTrial,[]);
% %             
% %             g().set_names('x','Latency','color','LaserTrial')
% % 
% %             g().stat_bin()
% %                        
% %             g().set_title(printStr)
% % 
% %             g.draw()
% 
%                 %try anova?
%                 % %anova 
% %                 [p, tableAnova, stats, terms]= anovan(data4.RelLatency, {data4.LaserTrial});
% 
%             
        end

    
end

% -Followup for each CueID separately

%subset data
% ind= [];
% %DS only
% ind= (data2.CueType == 1 | data2.CueType == 2);
% 
% data3= data2(ind,:);

%% -- old stat STAT Comparison of above PE behavior by laser
% 
% %copying dataset above prior to dummy coding variables
% data2= data; 
% 
% % STAT Testing
% %are mean nosepokes different by laser state/virus etc?... lme with random subject intercept
% 
% %- dummy variable conversion
% % % converting to dummies(retains only one column, as 2+ is redundant)
% % 
% % %convert CueType to dummy variable 
% % dummy=[];
% % dummy= categorical(data2.CueType);
% % dummy= dummyvar(dummy); 
% % 
% % data2.CueType= dummy(:,1); %is this correct? reducing to 2 instead of 4 values...should take first 3?
% % 
% % % %convert StimLength to dummy variable 
% % % dummy=[];
% % % dummy= categorical(data2.StimLength);
% % % dummy= dummyvar(dummy); 
% % 
% % % data2.StimLength= dummy(:,1);
% 
% %--Run LME
% lme1=[];
% 
% lme1= fitlme(data2, 'RelLatency~ CueType*StimLength + (1|Subject)');
% 
% % lme1
% 
% 
% %print and save results to file
% %seems diary keeps running log to same file (e.g. if code rerun seems prior output remains)
% diary('DS Task Stim Day- old All trials Latency Stats lmeDetails.txt')
% lme1
% diary off
% 
% %---- Followup simple comparison for CueType effect
% %- Simple comparison: Run DS subset and NS subset separately?
% 
% %subset data
% ind= [];
% %DS only
% ind= (data2.CueType == 1 | data2.CueType == 2);
% 
% data3= data2(ind,:);
% 
% %-Run LME
% lme1=[];
% 
% lme1= fitlme(data3, 'RelLatency~ CueType*StimLength + (1|Subject)');
% 
% % lme1
% 
% diary('DS Task Stim Day- DS trials only Latency Stats lmeDetails.txt')
% lme1
% diary off
% 
% % Same for NS
% 
% %subset data
% ind= [];
% %DS only
% ind= (data2.CueType == 3 | data2.CueType == 4);
% 
% data3= data2(ind,:);
% 
% %-Run LME
% lme1=[];
% 
% lme1= fitlme(data3, 'RelLatency~ CueType*StimLength + (1|Subject)');
% 
% % lme1
% 
% diary('DS Task Stim Day- NS trials only Latency Stats lmeDetails.txt');
% lme1
% diary off
% 
% % %anova 
% % [p, tableAnova, stats, terms]= anovan(data3.RelLatency, {data3.CueType, data3.StimLength});

%% OLD: Plot Post-Stim Session

%Latency
figure 
selection= Mode==1 & Expression==1 & Learner==1 & StimLength==20
g=gramm('x',Group(selection),'y',RelLatency(selection),'color',CueType(selection))
g.stat_summary('type','sem', 'geom',{'bar','black_errorbar'}) 
g.set_names('x','Projections','y','Latency')
g.set_title('Post Stim Day Latency')
g.draw();

figTitle= 'post_stimulation_day_peLatency';
saveFig(gcf, figPath,figTitle,figFormats);

%Probability 
figure();
selection= Mode==1 & Expression==1 & Learner==1 & StimLength==20
g=gramm('x',Group(selection),'y',ResponseProb(selection),'color',CueType(selection))
g.stat_summary('type','sem', 'geom',{'bar' 'black_errorbar'})
g.set_names('x','Projections','y','Probability')
g.set_title('Post Stim Day Probability')
g.draw()

figTitle= 'post_stimulation_day_peProbability';
saveFig(gcf, figPath,figTitle,figFormats);

%% Histogram
% %% histogram 
% NSselection= CueType==3 & StimLength==0
% BinNums = [0:.1:1]
% histogram (ResponseProb(NSselection), BinNums)
% 
% figure
% DSselection= CueType==1 & StimLength==0
% BinNums = [0:.1:1]
% histogram (ResponseProb(DSselection), BinNums)



