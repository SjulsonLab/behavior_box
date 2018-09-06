%% code for training in new five-poke boxes (or three-poke boxes capable of having five pokes)

%     phase 1: white noise, init poke pre-rewarded. Animal pokes init, then gets cue, and
%     only one door opens, which is also pre-rewarded. Advance when animal gets reward quickly.
% 
%     phase 2: same as phase 1 except neither poke is pre-rewarded
% 
%     phase 3: same as phase 2 except two reward doors open, and only the correct one is rewarded. No punishment for
%     picking the wrong door. Try to keep this short.
% 
%     phase 4: same as phase 3 except now the incorrect door is punished.
% 
%     phase 5: increasing init poke duration. Also, rewards become probabilistic. Only outer doors open.
% 
%     phase 6: no cue, only center door opens. Reward is probabilistic.
% 
%     phase 7: full task. All three doors open on every trial.
% 
% 
%   reward codes - they are independent of which poke is rewarded
%     0 - no reward
%     1 - reward init poke at ready signal
%     2 - reward on init nose poke
%     3 - reward at end of cue
%     4 - reward only upon nosepoke
    
%% parameters to set
startTrialNum          = 1;     % in case you stop and start on the same day
resetTimeYN            = 'yes'; %

m.mouseName            = 'clean';
m.trainingPhase        = 2;
m.low                  = 'left';  % this is specific for each animal and must be consistent between sessions
m.serialPort           = 'COM4'; % look this up in the arduino software
m.requiredVersion      = 8;  % version of arduino DUE fourPoke software required
m.sessionLength        = 60; % in minutes
m.maxTrials            = 300; % program terminates when either sessionLength or maxTrials is reached
m.interTrialInterval   = 2;  % number of seconds between trials
m.useInitPumpForCenter = 1;  % if this is set to 1, a center poke will activate the init syringe pump (for boxes with only three pumps)



% need to set starting points for these for phases 5-7
nosePokeHoldLength     = 200; % in units of milliseconds. Need to set this higher starting in phase 5
LrewardProb            = 100; % probability of reward in units of percent (so 100 is 100%)
CrewardProb            = 100;
RrewardProb            = 100;


if strcmpi(computer, 'MACI64')
    m.basedir = '/Users/luke/Google Drive/lab-shared/lab_projects/rewardPrediction/behavior';
else
    m.basedir = 'C:\Users\Luke\Google Drive\lab-shared\lab_projects\rewardPrediction\behavior';
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
boxParams.update(pyargs('nTrial',        startTrialNum));
boxParams.update(pyargs('resetTimeYN',   0)); % setting this to 1 sets the arduino clock zero and sends a sync pulse to the intan

boxParams.update(pyargs('WNvolume',      80));
boxParams.update(pyargs('lowCueVolume',  120));
boxParams.update(pyargs('highCueVolume', 120));
boxParams.update(pyargs('buzzerVolume',  90));

boxParams.update(pyargs('cueHiLow', 0)); % -1 is low, 1 is high, and 0 is neither
boxParams.update(pyargs('auditoryOrVisualCue', 1)); % 0 is none, 1 is auditory, 2 is visual
boxParams.update(pyargs('trainingPhase', m.trainingPhase));
boxParams.update(pyargs('doorCloseSpeed', 2)); % original default was 10
boxParams.update(pyargs('laserOnCode', 0));
boxParams.update(pyargs('useInitPumpForCenter', m.useInitPumpForCenter));

boxParams.update(pyargs('LopenYN', 0)); % 1 means open port, 0 means keep closed
boxParams.update(pyargs('CopenYN', 0));
boxParams.update(pyargs('RopenYN', 0));

boxParams.update(pyargs('readyToGoLength',        1000*30));
boxParams.update(pyargs('timeOutLength',          1000*3));
boxParams.update(pyargs('missedLength',           100));
boxParams.update(pyargs('preCueLength',           10));
boxParams.update(pyargs('auditoryCueLength',      200));
boxParams.update(pyargs('visualCueLength',        200));
boxParams.update(pyargs('postCueLength',          100));
boxParams.update(pyargs('goToPokesLength',        1000*60));
boxParams.update(pyargs('nosePokeHoldLength',     200));
boxParams.update(pyargs('rewardCollectionLength', 4000));

boxParams.update(pyargs('IrewardCode',  0));
boxParams.update(pyargs('LrewardCode',  0));
boxParams.update(pyargs('RrewardCode',  0));
boxParams.update(pyargs('CrewardCode',  0));

boxParams.update(pyargs('IrewardProb',  100));
boxParams.update(pyargs('LrewardProb',  100));
boxParams.update(pyargs('RrewardProb',  100));
boxParams.update(pyargs('CrewardProb',  50));


boxParams.update(pyargs('IrewardLength', 500)); % length in ms - calibrate for 10 uL
boxParams.update(pyargs('LrewardLength', 500)); % length in ms - calibrate for 10 uL
boxParams.update(pyargs('CrewardLength', 500)); % length in ms - calibrate for 10 uL
boxParams.update(pyargs('RrewardLength', 500)); % length in ms - calibrate for 10 uL

if strcmpi(m.low, 'right')
    boxParams.update(pyargs('isLeftLow', 0));
    rightCue = -1;
    leftCue = 1;
else
    boxParams.update(pyargs('isLeftLow', 1));
    leftCue = -1;
    rightCue = 1;
end

%% connect to arduino
delete(instrfindall);
box1 = serial(m.serialPort,'Timeout', 10, 'BaudRate', 115200, 'Terminator', 'LF');
fopen(box1);
pause(1);
fprintf(box1, 'checkVersion\n');
tstr = fgetl(box1);
if str2num(tstr) ~= m.requiredVersion
    error(sprintf('The arduino has version %d, but the matlab script requires version %d', str2num(tstr), m.requiredVersion));
end


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

while toc(t)/60 < m.sessionLength && nTrial <= m.maxTrials && exitNowYN == 0 && exitAfterTrialYN == 0
    
    %% set box params for this trial
    
    % set according to training phase
    if m.trainingPhase == 1  % when rewards are given
        icode = 1;
        dcode = 3;
    else
        icode = 0;
        dcode = 4;
    end
    
    if m.trainingPhase <= 2  % whether the door opposite to the rewarded door opens
        opdoor = 0;
    else
        opdoor = 1;
    end
    
    
    
    
    P = boxParams.copy;
    P.update(pyargs('nTrial', nTrial));
    P.update(pyargs('IrewardCode', icode));
    P.update(pyargs('nosePokeHoldLength', nosePokeHoldLength));
    
    % for training phases 1-5 or 7, open L and/or R doors. The arduino
    % determines whether or not to punish incorrect pokes based on the
    % training phase number.
    if m.trainingPhase <= 5 || m.trainingPhase == 7
        c = ceil(2*rand());
        switch c
            case 1 % left cue
                P.update(pyargs('LrewardCode', dcode));
                P.update(pyargs('LopenYN', 1));
                P.update(pyargs('RopenYN', opdoor));
                P.update(pyargs('cueHiLow', leftCue));
            case 2 % right cue
                P.update(pyargs('RrewardCode', dcode));
                P.update(pyargs('RopenYN', 1));
                P.update(pyargs('LopenYN', opdoor));
                P.update(pyargs('cueHiLow', rightCue));
        end
    end
    
    % for phases 5 and higher, probabilistic rewards
    if m.trainingPhase >= 5
        P.update(pyargs('LrewardProb', LrewardProb));
        P.update(pyargs('CrewardProb', CrewardProb));
        P.update(pyargs('RrewardProb', RrewardProb));
    end

    % for phases 6-7, also open center door
    if m.trainingPhase >= 6
       P.update(pyargs('CopenYN', 1));
       P.update(pyargs('CrewardCode', 4));
    end

    
    nTrial = nTrial + 1;


%% run actual trial
fname = runFivePokeSingleTrial(box1, m, P);

%% write additional parameters to logfile

% LcueProb - these are the parameters that never get passed to the arduino
% RcueProb
% noCueProb


%% read logfile, update plot







end

%% close arduino
fclose(box1);
close all force;
fprintf('Session completed.\n');



