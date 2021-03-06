%% this is the test code to run an initial training session

% for training phase 1, the box plays white noise and prerewards the init poke. When
% the animal collects the reward from the init poke, the white noise shuts
% off, and the left and right poke doors open to reveal rewards. When the
% animal collects each, the associated cue plays. After the animal has
% collected each, the doors close and a new trial is initiated.


%% parameters to set
basedir = 'E:\Google Drive\lab-shared\lab_projects\rewardPrediction\behavior'; % set this later
mouseName = 'CLEAN';
trainingPhase = 1;
serialPort = 'COM5'; % look this up in the arduino software
requiredVersion      = 3;  % version of arduino DUE_threePoke software required
sessionLength        = 20; % in minutes
maxTrials            = 20; % program terminates when either sessionLength or maxTrials is reached
interTrialInterval   = 2; % number of seconds between trials

low = 'left';         % this is specific for each animal and must be consistent between sessions

% reward codes - they are independent of which poke is rewarded
%     0 - no reward
%     1 - reward init poke at ready signal
%     2 - reward on init nose poke
%     3 - reward at end of cue
%     4 - reward only upon nosepoke

% put all params here
nTrial = 16; % can reset this if you changed some parameters before running more trials

% resetting counter - comment out if you're restarting this after
pidx = 0;
pidx = pidx + 1; param(pidx).fieldname = 'resetTimeYN'; param(pidx).val = 1;

% parameters that get set once per session
pidx = pidx + 1; param(pidx).fieldname = 'trainingPhase'; param(pidx).val = trainingPhase;
pidx = pidx + 1; param(pidx).fieldname = 'LopenYN'; param(pidx).val = 1; % 1 means open port, 0 means keep closed
pidx = pidx + 1; param(pidx).fieldname = 'CopenYN'; param(pidx).val = 0;
pidx = pidx + 1; param(pidx).fieldname = 'RopenYN'; param(pidx).val = 1;

pidx = pidx + 1; param(pidx).fieldname = 'readyToGoLength'; param(pidx).val = 5*60000;
pidx = pidx + 1; param(pidx).fieldname = 'missedLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'preCueLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'auditoryCueLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'visualCueLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'postCueLength'; param(pidx).val = 10;
pidx = pidx + 1; param(pidx).fieldname = 'goToPokesLength'; param(pidx).val = 10*60000;
pidx = pidx + 1; param(pidx).fieldname = 'nosePokeHoldLength'; param(pidx).val = 0; % set to zero for phases 1-3, then increases in phase 4
pidx = pidx + 1; param(pidx).fieldname = 'rewardCollectionLength'; param(pidx).val = 12000;

pidx = pidx + 1; param(pidx).fieldname = 'LrewardLength'; param(pidx).val = 1000; % length in ms - calibrate for 10 uL
pidx = pidx + 1; param(pidx).fieldname = 'CrewardLength'; param(pidx).val = 1000; % length in ms - calibrate for 10 uL
pidx = pidx + 1; param(pidx).fieldname = 'RrewardLength'; param(pidx).val = 1000; % length in ms - calibrate for 10 uL


%% parameters that get set for each trial
laserOnCode = 0;
LrewardCode = 2;
CrewardCode = 1;
RrewardCode = 2;
cueHiLow    = 0;  % -1 is low, 1 is high, and 0 is neither
auditoryOrVisualCue = 0;



%% start of actual program - after initial debugging, nothing below this line should be edited

% open dialog box for terminating sessions
global exitNowYN;
exitNowYN = 0;
operantBoxExitDialog();

% get date, time
dateString = datestr(now, 29);
timeString = datestr(now, 30);
timeString = timeString(end-6:end);
fname = mfilename('fullpath');
[~, fbasename] = fileparts(fname);

% make sure no old serial ports are open
delete(instrfindall);

% open new serial port
baudRate = 115200;
s = serial(serialPort,'Timeout', 15000, 'BaudRate', baudRate, 'Terminator', 'LF');
fopen(s);

pause(1);
fprintf(s, 'checkVersion\n');
tstr = fgetl(s);
if str2num(tstr) ~= requiredVersion
    error(sprintf('The arduino has version %d, but the matlab script requires version %d', str2num(tstr), requiredVersion));
end

% % connecting to the arduino turns on the center syringe pump, so this shuts
% % it off again
% pause(0.2);
% fprintf(s, 'centerPulseYN;1\n');

% set all per-session parameters
fprintf(s, 'reset\n');
for idx = 1:pidx
    fprintf(s, [param(idx).fieldname ';' num2str(param(idx).val) '\n']);
    pause(0.1);
end

% make directory to save log file, copy m-file there
cd(basedir);
mkdir([mouseName '_' dateString]);
cd([mouseName '_' dateString]);
if ~isunix()
    system(['copy "' fname '.m" .\' mouseName '_' dateString '_' timeString '_mfile.m']);
else
    fname = strrep(fname, ' ', '\ ');
    system(['cp ' fname '.m ./' mouseName '_' dateString '_' timeString '_mfile.m']);
end






%% trials
waitBest('Hit OK to start the trials', ['Phase ' num2str(trainingPhase)]);
t = tic;

while nTrial<=maxTrials && toc(t) < sessionLength*60
    
    
    try
        
        % load settings for each trial to arduino
        
        sendToArduino(s, nTrial, 'laserOnCode', laserOnCode);
        sendToArduino(s, nTrial, 'LrewardCode', LrewardCode);
        sendToArduino(s, nTrial, 'CrewardCode', CrewardCode);
        sendToArduino(s, nTrial, 'RrewardCode', RrewardCode);
        sendToArduino(s, nTrial, 'cueHiLow', cueHiLow);
        sendToArduino(s, nTrial, 'auditoryOrVisualCue', auditoryOrVisualCue);
        fprintf(s, ['nTrial;' num2str(nTrial) '\n']);
        
        % open log file (separately for each trial)
        logfid = fopen([mouseName '_' dateString '_' timeString '.txt'], 'at');
        Astr = '';
        
        % start trial, log results
        pause(0.5);
        fprintf(s, 'startTrialYN;1\n');
        
        % loop to wait while trial runs, polling arduino periodically
        while isempty(strfind(Astr, 'tandby'))
            if s.bytesAvailable>0
                pause(0.05);
                Astr = fgetl(s);
                fprintf(logfid, [Astr '\n']);
                fprintf([Astr '\n']);
            else
                pause(0.05);
            end
        end
        
        fclose(logfid);
        if interTrialInterval >= 0.5
            pause(interTrialInterval - 0.5);
        else
            error('interTrialInterval must be at least 0.5');
        end
        nTrial = nTrial + 1;
        
        if exitNowYN == 1
            exitNowYN = 0;
            x = questdlg('Are you sure you want to exit?', '???', 'No');
            if strcmpi(x, 'yes')
                nTrial = maxTrials+1;
            end
        end
        
    catch
        warning('error encountered, exiting');
        fclose(logfid);
        nTrial = Inf;
        fprintf(s, 'goToStandby;1\n');
    end
    
end

%% shut things down - run this if you stop in the middle

fprintf(s, 'goToStandby;1\n');
fclose(s);
fclose('all');
disp('Exiting session');




