function T = getEventTimes(textString, fname)

% function T = getEventTimes(textString, fname)
%
% This function searches for textString in the logfile called fname.
% if fname is not provided, it searches all .txt files in the current 
% directory.
% It then returns the first column (which is the timestamp for
% behavior box log files). 
%
% Luke Sjulson, 2018-12-20

if nargin<2
	fname = '*.txt';
end

winbash(['grep -i ' textString ' ' fname ' | cut -f 1 -d '';'' > ' textString '.tmp'], 'silent');
T = load([textString '.tmp']) ./ 1000; % convert from ms to seconds
winbash(['rm ' textString '.tmp']);

