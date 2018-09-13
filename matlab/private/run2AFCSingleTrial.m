function fname = run2AFCSingleTrial(arduino, sessionStr, trial_dict)

% function fname = run2AFCSingleTrial(arduino, sessionStr, trial_dict)
%
% this function runs a single trial for the 2AFC box (three nosepokes)
%
% INPUTS
% arduino: a pointer to an arduino serial object
% sessionStr: a struct containing info about this mouse and session
% trial_dict: a python dict containing all parameters sent to the box for each trial
%
% OUTPUTS
% fname: the name of the log file
%
% Luke Sjulson, 2017-09-26
% modified for 2AFC task by Luke Sjulson, 2018-09-12


global exitNowYN  % used for the GUI button that allows you to exit in the middle of a trial

%% start of actual program - after initial debugging, nothing below this line should be edited

% send dict of box parameters to arduino
k = trial_dict.keys;
d = trial_dict.values;
for idx = 1:length(d)
   sendToArduino(arduino, [], char(k{idx}), d{idx});
   pause(0.01);
end
% fprintf(['done sending info to arduino, trial #' num2str(trial_dict{'nTrial'}) '\n']);

% open log file (separately for each trial)
cd(sessionStr.basedir);
cd(sessionStr.basename);
fname = [sessionStr.basename '.txt'];
logfid = fopen(fname, 'at');
Astr = '';

% start trial, log results
pause(0.01);
sendToArduino(arduino, [], 'startTrialYN', 1);

% loop to wait while trial runs, polling arduino periodically
while ~contains(Astr, 'tandby')
   if arduino.bytesAvailable>0
      pause(0.1); % to prevent fgetl from being called before the entire string is written
      Astr = fgetl(arduino);
      fprintf(logfid, [Astr '\n']);
      fprintf([Astr '\n']);
   else
      pause(0.050);
   end
   
   if exitNowYN == 1
      sendToArduino(arduino, [], 'goToStandby', 1);
      Astr = 'Standby'; % to exit the while loop
   end
end

% pause(0.2);
fclose(logfid);



