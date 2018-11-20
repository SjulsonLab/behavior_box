% code for training phase 1, using arduino code v6
% Luke Sjulson, 2018-10-18

% ////////////////////////////////////////////////////////////////////////////
%   PHASE 1. collection: no white noise, mice get reward (in side poke) for poking the "correct"
%     sidepoke for that trial. Cue is given when animal does correct side poke. 
%   PHASE 2. initiation: white noise, animal must center poke to get reward delivered in side poke
%   PHASE 3. fast choice: white noise, center poke, cue given, then animal must collect
%     the reward within four seconds.
%   PHASE 4. nosepoke hold through precue, then nosepoke hold through increased IOI (stimulus inter-onset interval)
%   PHASE 5. correct choice: full task with punishment for incorrect choice
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
m.requiredVersion      = 6;  % version of arduino DUE software required

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

% for stages 1-2, this should be [1 3]. For stage 3 and higher, it should be [1:6]
sessionStr.trialLRtype  = makeRandomVector([1 3], length(allTrials)); % (1 = LX, 2 = XL, 3 = RX, 4 = XR, 5 = LR, 6 = RL). No free choice until stage 3
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

% in phases 3-5, mouse only gets 4 seconds to poke L or R
if sessionStr.trainingPhase>=3
    sessionStr.goToPokesLength     = 4 * 1000;
else
    sessionStr.goToPokesLength     = 60 * 1000;
end
    
% cue lengths, etc.
sessionStr.preCueLength         = 0 * allTrials; % should be zero until stage 4, when it is gradually increased
sessionStr.cue1Length           = 100 * allTrials;
sessionStr.cue2Length           = 100 * allTrials;
sessionStr.interOnsetInterval   = 0 * allTrials; % in stage 4, the interOnsetInterval increases gradually
sessionStr.postCueLength        = 0 * allTrials;


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
sessionStr = makeCues_v5(sessionStr, m, 1);
lastPos = 0;
totalRewards = 0;

close all

while exitNowYN == 0 && exitAfterTrialYN == 0
	
    %% create new trial_dict for each trial
	clear trial_dict;
    trial_dict = makeTrialDict(sessionStr, nTrial);
	
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

    %% copy reward sizes for next trial
	sessionStr.LrewardSize_nL(nTrial+1) = sessionStr.LrewardSize_nL(nTrial);
	sessionStr.RrewardSize_nL(nTrial+1) = sessionStr.RrewardSize_nL(nTrial);

    %% generate cues for next trial
	sessionStr = makeCues_v5(sessionStr, m, nTrial+1);
    sessionStr.trialNum(nTrial+1) = sessionStr.trialNum(nTrial) + 1;
    
    %% adjust reward sizes for free choice trials (phase 3 and 4 only)
    if sessionStr.trainingPhase==3 || sessionStr.trainingPhase==4
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
    end
    
	%% adjust cue lengths, etc. (stage 4 only)
    if sessionStr.trainingPhase==4
        % insert code here
        
        
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



