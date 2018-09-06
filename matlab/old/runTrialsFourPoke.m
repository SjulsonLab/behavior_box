function runTrialsFourPoke(m, param)

% function runTrialsFourPoke(m, param)
%
% This function is called by the box_train_phaseX_v2 scripts, and it runs
% the trials for the operant box.
%
% Luke Sjulson, 2017-07-26


%% start of actual program - after initial debugging, nothing below this line should be edited

% open dialog box for terminating sessions
global exitNowYN;
global exitAfterTrialYN;
exitNowYN = 0;
exitAfterTrialYN = 0;
x = operantBoxExitDialog2();
set(x,'WindowStyle','modal'); % keep this window always on top

% get date, time
dateString = datestr(now, 29);
timeString = datestr(now, 30);
timeString = timeString(end-6:end);
tempfname = dbstack('-completenames'); % gets name of function that called this one.
fname = tempfname(2).file;
% fname = mfilename('fullpath');
[~, fbasename] = fileparts(fname);

% make sure no old serial ports are open
delete(instrfindall);

% open new serial port
baudRate = 115200;
s = serial(m.serialPort,'Timeout', 10, 'BaudRate', baudRate, 'Terminator', 'LF');
fopen(s);

pause(1);
fprintf(s, 'checkVersion\n');
tstr = fgetl(s);
if str2num(tstr) ~= m.requiredVersion
    error(sprintf('The arduino has version %d, but the matlab script requires version %d', str2num(tstr), m.requiredVersion));
end

% % connecting to the arduino turns on the center syringe pump, so this shuts
% % it off again
% pause(0.2);
% fprintf(s, 'centerPulseYN;1\n');

% set all per-session parameters
fprintf(s, 'reset\n');
for idx = 1:length(param)
    fprintf(s, [param(idx).fieldname ';' num2str(param(idx).val) '\n']);
    pause(0.1);
end

% make directory to save log file, copy m-file there
cd(m.basedir);
mkdir([m.mouseName '_' dateString]);
cd([m.mouseName '_' dateString]);
if ~isunix()
    system(['copy "' fname '" .\' m.mouseName '_' dateString '_' timeString '_mfile.m']);
else
    fname = strrep(fname, ' ', '\ ');
    system(['cp ' fname ' ./' m.mouseName '_' dateString '_' timeString '_mfile.m']);
end






%% trials
waitBest('Hit OK to start the trials', ['Phase ' num2str(m.trainingPhase)]);
t = tic;

while m.nTrial<=m.maxTrials && toc(t) < m.sessionLength*60
    
    
%     try
        
        % load settings for each trial to arduino
        
        sendToArduino(s, m.nTrial, 'laserOnCode', m.laserOnCode);
        sendToArduino(s, m.nTrial, 'LrewardCode', m.LrewardCode);
        sendToArduino(s, m.nTrial, 'CLrewardCode', m.CLrewardCode);
        sendToArduino(s, m.nTrial, 'RrewardCode', m.RrewardCode);
        sendToArduino(s, m.nTrial, 'CRrewardCode', m.CRrewardCode);
        sendToArduino(s, m.nTrial, 'cueHiLow', m.cueHiLow);
        sendToArduino(s, m.nTrial, 'auditoryOrVisualCue', m.auditoryOrVisualCue);
        fprintf(s, ['nTrial;' num2str(m.nTrial) '\n']);
        
        % open log file (separately for each trial)
        logfid = fopen([m.mouseName '_' dateString '_' timeString '.txt'], 'at');
        Astr = '';
        
        % start trial, log results
        pause(0.5);
        fprintf(s, 'startTrialYN;1\n');
        
        % loop to wait while trial runs, polling arduino periodically
        while isempty(strfind(Astr, 'tandby'))
            if s.bytesAvailable>0
                pause(0.05);
                Astr = fgetl(s);
                pause(0.05);
                fprintf(logfid, [Astr '\n']);
                fprintf([Astr '\n']);
            else
                pause(0.05);
            end
            
            if exitNowYN == 1
                fprintf(s, 'goToStandby;1\n');
                m.nTrial = m.maxTrials + 1;
                Astr = 'Standby';
            end
        end
        
        pause(0.2);
        fclose(logfid);
        if m.interTrialInterval >= 0.5
            pause(m.interTrialInterval - 0.5);
        else
            error('interTrialInterval must be at least 0.5');
        end
        m.nTrial = m.nTrial + 1;
        
        if exitAfterTrialYN == 1
            exitAfterTrialYN = 0;
            tempStr = questdlg('Are you sure you want to exit?', '???', 'No');
            if strcmpi(tempStr, 'yes')
                m.nTrial = m.maxTrials+1;
            end
        end
        
        
        
        
%     catch
%         warning('error encountered, exiting');
%         fclose(s);
%         fclose('all');
%         m.nTrial = Inf;
%     end
    
end

%% shut things down - run this if you stop in the middle

fprintf(s, 'goToStandby;1\n');
pause(10);
fclose(s);
fclose('all');
disp('Exiting session');
close(x);
