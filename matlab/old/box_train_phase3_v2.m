%% this is the test code to run sessions with training phase 3:
% animal initiates trial, gets cue, L and R doors open. Correct choice
% rewarded deterministically and incorrect choice punished.



%% parameters to set
m.basedir = 'E:\Google Drive\lab-shared\lab_projects\rewardPrediction\behavior'; % set this later
m.mouseName = 'D1R77_7';
m.trainingPhase = 3;
m.serialPort = 'COM5'; % look this up in the arduino software
m.requiredVersion      = 3;  % version of arduino DUE_threePoke software required
m.sessionLength        = 6; % in minutes
m.maxTrials            = 400; % program terminates when either sessionLength or maxTrials is reached
m.interTrialInterval   = 2; % number of seconds between trials

m.low = 'left';         % this is specific for each animal and must be consistent between sessions

% reward codes - they are independent of which poke is rewarded
%     0 - no reward
%     1 - reward init poke at ready signal
%     2 - reward on init nose poke
%     3 - reward at end of cue
%     4 - reward only upon nosepoke

% put all params here
m.nTrial = 301; % can reset this if you changed some parameters before running more trials

% resetting counter - comment out if you're restarting this after
pidx = 0;
pidx = pidx + 1; param(pidx).fieldname = 'resetTimeYN'; param(pidx).val = 1;

% parameters that get set once per session
pidx = pidx + 1; param(pidx).fieldname = 'trainingPhase'; param(pidx).val = m.trainingPhase;
pidx = pidx + 1; param(pidx).fieldname = 'LopenYN'; param(pidx).val = 1; % 1 means open port, 0 means keep closed
pidx = pidx + 1; param(pidx).fieldname = 'CopenYN'; param(pidx).val = 0;
pidx = pidx + 1; param(pidx).fieldname = 'RopenYN'; param(pidx).val = 1;

pidx = pidx + 1; param(pidx).fieldname = 'readyToGoLength'; param(pidx).val = 5*6000;
pidx = pidx + 1; param(pidx).fieldname = 'missedLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'preCueLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'auditoryCueLength'; param(pidx).val = 200;
pidx = pidx + 1; param(pidx).fieldname = 'visualCueLength'; param(pidx).val = 200;
pidx = pidx + 1; param(pidx).fieldname = 'postCueLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'goToPokesLength'; param(pidx).val = 600000;
pidx = pidx + 1; param(pidx).fieldname = 'nosePokeHoldLength'; param(pidx).val = 0; % set to zero for phases 1-3, then increases in phase 4
pidx = pidx + 1; param(pidx).fieldname = 'rewardCollectionLength'; param(pidx).val = 5000;

pidx = pidx + 1; param(pidx).fieldname = 'LrewardLength'; param(pidx).val = 500; % length in ms - calibrate for 10 uL
pidx = pidx + 1; param(pidx).fieldname = 'CrewardLength'; param(pidx).val = 500; % length in ms - calibrate for 10 uL
pidx = pidx + 1; param(pidx).fieldname = 'RrewardLength'; param(pidx).val = 500; % length in ms - calibrate for 10 uL
pidx = pidx + 1; param(pidx).fieldname = 'doorCloseSpeed'; param(pidx).val = 2; % default was 10


%% parameters that get set for each trial
m.laserOnCode = 0;

% randvec = round(rand(300, 1)); % used for generating initial random vector
% fprintf('%d ', randvec)
randvec = [1 0 1 1 0 1 1 1 1 1 0 0 0 0 1 0 0 0 0 0 0 1 0 0 1 1 0 0 0 0 1 0 1 1 0 0 0 0 0 1 0 0 1 0 1 1 0 1 0 0 1 1 1 0 0 1 1 0 0 1 0 1 1 1 0 0 0 1 0 1 0 1 0 1 1 1 1 0 1 0 0 1 1 0 1 1 1 1 1 1 0 0 1 0 0 0 1 1 1 0 0 1 0 0 1 0 1 1 1 0 1 1 1 1 1 0 0 1 0 0 0 0 1 1 0 0 1 0 1 1 0 0 0 1 0 0 0 0 0 0 1 1 0 1 0 0 1 1 0 1 0 1 1 1 1 1 0 0 1 0 0 1 1 1 0 0 0 1 0 1 1 0 0 0 0 0 1 0 0 1 0 0 1 0 1 1 1 0 1 0 1 1 1 0 1 0 0 0 0 0 0 0 1 0 1 1 1 0 0 0 1 1 0 1 1 1 1 0 0 1 1 0 0 0 0 0 0 1 0 1 1 1 1 1 0 1 0 1 1 0 0 0 1 1 0 1 1 0 1 0 1 0 0 0 0 1 0 1 0 0 0 1 0 0 0 1 0 1 0 1 0 1 0 0 0 1 1 1 0 1 1 1 1 1 0 1 0 0 1 0 0 1 1 0 1 0 1 1 0 1];

m.LrewardCode = 4 * randvec;
m.CrewardCode = 0;
m.RrewardCode = 4 * (1-randvec);

% set cues to correspond to whether L or R is rewarded
m.cueHiLow = zeros(size(m.LrewardCode)); % -1 is low, 1 is high, and 0 is neither
if strcmpi(m.low, 'left')
    m.cueHiLow(randvec==1) = -1;
    m.cueHiLow(randvec==0) = 1;
else
    m.cueHiLow(randvec==1) = 1;
    m.cueHiLow(randvec==0) = -1;
end

m.auditoryOrVisualCue = 1; % 1 for auditory, 2 for visual, 0 for no cue


%% start of actual program - after initial debugging, nothing below this line should be edited
runTrials(m, param);


