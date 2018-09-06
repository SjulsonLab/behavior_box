%% code for training in new four-poke boxes

% training phases
% 1	reward init poke, play white noise, 1/4 doors open with correct cue, which is prerewarded
% 2	1/4 doors open with correct cue, not prerewarded.
% 3	2/4 doors (L vs R OR CL vs CR), no punishment
% 4	2/4 doors (L vs R OR CL vs CR), punishment of door closing and punish tone
% 5	increase init hold duration to 300ms. introduce probabilistic reward. start 0.9, end 0.8?
% 6 full task, all four doors open

%% parameters to set
startTrialNum          = 1;     % in case you stop and start on the same day
resetTimeYN            = 'yes'; %

m.trainingPhase        = 6;
m.mouseName            = 'fourPokeTest';
m.serialPort           = 'COM5'; % look this up in the arduino software
m.requiredVersion      = 7;  % version of arduino DUE fourPoke software required
m.sessionLength        = 35; % in minutes
m.maxTrials            = 10; % program terminates when either sessionLength or maxTrials is reached
m.interTrialInterval   = 2;  % number of seconds between trials
m.low                  = 'right';         % this is specific for each animal and must be consistent between sessions

% need to set starting points for these for phases 5-6
nosePokeHoldLength     = 0;   % need to set this higher for phase 5
LrewardProb            = 0.9; % probability of reward at each port
CLrewardProb           = 0.9;
CRrewardProb           = 0.9;
RrewardProb            = 0.9;


if strcmpi(computer, 'MACI64')
    m.basedir = '/Users/luke/Google Drive/lab-shared/lab_projects/rewardPrediction/behavior';
else
    m.basedir = 'E:\Google Drive\lab-shared\lab_projects\rewardPrediction\behavior';
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

boxParams.update(pyargs('LopenYN',  0)); % 1 means open port, 0 means keep closed
boxParams.update(pyargs('CLopenYN', 0));
boxParams.update(pyargs('RopenYN',  0));
boxParams.update(pyargs('CRopenYN', 0));

boxParams.update(pyargs('readyToGoLength',        3000));
boxParams.update(pyargs('timeOutLength',          3000));
boxParams.update(pyargs('missedLength',           100));
boxParams.update(pyargs('preCueLength',           10));
boxParams.update(pyargs('auditoryCueLength',      200));
boxParams.update(pyargs('visualCueLength',        200));
boxParams.update(pyargs('postCueLength',          100));
boxParams.update(pyargs('goToPokesLength',        3000));
boxParams.update(pyargs('nosePokeHoldLength',     200));
boxParams.update(pyargs('rewardCollectionLength', 2000));

boxParams.update(pyargs('IrewardCode',  0));
boxParams.update(pyargs('LrewardCode',  0));
boxParams.update(pyargs('CLrewardCode', 0));
boxParams.update(pyargs('RrewardCode',  0));
boxParams.update(pyargs('CRrewardCode', 0));

boxParams.update(pyargs('IrewardProb',  100));
boxParams.update(pyargs('LrewardProb',  100));
boxParams.update(pyargs('CLrewardProb', 100));
boxParams.update(pyargs('RrewardProb',  100));
boxParams.update(pyargs('CRrewardProb', 100));

boxParams.update(pyargs('IrewardLength',  500)); % length in ms - calibrate for 10 uL
boxParams.update(pyargs('LrewardLength',  500)); % length in ms - calibrate for 10 uL
boxParams.update(pyargs('CLrewardLength', 500)); % length in ms - calibrate for 10 uL
boxParams.update(pyargs('RrewardLength',  500)); % length in ms - calibrate for 10 uL
boxParams.update(pyargs('CRrewardLength', 500)); % length in ms - calibrate for 10 uL

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
        icode = 2;
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
    
    % randomly choosing which ports are cued/rewarded and opened
    if m.trainingPhase <= 5
        c = ceil(4*rand());
        switch c
            case 1
                P.update(pyargs('LrewardCode', dcode));
                P.update(pyargs('LopenYN', 1));
                P.update(pyargs('RopenYN', opdoor));
                P.update(pyargs('cueHiLow', leftCue));
            case 2
                P.update(pyargs('CLrewardCode', dcode));
                P.update(pyargs('CLopenYN', 1));
                P.update(pyargs('CRopenYN', opdoor));
                P.update(pyargs('cueHiLow', leftCue));
            case 3
                P.update(pyargs('CRrewardCode', dcode));
                P.update(pyargs('CRopenYN', 1));
                P.update(pyargs('CLopenYN', opdoor));
                P.update(pyargs('cueHiLow', rightCue));
            case 4
                P.update(pyargs('RrewardCode', dcode));
                P.update(pyargs('RopenYN', 1));
                P.update(pyargs('LopenYN', opdoor));
                P.update(pyargs('cueHiLow', rightCue));
        end
    else % phase 6
        c = ceil(2*rand());
        switch c
            case 1
                P.update(pyargs('LrewardCode', dcode));
                P.update(pyargs('CLrewardCode', dcode));
                P.update(pyargs('cueHiLow', leftCue));
            case 2
                P.update(pyargs('RrewardCode', dcode));
                P.update(pyargs('CRrewardCode', dcode));
                P.update(pyargs('cueHiLow', rightCue));
        end
        P.update(pyargs('CRopenYN', 1));
        P.update(pyargs('CLopenYN', 1));
        P.update(pyargs('RopenYN', 1));
        P.update(pyargs('LopenYN', 1));
    end
    
    % adding in probabilistic rewards
    if m.trainingPhase >= 5
        P.update(pyargs('LrewardProb', LrewardProb));
        P.update(pyargs('CLrewardProb', CLrewardProb));
        P.update(pyargs('CRrewardProb', CRrewardProb));
        P.update(pyargs('RrewardProb', RrewardProb));
    end
    
    nTrial = nTrial + 1;


%% run actual trial
fname = runFourPokeSingleTrial(box1, m, P);

%% read logfile, update plot







end

%% close arduino
fclose(box1);
close all force;
fprintf('Session completed.\n');



