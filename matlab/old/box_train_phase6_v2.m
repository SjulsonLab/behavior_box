%% this is the test code to run sessions with training phase 6
%  full task - all three doors open, all rewards are probabilistic



%% parameters to set
m.basedir = 'E:\Google Drive\lab-shared\lab_projects\rewardPrediction\behavior'; % set this later
m.mouseName = 'mouse1';
m.trainingPhase = 6;
m.serialPort = 'COM5'; % look this up in the arduino software
m.requiredVersion      = 3;  % version of arduino DUE_threePoke software required
m.sessionLength        = 60; % in minutes
m.maxTrials            = 10; % program terminates when either sessionLength or maxTrials is reached
m.interTrialInterval   = 2;  % number of seconds between trials

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

pidx = pidx + 1; param(pidx).fieldname = 'readyToGoLength'; param(pidx).val = 5*6000;
pidx = pidx + 1; param(pidx).fieldname = 'missedLength'; param(pidx).val = 3000;
pidx = pidx + 1; param(pidx).fieldname = 'preCueLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'auditoryCueLength'; param(pidx).val = 200;
pidx = pidx + 1; param(pidx).fieldname = 'visualCueLength'; param(pidx).val = 200;
pidx = pidx + 1; param(pidx).fieldname = 'postCueLength'; param(pidx).val = 100;
pidx = pidx + 1; param(pidx).fieldname = 'goToPokesLength'; param(pidx).val = 600000;
pidx = pidx + 1; param(pidx).fieldname = 'nosePokeHoldLength'; param(pidx).val = 200; % set to zero for phases 1-3, then increases in phase 4
pidx = pidx + 1; param(pidx).fieldname = 'rewardCollectionLength'; param(pidx).val = 2000;

pidx = pidx + 1; param(pidx).fieldname = 'LrewardLength'; param(pidx).val = 1000; % length in ms - calibrate for 10 uL
pidx = pidx + 1; param(pidx).fieldname = 'CrewardLength'; param(pidx).val = 1000; % length in ms - calibrate for 10 uL
pidx = pidx + 1; param(pidx).fieldname = 'RrewardLength'; param(pidx).val = 1000; % length in ms - calibrate for 10 uL
pidx = pidx + 1; param(pidx).fieldname = 'doorCloseSpeed'; param(pidx).val = 2; % default was 10


%% parameters that get set for each trial
m.laserOnCode = 0;

% sample expt using blocks of 20 trials with changing reward contingencies
Lprob = [0.9*ones(20,1); 0.2*ones(20,1); 0.9*ones(20,1)]';
Rprob = [0.9*ones(20,1); 0.9*ones(20,1); 0.2*ones(20,1)]';
Cprob = [0.4*ones(60,1)]';

% randvec = round(rand(300, 1)); % used for generating initial random vector: 1 is left and 0 is right
% fprintf('%d ', randvec)
LRvec = [1 0 1 1 0 1 1 1 1 1 0 0 0 0 1 0 0 0 0 0 0 1 0 0 1 1 0 0 0 0 1 0 1 1 0 0 0 0 0 1 0 0 1 0 1 1 0 1 0 0 1 1 1 0 0 1 1 0 0 1 0 1 1 1 0 0 0 1 0 1 0 1 0 1 1 1 1 0 1 0 0 1 1 0 1 1 1 1 1 1 0 0 1 0 0 0 1 1 1 0 0 1 0 0 1 0 1 1 1 0 1 1 1 1 1 0 0 1 0 0 0 0 1 1 0 0 1 0 1 1 0 0 0 1 0 0 0 0 0 0 1 1 0 1 0 0 1 1 0 1 0 1 1 1 1 1 0 0 1 0 0 1 1 1 0 0 0 1 0 1 1 0 0 0 0 0 1 0 0 1 0 0 1 0 1 1 1 0 1 0 1 1 1 0 1 0 0 0 0 0 0 0 1 0 1 1 1 0 0 0 1 1 0 1 1 1 1 0 0 1 1 0 0 0 0 0 0 1 0 1 1 1 1 1 0 1 0 1 1 0 0 0 1 1 0 1 1 0 1 0 1 0 0 0 0 1 0 1 0 0 0 1 0 0 0 1 0 1 0 1 0 1 0 0 0 1 1 1 0 1 1 1 1 1 0 1 0 0 1 0 0 1 1 0 1 0 1 1 0 1];

% randomly generate reward patterns
Lidx = rand(size(Lprob)) < Lprob;
m.LrewardCode = LRvec(1:length(Lidx)) + Lidx;
m.LrewardCode(m.LrewardCode==1) = 0;
m.LrewardCode(m.LrewardCode==2) = 4;

Ridx = rand(size(Rprob)) < Rprob;
m.RrewardCode = (1-LRvec(1:length(Lidx))) + Ridx;
m.RrewardCode(m.RrewardCode==1) = 0;
m.RrewardCode(m.RrewardCode==2) = 4;

m.CrewardCode = (rand(size(Cprob)) < Cprob) * 4;

% set cues to correspond to whether L or R is rewarded
m.cueHiLow = zeros(size(LRvec)); % -1 is low, 1 is high, and 0 is neither
if strcmpi(m.low, 'left')
    m.cueHiLow(LRvec==1) = -1;
    m.cueHiLow(LRvec==0) = 1;
else
    m.cueHiLow(LRvec==1) = 1;
    m.cueHiLow(LRvec==0) = -1;
end

m.auditoryOrVisualCue = 1; % 1 for auditory, 2 for visual, 0 for no cue


%% start of actual program - after initial debugging, nothing below this line should be edited

runTrials(m, param);