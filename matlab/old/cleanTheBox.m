%% this is the test code to run an initial training session

% for training phase 1, the box plays white noise and prerewards the init poke. When
% the animal collects the reward from the init poke, the white noise shuts
% off, and the left and right poke doors open to reveal rewards. When the
% animal collects each, the associated cue plays. After the animal has
% collected each, the doors close and a new trial is initiated.


%% parameters to set
m.basedir = 'C:\Users\Luke\Google Drive\lab-shared\lab_projects\rewardPrediction\behavior'; % set this later
m.mouseName = 'clean';
m.trainingPhase = 1;
m.serialPort = 'COM5'; % look this up in the arduino software
m.requiredVersion      = 8;  % version of arduino DUE_threePoke software required
m.sessionLength        = 10; % in minutes
m.maxTrials            = 1; % program terminates when either m.sessionLength or m.maxTrials is reached
m.interTrialInterval   = 2; % number of seconds between trials

m.low = 'left';         % this is specific for each animal and must be consistent between sessions

% reward codes - they are independent of which poke is rewarded
%     0 - no reward
%     1 - reward init poke at ready signal
%     2 - reward on init nose poke
%     3 - reward at end of cue
%     4 - reward only upon nosepoke

% put all params here
m.nTrial = 1; % can reset this if you changed some parameters before running more trials

% resetting counter - comment out if you're restarting this after
pidx = 0;
pidx = pidx + 1; param(pidx).fieldname = 'resetTimeYN'; param(pidx).val = 1;

% parameters that get set once per session
pidx = pidx + 1; param(pidx).fieldname = 'trainingPhase'; param(pidx).val = m.trainingPhase;
pidx = pidx + 1; param(pidx).fieldname = 'LopenYN'; param(pidx).val = 1; % 1 means open port, 0 means keep closed
pidx = pidx + 1; param(pidx).fieldname = 'CopenYN'; param(pidx).val = 1;
pidx = pidx + 1; param(pidx).fieldname = 'RopenYN'; param(pidx).val = 1;

pidx = pidx + 1; param(pidx).fieldname = 'readyToGoLength'; param(pidx).val = 5*60000;
pidx = pidx + 1; param(pidx).fieldname = 'missedLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'preCueLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'auditoryCueLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'visualCueLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'postCueLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'goToPokesLength'; param(pidx).val = 10*60000;
pidx = pidx + 1; param(pidx).fieldname = 'nosePokeHoldLength'; param(pidx).val = 0; % set to zero for phases 1-3, then increases in phase 4
pidx = pidx + 1; param(pidx).fieldname = 'rewardCollectionLength'; param(pidx).val = 6000;

pidx = pidx + 1; param(pidx).fieldname = 'LrewardLength'; param(pidx).val = 1000; % length in ms - calibrate for 10 uL
pidx = pidx + 1; param(pidx).fieldname = 'CrewardLength'; param(pidx).val = 1000; % length in ms - calibrate for 10 uL
pidx = pidx + 1; param(pidx).fieldname = 'RrewardLength'; param(pidx).val = 1000; % length in ms - calibrate for 10 uL
pidx = pidx + 1; param(pidx).fieldname = 'doorCloseSpeed'; param(pidx).val = 0.05; % default was 10


%% parameters that get set for each trial
m.laserOnCode = 0;
m.LrewardCode = 0;
m.CrewardCode = 0;
m.RrewardCode = 0;
m.cueHiLow    = 0;  % -1 is low, 1 is high, and 0 is neither
m.auditoryOrVisualCue = 0;



%% start of actual program - after initial debugging, nothing below this line should be edited

runTrials(m, param);




