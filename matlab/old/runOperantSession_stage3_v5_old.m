% code for training phase 3, using arduino code v5
% Luke Sjulson, 2018-10-18

% ////////////////////////////////////////////////////////////////////////////
%   PHASE 1. collection: no white noise, mice get reward for center poke or for poking the "correct"
%     nosepoke for that trial. Cue is given when animal does correct side poke.
%   PHASE 2. initiation: white noise, animal must center poke to get reward
%   PHASE 3. fast choice: white noise, center poke, cue given, then animal must collect
%     the reward within four seconds.
%   PHASE 4. nosepoke hold: same as phase 3, except mice must hold nosepoke for longer duration.
%   PHASE 5. nosepoke hold during two stimuli: now IOI (stimulus inter-onset interval) increases.
%   PHASE 6. correct choice: full task with punishment for incorrect choice
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
% slot1_vis and slot2_vis codes
%   0 - no visual cue
%   1 - LEDs 1 and 2 on
%   2 - LEDs 3 and 4 on
%   3 - all LEDs on
% 
% slot1_aud and slot2_aud codes
%   0 - no auditory cue
%   1 - low tone
%   2 - high tone
%   3 - buzzer
%   4 - white noise
  
clear all
close all





%% parameters for the mouse struct - these should never change
m.mouseName            = 'jaxmale08';  % should not change
m.requiredVersion      = 5;  % version of arduino DUE software required

% setting which cues are used for this animal - must be consistent for a given animal
% slot1_vis and slot2_vis codes
%   0 - no visual cue
%   1 - LEDs 1 and 2 on
%   2 - LEDs 3 and 4 on
%   3 - all LEDs on
m.leftVisCue         = 0;
m.rightVisCue        = 3;

% slot1_aud and slot2_aud codes
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

sessionStr.startTrialNum = 1;     % in case you stop and start on the same day
resetTimeYN              = 'yes'; %

sessionStr.maxSessionLength_min      = 60; % in minutes
sessionStr.maxTrials                 = 10000; % program terminates when either maxSessionLength_min or maxTrials is reached
sessionStr.maxRewards                = 200; % program also terminates if maxRewards is reached
sessionStr.interTrialInterval_mean   = 0;  % number of seconds between trials
sessionStr.interTrialInterval_SD     = 0; % standard deviation of seconds between trials

sessionStr.IrewardSize_nL = 5000; 
sessionStr.punishForErrorPokeYN      = 0; % 0 = no, 1 = yes for stage 5 only
sessionStr.cueWithdrawalPunishYN     = 0; % only 1 in phase 4-5

% info about trials - will figure out something more sophisticated later
allTrials = ones(1, sessionStr.maxTrials);
sessionStr.trialLRtype  = makeRandomVector([1 2 3 4 5 6], length(allTrials)); % (1 = LX, 2 = XL, 3 = RX, 4 = XR, 5 = LR, 6 = RL). No free choice until stage 3
sessionStr.trialLRtype_info = '(1 = LX, 2 = XL, 3 = RX, 4 = XR, 5 = LR, 6 = RL)';

% this is planning for the future, when we will likely want two auditory
% stimuli and two visual stimuli. For now, just leave it as all 3's
sessionStr.trialAVtype  = 3 * allTrials; % 1 = auditory only, 2 = visual only, 3 = both aud + vis
sessionStr.trialAVtype_info = '1 = auditory only, 2 = visual only, 3 = both aud + vis';

% just the starting values - they will be updated later
sessionStr.LrewardSize_nL      = 5000; % the starting value, which will be updated over time
sessionStr.RrewardSize_nL      = 5000;
sessionStr.rewardSizeMax_nL    = 8000;
sessionStr.rewardSizeMin_nL    = 2000;
sessionStr.rewardSizeDelta_nL  = 500; % the number of nanoliters to adjust reward size by to prevent 
sessionStr = makeRewardCodes_v5(sessionStr, 1:length(allTrials)); % adding reward codes to the struct

% in phase 3, mouse only gets 4 seconds to poke L or R
sessionStr.goToPokesLength     = 1000*4;

% cue lengths, etc. - for phases 3-5 only
sessionStr.preCueLength         = 0 * allTrials; % should be zero until stage 4, when it is gradually increased
sessionStr.cue1Length           = 100 * allTrials;
sessionStr.cue2Length           = 100 * allTrials;
sessionStr.interOnsetInterval   = 0 * allTrials; % in stage 4, the interOnsetInterval increases gradually
sessionStr.postCueLength        = 0 * allTrials;


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
elseif strfind(hostname, 'gammalsjul')
    m.basedir = '/home/luke/temp';
    m.serialPort = '/dev/ttyACM0';
else
	error('can''t figure out correct location to store files');
end

m.dateString = datestr(now, 29);
timeString = datestr(now, 30);
m.timeString = timeString(end-5:end);
sessionStr.timeString = m.timeString;
sessionStr.dateString = m.dateString;

%% creating directory to store the data, saving structs to disk
cd(m.basedir);
sessionStr.basename = [sessionStr.mouseName '_' datestr(now, 'yymmdd') '_' sessionStr.timeString];
sessionStr.basedir = [m.basedir '/' sessionStr.basename];
mkdir(sessionStr.basename);
cd(sessionStr.basename);



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
boxParams.update(pyargs('cueWithdrawalPunishYN', 0)); % setting to 1 enables punishment for poke withdrawal during cues

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
boxParams.update(pyargs('punishDelayLength',      1000*6));
boxParams.update(pyargs('preCueLength',           10));
boxParams.update(pyargs('slot1Length',             5));
boxParams.update(pyargs('slot2Length',             5));
boxParams.update(pyargs('slot3Length',             5));
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
nTrial = 1;
sessionStr.trialNum(nTrial) = sessionStr.startTrialNum -1 + nTrial;

% generate stuff for first trial
sessionStr = makeCues_v5(sessionStr, m, 1);


lastPos = 0;
totalRewards = 0;
close all

while exitNowYN == 0 && exitAfterTrialYN == 0
	
	% set box params for this trial

	
	% all reward codes default to zero and will be zero unless changed here
	
	clear trial_dict;
	trial_dict = py.dict; % empty python dict that fills only w/parameters that
	% are updated in the current trial.
	
	trial_dict.update(pyargs('nTrial', sessionStr.trialNum(nTrial)));
	trial_dict.update(pyargs('trainingPhase', sessionStr.trainingPhase));
	trial_dict.update(pyargs('goToPokesLength', sessionStr.goToPokesLength));
	
	% info about trial type - sent to arduino only so that they get
	% saved in text log file
	trial_dict.update(pyargs('trialLRtype', sessionStr.trialLRtype(nTrial)));
	trial_dict.update(pyargs('trialAVtype', sessionStr.trialAVtype(nTrial)));
	
	% reward info
	if sessionStr.trainingPhase==1
		trial_dict.update(pyargs('IrewardCode', 1));
	elseif sessionStr.trainingPhase==2
		trial_dict.update(pyargs('IrewardCode', 2));
	elseif sessionStr.trainingPhase>2
		trial_dict.update(pyargs('IrewardCode', 0));
	end
	
	trial_dict.update(pyargs('IrewardSize_nL', sessionStr.IrewardSize_nL));
	trial_dict.update(pyargs('LrewardCode', sessionStr.LrewardCode(nTrial)));
	trial_dict.update(pyargs('LrewardSize_nL', sessionStr.LrewardSize_nL(nTrial)));
	trial_dict.update(pyargs('RrewardCode', sessionStr.RrewardCode(nTrial)));
	trial_dict.update(pyargs('RrewardSize_nL', sessionStr.RrewardSize_nL(nTrial)));
	
	% cue info
	trial_dict.update(pyargs('slot1_vis', sessionStr.slot1_vis(nTrial)));
	trial_dict.update(pyargs('slot1_aud', sessionStr.slot1_aud(nTrial)));
	trial_dict.update(pyargs('slot2_vis', sessionStr.slot2_vis(nTrial)));
	trial_dict.update(pyargs('slot2_aud', sessionStr.slot2_aud(nTrial)));
	trial_dict.update(pyargs('slot3_vis', sessionStr.slot3_vis(nTrial)));
	trial_dict.update(pyargs('slot3_aud', sessionStr.slot3_aud(nTrial)));
	
	trial_dict.update(pyargs('cueWithdrawalPunishYN', sessionStr.cueWithdrawalPunishYN));
	trial_dict.update(pyargs('preCueLength', sessionStr.preCueLength(nTrial)));
	trial_dict.update(pyargs('slot1Length', sessionStr.slot1Length(nTrial)));
	trial_dict.update(pyargs('slot2Length', sessionStr.slot2Length(nTrial)));
	trial_dict.update(pyargs('slot3Length', sessionStr.slot3Length(nTrial)));
	trial_dict.update(pyargs('postCueLength', sessionStr.postCueLength(nTrial)));
	
	%% run actual trial
	fname = run2AFCSingleTrial(box1, sessionStr, trial_dict);
	
	%% extract trial info
	[trialStr, lastPos] = extractTrial_v2([sessionStr.basedir '/' sessionStr.basename '.txt'], lastPos);
	if any(contains(trialStr.eventType, 'eward'))
		sessionStr.rewardThisTrialYN(nTrial) = 1;
		totalRewards = totalRewards + 1;
	else
		sessionStr.rewardThisTrialYN(nTrial) = 0;
	end
	
	%% generate stuff for next trial
	sessionStr = makeCues_v5(sessionStr, m, nTrial+1);
	sessionStr.trialNum(nTrial+1) = sessionStr.trialNum(nTrial) + 1;

	
	%% adjust cue lengths, etc. (stage 4 only)
	
	
	%% copy reward sizes for next trial
	sessionStr.LrewardSize_nL(nTrial+1) = sessionStr.LrewardSize_nL(nTrial);
	sessionStr.RrewardSize_nL(nTrial+1) = sessionStr.RrewardSize_nL(nTrial);
	
	%% adjust reward sizes for free choice trials (phase 3 and 4 only)
 	if sessionStr.trialLRtype(nTrial)==5 || sessionStr.trialLRtype(nTrial)==6 % if it's a free choice trial
		if any(contains(trialStr.eventType, 'leftReward'))
			sessionStr.LrewardSize_nL(nTrial+1) = max(sessionStr.LrewardSize_nL(nTrial) - sessionStr.rewardSizeDelta_nL, sessionStr.rewardSizeMin_nL);
			sessionStr.RrewardSize_nL(nTrial+1) = min(sessionStr.RrewardSize_nL(nTrial) + sessionStr.rewardSizeDelta_nL, sessionStr.rewardSizeMax_nL);
			disp('left reward on free choice, reducing L reward size and increasing R reward size');
		elseif any(contains(trialStr.eventType, 'rightReward'))
			sessionStr.RrewardSize_nL(nTrial+1) = max(sessionStr.RrewardSize_nL(nTrial) - sessionStr.rewardSizeDelta_nL, sessionStr.rewardSizeMin_nL);
			sessionStr.LrewardSize_nL(nTrial+1) = min(sessionStr.LrewardSize_nL(nTrial) + sessionStr.rewardSizeDelta_nL, sessionStr.rewardSizeMax_nL);
			disp('right reward on free choice, increasing L reward size and reducing R reward size');
		end
	end
	
	%% reasons for exiting
	if toc(t)/60 > sessionStr.maxSessionLength_min
		disp('Session reached maximum duration. Exiting.');
		exitNowYN = 1;
	elseif nTrial > sessionStr.maxTrials
		disp('Maximum trial number reached. Exiting.');
		exitNowYN = 1;
	elseif totalRewards > sessionStr.maxRewards
		disp('Maximum number of rewards reached. Exiting.');
		exitNowYN = 1;
	end
	
	
	%% randomized inter-trial interval
	pause(sessionStr.interTrialInterval_mean + sessionStr.interTrialInterval_SD .* randn());
	nTrial = nTrial + 1;
end

%% save structs to disk
mouseStr = m;
save('mouseStr.mat', 'mouseStr');
save('sessionStr.mat', 'sessionStr');

%% stop camera
sendToArduino(box1, [], 'cameraRecordingYN', 0);


%% close arduino
fclose(box1);
close all force;
fprintf('Session completed.\n');



