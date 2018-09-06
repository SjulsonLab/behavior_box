% code for all phases of training in the operant boxes.
% Daniela Cassataro updated v1  8/6/18 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% O L D %%%%%%%%%%%%%%%%%%%%%%
%     phase 1: white noise, init poke pre-rewarded. Animal pokes init, then gets cue, and
%              only one door opens, which is also pre-rewarded. Advance when animal gets reward quickly.
%     phase 2: same as phase 1 except neither poke is pre-rewarded
%     phase 3: same as phase 2 except two reward doors open, and only the correct one is rewarded. No punishment for
%              picking the wrong door. Try to keep this short.
%     phase 4: same as phase 3 except now the incorrect door is punished.
%     phase 5: increasing init poke duration. Also, rewards become probabilistic. Only outer doors open.
%     phase 6: no cue, only center door opens. Reward is probabilistic.
%     phase 7: full task. All three doors open on every trial.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     reward codes - they are independent of which poke is rewarded
%      0 - no reward
%      1 - reward init poke at ready signal
%      2 - reward on init nose poke
%      3 - reward at end of cue
%      4 - reward only upon nosepoke

%% parameters to set
startTrialNum          = 1;     % in case you stop and start on the same day
resetTimeYN            = 'yes'; %

m.mouseName            = 'ec-test-9-05-jaxmale03b';
m.trainingPhase        = 2;
m.auditoryCueSide      = 'right';  % this is specific for each animal and must be consistent between sessions
m.serialPort           = 'COM4'; % look this up in the arduino software
m.requiredVersion      = 9;  % version of arduino DUE fourPoke software required
m.sessionLength        = 60; % in minutes
m.maxTrials            = 300; % program terminates when either sessionLength or maxTrials is reached
m.interTrialInterval   = 2;  % number of seconds between trials

% need to set starting points for these for phases 5-7
LcueProb               = 50;  % again using units of percent
nosePokeHoldLength     = 50; % in units of milliseconds. Need to set this higher starting in phase 5

% i would like to update this section using exist to search for basedir.
% -dc
if strcmpi(computer, 'MACI64')
   m.basedir = '/Users/luke/Google Drive/lab-shared/lab_projects/rewardPrediction/behavior'; 
else
   m.basedir = 'G:\My Drive\lab-shared\lab_projects\rewardPrediction\behavior';
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

% put all default box params here
boxParams = py.dict;
boxParams.update(pyargs('nTrial',            startTrialNum));
boxParams.update(pyargs('resetTimeYN',       0)); % setting this to 1 sets the arduino clock zero and sends a sync pulse to the intan
boxParams.update(pyargs('initPokePunishYN',  0)); % setting to 1 enables punishment for initpoke during standby

boxParams.update(pyargs('WNvolume',      50));
boxParams.update(pyargs('lowCueVolume',  120));
boxParams.update(pyargs('highCueVolume', 120));
boxParams.update(pyargs('buzzerVolume',  90));

%boxParams.update(pyargs('cueHiLow',              0)); % -1 is low, 1 is high, and 0 is neither
boxParams.update(pyargs('auditoryOrVisualCue',   0)); % 0 is none, 1 is auditory, 2 is visual
boxParams.update(pyargs('trainingPhase',         m.trainingPhase));
boxParams.update(pyargs('doorCloseSpeed',        1)); % original default was 10
boxParams.update(pyargs('laserOnCode',           0));

boxParams.update(pyargs('IopenYN', 0)); % 1 means open port, 0 means keep closed
boxParams.update(pyargs('LopenYN', 0));
boxParams.update(pyargs('RopenYN', 0));
boxParams.update(pyargs('extra4openYN', 0));
boxParams.update(pyargs('extra5openYN', 0));

boxParams.update(pyargs('readyToGoLength',        1000*30));
boxParams.update(pyargs('punishDelayLength',      1000*16));
boxParams.update(pyargs('missedLength',           100));
boxParams.update(pyargs('preCueLength',           10));
boxParams.update(pyargs('auditoryCueLength',      200));
boxParams.update(pyargs('visualCueLength',        200));
boxParams.update(pyargs('postCueLength',          100));
boxParams.update(pyargs('goToPokesLength',        1000*60));
boxParams.update(pyargs('nosePokeHoldLength',     0));
boxParams.update(pyargs('rewardCollectionLength', 1000*5));

boxParams.update(pyargs('IrewardCode',  0));
boxParams.update(pyargs('LrewardCode',  0));
boxParams.update(pyargs('RrewardCode',  0));
boxParams.update(pyargs('extra4rewardCode',  0));
boxParams.update(pyargs('extra5rewardCode',  0));
boxParams.update(pyargs('extra6rewardCode',  0));

boxParams.update(pyargs('volumeInit_nL',        1000*5));
boxParams.update(pyargs('volumeLeft_nL',        1000*5));
boxParams.update(pyargs('volumeRight_nL',       1000*5));
boxParams.update(pyargs('deliveryDuration_ms',  1000));
boxParams.update(pyargs('syringeSize_mL',       5));

if strcmpi(m.auditoryCueSide, 'right') % if the aud cue side is right,
   boxParams.update(pyargs('isLeftAuditory', 0)); % set isleftauditory to 0
   rightCueType = 1; %right is auditory
   leftCueType = 2; %left is visual
else % if the aud cue side is left,
   boxParams.update(pyargs('isLeftAuditory', 1)); % set isleftauditory to 1
   leftCueType = 1; % left is auditory
   rightCueType = 2; % right is visual
end

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
f1 = figure;
maxOutcome2Length = 1;


%% send boxparams once to arduino, with slightly longer pause:
k = boxParams.keys;
d = boxParams.values;
for idx = 1:length(d)
   sendToArduino(box1, [], char(k{idx}), d{idx});
   pause(0.2); % extended the pause to 0.2 s
end




while toc(t)/60 < m.sessionLength && nTrial <= m.maxTrials && exitNowYN == 0 && exitAfterTrialYN == 0
   
   %% set box params for this trial
   % all reward codes default to zero and will be zero unless changed here
   
   % set according to training phase
   if m.trainingPhase == 1 % when rewards are given
      icode = 1;
   elseif m.trainingPhase == 2
      icode = 3;
   else
      icode = 0;
   end
   
   % whether the door opposite to the rewarded door opens
   if m.trainingPhase == 3  
      opdoor = 0;
      dcode = 3;
   elseif m.trainingPhase > 3
      opdoor = 1;
      dcode = 4;
   end
   
   P = py.dict; % empty python dict that fills only w/parameters that 
   % are updated in the current trial.
   % P is cleared after every trial (later,below)
   P.update(pyargs('nTrial', nTrial));
   P.update(pyargs('IrewardCode', icode)); 
   % 1 in phase1,    3 in phase2,     0 in all other phases
   P.update(pyargs('nosePokeHoldLength', nosePokeHoldLength));
   
   
   if m.trainingPhase >= 3
       if (LcueProb > round(rand()*99)) % if left cue
           P.update(pyargs('auditoryOrVisualCue', leftCueType)); %1 for aud/2 for vis
           P.update(pyargs('LrewardCode', dcode)); % 3 or 4
           P.update(pyargs('RrewardCode', 0)); % default is 0
           P.update(pyargs('LopenYN', 1));
           P.update(pyargs('RopenYN', opdoor)); % 0 or 1
       else %right cue
           P.update(pyargs('auditoryOrVisualCue', rightCueType)); %1 for aud/2 for vis
           P.update(pyargs('RrewardCode', dcode)); % 3 or 4
           P.update(pyargs('LrewardCode', 0)); % default is 0
           P.update(pyargs('RopenYN', 1));
           P.update(pyargs('LopenYN', opdoor)); % 0 or 1
       end
   end
   
   nTrial = nTrial + 1;
   
   
   %% run actual trial
   fname = runFivePokeSingleTrial(box1, m, P); 
   % only pass the freshly made P dict for THAT trial.
   
   clear P; % clear the P dict so it can be created again next trial:

   
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



