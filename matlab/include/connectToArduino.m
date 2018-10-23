function box1 = connectToArduino(m)

% function box1 = connectToArduino(m)
%
% connects to the arduino

delete(instrfindall);
box1 = serial(m.serialPort,'Timeout', 10, 'BaudRate', 115200, 'Terminator', 'LF', 'OutputBufferSize', 10^6, 'InputBufferSize', 10^6);
fopen(box1);
pause(1);
fprintf(box1, 'checkVersion\n');
tstr = fgetl(box1);
if str2num(tstr) ~= m.requiredVersion
	error(sprintf('The arduino has version %d, but the matlab script requires version %d', str2num(tstr), m.requiredVersion));
end