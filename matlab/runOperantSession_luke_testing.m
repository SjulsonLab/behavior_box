% code for all phases of training in the operant boxes.
% Daniela Cassataro updated v1  8/6/18
%

% ////////////////////////////////////////////////////////////////////////////
%   PHASE 1. white noise, init servo opens, prerewarded. reward code 1
%   PHASE 2. hold init poke longer, reward at end of waiting long enough 
%      in init poke. reward code 3.
%   PHASE 3. block of "one side" trials. pre-reward only first block
%             P=1, 5 uL, L or R random assigned/mouse
%             only correct/single door open
%             init no longer rewarded
%             single cue, reward code 3 for the first block and reward code 4 after
%   PHASE 4. random L/R, non-block trials, both doors open, 5 +/- 1 uL
%             single cue, reward code 4 
%   PHASE 5. decide on phase 5 based on how the mouse learned 1-4.
%             vary reward size even more, over the course of the whole session.
%             some trials will get double cue. reward code 4
% ////////////////////////////////////////////////////////////////////////////
% 
% 
% 
% reward codes - they are independent of which poke is rewarded
%  -1 - punish for incorrect nosepoke during goToPokes
%   0 - no reward
%   1 - reward at ready signal
%   2 - reward on init nose poke
%   3 - reward at end of cue
%   4 - reward only upon nosepoke
% 
% cue1_vis and cue2_vis codes
%   0 - no visual cue
%   1 - LEDs 1 and 2 on
%   2 - LEDs 3 and 4 on
%   3 - all LEDs on
% 
% cue1_aud and cue2_aud codes
%   0 - no auditory cue
%   1 - low tone
%   2 - high tone
%   3 - buzzer
%   4 - white noise
  
  


clear all
close all



%% code for setting rewards on right and left. Will do something more sophisticated later
IrewardSize_nL = 5000; %IrewardCode is determined by the training phase

LrewardCode = [4 -1 4 -1];
LrewardSize_nL = [5000 5000 5000 5000];
RrewardCode = [-1 4 -1 4];
RrewardSize_nL = [5000 5000 5000 5000];



%% parameters to set on a per-mouse basis
m.mouseName            = 'ec-test-9-05-jaxmale03b';  % should not change
m.trainingPhase        = 2;
m.serialPort           = 'COM4'; % look this up in the arduino software
m.requiredVersion      = 10;  % version of arduino DUE software required
m.sessionLength        = 60; % in minutes
m.maxTrials            = 300; % program terminates when either sessionLength or maxTrials is reached
m.interTrialInterval   = 2;  % number of seconds between trials

startTrialNum          = 1;     % in case you stop and start on the same day
resetTimeYN            = 'yes'; %

% setting which cues are used for this animal - must be consistent for a given animal
%   0 - no auditory cue
%   1 - low tone
%   2 - high tone
%   3 - buzzer
m.leftVisCue         = 0;
m.leftAudCue         = 3;
m.rightVisCue        = 3;
m.rightAudCue        = 0;



% fix: update this section using exist to search for basedir.
if strcmpi(computer, 'MACI64')
	m.basedir = '/Users/luke/Google Drive/lab-shared/lab_projects/rewardPrediction/behavior';
else
	%    m.basedir = 'G:\My Drive\lab-shared\lab_projects\rewardPrediction\behavior';
	m.basedir = 'C:\Users\lukes\Desktop\temp';
end
m.dateString = datestr(now, 29);
timeString = datestr(now, 30);
m.timeString = timeString(end-6:end);
cd(m.basedir);

% reward codes - they are independent of which poke is rewarded
%     0 - no reward
%     1 - reward init poke at ready signal
%     2 - reward on init nose poke
%     3 - reward at end of cue
%     4 - reward only upon nosepoke

%% put all default box params here
boxParams = py.dict;
boxParams.update(pyargs('nTrial',            startTrialNum));
boxParams.update(pyargs('resetTimeYN',       0)); % setting this to 1 sets the arduino clock zero and sends a sync pulse to the intan
boxParams.update(pyargs('initPokePunishYN',  0)); % setting to 1 enables punishment for initpoke during standby

boxParams.update(pyargs('WNvolume',      50));
boxParams.update(pyargs('lowCueVolume',  120));
boxParams.update(pyargs('highCueVolume', 120));
boxParams.update(pyargs('buzzerVolume',  90));

boxParams.update(pyargs('trainingPhase',         m.trainingPhase));
boxParams.update(pyargs('laserOnCode',           0));

% % stuff we're not using now that we don't have doors
% boxParams.update(pyargs('doorCloseSpeed',        1)); % original default was 10
% boxParams.update(pyargs('IopenYN', 0)); % 1 means open port, 0 means keep closed
% boxParams.update(pyargs('LopenYN', 0));
% boxParams.update(pyargs('RopenYN', 0));
% boxParams.update(pyargs('extra4openYN', 0));
% boxParams.update(pyargs('extra5openYN', 0));

% these are all in milliseconds
boxParams.update(pyargs('readyToGoLength',        1000*30));
boxParams.update(pyargs('punishDelayLength',      1000*16));
boxParams.update(pyargs('preCueLength',           10));
boxParams.update(pyargs('cue1Length',             200));
boxParams.update(pyargs('interCueLength',         10));
boxParams.update(pyargs('cue2Length',             10));
boxParams.update(pyargs('postCueLength',          10));
boxParams.update(pyargs('goToPokesLength',        1000*60));
boxParams.update(pyargs('rewardCollectionLength', 1000*5));

boxParams.update(pyargs('IrewardCode',  0));
boxParams.update(pyargs('LrewardCode',  0));
boxParams.update(pyargs('RrewardCode',  0));
% boxParams.update(pyargs('extra4rewardCode',  0));
% boxParams.update(pyargs('extra5rewardCode',  0));
% boxParams.update(pyargs('extra6rewardCode',  0));

boxParams.update(pyargs('IrewardSize_nL',       1000*5));
boxParams.update(pyargs('LrewardSize_nL',       1000*5));
boxParams.update(pyargs('RrewardSize_nL',       1000*5));
boxParams.update(pyargs('deliveryDuration_ms',  1000));
boxParams.update(pyargs('syringeSize_mL',       5));



%% connect to arduino
delete(instrfindall);
box1 = serial(m.serialPort,'Timeout', 10, 'BaudRate', 115200, 'Terminator', 'LF', 'OutputBufferSize', 10000, 'InputBufferSize', 10000);
fopen(box1);
pause(1);
fprintf(box1, 'checkVersion\n');
tstr = fgetl(box1);
if str2num(tstr) ~= m.requiredVersion
	error(sprintf('The arduino has version %d, but the matlab script requires version %d', str2num(tstr), m.requiredVersion));
end

% box1.FlowControl = 'software';


%% generate UI, wait before starting
global exitNowYN;
global exitAfterTrialYN;
exitNowYN = 0;
exitAfterTrialYN = 0;
x = operantBoxExitDialog2();
set(x,'WindowStyle','modal'); % keep this window always on top

waitBest('Hit OK to start the trials', ['Phase ' num2str(m.trainingPhase)]);
if strcmpi(resetTimeYN, 'yes')
	sendToArduino(box1, [], 'resetTimeYN', 1);
end

%% loop over trials
t = tic;
nTrial = startTrialNum;
lastPos = 0;
close all
% f1 = figure;
% maxOutcome2Length = 1;


%% send boxparams once to arduino, with slightly longer pause to prevent buffer overrun
k = boxParams.keys;
d = boxParams.values;
for idx = 1:length(d)
	sendToArduino(box1, [], char(k{idx}), d{idx});
	pause(0.2); % extended the pause to 0.2 s
end



%% main while loop, looping over trials
while toc(t)/60 < m.sessionLength && nTrial <= m.maxTrials && exitNowYN == 0 && exitAfterTrialYN == 0
	
	% set box params for this trial
	% all reward codes default to zero and will be zero unless changed here
	
	clear P;
	P = py.dict; % empty python dict that fills only w/parameters that
	% are updated in the current trial.
	% P is cleared after every trial (later,below)
	P.update(pyargs('nTrial', nTrial));
	
	if m.trainingPhase == 1
		P.update(pyargs('IrewardCode', 1));
		P.update(pyargs('IrewardSize_nL', IrewardSize_nL));
	elseif m.trainingPhase == 2
		P.update(pyargs('IrewardCode', 3));
		P.update(pyargs('IrewardSize_nL', IrewardSize_nL));
	else
		% reward info
		P.update(pyargs('LrewardCode', LrewardCode(nTrial)));
		P.update(pyargs('LrewardSize_nL', LrewardSize_nL(nTrial)));
		P.update(pyargs('RrewardCode', RrewardCode(nTrial)));
		P.update(pyargs('RrewardSize_nL', RrewardSize_nL(nTrial)));
		
		% cue info
		% 		m.leftCueVis        = 0;
		% 		m.leftCueAud        = 2;
		% 		m.rightCueVis       = 3;
		% 		m.rightCueAud       = 0;
		if LrewardCode(nTrial)==4 && RrewardCode(nTrial)<4 % Left trial
		end	
		
		
	end
	
	
	% 1 in phase1,    3 in phase2,     0 in all other phases
	
	
	% 	if m.trainingPhase >= 3
	% 		if (LcueProb > round(rand()*99)) % if left cue
% 			P.update(pyargs('auditoryOrVisualCue', leftCueType)); %1 for aud/2 for vis
% 			P.update(pyargs('LrewardCode', dcode)); % 3 or 4
% 			P.update(pyargs('RrewardCode', 0)); % default is 0
% 			P.update(pyargs('LopenYN', 1));
% 			P.update(pyargs('RopenYN', opdoor)); % 0 or 1
% 		else %right cue
% 			P.update(pyargs('auditoryOrVisualCue', rightCueType)); %1 for aud/2 for vis
% 			P.update(pyargs('RrewardCode', dcode)); % 3 or 4
% 			P.update(pyargs('LrewardCode', 0)); % default is 0
% 			P.update(pyargs('RopenYN', 1));
% 			P.update(pyargs('LopenYN', opdoor)); % 0 or 1
% 		end
% 	end
	
	nTrial = nTrial + 1;
	
	
	%% run actual trial
	fname = runFivePokeSingleTrial(box1, m, P);
	% only pass the freshly made P dict for THAT trial.

	
	
	%% write additional parameters to logfile
	
	% these parameters never get passed to the arduino, so we should log
	% them here at some point
	
	% LcueProb
	% RcueProb
	% noCueProb
	
	%    %% load in trial info from text file
	%
	%    % extract the event names, etc. from text file
	%    [trialStr, lastPos] = extractTrial_v2(fname, lastPos); %lastPos gets updated so that only the last trial is read in
	%
	%    % convert event names into a struct that contains only the relevant info
	%    trialInfo = analyzeTrialStr1(trialStr);
	%    %trialInfo(end).nTrial = nTrial;
	%
	%    %% plot latency to nose poke
	%    a1 = subplot(2, 2, 1); % The 2,2,1 arguments make a 2x2 array of subplots, then select #1 (top left)
	%    ylabel('Latency to init poke (sec.)');
	%    xlabel('Trial number');
	%    if ~isempty(trialInfo.latency_to_init)
	%       p1 = bar(trialInfo.trialNum, trialInfo.latency_to_init); hold on
	%       p1.FaceColor = [0 0 0]; % red, green, blue - each value ranges from 0 to 1
	%    end
	%    t1 = title(m.mouseName);
	%    t1.Interpreter = 'none'; % this prevents underscores from being interpreted as LaTeX subscripts...not super important
	%
	%    %% plot nose poke duration
	%    a2 = subplot(2, 2, 3); % lower left
	%    ylabel('Nose poke duration (sec.)');
	%    xlabel('Trial number');
	%    if ~isempty(trialInfo.latency_to_init)
	%       p1 = bar(trialInfo.trialNum, trialInfo.init_poke_length); hold on
	%       p1.FaceColor = [0 0 0]; % red, green, blue
	%    end
	%
	%    %% plot responses to left cues: correct, error, and missed
	%    a3 = subplot(2, 2, 2); % upper right
	%
	%    a3.XLabel.String = 'Trial number';
	%    ylabel('Time to nosepoke (sec.)');
	%    hold on
	%
	%    if trialInfo.outcome2Time > maxOutcome2Length
	%       maxOutcome2Length = trialInfo.outcome2Time;
	%    end
	%    if strcmpi(trialInfo.cuedSide, 'left')
	%       if strcmpi(trialInfo.outcome2, 'correct')
	%          p1 = bar(trialInfo.trialNum, trialInfo.outcome2Time);
	%          p1.FaceColor = [0 1 0]; % red, green, blue
	%          p1.EdgeAlpha = 0;
	%       elseif strcmpi(trialInfo.outcome2, 'ErrorPoke')
	%          p1 = bar(trialInfo.trialNum, trialInfo.outcome2Time);
	%          p1.FaceColor = [1 0 0];
	%          p1.EdgeAlpha = 0;
	%       elseif strcmpi(trialInfo.outcome2, 'miss')
	%          p1 = bar(trialInfo.trialNum, trialInfo.outcome2Time);
	%          p1.FaceColor = [0 0 1];
	%          p1.EdgeAlpha = 0;
	%       end
	%    end
	%
	%
	%    a3.YLim = [0 maxOutcome2Length];
	%    t1 = title('Left trials, green = correct, red = error, blue = missed');
	%
	%    %% plot correct and incorrect responses to right cues
	%    a4 = subplot(2, 2, 4); % lower right
	%
	%    xlabel('Trial number');
	%    ylabel('Time to nosepoke (sec.)');
	%    hold on
	%
	%    if trialInfo.outcome2Time > maxOutcome2Length
	%       maxOutcome2Length = trialInfo.outcome2Time;
	%    end
	%    if strcmpi(trialInfo.cuedSide, 'right')
	%       if strcmpi(trialInfo.outcome2, 'correct')
	%          p1 = bar(trialInfo.trialNum, trialInfo.outcome2Time);
	%          p1.FaceColor = [0 1 0]; % red, green, blue
	%          p1.EdgeAlpha = 0;
	%       elseif strcmpi(trialInfo.outcome2, 'ErrorPoke')
	%          p1 = bar(trialInfo.trialNum, trialInfo.outcome2Time);
	%          p1.FaceColor = [1 0 0];
	%          p1.EdgeAlpha = 0;
	%       elseif strcmpi(trialInfo.outcome2, 'miss')
	%          p1 = bar(trialInfo.trialNum, trialInfo.outcome2Time);
	%          p1.FaceColor = [0 0 1];
	%          p1.EdgeAlpha = 0;
	%       end
	%    end
	%
	%    a4.YLim = [0 maxOutcome2Length];
	%    t1 = title('Right trials, green = correct, red = error, blue = missed');
	
end

%% close arduino
fclose(box1);
% close all force;
fprintf('Session completed.\n');



