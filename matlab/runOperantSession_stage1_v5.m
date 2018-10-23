% code for training phase 1, using arduino code v5
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
sessionStr.trainingPhase = 1;

sessionStr.startTrialNum = 1;     % in case you stop and start on the same day
resetTimeYN              = 'yes'; %

sessionStr.sessionLength             = 60; % in minutes
sessionStr.maxTrials                 = 10000; % program terminates when either sessionLength or maxTrials is reached
sessionStr.maxRewards                = 200; % program also terminates if maxRewards is reached
sessionStr.interTrialInterval_mean   = 0;  % number of seconds between trials
sessionStr.interTrialInterval_SD     = 0 ; % standard deviation of seconds between trials

sessionStr.IrewardSize_nL = 5000; 
sessionStr.punishForErrorPoke = 'no'; % 0 for no, 1 for yes
sessionStr.cueWithdrawalPunishYN = 0; % 0 for no, 1 for yes

% sessionStr.phase3_firstblock = 'no'; % if 'yes', in phase 3 the left/right pokes get pre-rewarded

% info about trials - will figure out something more sophisticated later
sessionStr.trialLRtype  = [1 2 2 1 2 2 1 1 2 1 2 1 2 1]; % 1 = left, 2 = right, 3 = free choice (i.e. both). No free choice until stage 3
sessionStr.trialLRtype_info = '1 = left, 2 = right, 3 = free choice (i.e. both)';

sessionStr.trialAVtype  = [3 3 3 3 3 3 3 3 3 3 3 3 3 3]; % 1 = auditory only, 2 = visual only, 3 = both aud + vis
sessionStr.trialAVtype_info = '1 = auditory only, 2 = visual only, 3 = both aud + vis';

sessionStr.leftCueWhen  = ones(size(sessionStr.trialLRtype)); % 1 = first cue slot, 2 = second cue slot, 3 = both cue slots
sessionStr.leftCueWhen_info = '1 = first cue slot, 2 = second cue slot, 3 = both cue slots';
sessionStr.rightCueWhen = ones(size(sessionStr.trialLRtype)); % 1 = first cue slot, 2 = second cue slot, 3 = both cue slots
sessionStr.rightCueWhen_info = '1 = first cue slot, 2 = second cue slot, 3 = both cue slots';

sessionStr.LrewardSize_nL = 5000 * ones(size(sessionStr.trialLRtype));
sessionStr.RrewardSize_nL = 5000 * ones(size(sessionStr.trialLRtype));

sessionStr = makeRewardCodes(sessionStr); % adding reward codes to the struct

% cue lengths, etc.
sessionStr.preCueLength   = 1;
sessionStr.slot1Length     = 100;
sessionStr.slot2Length     = 0;
sessionStr.slot3Length     = 0;
sessionStr.postCueLength  = 0;

[slot1_vis, slot1_aud, slot2_vis, slot2_aud, slot3_vis, slot3_aud] = makeCueVectors_3cue(sessionStr, m);



%% figuring out where to save the log files and which computer we're on
m = setSerialPort(m); % edit this file if you want to change serial ports or add a new machine

%% creating directory to store the data
sessionStr = makeNewDataDirectory(sessionStr, m);
cd(sessionStr.basedir);

%% put all default box params here
boxParams = setDefaultBoxParams(sessionStr);


%% connect to arduino
box1 = connectToArduino(m);

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

% generate stuff for first trial
t = tic;
nTrial = 1;
sessionStr.trialNum(nTrial) = sessionStr.startTrialNum -1 + nTrial;
% sessionStr = makeCues_v5(sessionStr, m, 1);
lastPos = 0;
totalRewards = 0;

% t = tic;
% nTrial = sessionStr.startTrialNum;
% lastPos = 0;
% totalRewards = 0;
close all

while exitNowYN == 0 && exitAfterTrialYN == 0
	
	% set box params for this trial
	% all reward codes default to zero and will be zero unless changed here
	
    %% create new trial_dict for each trial
% 	clear trial_dict;
%     trial_dict = makeTrialDict(sessionStr, nTrial);
    
	clear trial_dict;
	trial_dict = py.dict; % empty python dict that fills only w/parameters that
	% are updated in the current trial.
	
	trial_dict.update(pyargs('nTrial', nTrial));
	trial_dict.update(pyargs('trainingPhase', sessionStr.trainingPhase));
	
	
	% info about trial type - sent to arduino only so that they get
	% saved in text log file
	trial_dict.update(pyargs('trialLRtype', sessionStr.trialLRtype(nTrial)));
	trial_dict.update(pyargs('trialAVtype', sessionStr.trialAVtype(nTrial)));
	
	% reward info
	trial_dict.update(pyargs('IrewardCode', 1));
	trial_dict.update(pyargs('IrewardSize_nL', sessionStr.IrewardSize_nL));
	trial_dict.update(pyargs('LrewardCode', sessionStr.LrewardCode(nTrial)));
	trial_dict.update(pyargs('LrewardSize_nL', sessionStr.LrewardSize_nL(nTrial)));
	trial_dict.update(pyargs('RrewardCode', sessionStr.RrewardCode(nTrial)));
	trial_dict.update(pyargs('RrewardSize_nL', sessionStr.RrewardSize_nL(nTrial)));
	
	% cue info
	trial_dict.update(pyargs('slot1_vis', slot1_vis(nTrial)));
	trial_dict.update(pyargs('slot1_aud', slot1_aud(nTrial)));
	trial_dict.update(pyargs('slot2_vis', slot2_vis(nTrial)));
	trial_dict.update(pyargs('slot2_aud', slot2_aud(nTrial)));
	
	trial_dict.update(pyargs('cueWithdrawalPunishYN', sessionStr.cueWithdrawalPunishYN));
	trial_dict.update(pyargs('preCueLength', sessionStr.preCueLength));
	trial_dict.update(pyargs('slot1Length', sessionStr.slot1Length));
	trial_dict.update(pyargs('slot2Length', sessionStr.slot2Length));
	trial_dict.update(pyargs('slot3Length', sessionStr.slot3Length));
	trial_dict.update(pyargs('postCueLength', sessionStr.postCueLength));
% 	
	
	
	nTrial = nTrial + 1;
	
	
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
	
	%% reasons for exiting
	if toc(t)/60 > sessionStr.sessionLength
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
	
end

%% stop camera
sendToArduino(box1, [], 'cameraRecordingYN', 0);


%% close arduino
fclose(box1);
% close all force;
fprintf('Session completed.\n');



