%% this is the test code to run for phase 1

% phase 1: animal nosepokes init poke in response to white noise, receives cue, and
% only one door opens.



%% parameters to set
startTrialNum          = 1;     % in case you stop and start on the same day
resetTimeYN            = 'yes'; %

m.mouseName            = 'fourPokeTest';
m.trainingPhase        = 1;
m.serialPort           = 'COM5'; % look this up in the arduino software
m.requiredVersion      = 7;  % version of arduino DUE fourPoke software required
m.sessionLength        = 35; % in minutes
m.maxTrials            = 3; % program terminates when either sessionLength or maxTrials is reached
m.interTrialInterval   = 2;  % number of seconds between trials
m.low                  = 'right';         % this is specific for each animal and must be consistent between sessions


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
boxParams.update(pyargs('lowCueVolume',  80));
boxParams.update(pyargs('highCueVolume', 40));
boxParams.update(pyargs('buzzerVolume',  90));

boxParams.update(pyargs('trainingPhase',  m.trainingPhase));
boxParams.update(pyargs('doorCloseSpeed', 2)); % original default was 10
boxParams.update(pyargs('laserOnCode',    0));

boxParams.update(pyargs('LopenYN',  0)); % 1 means open port, 0 means keep closed
boxParams.update(pyargs('CLopenYN', 0));
boxParams.update(pyargs('RopenYN',  0));
boxParams.update(pyargs('CRopenYN', 0));

boxParams.update(pyargs('readyToGoLength',        60000));
boxParams.update(pyargs('timeOutLength',          3000));
boxParams.update(pyargs('missedLength',           100));
boxParams.update(pyargs('preCueLength',           10));
boxParams.update(pyargs('auditoryCueLength',      200));
boxParams.update(pyargs('visualCueLength',        200));
boxParams.update(pyargs('postCueLength',          100));
boxParams.update(pyargs('goToPokesLength',        60000));
boxParams.update(pyargs('nosePokeHoldLength',     0));
boxParams.update(pyargs('rewardCollectionLength', 4000));

boxParams.update(pyargs('IrewardCode',  0));
boxParams.update(pyargs('LrewardCode',  0));
boxParams.update(pyargs('CLrewardCode', 0));
boxParams.update(pyargs('RrewardCode',  0));
boxParams.update(pyargs('CRrewardCode', 0));

boxParams.update(pyargs('IrewardLength',  500)); % length in ms - calibrate for 10 uL
boxParams.update(pyargs('LrewardLength',  500)); % length in ms - calibrate for 10 uL
boxParams.update(pyargs('CLrewardLength', 500)); % length in ms - calibrate for 10 uL
boxParams.update(pyargs('RrewardLength',  500)); % length in ms - calibrate for 10 uL
boxParams.update(pyargs('CRrewardLength', 500)); % length in ms - calibrate for 10 uL

if strcmpi(m.low, 'right')
   boxParams.update(pyargs('isLeftLow', 0));
else
   boxParams.update(pyargs('isLeftLow', 1));
end

%% connect to arduino
box1 = serial(m.serialPort,'Timeout', 10, 'BaudRate', 115200, 'Terminator', 'LF');
fopen(box1);
pause(1);
fprintf(box1, 'checkVersion\n');
tstr = fgetl(s);
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
   
   %% set box params for this trial - this part is specific for training phase 1
   P = boxParams.copy;
   P.update(pyargs('nTrial', nTrial));
   P.update(pyargs('IrewardCode', 1));
   
   % randomly choosing which one opens
   c = ceil(4*rand());
   switch c
      case 1
         P.update(pyargs('LrewardCode', 3));
         P.update(pyargs('LopenYN', 1));
      case 2
         P.update(pyargs('CLrewardCode', 3));
         P.update(pyargs('CLopenYN', 1));
      case 3
         P.update(pyargs('CRrewardCode', 3));
         P.update(pyargs('CRopenYN', 1));
      case 4
         P.update(pyargs('RrewardCode', 3));
         P.update(pyargs('RopenYN', 1));
   end
   
   %% run actual trial
   fname = runFourPokeSingleTrial(box1, m, P);
   
   %% read logfile, update plot
   
   
   
   
   
   
   
   
   
   
end

%% close arduino
fclose(box1);
fprintf('Session completed.\n');



