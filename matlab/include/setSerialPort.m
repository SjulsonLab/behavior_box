function m = setSerialPort(m)

% function m = setSerialPort(m)
%
% takes the mouse struct m and adds machine-specific info about which serial
% port the arduino is on, what the basedir is, etc.
%
% Luke Sjulson, 2018-10-23

[~, hostname] = system('hostname');
if strfind(hostname, 'Luke-HP-laptop')
	m.basedir = 'C:\Users\lukes\Desktop\temp';
	m.serialPort = 'COM5';  % can look this up in the arduino
elseif strfind(hostname, 'bumbrlik01')
	m.basedir = 'G:\My Drive\lab-shared\lab_projects\rewardPrediction\behavior';
	m.serialPort = 'COM4';  %commented by EFO
elseif strfind(hostname, 'bumbrlik02')
    m.basedir = 'G:\My Drive\lab-shared\lab_projects\rewardPrediction\behavior';
    m.serialPort = 'COM5'; %introduced by EFO, arduino was connected on COM5 only, no matter which USB port  
elseif strfind(hostname, 'bumbrlik03')
    m.basedir = 'G:\My Drive\lab-shared\lab_projects\rewardPrediction\behavior';
    m.serialPort = 'COM6';
elseif strfind(hostname, 'gammalsjul')
    m.basedir = '/home/luke/temp';
    m.serialPort = '/dev/ttyACM0';
elseif strfind(hostname, 'DESKTOP-RE9G846')
    m.basedir = 'C:\Users\lab\Desktop\temp';
    %m.serialPort = 'COM6';
    m.serialPort = 'COM11';

else
	error('This computer is not on the list. Edit setSerialPort.m to add it.');
end

m.dateString = datestr(now, 29);
timeString = datestr(now, 30);
m.timeString = timeString(end-5:end);