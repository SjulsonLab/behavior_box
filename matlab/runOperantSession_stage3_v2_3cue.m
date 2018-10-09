% code for all phases of training in the operant boxes.
% Daniela Cassataro updated v1  8/6/18
%

% ////////////////////////////////////////////////////////////////////////////
%   PHASE 1. white noise, init servo opens, prerewarded. reward code 1
%   PHASE 2. hold init poke longer, reward at end of waiting long enough 
%      in init poke. reward code 3.
%   PHASE 3. block of "one side" trials. pre-reward only first block
%             P= 5 uL, L or R random assigned/mouse
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


%% parameters for the mouse struct - these should never change
m.mouseName            = 'jaxmale08';  % should not change
m.requiredVersion      = 10;  % version of arduino DUE software required


% setting which cues are used for this animal - must be consistent for a given animal
% cue1_vis and cue2_vis codes
%   0 - no visual cue
%   1 - LEDs 1 and 2 on
%   2 - LEDs 3 and 4 on
%   3 - all LEDs on
m.leftVisCue         = 0;
m.rightVisCue        = 3;

% cue1_aud and cue2_aud codes
%   0 - no auditory cue
%   1 - low tone
%   2 - high tone
%   3 - buzzer
%   4 - white noise
m.leftAudCue         = 3;
m.rightAudCue        = 0;



%% parameters to set for today's session
sessionStr.mouseName     = m.mouseName;
sessionStr.trainingPhase = 3;

% first block is pre-rewarded
sessionStr.phase3_firstblock = 'yes';
% sessionStr.phase3_firstblock = 'no';

sessionStr.startTrialNum = 1;     % in case you stop and start on the same day
resetTimeYN              = 'yes'; %

sessionStr.sessionLength             = 60; % in minutes
sessionStr.maxTrials                 = 50; % program terminates when either sessionLength or maxTrials is reached
sessionStr.interTrialInterval_mean   = 3;  % number of seconds between trials
sessionStr.interTrialInterval_SD     = 1; % standard deviation of time between trials

sessionStr.IrewardSize_nL = 5000;   % will have to update later for varying reward size
sessionStr.punishForErrorPoke = 'no'; % 0 for no, 1 for yes

% info about trials - will figure out something more sophisticated later

% for phase 3 only
sessionStr.trialLRtype  = 1 .* ones(sessionStr.maxTrials, 1);  % left block
% sessionStr.trialLRtype  = 2 .* ones(sessionStr.maxTrials, 1);  % right block
sessionStr.trialLRtype_info = '1 = left, 2 = right, 3 = free choice (i.e. both)';

sessionStr.trialAVtype  = 3 .* ones(sessionStr.maxTrials, 1);  % for phase 3, use both
sessionStr.trialAVtype_info = '1 = auditory only, 2 = visual only, 3 = both aud + vis';


% when to give cues
sessionStr.leftCueWhen  = repmat([1], 1, 1000);
sessionStr.leftCueWhen_info = '1 = first cue slot, 2 = second cue slot, 4 = third cue slot';
sessionStr.rightCueWhen = repmat([1], 1, 1000); 
sessionStr.rightCueWhen_info = '1 = first cue slot, 2 = second cue slot, 4 = third cue slot';

sessionStr.LrewardSize_nL = 5000 * ones(size(sessionStr.trialLRtype));
sessionStr.RrewardSize_nL = 5000 * ones(size(sessionStr.trialLRtype));

sessionStr = makeRewardCodes(sessionStr); % adding reward codes to the struct

% cue lengths, etc.
if sessionStr.trainingPhase>2
	sessionStr.preCueLength   = 0;
	sessionStr.cue1Length     = 150;
	sessionStr.cue2Length     = 0;
	sessionStr.cue3Length     = 0;
	sessionStr.postCueLength  = 0;
end

[cue1_vis, cue1_aud, cue2_vis, cue2_aud, cue3_vis, cue3_aud] = makeCueVectors_3cue(sessionStr, m);


%% figuring out where to save the log files and which computer we're on
[~, hostname] = system('hostname');

if strfind(hostname, 'Luke-HP-laptop')
	m.basedir = 'C:\Users\lukes\Desktop\temp';
	m.serialPort = 'COM4';  % can look this up in the arduino
elseif strfind(hostname, 'bumbrlik01')
	m.basedir = 'G:\My Drive\lab-shared\lab_projects\rewardPrediction\behavior';
	m.serialPort = 'COM4';  %commented by EFO
elseif strfind(hostname, 'bumbrlik02')
    m.basedir = 'G:\My Drive\lab-shared\lab_projects\rewardPrediction\behavior';
    m.serialPort = 'COM5'; %introduced by EFO, arduino was connected on COM5 only, no matter which USB port  
else
	error('can''t figure out correct location to store files');
end

m.dateString = datestr(now, 29);
timeString = datestr(now, 30);
m.timeString = timeString(end-5:end);
sessionStr.basedir = m.basedir;
sessionStr.timeString = m.timeString;
sessionStr.dateString = m.dateString;

%% creating directory to store the data, saving structs to disk
cd(sessionStr.basedir);
sessionStr.basename = [sessionStr.mouseName '_' datestr(now, 'yymmdd') '_' sessionStr.timeString];
mkdir(sessionStr.basename);
cd(sessionStr.basename);

mouseStr = m;
save('mouseStr.mat', 'mouseStr');
save('sessionStr.mat', 'sessionStr');

%% verify we're using python 2.7, as version 3 creates problems with dicts
x = pyversion();
if str2num(x) ~= 2.7
	try
		pyversion 2.7
	catch
		disp('The wrong version of python is loaded. Restart MATLAB.');
		return
	end
end


%% put all default box params here
boxParams = py.dict;
boxParams.update(pyargs('nTrial',            sessionStr.startTrialNum));
boxParams.update(pyargs('resetTimeYN',       0)); % setting this to 1 sets the arduino clock zero and sends a sync pulse to the intan
boxParams.update(pyargs('initPokePunishYN',  0)); % setting to 1 enables punishment for initpoke during standby

boxParams.update(pyargs('WNvolume',      50));
boxParams.update(pyargs('lowCueVolume',  120));
boxParams.update(pyargs('highCueVolume', 120));
boxParams.update(pyargs('buzzerVolume',  90));

boxParams.update(pyargs('trainingPhase', 0));
boxParams.update(pyargs('laserOnCode', 0));

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

boxParams.update(pyargs('cueLED1Brightness',       1023));
boxParams.update(pyargs('cueLED2Brightness',       1023));
boxParams.update(pyargs('cueLED3Brightness',       1023));
boxParams.update(pyargs('cueLED4Brightness',       1023));




%% connect to arduino
delete(instrfindall);
box1 = serial(m.serialPort,'Timeout', 10, 'BaudRate', 115200, 'Terminator', 'LF', 'OutputBufferSize', 10^6, 'InputBufferSize', 10^6);
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

waitBest('Start camera and recordings now, then hit OK to start the trials', ['Phase ' num2str(sessionStr.trainingPhase)]);
if strcmpi(resetTimeYN, 'yes')
	sendToArduino(box1, [], 'resetTimeYN', 1);
end

%% start camera
sendToArduino(box1, [], 'cameraRecordingYN', 1);

%% can open a figure here for plotting

% f1 = figure;
% maxOutcome2Length = 1;

%% send a full set of boxparams to arduino (later, only a few are sent)
k = boxParams.keys;
d = boxParams.values;
for idx = 1:length(d)
	sendToArduino(box1, [], char(k{idx}), d{idx});
	pause(0.01); % used to be 0.2 s before increasing buffer size
end

%% main while loop, looping over trials
t = tic;
nTrial = sessionStr.startTrialNum;
lastPos = 0;
close all

while toc(t)/60 < sessionStr.sessionLength && nTrial <= sessionStr.maxTrials && exitNowYN == 0 && exitAfterTrialYN == 0
	
	% set box params for this trial
	% all reward codes default to zero and will be zero unless changed here
	
	clear trial_dict;
	trial_dict = py.dict; % empty python dict that fills only w/parameters that
	% are updated in the current trial.
	
	trial_dict.update(pyargs('nTrial', nTrial));
	trial_dict.update(pyargs('trainingPhase', sessionStr.trainingPhase));
	
	
	if sessionStr.trainingPhase == 1
		trial_dict.update(pyargs('IrewardCode', 1));
		trial_dict.update(pyargs('IrewardSize_nL', sessionStr.IrewardSize_nL));
	elseif sessionStr.trainingPhase == 2
		trial_dict.update(pyargs('IrewardCode', 3));
		trial_dict.update(pyargs('IrewardSize_nL', sessionStr.IrewardSize_nL));
	else
		% info about trial type - sent to arduino only so that they get
		% saved in text log file
		trial_dict.update(pyargs('trialLRtype', sessionStr.trialLRtype(nTrial)));
		trial_dict.update(pyargs('trialAVtype', sessionStr.trialAVtype(nTrial)));
		trial_dict.update(pyargs('leftCueWhen', sessionStr.leftCueWhen(nTrial)));
		trial_dict.update(pyargs('rightCueWhen', sessionStr.rightCueWhen(nTrial)));

		% reward info
		trial_dict.update(pyargs('LrewardCode', sessionStr.LrewardCode(nTrial)));
		trial_dict.update(pyargs('LrewardSize_nL', sessionStr.LrewardSize_nL(nTrial)));
		trial_dict.update(pyargs('RrewardCode', sessionStr.RrewardCode(nTrial)));
		trial_dict.update(pyargs('RrewardSize_nL', sessionStr.RrewardSize_nL(nTrial)));
		
		% cue info
		trial_dict.update(pyargs('cue1_vis', cue1_vis(nTrial)));
		trial_dict.update(pyargs('cue1_aud', cue1_aud(nTrial)));
		trial_dict.update(pyargs('cue2_vis', cue2_vis(nTrial)));
		trial_dict.update(pyargs('cue2_aud', cue2_aud(nTrial)));
		
		trial_dict.update(pyargs('preCueLength', sessionStr.preCueLength));
		trial_dict.update(pyargs('cue1Length', sessionStr.cue1Length));
		trial_dict.update(pyargs('cue2Length', sessionStr.cue2Length));
		trial_dict.update(pyargs('cue3Length', sessionStr.cue3Length));
		trial_dict.update(pyargs('postCueLength', sessionStr.postCueLength));
		
	end
	
	nTrial = nTrial + 1;
	
	
	%% run actual trial
	fname = run2AFCSingleTrial(box1, sessionStr, trial_dict);
	
	% randomized inter-trial interval
	pause(sessionStr.interTrialInterval_mean + sessionStr.interTrialInterval_SD .* randn());
	
	
	%% write additional parameters to logfile
	
	% these parameters never get passed to the arduino, so we should log
	% them here at some point
	
	% LcueProb
	% RcueProb
	% noCueProb
	
	%    %% load in trial info from text file
	%
	%    % extract the event names, etc. from text file
	%    [sessionStr, lastPos] = extractTrial_v2(fname, lastPos); %lastPos gets updated so that only the last trial is read in
	%
	%    % convert event names into a struct that contains only the relevant info
	%    trialInfo = analyzeTrialStr1(sessionStr);
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

%% stop camera
sendToArduino(box1, [], 'cameraRecordingYN', 0);


%% close arduino
fclose(box1);
% close all force;
fprintf('Session completed.\n');



