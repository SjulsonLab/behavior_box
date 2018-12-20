% a function for running bash commands in windows (assuming windows 
% subsystem for linux is installed). 
% 
% usage: same as system()

function [a, b] = winbash(inputString, silent)

if nargin<2
	silent = '';
end

if contains(inputString, '"')
	error('winbash does not support use of quotation marks');
end

if contains(computer, 'PCWIN')
	[a, b] = system(['bash -c "' inputString '"']);
else 
	warning('Windows not detected...passing command to native bash');
	[a, b] = system(inputString);
end

if ~strcmpi(silent, 'silent')
	disp(b)
end